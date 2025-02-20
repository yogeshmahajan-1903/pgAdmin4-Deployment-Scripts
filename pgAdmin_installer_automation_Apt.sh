#! /bin/bash
# Wait times
WAIT_TO_LAUNCH_APP=15
WAIT_TO_LAUNCH_FF=10
WAIT_TO_LAUNCH_PGAMIN_IN_NWJS=15

WAIT_TO_LAUNCH_PGAMIN_IN_FF=12
ABOUT_BOX_SHOW_TIME=3

BUILD_DATE=''
export PGADMIN_SETUP_EMAIL='edb@edb.com'
export PGADMIN_SETUP_PASSWORD='adminedb'

# Exit on error
set -e

# Set up parser
help()
{
  echo "Usage: bash pgAdmin_installer_automation_Apt.sh 
  [ -o | --operation ](required):
      install  :Install latest released version
      install_snapshot :Install snapshot of specified date
      install_cb :Install candidate build of specified date
      install_old :Install older pgadmin version
      verify :Verify pgadmin installtion
      upgrade_cb :Upgrade to candidate build
      upgrade_test : Installs released version and then upgrades with candidate build and verify instalttion
      fresh_test : Installs candidate build and verify instalttion
      uninstall : Uninstall the pgadmin from system 
  [ -m | --mode ] (optional):
      desktop
      server
  [ -h | --help  ]"
  exit 2
}
SHORT=o:,m:,h
LONG=operation:,mode:,help
OPTS=$(getopt -a -n pgAdmin_installer_automation_Apt.sh --options $SHORT --longoptions $LONG -- "$@")

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

operations=("install" "install_cb" "install_snapshot" "install_old" "verify" "upgrade_cb" "upgrade_test" "fresh_test" "uninstall")
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
# echo '******Setting up display.********'
# CURRENT_DISPLAY=`xrandr | awk '/ connected/ && /[[:digit:]]x[[:digit:]].*+/{print $1}'`
# xrandr --output $CURRENT_DISPLAY --mode 1440x900 --size 16:10
# #xrandr --output Virtual1 --mode 1440x900 --size 16:10
# sleep 1.5

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
  echo ''
  echo '***********************************************************'
  echo 'Installing released pgAdmin version mode: - '$mode
  echo '***********************************************************'
  echo ''

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
    sudo -E /usr/pgadmin4/bin/setup-web.sh --yes
  else
    echo '----Installing pgAdmin4 in both modes'
    sudo apt install pgadmin4 -y
    # Configure the webserver, if you installed pgadmin4-web:
    sudo -E /usr/pgadmin4/bin/setup-web.sh --yes
  fi
  echo ''
  echo '***********************************************************'
  echo 'pgAdmin installed successfully - '$(apt-show-versions pgadmin4"$suffix")
  echo '***********************************************************'
  echo ''
}

_wait_for_window(){
  set +e
  win_name=$1
  wait_time=$2
  counter=$wait_time
  echo -ne '----Will wait for for '$counter' seconds to search window.'
  while [[ $counter -gt 0 ]]
  do
    wid=`xdotool search --onlyvisible --class --classname --name "${win_name}"`
    if [[ -z "$wid" ]]; then
      sleep 2
      counter=$(( counter - 1 ))
      if  [[ "$counter" -eq 0 ]]; then
        echo
        echo '---- '$win_name' not found after '$wait_time
        exit 1
      else
        echo -ne "."
      fi
    else
      echo
      echo '--- '$win_name' found.'
      counter=0
      sleep 2
    fi
  done

}

_wait_method(){
  set +e
  wait_time=$1
  counter=$wait_time
  echo -ne '----Waiting for '$counter' seconds'
  while [ $counter -gt 0 ]
  do
    read -t 1 -n 1
    if [ $? = 0 ] ; then
      counter=0
      sleep 1
    else
      echo -ne "."
    fi
    counter=$(( $counter -1))
  done
  if [ $counter = 0 ]; then
  echo
  fi
  set -e
}

