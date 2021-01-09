# Message Of The Day (MOTD)

### Files location
``` bash
# static file
/etc/motd

# dynamic file
/var/run/motd.dynamic

# scripts updating dynamic file are under:
/etc/update-motd.d/
```

### Remove current MOTD
Remove and disable the default MOTD:
``` bash
# disable MOTD
sudo systemctl disable motd

# remove the motd file
sudo rm -f /etc/motd

# remove the script updating the motd file
sudo rm /etc/update-motd.d/10-uname
```

### Create new files
``` bash
# script updating motd file
sudo touch /etc/update-motd.d/10-custom

# change permissions
sudo chown root:root /etc/update-motd.d/10-custom
sudo chmod a+x /etc/update-motd.d/10-custom
```

In the file `10-custom` add the code from the file [motd.sh](https://github.com/smyrnakis/raspberry-born/blob/main/src/motd.sh).

### Test
You can test the script by running:
``` bash
bash /etc/update-motd.d/10-custom
```

<br>

### Feature work

``` bash
# Running processes
ps ax | wc -l | tr -d " "
```

``` bash
# weather info
curl -s "http://rss.accuweather.com/rss/liveweather_rss.asp?metric=1&locCode=EUR|UK|UK001|NAILSEA|" | sed -n '/Currently:/ s/.*: \(.*\): \([0-9]*\)\([CF]\).*/\2°\3, \1/p'
```