# pacommander

## Goal

PAServer refuses to talk to a Delphi IDE whose version it doesn't
recognize, which means every supported Delphi release effectively needs
its own PAServer instance (and often its own port) on a Linux dev
machine. pacommander's goal is to remove that requirement: a single
proxy that sits in front of one real PAServer backend and makes it
transparently answer for whichever Delphi version actually connects, so
one backend can serve every supported IDE on one port.

It started as a passive logging proxy to study the PAServer wire
protocol, and has since grown into a small toolset built around that
same protocol understanding:

- `scripts/pacommander.py` — the original logging proxy. Listens on a
  port, forwards to a real PAServer, hex-dumps everything in both
  directions to a log file. No modification of traffic.
- `scripts/pacommander_probe.py` — a minimal fake-IDE client. Connects
  straight to a real PAServer and reads back its `VerifyPlatform`
  response, without needing a real Delphi IDE or the SetName/SetAddress/
  auth dance.
- `scripts/pacommander_parse.py` — an offline summarizer for
  `pacommander.py`'s logs: pulls out `connect` info, the server's
  reported `ScratchDir`, the package name an IDE's `FileExistsEx` check
  is looking for, and whether `PutFile` happened, instead of re-deriving
  those by hand from raw hex dumps.
- `scripts/pacommander_spoof.py` — the active router prototype. Proxies
  one real backend PAServer and rewrites the two version-identifying
  integers inside `VerifyPlatform`'s response in-flight, so the backend
  can claim to be whichever PAServer version a connecting IDE expects.

## What we learned

- **Wire shape:** a 5-byte handshake, then a sequence of JSON-shaped
  DataSnap/DBX RPC calls (some parameters are raw length-prefixed binary
  spliced into what otherwise reads as JSON, not valid JSON on their
  own). Normal sequence: `connect` → `GetDatabase` → `SetName` →
  `SetAddress` + a two-round auth `callback` exchange → `VerifyPlatform`
  → (`FileExistsEx`/`PutFile` if the IDE decides to self-heal) →
  `command_close` per handle → `disconnect`.
- **The version-mismatch dialog is entirely client-side.** The exact
  same `VerifyPlatform` response bytes were sent by a given backend
  regardless of which IDE connected or whether that IDE ended up
  showing a mismatch dialog. Each IDE build has its own hardcoded
  expected PAServer version baked in and compares it locally against
  what the server reports — nothing is negotiated.
- **The version encoding is fully decoded.** `VerifyPlatform`'s response
  carries two integers, `ServerMajorVersion` and `ServerMinorVersion`,
  packed as tagged variable-length values (tag byte `0x60 + byte-width`,
  value follows big-endian). Across PAServer's real 4-part version
  scheme (`Major.Minor.Build.Patch` — a different numbering system than
  the marketing name, e.g. package "PAServer 13.1" is internally
  `37.1.10.6`): `ServerMajorVersion = Major*10 + Minor`,
  `ServerMinorVersion = Build*10 + Patch`. Verified exact against real
  `paserver -help` output for 5 of 6 real binaries checked. **Not
  reliable when `Patch` is two digits** — one real sample breaks the
  formula and we don't yet know the correct encoding for that case.
- **Spoofing works.** Pointed a real, newer PAServer backend through
  `pacommander_spoof.py`, rewrote its `VerifyPlatform` response to the
  exact bytes a different (older) IDE expected, and that IDE connected
  with no mismatch dialog and completed a real deploy. This is the core
  mechanism the "smart router" idea depends on, and it's now proven to
  work end to end for at least one same-generation IDE/backend pairing.
- **Spoofing's real limit, and a false alarm.** A later remote-debug
  attempt against the spoofed backend failed — initially this looked
  like the expected risk (faking the version doesn't guarantee full
  protocol/tooling compatibility). It turned out to be unrelated: the
  same failure reproduced against a real, correctly-matching,
  unmodified backend too. The actual cause was a broken `lldb` symlink
  (points to a Debian/Ubuntu-only path) shipped in the PAServer package.
  Checked all six downloaded PAServer packages directly: three older
  ones (Tokyo/Rio/Sydney-era) don't ship this file at all; the two
  newer ones (12.3, 13.1) have the identical broken symlink. Only the
  11.3 case was confirmed end to end (broken → relinked → debugger
  verified working); 12.3/13.1 are inspection-only so far, not
  debug-tested. `SetupLinux4Delphi.sh`'s existing fix for this was
  scoped to one product version only (the one it was originally
  reported for) — changed to detect a dangling symlink directly instead
  of checking the product version, so it's a no-op on packages that
  don't have the problem and fixes it on any that do, rather than
  silently skipping versions it wasn't originally written for.
- **At least one official PAServer package doesn't match what its own
  IDE expects, independent of anything pacommander does.** Confirmed by
  connecting the affected IDE directly to its real, unmodified,
  documented PAServer download with no proxy involved — still a
  mismatch. Not something a router can fix by picking a better package;
  the inconsistency is on Embarcadero's side.

Full research log, per-version comparison table, and raw protocol
captures are in `captures/` (`NOTES.md`, `analysis.md`, and the
individual `delphi-*.log` files) for anyone who wants the evidence
behind the summary above.

## Current strategy

Short-term, pragmatic: use `pacommander_spoof.py` manually — pick one
real backend PAServer, pick a `--target-version` matching real captured
bytes (not the unverified formula), and point the IDE that needs it at
the proxy port. This already works for same-generation IDE/backend
pairs.

What's still needed before this could be a real "one port, any IDE"
router rather than a manually-targeted proxy:

1. **Two-digit-Patch byte encoding.** Needed to spoof targets like
   `10.3.1.15` where the formula is known wrong and no real backend
   exists to capture the correct bytes from.
2. **Automatic target selection.** Today the target version is a
   command-line flag chosen ahead of time. The only client-side signal
   that reveals which IDE is connecting (`FileExistsEx`'s requested
   package filename) arrives *after* `VerifyPlatform`'s response has
   already been sent — an ordering problem that needs solving before
   routing can be automatic rather than manual.
3. **Broader compatibility testing.** Only one IDE/backend generation
   gap has been proven to work end-to-end (11.3 IDE against a 13.1
   backend). Whether spoofing holds up across much larger gaps (e.g. a
   Tokyo-era IDE against a Florence-era backend) is untested.
