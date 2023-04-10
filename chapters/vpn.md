# Install & configure ***OpenVPN*** server

*Article 1: https://docs.pi-hole.net/guides/vpn/overview/*

*Article 2: https://github.com/OpenVPN/easy-rsa/blob/master/easyrsa3/vars.example*

*Article 3: https://blog.securityevaluators.com/hardening-openvpn-in-2020-1672c3c4135a*

*Article 4: https://blog.g3rt.nl/openvpn-security-tips.html*

<br>

## Preparation

Ensure the system is updated:
``` bash
sudo apt-get update && sudo apt-get upgrade -y
```

Create a directory named `OpenVPN`, subdirectory of `Software` in your `$HOME` :
``` bash
cd ~
mkdir Software
mkdir Software/OpenVPN
cd Software/OpenVPN
```

Download installation script and make it executable:
``` bash
wget https://git.io/vpn -O openvpn-install.sh
chmod 755 openvpn-install.sh
```

### Getting installation script ready

*The above script (version of 13/12/2021, including the customisations) is also available [HERE](https://github.com/smyrnakis/raspberry-born/blob/main/src/vpn/openvpn-install.sh).*

*It is recommended that you always get the newest version and follow the above steps before a fresh OpenVPN installation.*

<br>

Edit the installation script accordingly:
``` bash
nano openvpn-install.sh
```

#### External port
Add *External port* section, just after line `177`. This is the external port you plan to open in your router, where the clients will connect to :
``` bash
echo "What port should OpenVPN listen to?"
read -p "Port [1194]: " port
until [[ -z "$port" || "$port" =~ ^[0-9]+$ && "$port" -le 65535 ]]; do
  echo "$port: invalid port."
  read -p "Port [1194]: " port
done
[[ -z "$port" ]] && port="1194"
echo
# <<< PART TO BE ADDED STARTS HERE >>>
echo "What will be the external OpenVPN port?"
read -p "External Port [1194]: " extport
until [[ -z "$extport" || "$extport" =~ ^[0-9]+$ && "$extport" -le 65535 ]]; do
  echo "$extport: invalid port."
  read -p "External Port [1194]: " extport
done
[[ -z "$extport" ]] && extport="1194"
echo
# <<< PART TO BE ADDED FINISHES HERE >>>
```

#### *easy-rsa* version
The installation script will download `easy-rsa` from the official OpenVPN's [Github](https://github.com/OpenVPN/easy-rsa/releases/) repo.
It's recommended that you check the latest version in the repo is the same with the one the script will download *(`v3.1.2` as of 12/3/2023)*.
``` bash
# line 247
easy_rsa_url='https://github.com/OpenVPN/easy-rsa/releases/download/v3.1.2/EasyRSA-3.1.2.tgz'
```

#### easy-rsa *KEY_SIZE*
Add `EASYRSA_KEY_SIZE` var, after line `251`:
``` bash
chown -R root:root /etc/openvpn/server/easy-rsa/
cd /etc/openvpn/server/easy-rsa/
# <<< PART TO BE ADDED STARTS HERE >>>
cp vars.example vars
echo 'set_var EASYRSA_KEY_SIZE  4096' >> vars
# <<< PART TO BE ADDED FINISHES HERE >>>
```

At this point you can add more EASYRSA variables, e.g: `EASYRSA_REQ_EMAIL`. Example:
``` bash
echo 'set_var EASYRSA_REQ_EMAIL  {YOUR-EMAIL}' >> vars
```

#### Client's password
Remove the `nopass` argument from client's keys creation in line `259`:

``` bash
./easyrsa --batch build-ca nopass
EASYRSA_CERT_EXPIRE=3650 ./easyrsa build-server-full server nopass
# <<< PART TO BE EDITED STARTS HERE >>>
EASYRSA_CERT_EXPIRE=3650 ./easyrsa build-client-full "$client"
# <<< PART TO BE EDITED FINISHES HERE >>>
```

Doing this, the script will ask you to set client's certificate password which will be needed in order to connect to the server, improving the security of the configuration.

#### DH parameters
It is recommended to use `ffdhe4096` rather the `ffdhe2048` in order to increase the security. In line `270` there are the *pre-defined **ffdhe2048*** parameters.

Replace them with the *pre-defined **ffdhe4096*** available [HERE](https://github.com/internetstandards/dhe_groups/blob/master/ffdhe4096.pem) *(NL Internet Standards)* and also [HERE](https://github.com/smyrnakis/raspberry-born/blob/main/src/vpn/ffdhe4096.pem) *(re-uploaded on my repo)*.

``` bash
# line 270

# <<< PART TO BE REPLACED STARTS HERE >>>
echo '-----BEGIN DH PARAMETERS-----
MIIBCAKCAQEA//////////+t+FRYortKmq/cViAnPTzx2LnFg84tNpWp4TZBFGQz
+8yTnc4kmz75fS/jY2MMddj2gbICrsRhetPfHtXV/WVhJDP1H18GbtCFY2VVPe0a
87VXE15/V8k1mE8McODmi3fipona8+/och3xWKE2rec1MKzKT0g6eXq8CrGCsyT7
YdEIqUuyyOP7uWrat2DX9GgdT0Kj3jlN9K5W7edjcrsZCwenyO4KbXCeAvzhzffi
7MA0BM0oNC9hkXL+nOmFg/+OTxIy7vKBg8P+OxtMb61zO7X8vC7CIAXFjvGDfRaD
ssbzSibBsu/6iGtCOGEoXJf//////////wIBAg==
-----END DH PARAMETERS-----' > /etc/openvpn/server/dh.pem
# <<< PART TO BE REPLACED FINISHES HERE >>>

# <<< REPLACE ABOVE CODE WITH THE FOLLOWING>>>
echo '-----BEGIN DH PARAMETERS-----
MIICCAKCAgEA//////////+t+FRYortKmq/cViAnPTzx2LnFg84tNpWp4TZBFGQz
+8yTnc4kmz75fS/jY2MMddj2gbICrsRhetPfHtXV/WVhJDP1H18GbtCFY2VVPe0a
87VXE15/V8k1mE8McODmi3fipona8+/och3xWKE2rec1MKzKT0g6eXq8CrGCsyT7
YdEIqUuyyOP7uWrat2DX9GgdT0Kj3jlN9K5W7edjcrsZCwenyO4KbXCeAvzhzffi
7MA0BM0oNC9hkXL+nOmFg/+OTxIy7vKBg8P+OxtMb61zO7X8vC7CIAXFjvGDfRaD
ssbzSibBsu/6iGtCOGEfz9zeNVs7ZRkDW7w09N75nAI4YbRvydbmyQd62R0mkff3
7lmMsPrBhtkcrv4TCYUTknC0EwyTvEN5RPT9RFLi103TZPLiHnH1S/9croKrnJ32
nuhtK8UiNjoNq8Uhl5sN6todv5pC1cRITgq80Gv6U93vPBsg7j/VnXwl5B0rZp4e
8W5vUsMWTfT7eTDp5OWIV7asfV9C1p9tGHdjzx1VA0AEh/VbpX4xzHpxNciG77Qx
iu1qHgEtnmgyqQdgCpGBMMRtx3j5ca0AOAkpmaMzy4t6Gh25PXFAADwqTs6p+Y0K
zAqCkc3OyX3Pjsm1Wn+IpGtNtahR9EGC4caKAH5eZV9q//////////8CAQI=
-----END DH PARAMETERS-----' > /etc/openvpn/server/dh.pem
```

*More info: [IETF RFC 7919](https://tools.ietf.org/html/rfc7919)*

#### TLS version
To strengthen against downgrade attack on the TLS protocol level, add in a new line the `tls-version-min 1.2` on both *server* and *client* configuration (approx lines: `293` & `441` respectively).

``` bash
# line 293
ca ca.crt
cert server.crt
key server.key
dh dh.pem
auth SHA512
# <<< PART TO BE ADDED STARTS HERE >>>
tls-version-min 1.2
# <<< PART TO BE ADDED FINISHES HERE >>>
tls-crypt tc.key
topology subnet

# [...]

# line 441
nobind
persist-key
persist-tun
# <<< PART TO BE ADDED STARTS HERE >>>
tls-version-min 1.2
# <<< PART TO BE ADDED FINISHES HERE >>>
remote-cert-tls server
auth SHA512
```

#### Server logging
Change the logging directives of the server after the line `348`:

``` bash
verb 3
# <<< PART TO BE ADDED STARTS HERE >>>
mute 10
status /var/log/openvpn-status.log 20
log-append /var/log/openvpn.log
# <<< PART TO BE ADDED FINISHES HERE >>>
```

#### Client configuration
Replace `$port` variable with `$extport` in line `439`:

``` bash
dev tun
proto $protocol
# <<< PART TO BE EDITED STARTS HERE >>>
remote $ip $extport
# <<< PART TO BE EDITED FINISHES HERE >>>
```

#### Client's password (when adding new client)
Remove the `nopass` argument from client's keys creation in line `485`:

``` bash
cd /etc/openvpn/server/easy-rsa/
# <<< PART TO BE EDITED STARTS HERE >>>
EASYRSA_CERT_EXPIRE=3650 ./easyrsa build-client-full "$client"
# <<< PART TO BE EDITED FINISHES HERE >>>
```

<br>

### Dynamic DNS

It would be useful to set up a Dynamic DNS FQDN before starting the installation of OpenVPN. That way, you will be able to easily connect to your server remotely.

A guide is available in ["Dynamic DNS (ddclient & noip DUC)"](https://github.com/smyrnakis/raspberry-born/blob/main/chapters/dynamic-dns.md).

<br>

## Installation

Script needs to run with elevated privileges:
``` bash
sudo su
bash openvpn-install.sh
```

In the prompt about your *Public IPv4*, fill in your Dynamic DNS address, configured in the guide [HERE](https://github.com/smyrnakis/raspberry-born/blob/main/chapters/dynamic-dns.md) :
```
Public IPv4 address / hostname: {YOUR-NOIP-HOSTNAME}
```

Rest of the installation options:
``` bash
# Protocol
Which protocol should OpenVPN use?
   1) UDP (recommended)
   2) TCP
Protocol [1-2]: 1


# Service port
What port do you want OpenVPN listening to?
Port [1194]: 1194


# External port (configured at your home router)
# It's recommended to use a different port
What will be the external OpenVpn port?
External Port [1194]: 11194


# This will be reconfigured later
Select a DNS server for the client:
   1) Current system resolvers
   2) Google
   3) 1.1.1.1
   4) OpenDNS
   5) Quad9
   6) AdGuard
DNS [1-6]: 1


# Create the first client's profile
# The name can contain only letters, numbers, `-` or `_`
Enter a name for the first client:
Name [client]: MyMobile


OpenVPN installation is ready to begin.
Press any key to continue...

# [...]

# Enter the password for the first client
Enter PEM pass phrase:
```

At this step, the script will install the following packages (if not already installed):
`openvpn`, `openssl`, `ca-certificates`, `iptables`

```
The client configuration is available in: ~/MyMobile.ovpn
New clients can be added by running this script again.
```

The script is saving the client configuration (*.ovpn* file) in the home directory of the user.
Since we executed it as `root`, the file is saved in `/root/` directory.

You can copy this file to your home directory and distribute it to the users:
``` bash
cp /root/MyMobile.ovpn /home/{YOUR-USERNAME}/MyMobile.ovpn
```

For long term storage, you can create a directory under `/etc/openvpn/client/` and name it after the current date.
``` bash
mkdir /etc/openvpn/client/20230312
mv /root/*.ovpn /etc/openvpn/client/20230312/
```

<br>

*At this point, you can exit the `sudo su` mode by typing `exit`.*

<br>

You can always run the script again to `Add a new client`, `Revoke an existing client` or `Remove OpenVPN`:
```
OpenVPN is already installed.
Select an option:
  1) Add a new client
  2) Revoke an existing client
  3) Remove OpenVPN
  4) Exit
```

<br>

### UFW configuration

Allow OpenVPN through UFW firewall:

``` bash
sudo ufw allow openvpn comment 'OpenVPN'
```

<br>
<br>

## Extra

### Configure OpenVPN to use Pi-hole

> This step should be executed **AFTER** installing Pi-hole as described [HERE](https://github.com/smyrnakis/raspberry-born/blob/main/chapters/pihole.md).

Edit your `server.conf` file located in `/etc/openvpn/server/server.conf` and add the OpenVPN server address as the DNS.

You can keep one more DNS server as a secondary fallback option.
``` bash
push "dhcp-option DNS 10.8.0.1"
push "dhcp-option DNS 9.9.9.9"
```

Add a route for your network, e.g for 192.168.178.0/24, add:
``` bash
push "route 192.168.178.0 255.255.255.0"
```

[Restart](https://github.com/smyrnakis/raspberry-born/blob/main/chapters/vpn.md#startstoprestart-openvpn-service) OpenVPN server to apply the changes.

#### Another way (NOTE 2022/1/30: not to be used)
You could achieve the same result by instructing the Pi-hole to listen **only** on `eth0` interface and by adding the appropriate *route* & *DNS* in the `server.conf` file.

``` bash
pihole -a -i eth0
```

Assuming your Raspberry Pi has the IP `192.168.178.31` on a `255.255.255.0` network, the `server.conf` file should be updated:
``` bash
push "route 192.168.178.0 255.255.255.0"
push "dhcp-option DNS 192.168.178.31"
push "dhcp-option DNS 9.9.9.9"
```

### Start/Stop/Restart OpenVPN service
``` bash
sudo service openvpn start

sudo service openvpn stop

sudo service openvpn restart
```

### Status check & LOG files

To check the service status use:
``` bash
sudo service openvpn status
```

To check the OpenVPN's network interface use:
``` bash
ip a

# to see **only** the new interface:
ip a show tun0
```

Log files:
``` bash
sudo tail -f /var/log/openvpn.log
sudo tail -f /var/log/openvpn-status.log

grep VPN /var/log/syslog
```

### Restrictive networks

`UDP` help avoid [TCP meltdown](https://openvpn.net/faq/what-is-tcp-meltdown/) issue but might be restricted on some public networks, like cafè WiFi.

Server's and client's profiles should be edited accordingly:
``` bash
proto tcp
remote {YOUR-EXTERNAL-IP} 443
socket-flags TCP_NODELAY          #reduce latency
```

### Files' security
``` bash
sudo su
chmod 700 /etc/openvpn/client
# chmod -R 755 /etc/openvpn/server
```

<br>

### Notification email

<!--

> :warning: The method described in the HTML comment section did **NOT** work. The script `OpenVPN-email.sh` should not be used for this method! :warning:

The following steps will add a script which will be called by **OpenVPN server** on client's *connection* or *disconnection*.
The script will email us on client's connection / disconnection.

Create a file in `~/Software/OpenVPN/OpenVPN-email.sh`
``` bash
mkdir ~/Software/OpenVPN
cd ~/Software/OpenVPN

touch OpenVPN-email.sh
sudo chown root:root OpenVPN-email.sh
sudo chmod 744 OpenVPN-email.sh
```

Add the following code into the file : [OpenVPN-LED.sh](https://github.com/smyrnakis/raspberry-born/blob/main/src/vpn/OpenVPN-email.sh)
``` bash
sudo nano OpenVPN-email.sh
```

Add an *unprivileged* user `openvpn`:
``` bash
# adding user 'openvpn'
useradd -s /usr/sbin/nologin -r -M -d /dev/null openvpn
```

Verify that the new user was created:
``` bash
less /etc/passwd
```

Give user `openvpn` the right to execute the above script by editing the `sudoers` file:
``` bash
sudo visudo
```
Add the following in the `sudoers` file, replacing `{YOUR-USERNAME}`:
``` bash
openvpn ALL=NOPASSWD: /home/{YOUR-USERNAME}/Software/OpenVPN/OpenVPN-email.sh
```

Edit the `/etc/openvpn/server/server.conf` file according to the following:
``` bash
# change user / group that OpenVPN runs as
user openvpn
group nogroup

# add script execution using sudo
script-security 2
client-connect "/usr/bin/sudo /usr/bin/bash /home/{YOUR-USERNAME}/Software/OpenVPN/OpenVPN-email.sh"
client-disconnect "/usr/bin/sudo /usr/bin/bash /home/{YOUR-USERNAME}/Software/OpenVPN/OpenVPN-email.sh"
```

-->

The following steps will be checking the `/var/log/openvpn-status.log` log file for client's *connection* or *disconnection* and email us accordingly.

> The script is using the `msmtp` tool. Instructions on how to configure `msmtp` are available [HERE](https://github.com/smyrnakis/raspberry-born/blob/main/chapters/email.md).
> 
> 
> The script is using the `inotify` tool. Install it if not available:
> 
> `apt-get install -y inotify-tools`

Create a file in `~/Software/OpenVPN/OpenVPN-email.sh`
``` bash
mkdir ~/Software/OpenVPN
cd ~/Software/OpenVPN

touch OpenVPN-email.sh
sudo chown root:root OpenVPN-email.sh
sudo chmod 744 OpenVPN-email.sh
```

Add the following code into the file : [OpenVPN-email.sh](https://github.com/smyrnakis/raspberry-born/blob/main/src/vpn/OpenVPN-email.sh)
``` bash
sudo nano OpenVPN-email.sh
```

Add your email in line 13:
``` bash
recipient="{YOUR-EMAIL}"
```

Set the script to run on Raspberry's boot:
``` bash
sudo crontab -e
```

and add the line:
``` bash
@reboot sudo bash /home/{YOUR-USERNAME}/Software/OpenVPN/OpenVPN-email.sh
```

In order to allow the script to run with `sudo` command, you need to add it in the `visudo` file.
``` bash
sudo visudo
```

Add the following lines, replacing `{USERNAME}` with your username:
``` bash
# Give OpenVPN-email.sh script root permissions
{USERNAME} ALL=(ALL) NOPASSWD: /home/{USERNAME}/Software/OpenVPN/OpenVPN-email.sh
```

The script will email you the names and source IPs of the currently connected client(s) (every time a new client is connected or disconnected) and with the message *'All clients DISCONNECTED'* when there is no connected client on the OpenVPN server.

#### Debugging

To verify that the script is running, especially after a reboot, execute the following command:
``` bash
ps aux | grep "OpenVPN-email.sh"

root     1917605  0.0  0.0   6956  1724 ?        S    00:45   0:00 bash /home/tolis/Software/OpenVPN/OpenVPN-email.sh
```

### Indicator LED

You can add a LED on the GPIO pin and let it blink according to the number of connected clients. Do not forget to use an appropriate resistor on the LED!

Create a file in `~/Software/OpenVPN/OpenVPN-LED.sh`
``` bash
mkdir ~/Software/OpenVPN
cd ~/Software/OpenVPN

touch OpenVPN-LED.sh
```

Add the following code into the file : [OpenVPN-LED.sh](https://github.com/smyrnakis/raspberry-born/blob/main/src/vpn/OpenVPN-LED.sh)

*The code above uses GPIO16 for the YELLOW LED.*

Make the script executable:
``` bash
chmod a+x ~/Software/OpenVPN/OpenVPN-LED.sh
```

Test the script by *uncommenting* the `echo` line:
``` bash
[...]

if [[ ! -z "$CONNCLIENTS" ]]; then
    echo "$CONNCLIENTS" | while read LINE; do
        #echo "OpenVPN-LED : blink!"
        longBlink
        sleep 0.5
    done
fi
```

``` bash
sudo bash ~/Software/OpenVPN/OpenVPN-LED.sh
```

Connect on the OpenVPN server. If you can see the LED blinking and the message `OpenVPN-LED : blink!` on the console the script and the hardware are working fine!

Comment out the two `echo` command again.

Set the script to run on Raspberry's boot:
``` bash
sudo crontab -e
```

and add the line:
``` bash
@reboot bash /home/{YOUR-USERNAME}/Software/OpenVPN/OpenVPN-LED.sh
```

<br>

### A note on security

For security purposes, it is recommended that the CA machine should be separate from the machine running OpenVPN. If you lose control of your CA private key, you can no longer trust any certificates from this CA. Anyone with access to this CA private key can sign new certificates without your knowledge, which then can connect to your OpenVPN server without needing to modify anything on the VPN server. Place your CA files on storage that can be offline as much as possible, only to be activated when you need to get a new certificate for a client or server.

<br>
