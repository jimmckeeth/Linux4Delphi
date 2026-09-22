#!/bin/bash
# 
# Download and execute with the following:
# curl -L https://embt.co/SetupRedHat4Delphi22sh | bash
#
echo "updating installed package"
sudo yum upgrade -y
echo "installing development tools"
sudo yum groupinstall 'Development Tools' -y
sudo yum install wget gtk3 mesa-libGL gtk3-devel -y
cd ~
echo "Downloading Linux PAServer for Alexandria 12.3 (23.0)"
# wget https://altd.embarcadero.com/releases/studio/22.0/113/LinuxPAServer22.0.tar.gz # 11.3
# wget https://altd.embarcadero.com/releases/studio/23.0/120/LinuxPAServer23.0.tar.gz # 12.0
# wget https://altd.embarcadero.com/releases/studio/23.0/121/LinuxPAServer23.0.tar.gz # 12.1
# wget https://altd.embarcadero.com/releases/studio/23.0/122/LinuxPAServer23.0.tar.gz # 12.2
wget https://altd.embarcadero.com/releases/studio/23.0/123/LinuxPAServer23.0.tar.gz # 12.3
echo "Setting up directories to extract PA Server into"
mkdir PAServer
mkdir PAServer/22.0
rm PAServer/22.0/*
tar xvf LinuxPAServer22.0.tar.gz -C PAServer/22.0 --strip-components=1
rm LinuxPAServer22.0.tar.gz
echo \#\!\/bin\/bash >pa22.sh
echo ~/PAServer/22.0/paserver >>pa22.sh
chmod +x pa22.sh
echo "-----------------------------------"
echo " To launch PAServer type ~/pa22.sh"
echo "-----------------------------------"
