# Pi-hole advertisement blocker

> This guide assumes that *OpenVPN* is installed on the system. If you are not using OpenVPN, you can just follow the default settings during the installation.

<br>

*Article 1: https://docs.pi-hole.net/guides/vpn/installation/*

*Article 2: https://docs.pi-hole.net/*

*Article 3: https://github.com/JavanXD/ya-pihole-list*

<br>

## Preparation

### Configure UFW
``` bash
sudo ufw allow 80/tcp
sudo ufw allow 53/tcp comment 'pihole'
sudo ufw allow 53/udp comment 'pihole'
sudo ufw allow 67/tcp comment 'pihole'
sudo ufw allow 67/udp comment 'pihole'
sudo ufw allow 546:547/udp comment 'pihole'   # if using IPv6
```

### Static IP
The Raspberry Pi needs to have a *static IP* for the pihole to function correctly.
Make sure that you configure your router's DHCP settings or that you select a static IP in the Raspberry Pi's settings.

<br>

## Install Pi-hole

Script needs to run with elevated privileges:
``` bash
sudo su
```

``` bash
curl -sSL https://install.pi-hole.net | bash
```

### Configuration during installation
``` bash
# Static IP Needed
Continue

# Choose yes to indicate that you have understood this message, and wish to continue
yes

# interface (in order to be able to work with OpenVPN. If not using OpenVPN, select 'eth0')
tun0

# IP protocols (if you use IP v6)
both

# Static IP Address
Skip

# Choose an upstream DNS provider
OpenDNS

# block lists
all offered

# Do you wish to install the web admin interface?
Yes

# Do you wish to install the web server (lighttpd) and required PHP modules?
Yes

# Do you want to log queries?
Yes

# Select a privacy mode for FTL.
0 Show everything

# !!! IMPORTANT !!!
# KEEP A NOTE OF THE ADMIN PASSWORD
```

Exit the elevated terminal:
```bash
exit
```

### Set admin password

Choose your own password:
``` bash
sudo pihole -a -p
```

### Configure [DNSSEC](https://www.icann.org/resources/pages/dnssec-what-is-it-why-important-2019-03-05-en)
```
# Access admin panel at {RASPBERRY-PI-IP}/admin
# e.g: 192.168.1.100/admin

# Settings --> DNS --> Advanced DNS settings
Check "Use DNSSEC"
```

### Configure interfaces

##### Using the terminal
``` bash
pihole -a -i all
```

##### Using the admin panel
```
# Access admin panel at {RASPBERRY-PI-IP}/admin
# e.g: 192.168.1.100/admin

# Settings --> DNS --> Interface settings --> Potentially dangerous options
Permit all origins
```

## OpenVPN configuration

