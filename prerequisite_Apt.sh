#!/bin/bash
set -e
# Get platform
UNAME=$(uname -a)
sudo apt-get install curl -y
sudo apt-get install xdotool -y
sudo apt install apt-show-versions -y
#xhost +
echo $XDG_SESSION_TYPE
if [ "$XDG_SESSION_TYPE" = "x11" ]; then
  echo 'Display type is correct.Will reset display size.'
  CURRENT_DISPLAY=`xrandr | awk '/ connected/ && /[[:digit:]]x[[:digit:]].*+/{print $1}'`
  xrandr --output $CURRENT_DISPLAY --mode 1440x900 --size 16:10
  sleep 2
  echo 'Good to go. Run Installer scripts'
else
  echo 'Need to update display.'
  if [[ "$UNAME" =~ "Debian" ]]; then
    echo '******  This will edit etc/gdm3/daemon.conf file & will restart system. ******'
    echo 'Press any key to continue... '
    read var
    sudo sed -i '/WaylandEnable=/s/^#//g' /etc/gdm3/daemon.conf
    sudo reboot
    #sudo systemctl restart gdm3
  elif [[ "$UNAME" =~ "Ubuntu" ]]; then
    echo '****** This will edit etc/gdm3/custom.conf file & will restart system. ******'
    echo 'Press any key to continue... '
    read var
    sudo sed -i '/WaylandEnable=/s/^#//g' /etc/gdm3/custom.conf
    sudo reboot
  fi
fi