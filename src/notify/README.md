# Durable notification queue assets

These files implement the general notification mechanism documented in
[`chapters/email.md`](../../chapters/email.md).

The repository contains no recipient address or SMTP credential. Copy
`notify.conf.example` to the ignored `notify.conf` file and edit it locally.
Create `/etc/msmtprc` and any password or token file directly on the Raspberry
Pi.

`install-notify.sh` is read-only unless `--apply` or `--rollback` is specified.
Application creates a timestamped backup and installs the files, but does not
enable the retry timer. This leaves service activation as a separate reviewed
step.

The queue interface is:

```text
raspi-notify [--key KEY] [--event-time ISO-8601] SUBJECT
```

The message body is read from standard input. `--key` coalesces an unsent
periodic update so only the latest message with that key remains queued.
