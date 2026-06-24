# Repository Guidelines

## Project Structure & Module Organization

This repository centers on one maintained Bash installer: `scripts/SetupLinux4Delphi.sh`. It installs PAServer and Linux dependencies for Delphi development across supported distributions. The `legacy/` directory contains superseded historical scripts and should be used only for reference. Images and README assets live in `images/`. GitHub Actions configuration is in `.github/workflows/commit_test.yml`. Local helper files such as `test-local.ps1` may exist, but production changes should stay focused on the maintained script and documentation.

## Build, Test, and Development Commands

- `shellcheck scripts/SetupLinux4Delphi.sh` checks the main script; CI treats ShellCheck findings at error severity.
- `bash -n scripts/SetupLinux4Delphi.sh` performs a fast Bash syntax check.
- `shfmt -d scripts/SetupLinux4Delphi.sh` previews formatting differences without rewriting the file.
- `powershell -ExecutionPolicy Bypass -File .\test-local.ps1` runs local validation when available.

GitHub Actions also runs live install tests for Ubuntu 26.04 and RHEL 10. Push to a `test**` branch to exercise CI before sending changes to `main`.

## Coding Style & Naming Conventions

Keep the main script POSIX-aware where practical, but preserve existing Bash conventions. Use uppercase variable names for installer state such as `COMPILER`, `PRODUCT`, `RELEASE`, and `PASERVER_URL`. Keep version alias handling in the `case "$PARAM"` block and maintain clear package-manager branches for `apt`, `dnf`, `yum`, and `pacman`. Prefer small, readable conditionals over dense one-liners because this script is intended to be reviewed before running with `sudo`.

## Testing Guidelines

Run ShellCheck and `bash -n` before committing script changes. When adding Delphi releases or package-manager behavior, update help text and CI version references in the same change. For risky install logic, test in WSL, a VM, or a container rather than on a production host.

## Commit & Pull Request Guidelines

Recent commits use short, direct, mostly lowercase subjects, for example `add 13.1 support for issue #5`. Keep commits scoped to one behavior or documentation update. Pull requests should describe the affected distro or Delphi version, list local checks run, link related issues, and include relevant CI results. Add screenshots only for README or asset changes.

## Agent-Specific Instructions

Do not modify `legacy/` unless the task explicitly targets historical scripts. Avoid reverting local user changes. When changing supported versions, verify the PAServer URL from the Embarcadero DocWiki rather than inferring it from nearby entries.

## Script Architecture

`scripts/SetupLinux4Delphi.sh` has three main phases:

1. Argument parsing: `PARAM` defaults to the latest supported compiler version. The argument loop handles `--help` and optional package-manager overrides.
2. Version resolution: `case "$PARAM"` maps accepted aliases to `COMPILER`, `PRODUCT`, `RELEASE`, and `PASERVER_URL`; `ARCHIVE` is derived from the URL basename.
3. Distro detection and install: the script reads `/etc/os-release`, selects `apt`, `dnf`, `yum`, or `pacman`, installs packages, downloads PAServer, extracts it, and writes `/usr/local/bin/pa$PRODUCT.sh`.

## Adding Delphi Versions

When adding a point release, add the specific version case before the broader compiler-version case. Update the canonical compiler alias to point at the latest point release, adjust the default `PARAM` if it is the newest release overall, and update both help-text blocks. Also update `.github/workflows/commit_test.yml` when CI should test the new version.

The compiler version, such as `37.0` or `23.0`, is the canonical alias and should map to the latest point release for that compiler. Specific product versions, such as `13.0` or `12.2`, should keep exact entries.

## PAServer URLs

PAServer download URLs are not fully predictable. Use the Embarcadero DocWiki page for the authoritative current URL:

`https://docwiki.embarcadero.com/RADStudio/en/Installing_the_Platform_Assistant_on_Linux`

For older releases, compare existing `case` entries before making a change.
