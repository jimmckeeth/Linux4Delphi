#!/bin/bash
# 
# Single step download and execute with the following:
# curl -fsSL https://tinyurl.com/SetupLinux4Delphi | sudo bash
#  or
# wget -qO - https://tinyurl.com/SetupLinux4Delphi | sudo bash 
#
echo "_____________________________________________________________"
echo ""
echo "Setup Linux for Delphi development version 2025-12-19"
echo "_____________________________________________________________"
echo ""
echo "This script requires sudo privileges"
echo "More info: https://github.com/jimmckeeth/Linux4Delphi"
echo ""
# Stop on all errors
set -e

if [[ $EUID -ne 0 ]]; then
  echo "Please run this script with sudo."
  exit 1
fi

# Every explicit PAServer product version below needs a matching case branch
# further down; this array only tracks which one is newest, so the default
# alias and the help text's [DEFAULT] marker can't drift out of sync with
# each other (or get left pointing at an old version) the way separate
# hardcoded literals did.
KNOWN_VERSIONS=(
    10.2.0 10.2.3
    10.3.0 10.3.1 10.3.2 10.3.3
    10.4.0 10.4.1 10.4.2
    11.0 11.1 11.2 11.3
    12.0 12.1 12.2 12.3
    13.0 13.1 13.2
)
LATEST_VERSION="$(printf '%s\n' "${KNOWN_VERSIONS[@]}" | sort -V | tail -1)"

# Prints " [DEFAULT]" when $1 is the newest entry in KNOWN_VERSIONS, for tagging help text.
version_tag() {
    if [[ "$1" == "$LATEST_VERSION" ]]; then
        echo " [DEFAULT]"
    fi
}

# Parse arguments
PARAM="$LATEST_VERSION" # Default version
PKG_OVERRIDE=""

# Function to download files using whichever tool is available
download_file() {
    local url=$1
    local dest=$2
    if command -v wget >/dev/null 2>&1; then
        wget -q -O "$dest" "$url"
    elif command -v curl >/dev/null 2>&1; then
        curl -fsSL -o "$dest" "$url"
    else
        echo "❌ Error: Neither wget nor curl found. Please install one to continue."
        exit 1
    fi
}

while [[ $# -gt 0 ]]; do
  key="$(echo "$1" | tr '[:upper:]' '[:lower:]')"
  case $key in
    apt|dnf|yum|pacman)
      PKG_OVERRIDE="$key"
      shift
      ;;
    help|--help|h|--h|-h)
      echo "Usage: sudo SetupLinux4Delphi.sh [version] [manager]"
      echo ""
      echo "  manager            = apt, pacman, dnf, or yum (force specific package manager)"
      echo ""
      echo "Where [version] is one of the following:"
      echo "  37.0, 13.2         = Florence 13.2$(version_tag 13.2)"
      echo "  13.1               = Florence 13.1$(version_tag 13.1)"
      echo "  13.0               = Florence 13.0$(version_tag 13.0)"
      echo "  23.0, 12.3, 12     = Athens 12.3$(version_tag 12.3)"
      echo "  12.2               = Athens 12.2$(version_tag 12.2)"
      echo "  12.1               = Athens 12.1$(version_tag 12.1)"
      echo "  12.0               = Athens 12.0$(version_tag 12.0)"
      echo "  22.0, 11.3, 11     = Alexandria 11.3$(version_tag 11.3)"
      echo "  11.2               = Alexandria 11.2$(version_tag 11.2)"
      echo "  11.1               = Alexandria 11.1$(version_tag 11.1)"
      echo "  11.0               = Alexandria 11.0$(version_tag 11.0)"
      echo "  21.0, 10.4, 10.4.2 = Sydney 10.4.2$(version_tag 10.4.2)"
      echo "  10.4.1             = Sydney 10.4.1$(version_tag 10.4.1)"
      echo "  10.4.0             = Sydney 10.4.0$(version_tag 10.4.0)"
      echo "  20.0, 10.3, 10.3.3 = Rio 10.3.3$(version_tag 10.3.3)"
      echo "  10.3.2             = Rio 10.3.2$(version_tag 10.3.2)"
      echo "  10.3.1             = Rio 10.3.1$(version_tag 10.3.1)"
      echo "  10.3.0             = Rio 10.3.0$(version_tag 10.3.0)"
      echo "  19.0, 10.2, 10.2.3 = Tokyo 10.2.3$(version_tag 10.2.3)"
      echo "  10.2               = Tokyo 10.2.0$(version_tag 10.2.0)"
      exit 0
      ;;
    *)
      PARAM="$key"
      shift
      ;;
  esac
