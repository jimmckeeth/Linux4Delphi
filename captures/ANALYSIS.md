# Version comparison

Unless noted otherwise, captures below are Delphi IDEs connecting to the
same real PAServer instance, version **13.1**, through `pacommander.py`
proxying 64211 → 64212. Generated with the help of
`scripts/pacommander_parse.py`.

| Delphi version tested | IDE build | Compiler / Release | Dialog said "expecting" |
|---|---|---|---|
| 13.1 | (matching) | 37.0 / Florence | *(no mismatch — versions match)* |
| 12.3 | — | 23.0 / Athens | `14.3.14.2` |
| 11.3 | 28.0.48361.3236 | 22.0 / Alexandria | `13.3.12.7` |
| 10.3 Update 3 | 26.0.36039.7899 | 20.0 / Rio | `11.2.13.8` |
| 10.2 Update 3 | 25.0.31059.3231 | 19.0 / Tokyo | `10.3.1.15` |

## Observations

- **The handshake never changes.** Every IDE, regardless of how far
  apart in age, sends and receives the identical 5 bytes
  (`05 05 05 05 05` → `06 00 00 00 00`). Whatever this handshake
  negotiates, it isn't the thing driving the "expecting X.X.X.X"
  message — that string is not present anywhere on the wire in any
  capture.
- **The `VerifyPlatform` response is byte-identical across every capture
  against the *same* server** (all captures above talked to the one
  real PAServer 13.1 on this machine), match or mismatch alike — proving
  the pass/fail decision is purely **client-side**, not negotiated. To
  find out what it's actually comparing, we went further: extracted the
  real `paserver` binary from all six downloaded packages
  (19.0–37.0), ran each one for real, and captured `VerifyPlatform`'s
  response from each directly (no IDE involved). Result: **fully
  decoded.** `ServerMajorVersion` = `Major*10+Minor`, `ServerMinorVersion`
  = `Build*10+Patch` of the PAServer binary's own 4-part version (a
  different numbering scheme than the marketing "13.1" name), packed as
  variable-length tagged integers. Confirmed exact match against real
  binaries for 5 of 6 samples; the sixth (a two-digit `Patch` value)
  breaks the simple digit-packing assumption. Full writeup in
  NOTES.md, "Where the version-mismatch check actually happens — SOLVED."
- **The expected-version string is unique per IDE build**, not just per
  compiler line — 11.3, 12.3, 10.3.3, and 10.2.3 each reported a
  different "expecting" string despite 11.3 and 12.3 being adjacent
  releases.
- **Newer IDEs (11.3, 12.x) self-heal; 10.3.3 and 10.2.3 do not.** 11.3
  and 12.x both continue past the mismatch to check for (and upload) the
  PAServer package they expect, then complete the deploy handshake
  normally. 10.3.3 and 10.2.3 both give up immediately after
  `VerifyPlatform` — neither even attempts the file check. This
  suggests the self-healing/auto-update logic itself was added at some
  point between the Rio/Tokyo (10.x) and Alexandria (11.x) IDE
  generations, not just the version numbers being compared.
- **No literal "X.X.X.X" version string is ever sent as text** — it's
  reconstructed by the client from the two packed integers described
  above. The plaintext `13.1-scratch` fragment in `ScratchDir` is just
  the product name, a red herring for this particular check.
- **Ground truth for the real PAServer version behind each package:**
  LinuxPAServer19.0→`10.2.1.13`, 20.0→`11.2.13.8`, 21.0→`12.2.10.3`,
  22.0→`13.3.12.7`, 23.0→`14.3.14.2`, 37.0→`37.1.10.6` (matches the
  locally installed 13.1/Florence instance used for all the IDE
  captures above). These came straight from `paserver -help` on each
  extracted binary.
- **Confirmed: 10.2 Update 3's expected version doesn't match its own
  official download — an Embarcadero-side inconsistency, not ours.**
  `SetupLinux4Delphi.sh`'s `"tokyo"|"10.2.3"` case points at
  `.../19.0/PAServer/Release3/LinuxPAServer19.0.tar.gz`, which
  self-reports `10.2.1.13` — but a real Delphi 10.2 Update 3 IDE (build
  `25.0.31059.3231`) reported expecting `10.3.1.15` instead. Checked
  every other Tokyo/19.0 package on Embarcadero's CDN
  (base/Release1/Release2/Release3 — see NOTES.md) and none self-report
  `10.3.1.15`. Two pacommander version-spoof attempts also failed
  (formula-derived guesses, unverified for two-digit `Patch` values).
  To rule out our own tooling as the cause, connected the IDE **directly
  to the real, unmodified, official Release3 binary** with zero
  spoofing — same failure. This is not a wrong-download or spoofing
  problem; the official package and the IDE's own check simply disagree
  with each other. Not resolved on Embarcadero's end as far as we can
  tell — see NOTES.md for the full URL/version table and raw capture.
