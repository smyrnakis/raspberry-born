# UPS monitoring assets

These files implement the optional event and health monitoring described in
[`chapters/ups.md`](../../chapters/ups.md). NUT remains responsible for safe
shutdown. This monitor adds durable notifications, communication-failure
tracking and periodic status reports while the UPS is on battery.

Install the general notification queue under [`src/notify/`](../notify/) first.
Then copy `ups-monitor.conf.example` to the ignored `ups-monitor.conf`, adapt
the UPS and service names, and run the installer in read-only mode:

```bash
sudo ./install-ups-monitor.sh --check
```

`--apply` creates a timestamped backup and installs the files. It does not
enable units or restart NUT. The installer refuses an existing NUT
`NOTIFYCMD`, or managed `NOTIFYFLAG` entries, because replacing another event
integration requires a deliberate migration.
