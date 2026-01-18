#!/bin/bash
# 
# Single step download and execute with the following:
# curl -fsSL https://tinyurl.com/SetupLinux4Delphi | sudo bash
#  or
# wget -qO - https://tinyurl.com/SetupLinux4Delphi | sudo bash 
#
echo "_____________________________________________________________"
echo ""
echo "Setup Linux for Delphi development version 2026-01-17"
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

# Parse arguments
PARAM="37.0" # Default version
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
      echo "  13, 13.0, 37.0     = Florence 13.0 [DEFAULT]"
      echo "  12, 12.3, 23.0     = Athens 12.3"
      echo "  12.2               = Athens 12.2"
      echo "  12.1               = Athens 12.1"
      echo "  12.0               = Athens 12.0"
      echo "  11, 11.3, 22.0     = Alexandria 11.3"
      echo "  11.2               = Alexandria 11.2"
      echo "  11.1               = Alexandria 11.1"
      echo "  11.0               = Alexandria 11.0"
      echo "  10.4.1, 21.0       = Sydney 10.4.1"
      echo "  10.4.0             = Sydney 10.4.0"
      echo "  10.3, 10.3.3, 20.0 = Rio 10.3.3"
      echo "  10.3.2             = Rio 10.3.2"
      echo "  10.3.1             = Rio 10.3.1"
      echo "  10.3.0             = Rio 10.3.0"
      echo "  10.2, 10.2.3, 19.0 = Tokyo 10.2.3"
      echo "  10.2.0             = Tokyo 10.2.0"
      exit 0
      ;;
    *)
      PARAM="$key"
      shift
      ;;
  esac
done

case "$PARAM" in
    "help"|"--help"|"h"|"--h"|"-h")
        echo "Usage: sudo SetupUbuntu4Delphi.sh [version]"
        echo ""
        echo "Where [version] is one of the following:"
        echo "  37.0, 13.0         = Florence 13.0 [DEFAULT]"
        echo "  23.0, 12.3, 12     = Athens 12.3"
        echo "  12.2               = Athens 12.2"
        echo "  12.1               = Athens 12.1"
        echo "  12.0               = Athens 12.0"
        echo "  22.0, 11.3, 11     = Alexandria 11.3"
        echo "  11.2               = Alexandria 11.2"
        echo "  11.1               = Alexandria 11.1"
        echo "  11.0               = Alexandria 11.0"
        echo "  21.0, 10.4.1       = Sydney 10.4.1"
        echo "  10.4.0             = Sydney 10.4.0"
        echo "  20.0, 10.3, 10.3.3 = Rio 10.3.3"
        echo "  10.3.2             = Rio 10.3.2"
        echo "  10.3.1             = Rio 10.3.1"
        echo "  10.3.0             = Rio 10.3.0"
        echo "  19.0, 10.2, 10.2.3 = Tokyo 10.2.3"
        echo "  10.2               = Tokyo 10.2.0"
        exit 0
        ;;
    # Florence
    "37.0"|"13.0"|"florence")
        COMPILER="37.0"
        RELEASE="Florence"
        PRODUCT="13"
        PASERVER_URL="http://altd.embarcadero.com/releases/studio/37.0/130/LinuxPAServer37.0.tar.gz"
        ;;
    # Athens
    "23.0"|"12.3"|"12"|"athens")
        COMPILER="23.0"
        RELEASE="Athens"
        PRODUCT="12.3"
        PASERVER_URL="http://altd.embarcadero.com/releases/studio/23.0/123/LinuxPAServer23.0.tar.gz"
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
        PASERVER_URL="http://altd.embarcadero.com/releases/studio/23.0/120/LinuxPAServer23.0.tar.gz"
        ;;
    # Alexandria
    "22.0"|"11"|"11.3"|"alexandria")
        COMPILER="22.0"
        PRODUCT="11.3"
        RELEASE="Alexandria"
        PASERVER_URL="http://altd.embarcadero.com/releases/studio/22.0/113/LinuxPAServer22.0.tar.gz"
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
    "10.4"|"10.4.1"|"sydney"|"21.0")
        COMPILER="21.0"
        PRODUCT="10.4.1"
        RELEASE="Sydney"
        PASERVER_URL="https://altd.embarcadero.com/releases/studio/21.0/1/PAServer/LinuxPAServer21.0.tar.gz"
    ;;
    "10.4.0")
        COMPILER="21.0"
        PRODUCT="10.4.0"
        RELEASE="Sydney"
        PASERVER_URL="http://altd.embarcadero.com/releases/studio/21.0/PAServer/LinuxPAServer21.0.tar.gz"
    ;;
    # Rio
    "10.3"|"rio"|"10.3.3")
        COMPILER="20.0"
        PRODUCT="10.3.3"
        RELEASE="Rio"
        PASERVER_URL="http://altd.embarcadero.com/releases/studio/20.0/PAServer/Release3/LinuxPAServer20.0.tar.gz"
    ;;
    "10.3.2")
        COMPILER="20.0"
        PRODUCT="10.3.2"
        RELEASE="Rio"
        PASERVER_URL="http://altd.embarcadero.com/releases/studio/20.0/PAServer/Release2/LinuxPAServer20.0.tar.gz"
    ;;
    "10.3.1")
        COMPILER="20.0"
        PRODUCT="10.3.1"
        RELEASE="Rio"
        PASERVER_URL="http://altd.embarcadero.com/releases/studio/20.0/PAServer/Release1/LinuxPAServer20.0.tar.gz"
    ;;
    "10.3.0")
        COMPILER="20.0"
        PRODUCT="10.3.0"
        RELEASE="Rio"
        PASERVER_URL="http://altd.embarcadero.com/releases/studio/20.0/PAServer/LinuxPAServer20.0.tar.gz"
    ;;
    # Tokyo
    "10.2")
        COMPILER="19.0"
        PRODUCT="10.2.0"
        RELEASE="Tokyo"
        PASERVER_URL="http://altd.embarcadero.com/releases/studio/19.0/PAServer/LinuxPAServer19.0.tar.gz"
    ;;
    "tokyo"|"10.2.3")
        COMPILER="19.0"
        PRODUCT="10.2.3"
        RELEASE="Tokyo"
        PASERVER_URL="http://altd.embarcadero.com/releases/studio/19.0/PAServer/Release3/LinuxPAServer19.0.tar.gz"
    ;;
