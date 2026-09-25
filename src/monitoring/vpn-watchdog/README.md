# OpenVPN watchdog assets

These files implement the reusable client and server health monitoring described
in [`chapters/vpn-watchdog.md`](../../../chapters/vpn-watchdog.md).

Copy exactly one role example to the ignored `vpn-watchdog.conf`, review its
device-specific values, and run the installer in its default `--check` mode.
The installer never enables the timer, restarts OpenVPN, sends a notification or
reboots the host.

The tracked default is `ALLOW_REBOOT=false`. Reboot permission is a separate,
per-device decision after recovery testing. The watchdog never treats the lack
of connected OpenVPN clients as a server failure.
