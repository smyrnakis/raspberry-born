# Pi-hole advertisement blocker & DNSCrypt

*Article 1: https://www.itchy.nl/raspberry-pi-4-with-openvpn-pihole-dnscrypt/*

*Article 2: https://docs.pi-hole.net/*

*Article 3: https://github.com/JavanXD/ya-pihole-list*

<br>

## DNSCrypt

### Install DNSCrypt
``` bash
# check and use the latest version: https://github.com/DNSCrypt/dnscrypt-proxy/releases/

cd /opt
sudo wget https://github.com/DNSCrypt/dnscrypt-proxy/releases/download/2.0.45/dnscrypt-proxy-linux_arm-2.0.45.tar.gz
sudo tar xf dnscrypt-proxy-linux_arm-2.0.45.tar.gz
sudo rm dnscrypt-proxy-linux_arm-2.0.45.tar.gz
sudo mv linux-arm dnscrypt-proxy
cd dnscrypt-proxy
sudo cp example-dnscrypt-proxy.toml dnscrypt-proxy.toml
```

### Configure & enable DNSCrypt
``` bash
sudo nano /opt/dnscrypt-proxy/dnscrypt-proxy.toml
```

Change the following settings:
``` bash
listen_addresses = ['127.0.0.1:54', '[::1]:54']

ipv6_servers = true # if you have IPv6 connectivity

require_dnssec = true

log_files_max_size = 30
log_files_max_age = 15
log_files_max_backups = 2
```

Enable the service:
``` bash
sudo ./dnscrypt-proxy -service install
sudo ./dnscrypt-proxy -service start
```

Check the service status:
``` bash
sudo systemctl status dnscrypt-proxy
```

<br>

## Pi-hole

### Configure UFW
``` bash
sudo ufw allow 80/tcp                        # if not already open
sudo ufw allow 53/tcp comment 'pihole'
sudo ufw allow 53/udp comment 'pihole'
sudo ufw allow 67/tcp comment 'pihole'
sudo ufw allow 67/udp comment 'pihole'
sudo ufw allow 546:547/udp comment 'pihole'   # if using IPv6
```

### Install Pi-hole
``` bash
wget -O basic-install.sh https://install.pi-hole.net
sudo bash basic-install.sh
```

### Configuration during installation
``` bash
# upstream DNS provider
cloudflare  # will be changed later

# block lists
both

# protocols
both

# Do you want to use your current network settings as a static address?
no

# desired IP
# e.g: 192.168.1.100/24
{YOUR-LOCAL-IP}/{YOUR-NETWORK-MASK}

# default gateway
# e.g: 192.168.1.1
{YOUR-ROUTER-IP}

# Do you wish to install the web admin interface?
on

# Do you wish to install the web server?
on

# Do you want to log queries?
on

# Select a privacy mode for FTL.
0 - show everything

# !!! IMPORTANT !!!
# KEEP A NOTE OF THE ADMIN PASSWORD
```

### Further configuration
```
# Access admin panel at {RASPBERRY-PI-IP}/admin
# e.g: 192.168.1.100/admin

# {RASPBERRY-PI-IP}/admin/settings.php?tab=dns
Uncheck any DNS server
Custom 1 (IPv4) --> 127.0.0.1#54
Custom 3 (IPv6) --> ::1#54

# Interface listening behavior
Listen on all interfaces

# Advanced DNS settings
Use DNSSEC
```

Choose your own password:
``` bash
sudo pihole -a -p
```

### Add more blocked domains
``` bash
cd ~/Software
git clone --depth=1 https://github.com/JavanXD/ya-pihole-list.git ya-pihole-list
cd ya-pihole-list
```

Edit the following in the `adlists-updater.sh` :
``` bash
# replace username / fix the paths in lines 12 & 13
adListFile="/home/{YOUR-USERNAME}/Software/ya-pihole-list/adlists.list.updater"
tmpFile="/home/{YOUR-USERNAME}/Software/ya-pihole-list/adlists.list.updater.tmp"

# line 38
apt-get update -y && apt-get upgrade -y
```

Run the `adlists-updater.sh`
``` bash
sudo chmod a+x adlists-updater.sh
sudo sh adlists-updater.sh 1
```

### Schedule automatic gravity update every day at 02:15
``` bash
sudo crontab -e
```

Add the following line, replacing the path as above:
``` bash
15 2 * * * sudo /home/tolis/Software/ya-pihole-list/adlists-updater.sh 1 >/dev/null
```

### Clean up
``` bash
rm ~/basic-install.sh
```

<br>

### Logs

``` bash
# print a summary, once (optimised for small screen)
pihole -c -e

# print a summary, refresh every 5" (optimised for small screen)
pihole -c -r 5

# log file
tail -f /var/log/pihole.log
```

<br>

### Extra

#### Spotify
``` bash
# whitelist the following domain
spclient.wg.spotify.com
```

More on Spotify: [https://gist.github.com/captainhook/9eb4132d6e58888e37c6bc6c73dd4e60](https://gist.github.com/captainhook/9eb4132d6e58888e37c6bc6c73dd4e60)

<br>

#### Hostnames

In order to show the hostnames in the Pi-hole console, you can update the `/etc/hosts` file and assign IP addresses to hostnames:

``` bash
127.0.0.1       localhost
::1             localhost ip6-localhost ip6-loopback
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters

127.0.1.1       {RASPBERRY-PI-HOSTNAME}

# examples bellow
192.168.1.1     my-router
192.168.1.2     my-phone
```

<br>

#### Router configuration

Do not forget to configure the router to use the Raspberry Pi's IP addresses (IPv4 & IPv6) for DNS.

To check find the IPs use:
``` bash
ip a
```

<br>
