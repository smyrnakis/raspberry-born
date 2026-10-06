# Durable email notifications

This guide configures `msmtp` as the SMTP transport and adds a small, persistent
local queue for system notifications. A monitoring script writes its message to
disk before delivery is attempted. If DNS, the network or the SMTP provider is
unavailable, the dispatcher retries without blocking the monitoring service.

The queue was developed and tested on Raspi3-02. The repository version uses
generic names and paths so the same design can be used on any Raspberry Pi.

References:

- [msmtp manual](https://marlam.de/msmtp/msmtp.html)
- [systemd timer documentation](https://www.freedesktop.org/software/systemd/man/latest/systemd.timer.html)

## What is stored where

| Path | Purpose |
| --- | --- |
| `/etc/msmtprc` | SMTP server and authentication settings |
| `/etc/msmtp-password` | Optional root-only application password |
| `/etc/raspi-notify/notify.conf` | Local sender, recipients and display name |
| `/var/spool/raspi-notify/queue/` | Messages waiting for delivery |
| `/var/spool/raspi-notify/bad/` | Invalid messages retained for inspection |
| `/usr/local/sbin/raspi-notify` | Command used by monitoring scripts |
| `/usr/local/sbin/raspi-notify-dispatcher` | Queue delivery process |

Email addresses and SMTP credentials are local configuration. Do not commit
`notify.conf`, `/etc/msmtprc`, `/etc/msmtp-password` or copies of those files.

## 1. Inspect the current Raspberry Pi

These commands are read-only:

```bash
command -v msmtp || true
msmtp --version 2>/dev/null || true
sudo test -r /etc/msmtprc && echo "msmtp configuration exists"
systemctl status raspi-notify-dispatcher.timer --no-pager 2>/dev/null || true
sudo find /var/spool/raspi-notify/queue -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null
```

If another mail queue or monitoring framework already exists, review it before
installing this one.

## 2. Install the SMTP transport

Package installation changes the system. Review the package plan before
approving it:

```bash
sudo apt-get update
apt-get --simulate install msmtp ca-certificates
sudo apt-get install msmtp ca-certificates
```

The queue calls `msmtp` directly. The optional `msmtp-mta` package is needed
only when programs must use a traditional `/usr/sbin/sendmail` interface.

## 3. Configure `msmtp`

The repository includes [`msmtprc.example`](../src/notify/msmtprc.example).
Copy its structure to `/etc/msmtprc` and adapt the SMTP host, account and sender
locally:

```bash
sudo install -o root -g root -m 600 /dev/null /etc/msmtprc
sudo vim /etc/msmtprc
```

For a provider that uses an application password, keep it in a separate
root-only file. Enter the secret directly in Vim; do not place it in a shell
command, repository file or chat message:

```bash
sudo install -o root -g root -m 600 /dev/null /etc/msmtp-password
sudo vim /etc/msmtp-password
```

The file contains exactly one line: the provider-issued application password
or access token itself. Do not add `password=`, quotes or surrounding spaces.
For example, the file structure is:

```text
replace-this-line-with-the-application-password-or-token
```

Replace the complete example line. A normal newline at the end of the file is
fine. The `passwordeval` command reads the file and shell command substitution
removes that trailing newline before passing the value to `msmtp`.

The example uses `passwordeval` so the password is not embedded in
`/etc/msmtprc`. The password remains a local secret and must still be protected.
The upstream msmtp manual also documents desktop keyrings and commands that
decrypt a password at use time.

Test the SMTP transport before installing the queue. Replace the address only
in the local command:

```bash
printf 'Subject: Raspberry Pi msmtp test\n\nDirect transport test.\n' | \
    sudo msmtp --account=default recipient@example.invalid
```

Inspect the result without printing the configuration or password:

```bash
sudo journalctl -t msmtp --no-pager -n 30
```

Do not use `msmtp --debug` in copied logs or screenshots. Debug output can
contain account, server and message information.

## 4. Prepare the notification configuration

On the Raspberry Pi, from the repository checkout:

```bash
cd ~/raspberry-born/src/notify
cp notify.conf.example notify.conf
vim notify.conf
```

`notify.conf` is ignored by Git. Use a descriptive sender name such as the
Raspberry Pi hostname. `MAIL_TO` accepts either one address or several
comma-separated addresses without spaces:

```ini
MAIL_TO=first-recipient@example.invalid
```

```ini
MAIL_TO=first-recipient@example.invalid,second-recipient@example.invalid
```

Every configured recipient receives the same message. All addresses appear in
the email's `To:` header, so recipients can see each other's addresses. Do not
use quotes, spaces, display names, semicolons or angle brackets in `MAIL_TO`.
Keep actual addresses only in the ignored local `notify.conf` and the installed
root-only configuration, never in Git.

## 5. Validate, apply and test

The default installer mode is read-only. It validates dependencies, scripts,
configuration and systemd units, then prints the files it would install:

```bash
sudo ./install-notify.sh --check
```

Review that output. Applying creates a timestamped backup, installs the queue
and reloads systemd metadata. It does not enable the retry timer:

```bash
sudo ./install-notify.sh --apply
```

Queue a test message:

```bash
printf 'Durable notification queue test.\n' | \
    sudo /usr/local/sbin/raspi-notify "[$(hostname --short)] Notification test"
```

The test must arrive at every address configured in `MAIL_TO`.

Then verify the delivery service and queue:

```bash
sudo systemctl status raspi-notify-dispatcher.service --no-pager
sudo journalctl -t raspi-notify-dispatcher --no-pager -n 30
sudo find /var/spool/raspi-notify/queue -mindepth 1 -maxdepth 1 -type d -printf '%f\n'
sudo find /var/spool/raspi-notify/bad -mindepth 1 -maxdepth 1 -type d -printf '%f\n'
```

Expected results:

| Command | Successful result |
| --- | --- |
| `systemctl status` | The oneshot service shows its latest run as successful. It normally returns to `inactive (dead)` after delivering the message; it is not intended to remain running. |
| `journalctl` | Contains `Delivered notification:` followed by the test subject. A delivery failure instead records a retry and leaves the message queued. |
| `find .../queue` | No output after successful delivery. A directory named `msg-*` or `key-*` means a message is still waiting or backing off before another attempt. |
| `find .../bad` | No output. Any listed directory is a malformed queue entry that was quarantined rather than discarded. |

Confirm the service exit result directly when `systemctl status` shows it as
inactive:

```bash
sudo systemctl show raspi-notify-dispatcher.service \
    --property=ActiveState \
    --property=SubState \
    --property=Result \
    --property=ExecMainStatus
```

After a successful completed run, expect `ActiveState=inactive`,
`SubState=dead`, `Result=success` and `ExecMainStatus=0`.

### Add or remove a recipient later

Edit the ignored configuration beside the installer rather than placing an
address in a tracked file:

```bash
cd ~/raspberry-born/src/notify
vim notify.conf
sudo ./install-notify.sh --check
sudo ./install-notify.sh --apply
```

`--check` validates every address before changing the system. `--apply` creates
a timestamped backup and updates `/etc/raspi-notify/notify.conf`; it does not
restart the dispatcher or retry timer. The next dispatcher invocation reads the
new list. Queue the test message above and confirm that every intended recipient
receives it before relying on the change.

Enable the one-minute retry timer only after the direct transport and queue
tests pass:

```bash
sudo systemctl enable --now raspi-notify-dispatcher.timer
systemctl is-enabled raspi-notify-dispatcher.timer
systemctl is-active raspi-notify-dispatcher.timer
systemctl list-timers raspi-notify-dispatcher.timer --no-pager
```

## 6. Use the queue from another script

Send the message body on standard input and pass the subject as the final
argument:

```bash
printf '%s\n' "Service check failed." | \
    /usr/local/sbin/raspi-notify "[$(hostname --short)] Service alert"
```

The caller must run as root because the queue is root-only. Use `--event-time`
when the event happened earlier than the enqueue operation:

```bash
printf '%s\n' "Network access recovered." | \
    /usr/local/sbin/raspi-notify \
        --event-time "2026-09-20T12:00:00+02:00" \
        "[$(hostname --short)] Network recovered"
```

Use `--key` for periodic status messages where only the newest unsent version
is useful. A newer message with the same key replaces the queued older one:

```bash
printf '%s\n' "The service is still unavailable." | \
    /usr/local/sbin/raspi-notify \
        --key service-unavailable \
        "[$(hostname --short)] Service still unavailable"
```

Do not use a shared key for distinct critical events that must each be retained.

Use `--boot-only` for a message which is useful only during the current Linux
boot, such as a best-effort warning immediately before an automated shutdown:

```bash
printf '%s\n' "The system is shutting down now." | \
    /usr/local/sbin/raspi-notify \
        --boot-only \
        "[$(hostname --short)] Shutdown initiated"
```

The queue records the current boot ID. Delivery may retry while that boot
remains active, but the dispatcher discards the message after a reboot instead
of sending a stale warning. Do not use this option for recovery reports or
other historical events which must remain durable.

## Retry and recovery behavior

Failed deliveries retry after 1, 2, 4, 8, 15, 30 and then 60 minutes. Event,
queue and delivery times are appended to the delivered message. If power is
lost while a message is being delivered, the next dispatcher run returns the
interrupted message to the queue. Invalid queue entries are moved to `bad/`
instead of being discarded.

The queue is intentionally persistent. Review its contents before deleting a
failed or obsolete notification.

## Rollback

The apply command prints its backup directory. To restore the files that were
present before installation, pass that exact directory:

```bash
sudo ./install-notify.sh --rollback /var/backups/raspi-notify/YYYYMMDD-HHMMSS
```

Rollback does not delete queued messages or SMTP configuration. If the timer
was enabled manually, disable it separately when retiring the queue:

```bash
sudo systemctl disable --now raspi-notify-dispatcher.timer
```

Older scripts that call `msmtp` directly should be migrated gradually. Do not
remove a working legacy notifier until its replacement has been tested on the
target Raspberry Pi.
