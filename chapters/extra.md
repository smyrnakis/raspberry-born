# Extra commands and snippets
*(shorted alphabetically)*

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

### Process by name (find)
``` bash
# find a process by name, e.g: "nano"
ps aux | grep -i nano
```

<br>

### Raspberry Pi version
``` bash
cat /sys/firmware/devicetree/base/model
```

<br>

### scp for file copies over ssh

<br>

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
# current time / how much time system is up / connected users / system load
uptime
>19:53:34 up 1 day, 18:46,  1 user,  load average: 0.15, 0.13, 0.11

# how much time system is up
uptime -p
> up 1 day, 18 hours, 44 minutes

# time system started
uptime -s
> 2021-01-19 01:06:57
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
