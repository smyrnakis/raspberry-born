# Athens-Crete site-to-site VPN

This guide extends an existing OpenVPN installation so authenticated clients of the Athens VPN can reach devices on the Crete LAN through Raspi3-02.

It is a tested case study and a reusable procedure. It does not install an OpenVPN server or create client profiles.

## Tested topology

| Role | Tested value |
| --- | --- |
| Athens OpenVPN server LAN | `192.168.178.0/24` |
| OpenVPN tunnel network | `10.8.0.0/24` |
| Raspi3-02 VPN address | `10.8.0.20` |
| Crete LAN | `192.168.1.0/24` |
| Crete VPN client certificate name | `401-Raspi3-02` |
| Raspi3-02 VPN interface | `tun0` |
| Raspi3-02 LAN interface | `eth0` |

Raspi3-02 remains split-tunnelled. Its ordinary internet traffic continues to use the Crete internet connection. Only traffic from authenticated VPN clients to the Crete LAN is forwarded and masqueraded.

The Starlink router at Crete cannot hold a return route for the VPN network. Raspi3-02 therefore performs narrowly scoped source NAT for `10.8.0.0/24` to `192.168.1.0/24`.

## Assumptions

- The Athens OpenVPN server and the Raspi3-02 OpenVPN client already connect successfully.
- The server uses `topology subnet`.
- Raspi3-02 receives `10.8.0.20` through its client-specific configuration.
- The Crete client uses `route-nopull`, so it does not replace its default route or import unrelated pushed routes.
- The two LAN ranges do not overlap.
- The nftables installer is run only after reviewing the existing firewall.

Do not copy a live `.ovpn` profile, private key, public endpoint or DDNS name into this repository.

## 1. Read-only audit

Complete this section before changing either system.

### Athens OpenVPN server

```bash
sudo systemctl list-units --type=service --all 'openvpn*' --no-pager
openvpn --version | head -n 2

sudo grep -E \
  '^[[:space:]]*(server|topology|client-config-dir|route|push|client-to-client|dev|proto|port)([[:space:]]|$)' \
  /etc/openvpn/server/server.conf

sudo cat /etc/openvpn/ccd/401-Raspi3-02
sysctl net.ipv4.ip_forward
ip -4 route show 192.168.1.0/24

sudo nft list ruleset
```

Confirm the actual OpenVPN service and configuration paths before continuing. They can differ between Debian versions and installation methods.

### Crete Raspi3-02 client

```bash
systemctl is-active openvpn-client@crete
systemctl is-enabled openvpn-client@crete
ip -br -4 address show tun0
ip -4 route show
sysctl net.ipv4.ip_forward

sudo nft list ruleset
```

Expected before router installation:

- `openvpn-client@crete` is active and enabled.
- `tun0` has `10.8.0.20/24`.
- The normal default route still uses the Crete LAN gateway.
- No unexpected firewall rules conflict with the proposed VPN-to-LAN path.

If the VPN itself is not healthy, stop here. This guide does not repair the base OpenVPN installation.

## 2. Configure the Athens OpenVPN route

This section changes the server configuration and later requires an OpenVPN service restart. Keep an existing administrative connection available and schedule the restart appropriately.

Back up the server configuration:

```bash
sudo cp -a \
  /etc/openvpn/server/server.conf \
  "/etc/openvpn/server/server.conf.pre-crete-route.$(date +%Y%m%d-%H%M%S)"
```

Edit it with Vim:

```bash
sudo vim /etc/openvpn/server/server.conf
```

Ensure these directives are present once:

```conf
topology subnet
client-config-dir /etc/openvpn/ccd

# Route the Crete LAN through Raspi3-02's stable VPN address.
route 192.168.1.0 255.255.255.0 10.8.0.20

# Advertise the Crete LAN to the other VPN clients.
push "route 192.168.1.0 255.255.255.0"
```

The server `route` places the subnet in the operating-system routing table. The client-specific `iroute` in the next step tells OpenVPN which connected client owns that subnet. Both are required.

Create or edit the client-specific file. Its filename must match the client certificate common name:

```bash
sudo install -d -o root -g root -m 755 /etc/openvpn/ccd
sudo vim /etc/openvpn/ccd/401-Raspi3-02
```

```conf
# Stable tunnel address for Raspi3-02 with topology subnet.
ifconfig-push 10.8.0.20 255.255.255.0

# The Crete LAN is reachable through this client.
iroute 192.168.1.0 255.255.255.0
```

Do not put `iroute` in the main server configuration. It belongs to the client-specific file.

Review the resulting files before restarting anything:

```bash
sudo grep -nE \
  '^[[:space:]]*(topology|client-config-dir|route|push)([[:space:]]|$)' \
  /etc/openvpn/server/server.conf

sudo cat /etc/openvpn/ccd/401-Raspi3-02
```

After explicitly approving the interruption, restart the verified server unit:

```bash
sudo systemctl restart openvpn-server@server
sudo systemctl --no-pager --full status openvpn-server@server
```

Verify that Raspi3-02 reconnects before proceeding.

## 3. Check the Crete OpenVPN client

The client profile remains secret and outside Git. Review only the non-secret routing directives on Raspi3-02:

