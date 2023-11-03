#!/bin/bash
set -e

OS_VERSION=$(grep "^VERSION_ID=" /etc/os-release | awk -F "=" '{ print $2 }' | sed 's/"//g' | awk -F "." '{ print $1 }')

set +e
sudo yum install -y "https://dl.fedoraproject.org/pub/epel/epel-release-latest-${OS_VERSION}.noarch.rpm"
sudo yum install -y "https://download.fedoraproject.org/pub/epel/epel-release-latest-${OS_VERSION}.noarch.rpm"
set -e

sudo yum install xdotool -y
sudo yum install xrandr -y
echo $XDG_SESSION_TYPE
if [ "$XDG_SESSION_TYPE" = "x11" ]; then
  echo 'Display type is correct.Will reset display size.'
  xrandr --output Virtual1 --mode 1440x900 --size 16:10
  sleep 2
  echo 'Good to go. Run Installer scripts'
else
  echo 'Need to update display.'
  echo '******  This will edit etc/gdm/custom.conf file & will restart system. ******'
  echo 'Press any key to continue... '
  read var
  sudo sed -i '/WaylandEnable=/s/^#//g' /etc/gdm/custom.conf
  sudo reboot
fi