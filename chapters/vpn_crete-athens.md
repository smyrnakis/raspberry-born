# Site‑to‑Site (Athens ⇄ Crete) over OpenVPN

This document captures the configuration and checks in order to connect two Raspberry Pis with OpenVPN so that:
- Crete (LAN 192.168.1.0/24) runs an OpenVPN client and always connects to Athens.
- Athens runs the OpenVPN server on VPN subnet 10.8.0.0/24.
- Crete’s VPN IP is statically pinned to 10.8.0.20.
- From Athens, you can reach Crete’s IP camera 192.168.1.150 (and the Crete Pi itself via 10.8.0.20).
- Crete remains reachable on its local LAN (no default‑route hijacking when the VPN comes up).
- The tunnel auto‑starts and auto‑recovers.

<br>

Conventions:
- Athens = OpenVPN server (LAN 192.168.178.0/24)
- Crete = OpenVPN client (LAN 192.168.1.0/24)
- Crete Pi LAN IP: 192.168.1.154 (example from logs)
- IP camera in Crete: 192.168.1.150
- OpenVPN server subnet: 10.8.0.0/24
- Crete’s static VPN IP: 10.8.0.20
- Client CN for Crete: 401-Raspi3-02

<br>

## 1. Athens — OpenVPN server configuration

Edit the `server.conf`:
``` bash
sudo vim /etc/openvpn/server/server.conf
```

and make sure that you have the following:
``` conf
local 192.168.178.41
port 1194
proto udp
dev tun

ca ca.crt
cert server.crt
key server.key
dh dh.pem

auth SHA512
tls-version-min 1.2
tls-crypt tc.key
topology subnet

# OpenVPN server VPN subnet
server 10.8.0.0 255.255.255.0

# Client-config-dir for static IPs & iroutes
client-config-dir /etc/openvpn/ccd

# DO NOT push full-tunnel. Keep Crete's local LAN accessible.
# push "redirect-gateway def1 bypass-dhcp"   <-- leave this commented

# Let other VPN clients learn Crete's LAN route
push "route 192.168.1.0 255.255.255.0"

# Server's own route to Crete's LAN via Crete's VPN IP
route 192.168.1.0 255.255.255.0 10.8.0.20

push "dhcp-option DNS 10.8.0.1"
push "dhcp-option DNS 9.9.9.9"
#push "dhcp-option DNS 1.1.1.1"

keepalive 10 120
cipher AES-256-CBC
user nobody
group nogroup
persist-key
persist-tun
verb 3
mute 10
status /var/log/openvpn-status.log 20
log-append /var/log/openvpn.log
crl-verify crl.pem
explicit-exit-notify
```

<br>

Then, create the **CCD** entry for Crete:
``` bash
sudo mkdir -p /etc/openvpn/ccd
sudo vim /etc/openvpn/ccd/401-Raspi3-02
```

Add the following:
``` conf
# Static VPN IP for the Crete client:
ifconfig-push 10.8.0.20 255.255.255.0

# Tell OpenVPN that this client owns the Crete LAN:
iroute 192.168.1.0 255.255.255.0
```

Restart the OpenVPN **server** in Athens:
``` bash
sudo systemctl restart openvpn-server@server
```

<br>

### Test Configuration

On **Athens**, run:
``` bash
sudo grep -E 'ROUTING_TABLE|401-Raspi3-02|192\.168\.1\.0' /var/log/openvpn-status.log
```

You should see entries like the following:
``` bash
CLIENT_LIST,401-Raspi3-02,...,10.8.0.20,...
HEADER,ROUTING_TABLE,Virtual Address,Common Name,Real Address,Last Ref,Last Ref (time_t)
ROUTING_TABLE,192.168.1.0/24,401-Raspi3-02,91.140.x.x:xxxxx,YYYY-MM-DD HH:MM:SS,##########
ROUTING_TABLE,10.8.0.20,401-Raspi3-02,91.140.x.x:xxxxx,YYYY-MM-DD HH:MM:SS,##########
```

Then, run the following:
``` bash
ip route | grep 192.168.1.0
```

and check for the following output:
``` bash
192.168.1.0/24 via 10.8.0.20 dev tun0
```

<br>

## 2. Crete — OpenVPN client configuration

Install the OpenVPN client on Crete:
``` bash
sudo apt-get install openvpn
```

``` bash
sudo mkdir -p /etc/openvpn/client
```

We assume that there is an `.ovpn` profile created on Athens OpenVPN server, named `401-Raspi3-02.ovpn`. Bring this file on the **Crete** Raspberry Pi and save it in `/etc/openvpn/client`.

``` bash
sudo cp /etc/openvpn/client/401-Raspi3-02.ovpn /etc/openvpn/client/crete.conf
```

Edit the file:
``` bash
sudo vim /etc/openvpn/client/crete.conf
```

It should contain the following:
``` conf
client
dev tun
proto udp
remote {IP_ADDRESS_ATHENS} {PORT_ATHENS}
resolv-retry infinite
nobind

persist-key
persist-tun

# Keep local LAN access; do NOT accept redirect-gateway
route-nopull
route 10.8.0.0 255.255.255.0

# Robust reconnect
keepalive 10 60

tls-version-min 1.2
remote-cert-tls server
auth SHA512
cipher AES-256-CBC

verb 3
```

