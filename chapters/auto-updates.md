# Automatic security updates and weekly maintenance

Official references:

- [Debian periodic updates](https://wiki.debian.org/PeriodicUpdates)
- [unattended-upgrades configuration](https://sources.debian.org/src/unattended-upgrades/2.13/README.md)
- [Raspberry Pi OS package updates](https://www.raspberrypi.com/documentation/computers/os.html)

This guide uses two update levels:

| Level | Schedule | Action |
| --- | --- | --- |
| Debian-Security | Daily | Install automatically without an automatic reboot. |
| All configured same-release repositories | Weekly | Refresh metadata, simulate `apt full-upgrade` and send a durable report. Install nothing. |
| Broader same-release upgrade | Approved maintenance window | Review and run manually, one Raspberry Pi at a time. |
| Major OS release | Separate rebuild project | Do not automate an in-place release transition. |

Regular smaller update batches are easier to review than several months of
accumulated changes. Broader upgrades remain manual because packages can
restart OpenVPN, Pi-hole and other services or change dependencies.

The repository assets use the durable queue from [email.md](email.md). No email
address is stored in the APT configuration.

## Assumptions

The procedure targets a supported Debian or Raspberry Pi OS release and stays
within its current major version. Raspberry Pi OS recommends `apt full-upgrade`
for regular same-release maintenance because its package dependencies can
change.

The unattended policy selects Debian-Security only. Raspberry Pi OS vendor
packages, firmware and other ordinary updates appear in the weekly report but
are not installed automatically.

## 1. Inspect the current system

The following commands are read-only and run on the Raspberry Pi:

```bash
cat /etc/os-release
dpkg-query -W -f='${binary:Package}\t${Version}\n' unattended-upgrades reboot-notifier 2>/dev/null
systemctl is-enabled apt-daily.timer apt-daily-upgrade.timer
systemctl is-active apt-daily.timer apt-daily-upgrade.timer
systemctl list-timers apt-daily.timer apt-daily-upgrade.timer --no-pager
apt-config dump | grep -E '^(APT::Periodic|Unattended-Upgrade::(Origins-Pattern|Automatic-Reboot))'
test -e /run/reboot-required && echo "reboot required" || echo "no reboot requested"
```

Expected results:

- `/etc/os-release` identifies the installed release and codename.
- Installed package versions are printed; missing packages produce no line.
- Timer commands show whether Debian's APT timers are enabled, active and when
  they will next run.
- `apt-config dump` shows the effective periodic, origin and reboot policy.
- The final command reports whether a package has already requested a reboot.

Do not share unredacted package-source output if a repository URL contains
credentials or a private public-facing hostname.

## 2. Install prerequisites after approval

Package installation can restart affected services. Review the APT plan before
approving it:

```bash
sudo apt-get update
apt-get -s install unattended-upgrades reboot-notifier
```

If the simulation is acceptable:

```bash
sudo apt-get install unattended-upgrades reboot-notifier
```

`reboot-notifier` creates `/run/reboot-required` after relevant kernel
updates. Do not install `mailutils` for this workflow; notifications use
`raspi-notify`.

> [!WARNING]
> Install and successfully test the durable notification queue from
> [email.md](email.md) before continuing. Reboot alerts and weekly reports
> depend on it. Do not activate the update units until a test notification is
> delivered.

## 3. Validate the repository assets

On the Raspberry Pi:

```bash
cd ~/raspberry-born/src/maintenance/updates
sudo ./install-updates.sh --check
```

A successful check prints `Validation passed. No files were changed.` It
confirms that:

- required commands and packages are available
- the source scripts have valid Bash syntax
- the proposed APT policy selects Debian-Security
- automatic reboot is disabled
- the durable notification command is installed

## 4. Install the policy files

This writes configuration but does not enable timers, refresh package metadata,
install an update, restart a service, send email or reboot:

```bash
sudo ./install-updates.sh --apply
```

The installer creates a timestamped backup under
`/var/backups/raspi-update-policy/` and installs:

| Path | Purpose |
| --- | --- |
| `/etc/apt/apt.conf.d/20auto-upgrades` | Daily package-list refresh and unattended-upgrade interval |
| `/etc/apt/apt.conf.d/52unattended-upgrades-security` | Debian-Security-only origin and no-reboot policy |
| `/usr/local/sbin/raspi-update-report` | Reboot alerts, weekly simulations and policy checks |
| `/usr/local/sbin/raspi-configure-auto-reboot` | Explicitly check, enable, disable or roll back the optional reboot profile |
| `/usr/local/share/raspi-maintenance/53unattended-upgrades-auto-reboot` | Inactive template for the optional conditional reboot |
| `raspi-update-reboot-alert.path` | Detect `/run/reboot-required` |
| `raspi-update-weekly-report.timer` | Run the weekly report Sunday after 06:15 with a randomized delay |

If `apt-daily-upgrade.timer` is already active, the installed policy applies
to its next run.

## 5. Review and test before activation

Review the installed configuration with Vim:

```bash
sudo vim /etc/apt/apt.conf.d/20auto-upgrades
sudo vim /etc/apt/apt.conf.d/52unattended-upgrades-security
```

Verify the effective policy:

```bash
sudo /usr/local/sbin/raspi-update-report --check
sudo unattended-upgrade --dry-run --debug
```

Expected results:

- the policy check reports Debian-Security enabled and automatic reboot
  disabled
- the dry run installs nothing
- eligible packages, if any, come only from the configured Debian-Security
  origin
- ordinary and Raspberry Pi OS vendor updates remain outside the unattended
  selection

The debug output may be long. Review its allowed and rejected origins rather
than relying only on the final package count.

Test the reboot notification template without creating a reboot flag:

```bash
sudo /usr/local/sbin/raspi-update-report --simulate-reboot-required
```

Expected result:

```text
Queued simulated reboot-required notification
```

The received subject begins with `TEST`, and no package, service or reboot
state changes.

## 6. Activate after approval

Enabling the standard APT timers authorizes future automatic Debian-Security
installation. Enabling the repository units authorizes weekly metadata refresh
and report delivery:

```bash
sudo systemctl enable --now \
    apt-daily.timer \
    apt-daily-upgrade.timer \
    raspi-update-weekly-report.timer \
    raspi-update-reboot-alert.path
```

No reboot is configured. A package may still restart one of its own services
while being installed.

Verify activation:

```bash
systemctl is-enabled \
    apt-daily.timer \
    apt-daily-upgrade.timer \
    raspi-update-weekly-report.timer \
    raspi-update-reboot-alert.path

systemctl is-active \
    apt-daily.timer \
    apt-daily-upgrade.timer \
    raspi-update-weekly-report.timer \
    raspi-update-reboot-alert.path

systemctl list-timers \
    apt-daily.timer \
    apt-daily-upgrade.timer \
    raspi-update-weekly-report.timer --no-pager
```

Each unit should report `enabled` and `active`. The timer list should show a
future run for all three timers.

## 7. Test the weekly report

This command changes APT package-list metadata and sends a real report, but it
does not install or remove packages:

```bash
sudo systemctl start raspi-update-weekly-report.service
sudo systemctl status raspi-update-weekly-report.service --no-pager
sudo journalctl -u raspi-update-weekly-report.service \
    -t raspi-update-report --no-pager -n 100
```

Expected results:

- the oneshot service finishes as `inactive (dead)` with
  `status=0/SUCCESS`; this is normal
- the journal says that a weekly report was queued
- the email states `Packages installed: none; simulation only`
- pending install/upgrade and removal counts match a fresh
  `apt-get -s full-upgrade`

The report is keyed, so an undelivered older weekly report is replaced by the
newest one rather than building a stale backlog.

## 8. Respond to a reboot-required alert

When `/run/reboot-required` appears, the path unit queues one durable alert
for that boot. Inspect the request:

```bash
cat /run/reboot-required
if test -s /run/reboot-required.pkgs; then
    sort -u /run/reboot-required.pkgs
fi
systemctl --failed
```

Before rebooting a remote Raspberry Pi, verify its VPN, firewall, UPS and local
recovery path. Reboot only after explicit approval:

```bash
sudo systemctl reboot
```

After reconnecting:

```bash
test -e /run/reboot-required && echo "reboot still requested" || echo "reboot request cleared"
systemctl --failed
systemctl is-active ssh
```

The reboot flag should be absent, no units should be failed and SSH should be
active. Run the device-specific service checks from its runbook as well.

## 9. Optionally enable a conditional 04:45 reboot

Keep this disabled until the individual Raspberry Pi has completed a controlled
reboot test. Before enabling it, verify that:

- SSH and the required VPN path return without manual intervention
- firewall, Pi-hole, storage, UPS and device-specific services recover
- the Raspberry Pi can recover after a power interruption
- a local recovery method or person is available if remote access does not
  return
- notification delivery is working

Do not enable this profile on both VPN servers for the same maintenance window.
Start with one Raspberry Pi, observe at least one real update and reboot cycle,
then decide how the other server should be handled.

The optional process uses three `unattended-upgrades` settings:

```text
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-WithUsers "false";
Unattended-Upgrade::Automatic-Reboot-Time "04:45";
```

This is not an unconditional daily reboot. After an unattended upgrade,
`unattended-upgrades` schedules 04:45 only if `/run/reboot-required` exists.
Logged-in users prevent the automatic reboot. The reboot alert is still queued
when the flag first appears.

First inspect the current state. This command is read-only:

```bash
sudo raspi-configure-auto-reboot --check
```

Expected initial result:

```text
Managed file: absent
Automatic-Reboot: false
Result: automatic reboot is disabled
```

After explicitly approving future conditional reboots on this device, enable
the profile:

```bash
sudo raspi-configure-auto-reboot --enable
sudo raspi-configure-auto-reboot --check
```

The helper backs up the previous state under `/var/backups/raspi-auto-reboot/`,
installs only
`/etc/apt/apt.conf.d/53unattended-upgrades-auto-reboot`, and validates the
effective APT settings. It does not immediately run an update or reboot. If
`/run/reboot-required` already exists, however, a later unattended-upgrade run
may schedule the 04:45 reboot.

The final check should report:

```text
Managed file: present
Automatic-Reboot: true
Automatic-Reboot-WithUsers: false
Automatic-Reboot-Time: 04:45
Result: conditional automatic reboot is enabled for 04:45
```

To disable future automatic reboots while keeping security updates active:

```bash
sudo raspi-configure-auto-reboot --disable
sudo raspi-configure-auto-reboot --check
```

To restore the exact state from before an enable or disable operation, use the
backup path printed by that operation:

```bash
sudo raspi-configure-auto-reboot --rollback \
    /var/backups/raspi-auto-reboot/YYYYMMDD-HHMMSS
```

After a real automatic reboot, reconnect and run the post-reboot checks from
the previous section. The weekly report is scheduled after 06:15 on Sunday, so
it does not compete with the 04:45 reboot window.

## 10. Perform the broader maintenance upgrade

Use the weekly report to avoid accumulating several months of changes. Handle
one Raspberry Pi at a time.

First refresh and inspect:

```bash
sudo apt-get update
apt-mark showhold
df -h /
sudo dpkg --audit
sudo apt-get -s full-upgrade
```

Expected results before proceeding:

- package-list refresh succeeds
- held packages are understood
- the root filesystem has enough free space
- `dpkg --audit` prints nothing
- the simulated additions, upgrades and removals are acceptable

Stop important workloads and ensure configuration and data backups are current.
Then, after explicit approval:

```bash
sudo apt full-upgrade
```

Do not use `-y` here. Review package removals and configuration questions
interactively.

Afterward:

```bash
sudo dpkg --audit
systemctl --failed
test -e /run/reboot-required && echo "reboot required" || echo "no reboot requested"
sudo /usr/local/sbin/raspi-update-report --reboot-required
```

Investigate any `dpkg --audit` output or failed unit before updating another
Raspberry Pi. If a reboot is required, follow the previous section.

This procedure updates within the current major OS version. Do not change APT
sources to a new Debian or Raspberry Pi OS codename as part of routine
maintenance.

## 11. Logs and troubleshooting

Inspect unattended-upgrade and report activity:

```bash
sudo journalctl \
    -u apt-daily-upgrade.service \
    -u raspi-update-weekly-report.service \
    -u raspi-update-reboot-alert.service --no-pager -n 200

sudo tail -n 100 /var/log/unattended-upgrades/unattended-upgrades.log
sudo tail -n 100 /var/log/unattended-upgrades/unattended-upgrades-dpkg.log
```

Useful checks:

```bash
sudo unattended-upgrade --dry-run --debug
apt-config dump | grep -E '^(APT::Periodic|Unattended-Upgrade::)'
systemctl list-timers apt-daily.timer apt-daily-upgrade.timer --no-pager
```

## 12. Roll back repository-managed files

Use the exact backup path printed by `--apply`:

```bash
cd ~/raspberry-born/src/maintenance/updates
sudo ./install-updates.sh --rollback \
    /var/backups/raspi-update-policy/YYYYMMDD-HHMMSS
```

Rollback restores only the managed policy, report command and unit files. It
reloads systemd metadata but does not disable timers, remove packages, undo
already installed updates, restore APT metadata or delete queued
notifications. Review timer state and the restored policy afterward.