Assuming an *OpenVPN* server is running on your system, configure it to use Pi-hole by following the steps [HERE](https://github.com/smyrnakis/raspberry-born/blob/main/chapters/vpn.md#configure-openvpn-to-use-pi-hole).

<br>

## Add more domains in the Blocklist

You can find many interesting blocklists here: [https://avoidthehack.com/best-pihole-blocklists](https://avoidthehack.com/best-pihole-blocklists) .

From those lists, I chose:
* https://osint.digitalside.it/Threat-Intel/lists/latestdomains.txt
* https://v.firebog.net/hosts/Prigent-Crypto.txt
* https://v.firebog.net/hosts/RPiList-Phishing.txt

In order to add the lists:
1. Navigate to your Pi-hole's admin panel and click on **Adlists** in the menu.
2. In the *Address:* field, add the above URLs
    - you can add all URLs at once, separated by space
    - add them individually if you want to include a different *comment* for every list
3. Click on the **Add** button
4. Click on the **online** link just bellow to update the Gravity DB

<br>

<details>
<summary>ya-pihole-list</summary>

> UPDATE 2023/03/16
> I did not use this tool now. Check the previous method, just above.

``` bash
cd ~/Software
git clone --depth=1 https://github.com/JavanXD/ya-pihole-list.git ya-pihole-list
cd ya-pihole-list
```

Edit the following in the `adlists-updater.sh` :
``` bash
# replace username / fix the paths in lines 18 & 19
adListFile="$HOME/Software/ya-pihole-list/adlists.list.updater"
tmpFile="$HOME/Software/ya-pihole-list/adlists.list.updater.tmp"

# line 39
apt-get update && apt-get upgrade -y
```

Make the script executable and run it:
``` bash
sudo chmod a+x adlists-updater.sh
sudo bash adlists-updater.sh 1
```

### Schedule automatic gravity update every day at 05:15
``` bash
sudo crontab -e
```

Add the following line, replacing the path as above:
``` bash
15 5 * * * sudo /home/{YOUR-USERNAME}/Software/ya-pihole-list/adlists-updater.sh 1 >/dev/null
```

</details>

<br>

## Auto update blocklists

> TO BE FIXED
> Check: https://github.com/jacklul/pihole-updatelists

<br>

## Debugging

``` bash
# check the status
pihole status

# print a summary, once (optimised for small screen)
pihole -c -e

# print a summary, refresh every 5" (optimised for small screen)
pihole -c -r 5

# log file
tail -f /var/log/pihole.log
```

<br>

## Allow/Block lists

List of common whitelist URLs: [https://discourse.pi-hole.net/t/commonly-whitelisted-domains/212](https://discourse.pi-hole.net/t/commonly-whitelisted-domains/212)

<br>

For bulk addition, you can use:
``` bash
!#/bin/bash

pihole -w $(tr ‘\n’ ’ ’ < input_filename)
# https://discourse.pi-hole.net/t/add-comments-to-domains-on-the-cli/28556/9
```

### Spotify
``` bash
sudo pihole -w spclient.wg.spotify.com
```

More on Spotify: [https://gist.github.com/captainhook/9eb4132d6e58888e37c6bc6c73dd4e60](https://gist.github.com/captainhook/9eb4132d6e58888e37c6bc6c73dd4e60)

### YouTube
``` bash
# to enable 'watched' history
sudo pihole -w s.youtube.com
```

### WINDVision

> Not clear if needed! Under investigation...

``` bash
# to enable WINDVision system updates
sudo pihole -w redirector.gvt1.com
```

### Discourse thread

In case of issues, consider whitelisting the domains described here.

[https://discourse.pi-hole.net/t/commonly-whitelisted-domains/212/109](https://discourse.pi-hole.net/t/commonly-whitelisted-domains/212/109)

<br>

## Extra

### Back up *iptables* rules
``` bash
sudo iptables-save > /etc/pihole/rules.v4
sudo ip6tables-save > /etc/pihole/rules.v6
```

You can restore the rules using:
``` bash
sudo iptables-restore < /etc/pihole/rules.v4
sudo ip6tables-restore < /etc/pihole/rules.v6
```

### Hostnames

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

### Router configuration

Do not forget to configure the router to use the Raspberry Pi's IP addresses (IPv4 & IPv6) for DNS.

To check find the IPs use:
``` bash
ip a
```

<br>

### Command line usage

[https://discourse.pi-hole.net/t/the-pihole-command-with-examples/738](https://discourse.pi-hole.net/t/the-pihole-command-with-examples/738)

<br>

### Indicator LEDs

You can add LEDs on the GPIO pins and let them blink with allowed or blocked DNS queries.

Create a file in `~/Software/pihole/pihole-LEDs.sh`
``` bash
mkdir ~/Software/pihole
cd ~/Software/pihole

touch pihole-LEDs.sh
```

Add the following code into the file : [pihole-LEDs.sh](https://github.com/smyrnakis/raspberry-born/blob/main/src/pihole-LEDs.sh)

*The code above uses GPIO20 and GPIO21 for the GREEN and the RED LED respectively.*

Make the script executable:
``` bash
chmod a+x ~/Software/pihole/pihole-LEDs.sh
```

Test the script by *uncommenting* the `echo` lines:
``` bash
[...]

tail -f /var/log/pihole.log | while read INPUT
do
    if [[ "$INPUT" == *": gravity blocked"* ]]; then
        shortBlink red
        echo "pihole block"     # uncomment this line
    fi
    if [[ "$INPUT" == *": reply"* ]]; then
        shortBlink green
        echo "pihole allow"     # uncomment this line
    fi
done
```

``` bash
sudo bash ~/Software/pihole/pihole-LEDs.sh
```

If you can see the LEDs blinking and the messages `pihole block` or `pihole allow` on the console, the script and the hardware are working fine!

Comment out the two `echo` commands again.

Set the script to run on Raspberry's boot:
``` bash
sudo crontab -e
```

and add the line:
``` bash
@reboot bash /home/{YOUR-USERNAME}/Software/pihole/pihole-LEDs.sh
```

<br>