done

case "$PARAM" in
    # Florence
    "37.0"|"13.2"|"florence")
        COMPILER="37.0"
        PRODUCT="13.2"
        RELEASE="Florence"
        PASERVER_URL="https://altd.embarcadero.com/releases/studio/37.0/132/LinuxPAServer37.0.tar.gz"
        ;;
    "13.1")
        COMPILER="37.0"
        PRODUCT="13.1"
        RELEASE="Florence"
        PASERVER_URL="https://altd.embarcadero.com/releases/studio/37.0/131/LinuxPAServer37.0.tar.gz"
        ;;
    "13.0")
        COMPILER="37.0"
        PRODUCT="13.0"
        RELEASE="Florence"
        PASERVER_URL="https://altd.embarcadero.com/releases/studio/37.0/130/LinuxPAServer37.0.tar.gz"
        ;;
    # Athens
    "23.0"|"12.3"|"12"|"athens")
        COMPILER="23.0"
        RELEASE="Athens"
        PRODUCT="12.3"
        PASERVER_URL="https://altd.embarcadero.com/releases/studio/23.0/123/LinuxPAServer23.0.tar.gz"
        ;;
    "12.2")
        COMPILER="23.0"
        PRODUCT="12.2"
        RELEASE="Athens"
        PASERVER_URL="https://altd.embarcadero.com/releases/studio/23.0/122/1221/LinuxPAServer23.0.tar.gz"
        ;;
    "12.1")
        COMPILER="23.0"
        PRODUCT="12.1"
        RELEASE="Athens"
        PASERVER_URL="https://altd.embarcadero.com/releases/studio/23.0/121/1211/LinuxPAServer23.0.tar.gz"
        ;;
    "12.0")
        COMPILER="23.0"
        PRODUCT="12.0"
        RELEASE="Athens"
        PASERVER_URL="https://altd.embarcadero.com/releases/studio/23.0/120/LinuxPAServer23.0.tar.gz"
        ;;
    # Alexandria
    "22.0"|"11"|"11.3"|"alexandria")
        COMPILER="22.0"
        PRODUCT="11.3"
        RELEASE="Alexandria"
        PASERVER_URL="https://altd.embarcadero.com/releases/studio/22.0/1131/LinuxPAServer22.0.tar.gz"
    ;;
    "11.0")
        COMPILER="22.0"
        PRODUCT="11.0"
        RELEASE="Alexandria"
        PASERVER_URL="https://altd.embarcadero.com/releases/studio/22.0/LinuxPAServer22.0.tar.gz"
    ;;
    "11.1")
        COMPILER="22.0"
        PRODUCT="11.1"
        RELEASE="Alexandria"
        PASERVER_URL="https://altd.embarcadero.com/releases/studio/22.0/111/LinuxPAServer22.0.tar.gz"
    ;;
    "11.2")
        COMPILER="22.0"
        PRODUCT="11.2"
        RELEASE="Alexandria"
        PASERVER_URL="https://altd.embarcadero.com/releases/studio/22.0/112/LinuxPAServer22.0.tar.gz"
    ;;  
    # Sydney
    "10.4"|"10.4.2"|"sydney"|"21.0")
        COMPILER="21.0"
        PRODUCT="10.4.2"
        RELEASE="Sydney"
        PASERVER_URL="https://altd.embarcadero.com/releases/studio/21.0/2/PAServer/LinuxPAServer21.0.tar.gz"
    ;;
    "10.4.1")
        COMPILER="21.0"
        PRODUCT="10.4.1"
        RELEASE="Sydney"
        PASERVER_URL="https://altd.embarcadero.com/releases/studio/21.0/1/PAServer/LinuxPAServer21.0.tar.gz"
    ;;
    "10.4.0")
        COMPILER="21.0"
        PRODUCT="10.4.0"
        RELEASE="Sydney"
        PASERVER_URL="https://altd.embarcadero.com/releases/studio/21.0/PAServer/LinuxPAServer21.0.tar.gz"
    ;;
    # Rio
    "10.3"|"rio"|"10.3.3")
        COMPILER="20.0"
        PRODUCT="10.3.3"
        RELEASE="Rio"
        PASERVER_URL="https://altd.embarcadero.com/releases/studio/20.0/PAServer/Release3/LinuxPAServer20.0.tar.gz"
    ;;
    "10.3.2")
        COMPILER="20.0"
        PRODUCT="10.3.2"
        RELEASE="Rio"
        PASERVER_URL="https://altd.embarcadero.com/releases/studio/20.0/PAServer/Release2/LinuxPAServer20.0.tar.gz"
    ;;
    "10.3.1")
        COMPILER="20.0"
        PRODUCT="10.3.1"
        RELEASE="Rio"
        PASERVER_URL="https://altd.embarcadero.com/releases/studio/20.0/PAServer/Release1/LinuxPAServer20.0.tar.gz"
    ;;
    "10.3.0")
        COMPILER="20.0"
        PRODUCT="10.3.0"
        RELEASE="Rio"
        PASERVER_URL="https://altd.embarcadero.com/releases/studio/20.0/PAServer/LinuxPAServer20.0.tar.gz"
    ;;
    # Tokyo
    "10.2")
        COMPILER="19.0"
        PRODUCT="10.2.0"
        RELEASE="Tokyo"
        PASERVER_URL="https://altd.embarcadero.com/releases/studio/19.0/PAServer/LinuxPAServer19.0.tar.gz"
    ;;
    "tokyo"|"10.2.3")
        COMPILER="19.0"
        PRODUCT="10.2.3"
        RELEASE="Tokyo"
        PASERVER_URL="https://altd.embarcadero.com/releases/studio/19.0/PAServer/Release3/LinuxPAServer19.0.tar.gz"
    ;;
