# Install and configure an OpenVPN server

This guide prepares a new OpenVPN server on Raspberry Pi OS based on Debian 12 or 13 with OpenVPN 2.6 or later. It does not migrate an existing server.

The example uses:

- UDP `1194` on the Raspberry Pi
- UDP `11194` on the Internet router, forwarded to UDP `1194`
- VPN network `10.8.0.0/24`
- full-tunnel routing
- Pi-hole on the same Raspberry Pi at `10.8.0.1`

Do not commit a real public IP address, DDNS name, private key or generated `.ovpn` profile.

This procedure tunnels IPv4. A client with working public IPv6 may bypass the IPv4 tunnel; disable IPv6 on that client or add a separately tested IPv6 VPN design when IPv6 full-tunnel coverage is required.

## 1. Get the repository

Run on the Raspberry Pi as the normal login user:

```bash
mkdir -p ~/Software
cd ~/Software
git clone https://github.com/smyrnakis/raspberry-born.git
cd raspberry-born
```

If the repository is already present:

```bash
cd ~/Software/raspberry-born
git status --short
git pull --ff-only
```

Do not pull over local changes. Resolve them first.

## 2. Confirm that this is a fresh installation

These commands only inspect the Raspberry Pi:

```bash
cat /etc/os-release
ip -brief address
ip route
sudo ss -lntup
dpkg-query -W openvpn easy-rsa nftables 2>/dev/null || true
systemctl list-unit-files 'openvpn*' --no-pager
sudo find /etc/openvpn -maxdepth 3 -type f -print 2>/dev/null
sysctl net.ipv4.ip_forward
sudo nft list ruleset 2>/dev/null || true
```

Use the results as follows:

| Command | Expected result on a suitable fresh installation |
| --- | --- |
| `cat /etc/os-release` | Raspberry Pi OS or Debian, with `VERSION_CODENAME=bookworm` or `trixie`. Stop if the release differs until compatibility is checked. |
| `ip -brief address` | The LAN interface is `UP` and has the expected private address. There is normally no `tun0` yet. |
| `ip route` | A `default via ... dev ...` route identifies the Internet-facing interface. A connected route identifies the LAN subnet. Record both. |
| `sudo ss -lntup` | Existing listening services are shown. UDP `1194` must be unused. Investigate anything unexpectedly exposed on `0.0.0.0` or `[::]`. |
| `dpkg-query ...` | Installed package versions are printed. Missing packages produce no visible line because errors are suppressed. |
| `systemctl list-unit-files 'openvpn*'` | No active custom OpenVPN instance should exist. Unit templates may appear if the package is already installed. |
| `sudo find /etc/openvpn ...` | No output is expected. Any configuration, certificate or key means this is not a fresh installation. |
| `sysctl net.ipv4.ip_forward` | `net.ipv4.ip_forward = 0` is the normal starting value. If it is already `1`, identify which service requires forwarding before continuing. |
| `sudo nft list ruleset` | An empty or known minimal ruleset is expected. Stop if UFW, firewalld, Docker or another administrator already owns firewall rules until the new rules are integrated with that owner. |

Stop here if `/etc/openvpn` already contains a configuration, certificate authority, certificate or private key. Back up and assess that installation separately.

Record these two values from the output:

- the LAN network, for example `192.168.1.0/24`
- the Internet-facing interface from the default route, for example `eth0`

The interface is needed for the firewall configuration later in this guide.

## 3. Install the required packages

This does not perform a full system upgrade:

```bash
sudo apt update
sudo apt install openvpn easy-rsa nftables
```

Verify the installed versions:

```bash
openvpn --version | head -n 2
dpkg-query -W -f='${Package}\t${Version}\n' openvpn easy-rsa nftables
```

The OpenVPN output must report version 2.6 or later for this configuration.

## 4. Create the certificate authority

Create a root-only Easy-RSA working directory:

```bash
sudo install -d -o root -g root -m 700 /etc/openvpn/server/easy-rsa
sudo cp -a /usr/share/easy-rsa/. /etc/openvpn/server/easy-rsa/
sudo chown -R root:root /etc/openvpn/server/easy-rsa
cd /etc/openvpn/server/easy-rsa
```

Create the Easy-RSA settings:

```bash
sudo cp vars.example vars
sudo vim vars
```

