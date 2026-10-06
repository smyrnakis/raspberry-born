# UPS monitoring assets

These files implement the optional event and health monitoring described in
[`chapters/ups.md`](../../chapters/ups.md). NUT remains responsible for safe
shutdown. This monitor adds durable notifications, communication-failure
tracking and periodic status reports while the UPS is on battery.

UPS messages use short subjects without timestamps or incident IDs. Their
bodies put the current condition first and retain the detailed power, UPS and
NUT service information under separated headings. A shutdown notice is marked
boot-only, so it is discarded if it could not be delivered before the
Raspberry Pi restarted. The following restoration message records the total
outage duration and whether a shutdown/restart was detected.

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