esac

# Attempt to locate a PAServer URL for versions not explicitly listed.
# Probes candidate URLs derived from observed Embarcadero URL patterns.
try_guess_paserver_url() {
    local input="$1"
    local base="https://altd.embarcadero.com/releases/studio"
    local major minor patch has_patch compiler release product digits

    if [[ "$input" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
        major="${BASH_REMATCH[1]}"; minor="${BASH_REMATCH[2]}"; patch="${BASH_REMATCH[3]}"; has_patch=1
    elif [[ "$input" =~ ^([0-9]+)\.([0-9]+)$ ]]; then
        major="${BASH_REMATCH[1]}"; minor="${BASH_REMATCH[2]}"; patch="0"; has_patch=0
    else
        return 1
    fi

    # Map product major version to internal compiler version and release name.
    # Compiler numbers tracked the product major 1:1 through 23.0 (Athens/12.x),
    # then jumped to 37.0 for Florence/13.x. 14.x/15.x aren't released yet, so
    # 38.0/39.0 below are an unverified extrapolation (assuming the pre-jump
    # +1-per-major pattern resumed) rather than a confirmed mapping — probing
    # still decides whether a guess is actually used, and the caller prints an
    # extra warning whenever `release` is empty.
    case "$major" in
        10)
            case "$minor" in
                2) compiler="19.0"; release="Tokyo" ;;
                3) compiler="20.0"; release="Rio" ;;
                4) compiler="21.0"; release="Sydney" ;;
                *) return 1 ;;
            esac
            product="${major}.${minor}.${patch}"
            digits="${major}${minor}${patch}"
            ;;
        11|12|13|14|15)
            # These eras are only ever named major.minor (no third-level patch
            # release like 10.x's Release1/2/3); reject a 3-component input
            # instead of silently ignoring the patch and guessing major.minor.
            if [ "$has_patch" -eq 1 ]; then
                return 1
            fi
            case "$major" in
                11) compiler="22.0"; release="Alexandria" ;;
                12) compiler="23.0"; release="Athens" ;;
                13) compiler="37.0"; release="Florence" ;;
                14) compiler="38.0"; release="" ;;
                15) compiler="39.0"; release="" ;;
            esac
            product="${major}.${minor}"
            digits="${major}${minor}"
            ;;
        *) return 1 ;;
    esac

    # Build ordered candidate list based on the URL pattern for each era.
    local candidates=()
    case "$compiler" in
        "19.0"|"20.0")
            # Tokyo/Rio: updates use PAServer/Release{N}/
            if [ "$patch" -eq 0 ]; then
                candidates+=("$base/$compiler/PAServer/LinuxPAServer${compiler}.tar.gz")
            else
                candidates+=(
                    "$base/$compiler/PAServer/Release${patch}/LinuxPAServer${compiler}.tar.gz"
                    "$base/$compiler/PAServer/LinuxPAServer${compiler}.tar.gz"
                )
            fi
            ;;
        "21.0")
            # Sydney: updates use {N}/PAServer/
            if [ "$patch" -eq 0 ]; then
                candidates+=("$base/$compiler/PAServer/LinuxPAServer${compiler}.tar.gz")
            else
                candidates+=(
                    "$base/$compiler/${patch}/PAServer/LinuxPAServer${compiler}.tar.gz"
                    "$base/$compiler/PAServer/LinuxPAServer${compiler}.tar.gz"
                )
            fi
            ;;
        "22.0")
            # Alexandria: base release has no subdir; updates use {digits}[1]/
            if [ "$minor" -eq 0 ]; then
                candidates+=("$base/$compiler/LinuxPAServer${compiler}.tar.gz")
            else
                candidates+=(
                    "$base/$compiler/${digits}1/LinuxPAServer${compiler}.tar.gz"
                    "$base/$compiler/${digits}/LinuxPAServer${compiler}.tar.gz"
                )
            fi
            ;;
        *)
            # Athens/Florence and future: flat {digits}/ or nested {digits}/{digits}1/
            candidates+=(
                "$base/$compiler/${digits}/LinuxPAServer${compiler}.tar.gz"
                "$base/$compiler/${digits}/${digits}1/LinuxPAServer${compiler}.tar.gz"
            )
            ;;
    esac

    echo "Version '$input' is not explicitly listed. Probing for PAServer..."
    local url status
    for url in "${candidates[@]}"; do
        printf "  Trying: %s\n" "$url"
        # This runs before prerequisites are installed, so only wget or curl
        # (whichever, if either, is already present) can be relied on here.
        if command -v wget >/dev/null 2>&1; then
            status=$(wget --spider --server-response --timeout=10 "$url" 2>&1 \
                | awk '/^ *HTTP\// {code=$2} END {print code}')
        elif command -v curl >/dev/null 2>&1; then
            status=$(curl -sI --max-time 10 "$url" 2>/dev/null | awk 'NR==1{print $2}' | tr -d '\r')
        else
            status=""
        fi
        if [ "$status" = "200" ]; then
            PASERVER_URL="$url"
            COMPILER="$compiler"
            RELEASE="${release:-Unreleased}"
            PRODUCT="$product"
            echo "  Found!"
            echo "WARNING: Using a guessed URL — verify this PAServer matches your IDE version."
            if [ -z "$release" ]; then
                echo "WARNING: Compiler $compiler for $product is an unverified extrapolation," \
                     "not a confirmed mapping — double-check against the DocWiki before relying on it."
            fi
            return 0
        fi
    done

    echo "Could not locate a PAServer for '$input'. Check https://altd.embarcadero.com/releases/studio/ manually."
    return 1
}

