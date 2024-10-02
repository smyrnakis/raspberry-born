# Extra commands and snippets
*(shorted alphabetically **after** logs section)*

<br>

### Useful logs & debugging locations

``` bash
# main & system logs
sudo journalctl
sudo journalctl -f

sudo tail /var/log/syslog
sudo tail /var/log/messages

# security
sudo journalctl -u ssh
sudo tail /var/log/auth.log

# unattended-upgrade
sudo cat /var/log/syslog | grep unattended-upgrade

# msmtp email logs
sudo journalctl -u msmtp
sudo cat /var/log/syslog | grep msmtp
sudo tail /var/log/mail.log

# OpenVPN
sudo tail -f /var/log/openvpn-status.log
sudo tail -f /var/log/openvpn.log
grep VPN /var/log/syslog

ps aux | grep "OpenVPN-email.sh"

# Pi-hole
pihole status
pihole -c -e
pihole -c -r 5
tail -f /var/log/pihole.log
```

<br>

### crontab
To configure a script to run recursively, add it in crontab.
Useful info available [HERE](https://crontab.guru/) and [HERE](https://man7.org/linux/man-pages/man5/crontab.5.html).

Open crontab:
``` bash
sudo crontab -e
```

Add the following line to have the script executing **weekly** at **12:00** noon:
``` bash
0 12 * * 1 /path/to/script.sh
```

To execute a script on system's reboot, use:
``` bash
@reboot /path/to/script.sh
```

To review currently running cronjobs:
``` bash
ps fauxww | grep -A 1 '[C]RON'
```

<br>

### `rc.local`
```bash
sudo vim /etc/rc.local
```

<br>

### Fix "`perl: warning: Falling back to a fallback locale ("en_GB.UTF-8").`"
``` bash
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
sudo locale-gen en_US.UTF-8
sudo dpkg-reconfigure locales
```

Edit the `/etc/ssh/sshd_config` file and commend out the line `SendEnv LANG LC_*` :
``` bash
#   SendEnv LANG LC_*
```

<br>

### Installed package version
``` bash
sudo apt list {PACKAGE-NAME}
```

<br>

### Mount + auto mount at boot

> The example bellow is for mounting a **network share** folder.
>
> To identify and mount a connected USB drive or microSD card, use the command `sudo fdisk -l`.

To view connected storage devices use:
```bash
sudo lsblk
```

or for more detailed view:
```bash
sudo fdisk -l
```

#### One-time mount
Create a directory where you will mount the *network share*:
``` bash
sudo mkdir /mnt/NAS
```

Mount the share:
``` bash
# For the examples bellow:
# server's IP       :    192.168.1.50
# network share     :    Raspberry
# server's username :    raspi

mount -t cifs -o user=raspi,rw,file_mode=0777,dir_mode=0777 //192.168.1.50/Raspberry /mnt/NAS
Password for raspi@//192.168.1.50/Raspberry:  ******
```

#### Auto-mount at boot
*Mounting on the `mnt/NAS` directory created in the previous step.*

Create the `credentials` file that will store your SAMBA *username* & *password* in `/etc/samba/`:
``` bash
sudo touch /etc/samba/credentials
```

Add **only** two lines with the exact text (replacing `{YOUR-USERNAME}` and `{YOUR-PASSWORD}`). The credentials are those of the *network server*, not your Raspberry Pi login.
``` bash
username={YOUR-USERNAME}
password={YOUR-PASSWORD}
```

Make `root` the owner and give only *read* permissions:
``` bash
chown root:root /etc/samba/credentials
sudo chmod 400 /etc/samba/credentials
```

Edit the `etc/fstab` file
``` bash
sudo nano etc/fstab
```

and add the following line (replacing accordingly):
``` bash
//192.168.1.50/Raspberry /mnt/NAS cifs _netdev,credentials=/etc/samba/credentials,rw,file_mode=0777,dir_mode=0777,comment=systemd.automount,x-systemd.mount-timeout=30  0  0
```

The `_netdev` means that the mount is treated as a *Network Drive* thus mounting will execute after network link is up.

<br>

### Network listening
``` bash
sudo netstat -putan | grep LISTEN
```

### Networks and IPs
View all networks:
```bash
ifconfig

ip -a
```

Connected SSID:
```bash
iwgetid
```

WiFi configuration file in `/etc/wpa_supplicant/wpa_supplicant.conf`
```bash
sudo vim /etc/wpa_supplicant/wpa_supplicant.conf
```

File's structure:
```json
network={
    ssid="your_SSID"
    psk="your_password"
}
```

After updating `wpa_supplicant.conf`, use `wpa_cli reconfigure` to reconfigure the WiFi connection:
```bash
wpa_cli reconfigure
```

Disconnect from WiFi: 
```bash
sudo ifconfig wlan0 down
```

Reconnect to WiFi: 
```bash
sudo ifconfig wlan0 up
```

<br>

### Process by name (find)
``` bash
# find a process by name, e.g: "nano"
ps aux | grep -i nano
```

<br>

### Python
``` bash
# Python version
python --version
> Python 2.7.13

# Use Python 3 by default
# edit .bashrc file
nano ~/.bashrc

# add the following alias
alias python='/usr/bin/python3'

# source the .bashrc
source ~/.bashrc

# if using zrc:
source ~/.zshrc
```

<br>

### Raspberry Pi version
``` bash
cat /sys/firmware/devicetree/base/model
```

<br>

<!--
### scp for file copies over ssh

<br>
-->

### Shutdown / Reboot schedule
Check if/when a *shutdown* or a *reboot* is scheduled:
``` bash
cat /run/systemd/shutdown/scheduled
```
Output:
``` bash
USEC=1610159400000000
WARN_WALL=1
MODE=reboot
```
Convert time to human-readable format:
``` bash
date -d "@$( awk -F '=' '/USEC/{ $2=substr($2,1,10); print $2 }' /run/systemd/shutdown/scheduled )"

Sat Jan  9 04:30:00 EET 2021
```

<br>

### Successful / failed SSH logins
``` bash
cat /var/log/auth.log | grep 'Accepted password'

cat /var/log/auth.log | grep 'Failed password'

cat /var/log/auth.log | grep 'Accepted publickey'

cat /var/log/auth.log | grep 'Failed publickey'
```

<br>

### Connected Users
```bash
w
```
```bash
who
```
```bash
users
```
```bash
last
```

<br>

### Temperature
``` bash
/opt/vc/bin/vcgencmd measure_temp

temp=34.4'C
```

<br>

### Uninstall package
``` bash
# uninstall a package
sudo apt-get purge {PACKAGE-NAME}
    # remove : remove installation files (only)
    # purge  : remove installation & configuration files

# remove unnecessary files & dependencies
sudo apt-get autoremove
```

<br>

### Uptime
``` bash
# current time / how much time system is up / connected users / system load [1-5-15]
uptime
>19:53:34 up 1 day, 18:46,  1 user,  load average: 0.15, 0.13, 0.11

# how much time system is up
uptime -p
> up 1 day, 18 hours, 44 minutes

# time system started
uptime -s
> 2021-01-19 01:06:57

# CPU average load (1 minute)
uptime | grep 'load average: ' | awk '{print $10}' | sed 's/,//g'
```

<br>

<!--
#### Automatic SD card backup
[https://www.raspberrypi.org/forums/viewtopic.php?p=136912#p173999](https://www.raspberrypi.org/forums/viewtopic.php?p=136912#p173999)

<br>

#### Automatic reboot with *watchdog timmer*
[https://pi.gadgetoid.com/article/who-watches-the-watcher](https://pi.gadgetoid.com/article/who-watches-the-watcher)

<br>
-->