Add these lines at the end:

```text
set_var EASYRSA_ALGO           rsa
set_var EASYRSA_KEY_SIZE       3072
set_var EASYRSA_DIGEST         sha256
set_var EASYRSA_CA_EXPIRE      5475
set_var EASYRSA_CERT_EXPIRE    1825
```

These values select widely supported RSA keys, a 3072-bit key size, SHA-256 signatures, a 15-year CA and 5-year server/client certificates. The longer-lived CA avoids rebuilding every client profile during the first ten years; the shorter device certificates are easier to rotate if a key has aged or a device is replaced.

Initialize the PKI and create the CA:

```bash
sudo ./easyrsa init-pki
sudo ./easyrsa --req-cn=raspberry-born-ca build-ca
```

Enter a strong CA passphrase and store it in an encrypted password manager. The CA private key remains on this Raspberry Pi under `/etc/openvpn/server/easy-rsa/pki/private/ca.key`; include it only in an encrypted offline backup.

The CA is valid for 15 years. Server and client certificates are valid for 5 years and are renewed without replacing the CA. This gives the installation a service life beyond ten years while still rotating device certificates. Section 13 installs expiry reminders.

## 5. Create the server credentials

The server key is deliberately created without a passphrase so OpenVPN can start unattended. It remains readable only by `root`.

```bash
sudo ./easyrsa build-server-full server nopass
sudo ./easyrsa gen-crl
sudo openvpn --genkey tls-crypt /etc/openvpn/server/tls-crypt.key
```

Easy-RSA asks for the CA passphrase when signing the server certificate and CRL.

Install the files used by the OpenVPN service:

```bash
sudo install -o root -g root -m 644 pki/ca.crt /etc/openvpn/server/ca.crt
sudo install -o root -g root -m 644 pki/issued/server.crt /etc/openvpn/server/server.crt
sudo install -o root -g root -m 600 pki/private/server.key /etc/openvpn/server/server.key
sudo install -o root -g root -m 644 pki/crl.pem /etc/openvpn/server/crl.pem
sudo chown root:root /etc/openvpn/server/tls-crypt.key
sudo chmod 600 /etc/openvpn/server/tls-crypt.key
```

## 6. Install the server configuration

Return to the repository and install the maintained template:

```bash
cd ~/Software/raspberry-born
sudo install -o root -g root -m 600 \
  src/vpn/server/server.conf.template \
  /etc/openvpn/server/server.conf
sudo vim /etc/openvpn/server/server.conf
```

Replace both LAN placeholders with the Raspberry Pi LAN network and netmask. For `192.168.1.0/24`, use:

```text
push "route 192.168.1.0 255.255.255.0"
```

### Pi-hole DNS filtering

Choose one DNS configuration in `/etc/openvpn/server/server.conf`:

- If Pi-hole runs on this Raspberry Pi, keep `push "dhcp-option DNS 10.8.0.1"`. Do not add a public fallback if all ordinary client DNS must be filtered.
- If Pi-hole runs on another LAN host, replace `10.8.0.1` with that host's private LAN address.
- If Pi-hole is not installed, replace the Pi-hole line with a public resolver pair. For Cloudflare:

```text
push "dhcp-option DNS 1.1.1.1"
push "dhcp-option DNS 1.0.0.1"
```

