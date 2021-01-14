# Install & configure ***OpenVPN*** server

:warning:
> It is recommended that you follow the automated installation method, described [HERE](https://github.com/smyrnakis/raspberry-born/blob/main/chapters/vpn.md) .

<br>

*Article 1: https://tecadmin.net/install-openvpn-debian-10/*

*Article 2: https://github.com/OpenVPN/easy-rsa/blob/master/easyrsa3/vars.example*

*Article 3: https://security.stackexchange.com/a/95184*

*Article 4: https://blog.securityevaluators.com/hardening-openvpn-in-2020-1672c3c4135a*

<br>

## Preparation

Ensure the system is updated:
``` bash
sudo apt-get update -y && sudo apt-get upgrade -y
```

Enable IP forwarding (IPv4 & IPv6) by changing the value of `net.ipv4.ip_forward` to `1` in the file `/etc/sysctl.conf` :
``` bash
sudo nano /etc/sysctl.conf
```
``` bash
net.ipv4.ip_forward=1
```

Save the file and apply the changes using the command:
``` bash
sudo sysctl -p
```

## Installation

Install OpenVPN server:
``` bash
sudo apt-get install openvpn -y
```

Copy `easy-rsa` folder into `/etc/openvpn` :
``` bash
sudo cp -r /usr/share/easy-rsa /etc/openvpn/
```

<br>

Since the following commands need elevated privileges, it's recommended to change to `root` user by:
```bash
sudo su
```

## Configure Certificate Authority

``` bash
cd /etc/openvpn/easy-rsa
nano vars
```

Add the following in the `vars` file (replacing accordingly):
``` bash
set_var EASYRSA                 "$PWD"
set_var EASYRSA_PKI             "$EASYRSA/pki"
set_var EASYRSA_DN              "cn_only"
set_var EASYRSA_REQ_COUNTRY     "GR"
set_var EASYRSA_REQ_PROVINCE    "Attika"
set_var EASYRSA_REQ_CITY        "Athens"
set_var EASYRSA_REQ_ORG         "MyRaspberry CA"
set_var EASYRSA_REQ_EMAIL	    "{YOUR-EMAIL}"
set_var EASYRSA_REQ_OU          "MyRaspberry EASY CA"
set_var EASYRSA_KEY_SIZE        4096
set_var EASYRSA_ALGO            rsa
set_var EASYRSA_CA_EXPIRE	    3650
set_var EASYRSA_CERT_EXPIRE     3650
set_var EASYRSA_NS_SUPPORT	    "no"
set_var EASYRSA_NS_COMMENT	    ""
set_var EASYRSA_EXT_DIR         "$EASYRSA/x509-types"
set_var EASYRSA_SSL_CONF        "$EASYRSA/openssl-easyrsa.cnf"
set_var EASYRSA_DIGEST          "sha256"
```

More info on the `vars` file is available [HERE](https://github.com/OpenVPN/easy-rsa/blob/master/easyrsa3/vars.example).

## Server certificates

### Initiate PKI directory:

``` bash
./easyrsa init-pki
```

Successful output:
```
Note: using Easy-RSA configuration from: ./vars

init-pki complete; you may now create a CA or requests.
Your newly created PKI dir is: /etc/openvpn/easy-rsa/pki
```

### Build CA certificates

``` bash
./easyrsa build-ca
```

You will be asked to give a password for the new CA key and "Common Name" (can be the default).

Successful output:
```
Note: using Easy-RSA configuration from: ./vars

Using SSL: openssl OpenSSL 1.1.1d  10 Sep 2019

Enter New CA Key Passphrase:
Re-Enter New CA Key Passphrase:
Generating RSA private key, 4096 bit long modulus (2 primes)
........................................................................................................................................................++++
...........................................................++++
e is 65537 (0x010001)
Can't load /etc/openvpn/easy-rsa/pki/.rnd into RNG
1995976720:error:2406F079:random number generator:RAND_load_file:Cannot open file:../crypto/rand/randfile.c:98:Filename=/etc/openvpn/easy-rsa/pki/.rnd
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Common Name (eg: your user, host, or server name) [Easy-RSA CA]:

CA creation complete and you may now import and sign cert requests.
Your new CA certificate file for publishing is at:
/etc/openvpn/easy-rsa/pki/ca.crt
```

### Generate Server Key

You need to give a name for the certificate. It can be `{HOSTNAME}-server`.
``` bash
./easyrsa gen-req {HOSTNAME}-server nopass
```

You will be asked to verify the "Common Name". Hit enter to use the one provided with the command ({HOSTNAME}-server).

Successful output:
```
[...]
Keypair and certificate request completed. Your files are:
req: /etc/openvpn/easy-rsa/pki/reqs/{HOSTNAME}-server.req
key: /etc/openvpn/easy-rsa/pki/private/{HOSTNAME}-server.key
```

### Sign & Verify the Server Key

``` bash
./easyrsa sign-req server {HOSTNAME}-server
```

You will be asked to type `yes` in order to confirm the details:
```
Type the word 'yes' to continue, or any other input to abort.
  Confirm request details: yes
```

You will also need to type the *password* for the `ca.key` file that you set before.
```
Enter pass phrase for /etc/openvpn/easy-rsa/pki/private/ca.key:
```

Successful output:
```
[...]
Write out database with 1 new entries
Data Base Updated

Certificate created at: /etc/openvpn/easy-rsa/pki/issued/{HOSTNAME}-server.crt
```

Verify the generated certificate:
``` bash
openssl verify -CAfile pki/ca.crt pki/issued/{HOSTNAME}-server.crt
```

Successful output:
```
pki/issued/{HOSTNAME}-server.crt: OK
```

### Generate DH key

*Using [https://security.stackexchange.com/a/95184](https://security.stackexchange.com/a/95184)*

*Docs: [https://www.openssl.org/docs/man1.1.1/man1/dhparam.html#OPTIONS](https://www.openssl.org/docs/man1.1.1/man1/dhparam.html#OPTIONS)*

Drastically improve speed of DH key generation by using the `-dsaparam` flag. This results in *DSA* (rather than *DH*) parameters creation which then are converted to DH format.

``` bash
nano easyrsa
```

Find the line `"$EASYRSA_OPENSSL" dhparam -out "$out_file" "$EASYRSA_KEY_SIZE" || \` and add the argument `-dsaparam` :

``` bash
"$EASYRSA_OPENSSL" dhparam -dsaparam -out "$out_file" "$EASYRSA_KEY_SIZE" || \
```

Save and close the file.

Generate the DH key:
``` bash
./easyrsa gen-dh
```

Successful output:
```
DH parameters of size 4096 created at /etc/openvpn/easy-rsa/pki/dh.pem
```

### Generate *tls-auth* key

To strengthen the VPN server and avoid DoS attacks & SSL/TLS handshake initiations from unauthorised machines, you can create a shared-secret key that is used in addition to the standard RSA certificate/key.

*Article: https://openvpn.net/community-resources/hardening-openvpn-security/*

``` bash
openvpn --genkey --secret pki/ta.key
```

<br>

Copy the *certificate files* into the `/etc/openvpn/server/` directory:
``` bash
cp pki/ta.key /etc/openvpn/server/
cp pki/ca.crt /etc/openvpn/server/
cp pki/dh.pem /etc/openvpn/server/

cp pki/issued/{HOSTNAME}-server.crt /etc/openvpn/server/

cp pki/private/{HOSTNAME}-server.key /etc/openvpn/server/
```

## Client(s) certificates

### Generate keypair and certificate

Replace `{Client-Name}` with the client's name, e.g: `MyMobile`:

``` bash
./easyrsa gen-req {CLIENT-NAME}
```

*You will be asked to provide a password for this keypair. This password will be needed **every time** this client connects on the server!*

Successful output:
```
[...]
Keypair and certificate request completed. Your files are:
req: /etc/openvpn/easy-rsa/pki/reqs/{CLIENT-NAME}.req
key: /etc/openvpn/easy-rsa/pki/private/{CLIENT-NAME}.key
```

### Sign client certificate

Replace `{CLIENT-NAME}` with the name you provided in the previous step:
``` bash
./easyrsa sign-req client {CLIENT-NAME}
```

You will be asked to type `yes` in order to confirm the details:
```
Type the word 'yes' to continue, or any other input to abort.
  Confirm request details: yes
```

You will also need to type the *password* for the `ca.key` file that you set before.
```
Enter pass phrase for /etc/openvpn/easy-rsa/pki/private/ca.key:
```

Successful output:
```
Write out database with 1 new entries
Data Base Updated

Certificate created at: /etc/openvpn/easy-rsa/pki/issued/{CLIENT-NAME}.crt
```

<br>

*You can repeat the two above steps in order to **create more** certificates for other clients.*

<br>

Copy the *certificate files* into the `/etc/openvpn/client/` directory:
``` bash
cp pki/ta.key /etc/openvpn/client/
cp pki/ca.crt /etc/openvpn/client/

cp pki/issued/{CLIENT-NAME}.crt /etc/openvpn/client/

cp pki/private/{CLIENT-NAME}.key /etc/openvpn/client/
```

### Generate configuration files (ovpn)

*More info on client's .ovpn file: https://github.com/OpenVPN/openvpn/blob/master/sample/sample-config-files/client.conf*

<br>

**You will need to create one *configuration file (.ovpn)* for every client you created in the previous steps.**

In order to automate the procedure, you can use the script [MakeOVPN.sh](https://github.com/smyrnakis/raspberry-born/blob/main/src/vpn/archive/MakeOVPN.sh) .

Create a file named `MakeOVPN.sh` in `/etc/openvpn/client`, make it executable and paste the contents of the script available [HERE](https://raw.githubusercontent.com/smyrnakis/raspberry-born/main/src/vpn/archive/MakeOVPN.sh) .

``` bash
cd /etc/openvpn/client

touch MakeOVPN.sh
chmod 700 MakeOVPN.sh

nano MakeOVPN.sh
```

Next, you need a file named `OVPN-defaults`. Create it and paste the contents from [HERE](https://raw.githubusercontent.com/smyrnakis/raspberry-born/main/src/vpn/archive/OVPN-defaults) .


``` bash
touch OVPN-defaults
chmod 700 OVPN-defaults

nano OVPN-defaults
```

You need to replace the `{YOUR-EXTERNAL-IP}` in the above file with the ***public IP*** of your network.

If you don't have a fixed public IP, you can use the guide ["Dynamic DNS (ddclient & noip DUC)"](https://github.com/smyrnakis/raspberry-born/blob/main/chapters/dynamic-dns.md) .

<br>

Execute the `MakeOVPN.sh` for every client's *.ovpn* profile. The script will ask you to provide the profile's name.

``` bash
./MakeOVPN.sh
```

Successful output for `client1` :
```
Please enter an existing Client Name:
client1
Client’s cert found: client1
Client’s Private Key found: client1.key
CA public Key found: ca.crt
tls-auth Private Key found: ta.key
Done! client1.ovpn Successfully Created.
```

## Generate *server* configuration

*More info on client's .ovpn file: https://github.com/OpenVPN/openvpn/blob/master/sample/sample-config-files/server.conf*

<br>

Create the `server.conf` file in `/etc/openvpn/` and paste the contents from [HERE](https://raw.githubusercontent.com/smyrnakis/raspberry-born/main/src/vpn/server.conf) .

``` bash
cd /etc/openvpn
touch server.conf

nano server.conf
```

You need to replace the `{HOSTNAME}-server` in the above file with the *server name* you gave when creating the certificates some steps above.
```
cert /etc/openvpn/server/{HOSTNAME}-server.crt
key /etc/openvpn/server/{HOSTNAME}-server.key
```

You need to replace `XXX.XXX.XXX.XXX` in line `push "route XXX.XXX.XXX.XXX 255.255.255.0"` to match the Raspberry's local IP address.

You need to replace `YYY.YYY.YYY.YYY` in line `push "dhcp-option DNS YYY.YYY.YYY.YYY"` to match your *router's* address **or** the Raspberry Pi's local IP address (if you have configured **Pi-hole** on the sane device).

## Configure routing (ufw)

If you are using [***ufw***](https://github.com/smyrnakis/raspberry-born/blob/main/chapters/ufw.md), change the *default forward policy* by editing the `/etc/default/ufw` file:
``` bash
DEFAULT_FORWARD_POLICY="ACCEPT"
```

Then configure `before.rules`, in the file `/etc/ufw/before.rules` and add the following at the end of the file, **before** the `COMMIT` line:
```
*nat
:POSTROUTING ACCEPT [0:0]
-A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
```

Allow OpenVPN through ufw:
``` bash
ufw allow openvpn comment 'openvpn'
```

Allow IPv4 forwarding by editing the `/etc/sysctl.conf` file:
``` bash
net.ipv4.ip_forward=1
```

Apply the change using the command:
``` bash
sysctl -p
```

Add POSTROUTING rule in `iptables` :
``` bash
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
```

<br>

*At this point, you can exit the `sudo su` mode by typing `exit`.*

<br>

## Start/Stop/Restart OpenVPN service
``` bash
sudo systemctl start openvpn@server

# enable service to start at reboot
sudo systemctl enable openvpn@server
```

To restart the service use:
``` bash
sudo systemctl restart openvpn

# OR

sudo service openvpn restart
```

## Status check & LOG files

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

<br>

### Files' security

chmod 700 -r /etc/openvpn/client
chmod 700 -r /etc/openvpn/server

<br>

### Restrictive networks

`UDP` help avoid [TCP meltdown](https://openvpn.net/faq/what-is-tcp-meltdown/) issue but might be restricted on some public networks, like cafè WiFi.

You can create a **second** *server.conf* and configure the protocol to be `tcp`. It also needs a different listening port and the home router needs to be configured accordingly. It's recommended to use port `443` (HTTPS protocol's port) that should not be blocked on any public WiFi.

In that way, you will be able to connect to the OpenVPN server even from restricted WiFi networks.
```
proto tcp
remote {YOUR-EXTERNAL-IP} 443
socket-flags TCP_NODELAY          #reduce latency
```

<br>
