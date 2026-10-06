# UPS monitoring with NUT

*NUT documentation: https://networkupstools.org/documentation*

*NUT USB troubleshooting: https://networkupstools.org/docs/FAQ.html*

<br>

This guide installs and configures [Network UPS Tools (NUT)](https://networkupstools.org/) for a USB-connected UPS.

The example below was tested with a Megatec-compatible UPS detected as `0665:5161 Cypress Semiconductor USB to Serial` and the `nutdrv_qx` driver.

The service commands assume NUT 2.8 with systemd driver instances, as used on
current Raspberry Pi OS releases. Inspect the installed NUT version and unit
names before adapting the procedure to an older release.

## Installation

Connect the UPS USB cable and check that the operating system detects it:

```bash
lsusb
sudo dmesg | tail -50
```

Install NUT and scan for a compatible UPS:

```bash
sudo apt-get update
sudo apt-get install nut
sudo nut-scanner -U
```

Example scan result:

```text
Scanning USB bus.
[nutdev1]
        driver = "nutdrv_qx"
        port = "auto"
        vendorid = "0665"
        productid = "5161"
```

The warning about a missing IPMI library can be ignored when using a USB UPS.

## Configuration

Edit `/etc/nut/ups.conf`:

```bash
sudo vim /etc/nut/ups.conf
```

Add:

```ini
maxretry = 3

[myups]
    driver = nutdrv_qx
    port = auto
    vendorid = 0665
    productid = 5161
    desc = "UPS connected to Raspberry Pi"
```

Do not add USB bus or device numbers because they may change after a reboot or reconnection.

Edit `/etc/nut/nut.conf`:

```bash
sudo vim /etc/nut/nut.conf
```

Set:

```ini
MODE=standalone
```

Edit `/etc/nut/upsd.users`:

```bash
sudo vim /etc/nut/upsd.users
```

Add a monitoring user:

```ini
[monuser]
    password = ReplaceWithAnAlphanumericPassword
    upsmon primary
```

Edit `/etc/nut/upsmon.conf`:

```bash
sudo vim /etc/nut/upsmon.conf
```

Add or replace the `MONITOR` entry:

```ini
MONITOR myups@localhost 1 monuser ReplaceWithAnAlphanumericPassword primary
```

Use the same password in `upsd.users` and `upsmon.conf`.

## Apply USB permissions

Reload the NUT USB permissions and re-detect the device:

```bash
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=usb --action=change
sudo udevadm settle
```

This is especially important when the UPS was already connected while NUT was installed. Unplugging and reconnecting only the USB cable has the same effect.

## Enable and start NUT

Create the driver service and start NUT:

```bash
sudo upsdrvsvcctl resync
sudo upsdrvsvcctl start myups
sudo systemctl enable nut-server nut-monitor
sudo systemctl restart nut-server nut-monitor
```

Check the services:

```bash
systemctl is-active nut-driver@myups.service nut-server nut-monitor
systemctl is-enabled nut-server nut-monitor
```

Expected result:

```text
active
active
active
enabled
enabled
```

## Check UPS status

```bash
upsc myups@localhost
```

Example output:

```text
Init SSL without certificate database
battery.charge: 100
battery.voltage: 27.0
battery.voltage.high: 26.00
battery.voltage.low: 20.80
battery.voltage.nominal: 24.0
device.type: ups
driver.debug: 0
driver.flag.allow_killpower: 0
driver.name: nutdrv_qx
driver.parameter.pollfreq: 30
driver.parameter.pollinterval: 2
driver.parameter.port: auto
driver.parameter.productid: 5161
driver.parameter.synchronous: auto
driver.parameter.vendorid: 0665
driver.state: quiet
driver.version: 2.8.1
driver.version.data: Megatec 0.07
driver.version.internal: 0.36
driver.version.usb: libusb-1.0.28 (API: 0x100010a)
input.current.nominal: 5.0
input.frequency: 50.0
input.frequency.nominal: 50
input.voltage: 235.0
input.voltage.fault: 0.0
input.voltage.nominal: 220
output.voltage: 235.0
ups.beeper.status: enabled
ups.delay.shutdown: 30
ups.delay.start: 180
ups.firmware: V3.65
ups.load: 8
ups.productid: 5161
ups.status: OL
ups.temperature: 20.8
ups.type: offline / line interactive
ups.vendorid: 0665
```

`Init SSL without certificate database` is informational and can be ignored for a local `localhost` connection.

Important values:

- `battery.charge` : estimated battery charge percentage
- `battery.voltage` : current battery-pack voltage
- `battery.voltage.high` / `battery.voltage.low` : voltage values used for charge estimation
- `battery.voltage.nominal` : nominal battery-pack voltage
- `input.frequency` : utility power frequency in Hz; normally close to `50.0`
- `input.voltage` : current utility voltage; normally around `230 V` in Europe
- `input.voltage.fault` : input voltage recorded during the last transfer or fault
- `output.voltage` : voltage supplied by the UPS
- `ups.beeper.status` : audible alarm state
- `ups.delay.shutdown` : delay after NUT sends a shutdown command before the UPS turns off its output; a normal power failure does not start this timer
- `ups.delay.start` : delay after utility power is available before the UPS restores its output
- `ups.firmware` : UPS firmware version
- `ups.load` : current load as a percentage of UPS capacity
- `ups.temperature` : reported UPS temperature in Celsius
- `driver.*` : NUT driver version, state and communication settings
- `driver.flag.allow_killpower: 0` : safety lock preventing direct UPS output shutdown commands; it does not prevent the system from shutting down

Charge, load and temperature can be approximate on generic Megatec devices. If `battery.runtime` is absent, the UPS does not provide an estimated number of remaining seconds.

Common status values:

- `OL` : utility power is online
- `OB` : UPS is running on battery
- `LB` : battery is low
- `CHRG` : battery is charging
- `DISCHRG` : battery is discharging
- `RB` : battery should be replaced
- `BYPASS` : bypass mode is active
- `BOOST` / `TRIM` : automatic voltage regulation is increasing or reducing voltage

Query individual values:

```bash
upsc myups@localhost ups.status
upsc myups@localhost battery.charge
upsc myups@localhost battery.voltage
upsc myups@localhost ups.load
upsc myups@localhost input.voltage
```

## Test a power failure

Monitor the complete status:

```bash
watch -n 2 upsc myups@localhost
```

Disconnect only the UPS wall input. Keep the Raspberry Pi connected to a battery-backed UPS outlet.

Expected changes:

```text
ups.status: OB
input.voltage: 0.0
```

Reconnect utility power after 20 to 30 seconds. The status should return to:

```text
ups.status: OL
```

Do not wait for a low-battery condition during the first test. When the UPS eventually reports `LB`, `upsmon` will initiate a clean system shutdown.

## Automatic shutdown and restart

The following configuration was verified on this installation:

```text
SHUTDOWNCMD "/sbin/shutdown -h +0"
POWERDOWNFLAG "/etc/killpower"
FINALDELAY 5
MODE=standalone
```

The `nutshutdown` systemd hook is installed at `/usr/lib/systemd/system-shutdown/nutshutdown`, no `stayoff` option is configured, and the driver advertises support for `shutdown.return`.

When the UPS reports both `OB` and `LB`, the expected sequence is:

1. NUT waits for `FINALDELAY`, which is 5 seconds.
2. `upsmon` starts a normal system shutdown using `SHUTDOWNCMD`.
3. The system stops services and synchronises/unmounts its filesystems.
4. `upsmon` creates `/etc/killpower` to mark this as a UPS-triggered shutdown.
5. Late in the system shutdown, `nutshutdown` sends `shutdown.return` to the UPS.
6. The UPS waits for `ups.delay.shutdown`, which is 30 seconds, then turns off its output.
7. After the UPS detects utility power returning, it waits for `ups.delay.start`, which is 180 seconds, then should restore its output.
8. The Raspberry Pi boots automatically when power is restored.

If utility power returns after the critical shutdown has started, NUT does not cancel the sequence. It continues through the shutdown and requests an off/on power cycle so the Raspberry Pi does not remain halted while still powered.

> `upsc` confirms that monitoring works, but it cannot prove that the UPS firmware correctly performs `shutdown.return`. A complete shutdown test is required for that.

`POWEROFF_WAIT` is not configured. This optional fallback can reboot a system that remains powered because the UPS failed to cut its output. Do not configure it until the complete test is performed and a safe timeout can be chosen based on the battery runtime remaining at `LB`.

### Dry run versus complete test

The following command is a dry run:

```bash
sudo upsdrvctl -t shutdown
```

It parses the configuration and displays the driver shutdown action that would be attempted. It does **not** set the forced-shutdown state, shut down the Raspberry Pi, create `/etc/killpower`, send a shutdown command to the UPS or interrupt its output. It checks the planned driver action, not the UPS firmware behaviour.

The following command performs the complete shutdown sequence:

```bash
sudo upsmon -c fsd
```

`fsd` means *forced shutdown*. It sets the NUT forced-shutdown state, runs `SHUTDOWNCMD`, creates the power-down flag and allows the late systemd hook to command the UPS output off. This command intentionally shuts down the Raspberry Pi and may remove power from every device connected to the UPS.

### Complete shutdown and restart test

> **WARNING:** The complete test interrupts power and cannot normally be cancelled after it starts. Stop important workloads, ensure backups are current, disconnect any device that must remain powered and have physical access to the Raspberry Pi and UPS. The SSH connection will be lost.

First run the harmless dry run:

```bash
sudo upsdrvctl -t shutdown
```

This UPS was first tested with utility power continuously connected. The Raspberry Pi shut down cleanly and `shutdown.return` turned the 220 V output completely off, but the UPS remained off for more than ten minutes. It restarted only after its power button was held. This proves that shutdown and output removal work, but this firmware does not automatically restart after an online `FSD` test where utility power never disappeared.

The automatic-restart test must therefore reproduce a real outage. In one terminal, monitor the UPS:

```bash
watch -n 2 upsc myups@localhost
```

Disconnect the UPS input from utility power while keeping the Raspberry Pi connected to a battery-backed outlet. Confirm:

```text
ups.status: OB
```

In a second SSH session, start the complete shutdown:

```bash
sudo upsmon -c fsd
```

Wait until the Raspberry Pi has shut down and the UPS has turned its output completely off. Only then reconnect the UPS input to utility power. This creates the missing-power and power-return transition that `shutdown.return` is designed to use.

Expected result:

1. The Raspberry Pi shuts down cleanly.
2. The UPS output switches off after the configured shutdown delay.
3. Utility power is reconnected after the UPS output is off.
4. The UPS detects utility power returning.
5. The UPS output returns after the configured start delay.
6. The Raspberry Pi boots normally.
7. NUT reconnects to the UPS and reports `ups.status: OL`.

After the Raspberry Pi returns, verify it:

```bash
systemctl is-active nut-driver@myups.service nut-server nut-monitor
upsc myups@localhost ups.status
sudo test -e /etc/killpower && echo "killpower flag remains"
sudo journalctl -b -u nut-monitor --no-pager
```

Expected results:

| Command | Successful result |
| --- | --- |
| `systemctl is-active ...` | Prints `active` for the UPS driver, NUT server and NUT monitor. Each requested unit produces one line in the same order. |
| `upsc myups@localhost ups.status` | Includes `OL`, meaning the UPS is online and utility power is present. Additional flags such as `CHRG` may also appear while the battery is charging. |
| `test -e /etc/killpower ...` | Prints nothing. `killpower flag remains` means the shutdown flag is still present and must be investigated before relying on the next automated shutdown. |
| `journalctl -b ...` | Shows `nut-monitor` starting during the current boot, with no repeated communication, authentication or service failures. |

If the UPS output remains off for more than the configured start delay after utility power is reconnected, turn it on manually and do not rely on automatic unattended recovery. On systems configured with volatile journaling, the previous boot is not retained; use the shutdown emails and current-boot checks as the operational record.

## Optional durable notifications and UPS monitoring

NUT already performs the safety-critical shutdown. The optional repository
monitor adds:

- immediate notifications for power, low-battery, shutdown and battery events
- one-minute polling to detect missed events and communication failures
- status updates every five minutes while the UPS remains on battery
- a recovery summary with total outage duration, battery levels and detected
  shutdown/restart activity
- increasing reminders while UPS communication remains unavailable
- a voltage-trend runtime estimate when the UPS does not report
  `battery.runtime`
- boot-bound shutdown warnings which are discarded after a restart instead of
  arriving late and out of context

The event hook stores NUT events in a protected persistent inbox. A systemd path
unit starts the root-owned monitor, so the unprivileged `nut` account never
needs access to SMTP credentials. Notifications use the common durable queue
from [email.md](email.md).

### Notification layout and subjects

UPS subjects remain short and contain no timestamp or incident ID:

```text
[HOSTNAME] UPS | Power lost
[HOSTNAME] UPS | On battery 5 min
[HOSTNAME] UPS | LOW BATTERY
[HOSTNAME] UPS | Shutdown initiated
[HOSTNAME] UPS | Power restored after 18 min
```

On-battery and restoration subjects use elapsed whole minutes without seconds.
The body retains exact timestamps and durations. High-priority information is
shown first, followed by separated `CURRENT CONDITION`, `POWER`, `UPS DETAILS`
and `NUT SERVICES` sections. The restoration message adds an `OUTAGE SUMMARY`
containing the total duration, battery levels and shutdown/restart evidence.

`Shutdown initiated` is a best-effort pre-shutdown warning. It is queued with
the current Linux boot ID and may retry while that boot remains active. If it
was not delivered before the Raspberry Pi shut down, the dispatcher discards
it on the next boot. Power-loss, low-battery, restoration and communication
messages remain durable. The restoration summary still records when shutdown
was initiated and whether a subsequent boot was detected.

### Prepare the local configuration

Install and verify the durable notification queue first. On the Raspberry Pi,
open the UPS assets from the repository:

```bash
cd ~/raspberry-born/src/ups
cp ups-monitor.conf.example ups-monitor.conf
vim ups-monitor.conf
```

The ignored `ups-monitor.conf` file contains no secrets, but remains local
because unit names and timing choices may differ between installations.

| Setting | Purpose |
| --- | --- |
| `UPS_NAME` | NUT data-source name, normally `myups@localhost`. |
| `UPS_DRIVER_SERVICE` | Driver unit shown in reports, such as `nut-driver@myups.service`. |
| `NUT_SERVER_SERVICE` | NUT data-server unit, normally `nut-server.service`. |
| `NUT_MONITOR_SERVICE` | NUT shutdown-monitor unit, normally `nut-monitor.service`. |
| `COMM_FAILURE_CHECKS` | Failed one-minute polls required before declaring an incident. |
| `BATTERY_UPDATE_SECONDS` | Interval between fresh on-battery status reports. |
| `RUNTIME_ESTIMATE_*` | Sampling window and quality limits for voltage-trend estimates. |
| `COMM_REMINDER_OFFSETS_SECONDS` | Reminder times measured from the start of a communication incident. |
| `COMM_MONTHLY_REMINDER_SECONDS` | Repeating interval after the listed reminder offsets are exhausted. |

Values are literal `KEY=value` entries. Do not use shell variables or command
substitution.

### Validate without changing the Raspberry Pi

Run the installer in its default read-only mode:

```bash
sudo ./install-ups-monitor.sh --check
```

A successful check confirms that:

- all source scripts have valid Bash syntax
- the local configuration contains only known, valid keys
- `raspi-notify`, NUT commands, the `nut` group and
  `/etc/nut/upsmon.conf` exist
- the configured UPS responds to `upsc`
- no external `NOTIFYCMD` or overlapping `NOTIFYFLAG` entries would be
  replaced

If a notification command or flag already exists, stop and review that
integration. The installer deliberately refuses to overwrite it.

### Install the files

This is a configuration change, but it does not yet restart NUT or activate the
monitor:

```bash
sudo ./install-ups-monitor.sh --apply
```

The installer creates a timestamped backup under
`/var/backups/raspi-ups-monitor/`, installs the commands and systemd units,
and appends this marked block to `/etc/nut/upsmon.conf`:

```ini
# BEGIN RASPI UPS MONITOR
NOTIFYCMD "/usr/local/sbin/raspi-ups-event-hook"
NOTIFYFLAG ONLINE   SYSLOG+WALL+EXEC
NOTIFYFLAG ONBATT   SYSLOG+WALL+EXEC
NOTIFYFLAG LOWBATT  SYSLOG+WALL+EXEC
NOTIFYFLAG FSD      SYSLOG+WALL+EXEC
NOTIFYFLAG SHUTDOWN SYSLOG+WALL+EXEC
NOTIFYFLAG COMMBAD  SYSLOG+EXEC
NOTIFYFLAG COMMOK   SYSLOG+EXEC
NOTIFYFLAG NOCOMM   SYSLOG+EXEC
NOTIFYFLAG REPLBATT SYSLOG+EXEC
# END RASPI UPS MONITOR
```

Review the installed files before activation:

```bash
sudo vim /etc/raspi-ups-monitor/ups-monitor.conf
sudo vim /etc/nut/upsmon.conf
sudo systemd-analyze verify \
    /etc/systemd/system/raspi-ups-monitor.service \
    /etc/systemd/system/raspi-ups-monitor.timer \
    /etc/systemd/system/raspi-ups-monitor.path
```

The verification command should return without an error. Warnings about
unrelated installed units must be assessed separately.

### Activate after approval

Restarting `nut-monitor` briefly interrupts UPS event monitoring. Do this only
after reviewing the configuration and choosing an appropriate maintenance
window:

```bash
sudo systemctl enable --now \
    raspi-ups-monitor.timer \
    raspi-ups-monitor.path
sudo systemctl restart nut-monitor
```

Check the result:

```bash
systemctl is-enabled \
    raspi-notify-dispatcher.timer \
    raspi-ups-monitor.timer \
    raspi-ups-monitor.path
systemctl is-active \
    raspi-notify-dispatcher.timer \
    raspi-ups-monitor.timer \
    raspi-ups-monitor.path
sudo /usr/local/sbin/raspi-ups-monitor --check
systemctl list-timers \
    raspi-notify-dispatcher.timer \
    raspi-ups-monitor.timer --no-pager
```

Expected results:

- each `is-enabled` line is `enabled`
- each `is-active` line is `active`
- `--check` reports healthy communication and prints the current UPS snapshot
- the timer list shows a future run for both timers

Inspect pending notifications and recent logs:

```bash
sudo find /var/spool/raspi-notify/queue \
    -mindepth 1 -maxdepth 1 -type d -printf '%f\n'
sudo find /var/lib/raspi-ups-monitor/events \
    -mindepth 1 -maxdepth 1 -type f -name '*.event' -printf '%f\n'
sudo journalctl \
    -t raspi-ups-monitor \
    -t raspi-notify-dispatcher --no-pager -n 100
```

Both lists are normally empty after successful processing. Queue entries mean
email is still waiting for delivery. Event files mean a NUT callback has not
yet been processed; inspect the journal before removing anything.

### Test notification templates safely

These commands queue clearly marked test messages. They do not disconnect USB,
change UPS state, restart NUT, shut down the Raspberry Pi or remove power:

```bash
sudo /usr/local/sbin/raspi-ups-monitor --simulate-power-failure
sudo /usr/local/sbin/raspi-ups-monitor --simulate-power-update
sudo /usr/local/sbin/raspi-ups-monitor --simulate-low-battery
sudo /usr/local/sbin/raspi-ups-monitor --simulate-shutdown
sudo /usr/local/sbin/raspi-ups-monitor --simulate-power-restored
sudo /usr/local/sbin/raspi-ups-monitor --simulate-communication-failure
sudo /usr/local/sbin/raspi-ups-monitor --simulate-communication-restored
```

Each command should print `Queued test notification:` and the simulated event.
Verify delivery through the checks in [email.md](email.md).

### Runtime estimate

If the UPS reports `battery.runtime`, the monitor uses it. Otherwise, it
samples battery voltage in `/run`, which is normally RAM-backed, and estimates
time to `battery.voltage.low` from the recent trend. The default estimate
requires at least five samples over four minutes and a drop of at least
`0.2 V`.

This estimate is informational. Battery voltage is not linear through a
discharge and varies with load, temperature and battery age. NUT continues to
use the UPS `LB` state, not this estimate, for the shutdown decision.

Test the estimator with synthetic samples, without changing UPS state or
sending a notification:

```bash
sudo /usr/local/sbin/raspi-ups-monitor --self-test-runtime-estimator
```

Expected result: a line beginning with `Runtime estimator self-test: ~`. The
exact duration is determined by the built-in synthetic sample set.

### Roll back installed files

Use the exact backup path printed by `--apply`:

```bash
sudo ./install-ups-monitor.sh --rollback \
    /var/backups/raspi-ups-monitor/YYYYMMDD-HHMMSS
```

Rollback restores only the managed files and reloads systemd metadata. It does
not restart NUT, disable units, delete runtime state or delete queued
notifications. Review the restored configuration, then approve any required
service restart separately.

## Tested deployment: Raspi3-02

The design above was derived from the successfully deployed Raspi3-02 bundle.
Its USB UPS uses the `nutdrv_qx` driver and the example hardware identifiers
shown earlier in this chapter.

The final realistic outage test succeeded: while the UPS was on battery, NUT
shut down the Raspberry Pi, the UPS removed output, and reconnecting utility
power caused the UPS to restore output after its configured delay. The
Raspberry Pi booted and NUT returned to `OL`.

An earlier forced-shutdown test performed while utility power remained present
removed UPS output but did not make that UPS model restart automatically. This
is why the complete test must reproduce a real utility-power loss and return.
The result is specific to the tested UPS firmware and must not be assumed for a
different model.

## Management and troubleshooting

List writable variables and supported instant commands:

```bash
upsrw myups@localhost
upscmd -l myups@localhost
```

> **WARNING:** Do not experiment with `load.off`, `shutdown.*`,
> `driver.killpower` or deep battery-calibration commands on a running
> system. They can remove power from the Raspberry Pi.

Check service logs:

```bash
sudo journalctl \
    -u nut-driver@myups.service \
    -u nut-server \
    -u nut-monitor \
    -u raspi-ups-monitor.service --no-pager -n 100
```

If the log contains `insufficient permissions on everything`, reload the USB
permissions as described earlier or reconnect only the UPS USB cable, then
approve the required service restart.
