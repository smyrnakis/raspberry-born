# Hardware watchdog and service recovery

A hardware watchdog resets the Raspberry Pi if the process responsible for
feeding `/dev/watchdog` stops doing so. It can recover from a kernel hang or a
fully stalled userspace, but it is not automatically the right tool for every
service or network failure.

Keep these three mechanisms distinct:

1. The hardware watchdog resets an unresponsive Raspberry Pi.
2. systemd restarts an individual failed service.
3. An application health monitor verifies behavior such as DNS answers, MQTT
   traffic, VPN reachability or UPS communication.

Do not let both systemd and the `watchdog` daemon manage the same hardware
watchdog device. Choose one owner after completing the read-only audit.

References:

- [Raspberry Pi `config.txt` documentation](https://www.raspberrypi.com/documentation/computers/config_txt.html)
- [Debian `watchdog.conf` manual](https://manpages.debian.org/trixie/watchdog/watchdog.conf.5.en.html)
- [Debian `watchdog` daemon manual](https://manpages.debian.org/trixie/watchdog/watchdog.8.en.html)
- [Linux kernel watchdog documentation](https://www.kernel.org/doc/html/latest/watchdog/)
- [systemd service watchdog documentation](https://github.com/systemd/systemd/blob/main/man/systemd.service.xml)

## 1. Audit the current Raspberry Pi

All commands in this section are read-only:

```bash
cat /proc/device-tree/model; echo
uname -a
ls -l /dev/watchdog* 2>/dev/null || true
sudo wdctl /dev/watchdog0 2>/dev/null || true
cat /sys/class/watchdog/watchdog0/identity 2>/dev/null || true
sudo dmesg | grep -i watchdog || true
systemctl show \
    --property=RuntimeWatchdogUSec \
    --property=RebootWatchdogUSec
systemctl status watchdog.service --no-pager 2>/dev/null || true
systemctl cat watchdog.service 2>/dev/null || true
sudo fuser -v /dev/watchdog /dev/watchdog0 2>/dev/null || true
```

Interpretation:

- `/dev/watchdog0` is the kernel watchdog device. `/dev/watchdog` is normally a
  compatibility link to it.
- `wdctl` reports the active driver identity, current timeout and device state.
- A non-zero `RuntimeWatchdogUSec` means systemd is configured to feed a
  hardware watchdog.
- An active `watchdog.service` means the separate Debian daemon may own it.
- `fuser` identifies a process that currently has the device open.

Identify the boot configuration without assuming the operating-system version:

```bash
BOOT_CONFIG=""
if [[ -f /boot/firmware/config.txt ]]; then
    BOOT_CONFIG=/boot/firmware/config.txt
elif [[ -f /boot/config.txt ]]; then
    BOOT_CONFIG=/boot/config.txt
else
    echo "No Raspberry Pi boot configuration found" >&2
fi

if [[ -n "$BOOT_CONFIG" ]]; then
    printf 'Boot configuration: %s\n' "$BOOT_CONFIG"
    grep -nE '^[[:space:]]*(kernel_watchdog_timeout|dtparam=watchdog)=' \
        "$BOOT_CONFIG" || true
fi
```

Current Raspberry Pi OS releases use `/boot/firmware/config.txt`. Older images
may use `/boot/config.txt`. Stop if neither file exists.

## 2. Choose the owner and boot method

Choose the owner before changing `config.txt`:

- For the systemd option, current Raspberry Pi firmware documentation prefers
  `kernel_watchdog_timeout` because it keeps the watchdog active during the
  handoff from firmware to the operating system.
- For the classic Debian `watchdog` daemon, use the hardware device exposed by
  the platform and let that daemon arm it. `dtparam=watchdog=on` remains the
  legacy or fallback method when the device is not already exposed.

Do not configure both boot methods or both runtime owners. Exact firmware
support varies with Raspberry Pi model, firmware and operating-system image, so
the audit output is part of the decision.

## 3. Configure the chosen owner

### Option A: systemd for system-hang recovery

This is the simpler choice when the goal is to reset the Raspberry Pi only if
PID 1 can no longer feed the hardware watchdog. Do not install or enable the
separate `watchdog` daemon for this option.

Create the manager drop-in before enabling the firmware handoff:

```bash
sudo install -d -o root -g root -m 755 /etc/systemd/system.conf.d
sudo vim /etc/systemd/system.conf.d/10-hardware-watchdog.conf
```

Example:

```ini
[Manager]
RuntimeWatchdogSec=15s
RebootWatchdogSec=5min
```

Back up and edit the resolved boot configuration:

```bash
sudo cp -a -- "$BOOT_CONFIG" \
    "$BOOT_CONFIG.before-watchdog.$(date +%Y%m%d-%H%M%S)"
sudo vim "$BOOT_CONFIG"
```

While Vim is open, search for an existing setting with
`/kernel_watchdog_timeout`. Do not create a duplicate. If it does not exist,
add the following line in the `[all]` section so it applies to every boot:

```text
kernel_watchdog_timeout=15
```

If the file has no `[all]` section, append an `[all]` header and then the
setting at the end of the file.

If the setting already exists, review its value and change that line instead.
Save and close Vim with `:wq`. Confirm the resulting active line before
rebooting:

```bash
grep -nE '^[[:space:]]*kernel_watchdog_timeout=' "$BOOT_CONFIG"
```

Expect exactly one active line containing `kernel_watchdog_timeout=15`.

This is preferred to `dtparam=watchdog=on` for the systemd-owned path. On an
older image that does not support it, stop and confirm the model-specific
fallback before substituting the legacy parameter.

`RuntimeWatchdogSec` is the maximum time the hardware may go without a keepalive
before resetting the system. systemd feeds it at least twice within that period.
The hardware driver may select the closest timeout it supports.

`RebootWatchdogSec` is a separate safety net for a reboot that stalls during
the late shutdown phase.

Applying manager watchdog settings requires a manager re-execution or reboot.
For a remote Raspberry Pi, prefer a planned reboot after reviewing the file and
ensuring another access path is available:

```bash
sudo reboot
```

After it returns:

```bash
systemctl show \
    --property=RuntimeWatchdogUSec \
    --property=RebootWatchdogUSec
sudo wdctl /dev/watchdog0
sudo fuser -v /dev/watchdog0
```

Expected results:

- `RuntimeWatchdogUSec` is non-zero and corresponds to the requested timeout.
- `wdctl` shows the watchdog active; the effective timeout may be rounded by
  the driver.
- PID 1 (`systemd`) owns the device.

### Option B: Debian `watchdog` daemon for additional checks

Use the daemon only when its host, process, file or network checks are genuinely
needed. First verify that the systemd-owned path is disabled:

```bash
grep -nE '^[[:space:]]*kernel_watchdog_timeout=' "$BOOT_CONFIG" || true
systemctl show --property=RuntimeWatchdogUSec
```

For this documented classic-daemon path, the first command should print
nothing, or show an explicitly disabled value of `0`. The second should print
`RuntimeWatchdogUSec=0`.

If either value is non-zero, the Raspberry Pi is configured for the systemd
path. Do not start the classic daemon. To migrate deliberately:

1. Back up and edit `config.txt`, then remove the active
   `kernel_watchdog_timeout` line or set it to `0`.
2. Back up and edit the systemd manager drop-in, then remove
   `RuntimeWatchdogSec` or set it to `off`.
3. Add `dtparam=watchdog=on` if `/dev/watchdog0` is not otherwise exposed.
4. Review all three changes and perform one approved controlled reboot.
5. Re-run the audit and require `RuntimeWatchdogUSec=0` before installing or
   starting `watchdog.service`.

If `/dev/watchdog0` is absent, back up the resolved boot configuration, add the
legacy device-tree parameter once and perform an approved controlled reboot:

```bash
sudo cp -a -- "$BOOT_CONFIG" \
    "$BOOT_CONFIG.before-watchdog.$(date +%Y%m%d-%H%M%S)"
sudo vim "$BOOT_CONFIG"
```

```text
dtparam=watchdog=on
```

```bash
sudo reboot
```

After reconnecting, require a valid device before installing the daemon:

```bash
ls -l /dev/watchdog*
sudo wdctl /dev/watchdog0
cat /sys/class/watchdog/watchdog0/identity
```

Do not add `kernel_watchdog_timeout` for this classic-daemon procedure. That
firmware option is intended to keep the watchdog armed until systemd takes
ownership, while this procedure deliberately assigns ownership to
`watchdog.service` instead.

Review and install the package only after approval:

```bash
apt-get --simulate install watchdog
sudo apt-get install watchdog
```

Back up and edit its configuration:

```bash
sudo cp -a /etc/watchdog.conf \
    "/etc/watchdog.conf.before-local.$(date +%Y%m%d-%H%M%S)"
sudo vim /etc/watchdog.conf
```

Start with hardware keepalive only:

```ini
watchdog-device = /dev/watchdog
watchdog-timeout = 15
interval = 5
realtime = yes
```

The interval must remain comfortably below the effective hardware timeout.
Fifteen seconds is a common Raspberry Pi watchdog timeout, but `wdctl` and the
service journal are authoritative for the actual device. Do not add load,
network or service checks until the basic configuration has run reliably.

Test configuration and checks without arming the hardware or rebooting:

```bash
sudo timeout 30s watchdog \
    --no-action \
    --foreground \
    --verbose \
    --config-file /etc/watchdog.conf
```

`--no-action` prevents watchdog from enabling the hardware device or initiating
a reboot. It can still invoke configured repair programs, so do not use this
test after adding a `repair-binary` unless that program has been reviewed.

Enabling or starting the service arms the hardware watchdog. Do this only after
the no-action test passes and a recovery path is available:

```bash
sudo systemctl enable --now watchdog.service
systemctl is-enabled watchdog.service
systemctl is-active watchdog.service
sudo wdctl /dev/watchdog0
sudo journalctl -u watchdog.service --no-pager -n 50
```

Expect `enabled`, `active`, an active watchdog device and no repeated check or
keepalive errors.

## Common `watchdog.conf` parameters

Keep optional checks disabled unless a failure truly justifies rebooting the
whole Raspberry Pi.

| Parameter | Meaning and caution |
| --- | --- |
| `watchdog-device` | Hardware device to feed, normally `/dev/watchdog` or `/dev/watchdog0`. |
| `watchdog-timeout` | Requested hardware reset timeout in seconds. The driver may clamp it to a supported value. |
| `interval` | Sleep time between complete check cycles. It must be safely shorter than the hardware timeout. |
| `retry-timeout` | How long most failed checks may remain failed before action is taken. Use this to tolerate short interruptions. |
| `realtime` | `yes` locks the daemon into memory and gives it real-time scheduling support. |
| `priority` | Real-time scheduling priority. Leave the packaged default unless testing proves a change is necessary. |
| `max-load-1`, `max-load-5`, `max-load-15` | Reboot when load reaches the threshold. Disabled at `0`. Avoid arbitrary values because legitimate workloads can cause reboot loops. |
| `min-memory` | Minimum free memory expressed in memory pages, not MiB. Check `getconf PAGESIZE` before calculating a value. |
| `allocatable-memory` | Actively tests whether a number of memory pages can be allocated. Disabled at `0`. |
| `max-swap` | Maximum used swap in pages. Consider slow storage and zram behavior before enabling it. |
| `temperature-sensor` | Path to a milli-Celsius sensor file below `/sys`; may be specified more than once. Device numbering can change. |
| `max-temperature` | Temperature threshold in degrees Celsius. Reaching it stops or powers off the system rather than merely restarting a service. |
| `file` and `change` | Confirm a file exists and, optionally, that its modification time advances within a limit. Each `change` applies to the preceding `file`. |
| `pidfile` | Confirm that the process recorded in a real PID file still exists. Many modern systemd services do not create PID files. |
| `ping` and `ping-count` | Require one or more IPv4 destinations to answer. A router, firewall rule or remote outage can otherwise create a reboot loop. |
| `interface` | Require received traffic on a physical interface such as `eth0` or `wlan0`. This monitors traffic, not driver health, and a quiet network can trigger it. |
| `test-binary` and `test-timeout` | Run a custom health check with a bounded execution time. Any non-zero result is treated as a fault. |
| `repair-binary`, `repair-timeout`, `repair-maximum` | Attempt a reviewed repair before rebooting. A faulty repair program can delay recovery or create loops. |
| `test-directory` | Directory of executable test/repair programs, normally `/etc/watchdog.d`. Review every executable before enabling it. |
| `verbose` and `logtick` | Control diagnostic logging. High verbosity produces substantial journal traffic. |

Read the installed manual for the exact package version before using a less
common setting:

```bash
man watchdog.conf
man watchdog
```

## Network interfaces and drivers

These optional examples are intentionally commented:

```ini
# interface = eth0
# interface = wlan0
# ping = REPLACE_WITH_A_RELIABLE_LOCAL_GATEWAY_IP
# ping-count = 3
# retry-timeout = 60
```

An `interface` check passes when the physical interface receives traffic. It
does not prove that DHCP, DNS, routing, OpenVPN or Internet access works.
Likewise, failure to ping one device does not prove the Raspberry Pi is broken.

For remote systems, a network failure should normally trigger a bounded repair
and notification before any reboot. The general OpenVPN, camera and UPS
watchdogs should remain separate because each has different evidence and safe
recovery actions.

## Monitoring common services

Use systemd for process recovery and a protocol-specific monitor for functional
health. Common service units in this project include:

| Function | Typical unit | Appropriate check |
| --- | --- | --- |
| SSH | `ssh.service` | Process state plus a separate remote-access test; avoid restarting it casually during a remote session. |
| OpenVPN server | `openvpn-server@NAME.service` | Unit state plus tunnel and route checks. |
| OpenVPN client | `openvpn-client@NAME.service` | Unit state plus peer reachability through the tunnel. |
| Pi-hole DNS | `pihole-FTL.service` | Unit state plus a local DNS query. |
| Mosquitto | `mosquitto.service` | Unit state plus an authenticated publish/subscribe test when appropriate. |
| NUT monitor | `nut-monitor.service` | Unit state plus `upsc` communication; UPS communication loss alone should not reboot the Raspberry Pi. |

Inspect a service before changing it:

```bash
SERVICE=pihole-FTL.service
systemctl cat "$SERVICE"
systemctl show "$SERVICE" \
    --property=Type \
    --property=Restart \
    --property=RestartUSec \
    --property=WatchdogUSec
systemctl status "$SERVICE" --no-pager
```

For a compatible long-running service, a reviewed override may use
`Restart=on-failure` and a bounded `RestartSec`. Do not add `WatchdogSec` unless
the daemon explicitly supports systemd watchdog notifications. `WatchdogSec`
does not make systemd probe the service by itself; the daemon must regularly
send `WATCHDOG=1` notifications.

Any override requires separate review and normally a service restart. Do not
apply one generically to all services.

## Controlled reset test

Do not use a fork bomb. It can exhaust resources, corrupt work and obscure what
is actually being tested.

A real hardware-watchdog reset is intentionally disruptive. Perform it only
after backups, filesystem checks, local or out-of-band recovery access and an
explicit reboot approval.

For the classic `watchdog` daemon only, a controlled test can stop the daemon
from sending keepalives without exhausting the rest of the system:

```bash
pid=$(systemctl show watchdog.service --property=MainPID --value)
test "$pid" -gt 1
sync
sudo kill -STOP "$pid"
```

If the watchdog is armed correctly, the Raspberry Pi should reset after the
effective hardware timeout. The SSH connection will drop. Do not run this when
systemd owns the watchdog device, on a production system without recovery
access, or while storage maintenance is in progress.

After reconnecting:

```bash
uptime -s
systemctl is-active watchdog.service
sudo wdctl /dev/watchdog0
sudo journalctl -b -u watchdog.service --no-pager
```

Expect a recent boot time, an active service, an active hardware watchdog and no
repeated startup errors. Previous-boot logs are available only when the journal
is persistent.
