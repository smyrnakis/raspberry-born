# Dynamic DNS with *noip*

## Using *ddclient*

*Article 1: https://help.ubuntu.com/community/DynamicDNS*

*Article 2: https://www.andreagrandi.it/2014/09/02/configuring-ddclient-to-update-your-dynamic-dns-at-noip-com/*

*Article 3: https://pimylifeup.com/raspberry-pi-port-forwarding/*

### Install & configure
``` bash
sudo apt-get install ddclient
```

In the configuration screen, use:
``` bash
# service
other

# XXXXX
noip

# server
dynupdate.no-ip.com

# # protocol
# dyndns2

# username
{YOUR-NOIP-USERNAME}

# password
{YOUR-NOIP-PASSWORD}

# detection method
Web-based IP discovery service

# interface
eth0
# choose 'wlan0' if your using WiFi as the main way to connect the Raspberry Pi to the internet

# FQDN
{YOUR-NOIP-HOSTNAME}
```

Depending on the version of the ddclient, you will find either options in `/etc/ddclient.conf` :
```bash
# checkip
ssl=yes \
use=web, web=checkip.dyndns.com/, web-skip='IP Address' \

# ipify
use=web, https://api.ipify.org/ \
```


Ensure the following exist in the file `/etc/default/ddclient` :
``` bash
run_daemon="true"
daemon_interval="5m"
```

Restart the client:
``` bash
sudo /etc/init.d/ddclient restart
```

Start the service:
``` bash
sudo service ddclient start
```

Allow *ddclient* through UFW:
``` bash
# ddclient is using port 80
sudo ufw allow 80 comment 'ddclient'
```

Troubleshooting:
``` bash
sudo tail /var/log/syslog | grep ddclient

sudo ddclient -daemon=0 -debug -verbose -noquiet
```

<br>

## Using *noip* client

*Article: http://www.noip.com/support/knowledgebase/install-ip-duc-onto-raspberry-pi/*

### Create a folder
``` bash
mkdir ~/Software/noip
```

### Download
``` bash
cd ~/Software/noip

wget https://www.noip.com/client/linux/noip-duc-linux.tar.gz

tar vzxf noip-duc-linux.tar.gz

rm noip-duc-linux.tar.gz

cd noip-2.1.9-1
```

### Install & configure
``` bash
sudo make

sudo make install
```

```
Auto configuration for Linux client of no-ip.com.

Please enter the login/email string for no-ip.com  XXXXXX@gmail.com
Please enter the password for user 'XXXXXX@gmail.com'  *********

3 hosts are registered to this account.
Do you wish to have them all updated?[N] (y/N)  N
Do you wish to have host [XXXXXX] updated?[N] (y/N)  N
Do you wish to have host [YYYYYY] updated?[N] (y/N)  N
Do you wish to have host [ZZZZZZ] updated?[N] (y/N)  y

Please enter an update interval:[30]  5

Do you wish to run something at successful update?[N] (y/N)  N

New configuration file '/tmp/no-ip2.conf' created.
mv /tmp/no-ip2.conf /usr/local/etc/no-ip2.conf
```

### Uninstall
``` bash
# get the noip2 process ID by running 'sudo noip2 -S'
sudo noip2 -K {PROCESS-ID}

sudo rm /usr/local/bin/noip2
sudo rm /usr/local/etc/no-ip2.conf
sudo rm -rf ~/Software/noip

# if auto start was enabled
sudo rm /etc/init.d/noip2
```

### Extra

#### Start noip
```
sudo /usr/local/bin/noip2
```

#### Check if the service is running
``` bash
sudo noip2 -S
```

#### Auto-start `noip2` on system boot
``` bash
sudo vim /etc/rc.local
```

Add the following line before the `exit 0` line:

``` bash
/usr/local/bin/noip2
```

#### Configure autostart at system boot (alternative way)

Instructions [HERE](https://github.com/smyrnakis/raspberry-born/blob/main/chapters/autostart.md).

#### Check `noip2` logs

``` bash
sudo journalctl | grep 'noip2'
```

<br>
