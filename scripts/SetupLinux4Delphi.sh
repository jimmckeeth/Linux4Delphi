#!/bin/bash
# 
# Download and execute with the following:
# curl -L https://tinyurl.com/SetupLinux4Delphi | sudo bash
#
echo "Setup Linux for Delphi development version 2024-06-10"
echo "_____________________________________________________________"
echo ""
echo "This script requires sudo, su, or root privileges."
echo "More info: https://github.com/jimmckeeth/Delphi-on-Linux-Setup"
echo ""
# Stop on all errors
set -e

if [[ $EUID -ne 0 ]]; then
  echo "Please run this script with sudo or as root."
  exit 1
fi

PARAM="$(echo "${1:-37.0}" | tr '[:upper:]' '[:lower:]')"
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
        echo "  21.0, 10.4, 10.4.2 = Sydney 10.4.2"
        echo "  10.4.1             = Sydney 10.4.1"
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
        PRODUCT="13.0"
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
    "10.2"|"tokyo"|"10.2.3")
        COMPILER="19.0"
        PRODUCT="10.2.3"
        RELEASE="Tokyo"
        PASERVER_URL="http://altd.embarcadero.com/releases/studio/19.0/PAServer/Release3/LinuxPAServer19.0.tar.gz"
    ;;
    "10.2")
        COMPILER="19.0"
        PRODUCT="10.2.0"
        RELEASE="Tokyo"
        PASERVER_URL="http://altd.embarcadero.com/releases/studio/19.0/PAServer/LinuxPAServer19.0.tar.gz"
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
SCRIPT_PATH="/usr/local/bin/pa$PRODUCT.sh"
SCRATCH_DIR="/var/tmp/paserver-$PRODUCT"
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
if [[ "$ID" == "ubuntu" || "$ID" == "debian" || "$ID_LIKE" == *"debian"* || "$ID_LIKE" == *"ubuntu"* ]]; then
    # Ubuntu/Debian logic
    PKG="apt"
    if [[ ("$ID" == "ubuntu" && "$(echo "$VERSION_ID < 16.04" | bc)" -eq 1) || ("$ID" == "debian" && "$(echo "$VERSION_ID < 10" | bc)" -eq 1) ]]; then
        echo "This script requires at least Ubuntu 16.04 or Debian 10."
        exit 1
    fi
    if [ "$(uname -m)" != "x86_64" ]; then
        echo "This script requires a x86_64-bit operating system."
        exit 1
    fi  
elif [[ "$ID" == "rhel" || "$ID" == "centos" || "$ID" == "fedora" || "$ID_LIKE" == *"rhel"* || "$ID_LIKE" == *"fedora"* ]]; then
    # RedHat/Fedora/CentOS logic
    if [ "$(uname -m)" != "x86_64" ]; then
        echo "This script requires a x86_64-bit operating system."
        exit 1
    fi
    if command -v dnf >/dev/null 2>&1; then
      PKG="dnf"
    else
      PKG="yum"
    fi
else
    echo "Unsupported Linux distribution. Aborting."
    exit 1
fi

echo "Detected Linux distribution: $NAME $VERSION_ID ($ID)"
echo "Using package manager: $PKG"
echo ""

if [[ "$PKG" == "apt" ]]; then
    echo "__________________________________________________________________"
    echo ""
    echo "Updating the local package directory"
    apt update -y
fi
if [ $? -ne 0 ]; then
    echo "Update failed. Aborting."
    exit 1
fi

echo "__________________________________________________________________"
echo ""
echo "Upgrading any outdated packages"
if [[ "$PKG" == "apt" ]]; then
    apt dist-upgrade -y
else
    $PKG upgrade -y
fi
if [ $? -ne 0 ]; then
    echo "Upgrade failed. Aborting."
    exit 1
fi

echo "__________________________________________________________________"
echo ""
echo "Install new packages required for Delphi & FMXLinux"
echo "https://docwiki.embarcadero.com/RADStudio/en/Linux_Application_Development"
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
    set +e
    apt install openssh-server -y
    if [ $? -ne 0 ]; then
      echo "Warning: openssh-server installation failed, removing..."
      apt purge openssh-server -y
    fi
    set -e
    apt install joe wget p7zip-full curl build-essential zlib1g-dev libcurl4-gnutls-dev python3 libpython3-dev libgtk-3-dev $NCURSES_PKG xorg libgl1-mesa-dev libosmesa-dev libgtk-3-bin libc6-dev -y
