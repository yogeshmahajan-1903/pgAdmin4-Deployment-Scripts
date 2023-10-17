#! /bin/bash
# Wait times
WAIT_TO_LAUNCH_APP=15
WAIT_TO_LAUNCH_FF=15
WAIT_TO_LAUNCH_PGAMIN_IN_NWJS=15
WAIT_TO_LAUNCH_PGAMIN_IN_FF=8
ABOUT_BOX_SHOW_TIME=3

# Exit on error
set -e

# Set up parser
help()
{
    echo "Usage: bash pgAdmin_installer_automation_Apt_v1.sh 
                  [ -o | --operation ]
                      (required)[ install, install_snapshot, install_cb,
                                  verify, 
                                  upgrade_cb, upgrade_test, fresh_test], 
                  [ -m | --mode ]
                      (optional):[desktop or server]
                  [ -h | --help  ]"
    exit 2
}
SHORT=o:,m:,h
LONG=operation:,mode:,help
OPTS=$(getopt -a -n pgAdmin_installer_automation_Apt_v1.sh --options $SHORT --longoptions $LONG -- "$@")

VALID_ARGUMENTS=$# # Returns the count of arguments that are in short or long options

if [ "$VALID_ARGUMENTS" -eq 0 ]; then
  help
fi

# Check args
eval set -- "$OPTS"
while :
do
  case "$1" in
    -o | --operation )
      operation="$2"
      shift 2
      ;;
    -m | --mode )
      mode="$2"
      shift 2
      ;;
    -h | --help)
      help
      ;;
    --)
      shift;
      break
      ;;
    *)
      echo "Unexpected option: $1"
      help
      ;;
  esac
done


operations=("install" "install_cb" "install_snapshot" "verify" "upgrade_cb" "upgrade_test" "fresh_test")
modes=("desktop" "server" "")
if ! [[ " ${operations[@]} " =~ " ${operation} "  ]]; then
  echo 'Invalid operation'
  exit 1
fi

if [[ ! -z " ${mode} " ]] && ! [[ " ${modes[@]} " =~ " ${mode} "  ]]; then
  echo 'Invalid mode'
  exit 1
fi


# Setup display
echo '******Setting up display.********'
xrandr --output Virtual1 --mode 1440x900 --size 16:10
sleep 2

# Move Terminal Window to bottom
wid=`xdotool getactivewindow`
xdotool windowsize $wid 1300 500
sleep 1
xdotool windowmove $wid 60 700

_install_released_pgadmin(){
  # Take pgAdmin mode as argument
  mode=$1
  mode=$([ "$mode" == "" ] && echo "Server & Desktop" || echo "$mode")
  
  # Info
  echo '\n'
  echo '***********************************************************'
  echo 'Installing released pgAdmin version mode: - '$mode
  echo '***********************************************************'
  echo '\n'

  # Download
  echo '******Downloading existing pgAdmin.*******'
  KEY=/usr/share/keyrings/packages-pgadmin-org.gpg
  if [[ -f "$KEY" ]]; then
    echo "----Key exists. Removing key"
    rm -f /usr/share/keyrings/packages-pgadmin-org.gpg
  fi
  echo '----Adding key'
  curl -fsS https://www.pgadmin.org/static/packages_pgadmin_org.pub | sudo gpg  --dearmor -o /usr/share/keyrings/packages-pgadmin-org.gpg

  echo '----Adding repo config file'
  sudo sh -c 'echo "deb [signed-by=/usr/share/keyrings/packages-pgadmin-org.gpg] https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$(lsb_release -cs) pgadmin4 main" > /etc/apt/sources.list.d/pgadmin4.list && apt update'
  
  # Check mode
  suffix=""
  if [ "$mode" = "desktop" ]; then
    echo '----Installing pgAdmin4-desktop'
    sudo apt install pgadmin4-desktop -y
    suffix="-desktop"
  elif [ "$mode" = "server" ]; then
    echo '----Installing pgAdmin4-web'
    sudo apt install pgadmin4-web -y
    suffix="-web"
    # Configure the webserver, if you installed pgadmin4-web:
    sudo /usr/pgadmin4/bin/setup-web.sh --yes
  else
    echo '----Installing pgAdmin4 in both modes'
    sudo apt install pgadmin4 -y
    # Configure the webserver, if you installed pgadmin4-web:
    sudo /usr/pgadmin4/bin/setup-web.sh --yes
  fi
  echo '\n'
  echo '***********************************************************'
  echo 'pgAdmin installed successfully - '$(apt-show-versions pgadmin4"$suffix")
  echo '***********************************************************'
  echo '\n'
}