_verify_installed_pgadmin_server_mode(){
  # platform name
  UNAME=$(uname -a)

  # Take pgAdmin mode as argument
  mode=$1

  # Info
  echo ''
  echo '***********************************************************'
  echo 'Verifying pgAdmin Launch in Server mode.'
  echo '***********************************************************'
  echo ''

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
  _wait_method $WAIT_TO_LAUNCH_FF
  set -e

  # Search to ff window
  wid=`xdotool search --sync --onlyvisible --class --classname --name "${app_name}"`
  xdotool windowactivate $wid key --delay 250 ctrl+t
  xdotool windowfocus $wid
  xdotool key shift+Print


  # Check if window is maximized
  # Try to unmaximize
  eval $(xdotool getwindowgeometry --shell ${wid})
  sum=`expr $X + $WIDTH`
  if [[ "$sum" == 1440 ||  "$sum" == 1441 ]];then
    echo '----Need to reduce size as launched in full screen.'
    xdotool mousemove --sync 875 45 click --repeat 2 1
    echo '----Unmaximized.'
  fi
  xdotool key shift+Print

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
  _wait_method $WAIT_TO_LAUNCH_PGAMIN_IN_FF
  xdotool key shift+Print

  #Move to login email and password &  Enter email
  echo '----Entering login details'
  xdotool type "edb@edb.com"
  xdotool key "Tab"
  xdotool type "adminedb"
  xdotool key "Return"
  _wait_method 15

  # Handle password save
  xdotool mousemove 240 530 click 1
  sleep 1
  # Verify version
  echo '----Verifying version from About'
  # Open Help
  xdotool mousemove 450 130 click 1
  sleep 0.5
  # About option
  xdotool mousemove 485 270 click 1
  sleep 3
  xdotool key shift+Print
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
  echo ''
  echo '***********************************************************'
  echo 'pgAdmin sever version verified successfully.'
  echo '***********************************************************'
  echo ''

}