```bash
sudo grep -nE \
  '^[[:space:]]*(client|dev|route-nopull|route|pull-filter|data-ciphers|cipher)([[:space:]]|$)' \
  /etc/openvpn/client/crete.conf
```

For this tested split-tunnel design:

- Keep `route-nopull`.
- Do not add `redirect-gateway`.
- Do not add `route 10.8.0.0 255.255.255.0`; `10.8.0.0/24` is already directly connected through `tun0`.
- With OpenVPN 2.5 and later, use `data-ciphers` negotiation. Configure a legacy cipher or `data-ciphers-fallback` only after confirming that an audited older peer requires it.

No client service restart is needed if this review finds no change.

## 4. Prepare the nftables router assets

The reusable files are in [`src/vpn/site-to-site/`](../src/vpn/site-to-site/).

Copy only that directory to Raspi3-02. Do not copy VPN profiles with it.

From the **Windows laptop**, run in PowerShell from the repository root:

```powershell
scp -r .\src\vpn\site-to-site `
  {PI-USERNAME}@10.8.0.20:~/
```

On the **Raspberry Pi**:

```bash
cd ~/site-to-site
chmod 700 install-router.sh
```

Create the local configuration from the tested example:

```bash
cp site.conf.example site.conf
vim site.conf
```

The repository ignores `site.conf` so machine-specific working values are not committed accidentally.

Review the values and run the non-applying check:

```bash
sudo ./install-router.sh --check site.conf
```

The check:

- validates the interface names and subnet syntax;
- confirms the interfaces exist;
- renders and syntax-checks the proposed nftables file;
- shows current IPv4 forwarding, nftables service state and live ruleset;
- makes no persistent or runtime change.

If another firewall manages forwarding, stop and integrate equivalent rules into that firewall instead of assuming two independent rulesets will cooperate.

## 5. Apply the Crete router configuration

This step enables IPv4 forwarding, installs firewall files, enables nftables and restarts the nftables service. Run it only after reviewing the check output and explicitly approving the firewall change.

```bash
sudo ./install-router.sh --apply site.conf
```

The installer:

- creates a timestamped backup under `/var/backups/`;
- installs a dedicated nftables include without issuing ad hoc flush commands;
- validates the complete `/etc/nftables.conf` before activation;
- applies only the dedicated IPv4-forwarding sysctl file;
- enables and restarts nftables, reloading the complete configured ruleset;
- restores the previous files, forwarding value and service state if installation fails.

The forwarding table has an `accept` default policy and filters only packets entering or leaving the configured VPN interface. It does not take ownership of unrelated forwarded traffic. An existing firewall can still reject the route, which is why the audit remains mandatory.

## 6. Verify the complete path

### On Raspi3-02

```bash
sysctl net.ipv4.ip_forward
systemctl is-enabled nftables
systemctl is-active nftables

sudo nft list table inet vpn_site_forward
sudo nft list table ip vpn_site_nat
```

Expected:

- IPv4 forwarding is `1`.
- nftables is enabled and active.
- Both dedicated tables exist.

### On the Athens server

```bash
ip -4 route show 192.168.1.0/24

sudo grep -E \
  'ROUTING_TABLE|401-Raspi3-02|192\.168\.1\.0' \
  /var/log/openvpn-status.log
```

The route should use the OpenVPN tunnel, and the OpenVPN routing table should associate `192.168.1.0/24` with `401-Raspi3-02`. Do not publish the real-address column from the status log because it can contain a public endpoint.

### From another authenticated Athens VPN client

First confirm that the client received a route for `192.168.1.0/24`. Then test a known service on a current Crete LAN address:

```bash
ip -4 route show 192.168.1.0/24
ping -c 4 {CRETE-LAN-DEVICE-IP}
```

If ICMP is blocked, test the actual required application protocol instead. Successful application access is stronger evidence than ping alone.

Finally, check that nftables counters increased:

```bash
sudo nft list table inet vpn_site_forward
sudo nft list table ip vpn_site_nat
```

The tested deployment successfully carried real camera traffic from a Geneva VPN client through Athens and Raspi3-02 to the Crete LAN.

## 7. Roll back the Crete router

The successful installer output prints its backup directory. Use that exact directory:

```bash
sudo ./install-router.sh --rollback \
  /var/backups/vpn-site-router-{TIMESTAMP}
```

Rollback restores:

- `/etc/nftables.conf`;
- any previous dedicated rule and sysctl files;
- the previous `net.ipv4.ip_forward` value;
- the previous nftables enabled and active states.

Verify the restored state with the read-only commands from section 1.

If the Athens route must also be removed, edit the server configuration and the CCD file deliberately. Remove the Crete `route`, pushed route and `iroute`; keep the static `ifconfig-push` if stable VPN access to Raspi3-02 is still required. Restart the OpenVPN server only after explicit approval.

## References

- [OpenVPN 2.6 manual](https://openvpn.net/community-docs/community-articles/openvpn-2-6-manual.html)
- [OpenVPN: expanding the VPN to additional machines](https://openvpn.net/community-docs/expanding-the-scope-of-the-vpn-to-include-additional-machines-on-either-the-client-or-server-subnet.html)
