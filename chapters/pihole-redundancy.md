# Future redundant Pi-hole design

> **Status:** This is a potential future design. It has not been implemented,
> tested, or deployed. No redundancy scripts are currently maintained by this
> repository.

## Goal

Add a small second Raspberry Pi that continues serving filtered DNS if the
main Pi-hole is unavailable. The proposed secondary is a Raspberry Pi Zero 2 W
connected to the trusted home Wi-Fi network.

The device would have a deliberately limited role:

- Pi-hole
- SSH
- SSH key login, or password followed by TOTP as documented in [2FA](2FA.md)
- unattended security updates
- durable email notifications
- Pi-hole peer monitoring

It would not expose DNS, SSH, or the Pi-hole administration page to the WAN.

## DNS behavior

Ordinary DHCP configuration does not provide strict primary and standby DNS.
When a router advertises two DNS servers, client devices may use either server
while both are healthy. The operating system decides how and when it switches
between them.

The recommended design is therefore active-active:

1. Give each Pi-hole its own stable LAN address.
2. Advertise both addresses through the router's DHCP service.
3. Keep both Pi-holes running and ready to answer queries.
4. Configure both to return equivalent filtered and local DNS results.

The terms *main* and *secondary* describe their administrative roles, not a
guaranteed client query order.

A strict active-standby design using a shared virtual address and a failover
service such as keepalived could be considered later. It is not recommended
for the first implementation because it adds complexity and may be less
predictable over Wi-Fi.

## Proposed platform

- Raspberry Pi Zero 2 W
- Raspberry Pi OS Lite without a desktop
- reliable 2.4 GHz Wi-Fi with a strong signal
- high-quality microSD card
- DHCP reservation for a stable LAN address

DNS uses little bandwidth, so Wi-Fi should be sufficient when signal quality
is stable. A USB Ethernet adapter could be considered later if wireless
reliability proves inadequate.

## Network and access policy

- Keep the Pi-hole listening mode set to `LOCAL`.
- Allow DNS from the trusted LAN only.
- Allow SSH and the Pi-hole administration page from the trusted LAN only.
- Do not create router port-forwards for DNS, SSH, or web administration.
- Do not advertise a public resolver alongside the two Pi-holes, because
  clients could bypass filtering.
- Add VPN administration access only if it becomes an explicit requirement.

If the main Raspberry Pi also provides the only VPN path into the home network,
its failure may prevent remote interactive access to the secondary Pi-hole.
Email notifications would still work while the Internet connection is
available.

## Keep both Pi-holes consistent

Both installations should use the same:

- upstream resolvers
- listening policy
- blocklists
- service-compatibility allowlist
- local host records
- privacy and query-retention settings

The repository should remain the source for maintained list URLs, allowlist
entries, local-record templates, and installation instructions. Do not copy a
live Pi-hole database blindly between different Pi-hole versions.

The first implementation should favor explicit, repeatable configuration over
automatic database replication. A synchronization tool can be evaluated later
only if manual parity becomes difficult to maintain.

## Proposed peer monitoring

Run a small systemd timer on both Pi-holes so that each device monitors the
other. The monitor should:

1. Query the peer directly for a local name such as `pi.hole` every five
   minutes.
2. Test the peer's local DNS service without relying on Internet availability.
3. Treat three consecutive failed checks as an outage.
4. Send one peer-down notification through the durable notification queue.
5. Rate-limit reminders during a long outage.
6. Send one recovery notification when the peer responds again.
7. Report whether the surviving Pi-hole is receiving client queries.

An external-domain lookup can be recorded separately to distinguish a peer
failure from an Internet or upstream-resolver failure.

Monitoring should be symmetric. Monitoring only the main Pi-hole would allow a
failed secondary to remain unnoticed until the main Pi-hole also failed.

## Updates and maintenance

- Use the repository's unattended security-update procedure.
- Do not schedule both Pi-holes in the same maintenance window.
- Before rebooting one Pi-hole, verify that the peer is healthy and answering
  client DNS requests.
- Apply Pi-hole configuration changes to both devices and verify them
  separately.
- Back up each installation before a major Pi-hole upgrade.
- Test redundancy periodically by stopping DNS on one device temporarily and
  verifying that clients continue resolving through the other.

## Proposed repository work when resumed

If this design is approved for implementation later, add:

- a peer-monitor program under `src/pihole/redundancy/`
- an example configuration file containing only placeholders
- a systemd service and timer
- installation, verification, alert-throttling, and rollback instructions
- a documented failover test

The implementation should use the common durable notification queue. It should
not add another direct SMTP implementation.

## Decisions to make later

- Final hostname and reserved LAN address
- Wi-Fi placement and signal-quality acceptance threshold
- Query retention appropriate for the microSD card
- Whether administration should also be allowed through a VPN
- Peer failure threshold and reminder interval
- How local host records will be applied consistently
- Whether a synchronization tool is necessary after operating the manual
  repository-based method

## References

- [Pi-hole prerequisites](https://docs.pi-hole.net/main/prerequisites/)
- [Pi-hole command-line reference](https://docs.pi-hole.net/core/pihole-command/)
- [Raspberry Pi Zero 2 W specifications](https://www.raspberrypi.com/products/raspberry-pi-zero-2-w/)
- [Pi-hole discussion: behavior with two DNS servers](https://discourse.pi-hole.net/t/using-a-2nd-rpi-pi-hole-for-redundancy-setup-question/26932)
- [Microsoft DNS client server-selection behavior](https://learn.microsoft.com/en-us/troubleshoot/windows-server/networking/best-practices-for-dns-client-settings)
