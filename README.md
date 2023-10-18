# pgAdmin4-Deployment-Scripts
Provides pgAdmin4 deplyment scripts for Debian and rpm platforms. 

These shell script which installs released, candidate build, snapshot version.
Also it verifies pgAdmin launch in both server & desktop mode.
Scripts are written & tested for Debian & RPM packages.

**Usage**

Debian - 

1. Initial Setup.This may ask for restart.

  ```
bash pre_requivist_Apt.sh
```
2. Run script by specifying operation & mode. Command to install released version pgAdmin in both modes.

```
sudo bash pgAdmin_installer_automation_Apt.sh -o install
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

install_cb -  Installs candidate build version.

verify - Verifies pgadmin installation depending on mode and shows About box.

upgrade_cb - Upgrades to candidate build.

upgrade_test - Installs & verify released version and then upgrades to candidate build & verify.

fresh_test - Installs & verify the candidate build.

Modes -

  server - Web mode

  desktop - Desktop mode

  Both if not specified.