if [ -z "$PASERVER_URL" ]; then
    if ! try_guess_paserver_url "$PARAM"; then
        echo "Unknown version: $PARAM"
        echo "Run with 'help' to see supported versions."
        exit 1
    fi
fi

ARCHIVE="${PASERVER_URL##*/}"

echo "Setting up for Delphi $PRODUCT $RELEASE ($COMPILER)"
echo "Using PAServer URL: $PASERVER_URL"
echo ""
# Set defaults
INSTALL_DIR="/opt/PAServer/$PRODUCT"
SCRIPT_PATH="/usr/local/bin/pa$PRODUCT.sh"
# Get the actual user who invoked sudo
REAL_USER=${SUDO_USER:-$USER}
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
SCRATCH_DIR="$REAL_HOME/.PAServer/$PRODUCT-scratch"
echo "Installation directory: $INSTALL_DIR"
echo "Launch script path: $SCRIPT_PATH"
echo "" 

# Detect distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
else
    echo "Cannot determine Linux distribution. Aborting."
    exit 1
fi

if [ "$(uname -m)" != "x86_64" ]; then
    echo "This script requires a x86_64-bit operating system."
    exit 1
fi 

if [[ -n "$PKG_OVERRIDE" ]]; then
    PKG="$PKG_OVERRIDE"
    echo "Manual override: Using package manager '$PKG'"
