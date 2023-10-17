#!/bin/bash
set -e
# Get platform
UNAME=$(uname -a)
sudo apt-get install curl -y
sudo apt-get install xdotool -y
sudo sudo apt install apt-show-versions -y
echo $XDG_SESSION_TYPE
if [ "$XDG_SESSION_TYPE" = "x11" ]; then
  echo 'Display type is correct.Will reset display size.'
  xrandr --output Virtual1 --mode 1440x900 --size 16:10
  sleep 3
  echo 'Good to go. Run Installer scripts'
else
  echo 'Need to update display.'
  if [[ "$UNAME" =~ "Debian" ]]; then
    echo '******  This will edit etc/gdm3/daemon.conf file & will restart display. ******'
    echo 'Press any key to continue... '
    read var
    sudo sed -i '/WaylandEnable=/s/^#//g' /etc/gdm3/daemon.conf
    sudo systemctl restart gdm3
  elif [[ "$UNAME" =~ "Ubuntu" ]]; then
    echo '****** This will edit etc/gdm3/custom.conf file & will restart display. ******'
    echo 'Press any key to continue... '
    read var
    sudo sed -i '/WaylandEnable=/s/^#//g' /etc/gdm3/custom.conf
    sudo systemctl restart gdm3
  fi
fi