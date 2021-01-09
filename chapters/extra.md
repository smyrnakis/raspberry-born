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

<br>

### Installed package version
``` bash
sudo apt list {PACKAGE-NAME}
```

<br>

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

<!--
#### Automatic SD card backup
[https://www.raspberrypi.org/forums/viewtopic.php?p=136912#p173999](https://www.raspberrypi.org/forums/viewtopic.php?p=136912#p173999)

<br>

#### Automatic reboot with *watchdog timmer*
[https://pi.gadgetoid.com/article/who-watches-the-watcher](https://pi.gadgetoid.com/article/who-watches-the-watcher)

<br>
-->