_wait_for_window(){
  set +e
  win_name=$1
  wait_time=$2
  counter=$wait_time
  while [[ $counter -gt 0 ]]
  do
    wid=`xdotool search --onlyvisible --desktop --name "${win_name}"`
    if [[ -z "$wid" ]]; then
      sleep 2
      counter=$(( counter - 1 ))
      if  [[ "$counter" -eq 0 ]]; then
        echo '---- '$win_name' not found after '$wait_time
        exit 1
      fi
    else
      echo '--- '$win_name' found.'
      counter=0
      sleep 2
    fi
  done

}

_verify_installed_pgadmin_server_mode(){
  # platform name
  UNAME=$(uname -a)

  # Take pgAdmin mode as argument
  mode=$1

  # Info
  echo '\n'
  echo '***********************************************************'
  echo 'Verifying pgAdmin Launch in Server mode.'
  echo '***********************************************************'
  echo '\n'

  # App launch - Move to applications option an click
  xdotool mousemove --sync --screen 0 45 12
  sleep 0.5
  xdotool mousemove_relative 1 1
  sleep 0.5
  xdotool click 1
  sleep 1

  # Type in search box and heat enter
  xdotool type "firefox"
  sleep 0.5
  xdotool key Return

  # Wait for ff to open
  echo '----Waiting to open firefox.'
  app_name="Mozilla Firefox"
  time=$WAIT_TO_LAUNCH_APP
  _wait_for_window "$app_name" "$time"
  set -e

  # Search to ff window
  wid=`xdotool search --sync --onlyvisible --desktop --name "${app_name}"`
  xdotool windowactivate $wid key --delay 250 ctrl+t

  # Check if window is maximized
  # Try to unmaximize
  eval $(xdotool getwindowgeometry --shell ${wid})
  sum=`expr $X + $WIDTH`
  if [[ "$sum" == 1440 ||  "$sum" == 1441 ]];then
    echo '----Need to reduce size as launched in full screen.'
    xdotool mousemove --sync 875 45 click --repeat 2 1
    echo '----Unmaximized.'
  fi

  # Move window to Left top
  if [[ "$UNAME" =~ "Debian" ]]; then
    xdotool windowsize --sync $wid 1385 700
    sleep 0.5
    xdotool windowmove $wid 60 0
  elif [[ "$UNAME" =~ "Ubuntu" ]]; then
    xdotool windowsize --sync $wid 1400 700
    sleep 0.5
    xdotool windowmove $wid 0 0
  fi
  sleep 2
  echo '----Mozilla Firefox window in correct position.'

  # Launch pgAdmin
  echo '----Opening pgAdmin in FF'
  xdotool type "http://127.0.0.1/pgadmin4"
  xdotool key Return
  sleep $WAIT_TO_LAUNCH_PGAMIN_IN_FF

  #Move to login email and password &  Enter email
  echo '----Entering login details'
  xdotool type "edb@edb.com"
  xdotool key "Tab"
  xdotool type "adminedb"
  xdotool key "Return"
  sleep 5

  # Handle password save
  xdotool mousemove 240 530 click 1
  sleep 0.5
  # Verify version
  echo '----Verifying version from About'
  # Open Help
  xdotool mousemove 450 130 click 1
  sleep 0.5
  # About option
  xdotool mousemove 485 270 click 1
  sleep 3
  # Close About box
  xdotool mousemove 1095 215 click 1
  sleep 0.5
  echo '----Closed About box'
  #Move to logout
  xdotool mousemove 1350 125 click 1
  sleep 0.5
  xdotool mousemove 1260 250 click 1
  sleep 0.5
  xdotool key "Return"
  sleep $ABOUT_BOX_SHOW_TIME
  echo '----Logged out'
  # Move to close ff at top and click
  xdotool mousemove 1410 45 click 1
  sleep 0.5
  xdotool key "Return"
  echo '----FF is closed.'
  # Final Msg
  echo '\n'
  echo '***********************************************************'
  echo 'pgAdmin sever version verified successfully.'
  echo '***********************************************************'
  echo '\n'

}