elif [[ "$ID" == "ubuntu" || "$ID" == "debian" || "$ID_LIKE" == *"debian"* || "$ID_LIKE" == *"ubuntu"* || "$ID" == "kali" ]]; then
    # Ubuntu/Debian/Kali logic
    PKG="apt"
    if [[ ("$ID" == "ubuntu" && "$(echo "$VERSION_ID < 16.04" | bc)" -eq 1) || ("$ID" == "debian" && "$(echo "$VERSION_ID < 10" | bc)" -eq 1) ]]; then
        echo "This script requires at least Ubuntu 16.04 or Debian 10."
        exit 1
    fi
elif [[ "$ID" == "rhel" || "$ID" == "centos" || "$ID" == "fedora" || "$ID_LIKE" == *"rhel"* || "$ID_LIKE" == *"fedora"* ]]; then
    # RedHat/Fedora/CentOS logic
    if command -v dnf >/dev/null 2>&1; then
      PKG="dnf"
    else
      PKG="yum"
    fi
elif [[ "$ID" == "steamos" || "$ID" == "athena" || "$ID" == "arch" || "$ID_LIKE" == *"arch"* ]]; then
    # SteamOS/Athena/Arch Linux logic
    PKG="pacman"
else
    echo "Aborting! Unsupported Linux distribution: $NAME $VERSION_ID ($ID)"
    exit 1
fi

echo "Detected Linux distribution: $NAME $VERSION_ID ($ID)"
echo "Using package manager: $PKG"
echo ""

if [[ "$PKG" == "apt" ]]; then
    echo "__________________________________________________________________"
    echo ""
    echo "Updating the local package directory"
    if ! apt update -y; then
        echo "Update failed. Aborting."
        exit 1
    fi
fi

if [[ "$PKG" == "apt" ]]; then
    # Pre-install keyboard-configuration to avoid interactive prompts that can hang on fresh installs
    # This prevents the "Ctrl chars" issue on fresh Debian setups
    echo "Pre-configuring keyboard-configuration..."
    DEBIAN_FRONTEND=noninteractive apt install keyboard-configuration --no-install-recommends -y 
fi

echo "__________________________________________________________________"
echo ""
echo "Upgrading any outdated packages"
if [[ "$PKG" == "apt" ]]; then
    if ! apt dist-upgrade --no-install-recommends -y; then
        echo "Upgrade failed. Aborting."
        exit 1
    fi
elif [[ "$PKG" != "pacman" ]]; then
    if ! $PKG upgrade -y; then
        echo "Upgrade failed. Aborting."
        exit 1
    fi
