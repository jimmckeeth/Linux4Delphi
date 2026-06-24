# Linux4Delphi Setup

[![ShellCheck](https://img.shields.io/github/actions/workflow/status/jimmckeeth/linux4delphi/commit_test.yml?job=ShellCheck&label=ShellCheck&logo=shell)](https://github.com/jimmckeeth/linux4delphi/actions/workflows/commit_test.yml)
[![Ubuntu 26.04 with Delphi 13](https://img.shields.io/github/actions/workflow/status/jimmckeeth/linux4delphi/commit_test.yml?job=ubuntu_test&label=Ubuntu%2026.04%20with%20Delphi%2013&logo=ubuntu)](https://github.com/jimmckeeth/linux4delphi/actions/workflows/commit_test.yml)
[![RHEL 10 with Delphi 13](https://img.shields.io/github/actions/workflow/status/jimmckeeth/linux4delphi/commit_test.yml?job=rhel_test&label=RHEL%2010%20with%20Delphi%2013&logo=redhat&logoColor=red)](https://github.com/jimmckeeth/linux4delphi/actions/workflows/commit_test.yml)

**Update**: This project was formerly known as *Delphi-on-Linux-Setup*, but it has been renamed to *Linux4Delphi* to better reflect the scope of the project. Update your bookmarks and references accordingly.

Scripts and resources to simplify the setup and development with Delphi on Linux. It should work with all x86 64-bit Linux distros that Delphi supports in WSL, Virtual Machines, or running on hardware native.

Supporting Delphi 10.2 *Tokyo* (19.0) through Delphi 13 *Florence* (37.0), from one script. The installation location changed now, so it isn't user specific.

<a href="images/Linux4Delphi-Logo.webp">
  <img src="images/Linux4Delphi-Logo-256px.webp" align="right" alt="Linux4Delphi Logo" width="256" height="520" vspace="10" hspace="10" />
</a>

## Basic Usage

The same script works for both RedHat/Fedora and Ubuntu/Debian. There are a number of other quality of life improvements too. To run it from the web use either of the following commands:

```bash
curl -fsSL https://tinyurl.com/SetupLinux4Delphi | sudo bash 
```

If you don't have curl you can use wget instead (Debian usually excludes curl by default):

```bash
wget -qO - https://tinyurl.com/SetupLinux4Delphi | sudo bash 
```

⚠️*Warning*: It is recommended to [locally review the script](scripts/SetupLinux4Delphi.sh) before running it in a *production* environment.

✅*Update*: To improve performance, especially if testing in a containerized environment, calls to `apt`, `yum`, & `dnf` use  `--no-install-recommends` or `--setopt=install_weak_deps=False` respectively, which prevents the installation of *recommended packages*, that are not essential for the core functionality. It also makes the script less likely to change unrelated packages you might need.

## Detailed Usage

It defaults to the latest, but you can specify any version and optionally override the package manager detection.

Usage: `sudo SetupLinux4Delphi.sh [version] [pkgmgr]`

Where [version] is one of the following:

* Florence 13.1    = `Florence`, `37.0`, `13.1` or *blank*
* Florence 13.0    = `13.0`
* Athens 12.3      = `Athens`, `23.0`, `12.3`, or `12`
* Athens 12.2      = `12.2`
* Athens 12.1      = `12.1`
* Athens 12.0      = `12.0`
* Alexandria 11.3  = `Alexandria`, `22.0`, `11.3`, or `11`
* Alexandria 11.2  = `11.2`
* Alexandria 11.1  = `11.1`
* Alexandria 11.0  = `11.0`
* Sydney 10.4.1    = `Sydney`, `21.0`, or `10.4.1`
* Sydney 10.4.0    = `10.4.0`
* Rio 10.3.3       = `Rio`, `20.0`, `10.3`, or `10.3.3`
* Rio 10.3.2       = `10.3.2`
* Rio 10.3.1       = `10.3.1`
* Rio 10.3.0       = `10.3.0`
* Tokyo 10.2.3     = `Tokyo`, `19.0`, `10.2`, or `10.2.3`
* Tokyo 10.2.0     = `10.2`

The less specific labels are the latest versions, while the more specific labels refer to the exact version.

*🧪Experimental:* [pkgmgr] parameter allows you to optionally override the os and package manager detection. Valid values are:

* `apt`  - for Ubuntu/Debian based distros
* `yum`  - for RedHat based distros
* `dnf`  - for Fedora based distros
* `pacman` - for Arch based distros (🧪experimental, not fully tested)

**Note**: Just because you can install it on a distro doesn't mean it is supported by Delphi. See the [Official Platform Support list](https://docwiki.embarcadero.com/PlatformStatus/en/Main_Page). 

## Tested Distros

I tested Delphi 13 Florence against the following distros with this script:

* Debian based
  * Ubuntu 18.04
  * Ubuntu 20.04
  * Ubuntu 22.04
  * Ubuntu 24.04
  * Ubuntu 26.04
  * Kali Linux Rolling 2.6.3.0
  * Debian 13 (trixie)
  * Pengwin (WSL)
* Fedora based
  * Fedora Linux 42
  * Fedora Remix for WSL
  * Rocky Linux 9.6 (Blue Onyx)
  * Alma Linux 9.6 (Safe Margay)
  * RHEL 10
  * Oracle Linux Server 9.5
* Other
  * Arch Linux (WSL) - *🧪 experimental*
  * Steam OS 3.7.17 (Arch based) - *🧪 experimental* with partial support. The SDK import misses some libraries, so if build against a different SDK then I was able to run it on Steam OS. If you can track down the issues then please file an issue or PR.

See the [Official Platform Support list](https://docwiki.embarcadero.com/PlatformStatus/en/Main_Page).

It detects the distro and version and works with `apt`, `yum`, `dnf`, and `pacman` (experimental) package managers as necessary. You can [view the full source](https://github.com/jimmckeeth/Delphi-on-Linux-Setup/blob/main/scripts/SetupLinux4Delphi.sh), which is recommended before running it on your hardware.

## Installation changes

The old version of the script installed it based on the compiler version number, now it is based on the product version number. The reason for the name change is to support installation of multiple versions of PAServer. Technically both *12.0* and *12.3* are still **23.0**, so to allow installing both versions they need a unique name. I thought that was easier than using the *build number*.

It defaults to a **blank password**. You should *probably* change that.

The installation locations are as follows:

* `INSTALL_DIR="/opt/PAServer/$PRODUCT"`
* `SCRIPT_PATH="/usr/local/bin/pa$PRODUCT.sh"`
* `SCRATCH_DIR="$REAL_HOME/.PAServer/$PRODUCT-scratch"`

Where `$PRODUCT` is 13.1, 13.0, 12.2, etc. So you launch the latest *Florence* PAServer with `pa13.1.sh`.

## More information

The installation of packages is based on the [DocWiki](https://docwiki.embarcadero.com/RADStudio/en/Linux_Application_Development), but with a few changes to address nuances of different distros & installs. If the script doesn't work on your distro of choice then see if the original DocWiki instructions do, and if that still doesn't work, then your distro or installation might not be supported.

DocWiki Links:

* [Linux Application Development](https://docwiki.embarcadero.com/RADStudio/en/Linux_Application_Development)
* [Installing the Platform Assistant on Linux](https://docwiki.embarcadero.com/RADStudio/en/Installing_the_Platform_Assistant_on_Linux)
* [PAServer Overview](https://docwiki.embarcadero.com/RADStudio/en/PAServer,_the_Platform_Assistant_Server_Application)
* [Platform Assistant Server Errors Index](https://docwiki.embarcadero.com/RADStudio/en/Platform_Assistant_Server_Errors_Index)
* [Setting Options for the Platform Assistant](https://docwiki.embarcadero.com/RADStudio/en/Setting_Options_for_the_Platform_Assistant)
* [FmxLinux/FireMonkey for Linux](https://docwiki.embarcadero.com/RADStudio/en/FireMonkey_for_Linux)
* [Delphi Compiler Versions](https://docwiki.embarcadero.com/RADStudio/en/Compiler_Versions)
* [Python 3.6 issue](https://blogs.embarcadero.com/setting-up-ubuntu-22-04-for-delphi-11-2-debugging/)

## History

This was originally a series of [GISTs](https://gist.github.com/jimmckeeth/1cb657694d1ea18335782213097c8a33) that myself and [Ian Barker](https://gist.github.com/checkdigits/f910e3c4b308a25b31b9a5c1f23c5461) were updating. Figured it was time to turn it into a full GitHub project where we can collect all the scripts and add additional resources.

## Installing Ubuntu with WSL2 on Windows 11

Windows Subsystem for Linux 2 (WSL2) is a quick and lightweight way to get started with Linux from within Windows 11. It provides a lightweight virtualized Linux environment that integrates well with Windows.

Microsoft has a [full article](https://docs.microsoft.com/en-us/windows/wsl/install) with all the details. This is a summary for quick reference. There are BIOS configuration steps that may be required depending on your hardware.

On Windows you need to do this from an elevated (administrator) command prompt or PowerShell window. Easiest way is **Win+X,A**.

```pwsh
wsl --install -d Ubuntu
```

Your machine may reboot before installation asks you to enter a username and password. This will be your Linux credential for the Ubuntu distribution, and are separate from your Windows credentials.

Start Ubuntu from the start menu, or from the terminal by typing `ubuntu`

### Then run the following script

```bash
curl -fsSL https://tinyurl.com/SetupLinux4Delphi | sudo bash
```