_verify_installed_pgadmin_dektop_mode(){

  # Get platform name
  UNAME=$(uname -a)
  
  # Info
  echo '\n'
  echo '***********************************************************'
  echo 'Verifying pgAdmin launch in Desktop mode'
  echo '***********************************************************'
  echo '\n'

  # App launch - Move to applications option an click
  xdotool mousemove --sync --screen 0 45 12
  sleep 0.5
  xdotool mousemove_relative 1 1
  sleep 0.5
  xdotool click 1
  sleep 1

  # Type in search box and heat enter
  xdotool type "pgAdmin 4"
  sleep 0.5
  xdotool key Return

  # Wait for pgAdmin to open
  echo '----Waiting to open pgAdmin.'
  app_name="pgAdmin 4"
  time=$WAIT_TO_LAUNCH_APP
  _wait_for_window "$app_name" "$time"
  sleep $WAIT_TO_LAUNCH_PGAMIN_IN_NWJS
  set -e

  # Search to pgAdmin window
  wid=`xdotool search --onlyvisible --desktop --name "pgAdmin 4"`

  # Check if window is maximized
  # Try to unmaximize
  eval $(xdotool getwindowgeometry --shell ${wid})
  sum=`expr $X + $WIDTH`
  if [[ "$sum" == 1440 ||  "$sum" == 1441 ]];then
    echo "----Need to reduce size as launched in full screen."
    xdotool mousemove --sync 375 45 click --repeat 2 1
    echo "----Unmaximized."
  fi

  # Move window to Left top
  if [[ "$UNAME" =~ "Debian" ]]; then
    xdotool windowsize --sync $wid 1375 700
    sleep 0.5
    xdotool windowmove $wid 60 0
    sleep 0.5
  elif [[ "$UNAME" =~ "Ubuntu" ]]; then
    xdotool windowsize --sync $wid 1400 700
    sleep 0.5
    xdotool windowmove $wid 0 0
    sleep 0.5
  fi
  echo '----pgAdmin window in correct position.'

  echo '----Wait till I show About box to check version.'
  # Move to Help Menu and click
  xdotool mousemove 240 75 click 1
  sleep 0.5
  # Move to About menu
  xdotool mousemove 285 205 click 1
  sleep $ABOUT_BOX_SHOW_TIME
  echo '----About menu shown. Now will quit pgAdmin.'

  # Move to pgAdmin4 close at top and click
  xdotool mousemove 1415 45 click 1
  sleep 1
  xdotool key "Return"
  echo '----pgAdmin is closed.'

  # Final Msg
  echo '\n'
  echo '***********************************************************'
  echo 'pgAdmin desktop version verified successfully.'
  echo '***********************************************************'
  echo '\n'
}

_verify_installed_pgadmin(){
  # Take pgAdmin mode as argument
  mode=$1
  if [ "$mode" = "desktop" ]; then
    _verify_installed_pgadmin_dektop_mode
  elif [ "$mode" = "server" ]; then
    _verify_installed_pgadmin_server_mode
  else
    echo '*********Verifying both modes*********'
    _verify_installed_pgadmin_dektop_mode
    _verify_installed_pgadmin_server_mode
  fi
}

