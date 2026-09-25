# OpenVPN health monitoring and bounded recovery

This guide monitors an OpenVPN client or server without assuming that a
temporary remote-site outage means the local Raspberry Pi has failed. It sends
durable notifications, performs limited service recovery, and keeps rebooting
disabled unless it is explicitly enabled in that device's configuration.

Official references:

- [OpenVPN 2.6 manual](https://openvpn.net/community-docs/community-articles/openvpn-2-6-manual.html)
- [Debian OpenVPN systemd unit](https://sources.debian.org/src/openvpn/2.6.14-0%2Bdeb12u2/debian/openvpn%40.service/)
- [systemd timer units](https://www.freedesktop.org/software/systemd/man/latest/systemd.timer.html)
- [systemctl unit-state commands](https://www.freedesktop.org/software/systemd/man/latest/systemctl.html)

OpenVPN already has connection retry and `ping-restart` behavior. This
watchdog does not replace it. It adds host-level notification and recovery when
the service itself fails or a fault persists for many hours.

Installation requires the files under `src/monitoring/vpn-watchdog/`. The
recommended method is to clone the `raspberry-born` repository into the normal
login user's home directory. Do not clone it as `root`. Cloning the full
repository is not mandatory; copying only that directory to the Raspberry Pi
also works, provided all its files remain together.

## Health model

The same command supports two roles:

| Role | Required health evidence | What is deliberately ignored |
| --- | --- | --- |
| Client | OpenVPN service active or its main process still running, tunnel interface present, optional expected tunnel address present, configured VPN peer reachable through the tunnel | Whether the remote site currently accepts other clients |
| Server | OpenVPN service active, tunnel interface present, configured TCP or UDP listening socket present | Number of connected clients |

An OpenVPN server can be completely healthy with zero connected clients.
Client count must never be used as the server health criterion.

For a client, a failed tunnel is classified further:

| Local evidence | Interpretation | Automatic action |
| --- | --- | --- |
| OpenVPN service inactive or failed | Confirmed local service fault | Notify and make bounded restart attempts |
| Service or its main process running, tunnel unavailable, ordinary Internet available | Remote endpoint or VPN path may be unavailable | Notify; let OpenVPN retry; do not restart or reboot |
| Service or its main process running, tunnel unavailable, ordinary Internet unavailable | Cause is uncertain | Notify; optional reboot only after the configured long delay and safeguards |

The second case is a safe operational inference, not proof that the remote site
is down. A client cannot diagnose the remote network conclusively through the
same failed path.

## Device policy

The repository default is always:

```text
ALLOW_SERVICE_RESTART=false
ALLOW_REBOOT=false
```

Apply these device-specific policies only after testing service, firewall, boot
and remote-access recovery:

- `Raspi3-02` in Crete is a persistent client of the Athens VPN on
  `Raspi4-01`. It normally has no independent remote administration path. Its
  intended final profile may use `ALLOW_REBOOT=true` with a 12-hour failure
  threshold and a 12-hour minimum interval between watchdog reboots.
- If Raspi3-02's OpenVPN process remains active and either independent Internet
  endpoint responds, an unavailable Athens tunnel does not justify rebooting
  Crete. The client continues its own reconnection attempts.
- If the local OpenVPN service is failed, or both the VPN and independent
  Internet checks remain unavailable for 12 hours, Raspi3-02 may use its
  explicitly enabled and rate-limited reboot fallback.
- `Raspi4-01` in Athens and `Raspi4-02` in Geneva are OpenVPN servers. Automatic
  reboot remains off by default. A confirmed server fault generates notices
  after 10 minutes and approximately 1, 6 and 11 hours before an optional
  12-hour reboot threshold.

The timer, OpenVPN restart permission and reboot permission are separate
decisions. Installing files does not activate any of them.

## 1. Inspect the current OpenVPN installation

Run these read-only commands on the Raspberry Pi:

```bash
systemctl list-unit-files 'openvpn*.service' --no-pager
systemctl list-units 'openvpn*.service' --all --no-pager
ip -brief link show type tun
ip -4 -brief address
sudo ss -lunp
sudo ss -ltnp
```

For the exact candidate unit, inspect bounded status and recent logs:

```bash
timeout 10 systemctl is-active openvpn-client@CLIENT_NAME.service
timeout 10 systemctl status openvpn-client@CLIENT_NAME.service --no-pager
sudo journalctl -u openvpn-client@CLIENT_NAME.service --no-pager -n 50
```

Use `openvpn-server@server.service` or the actual server unit on a server.
Replace examples only after the first commands prove the installed unit name.

Expected results:

- the exact OpenVPN unit and its active state are visible
- the expected tunnel interface and its private address are visible while the
  tunnel is established
- a server shows a listening socket on its configured OpenVPN port even when no
  client is connected
- the commands do not restart a service or alter network state

Do not use an unbounded `service openvpn status` command for this audit.

## 2. Verify prerequisites

Install and test the durable notification queue from [email.md](email.md)
before continuing.

The watchdog uses `bash`, `curl`, `iproute2`, `iputils-ping`, `procps`,
`systemd` and `util-linux`. Git is used to obtain the repository. Inspect
package state first:

```bash
dpkg-query -W -f='${binary:Package}\t${Version}\n' \
    bash curl git iproute2 iputils-ping procps systemd util-linux 2>/dev/null
command -v raspi-notify
```

Install any missing packages:

```bash
sudo apt-get update
sudo apt-get install curl git iproute2 iputils-ping procps util-linux
```

## 3. Create the local configuration

If the repository is not already present, clone it as the normal login user:

```bash
mkdir -p ~/Software
cd ~/Software
git clone https://github.com/smyrnakis/raspberry-born.git
```

The path `~/Software/raspberry-born` resolves to
`/home/{USERNAME}/Software/raspberry-born`. The clone remains owned by
`{USERNAME}`; only the later system installation command uses `sudo`.

For an OpenVPN client:

```bash
cd ~/Software/raspberry-born/src/monitoring/vpn-watchdog
cp vpn-watchdog-client.conf.example vpn-watchdog.conf
vim vpn-watchdog.conf
```

If only the watchdog directory was copied instead of cloning the repository,
replace that `cd` command with its actual location, for example:

```bash
cd /path/to/copied/vpn-watchdog
```

For an OpenVPN server, copy `vpn-watchdog-server.conf.example` instead. The
real `vpn-watchdog.conf` is ignored by Git because it contains machine-specific
service and topology values.

The current installer manages one watchdog profile per Raspberry Pi. If a
future Raspberry Pi runs both an OpenVPN client and an OpenVPN server, use two
separate watchdog instances and configurations so a failure in one role cannot
hide the state of the other. Add that multi-instance setup to this guide when
such a host is introduced; the present hosts do not need it.

Important settings:

| Setting | Meaning |
| --- | --- |
| `ROLE` | `client` or `server` |
| `VPN_SERVICE` | Exact systemd service unit proved by the audit |
| `VPN_INTERFACE` | Tunnel interface, commonly `tun0` |
| `EXPECTED_TUNNEL_CIDR` | Optional exact local tunnel address and prefix |
| `VPN_PEER` | Client-side private VPN peer tested through the tunnel |
| `SERVER_PROTOCOL`, `SERVER_PORT` | Server listening-socket check |
| `INTERNET_CHECK_URLS` | Independent HTTPS endpoints; any one success proves ordinary Internet access |
| `FAILURE_NOTIFY_SECONDS` | Delay before the first failure notice |
| `REMINDER_SECONDS` | Increasing reminder thresholds, all below the reboot threshold |
| `RESTART_SECONDS` | Bounded restart thresholds used only for a confirmed local service failure |
| `ALLOW_SERVICE_RESTART` | Separate permission for bounded OpenVPN service restarts |
| `ALLOW_REBOOT` | Explicit per-device reboot permission; default `false` |
| `REBOOT_AFTER_SECONDS` | Continuous-failure duration before reboot can be considered |
| `REBOOT_MIN_INTERVAL_SECONDS` | Persistent minimum interval between watchdog reboots |
| `SUPPRESS_REBOOT_WHEN_LOGGED_IN` | Prevent reboot while an interactive session exists |
| `REBOOT_INHIBIT_FILE` | Temporary local marker that blocks watchdog reboot |

The default Internet checks use bounded HTTPS requests to Cloudflare and
Google. No DDNS name, account, payload or credential is sent. Any successful
request is sufficient; both failures mean only that Internet health is
uncertain.

For the Raspi3-02 target policy, retain the 12-hour values and change
`ALLOW_REBOOT=true` only after completing section 8.

## 4. Validate without changing the system

The installer defaults to a read-only check:

```bash
sudo ./install-vpn-watchdog.sh --check
```

Expected result:

```text
Validation passed. No files were changed.
```

It checks the configuration, script syntax, required commands and source files.
It also confirms that apply mode will not enable the timer, run the watchdog,
restart OpenVPN, send mail or reboot. Apply mode verifies the installed systemd
units before it finishes.

## 5. Install the inactive files

This changes files and reloads systemd metadata, but it does not change service
state:

```bash
sudo ./install-vpn-watchdog.sh --apply
```

The installer reports a backup directory under
`/var/backups/raspi-vpn-watchdog/`. Record that path for rollback.

Verify the installed files:

```bash
sudo /usr/local/sbin/raspi-vpn-watchdog --validate-config
systemctl is-enabled raspi-vpn-watchdog.timer
systemctl is-active raspi-vpn-watchdog.timer
```

Expected outcomes:

- configuration validation succeeds
- both timer commands report `disabled` or `inactive`
- OpenVPN has not been restarted

## 6. Run read-only health and notification tests

The health check does not update state, restart a service or reboot:

```bash
sudo /usr/local/sbin/raspi-vpn-watchdog --check
```

A healthy OpenVPN client or OpenVPN server prints `healthy` and exits with
status zero. An unhealthy result includes its classification, detail and
independent Internet state and exits non-zero.

Test notification templates without simulating a real outage:

```bash
sudo /usr/local/sbin/raspi-vpn-watchdog --simulate-failure
sudo /usr/local/sbin/raspi-vpn-watchdog --simulate-recovery
sudo journalctl -t raspi-notify-dispatcher --no-pager -n 30
```

Both messages must arrive. Neither test calls `systemctl restart` or
`systemctl reboot`.

## 7. Activate monitoring

Enable and start the timer:

```bash
sudo systemctl enable --now raspi-vpn-watchdog.timer
systemctl status raspi-vpn-watchdog.timer --no-pager
systemctl list-timers raspi-vpn-watchdog.timer --no-pager
```

Expected outcomes:

- the timer is active and shows its next two-minute run
- normal healthy runs produce no notification and no routine success log
- `journalctl -u raspi-vpn-watchdog.service` records only errors, recovery
  actions or other noteworthy events

To disable monitoring later without changing OpenVPN:

```bash
sudo systemctl disable --now raspi-vpn-watchdog.timer
```

## 8. Prove recovery before allowing reboot

Keep `ALLOW_SERVICE_RESTART=false` and `ALLOW_REBOOT=false` during initial
operation. Verify all of the following in a planned maintenance window:

1. A real OpenVPN service failure produces the first notice and bounded restart
   attempts.
2. Recovery produces a recovery notice that explicitly says no reboot is
   required.
3. A remote VPN outage while ordinary Internet remains available suppresses
   restart and reboot on a client.
4. The Raspberry Pi boots completely and restores OpenVPN, firewall rules,
   routing and notification delivery after a controlled reboot.
5. An alternate local or physical recovery method is available for the test.

Run the service-stop, Internet-disconnection and reboot tests only during a
planned maintenance window with a working recovery path.

After the Raspi3-02 tests pass, edit its installed configuration:

```bash
sudo vim /etc/raspi-vpn-watchdog/vpn-watchdog.conf
```

Set:

```text
ALLOW_SERVICE_RESTART=true
ALLOW_REBOOT=true
REBOOT_AFTER_SECONDS=43200
REBOOT_MIN_INTERVAL_SECONDS=43200
```

Revalidate without restarting the timer:

```bash
sudo /usr/local/sbin/raspi-vpn-watchdog --validate-config
```

For Athens and Geneva, service restart may be enabled after its controlled test.
Leave `ALLOW_REBOOT=false` until each server's boot and remote-access recovery
has been tested independently. The configured 10-minute, 1-hour, 6-hour and
11-hour messages still operate while recovery actions are disabled.

## 9. Temporarily inhibit a permitted reboot

Create the runtime inhibit marker:

```bash
sudo install -o root -g root -m 600 /dev/null \
    /run/raspi-vpn-watchdog/no-reboot
```

This survives timer runs but disappears at the next boot. Remove it after the
maintenance session:

```bash
sudo rm /run/raspi-vpn-watchdog/no-reboot
```

The watchdog also suppresses reboot while `who` reports an interactive login.
Neither safeguard makes an unhealthy VPN healthy; they only prevent automatic
reboot while an administrator is working.

## 10. Inspect state and troubleshoot

```bash
sudo find /run/raspi-vpn-watchdog -maxdepth 1 -type f -printf '%f: ' \
    -exec cat {} \; 2>/dev/null
sudo cat /var/lib/raspi-vpn-watchdog/last-reboot 2>/dev/null || true
sudo journalctl -u raspi-vpn-watchdog.service --no-pager -n 100
sudo journalctl -u openvpn-client@CLIENT_NAME.service --no-pager -n 100
```

Runtime markers record the continuous failure start, sent reminders and used
restart thresholds. `/var/lib/raspi-vpn-watchdog/last-reboot` persists across a
boot so a reboot loop cannot bypass the minimum interval.

Do not manually delete state merely to force another restart or reboot. First
identify why the health check remains unsuccessful.

## 11. Roll back

Disable the timer first:

```bash
sudo systemctl disable --now raspi-vpn-watchdog.timer
```

Then use the exact backup path reported by the installer:

```bash
sudo ./install-vpn-watchdog.sh --rollback \
    /var/backups/raspi-vpn-watchdog/YYYYMMDD-HHMMSS
```

Rollback restores only the managed command, configuration and unit files. It
does not restart OpenVPN, change queued notifications, clear watchdog state or
reboot the Raspberry Pi.
