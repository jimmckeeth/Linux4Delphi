# pacommander protocol capture notes

Findings from running `scripts/pacommander.py` as a logging proxy between
real Delphi IDEs and a real PAServer instance (PAServer 13.1, `paserver`
listening on 64212, proxied via 64211).

See `analysis.md` in this directory for a per-version comparison table
(reported "expecting X.X.X.X" string vs. handshake vs. how far each
session got). `scripts/pacommander_parse.py` automates pulling the
`connect` info, server `ScratchDir`, expected package name, and
`PutFile` occurrence out of a raw pacommander log — run it against
`/tmp/pacommander-swap.log` (or wherever `--log-file` points) instead of
re-deriving these fields by hand.

## Wire protocol shape (DataSnap/DBX over TCP)

Every connection observed follows the same shape:

1. **5-byte handshake.** Client sends `05 05 05 05 05`, server replies
   `06 00 00 00 00`. Looks like a version/capability negotiation; the
   literal bytes were identical across every PAServer 13.1 session
   captured (11.3, 12.3, 13.1, 10.3.3 clients all sent/received the same
   5 bytes) — this handshake does not appear to carry the version info
   the mismatch dialog is based on.
2. **Everything after that is JSON**, one object per DataSnap/DBX RPC
   call, no framing/length prefix visible at this layer (relies on
   DataSnap's own encoding within the JSON `data` arrays for binary
   parameters — those show up as raw non-UTF8 bytes inline in the JSON
   string, not base64).
3. Observed call sequence for a normal connect + platform check:
   - `connect` (driver/auth info — see below)
   - `execute` → `Dbx.MetaData.GetDatabase` (capability negotiation table)
   - `prepare`/`execute` → `TServerMethods.SetName` (client profile name)
   - `prepare`/`execute` → `TServerMethods.SetAddress` (client identity
     string, e.g. `<machine-name> [<client-ip>]`), followed by a
     **two-round challenge/response `callback`** exchange (looks like an
     auth handshake — server sends a `callback` challenge, client answers
     with `data`, repeated twice with the *same* challenge value both
     times)
   - `prepare`/`execute` → `TServerMethods.VerifyPlatform` (client sends
     `"Linux64"`, server replies with platform info + its own
     `ScratchDir`, e.g. `<home>/.PAServer/13.1-scratch/<profile-name>/`)
   - `prepare`/`execute` → `TServerMethods.FileExistsEx` checking for
     `LinuxPAServer<compiler-version>.tar.gz` (e.g.
     `LinuxPAServer23.0.tar.gz` for a 12.x/Athens client) inside that
     scratch dir
   - **if not found:** `prepare`/`execute` → `TServerMethods.PutFile`,
     uploading the full tar.gz (~39MB of hex-dump log for a ~60MB file,
     since pacommander logs every 4096-byte read as its own entry)
   - **if found:** skips straight to teardown
   - teardown: `command_close` for every open handle, then `disconnect`

## Version-mismatch finding

The PAServer instance used for these captures is version **13.1**
(confirmed via its own reported `ScratchDir`). Delphi 12.3, 11.3 (build
28.0.48361.3236), and 10.3 Update 3 (build 26.0.36039.7899) attempts all
connected to it successfully at the wire level — full JSON-RPC exchange,
clean teardown — but Delphi's IDE
reported a **version mismatch** to the user every time, each with a
different expected-version string (see `analysis.md` for the full
table). That exact string never appears on the wire; it's computed
IDE-side. The mechanism visible in the capture for 11.3/12.x: the
client's `FileExistsEx` check is for `LinuxPAServer23.0.tar.gz`
(12.x/Athens) or `LinuxPAServer22.0.tar.gz` (11.3/Alexandria) — the
package each IDE expects — while the actual server identifies itself as
`13.1`. That mismatch is what the IDE is flagging.

**10.3.3 behaves differently: no self-heal attempt at all.** Unlike
every 11.3/12.x capture, the 10.3.3 session never calls `FileExistsEx`
or `PutFile`. It goes `VerifyPlatform` → straight to `command_close` x3
+ `disconnect`, closing out right after reading the server's platform
info. This is the first concrete evidence for the compatibility-risk
concern raised earlier: older IDEs don't necessarily follow the same
self-healing path newer ones do, so a hypothetical version-spoofing fix
would need to account for materially different client behavior per IDE
generation, not just a single shared code path.