fi
# For pacman, upgrade and install are done in one step below

echo "__________________________________________________________________"
echo ""
echo "Installing packages required for Delphi & FMXLinux"
echo "https://docwiki.embarcadero.com/RADStudio/en/Linux_Application_Development"
osmesa=
if [[ "$PKG" == "apt" ]]; then
    # Determine the correct ncurses package
    if apt-cache show libncurses6 2>/dev/null | grep -q 'Package:'; then
      NCURSES_PKG="libncurses6"
    elif apt-cache show libncurses5 2>/dev/null | grep -q 'Package:'; then
      NCURSES_PKG="libncurses5"
    else
      echo "No suitable ncurses package found."
      exit 1
    fi
    if ! apt install openssh-server -y --no-install-recommends; then
      echo "Warning: openssh-server installation failed, removing..."
      apt purge openssh-server -y 
    fi
    # Removed libosmesa-dev from strict requirements
    if ! apt install joe wget p7zip-full curl build-essential zlib1g-dev libcurl4-gnutls-dev python3 libpython3-dev libgtk-3-dev $NCURSES_PKG xorg libgl1-mesa-dev libgtk-3-bin libc6-dev -y --no-install-recommends; then
        echo "Required package installation failed. Aborting."
        exit 1
    fi
    # Optional installation of OSMesa (handles missing package errors gracefully)
    echo "Attempting to install optional libosmesa-dev..."
    if apt install libosmesa-dev -y --no-install-recommends 2>/dev/null; then
        osmesa="Installed optional libosmesa-dev successfully."
    else
        echo "libosmesa-dev not found, checking for libosmesa6-dev..."
        if apt install libosmesa6-dev -y --no-install-recommends  2>/dev/null; then
             osmesa="Installed optional libosmesa6-dev successfully."
        else
             osmesa="Warning: Optional package libosmesa-dev (or libosmesa6-dev) was not found. Continuing installation without it."
        fi
    fi
    echo "$osmesa"
elif [[ "$PKG" == "pacman" ]]; then
    # SteamOS has a read-only filesystem, this command disables that.
    if command -v steamos-readonly &> /dev/null; then
        echo "Temporarily disabling SteamOS read-only filesystem..."
        steamos-readonly disable
        trap 'if [ -f /etc/pacman.conf.bak ]; then mv /etc/pacman.conf.bak /etc/pacman.conf; fi; steamos-readonly enable' EXIT
    fi

    echo "Initializing pacman keyring and updating packages..."
    pacman-key --init
    pacman-key --populate archlinux
    
    echo "Temporarily disabling package signature checking to work around keyring issues..."
    cp /etc/pacman.conf /etc/pacman.conf.bak
    sed -i 's/^\s*SigLevel\s*=.*/#&/' /etc/pacman.conf
    sed -i '/\[options\]/a SigLevel = Never' /etc/pacman.conf

    # Upgrade and install packages
    pacman -Syu --needed --noconfirm openssh wget p7zip curl base-devel zlib python gtk3 ncurses xorg-server mesa
    
    if [ -f "/etc/pacman.conf.bak" ]; then
        echo "Restoring original pacman configuration..."
        mv /etc/pacman.conf.bak /etc/pacman.conf
    fi
else 
    # Install individual tools instead of groups to ensure compatibility with minimal UBI containers
    echo "Installing core development tools and dependencies..."
    $PKG install -y gcc gcc-c++ make binutils autoconf automake \
        wget gtk3 mesa-libGL python3 zlib-devel python3-devel \
        tar procps-ng ncurses-devel \
        --setopt=install_weak_deps=False
fi

echo "__________________________________________________________________"
echo ""
echo "Clean-up unused packages"
if [[ "$PKG" == "apt" ]]; then
    apt autoremove -y
elif [[ "$PKG" == "pacman" ]]; then
    if pacman -Qtdq > /dev/null; then
        pacman -Rns --noconfirm "$(pacman -Qtdq)"
    fi