The second public resolver provides redundancy. VPN clients may use either resolver, so do not combine Pi-hole with a public resolver when filtering is required. See [Pi-hole advertisement blocker](pihole.md#5-openvpn-clients) for the Pi-hole-side setting.

If Pi-hole is installed later, update the OpenVPN server configuration at that time. Profiles do not need to be regenerated because DNS settings are pushed by the server:

```bash
sudo vim /etc/openvpn/server/server.conf
```

Remove every public DNS line and add the appropriate Pi-hole address. For Pi-hole on the OpenVPN server:

```text
push "dhcp-option DNS 10.8.0.1"
```

Confirm that Pi-hole is the only pushed resolver, then restart OpenVPN:

```bash
sudo grep -n 'push "dhcp-option DNS' /etc/openvpn/server/server.conf
sudo systemctl restart openvpn-server@server.service
sudo systemctl is-active openvpn-server@server.service
```

Expected results: the grep output contains only the intended Pi-hole address and the service returns `active`. Reconnect each VPN client so it receives the changed DNS setting, then verify a lookup in Pi-hole's query log.

Check that no placeholders remain:

```bash
sudo grep -n 'REPLACE_' /etc/openvpn/server/server.conf
```

Expected result: no output. Any output identifies a value that still needs editing.

Create the state directory referenced by the configuration:

```bash
sudo install -d -o root -g root -m 700 /var/lib/openvpn/server
```

## 7. Validate before activation

Verify the certificate chain and server private key:

```bash
sudo openssl verify \
  -CAfile /etc/openvpn/server/ca.crt \
  /etc/openvpn/server/server.crt
sudo openssl pkey \
  -in /etc/openvpn/server/server.key \
  -check -noout
sudo test -s /etc/openvpn/server/tls-crypt.key && echo "tls-crypt key: present"
```

Expected results:

- certificate verification ends with `server.crt: OK`
- private-key verification reports that the key is valid
- the final command prints `tls-crypt key: present`

Confirm file ownership and permissions:

```bash
sudo stat -c '%U:%G %a %n' \
  /etc/openvpn/server/easy-rsa/pki/private/ca.key \
  /etc/openvpn/server/server.key \
  /etc/openvpn/server/tls-crypt.key \
  /etc/openvpn/server/server.conf
```

Each listed file should be owned by `root:root` and should not be readable by other users. The expected mode is `600`.

Confirm that OpenVPN has not been activated and that internal UDP port `1194` is free:

```bash
sudo systemctl is-enabled openvpn-server@server.service || true
sudo systemctl is-active openvpn-server@server.service || true
sudo ss -lunp '( sport = :1194 )'
```

Expected results at this stage:

- the service is `disabled`
- the service is `inactive`
- the socket command displays only its heading and no process bound to UDP `1194`

## 8. Enable forwarding and install nftables rules

Keep the current SSH session open and have a second login or local console available while changing firewall state.

Back up the files that will be changed:

```bash
vpn_backup_dir="/var/backups/raspberry-born/openvpn-$(date +%Y%m%d-%H%M%S)"
sudo install -d -o root -g root -m 700 "$vpn_backup_dir"
sudo cp -a /etc/nftables.conf "$vpn_backup_dir/nftables.conf"
sudo test ! -e /etc/sysctl.d/90-openvpn-server.conf || \
  sudo cp -a /etc/sysctl.d/90-openvpn-server.conf "$vpn_backup_dir/"
echo "Backup: $vpn_backup_dir"
```

Install IPv4 forwarding and the dedicated OpenVPN nftables file:

```bash
cd ~/Software/raspberry-born
sudo install -o root -g root -m 644 \
  src/vpn/server/90-openvpn-server.conf \
  /etc/sysctl.d/90-openvpn-server.conf
sudo install -d -o root -g root -m 755 /etc/nftables.d
sudo install -o root -g root -m 600 \
  src/vpn/server/vpn-server.nft.template \
  /etc/nftables.d/vpn-server.nft
sudo vim /etc/nftables.d/vpn-server.nft
```

Replace `REPLACE_UPLINK_INTERFACE` with the interface recorded in section 2, such as `eth0`.

Ensure `/etc/nftables.conf` contains this line after any `flush ruleset` directive:

```bash
sudo vim /etc/nftables.conf
```

```text
include "/etc/nftables.d/*.nft"
```

Validate without changing the live ruleset:

```bash
sudo grep -n 'REPLACE_' /etc/nftables.d/vpn-server.nft
sudo nft -c -f /etc/nftables.conf
```

Expected results: the first command prints nothing and the nftables check returns without an error.

The dedicated table forwards and masquerades `10.8.0.0/24` but does not replace a separate host-input firewall. On the fresh installation expected by this guide, the router exposes only the forwarded OpenVPN port. If section 2 found an input chain with a drop policy, add UDP `1194` and, when Pi-hole is used, TCP/UDP `53` from `10.8.0.0/24` to that existing firewall instead of creating a second firewall owner.

Apply the reviewed settings:

```bash
sudo sysctl --system
sudo systemctl enable nftables
sudo systemctl restart nftables
```

Verify them:

```bash
sysctl net.ipv4.ip_forward
systemctl is-enabled nftables
systemctl is-active nftables
sudo nft list table inet raspberry_born_openvpn
sudo nft list table ip raspberry_born_openvpn_nat
```

Expected results: forwarding is `1`, nftables is `enabled` and `active`, and both OpenVPN tables are displayed.

## 9. Configure the Internet router

Give the Raspberry Pi a stable LAN address, preferably with a DHCP reservation. On the Internet router, create this port forward:

```text
Protocol:       UDP
External port:  11194
Destination:    Raspberry Pi LAN address
Internal port:  1194
```

Do not expose SSH, Pi-hole DNS port `53`, or the Pi-hole web interface to the Internet. If the public address changes, configure [Dynamic DNS](dynamic-dns.md) and use that name only in local client profiles.

## 10. Start the OpenVPN server

Check the systemd unit, then start the exact server instance:

```bash
sudo systemd-analyze verify openvpn-server@server.service
sudo systemctl start openvpn-server@server.service
sudo systemctl status openvpn-server@server.service --no-pager
```

If the service is `active (running)`, enable it at boot:

```bash
sudo systemctl enable openvpn-server@server.service
```

Verify the listener and tunnel:

```bash
systemctl is-enabled openvpn-server@server.service
systemctl is-active openvpn-server@server.service
ip -brief address show tun0
sudo ss -lunp '( sport = :1194 )'
sudo journalctl -u openvpn-server@server.service --no-pager -n 50
```

Expected results:

- the service is `enabled` and `active`;
- `tun0` is `UP` with `10.8.0.1/24`;
- OpenVPN listens on UDP `1194`;
- the journal contains no fatal configuration, certificate or permission error.

## 11. Create a client profile

Install the maintained client command:

```bash
cd ~/Software/raspberry-born
sudo install -o root -g root -m 755 \
  src/vpn/server/manage-client.sh \
  /usr/local/sbin/manage-openvpn-client
sudo install -d -o root -g root -m 755 /usr/local/share/raspberry-born
git rev-parse HEAD | sudo tee \
  /usr/local/share/raspberry-born/manage-openvpn-client.commit >/dev/null
sha256sum \
  src/vpn/server/manage-client.sh \
  /usr/local/sbin/manage-openvpn-client
```

The two SHA-256 values must match. Installation is normally done once. Three years later, the installed command can still create a client without copying it again:

```bash
sudo manage-openvpn-client create another-phone
```

The installed copy does not change when the repository changes, which protects a working server from an unreviewed update.

### Update the installed client command

“Latest” and “known working” are not automatically the same. Do not make this operational command pull or update itself. Before a maintenance session where the latest reviewed version is wanted, inspect what changed:

```bash
cd ~/Software/raspberry-born
git status --short
git fetch origin
git log --oneline HEAD..origin/main
git diff HEAD..origin/main -- \
  src/vpn/server/manage-client.sh \
  chapters/vpn.md
```

Do not continue with local changes or an unexpected diff. After reviewing the changes, update and validate the script:

```bash
git pull --ff-only
bash -n src/vpn/server/manage-client.sh
sudo install -b --suffix=.previous -o root -g root -m 755 \
  src/vpn/server/manage-client.sh \
  /usr/local/sbin/manage-openvpn-client
sudo manage-openvpn-client list
```

If `list` succeeds, record the new source commit:

```bash
git rev-parse HEAD | sudo tee \
  /usr/local/share/raspberry-born/manage-openvpn-client.commit >/dev/null
```

`list` is read-only. If it fails, restore the previous installed copy:

```bash
sudo install -o root -g root -m 755 \
  /usr/local/sbin/manage-openvpn-client.previous \
  /usr/local/sbin/manage-openvpn-client
```

Show the installed source commit at any time with:

```bash
cat /usr/local/share/raspberry-born/manage-openvpn-client.commit
```

Create one certificate per phone, laptop or Raspberry Pi. For an interactive device:

```bash
sudo manage-openvpn-client create my-phone
```

Enter the public IP address or DDNS name when prompted, then set a strong client-key password and enter the CA passphrase. The resulting profile is `/root/openvpn-client-exports/my-phone.ovpn`, mode `600`.

The profile uses only certificates; it does not require a separate OpenVPN username and password. In OpenVPN Connect, import the profile and allow the app to save the private-key password in the device keychain. A strong screen lock protects that saved credential.

### Unattended Raspberry Pi client

Create an unencrypted device-specific key:

```bash
sudo manage-openvpn-client create-unattended remote-pi
```

Use this only when the imported profile will be owned by `root`, mode `600`, and can be revoked promptly if the device is lost.

Transfer a profile through verified SSH, SFTP or WinSCP. One method is to place a temporary copy in the login user's home directory:

```bash
sudo install -o "$USER" -g "$(id -gn)" -m 600 \
  /root/openvpn-client-exports/my-phone.ovpn \
  "$HOME/my-phone.ovpn"
```

This copies the root-only profile into the current login user's home directory so that the user can download it over SSH:

- `-o "$USER"` makes the current login user the owner;
- `-g "$(id -gn)"` assigns that user's primary group;
- `-m 600` allows only that user to read or modify the copy;
- the source under `/root` remains unchanged.

The shell resolves `$USER`, `$(id -gn)` and `$HOME` before `sudo` runs. The destination is only a temporary transfer copy and is deleted after import.

On the Windows laptop, run in PowerShell and keep SSH host-key verification enabled:

```powershell
scp {USERNAME}@{RASPBERRY-PI-LAN-IP}:~/my-phone.ovpn "$env:USERPROFILE\Downloads\my-phone.ovpn"
```

After importing the profile and storing an encrypted backup, remove both temporary transfer copies:

```bash
rm "$HOME/my-phone.ovpn"
sudo rm /root/openvpn-client-exports/my-phone.ovpn
```

Never email a profile or commit it. An inline `.ovpn` profile contains the client private key and `tls-crypt` key.

## 12. Test from outside the home network

Disconnect the test device from the home Wi-Fi and use mobile data or another Internet connection. Connect with OpenVPN Connect, then verify:

1. The profile connects without a certificate error.
2. The device's public IP is the home connection's public IP because this is a full tunnel.
3. A private LAN service is reachable.
4. DNS works.
5. If Pi-hole is configured, the test lookup appears in Pi-hole's query log.

Cloudflare's diagnostic page can confirm the public IPv4 address: open `https://1.1.1.1/cdn-cgi/trace` and check the `ip=` line.

On the Raspberry Pi, inspect the connection and firewall counters:

```bash
sudo cat /run/openvpn-server/status-server.log
sudo journalctl -u openvpn-server@server.service --since '-10 minutes' --no-pager
sudo nft list table inet raspberry_born_openvpn
sudo nft list table ip raspberry_born_openvpn_nat
```

The status file should list the client certificate name. Forwarding and NAT counters should increase while the client uses the tunnel. The status file can contain a client's public source address, so do not publish it.

If Pi-hole is not installed, confirm that the client received the selected public resolvers. If Pi-hole is installed, confirm that it received only the Pi-hole address. Android Private DNS, browser DNS-over-HTTPS and application-specific encrypted DNS can bypass the resolver pushed by OpenVPN.

## 13. Install certificate-expiry reminders

> [!WARNING]
> Install and test the durable notification queue from [email.md](email.md) first. Without it, expiry warnings are written only to the journal and are not emailed.

Install the checker and daily timer:

```bash
cd ~/Software/raspberry-born
sudo install -o root -g root -m 755 \
  src/vpn/server/raspi-vpn-cert-check \
  /usr/local/sbin/raspi-vpn-cert-check
sudo install -o root -g root -m 644 \
  src/vpn/server/raspi-vpn-cert-check.service \
  /etc/systemd/system/raspi-vpn-cert-check.service
sudo install -o root -g root -m 644 \
  src/vpn/server/raspi-vpn-cert-check.timer \
  /etc/systemd/system/raspi-vpn-cert-check.timer
sudo systemctl daemon-reload
sudo /usr/local/sbin/raspi-vpn-cert-check --report
sudo systemctl enable --now raspi-vpn-cert-check.timer
```

The report shows the remaining days for the CA, server and client certificates. The timer warns at 90, 60, 30, 14, 7 and 1 days for server/client certificates. CA warnings begin at 180 days.

Verify the schedule and latest run:

```bash
systemctl list-timers raspi-vpn-cert-check.timer --no-pager
sudo systemctl start raspi-vpn-cert-check.service
sudo journalctl -u raspi-vpn-cert-check.service --no-pager -n 30
```

A healthy check produces no email. `--report` always prints the certificate inventory.

### Renew a server certificate

Back up the PKI first. Easy-RSA 3.1 and 3.2 handle renewal internals differently, so copy both the renewed certificate and key afterward:

```bash
cd /etc/openvpn/server/easy-rsa
vpn_pki_backup="/root/openvpn-pki-$(date +%Y%m%d-%H%M%S)"
sudo cp -a pki "$vpn_pki_backup"
sudo ./easyrsa --nopass renew server
sudo install -o root -g root -m 644 pki/issued/server.crt /etc/openvpn/server/server.crt
sudo install -o root -g root -m 600 pki/private/server.key /etc/openvpn/server/server.key
sudo openssl verify -CAfile pki/ca.crt pki/issued/server.crt
sudo systemctl restart openvpn-server@server.service
sudo systemctl is-active openvpn-server@server.service
```

After the renewed certificate works, revoke the superseded certificate and refresh the CRL:

```bash
sudo ./easyrsa revoke-renewed server superseded
sudo ./easyrsa gen-crl
sudo install -o root -g root -m 644 pki/crl.pem /etc/openvpn/server/crl.pem
```

Renewing a client certificate also requires exporting and importing a replacement profile:

```bash
cd /etc/openvpn/server/easy-rsa
sudo ./easyrsa renew my-phone
sudo manage-openvpn-client export my-phone
```

Transfer and import the replacement profile as in section 11. Revoke the superseded client certificate after the replacement connects successfully.

```bash
cd /etc/openvpn/server/easy-rsa
sudo ./easyrsa revoke-renewed my-phone superseded
sudo ./easyrsa gen-crl
sudo install -o root -g root -m 644 pki/crl.pem /etc/openvpn/server/crl.pem
```

CA expiry is different: every server and client must receive the replacement CA. When the 180-day CA warning arrives, make an encrypted PKI backup and plan a controlled CA rollover rather than waiting for expiry.

## 14. List or revoke clients

List issued client certificates:

```bash
sudo manage-openvpn-client list
```

Revoke a lost, replaced or retired device:

```bash
sudo manage-openvpn-client revoke my-phone
```

Revocation updates the server CRL. A currently connected client may remain connected until it reconnects; restart the OpenVPN service only when immediate disconnection justifies interrupting every client.

## 15. Test reboot recovery

Perform this only after remote access, OpenVPN, nftables and an alternative recovery path have been verified:

```bash
sudo reboot
```

After the Raspberry Pi returns:

```bash
systemctl is-active nftables openvpn-server@server.service
ip -brief address show tun0
sudo ss -lunp '( sport = :1194 )'
systemctl list-timers raspi-vpn-cert-check.timer --no-pager
```

Both services should be active, `tun0` should have `10.8.0.1/24`, UDP `1194` should be listening, and the certificate timer should have a future run time. Repeat the external client test.

## 16. Roll back the service configuration

Remove the router port forward first. On the Raspberry Pi:

```bash
sudo systemctl disable --now raspi-vpn-cert-check.timer
sudo systemctl disable --now openvpn-server@server.service
sudo rm -f /etc/nftables.d/vpn-server.nft
sudo rm -f /etc/sysctl.d/90-openvpn-server.conf
sudo cp -a /var/backups/raspberry-born/{BACKUP-DIRECTORY}/nftables.conf /etc/nftables.conf
sudo sysctl --system
sudo systemctl restart nftables
```

If the forwarding sysctl file existed before installation, restore its backed-up copy instead of removing it. This rollback leaves the PKI intact. Do not delete `/etc/openvpn/server/easy-rsa` until its encrypted backup and all certificate-revocation requirements have been reviewed.

Related guides:

- [Athens-Crete site-to-site VPN](vpn_crete-athens.md)
- [OpenVPN health monitoring](vpn-watchdog.md)
- [Archived superseded OpenVPN material](../archive/openvpn/README.md)

Technical references: [OpenVPN 2.6 manual](https://openvpn.net/community-docs/community-articles/openvpn-2-6-manual.html), [Debian OpenVPN service layout](https://wiki.debian.org/OpenVPN), and [Easy-RSA documentation](https://github.com/OpenVPN/easy-rsa/tree/master/doc).
