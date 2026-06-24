#!/usr/bin/env pwsh
# test-local.ps1 - Run lint and install tests locally
#
# Requires: Docker Desktop for ShellCheck and install tests
#           WSL for the fast bash -n syntax check
#
# Usage:
#   .\test-local.ps1              # ShellCheck + syntax check only (fast)
#   .\test-local.ps1 -Ubuntu      # + Ubuntu 26.04 install test
#   .\test-local.ps1 -RHEL        # + RHEL 10 install test
#   .\test-local.ps1 -All         # + both install tests
#   .\test-local.ps1 -Version 13.0  # Override PAServer version (default: 13.1)

param(
    [switch]$Ubuntu,
    [switch]$RHEL,
    [switch]$All,
    [string]$Version = "13.1"   # Match CI default
)

$Root = $PSScriptRoot
$Failures = 0
$Skipped = 0

function Write-Header([string]$Text) {
    Write-Host ""
    Write-Host ("=" * 66) -ForegroundColor Cyan
    Write-Host "  $Text" -ForegroundColor Cyan
    Write-Host ("=" * 66) -ForegroundColor Cyan
}

function Invoke-Check([string]$Label, [scriptblock]$Body) {
    Write-Host "  Running: $Label ..." -ForegroundColor DarkGray
    & $Body
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  FAIL: $Label" -ForegroundColor Red
        $script:Failures++
    } else {
        Write-Host "  PASS: $Label" -ForegroundColor Green
    }
}

function Write-Skip([string]$Text) {
    Write-Host "  SKIP: $Text" -ForegroundColor Yellow
    $script:Skipped++
}

function Set-CheckExitCode([bool]$Passed) {
    if ($Passed) {
        $global:LASTEXITCODE = 0
    } else {
        $global:LASTEXITCODE = 1
    }
}

function Test-DockerDaemon {
    docker info 2>&1 | Out-Null
    return $LASTEXITCODE -eq 0
}

function Get-DockerDesktopPath {
    $Candidates = @(
        "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe",
        "${env:ProgramFiles(x86)}\Docker\Docker\Docker Desktop.exe",
        "$env:LOCALAPPDATA\Docker\Docker Desktop.exe"
    )

    foreach ($Candidate in $Candidates) {
        if ($Candidate -and (Test-Path -LiteralPath $Candidate)) {
            return $Candidate
        }
    }

    return $null
}

function Start-DockerIfNeeded {
    if (Test-DockerDaemon) {
        return $true
    }

    Write-Host "  Docker is installed but the daemon is not running; attempting to start Docker Desktop..." -ForegroundColor Yellow

    if ($IsWindows -or $env:OS -eq "Windows_NT") {
        $DockerDesktop = Get-DockerDesktopPath
        if (-not $DockerDesktop) {
            Write-Host "  Docker CLI found, but Docker Desktop executable was not found." -ForegroundColor Red
            return $false
        }

        Start-Process -FilePath $DockerDesktop -WindowStyle Hidden
    } else {
        Write-Host "  Automatic Docker startup is only implemented for Docker Desktop on Windows." -ForegroundColor Red
        return $false
    }

    for ($Attempt = 1; $Attempt -le 60; $Attempt++) {
        Start-Sleep -Seconds 2
        if (Test-DockerDaemon) {
            return $true
        }
        Write-Host "." -NoNewline -ForegroundColor DarkGray
    }

    Write-Host ""
    Write-Host "  Docker did not become ready within 120 seconds." -ForegroundColor Red
    return $false
}

# Pre-flight
$DockerOk = $false

Write-Header "Docker availability"

Invoke-Check "docker installed and daemon ready" {
    $DockerAvailable = $null -ne (Get-Command docker -ErrorAction SilentlyContinue)
    if (-not $DockerAvailable) {
        Write-Host "  Docker is not installed or is not on PATH." -ForegroundColor Red
        Set-CheckExitCode $false
        return
    }

    $script:DockerOk = Start-DockerIfNeeded
    Set-CheckExitCode $script:DockerOk
}

