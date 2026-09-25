# Boot report and recovery summary

This guide sends one plain-text system report after each Raspberry Pi boot. It
uses the durable notification queue from [email.md](email.md), so temporary
Internet or SMTP outages do not lose the report.

The implementation uses Bash and standard system commands. It does not require
Python, a virtual environment, `/etc/rc.local` or a recipient address in the
script.

Official references:

- [systemd network-online target](https://www.freedesktop.org/software/systemd/man/latest/systemd.special.html#network-online.target)
- [Cloudflare `/cdn-cgi/trace` endpoint](https://developers.cloudflare.com/fundamentals/reference/cdn-cgi-endpoint/)

## What the report contains

The default report includes:

- hostname, generation time, boot time, uptime, OS and kernel
- whether network readiness was detected within the configured wait period
- all global local IPv4 addresses and the default route
- the public IPv4 address returned by Cloudflare
- CPU temperature, load, memory, root-filesystem and throttling state
- reboot-required state and the packages requesting it, when available
- failed systemd units
- optional systemd-service and peer-reachability checks

Static public IP addresses, email addresses, MAC addresses and public hostnames
are not stored in Git. Runtime reports are sent only to the recipient configured
locally for `raspi-notify`.

## 1. Inspect an existing installation

Run these read-only commands on the Raspberry Pi:

```bash
systemctl status raspi-boot-report.service send-boot-email.service \
    raspi3-boot-report.service --no-pager 2>/dev/null || true

sudo grep -nEi 'boot.*(email|mail|report)|send_boot_email' \
    /etc/rc.local /etc/systemd/system/*.service 2>/dev/null || true

command -v curl
command -v ip
command -v ping
command -v raspi-notify
```

Expected results:

- existing legacy boot scripts or services are identified before anything is
  replaced
- `curl`, `ip`, `ping` and `raspi-notify` resolve to installed commands
- a missing legacy service is normal on a new installation

Do not remove an existing boot notification until the replacement has sent a
successful report after a real boot.

## 2. Verify prerequisites

Install and test the durable notification queue from [email.md](email.md)
first. Confirm that this command queues and delivers a message:

```bash
printf 'Boot-report prerequisite test.\n' | \
    sudo /usr/local/sbin/raspi-notify "[$(hostname --short)] Notification test"
```

The report also needs `curl`, `iproute2`, `iputils-ping` and `procps`. Inspect
their package state:

```bash
dpkg-query -W -f='${binary:Package}\t${Version}\n' \
    curl iproute2 iputils-ping procps 2>/dev/null
```

If a package is missing, review the proposed change before installation:

```bash
apt-get --simulate install curl iproute2 iputils-ping procps
```

After approval, install only the missing packages. Package installation can
restart affected services.

## 3. Review the default configuration

Repository assets are under `src/monitoring/boot-report/`. The installer uses
`boot-report.conf.example` when no local configuration exists.

The defaults are:

```text
PUBLIC_IP_LOOKUP=true
PUBLIC_IP_URL=https://cloudflare.com/cdn-cgi/trace
NETWORK_WAIT_SECONDS=120
CHECK_SERVICES=
CHECK_PEERS=
```

Public-IP lookup is enabled by default. The report makes one bounded HTTPS
request to Cloudflare after boot, forces IPv4 and extracts only the `ip=` field.
The connection timeout is 3 seconds and the total request timeout is 8 seconds.
A failure produces `Public IPv4: unavailable` without failing the report.

This request necessarily reveals the Raspberry Pi's public source address to
Cloudflare. To disable it, use `PUBLIC_IP_LOOKUP=false` in the local
configuration.

## 4. Add optional device checks

Skip this section when the defaults are sufficient. To add service or peer
checks, create the ignored local file on the Raspberry Pi:

```bash
cd ~/raspberry-born/src/monitoring/boot-report
cp boot-report.conf.example boot-report.conf
vim boot-report.conf
```

Example structure:

```text
PUBLIC_IP_LOOKUP=true
PUBLIC_IP_URL=https://cloudflare.com/cdn-cgi/trace
NETWORK_WAIT_SECONDS=120
CHECK_SERVICES=ssh.service openvpn-client@CLIENT_NAME
CHECK_PEERS=VPN_PEER=10.8.0.1 ROUTER=192.168.1.1
```

Replace `CLIENT_NAME` and the example addresses with values for that Raspberry
Pi.
Use whitespace-separated values:

- `CHECK_SERVICES` accepts systemd unit names. A unit that is not active marks
  the report subject as `ATTENTION`.
- `CHECK_PEERS` accepts `LABEL=HOST` pairs. An unreachable peer marks the
  subject as `ATTENTION`.
- `NETWORK_WAIT_SECONDS` accepts `0` through `300`. The wait is bounded and
  does not prevent the rest of the boot indefinitely.

Do not add personal email addresses, MAC addresses, public DDNS names or secret
values to the tracked example. `boot-report.conf` is ignored by Git, but still
protect its deployed copy as root-owned configuration.

Camera discovery remains part of a device-specific runbook. A general boot
report should not require or publish a camera MAC address.

## 5. Validate the repository assets

The default installer mode is read-only:

```bash
cd ~/raspberry-born/src/monitoring/boot-report
./install-boot-report.sh --check
```

A successful result identifies whether the example or local configuration was
selected, validates its allowed settings, checks required commands and Bash
syntax, and prints:

```text
Validation passed. No files were changed.
```

The check does not contact Cloudflare, send a notification or change service
state.

## 6. Install without activating

After reviewing the plan and approving the file changes:

```bash
sudo ./install-boot-report.sh --apply
```

The installer creates a timestamped backup under
`/var/backups/raspi-boot-report/` and installs:

| Path | Purpose |
| --- | --- |
| `/usr/local/sbin/raspi-boot-report` | Collect, preview and queue the report |
| `/etc/raspi-boot-report/boot-report.conf` | Root-only local settings |
| `/etc/systemd/system/raspi-boot-report.service` | Run once during each boot |

It reloads systemd metadata and verifies the unit. It does not enable or start
the service, contact Cloudflare, send a report, restart another service or
reboot.

## 7. Preview and send a test report

First preview the report in the terminal:

```bash
sudo /usr/local/sbin/raspi-boot-report --preview
```

With the default configuration, previewing contacts Cloudflare for the public
IPv4 lookup. It does not queue email. Check that:

- local addresses do not contain `127.0.0.0/8`
- boot time is plausible and not in 1970
- public IPv4 is present or clearly says `unavailable`
- failed units and optional checks match the actual system
- no secret or prohibited identifier appears unexpectedly

Then queue one real test report:

```bash
sudo /usr/local/sbin/raspi-boot-report --send
sudo systemctl status raspi-notify-dispatcher.service --no-pager
sudo journalctl -t raspi-boot-report -t raspi-notify-dispatcher \
    --no-pager -n 50
```

Expected results:

- the command prints `Queued boot report`
- the journal contains `Queued boot report`
- the durable dispatcher either delivers the message or retains it for retry
- the received subject is `[hostname] Boot report`, with ` - ATTENTION` when a
  configured service, peer, network check or systemd unit needs review

## 8. Enable the boot service

Enabling the unit authorizes one report on every future boot. It does not start
the service immediately:

```bash
sudo systemctl enable raspi-boot-report.service
systemctl is-enabled raspi-boot-report.service
```

Expected result: `enabled`.

To test the systemd path without rebooting, explicitly approve and start the
oneshot:

```bash
sudo systemctl start raspi-boot-report.service
sudo systemctl status raspi-boot-report.service --no-pager
sudo journalctl -u raspi-boot-report.service -b --no-pager
```

A successful oneshot normally finishes as `inactive (dead)` with
`status=0/SUCCESS`. One report should be queued.

## 9. Verify after a real boot

A reboot is a separate disruptive action. Perform it only in an approved
maintenance window with a tested local or out-of-band recovery path.

After reconnecting, run:

```bash
systemctl is-enabled raspi-boot-report.service
systemctl status raspi-boot-report.service --no-pager
sudo journalctl -u raspi-boot-report.service -b --no-pager
systemctl --failed
```

Expected results:

- the service remains enabled
- the boot invocation completed successfully
- exactly one report for the current boot was queued
- the report's service and peer results match the device-specific runbook

## 10. Retire a legacy boot email

First check whether another boot-email mechanism exists. The following commands
are read-only.

Search system-wide systemd services by name and description:

```bash
systemctl list-unit-files --type=service --no-pager |
    grep -Ei 'boot.*(mail|email|report)|send.*boot' || true

systemctl list-units --all --type=service --no-pager |
    grep -Ei 'boot.*(mail|email|report)|send.*boot' || true
```

Search locally created service definitions by both filename and content:

```bash
sudo find /etc/systemd/system -maxdepth 3 \
    \( -type f -o -type l \) \
    \( -iname '*boot*mail*' -o -iname '*boot*email*' -o \
       -iname '*boot*report*' -o -iname '*send*boot*' \) -print

sudo grep -RInE \
    'boot.*(mail|email|report)|send_boot_email|msmtp|raspi-notify' \
    /etc/systemd/system 2>/dev/null || true
```

Check `rc.local` and cron startup entries:

```bash
if test -e /etc/rc.local; then
    test -x /etc/rc.local && echo '/etc/rc.local is executable'
    sudo grep -nEi \
        'boot.*(mail|email|report)|send_boot_email|msmtp|raspi-notify' \
        /etc/rc.local || true
    systemctl status rc-local.service --no-pager 2>/dev/null || true
fi

crontab -l 2>/dev/null | grep -Ei \
    '@reboot|boot.*(mail|email|report)|send_boot_email|msmtp|raspi-notify' || true

sudo crontab -l 2>/dev/null | grep -Ei \
    '@reboot|boot.*(mail|email|report)|send_boot_email|msmtp|raspi-notify' || true

sudo grep -RInE \
    '@reboot|boot.*(mail|email|report)|send_boot_email|msmtp|raspi-notify' \
    /etc/crontab /etc/cron.d /var/spool/cron/crontabs 2>/dev/null || true
```

Check likely script locations without printing file contents:

```bash
sudo find /usr/local/bin /usr/local/sbin /opt /home -maxdepth 4 -type f \
    \( -iname '*boot*mail*' -o -iname '*boot*email*' -o \
       -iname '*boot*report*' -o -iname 'send_boot_email*' \) \
    -print 2>/dev/null
```

No output from the searches, no `@reboot` cron entry and no relevant command in
an executable `/etc/rc.local` means that no common legacy boot-email path was
found. It is not proof that an unusually named custom mechanism does not exist,
but it covers the normal systemd, `rc.local` and cron locations.

For every candidate service, replace `UNIT.service` below with its exact name:

```bash
systemctl is-enabled UNIT.service
systemctl is-active UNIT.service
systemctl cat UNIT.service
sudo journalctl -u UNIT.service -b --no-pager
```

The `cat` output shows the executable and arguments without modifying the unit.
Confirm that it actually sends a boot notification rather than assuming from
its filename alone.

Only after identifying a legacy mechanism and completing a successful real-boot
test of `raspi-boot-report`:

1. Record the exact old `rc.local` line or systemd unit.
2. Back up the affected file.
3. Disable the old service or remove only its exact `rc.local` invocation.
4. Reboot later in another approved window and confirm that only one report is
   sent.

Do not delete the old script during the first migration step. Keep it until the
new path has passed a second boot or until its backup is independently verified.

## 11. Roll back repository-managed files

If the service was enabled, disable it first:

```bash
sudo systemctl disable --now raspi-boot-report.service
```

Then use the exact backup path printed by `--apply`:

```bash
cd ~/raspberry-born/src/monitoring/boot-report
sudo ./install-boot-report.sh --rollback \
    /var/backups/raspi-boot-report/YYYYMMDD-HHMMSS
```

Rollback restores only the managed command, configuration and systemd unit. It
reloads systemd metadata but does not restore a retired legacy boot script,
delete queued notifications or alter SMTP configuration.
