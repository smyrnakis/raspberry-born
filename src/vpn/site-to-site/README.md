# Reusable VPN-to-LAN router assets

These files configure a Raspberry Pi that is already an OpenVPN client to route authenticated VPN traffic to its local LAN.

They were generalized from the tested Raspi3-02 deployment. No VPN profile, public endpoint, DDNS name, credential, email address or device MAC address belongs here.

## Files

- `site.conf.example`: tested example values; copy to ignored `site.conf`.
- `vpn-site-router.nft.template`: dedicated forwarding and NAT tables.
- `90-vpn-site-router.conf`: persistent IPv4 forwarding.
- `install-router.sh`: read-only check, transactional application and rollback.

## Use

```bash
chmod 700 install-router.sh
cp site.conf.example site.conf
vim site.conf

sudo ./install-router.sh --check site.conf
```

Review the complete output. The check shows the proposed rules and current live firewall without changing either.

Only after approving the firewall and service impact:

```bash
sudo ./install-router.sh --apply site.conf
```

Keep the printed backup directory. To restore it:

```bash
sudo ./install-router.sh --rollback \
  /var/backups/vpn-site-router-{TIMESTAMP}
```

See [`chapters/vpn_crete-athens.md`](../../../chapters/vpn_crete-athens.md) for the complete server route, verification and recovery procedure.
