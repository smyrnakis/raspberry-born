# Autostart a program on system boot

*Article: https://www.stuffaboutcode.com/2012/06/raspberry-pi-run-program-at-start-up.html*

### Create the autorun script in `/etc/init.d/`
``` bash
sudo nano /etc/init.d/{name-of-the-script}
```

Add the following content:
``` sh
#! /bin/sh
# /etc/init.d/{name-of-the-script}

### BEGIN INIT INFO
# Provides:          noip
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Description: Simple script to start a program at boot
### END INIT INFO

# If you want a command to always run, put it here

# Carry out specific functions when asked to by the system
case "$1" in
  start)
    echo "Starting noip"
    # run application you want to start
    /usr/local/bin/noip2
    ;;
  stop)
    echo "Stopping noip"
    # kill application you want to stop
    killall noip2
    ;;
  *)
    echo "Usage: /etc/init.d/noip {start|stop}"
    exit 1
    ;;
esac

exit 0
```

### Make executable
``` bash
sudo chmod 755 /etc/init.d/{name-of-the-script}
```

### Test script
``` bash
sudo /etc/init.d/{name-of-the-script} start

sudo /etc/init.d/{name-of-the-script} stop
```

### Register auto start
``` bash
sudo update-rc.d {name-of-the-script} defaults
```

Un-register with:
``` bash
sudo update-rc.d -f  {name-of-the-script} remove
```
<br>