_verify_installed_pgadmin_dektop_mode(){

  # Get platform name
  UNAME=$(uname -a)
  
  # Info
  echo ''
  echo '***********************************************************'
  echo 'Verifying pgAdmin launch in Desktop mode'
  echo '***********************************************************'
  echo ''

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
  sleep 1
  xdotool key shift+Print

  # Wait for pgAdmin to open
  echo '----Waiting to open pgAdmin.'
  app_name="pgAdmin 4"
  time=$WAIT_TO_LAUNCH_APP
  _wait_for_window "$app_name" "$time"
  _wait_method $WAIT_TO_LAUNCH_PGAMIN_IN_NWJS
  set -e

  # Search to pgAdmin window
  # Use only name else it will fail giving multiple windows.
  wid=`xdotool search --desktop --onlyvisible --name "${app_name}"`
  xdotool windowactivate $wid
  xdotool key shift+Print

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
  xdotool key shift+Print
  
  echo '----Wait till I show About box to check version.'
  # Move to Help Menu and click
  xdotool mousemove 240 75 click 1
  sleep 0.5
  # Move to About menu
  xdotool mousemove 285 205 click 1
  sleep $ABOUT_BOX_SHOW_TIME
  xdotool key shift+Print
  echo '----About menu shown. Now will quit pgAdmin.'

  # Move to pgAdmin4 close at top and click
  xdotool mousemove 1415 45 click 1
  sleep 1
  xdotool key "Return"
  echo '----pgAdmin is closed.'

  # Final Msg
  echo ''
  echo '***********************************************************'
  echo 'pgAdmin desktop version verified successfully.'
  echo '***********************************************************'
  echo ''
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

_get_build_date(){
  # Take build date
  set +e
  build_type=$1
    if [ "$build_type" = "cb" ]; then
      default_date=$(date +'%Y-%m-%d')-1
      read -r -p "----Enter the caididate build date. Press enter to select default.[default:$(date +'%Y-%m-%d')-1]." date
      date="${date:=$default_date}"
      echo '----Selected candidate build date is - '$date
      BUILD_DATE=$date
    else
      default_date=$(date +'%Y-%m-%d')
      read -r -p "----Enter the snapshot build date. Press enter to select default.[default:$(date +'%Y-%m-%d')]." date
      date="${date:=$default_date}"
      echo '----Selected snapshot build date is - '$date
      BUILD_DATE=$date
    fi
  set -e
}

_update_repo(){
  set +e
  build_type=$1

  KEY=/usr/share/keyrings/packages-pgadmin-org.gpg
  if [[ -f "$KEY" ]]; then
    echo "----Key exists. Removing key"
    rm -f /usr/share/keyrings/packages-pgadmin-org.gpg
  fi
  echo '----Adding key'
  curl -fsS https://www.pgadmin.org/static/packages_pgadmin_org.pub | sudo gpg  --dearmor -o /usr/share/keyrings/packages-pgadmin-org.gpg
  set -e
  
  echo '----Adding repo config file'
  # From url
  if [ "$build_type" = "cb" ]; then
    url='https://developer.pgadmin.org/builds/'$BUILD_DATE'/apt/$(lsb_release -cs)'
  else
    url='https://ftp.postgresql.org/pub/pgadmin/pgadmin4/snapshots/'$BUILD_DATE'/apt/$(lsb_release -cs)'
  fi

  # Add/Update  repo config
  echo '----Using url - '$url
  url="deb [signed-by=/usr/share/keyrings/packages-pgadmin-org.gpg] $url pgadmin4 main"
  echo '----Creating repo config'
  echo ''
  sudo sh -c "echo $url > /etc/apt/sources.list.d/pgadmin4.list && apt update"

}

_upgrade_pgadmin_to_candidate_build(){
  mode=$1
  mode=$([ "$mode" == "" ] && echo "Server & Desktop" || echo "$mode")
  echo ''
  echo '***********************************************************'
  echo 'Upgrading pgAdmin to candidate build : - '$mode
  echo '***********************************************************'
  echo ''

  echo '******Configuring repo .*******'
  # Take candidate build date
  _get_build_date cb

  # Update repo data
  _update_repo cb

  # Check mode
  echo '******Starting upgrade .*******'
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
    sudo -E /usr/pgadmin4/bin/setup-web.sh --yes
  fi
  
  # Final msg
  echo ''
  echo '***********************************************************'
  echo 'pgAdmin upgraded to candidate build successfully - '$(apt-show-versions pgadmin4"$suffix")
  echo '***********************************************************'
  echo ''
}

_install_candidate_build_pgadmin(){
  # Take pgAdmin mode as argument
  mode=$1
  mode=$([ "$mode" == "" ] && echo "Server & Desktop" || echo "$mode")

  # Info
  echo ''
  echo '***********************************************************'
  echo 'Installing Candidate build pgAdmin mode: - '$mode
  echo '***********************************************************'
  echo ''

  echo '******Configuring repo .*******'
  # Take candidate build date
  _get_build_date cb

  # Update repo data
  _update_repo cb

  # Check mode
  echo '******Starting installtion .*******'
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
    sudo -E /usr/pgadmin4/bin/setup-web.sh --yes
  else
    echo '----Installing pgAdmin4 both modes'
    sudo apt install pgadmin4 -y
    sudo -E /usr/pgadmin4/bin/setup-web.sh --yes
  fi
  echo ''
  echo '***********************************************************'
  echo 'pgAdmin Candidate Build installed successfully - '$(apt-show-versions pgadmin4"$suffix")
  echo '***********************************************************'
  echo ''
}

_install_snapshot_build_pgadmin(){
  # Take pgAdmin mode as argument
  mode=$1
  mode=$([ "$mode" == "" ] && echo "Server & Desktop" || echo "$mode")

  # Info
  echo ''
  echo '***********************************************************'
  echo 'Installing Snapshot build pgAdmin mode: - '$mode
  echo '***********************************************************'
  echo ''

  echo '******Configuring repo .*******'
  # Take snapshot build date
  _get_build_date

  # Update repo data
  _update_repo

  # Check mode
  echo '******Starting installtion .*******'
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
    sudo -E /usr/pgadmin4/bin/setup-web.sh --yes
  else
    echo '----Installing pgAdmin4 both modes'
    sudo apt install pgadmin4 -y
    sudo -E /usr/pgadmin4/bin/setup-web.sh --yes
  fi
  echo ''
  echo '***********************************************************'
  echo 'pgAdmin Sanpshot build installed successfully - '$(apt-show-versions pgadmin4"$suffix")
  echo '***********************************************************'
  echo ''
}

_install_older_version(){
  # Take pgAdmin mode, version as argument
  mode=$1
  mode=$([ "$mode" == "" ] && echo "Server & Desktop" || echo "$mode")


  # Take version
  set +e
  default_version=""
  read -r -p "----Enter the pgadmin version." version
  version="${version:=$default_version}"
  echo '----Entered version is - '$version
  set -e

  if  [ "$version" = "" ]; then
    echo 'Version is not specified.'
  else
    # Info
    echo ''
    echo '***********************************************************'
    echo 'Installing pgadmin version: - '$version
    echo '***********************************************************'
    echo ''

    echo '******Downloading package.*******'
    url=https://pgadmin-archive.postgresql.org/pgadmin4/apt/$(lsb_release -cs)/dists/pgadmin4/main/binary-amd64/
    server_url="$url"pgadmin4-server_"$version"_amd64.deb
    desktop_url="$url"pgadmin4-desktop_"$version"_amd64.deb

    if curl --output /dev/null --silent --head --fail "$server_url"; then
        echo '----Package found.'
        curl -O $server_url
        curl -O $desktop_url

        echo '******Starting installtion .*******'
        echo '*****Need to install released verison first and then will downgrade .*******'
        _install_released_pgadmin

        echo '******Now will downgrade .*******'
        sudo dpkg -i ./pgadmin4-server_"$version"_amd64.deb

        # Check mode
        suffix=""
        if [ "$mode" = "desktop" ]; then
          echo '----Installing pgAdmin4-desktop'
          sudo dpkg -i ./pgadmin4-desktop_"$version"_amd64.deb
          suffix="-desktop"
        elif [ "$mode" = "server" ]; then
          echo '----Installing pgAdmin4-web'
          suffix="-web"
          # Configure the webserver, if you installed pgadmin4-web:
          sudo -E /usr/pgadmin4/bin/setup-web.sh --yes
        else
          echo '----Installing pgAdmin4 both modes'
          sudo dpkg -i ./pgadmin4-desktop_"$version"_amd64.deb
          sudo -E /usr/pgadmin4/bin/setup-web.sh --yes
        fi
        echo ''
        echo '***********************************************************'
        echo 'pgAdmin Older version installed - '$(apt-show-versions pgadmin4"$suffix")
        echo '***********************************************************'
        echo ''
    else
      echo '################ Package for version specified does NOT exist -'$version
    fi

  fi
}

_uninstall(){
  # Info
  echo ''
  echo '***********************************************************'
  echo 'Uninstalling pgAdmin mode: - '$mode
  echo '***********************************************************'
  echo ''

  # Take pgAdmin mode as argument
  mode=$1
  mode=$([ "$mode" == "" ] && echo "Server & Desktop" || echo "$mode")
  remove_data_dir=$2
  remove_data_dir=$([ "$remove_data_dir" == "" ] && echo "1" || echo "0")

  # Check mode
  if [ "$mode" = "desktop" ]; then
    echo '----Uninstalling pgAdmin4-desktop'
    sudo apt remove pgadmin4-desktop -y
    sudo apt purge pgadmin4-desktop -y
  elif [ "$mode" = "server" ]; then
    echo '----Uninstalling pgAdmin4-web'
    sudo apt remove pgadmin4-web -y
    sudo apt purge pgadmin4-web -y
  else
    echo '----Uninstalling pgAdmin4 both modes'
    sudo apt remove pgadmin4 -y
    sudo apt purge pgadmin4* -y
  fi
  echo '----Running auto-remove'
  sudo apt auto-remove -y
  echo '----Cleaning cache'
  sudo apt clean all

  # Info
  echo ''
  echo '***********************************************************'
  echo 'pgAdmin uninstalled successfully - mode: - '$mode
  echo '***********************************************************'
  echo ''

  read -r -p 'Do you want to delete DATA DIR(y/N)' response
  case ${response} in
    y|Y )
      set +e
      echo '----Deleting DATA DIR'
      if [ "$mode" = "desktop" ]; then
        echo '----Deleting /home/'$SUDO_USER'/.pgadmin/'
        rm -rf /home/$SUDO_USER/.pgadmin/*
        rmdir /home/$SUDO_USER/.pgadmin
      elif [ "$mode" = "server" ]; then
        echo '----Deleting /var/lib/pgadmin/'
        sudo -E rm -rf /var/lib/pgadmin/*
        sudo -E rmdir /var/lib/pgadmin/
      else
        echo '----Deleting /home/'$SUDO_USER'/.pgadmin/'
        rm -rf /home/$SUDO_USER/.pgadmin/*
        rmdir /home/$SUDO_USER/.pgadmin/
        echo '----Deleting /var/lib/pgadmin/'
        sudo -E rm -rf /var/lib/pgadmin/*
        sudo -E rmdir /var/lib/pgadmin/
      fi
      set -e
      echo '----DATA DIR is Deleted.'  
      ;;
    * )
      echo '----DATA DIR is NOT Deleted.'
  echo ''
  esac

  echo ''
  read -r -p 'Do you want to delete Code directory(y/N)' response
  case ${response} in
    y|Y )
      set +e
      echo '----Deleting Code directory'
        echo '----Deleting files from /usr/pgadmin4/'
        sudo -E rm -rf /usr/pgadmin4/*
        sudo -E rmdir /usr/pgadmin4/
      set -e
      echo '----Code directory is Deleted.'  
      ;;
    * )
      echo '----Code directory is NOT Deleted.'
  echo ''
  esac

}

if [ "$operation" = "install" ]; then
  # Install released pgAdmin
  _install_released_pgadmin $mode
elif [ "$operation" = "install_cb" ]; then
  # Install candidate build pgAdmin
  _install_candidate_build_pgadmin $mode
elif [ "$operation" = "install_old" ]; then
  # Install candidate build pgAdmin
  _install_older_version $mode
elif [ "$operation" = "uninstall" ]; then
  # Uninstall candidate build pgAdmin
  _uninstall $mode
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
  echo 'Press any key to Verify installed pgAdmin... '
  read var

  # Verify released pgAdmin
  _verify_installed_pgadmin $mode
  echo 'Press any key to Upgrade to candidate build... '
  read var

  # Upgrade pgAdmin
  _upgrade_pgadmin_to_candidate_build $mode
  echo 'Press any key to Verify upgraded pgAdmin... '
  read var

  # Verify upgraded pgAdmin
  _verify_installed_pgadmin $mode

elif [ "$operation" = "fresh_test" ]; then
  # Install candidate build pgAdmin
  _install_candidate_build_pgadmin $mode
  echo 'Press any key to Verify installed pgAdmin.. '
  read var

  # Verify upgraded pgAdmin
  _verify_installed_pgadmin $mode

else
    echo 'Specify correct operation:install, verify, upgrade, all'
fi

echo ''
echo '!!!!!!! THANK YOU !!!!!!!'
echo ''
