# Durable notification queue assets

These files implement the general notification mechanism documented in
[`chapters/email.md`](../../chapters/email.md).

The repository contains no recipient address or SMTP credential. Copy
`notify.conf.example` to the ignored `notify.conf` file and edit it locally.
Create `/etc/msmtprc` and any password or token file directly on the Raspberry
Pi.

`MAIL_TO` accepts one address or a comma-separated list without spaces:

```ini
MAIL_TO=first-recipient@example.invalid,second-recipient@example.invalid
```

Every configured address receives the same message and appears in its `To:`
header. Personal addresses belong only in the ignored local configuration,
never in this repository.

`install-notify.sh` is read-only unless `--apply` or `--rollback` is specified.
Application creates a timestamped backup and installs the files, but does not
enable the retry timer. This leaves service activation as a separate reviewed
step.

The queue interface is:

```text
raspi-notify [--key KEY] [--event-time ISO-8601] [--boot-only] SUBJECT
```

The message body is read from standard input. `--key` coalesces an unsent
periodic update so only the latest message with that key remains queued.
`--boot-only` records the current Linux boot ID. The dispatcher discards that
message instead of delivering it after a reboot. Use this only for notices
which become misleading after the originating machine has shut down.
