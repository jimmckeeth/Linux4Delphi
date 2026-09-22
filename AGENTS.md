# Repository Guidelines

## Domain and Current Product Direction

Linux4Delphi provides Linux-side setup for Delphi PAServer across multiple Delphi releases. Historically, the repository centered on one Bash installer (`scripts/SetupLinux4Delphi.sh`) that installs prerequisites and one selected PAServer version.

Current direction: transition to a router model where `pacommander` owns PAServer version mapping, download/install, launch on a free port, and proxying; keep existing direct script behavior supported during transition.

## Architecture Intent and Ownership Boundaries

Treat responsibilities as two layers:

1. **Bootstrap layer (shell script)**
   - `scripts/SetupLinux4Delphi.sh` should converge on prerequisite installation plus pacommander install/startup.
   - During migration, direct PAServer install/launch behavior remains supported.

2. **Runtime router layer (pacommander)**
   - `pacommander` should own version selection, artifact retrieval, installation, per-version process management, and connection proxying for incoming Delphi sessions.

Avoid split ownership of version mapping logic long-term. Target owner is pacommander; script should become thin bootstrap.

## Key Invariants and Deliberate Non-Invariants

### Invariants to preserve unless explicitly changed
- Keep backward-compatible script entry UX (`sudo SetupLinux4Delphi.sh [version] [pkgmgr]`) while dual mode exists.
- Keep distro/package-manager branches (`apt`, `dnf`, `yum`, `pacman`) explicit and auditable in `scripts/SetupLinux4Delphi.sh`.
- Keep PAServer URL updates tied to Embarcadero DocWiki verification, not inferred from nearby entries.

### Not fixed by policy (may be redesigned)
- Current install/state layout used by script (`/opt/PAServer/$PRODUCT`, `/usr/local/bin/pa$PRODUCT.sh`, `~/.PAServer/$PRODUCT-scratch`) may change if router architecture needs a different storage/process model.

## Entry Points and Startup Flow

- `scripts/SetupLinux4Delphi.sh`
  - Parses version and optional package-manager override.
  - Maps aliases to `COMPILER`, `PRODUCT`, `RELEASE`, `PASERVER_URL` in `case "$PARAM"`.
  - Installs prerequisites by distro.
  - Currently downloads/extracts PAServer and writes `pa$PRODUCT.sh` that runs `paserver -port=64211`.

- `pacommander.dpr`
  - Currently a console skeleton (`System.SysUtils` + TODO in main try/except).
  - This is the intended seam for router bootstrap and host lifecycle orchestration.

- `pacommander.dproj`
  - Console project with `<Platforms>` currently `Win32=True`, `Linux64=False`.
  - Linux-side router delivery requires enabling Linux64 and aligning build/release flow.

## Project Structure and Change Surfaces

- `scripts/SetupLinux4Delphi.sh`: production installer/bootstrap logic.
- `legacy/*.sh`: historical reference only; do not modify unless task explicitly targets legacy behavior.
- `pacommander.dpr`, `pacommander.dproj`: router executable entry and build settings.
- `README.md`: public contract for supported versions, aliases, usage modes, install locations.
- `.github/workflows/commit_test.yml`: CI guard for shell lint + live install/start validation.

## Coupled Changes Playbooks

### A) Add or change PAServer version mapping
Update all of:
1. `scripts/SetupLinux4Delphi.sh` alias map and `PASERVER_URL` entries.
2. Script help text (`--help`).
3. `README.md` version matrix/alias descriptions.
4. No CI edit needed for routine version additions: `.github/workflows/commit_test.yml`'s `discover_versions` job derives its test matrix from the `PRODUCT="..."` entries in the script (newest 5 by version sort). Only touch the workflow file itself if the *mechanism* needs to change (e.g. how many versions are covered, or the discovery logic).

Keep compiler aliases (`37.0`, `23.0`, etc.) mapping to latest point release, while explicit product aliases (`13.0`, `12.2`) stay exact.

### B) Implement or extend router mode in pacommander
Synchronize at minimum:
1. Router behavior in Delphi units rooted from `pacommander.dpr`.
2. Script bootstrap behavior in `scripts/SetupLinux4Delphi.sh` (what it installs/starts by default).
3. README usage/migration explanation (direct mode vs router mode).
4. CI checks for whichever mode is default and any compatibility path still promised.

### C) Change install/state layout
If layout changes for router mode, update together:
- Script output text and generated launcher behavior.
- README installation-location section.
- Router lookup logic for existing installs/state.

## Testing and Verification Guidance

Current automated checks are shell/install focused:
- `shellcheck scripts/SetupLinux4Delphi.sh`
- `bash -n scripts/SetupLinux4Delphi.sh`
- CI in `.github/workflows/commit_test.yml`:
  - `discover_versions` extracts the 5 newest `PRODUCT="..."` versions directly from the script (no hardcoded version list to maintain).
  - Ubuntu 26.04 and RHEL 10 each run as a matrix over those versions: install, start `pa<version>.sh`, verify `pgrep paserver`.
  - The URL-guessing path (`try_guess_paserver_url`, for versions not explicitly listed) is not covered by this matrix and has no automated test yet.

For pacommander router work, testing is mandatory before calling behavior stable. Validate at least:
1. **Version identification**: incoming connection metadata is parsed into the correct target PAServer version.
2. **Connection handoff**: router launches/reuses the correct backend PAServer and connects client traffic to it.
3. **Proxy routing**: bidirectional proxying works without protocol corruption, including disconnect/reconnect behavior.
4. **Missing-version path**: when target version is absent, install flow succeeds and then connection is routed.
5. **Port management**: backend PAServer free-port allocation avoids collisions while router remains on 64211.

There is no dedicated pacommander test project yet; add automated verification (unit/integration/CI command checks) as router implementation progresses.

## Practical Rules for Future Agents

- Prefer targeted edits in `scripts/SetupLinux4Delphi.sh`; keep package-manager logic readable.
- Do not modify `legacy/` for new behavior.
- Do not claim router behavior exists until implemented in pacommander sources.
- Preserve direct script mode unless a change explicitly removes compatibility and updates docs/CI in the same patch.
- For PAServer URL changes, verify against:
  - https://docwiki.embarcadero.com/RADStudio/en/Installing_the_Platform_Assistant_on_Linux

## Important Caveats / Open Items

- Router protocol detection details (how required PAServer version is inferred from inbound connection data) are not yet implemented/documented in source.
- `README.md` and script alias mapping can drift; always verify both when changing version support.