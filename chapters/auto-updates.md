# Automatic updates with email report

*Article 1: https://wiki.debian.org/UnattendedUpgrades*

*Article 2: https://www.zealfortechnology.com/2018/08/configure-unattended-upgrades-on-raspberry-pi.html*

### Install needed packages

``` bash
sudo apt-get install unattended-upgrades
sudo apt-get install mailutils
sudo apt-get install update-notifier-common
```

### Configure `unattended-upgrades`

``` bash
sudo nano /etc/apt/apt.conf.d/50unattended-upgrades
```

Recommended settings:

``` bash
Unattended-Upgrade::Mail "{YOUR-EMAIL}@gmail.com";
Unattended-Upgrade::MailOnlyOnError "true";

Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "04:30";
```

``` bash
sudo nano /etc/apt/apt.conf.d/20auto-upgrades
```

Recommended settings:

``` bash
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::Verbose "1";
APT::Periodic::AutocleanInterval "7";
```

### Test

``` bash
sudo unattended-upgrade -d -v --dry-run
```

### Enable `unattended-upgrades`

``` bash
sudo dpkg-reconfigure --priority=low unattended-upgrades
```

<br>