else
    $PKG autoremove -y
fi

echo "Setting up directories for PAServer"
# Clear contents but keep the directory; mkdir -p always follows to recreate it if rm somehow removed it
rm -rf "${INSTALL_DIR:?}"/*
if ! mkdir -p "$INSTALL_DIR"; then
    echo "Failed to create installation directory. Aborting."
    exit 1
fi
echo "__________________________________________________________________"
echo ""
echo "Downloading Linux PAServer"
download_file "$PASERVER_URL" "$INSTALL_DIR/$ARCHIVE"
echo "__________________________________________________________________"
echo ""
if ! tar xvf "$INSTALL_DIR/$ARCHIVE" -C "$INSTALL_DIR" --strip-components=1; then
    echo "PAServer extraction failed. Aborting."
    exit 1
fi

# Fix the Python 3 dependency in lldb: every PAServer Linux package we've
# checked (not just 11.2) ships lldb symlinked to a Debian/Ubuntu-specific
# libpython3 path that doesn't exist on other distros or other package
# versions, silently breaking the remote debugger.
# https://blogs.embarcadero.com/setting-up-ubuntu-22-04-for-delphi-11-2-debugging/
LLDB_LIBPYTHON="$INSTALL_DIR/lldb/lib/libpython3.so"
if [[ -L "$LLDB_LIBPYTHON" && ! -e "$LLDB_LIBPYTHON" ]]; then
    echo "Fixing lldb Python dependency"
    if [[ "$PKG" == "apt" ]]; then
        ln -sf "$(find /usr/lib/x86_64-linux-gnu -maxdepth 1 -name "libpython3.*.so.1.0" | sort | tail -1)" "$LLDB_LIBPYTHON"
    elif [[ "$PKG" == "pacman" ]]; then
        ln -sf "$(find /usr/lib -maxdepth 1 -name "libpython3.*.so" | sort | tail -1)" "$LLDB_LIBPYTHON"
    else
        ln -sf "$(find /usr/lib64 -maxdepth 1 -name "libpython3*.so.1.0" | sort | tail -1)" "$LLDB_LIBPYTHON"
    fi
fi
# Ensure ownership by the invoking user
mkdir -p "$SCRATCH_DIR"
chown -R "$REAL_USER":"$REAL_USER" "$REAL_HOME/.PAServer"

# Remove archive file
rm "$INSTALL_DIR/$ARCHIVE"

# Verify the installation
if [ ! -f "$INSTALL_DIR/paserver" ]; then
    echo "PAServer installation failed. Aborting."
    exit 1
fi

cat <<EOF >"$SCRIPT_PATH"
#!/bin/bash
. /etc/os-release
echo "Detected Linux distribution: \$NAME \$VERSION_ID (\$ID)"
echo "________________________________________"
echo "" 
echo "Install dir: $INSTALL_DIR " 
echo "Script path: $SCRIPT_PATH " 
echo "Scratch dir: $SCRATCH_DIR " 
echo "Password is BLANK (none) so you might want to change that..." 
echo "________________________________________"
echo "" 
# https://docwiki.embarcadero.com/RADStudio/en/Setting_Options_for_the_Platform_Assistant
$INSTALL_DIR/paserver -scratchdir=$SCRATCH_DIR -password= -port=64211
EOF
chmod +x "$SCRIPT_PATH"

# Verify the script
if [ ! -f "$SCRIPT_PATH" ]; then
    echo "Launch script creation failed. Aborting."
    exit 1
fi 

if [[ -n "$osmesa" ]]; then
    echo "$osmesa"
fi

echo "____________________________________________"
echo ""
echo "Setup complete!"
echo ""
echo "Install dir: $INSTALL_DIR"
echo "Script path: $SCRIPT_PATH"
echo "Scratch dir: $SCRATCH_DIR"
echo "Password is BLANK (none)"
echo "Edit the script to change settings."
echo "____________________________________________"
echo ""
echo " To launch PAServer type: pa$PRODUCT.sh"
echo "____________________________________________"