_upgrade_pgadmin_to_candidate_build(){
  mode=$1
  mode=$([ "$mode" == "" ] && echo "Server & Desktop" || echo "$mode")
  echo '\n'
  echo '***********************************************************'
  echo 'Upgrading pgAdmin to candidate build : - '$mode
  echo '***********************************************************'
  echo '\n'
  # Constants
  platform='apt'

  
  # Take candidate build date
  set +e
  default_date=$(date +'%Y-%m-%d')-1
  echo '----Enter the caididate build date [default:'  $default_date ']'
    read -r -p "----Will wait 10 seconds or press any key to continue immediately" -t 1- date
  date="${date:=$default_date}"'/'
  echo '----Select release date is - '$date
  set -e

  # From url
  url='https://developer.pgadmin.org/builds/'$date'/apt/$(lsb_release -cs)'
  url="deb [signed-by=/usr/share/keyrings/packages-pgadmin-org.gpg] $url pgadmin4 main"
  echo '----Using url - '$url

  # Add/Update repo config
  echo '----Creating repo config'
  sudo sh -c "echo $url > /etc/apt/sources.list.d/pgadmin4.list && apt update"

  # Check mode
  suffix=""
  if [ "$mode" = "desktop" ]; then
    echo '----Will start upgrading pgadmin desktop'
    sudo apt upgrade pgadmin4-desktop -y
    suffix="desktop"
  elif [ "$mode" = "server" ]; then
    echo '----Upgrading pgAdmin4-web'
    sudo apt upgrade pgadmin4-web -y
    suffix="web"
  else
    echo '----Upgrading pgAdmin4 both modes'
    sudo apt upgrade pgadmin4 -y
    sudo /usr/pgadmin4/bin/setup-web.sh --yes
  fi
  
  # Final msg
  echo '\n'
  echo '***********************************************************'
  echo 'pgAdmin upgraded to candidate build successfully - '$(apt-show-versions pgadmin4-"$suffix")
  echo '***********************************************************'
  echo '\n'
}

_install_candidate_build_pgadmin(){
  # Take pgAdmin mode as argument
  mode=$1
  mode=$([ "$mode" == "" ] && echo "Server & Desktop" || echo "$mode")

  # Info
  echo '\n'
  echo '***********************************************************'
  echo 'Installing Candidate build pgAdmin mode: - '$mode
  echo '***********************************************************'
  echo '\n'
  echo '******Downloading candidate build pgAdmin.*******'
  KEY=/usr/share/keyrings/packages-pgadmin-org.gpg
  if [[ -f "$KEY" ]]; then
    echo "----Key exists. Removing key"
    rm -f /usr/share/keyrings/packages-pgadmin-org.gpg
  fi
  echo '----Adding key'
  curl -fsS https://www.pgadmin.org/static/packages_pgadmin_org.pub | sudo gpg  --dearmor -o /usr/share/keyrings/packages-pgadmin-org.gpg

  echo '----Adding repo config file'
  # Take candidate build date
  set +e
  default_date=$(date +'%Y-%m-%d')-1
  echo '----Enter the caididate build date [default:'  $default_date '].'
  read -r -p "----Will wait 10 seconds or press any key to continue immediately" -t 5 date
  date="${date:=$default_date}"'/'
  echo '----Selected release date is - '$date
  set -e

  # From url
  url='https://developer.pgadmin.org/builds/'$date'/apt/$(lsb_release -cs)'
  url="deb [signed-by=/usr/share/keyrings/packages-pgadmin-org.gpg] $url pgadmin4 main"
  echo '----Using url - '$url

  # Add/Update  repo config
  echo '----Creating repo config'
  sudo sh -c "echo $url > /etc/apt/sources.list.d/pgadmin4.list && apt update"

  # Check mode
  suffix=""
  if [ "$mode" = "desktop" ]; then
    echo '----Installing pgAdmin4-desktop'
    sudo apt install pgadmin4-desktop -y
    suffix="-desktop"
  elif [ "$mode" = "server" ]; then
    echo '----Installing pgAdmin4-web'
    sudo apt install pgadmin4-web -y
    suffix="-web"
    # Configure the webserver, if you installed pgadmin4-web:
    sudo /usr/pgadmin4/bin/setup-web.sh --yes
  else
    echo '----Installing pgAdmin4 both modes'
    sudo apt install pgadmin4 -y
    sudo /usr/pgadmin4/bin/setup-web.sh --yes
  fi
  echo '\n'
  echo '***********************************************************'
  echo 'pgAdmin Candidate Build installed successfully - '$(apt-show-versions pgadmin4"$suffix")
  echo '***********************************************************'
  echo '\n'
}

