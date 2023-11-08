# pgAdmin4-Deployment-Scripts
Provides pgAdmin4 deployment scripts for Debian and RPM platforms. 

These shell script installs released, candidate build, snapshot version. Also unintalls.
Also it verifies pgAdmin launch in both server & desktop mode.
Scripts are written & tested for Debian & RPM packages.

**Usage**

**Debian -**

1. Copy script to machine
```
curl -OO https://raw.githubusercontent.com/yogeshmahajan-1903/pgAdmin4-Deployment-Scripts/main/{pgAdmin_installer_automation_Apt.sh,prerequisite_Apt.sh}
```

2. Initial Setup.This will ask for restart.
```
bash prerequisite_Apt.sh
```

3. Run script by specifying operation & mode. Command to install released version pgAdmin in both modes.
```
sudo bash pgAdmin_installer_automation_Apt.sh -o install
````


**RPM -**

1. Copy script to machine
```
curl -OO https://raw.githubusercontent.com/yogeshmahajan-1903/pgAdmin4-Deployment-Scripts/main/{pgAdmin_installer_automation_Yum.sh,prerequisite_Yum.sh}
```

2. Initial Setup.This will ask for restart.
```
bash prerequisite_Yum.sh
```

3. Run script by specifying operation & mode. Command to install released version pgAdmin in both modes.
```
sudo bash pgAdmin_installer_automation_Yum.sh -o install
````

Note: While installing in server mode, email/password should be entered edb@edb.com/adminedb

  For server mode only
  ```
  sudo bash pgAdmin_installer_automation_Apt.sh -o verify -m server
  ```

  For Desktop mode only
  ```
  sudo bash pgAdmin_installer_automation_Apt.sh -o verify -m desktop
  ````

3. To access  help 
 ```
  sudo bash pgAdmin_installer_automation_Apt.sh -h
  ````

**Valid Arguments** 

Operations -

install - Installs latest released version.

install_snapshot - Installs today's snapshot version.(Also has option to provide back date)

install_cb -  Installs candidate build version.(cb - Candiate build)

verify - Verifies pgadmin installation depending on mode and shows About box.

upgrade_cb - Upgrades to candidate build.(cb - Candiate build)

upgrade_test - Installs & verify released version and then upgrades to candidate build & verify.

fresh_test - Installs & verify the candidate build.

uninstall - Unintalls existing pgAdmin 4.

Modes -

  server - Web mode

  desktop - Desktop mode

  Both if not specified.