$WslAvailable = $null -ne (Get-Command wsl -ErrorAction SilentlyContinue)

# 1. bash -n syntax check (via WSL, no Docker needed)
Write-Header "Syntax check (bash -n)"

if ($WslAvailable) {
    Invoke-Check "bash -n via WSL" {
        $WslPath = (wsl wslpath ($Root -replace "\\", "/")) + "/scripts/SetupLinux4Delphi.sh"
        wsl bash -n $WslPath
    }
} else {
    Write-Skip "WSL not found - skipping bash -n check"
}

# 2. HTTP URL check (pure PowerShell, no Docker needed)
Write-Header "HTTP URL check"

Invoke-Check "no plain http:// URLs in script" {
    $Found = Select-String -Path "$Root\scripts\SetupLinux4Delphi.sh" -Pattern "http://" -SimpleMatch
    if ($Found) {
        Write-Host ""
        $Found | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
        cmd /c exit 1
    } else {
        cmd /c exit 0
    }
}

# 3. ShellCheck (via Docker)
Write-Header "ShellCheck"

if ($DockerOk) {
    Invoke-Check "shellcheck --severity=error" {
        docker run --rm `
            -v "${Root}:/workspace" `
            koalaman/shellcheck:stable `
            --severity=error `
            /workspace/scripts/SetupLinux4Delphi.sh
    }
} else {
    Write-Skip "Docker not running - skipping ShellCheck"
}

# 4. Ubuntu 26.04 install test (optional, slow)
if ($Ubuntu -or $All) {
    Write-Header "Ubuntu 26.04 install test  [version: $Version]  (~5-10 min)"

    if ($DockerOk) {
        Invoke-Check "Ubuntu 26.04: install + paserver starts" {
            $BashCommand = @(
                "set -e",
                "chmod +x /workspace/scripts/SetupLinux4Delphi.sh",
                "/workspace/scripts/SetupLinux4Delphi.sh $Version",
                ("/usr/local/bin/pa$($Version).sh " + [char]38),
                "sleep 15",
                "pgrep paserver"
            ) -join "`n"
            docker run --rm --privileged `
                -e DEBIAN_FRONTEND=noninteractive `
                -v "${Root}:/workspace" `
                ubuntu:26.04 `
                bash -c $BashCommand
        }
    } else {
        Write-Skip "Docker not running"
    }
}

# 5. RHEL 10 (UBI) install test (optional, slow)
if ($RHEL -or $All) {
    Write-Header "RHEL 10 (UBI) install test  [version: $Version]  (~5-10 min)"

    if ($DockerOk) {
        Invoke-Check "RHEL 10: install + paserver starts" {
            $BashCommand = @(
                "set -e",
                "chmod +x /workspace/scripts/SetupLinux4Delphi.sh",
                "/workspace/scripts/SetupLinux4Delphi.sh $Version",
                ("/usr/local/bin/pa$($Version).sh " + [char]38),
                "sleep 15",
                "pgrep paserver"
            ) -join "`n"
            docker run --rm --privileged `
                -v "${Root}:/workspace" `
                redhat/ubi10:latest `
                bash -c $BashCommand
        }
    } else {
        Write-Skip "Docker not running"
    }
}

# Summary
Write-Host ""
Write-Host ("=" * 66) -ForegroundColor Cyan
if ($Failures -eq 0 -and $Skipped -eq 0) {
    Write-Host "  All checks passed." -ForegroundColor Green
} elseif ($Failures -eq 0) {
    Write-Host "  No checks failed; $Skipped check(s) skipped." -ForegroundColor Yellow
} else {
    Write-Host "  $Failures check(s) failed." -ForegroundColor Red
}
Write-Host ("=" * 66) -ForegroundColor Cyan
Write-Host ""

exit $Failures
