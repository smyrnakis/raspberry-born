# Install & configure ***OpenVPN*** server

*Article 1: https://docs.pi-hole.net/guides/vpn/overview/*

*Article 2: https://github.com/OpenVPN/easy-rsa/blob/master/easyrsa3/vars.example*

*Article 3: https://blog.securityevaluators.com/hardening-openvpn-in-2020-1672c3c4135a*

<br>

## Preparation

Ensure the system is updated:
``` bash
sudo apt-get update -y && sudo apt-get upgrade -y
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

Edit the installation script accordingly:
``` bash
nano openvpn-install.sh
```

#### External port
Add *External port* section, just after line `170` :
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
echo "What will be the external OpenVpn port?"
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
It's recommended that you check the latest version in the repo is the same with the one the script will download *(`v3.0.8` as of 14/1/2021)*.
``` bash
# line 240
easy_rsa_url='https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.8/EasyRSA-3.0.8.tgz'
```

#### easy-rsa *KEY_SIZE*
Add `EASYRSA_KEY_SIZE` var, after line `245`:
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
Remove the `nopass` argument from client's keys creation in line `251`:

``` bash
./easyrsa --batch build-ca nopass
EASYRSA_CERT_EXPIRE=3650 ./easyrsa build-server-full server nopass
# <<< PART TO BE EDITED STARTS HERE >>>
EASYRSA_CERT_EXPIRE=3650 ./easyrsa build-client-full "$client"
# <<< PART TO BE EDITED FINISHES HERE >>>
```

Doing this, the script will ask you to set client's certificate password which will be needed in order to connect to the server, improving the security of the configuration.

#### DH parameters
It is recommended to use `ffdhe4096` rather the `ffdhe2048` in order to increase the security. In line `262` there are the *pre-defined **ffdhe2048*** parameters.

Replace them with the *pre-defined **ffdhe4096*** available [HERE](https://github.com/internetstandards/dhe_groups/blob/master/ffdhe4096.pem) *(NL Internet Standards)* and also [HERE](https://github.com/smyrnakis/raspberry-born/blob/main/src/vpn/ffdhe4096.pem) *(re-uploaded on my repo)*.

``` bash
# line 262

# <<< PART TO BE REPLACED STARTS HERE >>>
echo '-----BEGIN DH PARAMETERS-----
MIIBCAKCAQEA//////////+t+FRYortKmq/cViAnPTzx2LnFg84tNpWp4TZBFGQz
+8yTnc4kmz75fS/jY2MMddj2gbICrsRhetPfHtXV/WVhJDP1H18GbtCFY2VVPe0a
87VXE15/V8k1mE8McODmi3fipona8+/och3xWKE2rec1MKzKT0g6eXq8CrGCsyT7
YdEIqUuyyOP7uWrat2DX9GgdT0Kj3jlN9K5W7edjcrsZCwenyO4KbXCeAvzhzffi
7MA0BM0oNC9hkXL+nOmFg/+OTxIy7vKBg8P+OxtMb61zO7X8vC7CIAXFjvGDfRaD
ssbzSibBsu/6iGtCOGEoXJf//////////wIBAg==
-----END DH PARAMETERS-----' > /etc/openvpn/server/dh.pem
# <<< PART TO BE EDITED FINISHES HERE >>>

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

#### Server logging
Change the logging directives of the server in line `338`:

``` bash
# <<< PART TO BE REMOVED STARTS HERE >>>
status openvpn-status.log
verb 3
# <<< PART TO BE REMOVED FINISHES HERE >>>

# <<< PART TO BE ADDED STARTS HERE >>>
verb 4
mute 10
status /var/log/openvpn-status.log 20
log-append /var/log/openvpn.log
# <<< PART TO BE ADDED FINISHES HERE >>>
```

#### Client configuration
Replace `$port` variable with `$extport` in line `429`:

``` bash
dev tun
proto $protocol
# <<< PART TO BE EDITED STARTS HERE >>>
remote $ip $extport
# <<< PART TO BE EDITED FINISHES HERE >>>
```

#### Client's password (when adding new client)
Remove the `nopass` argument from client's keys creation in line `475`:

``` bash
cd /etc/openvpn/server/easy-rsa/
# <<< PART TO BE EDITED STARTS HERE >>>
EASYRSA_CERT_EXPIRE=3650 ./easyrsa build-client-full "$client"
# <<< PART TO BE EDITED FINISHES HERE >>>
```

<br>

*The above script (version of 13/12/2021, including the customisations) is also available [HERE](https://github.com/smyrnakis/raspberry-born/blob/main/src/vpn/openvpn-install.sh).*

*It is recommended that you always get the newest version and follow the above steps before a fresh OpenVPN installation.*

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
<br>

## Extra

### Configure OpenVPN to use Pi-hole

> This step should be executed **AFTER** installing Pi-hole as described [HERE](https://github.com/smyrnakis/raspberry-born/blob/main/chapters/pihole.md).

Edit your `server.conf` file located in `/etc/openvpn/server/server.conf` and add the OpenVPN server address as the DNS.

You can keep one more DNS server as a secondary fallback option.
``` bash
push "dhcp-option DNS 10.8.0.1"
push "dhcp-option DNS 1.1.1.1"
```

Add a route for your network, e.g for 192.168.178.0/24, add:
``` bash
push "route 192.168.178.0 255.255.255.0"
```

[Restart](https://github.com/smyrnakis/raspberry-born/blob/main/chapters/vpn.md#start-stop-restart-openvpn-service) OpenVPN server to apply the changes.

#### Another way
You could achieve the same result by instructing the Pi-hole to listen **only** on `eth0` interface and by adding the appropriate *route* & *DNS* in the `server.conf` file.

``` bash
pihole -a -i eth0
```

Assuming your Raspberry Pi has the IP `192.168.178.31` on a `255.255.255.0` network, the `server.conf` file should be updated:
``` bash
push "route 192.168.178.0 255.255.255.0"
push "dhcp-option DNS 192.168.178.31"
push "dhcp-option DNS 1.1.1.1"
```

### Start/Stop/Restart OpenVPN service
``` bash
sudo systemctl start openvpn@server

# enable service to start at reboot (already enabled on installation)
sudo systemctl enable openvpn@server
```

To restart the service use:
``` bash
sudo systemctl restart openvpn

# OR

sudo service openvpn restart
```

### Status check & LOG files

To check the service status use:
``` bash
sudo systemctl status openvpn@server

# OR

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
sudo tail /var/log/openvpn.log
sudo tail /var/log/openvpn-status.log

grep VPN /var/log/syslog
```

### Files' security
``` bash
chmod 751 -r /etc/openvpn/client
chmod 751 -r /etc/openvpn/server
```

### Restrictive networks

`UDP` help avoid [TCP meltdown](https://openvpn.net/faq/what-is-tcp-meltdown/) issue but might be restricted on some public networks, like cafè WiFi.

Server's and client's profiles should be edited accordingly:
``` bash
proto tcp
remote {YOUR-EXTERNAL-IP} 443
socket-flags TCP_NODELAY          #reduce latency
```

### A note on security

For security purposes, it is recommended that the CA machine should be separate from the machine running OpenVPN. If you lose control of your CA private key, you can no longer trust any certificates from this CA. Anyone with access to this CA private key can sign new certificates without your knowledge, which then can connect to your OpenVPN server without needing to modify anything on the VPN server. Place your CA files on storage that can be offline as much as possible, only to be activated when you need to get a new certificate for a client or server.

<br>