Start, enable and test the client connection:
``` bash
sudo systemctl restart openvpn-client@crete
```

``` bash
sudo systemctl enable openvpn-client@crete
```

``` bash
sudo systemctl status openvpn-client@crete
```

<br>

### Test Configuration

On **Crete**, run:
``` bash
ip a | grep -A2 tun
```

and check for output like:
``` bash
tun0: <...UP,LOWER_UP>
inet 10.8.0.20/24 scope global tun0
```

<br>

## 3. Crete — IP forwarding & firewall (iptables)

Enable IPv4 forwarding (runtime + persistent):
``` bash
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
```

<br>

We’ll allow Athens VPN clients (`10.8.0.0/24`) to reach only the IP camera in Crete (`192.168.1.150`) and NAT those packets so the camera replies properly.
> If you also want to reach other devices in `192.168.1.0/24`, use the **“Broader NAT”** variant below instead.

### Minimal rules — camera‑only
> These rules assume Crete’s LAN interface is `eth0`

Allow forwarding in both directions for the camera:
``` bash
sudo iptables -A FORWARD -s 10.8.0.0/24 -d 192.168.1.150 -j ACCEPT
```
``` bash
sudo iptables -A FORWARD -s 192.168.1.150 -d 10.8.0.0/24 -j ACCEPT
```

NAT (MASQUERADE) only for the camera:
``` bash
sudo iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -d 192.168.1.150 -o eth0 -j MASQUERADE
```

Make rules persistent:
``` bash
sudo apt-get update && sudo apt-get install -y iptables-persistent
```
``` bash
sudo netfilter-persistent save
```

### Broader NAT — entire Crete LAN (optional alternative)
If you decide you want to reach any host in `192.168.1.0/24` from **Athens**:

``` bash
sudo iptables -t nat -F
sudo iptables -F FORWARD
```
``` bash
sudo iptables -A FORWARD -s 10.8.0.0/24 -d 192.168.1.0/24 -j ACCEPT
sudo iptables -A FORWARD -s 192.168.1.0/24 -d 10.8.0.0/24 -j ACCEPT
sudo iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -d 192.168.1.0/24 -o eth0 -j MASQUERADE
```
``` bash
sudo netfilter-persistent save
```

<br>

## 4. Crete — Auto‑restart safety (systemd)

Have systemd restart the client if the process ever dies:

``` bash
sudo mkdir -p /etc/systemd/system/openvpn-client@crete.service.d
```
``` bash
sudo vim /etc/systemd/system/openvpn-client@crete.service.d/override.conf
```

Add the following:
``` ini
[Service]
Restart=always
RestartSec=5
```

And apply by executing:
``` bash
sudo systemctl daemon-reload
```
``` bash
sudo systemctl restart openvpn-client@crete
```

<br>

## 5. Verification checklist

### On **Crete**

VPN interface and static IP:
``` bash
ip a | grep -A2 tun
```
Expect: `inet 10.8.0.20/24 on tun0`

Forwarding enabled:
``` bash
cat /proc/sys/net/ipv4/ip_forward
```
Expect: `1`

NAT/forward rules present:
``` bash
sudo iptables -t nat -L -n -v | grep -E '192\.168\.1\.150|192\.168\.1\.0/24'
```
``` bash
sudo iptables -L FORWARD -n -v | grep -E '10\.8\.0\.0/24|192\.168\.1\.150|192\.168\.1\.0/24'
```

<br>

### On **Athens**

Client present and iroute active:
``` bash
sudo grep -E 'ROUTING_TABLE|401-Raspi3-02|192\.168\.1\.0' /var/log/openvpn-status.log
```
Expect both `ROUTING_TABLE` lines for `192.168.1.0/24` and `10.8.0.20`

Kernel route to Crete LAN via Crete VPN IP:
``` bash
ip route | grep 192.168.1.0
```
Expect: `192.168.1.0/24 via 10.8.0.20 dev tun0`

Reachability:
``` bash
ping -I tun0 10.8.0.20
```
Expect replies in the ping.

``` bash
ping -I tun0 192.168.1.150
```
Expect replies _(some cameras block ICMP; if no reply, try HTTP/RTSP to confirm)_

If ICMP is blocked by the camera, test the camera service instead.
Example HTTP test:
``` bash
curl -I http://192.168.1.150/
```

Example RTSP test _(depends on camera model/URL)_:
``` bash
ffprobe "rtsp://192.168.1.150:554/stream"
```

<br>
<br>

## Various

SSH to **Crete** from **Athens**:
```bash
ssh -i ".ssh/prvT" {USERNAME}@10.8.0.20
```

Relevant ChatGPT thread & troubleshooting: https://chatgpt.com/g/g-p-676072cbef608191937875a9dfdfe4e3-raspberry-pi/c/6774836c-ad98-8005-af27-d64782872829