**Self-healing behavior:** on the first 12.3 attempt, `FileExistsEx`
found nothing, so the IDE uploaded `LinuxPAServer23.0.tar.gz` to the
server's scratch dir via `PutFile` anyway and the deploy proceeded to
`command_close`/`disconnect` normally. On a second 12.3 attempt
afterward, `FileExistsEx` now found the file (from the prior upload) and
the IDE skipped `PutFile` entirely — otherwise the two sessions were
byte-for-byte identical in structure. The version-mismatch dialog
appeared both times regardless of whether the file transfer happened, so
it's a pure client-side check, unrelated to whether the upload occurs.

**Presence-by-filename is not sufficient to skip the upload.** To try to
avoid repeated multi-MB transfers during testing, the canonical PAServer
package for every compiler line in `SetupLinux4Delphi.sh` was
pre-downloaded from Embarcadero's CDN and placed directly into
`~/.PAServer/13.1-scratch/<profile-name>/` under the exact filename PAServer
looks for. A Delphi 11.3 (build 28.0.48361.3236) connection still
uploaded the full `LinuxPAServer22.0.tar.gz` via `PutFile` even though
`FileExistsEx` reported the file present (`"data":[18,...]`, same
found-response shape as the 12.3 skip case). Comparing the two
`FileExistsEx` response payloads byte-for-byte, only the embedded
TSDate/TSTime/Size fields differ — so the IDE is validating the existing
file's size/timestamp against its own expected value, not just its
presence, and re-uploads on any mismatch. A CDN-downloaded copy
apparently doesn't match closely enough. Only a file that PAServer itself
previously wrote via `PutFile` (i.e. captured from a real IDE upload) is
reliably skipped on a later check.

## Notes on sensitive-looking fields

