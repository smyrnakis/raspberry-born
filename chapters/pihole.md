# Pi-hole

This guide installs Pi-hole v6 on a Raspberry Pi and makes it available to
trusted local-network and OpenVPN clients. It uses Pi-hole's normal weekly
gravity update instead of an additional blocklist updater.

## 1. Before installation

Use a supported Raspberry Pi OS or Debian release. Give the Raspberry Pi a
stable address, preferably with a DHCP reservation on the router.

Run these read-only checks on the Raspberry Pi:

```bash
cat /etc/os-release
ip -brief address
ip route
sudo ss -lntup
command -v pihole || true
systemctl list-unit-files 'pihole*' --no-pager
sudo ufw status verbose 2>/dev/null || true
sudo nft list ruleset 2>/dev/null || true
```

Expected results:

- `cat /etc/os-release` identifies a currently supported Raspberry Pi OS or
  Debian release.
- `ip -brief address` shows the LAN interface and its stable address. Use this
  interface during installation, not `tun0`.
- `ip route` shows a default route through the LAN router.
- `ss` shows whether another service already owns DNS port 53 or web ports 80
  and 443. Resolve unexpected conflicts before continuing.
- `command -v pihole` and the systemd listing reveal an existing installation.
- The final two commands show the current firewall implementation. Extend the
  existing firewall instead of installing a second firewall manager.

## 2. Download and run the installer

```bash
sudo apt update
sudo apt install wget

install -d -m 700 ~/Software/Pi-hole-installer
cd ~/Software/Pi-hole-installer
wget -O basic-install.sh https://install.pi-hole.net
sudo bash basic-install.sh
```

This uses the manual-download method documented by Pi-hole. The installer is
saved locally before it is run instead of being piped directly into Bash.

Choose an upstream resolver during installation:

| Provider | IPv4 addresses | IPv6 addresses | Advantages | Trade-offs |
| --- | --- | --- | --- | --- |
| Cloudflare | `1.1.1.1`, `1.0.0.1` | `2606:4700:4700::1111`, `2606:4700:4700::1001` | Fast, privacy-focused, no filtering in the standard service. | Operated by a large commercial network. |
| Quad9 | `9.9.9.9`, `149.112.112.112` | `2620:fe::fe`, `2620:fe::9` | Privacy-focused and blocks known malicious domains. | A false positive can be blocked upstream rather than appearing as a Pi-hole block. |
| Google | `8.8.8.8`, `8.8.4.4` | `2001:4860:4860::8888`, `2001:4860:4860::8844` | Large global network and high availability. | Keeps temporary client-IP logs and longer-lived anonymized aggregate data. |

Cloudflare is a simple neutral default. Quad9 is a good alternative when an
additional malware-filtering layer is preferred. Ordinary port 53 DNS between
Pi-hole and these resolvers is not encrypted. A separate design is needed to
use recursive Unbound instead of a public resolver, or to forward through
DNS-over-TLS or DNS-over-HTTPS.

During installation:

- Select the normal LAN interface, usually `eth0` or `wlan0`.
- Confirm the reserved LAN address and gateway.
- Select the chosen upstream resolver. This can be changed later.
- Install the web interface.
- Keep query logging enabled if you want troubleshooting and the optional LED
  activity feature later in this guide.
- Choose the privacy level appropriate for the installation.

Set or change the web-interface password interactively:

```bash
sudo pihole setpassword
```

Do not place the password on the command line or in Git.

## 3. Restrict DNS to trusted networks

Keep Pi-hole in `LOCAL` listening mode:

```bash
sudo pihole-FTL --config dns.listeningMode "LOCAL"
sudo pihole reloaddns
```

`LOCAL` accepts requests that arrive from networks directly connected to the
Raspberry Pi. This covers its LAN and, when OpenVPN runs on the same Raspberry
Pi, the directly connected VPN subnet.

Do not use `ALL` or **Permit all origins** for this setup. That mode accepts
requests regardless of their origin and can expose an open DNS resolver if the
firewall or router is misconfigured.

### Firewall

First check whether UFW is active:

```bash
sudo ufw status verbose
```

If it reports `Status: active` and `Default: deny (incoming)`, add scoped allow
rules for Pi-hole. The commands below do not block ports 80 or 443. They permit
DNS and web administration only from the listed trusted networks because the
default incoming policy blocks other sources.

These examples use LAN `192.168.1.0/24` and OpenVPN `10.8.0.0/24`. Replace the
LAN range with the actual local network:

```bash
sudo ufw allow from 192.168.1.0/24 to any port 53 proto udp comment 'Pi-hole LAN DNS'
sudo ufw allow from 192.168.1.0/24 to any port 53 proto tcp comment 'Pi-hole LAN DNS'
sudo ufw allow from 10.8.0.0/24 to any port 53 proto udp comment 'Pi-hole VPN DNS'
sudo ufw allow from 10.8.0.0/24 to any port 53 proto tcp comment 'Pi-hole VPN DNS'

sudo ufw allow from 192.168.1.0/24 to any port 80 proto tcp comment 'Pi-hole LAN web'
sudo ufw allow from 192.168.1.0/24 to any port 443 proto tcp comment 'Pi-hole LAN web'
sudo ufw allow from 10.8.0.0/24 to any port 80 proto tcp comment 'Pi-hole VPN web'
sudo ufw allow from 10.8.0.0/24 to any port 443 proto tcp comment 'Pi-hole VPN web'
```

Omit the two VPN web rules if the administration page should be reachable only
from the LAN. Do not open DHCP ports unless Pi-hole will provide DHCP.

If UFW reports `Status: inactive`, these UFW rules are not the active firewall.
Do not enable UFW during a remote session without first preserving SSH access.
If nftables or another firewall already owns the ruleset, add equivalent scoped
rules there instead. Do not operate two independent firewall managers. If no
host firewall is active, do not add router port-forwards for Pi-hole; configure
the host firewall later from a session with a tested recovery path.

Review the effective listeners and firewall after making the changes:

```bash
sudo ss -lntup | grep -E ':(53|80|443|8080|8443)\b'
sudo ufw status verbose 2>/dev/null || true
sudo nft list ruleset 2>/dev/null || true
```

Expected results:

- `ss` shows `pihole-FTL` listening on TCP and UDP port 53. It normally shows
  the Pi-hole web server on TCP 80 and 443; if those ports were already in use,
  Pi-hole may use 8080 and 8443 instead.
- `ufw status verbose` shows the scoped DNS rules and the selected web rules
  when UFW is active. Its default incoming policy should be `deny`. Confirm
  that an SSH rule still permits administration before ending the session.
- `nft list ruleset` shows the effective kernel rules, including UFW-generated
  rules when UFW is active. The trusted LAN and VPN ranges should be allowed to
  the intended ports, with no router port-forward exposing them to the WAN.

A wildcard listener such as `0.0.0.0:53` in `ss` does not by itself mean the
service is Internet-accessible. Pi-hole's `LOCAL` mode, the host firewall, and
the absence of a router port-forward form the access boundary.

## 4. Configure clients to use Pi-hole

Configure the router's DHCP service to advertise the Raspberry Pi's stable
IPv4 address as DNS. If IPv6 is enabled, configure the IPv6 DNS advertisement
as well.

Do not advertise a public resolver as a secondary DNS server. Clients may use
it directly and bypass Pi-hole. For DNS redundancy, operate a second Pi-hole.

> **Potential future update:** A Raspberry Pi Zero 2 W redundancy design is
> recorded in [Future redundant Pi-hole design](pihole-redundancy.md). It is a
> deferred proposal, not a currently implemented procedure.

After renewing a client's DHCP lease, verify from that client:

```bash
nslookup pi.hole
nslookup example.com
```

Both lookups should identify the Pi-hole as the responding DNS server. The
queries should also appear in the Pi-hole Query Log.

## 5. OpenVPN clients

For an OpenVPN server on the same Raspberry Pi, use its VPN address as the DNS
server pushed to clients. With the repository's default VPN subnet this is:

