# Automatic security update assets

These files implement the layered maintenance policy documented in
[`chapters/auto-updates.md`](../../../chapters/auto-updates.md):

- daily unattended installation from Debian-Security only
- no automatic reboot by default
- a durable notification when a package requests a reboot
- a weekly report of the broader same-release `apt full-upgrade` plan
- an explicit helper for enabling a conditional 04:45 reboot after recovery
  testing

The weekly report changes only APT package-list metadata. It never installs or
removes a package. Broader upgrades remain an approved maintenance action.

Install the durable notification queue under [`src/notify/`](../../notify/)
first. Run `install-updates.sh` with `--check` before `--apply`. Application
creates a timestamped backup but does not enable or start any timer or path
unit.

The installer places an inactive reboot-policy template and
`raspi-configure-auto-reboot` on the Raspberry Pi. The helper defaults to a
read-only check. Its explicit `--enable` mode activates the 04:45 profile;
`--disable` and `--rollback` provide controlled recovery. See the chapter for
the required device checks before enabling it.