We originally observed `connect`'s
`DSAuthenticationPassword` field as a fixed 33-character hex-ish string
(`695602992E04E52893978599B689E4A5`) identical across every capture and
concluded it wasn't a real secret. That was only true because every
capture up to that point used a blank/"no password" profile. Connected
Delphi 10.3.3 to a real backend with an actual password set
(`-password=Test123` server-side, matching password entered client-side)
and the field **changed** to `462393DE631A0B6610A0DA68141F016E` — a
different value — and the connection authenticated successfully (no
`TDBXError` this time, vs. the rejection seen earlier when client and
server passwords didn't match). So this field **is** genuinely
password-derived and should be treated as sensitive/credential material,
not redacted-as-harmless. `695602992E04E52893978599B689E4A5` specifically
is what a blank password hashes to, not a universal constant. (The raw
capture from the password-set session was excluded from this directory
rather than committed — it's real credential-derived material, even
though the password itself was a disposable test value. This paragraph
is the complete record of the finding.)

- The two-round `callback`/`data` challenge-response hashes (32 hex
  chars each) also differ per session — legitimate per-connection auth
  material, redact if these captures are ever shared outside the team.

## Where the version-mismatch check actually happens — SOLVED

Earlier captures only ever talked to one real PAServer (13.1), so the
`VerifyPlatform` response was necessarily identical across every client
— that told us the check was client-side, but not what the client was
actually reading. To settle it, we stopped pacommander, extracted the
`paserver` binary from each of the six downloaded packages
(pre-seeded into the running PAServer's scratch directory, see above),
launched each real server on its own port, and used a minimal hand-
rolled DataSnap client (no SetName/SetAddress/auth needed — `connect`
can even fail auth and the server keeps answering `GetDatabase`/
`VerifyPlatform` anyway) to capture `VerifyPlatform`'s response from
each one directly.

**First finding — the binaries self-report their real version via
`paserver -help`,** and it matches the IDE's "expecting" string exactly:

| Package | `paserver -help` version | IDE that reported this as "expecting" |
|---|---|---|
| LinuxPAServer19.0 | `10.2.1.13` | — |
| LinuxPAServer20.0 | `11.2.13.8` | Delphi 10.3.3 |
| LinuxPAServer21.0 | `12.2.10.3` | — |
| LinuxPAServer22.0 | `13.3.12.7` | Delphi 11.3 |
| LinuxPAServer23.0 | `14.3.14.2` | Delphi 12.3 |
| LinuxPAServer37.0 | `37.1.10.6` | (matches the locally installed 13.1/Florence PAServer) |

Note this 4-part `Major.Minor.Build.Patch` PAServer version is a
**completely different numbering scheme** from the marketing/product
version (e.g. `37.1.10.6` is the same release as "PAServer 13.1"/
Florence). The plaintext `13.1` seen earlier in `ScratchDir` is the
product name, not this version — it's not what the IDE compares.

**Second finding — the wire encoding of `ServerMajorVersion`/
`ServerMinorVersion` is now fully decoded.** In every response, right
after the `"Linux64"` (`ServerPlatform`) string, there are 4–5 bytes
before the `\x10\x00` marker that precedes `ScratchDir`:

```
[[tag][value...]] [[tag][value...]]
   ServerMajorVersion    ServerMinorVersion
```

Each field is `[tag byte][value bytes]`, where the tag is `0x60 +
byte-width` (`0x61` = 1-byte value, `0x62` = 2-byte value, big-endian)
— a simple variable-length integer encoding. Decoded across all six
real servers:

- **`ServerMajorVersion` = `Major*10 + Minor`.** Exact match on all six
  samples, including LinuxPAServer37.0 needing a 2-byte value (`37*10+1
  = 371`, tag `0x62`) where every other sample fit in 1 byte (tag
  `0x61`) — a very specific confirmation, not a coincidence.
- **`ServerMinorVersion` = `Build*10 + Patch`.** Exact match on 5 of 6
  samples (20.0, 21.0, 22.0, 23.0, 37.0). LinuxPAServer19.0
  (`10.2.1.13`, i.e. `Build=1, Patch=13`) breaks it — predicted `23`,
  actual wire value `113` — because `Patch=13` is two digits and this
  packing scheme apparently assumes a single decimal digit. Not fully
  resolved; flagging rather than papering over.

This closes the loop end to end: Delphi 11.3 reported "was expecting
13.3.12.7"; LinuxPAServer22.0 self-identifies as `13.3.12.7` and its
wire encoding decodes to `ServerMajorVersion=133, ServerMinorVersion=127`
— i.e. `13*10+3=133` and `12*10+7=127`. Same numbers, same server. The
IDE's hardcoded expectation really is compared against these two wire
integers, encoded compactly rather than as a plain string.

Script and raw results: `scripts/pacommander_parse.py` was not used for
this part (it parses pacommander logs; this instead used a minimal
direct-socket client, `scripts/pacommander_probe.py`, that connects
straight to a real `paserver` and reads `VerifyPlatform`'s response
without needing SetName/SetAddress/auth). Raw output from running it
against all six extracted packages is saved in
`captures/paserver-version-probe-results.txt`.

## Can pacommander be updated to spoof the version and avoid the mismatch?

Yes, with a concrete recipe now: pacommander would need to rewrite the
`VerifyPlatform` response in-flight, replacing the `ServerMajorVersion`/
`ServerMinorVersion` tag+value bytes with the target IDE's expected
`Major*10+Minor` / `Build*10+Patch` values (re-tagging for byte-width if
the value crosses the 1-byte/2-byte boundary), while leaving
`ScratchDir` and everything else untouched. This is exactly the "smart
PAServer router" direction the original commit pointed at.

Built `scripts/pacommander_spoof.py` to do exactly this: it proxies a
real backend (the locally installed PAServer 13.1, `/opt/PAServer/13.1/
paserver`) and splices in the captured version bytes for a chosen
target (`--target-version`), using literal bytes from real captures
rather than the derived formula. Verified end-to-end against
`pacommander_probe.py`: the `data:[LEN,...]` prefix is correctly
recomputed and only the version segment changes.

**First real attempt (target 10.2, using LinuxPAServer19.0/Release3's
bytes for `10.2.1.13`) failed** — not because the splice was wrong, but
because we guessed the wrong target version. See "Tokyo/19.0 package
version reference" below: the real Delphi 10.2 Update 3 IDE (build
`25.0.31059.3231`) reported expecting `10.3.1.15`, which doesn't match
any of the four real Tokyo/19.0 packages checked. Also worth noting:
when the spoofed version still doesn't match, the IDE falls back to its
normal self-heal path (`FileExistsEx`/`PutFile`) exactly as if no
spoofing had happened — in this case that upload itself then failed
with a generic, unhelpful error ("An error occurred while copying a new
Platform Assistant Server installer package ... - ''"), a separate
problem not yet diagnosed.

**Operational note for standing up the real 13.1 backend for spoof
testing:** running `paserver` with stdin as `/dev/null` or redirected
from a closed pipe makes its interactive console busy-loop at 100% CPU
(it treats immediate EOF as "no input yet, ask again" rather than
blocking). Fix: give it a FIFO whose write end is held open by a
long-running `sleep infinity` redirected into it, so `read()` blocks
properly instead of spinning. Sending a single `\n` into that FIFO
answers the "Connection Profile password <press Enter for no
password>:" prompt so it starts unprotected, matching how the original
system instance was apparently set up (no password).

- **Still open:** the `Build*10+Patch` encoding for two-digit `Patch`
  values (like 19.0's `.1.13`, or the target `10.3.1.15`) isn't nailed
  down, so spoofing a target version with a two-digit patch component
  needs real captured bytes, not the formula.
- **Still the real risk:** even with a byte-perfect version spoof,
  older PAServer generations are old enough that their actual
  `TServerMethods.*` call set or DBX marshaling could differ from what
  13.1 implements. Suppressing the dialog doesn't guarantee the rest of
  a real deploy succeeds — worth testing end-to-end, not just checking
  whether the dialog disappears.

**Second attempt (target 10.3, formula-derived bytes for `10.3.1.15`
since no real capture exists) also failed** — same error, no
`FileExistsEx` attempt either time. To isolate whether this was our
spoofing or something else, connected the same real IDE **directly to
the actual official Release3/10.2.3 package with zero spoofing** (plain
`pacommander.py`, logging only). **Same failure.** The real, official,
unmodified PAServer download for 10.2.3 does not satisfy this
installed IDE's version check. This rules out both of our spoofing
attempts as the cause — the mismatch is between two pieces of
Embarcadero's own software, not something introduced by pacommander.
See "Tokyo/19.0 package version reference" below.

## Tokyo/19.0 package version reference

`SetupLinux4Delphi.sh` only lists two Tokyo URLs (base `"10.2"` and
`"tokyo"|"10.2.3"`); Embarcadero's CDN also has `Release1`/`Release2`
folders following the same naming pattern used for Rio, discovered by
guessing (not documented anywhere we've found):

| Delphi product | URL | Self-reported PAServer version |
|---|---|---|
| 10.2 (base, Update 0) | `.../19.0/PAServer/LinuxPAServer19.0.tar.gz` | `10.0.1.23` |
| 10.2 Update 1 *(assumed)* | `.../19.0/PAServer/Release1/LinuxPAServer19.0.tar.gz` | `10.1.1.33` |
| 10.2 Update 2 *(assumed)* | `.../19.0/PAServer/Release2/LinuxPAServer19.0.tar.gz` | `10.2.1.10` |
| 10.2 Update 3 | `.../19.0/PAServer/Release3/LinuxPAServer19.0.tar.gz` | `10.2.1.13` |

**None of these four match `10.3.1.15`**, which is what a real Delphi
10.2 Update 3 IDE (build `25.0.31059.3231`) actually reported expecting
when it connected. Confirmed conclusively (not just "we couldn't find
the right download"): connected this exact IDE **directly** to the real
Release3/10.2.3 binary running unmodified, no pacommander spoofing
involved, plain logging proxy only — and got the identical "expecting
10.3.1.15" failure
(`captures/delphi-10.2.3-paserver-19.0-version-mismatch.log`). So this
isn't a wrong-URL problem on our end; **Embarcadero's own official
Release3 download for 10.2.3 does not satisfy this IDE build's version
check.** Either:

- there's a PAServer point-patch for 10.2.3 published somewhere we
  haven't found (a `Release4`, a dated folder, or a differently-named
  path), or
- this specific IDE installation had its expected-version check updated
  independently of the PAServer package it originally shipped with
  (e.g. via a later GetIt/hotfix update to the IDE itself), or
- this particular combination is simply broken on Embarcadero's side —
  the official download and the IDE's own check disagree with each
  other regardless of what a user does.

Not resolved, and not fixable from the pacommander/spoofing side either
(confirmed by the two failed spoof attempts above) — spoofing can only
help when the target version's real bytes are known, and we don't have
a source for `10.3.1.15` at all.

**This is specific to 10.2.3, not a general "older IDEs are broken"
pattern.** Ran the identical direct/no-spoofing test for 10.3.3 against
its own real official package (`LinuxPAServer20.0`, self-reports
`11.2.13.8`) and got a completely clean result: no mismatch at all, full
deploy handshake through `SetSDKPath`/`SetSupportSymLink`/
`GetDebugWithPort` to a clean `command_close`×6 + `disconnect`
(`captures/delphi-10.3.3-paserver-20.0-match.log`). So 10.3.3's IDE and
its own official PAServer package agree perfectly — 10.2.3's failure is
an isolated inconsistency on Embarcadero's side, not something endemic
to pre-11.x Delphi releases in general.

This capture is also notable on its own: like 10.3.3's earlier mismatch
capture, the 10.2.3 mismatch session never attempts
`FileExistsEx`/`PutFile` — second confirmation that the self-heal
behavior is absent in the
older (pre-11.x) IDE generation, not just a 10.3.3 quirk.

Also confirmed 11.3 against its own real official package
(`LinuxPAServer22.0`, self-reports `13.3.12.7`, no password): identical
clean result, no mismatch, full handshake through
`SetSDKPath`/`SetSupportSymLink`/`GetDebugWithPort` to
`command_close`×6 + `disconnect`
(`captures/delphi-11.3-paserver-22.0-match.log`). So across every IDE
tested so far (13.1, 11.3, 10.3.3), the IDE's own genuinely-matching
official PAServer package always works cleanly — **10.2.3 is the only
confirmed broken pairing found to date.**

## Spoofing 11.3 against the real 13.1 backend — worked, but revealed an unrelated real bug

Added full hex-dump logging to `pacommander_spoof.py` (it only logged
the rewrite event before) and pointed it at the real 13.1 backend with
`--target-version 13.3` (11.3's real, verified bytes from the probe
table, not a formula guess). Result: **Delphi 11.3 connected
successfully** — no mismatch dialog, and a real import/deploy completed
against the spoofed 13.1 backend. This is the first successful
end-to-end spoof: unlike the 10.2/10.3 attempts (which used
formula-derived bytes for versions we have no real backend for), this
one had a real captured target and a real, presumably superset-capable
newer backend, and it worked.

**However, the remote debugger then failed** with an LLDB startup
error. Initially this looked like exactly the compatibility risk flagged
earlier ("suppressing the dialog doesn't guarantee the rest of a real
deploy succeeds") — but swapping to the **real, unmodified, correctly-
matching LinuxPAServer22.0 backend** (no spoofing at all) reproduced the
*exact same* debugger failure. So the debugger break has **nothing to do
with version spoofing** — it's a separate, real bug:

```
Unable to start LLDB kernel: 'Symbolic link target does not exist:
.../lldb/lib/libpython3.so -> /usr/lib/x86_64-linux-gnu/libpython3.7m.so.1.0.
```

PAServer's bundled `lldb` ships with `lib/libpython3.so` symlinked to a
Debian/Ubuntu multiarch path. On this Fedora machine that path doesn't
exist (Fedora uses `/usr/lib64/libpython3.X.so.1.0`).

**Only 11.3 was confirmed end to end** (broken → relinked → debugger
verified working afterward). To gauge how widespread this is, checked
`lldb/lib/libpython3.so` directly in all six downloaded PAServer
packages, plus the locally-installed real PAServer 13.1
(`/opt/PAServer/13.1/lldb/lib/libpython3.so`) — inspection only, not a
debug-session test for any of these except 11.3:

- **19.0, 20.0, 21.0** (Tokyo/Rio/Sydney-era): no `lldb/lib/libpython3.so`
  present at all. Older packages don't seem to bundle it this way.
- **22.0 (11.3)**: broken (this is the one we actually fixed and tested).
- **23.0 (12.3), 37.0 (13.1/Florence), and the locally-installed real
  13.1**: same broken symlink, same Debian-style target path pattern —
  strongly suggestive but not debug-tested.

`SetupLinux4Delphi.sh` already had a fix for this (`scripts/
SetupLinux4Delphi.sh`, added per
https://blogs.embarcadero.com/setting-up-ubuntu-22-04-for-delphi-11-2-debugging/)
— **but it was gated to `if [[ "$PRODUCT" == "11.2" ]]`**, so it silently
did nothing for every other version, including the 11.3 case we actually
tested. Fixed: the condition now checks whether
`lldb/lib/libpython3.so` is actually a dangling symlink
(`-L "$f" && ! -e "$f"`) instead of checking the product version — a
no-op on the three packages that don't have the file, and only acts
where there's a real broken link, rather than hardcoding which versions
it applies to. Verified `bash -n` and shellcheck clean. Manually
relinked the live test copies
(`LinuxPAServer22.0` test extraction, matching the fixed script's dnf/yum
branch logic) and confirmed the debugger works afterward.

## Files in this directory

- `delphi-13.1-paserver-session.log` — first successful capture, Delphi
  13.1 IDE against PAServer 13.1 (matching versions, no mismatch).
- `delphi-12.3-paserver-13.1-version-mismatch.log` — trimmed to the
  negotiation only (handshake through the `FileExistsEx`/`PutFile`-
  prepare exchange); the ~60MB `PutFile` payload that followed is
  omitted as noted inline. First-ever attempt against this server, file
  did not yet exist remotely.
- `delphi-11.3-paserver-13.1-version-mismatch.log` — same trimming.
  `FileExistsEx` reported the file present (pre-seeded from Embarcadero's
  CDN) but the IDE uploaded anyway — see "Presence-by-filename is not
  sufficient to skip the upload" above.
- `delphi-10.3.3-paserver-13.1-version-mismatch.log` — full capture, no
  trimming needed (206 lines total). Session ends right after
  `VerifyPlatform`; never reaches `FileExistsEx`/`PutFile`.
- `delphi-10.2.3-paserver-19.0-version-mismatch.log` — Delphi 10.2
  Update 3 (build 25.0.31059.3231) connected **directly to the real,
  unmodified, official Release3/10.2.3 PAServer binary**, no spoofing.
  Still reported "expecting 10.3.1.15" despite talking to the actual
  official package for its own product line — proof this is an
  Embarcadero-side inconsistency, not a wrong-download or spoofing
  problem. Same no-self-heal pattern as 10.3.3.
- `delphi-10.3.3-paserver-20.0-match.log` — Delphi 10.3 Update 3 (build
  26.0.36039.7899) connected directly to the real, unmodified, official
  LinuxPAServer20.0 (Rio) binary. Clean success, no mismatch at all —
  contrast with 10.2.3 above, proving that failure is isolated rather
  than a general old-IDE problem.
- (A capture of the same pairing with a real password set was used to
  correct the earlier "DSAuthenticationPassword is a harmless constant"
  claim — see "Notes on sensitive-looking fields" above — but wasn't
  kept in this directory since it contains real credential-derived
  material.)
- `delphi-11.3-paserver-22.0-match.log` — Delphi 11.3 (build
  28.0.48361.3236) connected directly to the real, unmodified, official
  LinuxPAServer22.0 (Alexandria) binary, no password. Clean success, no
  mismatch.
- `paserver-version-probe-results.txt` — raw output of
  `scripts/pacommander_probe.py` run against all six real extracted
  `paserver` binaries (19.0–37.0), used to decode the
  `ServerMajorVersion`/`ServerMinorVersion` wire encoding above.
- `analysis.md` — per-version comparison table and observations.