```text
push "dhcp-option DNS 10.8.0.1"
```

The maintained OpenVPN procedure includes the exact configuration and checks:
[Pi-hole DNS filtering](vpn.md#pi-hole-dns-filtering).

After reconnecting an OpenVPN client, confirm that it receives `10.8.0.1` as
DNS, resolves a normal domain, and appears in Pi-hole's Query Log.

If Pi-hole is installed after OpenVPN, add the DNS push setting and reconnect
clients. If Pi-hole is removed later, change the pushed DNS address before
clients reconnect.

## 6. Add the recorded blocklists

In the web interface, open **Lists**, add the following URLs one at a time, and
give each entry a descriptive comment:

| List | Purpose |
| --- | --- |
| `https://osint.digitalside.it/Threat-Intel/lists/latestdomains.txt` | Recently observed threat domains. |
| `https://v.firebog.net/hosts/Prigent-Crypto.txt` | Cryptocurrency-mining domains. |
| `https://v.firebog.net/hosts/RPiList-Phishing.txt` | Phishing domains. |

These are retained from the owner's working configuration. Third-party lists
can change or disappear, so add them individually and remove any list that
repeatedly fails to download or causes unacceptable false positives.

Update gravity after changing the list selection:

```bash
sudo pihole updateGravity
```

Pi-hole already refreshes gravity weekly. No external list updater or daily
root cron job is required.

## 7. Apply the service-compatibility allowlist

The repository keeps the owner's reviewed compatibility entries in
[`src/pihole/allowlist-service-compatibility.txt`](../src/pihole/allowlist-service-compatibility.txt).
They are not universal recommendations. Apply only the entries needed by the
services used on this installation.

| Domain | Observed reason |
| --- | --- |
| `spclient.wg.spotify.com` | Spotify did not work correctly. |
| `s.youtube.com` | YouTube watched history did not update. |
| `lnkd.in` | LinkedIn shortened links were blocked. |
| `analytics.google.com` | A required metrics dashboard did not load correctly. |
| `analytics.pinterest.com` | A required metrics dashboard did not load correctly. |

From the cloned repository root, preview the active entries:

```bash
grep -Ev '^[[:space:]]*(#|$)' src/pihole/allowlist-service-compatibility.txt
```

Apply them:

```bash
grep -Ev '^[[:space:]]*(#|$)' \
  src/pihole/allowlist-service-compatibility.txt \
  | xargs -r sudo pihole allow
```

Verify the entries and then test the affected services from a client:

```bash
while IFS= read -r domain; do
  pihole query "${domain}"
done < <(grep -Ev '^[[:space:]]*(#|$)' \
  src/pihole/allowlist-service-compatibility.txt)
```

Remove only these maintained entries if they are no longer wanted:

```bash
grep -Ev '^[[:space:]]*(#|$)' \
  src/pihole/allowlist-service-compatibility.txt \
  | xargs -r sudo pihole allow remove
```

## 8. Add useful local hostnames

Pi-hole reads local host mappings from `/etc/hosts`. Keep existing lines and
add only the mappings maintained by this Raspberry Pi:

```bash
sudo cp -a /etc/hosts "/etc/hosts.bak.$(date +%Y%m%d-%H%M%S)"
sudo vim /etc/hosts
```

Example structure:

```text
127.0.0.1       localhost
::1             localhost ip6-localhost ip6-loopback
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters

127.0.1.1       {RASPBERRY-PI-HOSTNAME}

192.168.1.1     my-router
192.168.1.2     my-phone
```

Reload DNS and verify one added name:

```bash
sudo pihole reloaddns
getent hosts my-router
```

`getent` should return the address entered in `/etc/hosts`.

## 9. Verify and maintain Pi-hole

```bash
pihole status
pihole version
pihole query example.com
sudo pihole tail
```

Expected results:

- `pihole status` reports DNS blocking as enabled.
- `pihole version` reports the installed Core, Web and FTL versions.
- `pihole query` explains whether the test domain is known to any configured
  list.
- `pihole tail` shows live DNS activity; press `Ctrl+C` to stop it.

Before a major Pi-hole update, read the release notes and export a Teleporter
backup from **Settings > Teleporter** in the web interface. Then update with:

```bash
sudo pihole -up
```

For troubleshooting:

```bash
sudo journalctl -u pihole-FTL --no-pager -n 100
sudo pihole debug
```

The debug command offers to upload a diagnostic log. Review the prompt and do
not share the resulting token publicly if the log contains installation data.

## 10. Optional query-activity LEDs

This optional feature flashes a green LED for an answered query and a red LED
for a blocked query. It uses GPIO Zero and a systemd service instead of the
deprecated `/sys/class/gpio` interface and root cron.

### Wire the LEDs

Shut down and disconnect power before changing GPIO wiring. Each LED needs its
own 220 to 330 ohm series resistor.

| Function | BCM GPIO | Physical pin |
| --- | ---: | ---: |
| Answered query, green | 20 | 38 |
| Blocked query, red | 21 | 40 |
| Ground | n/a | 39 |

### Install the service

Clone this repository if it is not already present:

```bash
sudo apt update
sudo apt install git python3-gpiozero
mkdir -p ~/Software
git clone https://github.com/smyrnakis/raspberry-born.git \
  ~/Software/raspberry-born
cd ~/Software/raspberry-born
```

If the repository already exists, review and update it first:

```bash
cd ~/Software/raspberry-born
git status --short
git pull --ff-only
```

Do not pull over local modifications. Review or preserve them first.

Install the maintained files:

```bash
sudo install -o root -g root -m 755 \
  src/pihole/leds/raspi-pihole-leds.py \
  /usr/local/sbin/raspi-pihole-leds
sudo install -o root -g root -m 644 \
  src/pihole/leds/raspi-pihole-leds.default \
  /etc/default/raspi-pihole-leds
sudo install -o root -g root -m 644 \
  src/pihole/leds/raspi-pihole-leds.service \
  /etc/systemd/system/raspi-pihole-leds.service

sudo systemd-analyze verify \
  /etc/systemd/system/raspi-pihole-leds.service
sudo systemctl daemon-reload
sudo systemctl enable --now raspi-pihole-leds.service
```

Verify it:

```bash
systemctl is-enabled raspi-pihole-leds.service
systemctl is-active raspi-pihole-leds.service
sudo journalctl -u raspi-pihole-leds.service --no-pager -n 30
```

The first two commands should print `enabled` and `active`. Generate one normal
and one blocked lookup from a client. The corresponding LEDs should flash, and
the service log should not show repeated errors.

To change the GPIO pins, log path, or flash duration:

```bash
sudo vim /etc/default/raspi-pihole-leds
sudo systemctl restart raspi-pihole-leds.service
```

To remove the optional feature:

```bash
sudo systemctl disable --now raspi-pihole-leds.service
sudo rm /etc/systemd/system/raspi-pihole-leds.service
sudo rm /etc/default/raspi-pihole-leds
sudo rm /usr/local/sbin/raspi-pihole-leds
sudo systemctl daemon-reload
```

## References

- [Pi-hole installation](https://docs.pi-hole.net/main/basic-install/)
- [Pi-hole prerequisites and ports](https://docs.pi-hole.net/main/prerequisites/)
- [Pi-hole configuration: listening mode](https://docs.pi-hole.net/ftldns/configfile/#dnslisteningmode)
- [Pi-hole command-line reference](https://docs.pi-hole.net/core/pihole-command/)
- [Pi-hole updates](https://docs.pi-hole.net/main/update/)
- [Cloudflare resolver setup and addresses](https://developers.cloudflare.com/1.1.1.1/setup/)
- [Cloudflare public-resolver privacy](https://developers.cloudflare.com/1.1.1.1/privacy/public-dns-resolver/)
- [Quad9 service and addresses](https://quad9.net/service/service-addresses-and-features/)
- [Google Public DNS setup and addresses](https://developers.google.com/speed/public-dns/docs/using)
- [Google Public DNS privacy](https://developers.google.com/speed/public-dns/privacy)