esac

if [ -z "$PASERVER_URL" ]; then
    echo "Unknown version: $PARAM"
    exit 1
fi

ARCHIVE="${PASERVER_URL##*/}"

echo "Setting up for Delphi $PRODUCT $RELEASE ($COMPILER)"
echo "Using PAServer URL: $PASERVER_URL"
echo ""
# Set defaults
INSTALL_DIR="/opt/PAServer/$PRODUCT"
SCRIPT_PATH="/usr/local/bin/"
SCRIPT_FILE="$SCRIPT_PATH/pa$PRODUCT.sh"
# Get the actual user who invoked sudo
REAL_USER=${SUDO_USER:-$USER}
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
SCRATCH_DIR="$REAL_HOME/.PAServer/$PRODUCT-scratch"
echo "Installation directory: $INSTALL_DIR"
echo "Launch script file: $SCRIPT_FILE"
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
    # Removed joe, it is a text editor and I doubt it is required.... Need more testing.
    apt install wget p7zip-full curl build-essential zlib1g-dev libcurl4-gnutls-dev python3 libpython3-dev libgtk-3-dev $NCURSES_PKG xorg libgl1-mesa-dev libgtk-3-bin libc6-dev -y --no-install-recommends
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

# Fix the Python 3.6 dependency in lldb for Delphi 11.2
# https://blogs.embarcadero.com/setting-up-ubuntu-22-04-for-delphi-11-2-debugging/
if [[ "$PRODUCT" == "11.2" ]]; then
    echo "Fixing lldb Python dependency"
    if [[ "$PKG" == "apt" ]]; then
        ln -sf "$(find /usr/lib/x86_64-linux-gnu -maxdepth 1 -name "libpython3.*.so.1.0" | sort | tail -1)" "$INSTALL_DIR"/lldb/lib/libpython3.so
    elif [[ "$PKG" == "pacman" ]]; then
        ln -sf "$(find /usr/lib -maxdepth 1 -name "libpython3.*.so" | sort | tail -1)" "$INSTALL_DIR"/lldb/lib/libpython3.so
    else
        ln -sf "$(find /usr/lib64 -maxdepth 1 -name "libpython3*.so.1.0" | sort | tail -1)" "$INSTALL_DIR"/lldb/lib/libpython3.so
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

cat <<EOF >"$SCRIPT_FILE"
#!/bin/bash
. /etc/os-release
echo "Detected Linux distribution: \$NAME \$VERSION_ID (\$ID)"
echo "________________________________________"
echo "" 
echo "Install dir: $INSTALL_DIR " 
echo "Script path: $SCRIPT_FILE " 
echo "Scratch dir: $SCRATCH_DIR " 
echo "Password is BLANK (none) so you might want to change that..." 
echo "________________________________________"
echo "" 
# https://docwiki.embarcadero.com/RADStudio/en/Setting_Options_for_the_Platform_Assistant
$INSTALL_DIR/paserver -scratchdir=$SCRATCH_DIR -password= -port=64211
EOF
chmod +x "$SCRIPT_FILE"

# Verify the script
if [ ! -f "$SCRIPT_FILE" ]; then
    echo "Launch script creation failed. Aborting."
    exit 1
fi 

if [[ "$ID" == "steamos" ]]; then
    # Re-enable SteamOS read-only filesystem
    if command -v steamos-readonly &> /dev/null; then
        echo "Re-enabling SteamOS read-only filesystem..."
        steamos-readonly enable
    fi
fi

if [[ -n "$osmesa" ]]; then
    echo "$osmesa"
fi

echo "____________________________________________"
echo ""
echo "Setup complete!"
echo ""
echo "Install dir: $INSTALL_DIR"
echo "Script path: $SCRIPT_FILE"
echo "Scratch dir: $SCRATCH_DIR"
echo "Password is BLANK (none)"
echo "Edit the script to change settings."
echo "____________________________________________"
echo ""
echo " To launch PAServer type: pa$PRODUCT.sh"
if [[ $PRODUCT -eq $LATEST ]]; then
    ln "$SCRIPT_FILE" "$SCRIPT_PATH/pa.sh"
    echo "   Since $PRODUCT is the latest, you can also use pa.sh"
fi
echo "____________________________________________"