_install_snapshot_build_pgadmin(){
  # Take pgAdmin mode as argument
  mode=$1
  mode=$([ "$mode" == "" ] && echo "Server & Desktop" || echo "$mode")

  # Info
  echo '\n'
  echo '***********************************************************'
  echo 'Installing Snapshot build pgAdmin mode: - '$mode
  echo '***********************************************************'
  echo '\n'
  echo '******Downloading snapshot build pgAdmin.*******'
  KEY=/usr/share/keyrings/packages-pgadmin-org.gpg
  if [[ -f "$KEY" ]]; then
    echo "----Key exists. Removing key"
    rm -f /usr/share/keyrings/packages-pgadmin-org.gpg
  fi
  echo '----Adding key'
  curl -fsS https://www.pgadmin.org/static/packages_pgadmin_org.pub | sudo gpg  --dearmor -o /usr/share/keyrings/packages-pgadmin-org.gpg

  echo '----Adding repo config file'
  # Take snapshot build date
  set +e
  default_date=$(date +'%Y-%m-%d')
  echo '----Enter the snapshot build date [default:'  $default_date '].'
  read -r -p "----Will wait for 10 seconds or press any key to continue immediately" -t 10 date
  date="${date:=$default_date}"'/'
  echo '----Selected snapshot date is - '$date
  set +e
  # From url
  url='https://ftp.postgresql.org/pub/pgadmin/pgadmin4/snapshots/'$date'/apt/$(lsb_release -cs)'
  url="deb [signed-by=/usr/share/keyrings/packages-pgadmin-org.gpg] $url pgadmin4 main"
  echo '----Using url - '$url

  # Add repor config/Update repo data command
  echo '----Creating/Updating repo config'
  sudo sh -c "echo $url > /etc/apt/sources.list.d/pgadmin4.list && apt update"

  # Check mode
  suffix=""
  if [ "$mode" = "desktop" ]; then
    echo '----Installing pgAdmin4-desktop'
    sudo apt install pgadmin4-desktop -y
    suffix="-desktop"
  elif [ "$mode" = "server" ]; then
    echo '----Installing pgAdmin4-web'
    sudo apt install pgadmin4-web -y
    suffix="-web"
    # Configure the webserver, if you installed pgadmin4-web:
    sudo /usr/pgadmin4/bin/setup-web.sh --yes
  else
    echo '----Installing pgAdmin4 both modes'
    sudo apt install pgadmin4 -y
    sudo /usr/pgadmin4/bin/setup-web.sh --yes
  fi
  echo '\n'
  echo '***********************************************************'
  echo 'pgAdmin Sanpshot build installed successfully - '$(apt-show-versions pgadmin4"$suffix")
  echo '***********************************************************'
  echo '\n'
}

if [ "$operation" = "install" ]; then
  # Install released pgAdmin
  _install_released_pgadmin $mode
elif [ "$operation" = "install_cb" ]; then
  # Install candidate build pgAdmin
  _install_candidate_build_pgadmin $mode
elif [ "$operation" = "install_snapshot" ];then
  # Insall snapshot
  _install_snapshot_build_pgadmin $mode
elif [ "$operation" = "verify" ]; then
  # Verify upgraded pgAdmin
  _verify_installed_pgadmin $mode
elif [ "$operation" = "upgrade_cb" ]; then
  # Upgrade pgAdmin
  _upgrade_pgadmin_to_candidate_build $mode
elif [ "$operation" = "upgrade_test" ]; then
  # Install released pgAdmin
  _install_released_pgadmin $mode
  echo 'Press any key to continue... '
  read var

  # Verify released pgAdmin
  _verify_installed_pgadmin $mode
  echo 'Press any key to continue... '
  read var

  # Upgrade pgAdmin
  _upgrade_pgadmin_to_candidate_build $mode
  echo 'Press any key to continue... '
  read var

  # Verify upgraded pgAdmin
  _verify_installed_pgadmin $mode
  echo 'Press any key to continue... '
  read var
elif [ "$operation" = "fresh_test" ]; then
  # Install candidate build pgAdmin
  _install_candidate_build_pgadmin $mode
  echo 'Press any key to continue... '
  read var

  # Verify upgraded pgAdmin
  _verify_installed_pgadmin $mode
  echo 'Press any key to continue... '
  read var

else
    echo 'Specify correct operation:install, verify, upgrade, all'
fi
