#!/bin/bash
# 
# Download and execute with the following:
# curl -L https://tinyurl.com/SetupUbuntu4Delphi23 | bash
#
# Updated for 12.2
#
echo "Updating the local package directory"
sudo apt update 
echo "Upgrading any outdated packages"
sudo apt full-upgrade -y
echo "Install new packages necessary for Delphi & FMXLinux"
sudo apt install joe python3 libpython3-dev wget p7zip-full curl libgtk-3-dev openssh-server build-essential zlib1g-dev libcurl4-gnutls-dev libncurses5 xorg libgl1-mesa-dev libosmesa-dev libgtk-3-bin -y
echo "Clean-up unused packages"
sudo apt autoremove -y
cd ~
echo "Downloading Linux PAServer for Athens 12.3 (23.0)"
# You can find the latest version here:
#   https://docwiki.embarcadero.com/RADStudio/en/Installing_the_Platform_Assistant_on_Linux
# wget https://altd.embarcadero.com/releases/studio/22.0/113/LinuxPAServer22.0.tar.gz # 11.3
# wget https://altd.embarcadero.com/releases/studio/23.0/120/LinuxPAServer23.0.tar.gz # 12.0
# wget https://altd.embarcadero.com/releases/studio/23.0/121/LinuxPAServer23.0.tar.gz # 12.1
# wget https://altd.embarcadero.com/releases/studio/23.0/122/LinuxPAServer23.0.tar.gz # 12.2
wget https://altd.embarcadero.com/releases/studio/23.0/123/LinuxPAServer23.0.tar.gz # 12.3

echo "Setting up directories to extract PA Server into"
mkdir PAServer
mkdir PAServer/23.0
rm PAServer/23.0/*
tar xvf LinuxPAServer23.0.tar.gz -C PAServer/23.0 --strip-components=1
# This fixes the Python 3.6 dependency
ln -sf `ls -1 /usr/lib/x86_64-linux-gnu/libpython3.*.so.1.0 | tail -1` ~/PAServer/23.0/lldb/lib/libpython3.so
rm LinuxPAServer23.0.tar.gz
echo \#\!\/bin\/bash >pa23.sh
echo \# https://docwiki.embarcadero.com/RADStudio/en/Setting_Options_for_the_Platform_Assistant >>pa23.sh
echo ~/PAServer/23.0/paserver >>pa23.sh
chmod +x pa23.sh
echo "-----------------------------------"
echo " To launch PAServer type ~/pa23.sh"
echo "-----------------------------------"
# ~/pa23.sh


exit