else
    if [[ "$PKG" == "dnf" ]]; then
      if [[ ("$ID_LIKE" == *"fedora"* || "$ID" == "fedora") && "${VERSION_ID}" -ge 40 ]]; then
        dnf group install c-development development-tools -y
      else
        dnf groupinstall 'Development Tools' -y
      fi
    else
      yum groupinstall 'Development Tools' -y
    fi
    $PKG install wget gtk3 mesa-libGL gtk3-devel python3 zlib-devel python3-devel -y
fi
if [ $? -ne 0 ]; then
    echo "Package installation failed. Aborting."
    exit 1
fi

echo "__________________________________________________________________"
echo ""
echo "Clean-up unused packages"
if [[ "$PKG" == "apt" ]]; then
    apt autoremove -y
else
    $PKG autoremove -y
fi

echo "Setting up directories for PAServer"
rm -rf "$INSTALL_DIR"/*
mkdir -p "$INSTALL_DIR"
if [ $? -ne 0 ]; then
    echo "Failed to create installation directory. Aborting."
    exit 1
fi
echo "__________________________________________________________________"
echo ""
echo "Downloading Linux PAServer "
wget -O "$INSTALL_DIR/$ARCHIVE" "$PASERVER_URL"
echo "__________________________________________________________________"
echo ""
tar xvf "$INSTALL_DIR/$ARCHIVE" -C "$INSTALL_DIR" --strip-components=1
if [ $? -ne 0 ]; then
    echo "PAServer extraction failed. Aborting."
    exit 1
fi

# Fix the Python 3.6 dependency in lldb for Delphi 11.2
# https://blogs.embarcadero.com/setting-up-ubuntu-22-04-for-delphi-11-2-debugging/
if [[ "$PRODUCT" == "11.2" ]]; then
    echo "Fixing lldb Python dependency"
    if [[ "$PKG" == "apt" ]]; then
        ln -sf $(ls -1 /usr/lib/x86_64-linux-gnu/libpython3.*.so.1.0 | tail -1) "$INSTALL_DIR"/lldb/lib/libpython3.so
    else
        ln -sf $(ls -1 /usr/lib64/libpython3*.so.1.0 | tail -1) "$INSTALL_DIR"/lldb/lib/libpython3.so
    fi
fi
# Ensure ownership by the invoking user
mkdir -p "$SCRATCH_DIR"
# Give all users write access to the scratch directory
chown "$SUDO_USER":"$SUDO_USER" "$SCRATCH_DIR"
chmod a+rw "$SCRATCH_DIR"
# Remove archive file
rm "$INSTALL_DIR/$ARCHIVE"

# Verify the installation
if [ ! -f "$INSTALL_DIR/paserver" ]; then
    echo "PAServer installation failed. Aborting."
    exit 1
fi


echo "#!/bin/bash" >"$SCRIPT_PATH"
echo ". /etc/os-release" >>"$SCRIPT_PATH"
echo "echo \"Detected Linux distribution: \$NAME \$VERSION_ID (\$ID)\"" >>"$SCRIPT_PATH"
echo "echo \"________________________________________\"" >>"$SCRIPT_PATH"
echo "echo \"\" " >>"$SCRIPT_PATH"
echo "echo \"Install dir: $INSTALL_DIR  \" " >>"$SCRIPT_PATH"
echo "echo \"Script path: $SCRIPT_PATH  \" " >>"$SCRIPT_PATH"
echo "echo \"Scratch dir: $SCRATCH_DIR \" " >>"$SCRIPT_PATH"
echo "echo \"Password is BLANK (none)  \" " >>"$SCRIPT_PATH"
echo "echo \"________________________________________\"" >>"$SCRIPT_PATH"
echo "echo \"\" " >>"$SCRIPT_PATH"
echo "# https://docwiki.embarcadero.com/RADStudio/en/Setting_Options_for_the_Platform_Assistant" >>"$SCRIPT_PATH"
echo "$INSTALL_DIR/paserver -scratchdir=$SCRATCH_DIR -password= -port=64211" >>"$SCRIPT_PATH"
chmod +x "$SCRIPT_PATH"

# Verify the script
if [ ! -f "$SCRIPT_PATH" ]; then
    echo "Launch script creation failed. Aborting."
    exit 1
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
