# Repository reconciliation status

## Purpose

This file records the state, decisions, rationale and progress of the local and remote repository reconciliation. Read it before every new repository action and update it whenever a decision or material action changes.

No merge, rebase, reset, commit or push is authorized merely by an entry in this file. Each execution phase still requires explicit approval.

## Audit baseline

Audit date: 2026-09-19

- Local branch: `main` at `e88de61`
- Remote branch after fetch: `origin/main` at `2086acc`
- Divergence: local is 0 commits ahead and 3 commits behind
- Local-only commits: none
- Additional local branches: none
- Staged files: none
- Remote-only commits:
  - `20fcd5f` Update pihole whitelist
  - `bd5a035` add vpn_crete-athens.md
  - `2086acc` update ssh process
- Modified tracked files:
  - `README.md`
  - `chapters/auto-updates.md`
- Untracked files:
  - `chapters/grafana.md`
  - `chapters/mosquitto.md`
  - `chapters/ups.md`
  - `chapters/watchdog.md`
- Ignored working file:
  - `src/vpn/OpenVPN-email_inotifywait.sh`
- `README.md` is modified locally and remotely. A dry application of the remote diff failed on its final hunk, so it must be reconciled manually.
- No untracked path collides with a remotely added path.

## Current integration state

As of 2026-09-25 after the approved VPN-watchdog commit:

- Reconciliation branch: `codex/reconcile-2026-09-19`.
- The branch is based on `origin/main` at `2086acc` and contains the planning checkpoint plus focused reconciliation commits.
- The three reviewed remote commits are now present in the branch history.
- Local `main` remains unchanged at `e88de61`.
- Nothing has been pushed.
- The automatic-updates, boot-report and VPN-watchdog commits are complete.
- The deferred untracked chapters remain present: `grafana.md` and `mosquitto.md`.
- The durable notification, hardware-watchdog, UPS, automatic-updates and boot-report changes are committed locally in separate focused commits. None has been deployed.

## Confirmed project decisions

- The repository should read as a step-by-step guide tailored to the owner's systems but understandable by anyone.
- General chapters should not mention that one hostname tested a procedure while others did not unless that fact changes compatibility, safety or the instructions. Keep device-specific deployment evidence in its runbook or this ledger.
- Hostnames and private LAN or VPN address ranges may be committed.
- MAC addresses, personal email addresses and public DDNS names must not be committed.
- Passwords, tokens, VPN profiles and private keys must never be committed.
- Debian and Raspberry Pi OS are the target platforms. Ubuntu-specific guidance is not authoritative.
- Prefer Vim for Debian editing commands. The Windows laptop uses PowerShell and VS Code.
- `chapters/grafana.md` will not be included in the current reconciliation. Rebuild it in a dedicated session.
- `chapters/mosquitto.md` will not be included in the current reconciliation. Rebuild it in a dedicated session.
- `chapters/ups.md` is intended for inclusion after style, portability and sanitization review.
- `chapters/watchdog.md` was initially deferred, then reopened at the user's request on 2026-09-22 for rebuilding as a safe hardware-watchdog and service-recovery guide. Keep it in a separate reviewable commit.
- UPS scripts and configuration templates should be maintained under `src/`, with the chapter explaining their purpose, operation, installation and verification.
- The Raspi3-02 installation is complete and tested.
- The durable mail queue and UPS watchdog are deployed successfully on Raspi3-02.
- The final UPS shutdown and restart test succeeded.
- The UPS guide must remain reusable for any Raspberry Pi while noting Raspi3-02 as a tested deployment.
- Raspi3-02 needs a dedicated device-specific operational chapter covering its networking, discovery, camera, monitoring, storage-write protections and remote-site role.
- The durable queued email design should become the general notification mechanism for all Raspberry Pis. Older direct-msmtp scripts and instructions will be migrated gradually.
- Raspi4-01 and Raspi4-02 will be inspected read-only later when access details are supplied.
- Replace the remaining hardcoded home-directory username references in `chapters/2FA.md` and `src/archive/pihole.md` with generic placeholders during their later focused reviews. Do not expand the current VPN-watchdog commit to include them.
- Repository work continues in the current Codex task. The separately created reconciliation task remains unused unless explicitly resumed.

## Source hierarchy

Use these sources in this order, while preserving all user changes:

1. Verified deployed behavior and explicit user decisions.
2. Current local working-tree changes.
3. Current `origin/main` history and documentation.
4. The final Raspi3-02 bundle under the owner's OneDrive project directory, after sanitization.
5. Older Codex scratch bundles only for comparison or recovery of missing context.

Never import the `old.VPN` directory or any `.ovpn` profile.

## Remote commit assessment

### `20fcd5f` pihole whitelist

Status: reviewed; preserve the commit in remote history and replace its unexplained dated snapshot with a maintained, documented service-compatibility allowlist.

Decision rationale:

- The five active domains represent operational knowledge needed to reproduce the owner's working installations.
- Each active entry must state the observed service failure it corrects so other users can choose only what they need.
- Store the active domains in `src/pihole/allowlist-service-compatibility.txt` so new installations can apply the reviewed list repeatably.
- Keep `marketingplatform.google.com` only as a commented historical candidate because it was disabled, not as an active entry.
- Use current `pihole allow` terminology and provide read-only preview, application, verification and rollback commands.
- Explain that the list is tested with the owner's blocklists but is not a universal recommendation.

### `bd5a035` Athens-Crete VPN guide

Status: preserve the remote commit in history, but replace its guide with documentation derived from the verified deployment.

Still-valid concepts:

- Athens is the OpenVPN server and Crete is a persistent client.
- Crete uses a stable VPN address and CCD `iroute` ownership for its LAN.
- VPN clients receive a route for the Crete LAN.
- Crete remains split-tunnel and keeps its normal internet route.
- The Starlink-side router cannot provide the VPN return route, so narrowly scoped NAT is required on Raspi3-02.

Outdated or unsafe content:

- Old fixed Pi and camera LAN addresses are presented as operational values.
- The firewall section uses iptables, but the verified Debian installation uses nftables.
- The broader iptables example flushes NAT and forwarding chains, which could destroy unrelated firewall state.
- The client includes a redundant VPN-subnet route that was removed from the deployed configuration.
- OpenVPN cipher guidance does not reflect the verified OpenVPN 2.6 negotiation.
- Package installation, service restart and reboot-impacting steps are not separated from read-only inspection or approval gates.
- The generic `Restart=always` override is not the verified recovery design.
- A ChatGPT conversation link is used as operational documentation instead of keeping the knowledge in Git.

Decision rationale: merging the file as-is would reintroduce an untested firewall implementation and stale topology details. The tested nftables installer and verified final state are the authoritative basis for the replacement.

Approved replacement structure:

- Keep `chapters/vpn_crete-athens.md` as a focused, tested site-to-site VPN case study.
- Create `chapters/raspi3-02.md` later as the complete device runbook, summarizing and linking to the focused VPN guide.
- Keep `chapters/vpn.md` for general OpenVPN server installation.
- Maintain reusable routing assets under `src/vpn/site-to-site/`, including the installer, nftables rules, configuration and a short README.
- Treat the Athens-Crete values as the tested example while keeping the implementation configurable.
- Assume the base OpenVPN server and client already exist. Cover only split tunnelling, stable VPN addressing, CCD `iroute`, route advertisement, nftables forwarding and scoped NAT, safe verification, recovery and rollback.
- Keep the private ranges `192.168.178.0/24`, `192.168.1.0/24` and `10.8.0.0/24`, plus Raspi3-02 VPN address `10.8.0.20`.
- Do not publish dynamic device addresses, public endpoints, DDNS names or VPN profiles.

Verified deployed source comparison:

- Authoritative source bundle: the final `raspi3-02-watchdog` directory under the Raspi3-02 OneDrive project directory. Live `.ovpn` profiles, private keys and the `old.VPN` directory are explicitly excluded.
- The deployed Crete router uses nftables, not iptables, and persists `net.ipv4.ip_forward=1` through `/etc/sysctl.d/`.
- The installer backs up `/etc/nftables.conf`, validates the complete ruleset with `nft -c`, applies the sysctl setting, enables/restarts nftables and rolls back on failure.
- The rules allow connections initiated from authenticated VPN clients in `10.8.0.0/24` to the full Crete LAN `192.168.1.0/24`, permit established return traffic and apply masquerading only to that VPN-to-LAN path.
- The tested deployment keeps ordinary Crete internet traffic on Starlink and prevents Crete LAN devices from initiating new connections toward the VPN through Raspi3-02.
- The live Athens audit confirmed the server route, pushed Crete LAN route, CCD static address and `iroute` ownership for client `401-Raspi3-02`.
- End-to-end routing and application access were verified from a Geneva VPN client through Athens and Raspi3-02 to the Crete camera. The final controlled reboot restored OpenVPN, nftables and LAN reachability.
- The deployed router files are Raspi3-02-specific and assume an otherwise empty/default Crete nftables configuration. Repository assets must be generalized and must not silently take ownership of an existing firewall.

Implementation status:

- Replaced the remote guide with a tested case study that separates read-only audit, Athens route/CCD changes, client review, Crete nftables application, verification and rollback.
- Added configurable assets under `src/vpn/site-to-site/` with an ignored local `site.conf`, read-only `--check`, explicit `--apply`, timestamped backup and `--rollback` modes.
- The generalized forwarding chain uses an accept policy and filters only traffic entering or leaving the configured VPN interface, avoiding ownership of unrelated forwarding traffic.
- Added scoped Git attributes so executable/configuration assets keep LF line endings on Windows checkouts.
- Bash parsing, Markdown fences, relative links, whitespace and prohibited-identifier scans passed locally.
- Native nftables validation cannot run on the Windows laptop. `sudo ./install-router.sh --check site.conf` on a Raspberry Pi remains mandatory before any application.

### `2086acc` SSH documentation

Status: reviewed and reconciled with the approved targeted edits in a focused branch commit.

Approved decisions:

- Keep the expanded SSH private-key ignore rules, then review broader secret-file protection separately so patterns do not hide legitimate templates by accident.
- Keep the README link and simplify `chapters/initial-settings.md` so the dedicated SSH chapter is the authoritative procedure.
- Keep the new `chapters/ssh-keys.md` guide after adapting it to project conventions and current tool behavior.

Required edits to the SSH guide:

- Clearly label commands for the Windows laptop versus Raspberry Pis.
- Use Vim for editing on Raspberry Pis and VS Code for editing the Windows SSH configuration.
- Keep one passphrase-protected Ed25519 key per laptop, reusable across the owner's Pis; never copy a private key to a Pi, cloud storage or Git.
- Keep host-key fingerprint verification and `IdentitiesOnly yes`; never disable host-key checking.
- Explain that WinSCP uses PuTTY `.ppk` files when a private-key file is selected directly, can offer conversion when importing an OpenSSH configuration, and can alternatively use the Windows OpenSSH agent.
- Do not commit private or public user keys. Keep examples generic and free of email addresses, DDNS names and other prohibited identifiers.

## Working-file assessment

### `README.md`

Status: approved for selective preservation during reconciliation.

- Retain the UPS and NASPi navigation additions.
- Omit the Mosquitto and hardware-watchdog links until those chapters are rebuilt and approved.
- Incorporate the approved remote SSH and VPN navigation changes when the README is reconciled.
- The complete pre-reconciliation working copy remains available in the verified external backup.

### `chapters/auto-updates.md`

Status: preserve in the verified backup, but do not carry the current working edit into the reconciled branch.

Rationale:

- It enables automatic reboot and specifies a fixed reboot time, contrary to the tested no-automatic-reboot policy.
- It uses Nano and includes Ubuntu-oriented material rather than a current Debian/Raspberry Pi OS procedure.
- Its 2022 failure note is historical rather than useful operational guidance.
- It will be replaced later using the successfully deployed Debian-Security-only configuration from Raspi3-02.

### Deferred untracked drafts

Status: leave `chapters/grafana.md` and `chapters/mosquitto.md` untracked and untouched during the first reconciliation. Their complete copies are also present in the verified backup. `chapters/ups.md` is being reviewed separately. `chapters/watchdog.md` was rebuilt, approved and committed locally.

### `chapters/ups.md`

Status: committed locally in the focused `Add reusable UPS monitoring guide` commit on 2026-09-23; not deployed.

- Matches the UPS task's final documentation-stage copy by SHA-256.
- Must be reviewed for repository style, generic applicability, sanitization and links to maintained `src/` assets.
- The general guide should not embed Raspi3-02-only paths or values except in a clearly labelled tested-example section.
- The core NUT installation, status interpretation, shutdown mechanics and test record remain useful.
- Preserve both test outcomes: an online forced-shutdown test did not restart the UPS while utility power remained present, while the final realistic outage test restored UPS output and rebooted the Raspberry Pi successfully when utility power returned.
- Keep the destructive `upsmon -c fsd` test behind a prominent, explicit confirmation boundary. The non-destructive `upsdrvctl -t shutdown` check is not a substitute for the final outage test.

Read-only bundle findings:

- The deployed UPS bundle is operational and passed Bash syntax checks, but it is device-specific rather than repository-ready.
- File names, systemd descriptions, configuration directories, spool paths and state paths are hardcoded with `raspi3` or `raspi3-02`.
- The installer assumes UPS name `myups@localhost`, references `nut-driver@myups.service` directly and requires an existing `/etc/msmtprc`.
- It installs both the UPS monitor and the general durable notification queue, so copying it would duplicate cross-cutting notification logic.
- It creates timestamped backups but has no check-only mode, explicit apply gate or automatic rollback after a failed service/configuration change.
- It removes existing NUT `NOTIFYCMD` and relevant `NOTIFYFLAG` directives before installing its managed block, which could replace another notification integration.
- No actual passwords, email addresses, MAC addresses, DDNS names or private keys were found in the reviewed UPS source files.
- USB vendor/product identifiers such as `0665:5161` identify the tested UPS model, not a unique device, and may remain in the tested-hardware example.

Approved repository design:

1. Generalize the durable mail queue once under `src/notify/`; UPS, boot and VPN monitoring should call that common interface instead of carrying their own mail implementation.
2. Generalize the UPS event hook, monitor, configuration example and systemd units under `src/ups/`, with neutral names and configurable UPS/service identifiers.
3. Give both installers a read-only validation mode by default, an explicit apply mode, timestamped backups and documented rollback. Do not silently replace an existing NUT notification command.
4. Restructure `chapters/ups.md` as a reusable NUT guide with an optional advanced monitoring section and a concise Raspi3-02 tested-deployment note.
5. Implement this as two reviewable commits: the durable notification foundation first, then the UPS integration and chapter.

Implementation prepared for review:

- Added neutral `raspi-ups-monitor` and `raspi-ups-event-hook` commands, configurable service names, systemd service/timer/path units and an ignored local configuration file under `src/ups/`.
- Preserved the tested immediate-event, one-minute polling, persistent outage tracking, coalesced on-battery update, increasing communication-reminder and voltage-trend runtime-estimation behavior.
- Added a read-only-by-default installer with explicit `--apply`, timestamped backups, automatic failure rollback and allowlisted manual rollback.
- The installer refuses an existing external NUT `NOTIFYCMD` or overlapping event `NOTIFYFLAG` entries instead of silently replacing another integration.
- Installation does not enable units, restart NUT, change UPS state or send an email. Those actions remain separate documented approval points.
- Reworked the chapter into a general NUT guide, optional durable monitoring procedure and concise Raspi3-02 tested-deployment record. The successful realistic outage test and unsuccessful online-restart behavior are both retained.
- Added expected outcomes for activation, queue/event inspection, safe simulations and runtime-estimator self-test.
- Git Bash syntax, whitespace, Markdown fence, local-link, LF and prohibited-identifier checks passed locally. Native systemd validation and NUT integration tests remain Raspberry Pi pre-deployment checks.

### Durable notification foundation

Status: committed locally in the focused `Add durable notification queue` commit on 2026-09-23. No deployment has been made.

- Replaced the direct-send-only email chapter with a reusable `msmtp` transport and persistent queue guide.
- Added neutral reusable assets under `src/notify/`; no Raspi3-02-specific path, email address or SMTP credential was imported.
- Kept the real `notify.conf` ignored and documented `/etc/msmtprc` plus the optional password file as local-only configuration.
- The notifier persists each message before requesting delivery. Keyed periodic messages can be coalesced without coalescing distinct critical events.
- The dispatcher uses bounded SMTP attempts and retry backoff, quarantines malformed entries and recovers messages interrupted during delivery or keyed-message replacement.
- The installer is read-only by default. `--apply` creates a timestamped backup, installs files and validates installed units, but does not enable or restart the timer.
- Automatic and manual rollback restore only an explicit allowlist of managed files. Queued messages and SMTP configuration are left untouched.
- Git Bash parsing, Markdown fence, relative-link, LF and prohibited-identifier checks are required before commit. Native systemd verification and a real delivery test remain Raspberry Pi pre-deployment checks.
- Clarified that `/etc/msmtp-password` contains only one application-password or token line, with no assignment, quoting or surrounding spaces.
- Added expected outcomes for the oneshot dispatcher, journal, pending queue and malformed-message quarantine checks.

### `chapters/watchdog.md`

Status: committed locally in the focused `Rebuild hardware watchdog guide` commit on 2026-09-23. No deployment has been made.

Findings:

- It documents the hardware watchdog, not the VPN, camera or UPS application watchdogs.
- It already uses Vim, which matches project policy.
- `/boot/config.txt` is version-dependent and may be `/boot/firmware/config.txt` on current Raspberry Pi OS.
- It immediately installs a package and requests a reboot without a read-only discovery phase or approval boundary.
- `max-load-1 = 24` is unexplained and not suitable as a universal value.
- Monitoring `wlan0` could cause unwanted reboots and needs explicit assumptions.
- The fork-bomb test is destructive and unsuitable for a general guide.

Implemented replacement:

- Separates whole-system hardware watchdog recovery, systemd service restart and protocol-specific application health checks.
- Detects `/boot/firmware/config.txt` or the legacy `/boot/config.txt` instead of assuming one location.
- Documents systemd and the Debian `watchdog` daemon as mutually exclusive owners of the hardware device.
- Uses the current `kernel_watchdog_timeout` firmware handoff for the systemd-owned path and retains `dtparam=watchdog=on` only for the legacy or classic-daemon path.
- Begins with read-only driver, device, systemd and ownership checks.
- Uses a minimal hardware-only configuration before optional checks are considered.
- Explains common `watchdog.conf` parameters, including load, memory, temperature, file, PID, network, custom test and repair checks.
- Clarifies that `interface` observes received traffic rather than driver health, and that quiet networks or unreachable ping targets can create reboot loops.
- Routes SSH, OpenVPN, Pi-hole, Mosquitto and NUT toward systemd process recovery plus application-specific health checks rather than unconditional whole-system resets.
- Replaces the fork bomb with a controlled, explicitly disruptive keepalive-stop test for the classic daemon only.
- Requires a planned reboot or service activation boundary and local or out-of-band recovery access before arming or testing the watchdog.

### Ignored `src/vpn/OpenVPN-email_inotifywait.sh`

Status: backup completed; keep the file ignored and do not commit it. Removal remains a separate approval step.

Findings:

- It is an older alternative to the tracked polling notifier.
- It sends directly through msmtp and has no durable queue or retry behavior.
- It adds an inotify dependency and can miss or mishandle log replacement events.
- It contains fragile word splitting and duplicated notification logic.
- Its startup message names the other script.

Recommendation: after backup, remove this ignored working copy rather than publish it. Retain the tracked legacy notifier temporarily only until the new general queued notification system is documented and adopted.

## External bundle handling

The final Raspi3-02 bundle contains tested scripts and units for:

- Durable queued email delivery
- Boot reporting
- VPN health monitoring and bounded recovery
- Camera discovery and monitoring
- UPS monitoring
- nftables VPN-to-LAN routing
- Pure zram and bounded volatile journaling
- Debian-Security-only unattended upgrades without automatic reboot

Before importing any file:

- Replace personal email addresses with configuration placeholders.
- Remove MAC addresses and public DDNS names.
- Keep permitted hostnames and private address ranges only where they clarify the topology.
- Split reusable components from Raspi3-02-specific configuration.
- Ensure installers do not perform disruptive work without explicit user confirmation.
- Keep secrets and live profiles outside Git.

### Raspi3-02 runbook source map

Status: completed as a read-only mapping pass on 2026-09-23. No bundle file was imported and no Raspberry Pi was contacted.

Already generalized in focused repository components:

- durable notification delivery under `src/notify/`
- UPS monitoring and NUT event handling under `src/ups/`
- Athens-Crete VPN-to-LAN routing under `src/vpn/site-to-site/`

Reusable components that still require separate generalization:

- boot reporting, with optional checks selected through local configuration instead of hardcoded Raspi3-02 services
- OpenVPN client health monitoring, bounded service recovery and reboot suppression
- Debian-Security-only unattended upgrades without automatic reboot
- pure-zram and bounded volatile-journal policies, with their storage and troubleshooting tradeoffs documented separately

Raspi3-02-specific runbook content:

- Crete role, installation order, service inventory and recovery expectations
- references to the general Athens-Crete routing, UPS and notification guides
- camera discovery and reachability monitoring using an ignored local configuration
- the exact combination of VPN client, camera, boot-report, UPS and maintenance services enabled on this device

Files that must not be copied directly:

- deployed `notify.conf` and `site.conf`, which contain prohibited local values
- the deployed unattended-upgrades fragment, which contains a personal email address
- the all-in-one installer, which bundles unrelated components and lacks a read-only default, explicit apply gate and automatic rollback
- live profiles, secrets, runtime state and generated event or mail queues

Recovery constraints to preserve during generalization:

- The VPN watchdog distinguishes a VPN-specific outage from loss of general Internet access. It suppresses reboot when Internet access still works, rate-limits any reboot to a 12-hour minimum interval and continues less-aggressive service restart attempts.
- Service restarts and reboots remain disruptive operations requiring explicit approval. A reusable installer must not activate the watchdog automatically.
- The boot report collects host, network, service, storage and UPS state, but site-specific VPN and camera checks must be optional rather than hardcoded.
- Volatile journaling reduces microSD writes but removes previous-boot logs; durable notifications and explicit recovery checks must document that tradeoff.

## Additional historical sources to investigate

Two earlier ChatGPT discussions supplied by the user may contain useful requirements or implementation details:

- OpenVPN watchdog
- Boot email

Do not copy these older approaches directly. Compare them with the newer, successfully deployed Raspi3-02 VPN watchdog, boot report and durable mail queue.

For each discussion:

- Identify requirements or failure cases that are not covered by the deployed implementation.
- Retain only behavior that is still useful on current Debian and Raspberry Pi OS systems.
- Generalize reusable notification and watchdog components for all Raspberry Pis.
- Keep Raspi3-02-specific values in its future device chapter or sanitized configuration templates.
- Store the resulting operational knowledge in Git instead of relying on private conversation links.

Status: pending investigation. The private conversation URLs are intentionally not recorded in this public repository.

## Tracked artifact review

Pending review:

- `src/noip-duc-linux.tar.gz`
- `src/ya-pihole-list-master.zip`
- `src/zsh-autosuggestions-master.zip`
- `src/zsh-syntax-highlighting-master.zip`
- `src/pihole-basic-install.sh`
- `src/vpn/openvpn-install.sh`
- `src/fan.bkp.py`
- `src/fan-pi.bkp.py`

Questions for each artifact:

- Is it still used by a documented workflow?
- Can it be retrieved reliably from an authoritative upstream source instead?
- Is its version and license recorded?
- Does keeping a stale copy create a security or maintenance risk?
- Is a backup file preserving unique logic, or is Git history sufficient?

No artifact should be deleted before backup and individual review.

## Documentation modernization backlog

Retain for staged review:

- Replace Raspbian-only wording with accurate Debian/Raspberry Pi OS terminology.
- Replace Nano commands with Vim.
- Remove or qualify Ubuntu-specific sources and instructions.
- Review Python 2 examples.
- Replace obsolete init, chkconfig and unsafe firewall guidance.
- Reconcile unattended-upgrade guidance with the tested security-only, no-automatic-reboot policy.
- Clarify hardware watchdog versus application health watchdogs.
- Normalize line endings and script executable modes deliberately.
- Review copied third-party files, licensing and update strategy.
- Replace direct SMTP notification scripts gradually with the durable queue.
- Audit the general OpenVPN server setup at the end of reconciliation. Compare `chapters/vpn.md`, the automated `src/vpn/openvpn-install.sh` workflow and the archived fully manual method; decide which are current, safe and maintainable without combining them blindly.

### Automatic-updates replacement assessment

Status: approved and committed locally in a focused automatic-updates commit on 2026-09-24; not deployed.

Current chapter problems:

- edits the package-owned `50unattended-upgrades` file instead of using a later local override
- enables automatic reboot at a fixed time, contrary to the approved no-automatic-reboot policy
- uses Nano, installs a traditional mail stack without relating it to the repository notification design and shows a Gmail-shaped recipient placeholder
- does not prove which package origins are eligible, inspect the systemd timers, explain service-restart impact or show expected verification results

Tested source findings:

- Raspi3-02 enables daily package-list refresh, unattended upgrades and periodic cache cleanup.
- Its local origin override clears the distribution defaults and permits Debian-Security origins only.
- Automatic reboot is disabled and existing local configuration files are retained during package upgrades.
- The deployed fragment contains a personal email address and must not be imported.
- The deployed installer changes several unrelated maintenance policies together and restarts `systemd-journald`; it is not suitable as the focused updates installer.

Proposed focused replacement:

- Rename the scope to automatic security updates rather than general automatic updates.
- Begin with read-only package, origin, timer and current-policy inspection.
- Use a later local APT configuration fragment, verify the effective policy with `apt-config dump`, and preserve the distribution-owned file.
- Permit Debian-Security packages only, disable automatic reboot and explain that Raspberry Pi OS vendor packages outside the Debian security archive still require reviewed manual upgrades.
- State clearly that installing packages automatically can restart affected services even when rebooting is disabled.
- Keep recipient addresses out of tracked files and omit built-in unattended-upgrades mail. Use the durable `raspi-notify` queue for reboot-required and weekly maintenance reports.
- Provide dry-run, log, timer, reboot-required and rollback checks with expected outcomes.
- If repository assets are added, give their installer a read-only default, explicit apply mode, timestamped backup and rollback, without enabling timers or restarting services automatically.

Approved maintenance policy:

- Install Debian-Security updates automatically each day. Keep automatic reboot disabled initially.
- Use the durable notification queue to send one deduplicated alert when `/run/reboot-required` exists, including the packages recorded in `/run/reboot-required.pkgs` when available.
- Check all configured repositories weekly and send a report of pending non-security and Raspberry Pi OS vendor updates; do not install that broader set unattended at first.
- Apply the broader same-release update set regularly in an approved maintenance window, one Raspberry Pi at a time, with a simulation, free-space check, configuration backup and post-update health checks. Raspberry Pi OS guidance uses `apt full-upgrade` for this same-release maintenance.
- Do not automate a major Debian or Raspberry Pi OS release transition. Rebuild from a current image as a separate project.
- Consider a conditional 04:45 automatic reboot only after boot, VPN, firewall, UPS and remote-access recovery have been tested on each device. Never schedule both VPN servers for the same maintenance window.

Rationale: smaller regular update batches reduce the size of each change and the time systems remain exposed, but unattended broad upgrades or reboots can interrupt Pi-hole, OpenVPN and other remote services or remove remote access. Email-first reboot handling and staggered reviewed full upgrades are the safer initial policy. The user approved this policy on 2026-09-24.

Implementation prepared for review:

- Replaced the old automatic-reboot chapter with a step-by-step guide covering read-only audit, prerequisites, source validation, explicit application, dry runs, activation, expected outcomes, reboot response, staggered broader maintenance and rollback.
- Added a Debian-Security-only APT override, explicitly clears other unattended origins, preserves local configuration files and disables automatic reboot.
- Added a durable reboot-required alert triggered by `/run/reboot-required`. The notification is deduplicated per boot, and the oneshot service remains active while the flag exists so the path unit does not retrigger continuously.
- Added a Sunday weekly report with a randomized delay. It runs `apt-get update` and simulates `apt-get full-upgrade`, but never installs or removes a package.
- Added a read-only-by-default installer with explicit apply, timestamped backup, automatic failure rollback and allowlisted manual rollback. It does not install packages, enable units, refresh APT metadata, send notifications, restart services, upgrade packages or reboot.
- Added a safe simulated reboot-alert template and documented that actual broader upgrades omit `-y` so removals and configuration questions remain interactive.
- Made the durable notification queue a prominent prerequisite because reboot alerts and weekly reports depend on it.
- Added an inactive 04:45 automatic-reboot template and a separate read-only-by-default helper with explicit enable, disable and rollback modes. The profile reboots only when a package has requested it and suppresses the reboot while users are logged in. Installing the main policy does not activate this profile.
- Moved the weekly report window to Sunday after 06:15 so it does not compete with an optional 04:45 reboot.
- Git Bash syntax, whitespace, Markdown fence, local-link, LF and prohibited-identifier checks passed locally. Native APT parsing, systemd verification, dry-run and notification tests remain Raspberry Pi pre-deployment checks.

### Boot-report replacement assessment

Status: approved and committed locally in a focused boot-report commit on 2026-09-25; not deployed.

Older boot-email approach:

- uses a Python script launched from `/etc/rc.local`
- hardcodes a personal home-directory path and recipient address
- depends on `requests` and `netifaces` for information available from standard system commands
- sends directly through `msmtp`, so a temporary network or SMTP failure can lose the boot report
- writes a separate log under the user's home directory and does not reliably interpret the mail process exit status
- queries an external public-IP service unconditionally

Requirements recovered from the earlier boot-email discussion:

- send one plain-text report after every boot
- include hostname, local address, public address, boot time and CPU temperature
- avoid loopback addresses and the incorrect 1970 boot time seen when networking and time synchronization were not ready
- run under systemd after network readiness and use the journal for troubleshooting rather than `/etc/rc.local` and a home-directory log
- avoid the previous root-versus-user `msmtp` configuration problem; the durable system queue now owns transport configuration

Verified Raspi3-02 approach:

- runs once per boot as a bounded systemd oneshot
- waits for basic network and VPN readiness without blocking indefinitely
- uses the durable `raspi-notify` queue
- reports host, boot, OS, kernel, network, VPN, camera, temperature, load, memory, storage, throttling, reboot-required and failed-unit state
- is deployed successfully but hardcodes the Raspi3-02 VPN instance, tunnel address, peer, site configuration path and camera behavior
- discovers the camera by a local MAC address and includes that MAC in the report; this is valid local runtime data but must not be copied into the public repository
- queries an external public-IP service, which should be optional because it creates an external dependency and discloses the source address to that service

Recommended reusable design:

- provide a general `raspi-boot-report` command and systemd oneshot under `src/monitoring/boot-report/`
- send through `raspi-notify`; never embed a recipient or call `msmtp` directly
- keep the core report dependency-free and include host, boot, OS, kernel, local network, temperature, load, memory, root storage, throttling, reboot-required and failed-unit state
- make service, interface, peer and public-IP checks optional through a root-owned local configuration that is ignored by Git
- keep camera discovery and other Raspi3-02-only checks in its device runbook or as explicit optional checks, not in the general defaults
- use a read-only-by-default installer with explicit apply, timestamped backup and rollback; do not enable or start the boot service during installation
- document activation, a safe manual simulation, expected results and rollback in a dedicated general chapter

Approved public-IP behavior:

- Enable public IPv4 lookup by default, as requested by the user on 2026-09-24.
- Use `https://cloudflare.com/cdn-cgi/trace`, force IPv4 and parse only the `ip=` field.
- Limit the connection attempt to 3 seconds and the complete request to 8 seconds.
- Treat lookup failure as `unavailable`; it must not fail or suppress the rest of the report.
- Explain that the request exposes the public source address to Cloudflare and provide a local `PUBLIC_IP_LOOKUP=false` opt-out.

Implementation prepared for review:

- Added a reusable Bash report, systemd oneshot, strict configuration example, safe installer and focused asset README under `src/monitoring/boot-report/`.
- Added a step-by-step chapter covering legacy discovery, prerequisites, default Cloudflare lookup, optional service and peer checks, read-only validation, installation, preview, delivery test, activation, real-boot verification, legacy retirement and rollback.
- The core report includes host, time, OS, kernel, local and public network state, temperature, load, memory, root storage, throttling, reboot-required state and failed systemd units without Python dependencies.
- Device-specific services and peers remain in an ignored local configuration. Camera MAC discovery is deliberately excluded from the general implementation.
- The installer defaults to read-only validation, uses timestamped allowlisted backups and automatic failure rollback, and does not enable or start the service, contact Cloudflare, send a notification, restart another service or reboot.
- Bash parsing, a no-network preview smoke test, Markdown fences, local links, whitespace, LF and sensitive-data pattern checks passed locally. Native systemd verification, Cloudflare lookup, notification delivery and real-boot behavior remain Raspberry Pi pre-deployment checks.
- Removed device-specific deployment-history wording from the general chapter and expanded legacy discovery with read-only systemd, `rc.local`, cron and script-location checks plus candidate-unit inspection.

### OpenVPN client watchdog assessment

Status: committed locally in the focused `Add reusable OpenVPN watchdog` commit on 2026-09-25; nothing has been deployed or activated.

Sources compared:

- the repository's general VPN, Athens-Crete VPN and hardware-watchdog documentation
- the deployed Raspi3-02 VPN watchdog bundle
- the earlier OpenVPN-watchdog discussion and its test results

Useful behavior in the deployed design:

- checks the configured OpenVPN client service, tunnel interface, expected tunnel address and peer reachability
- keeps healthy polling silent and sends durable queued failure and recovery notifications
- exposes a read-only `--check` mode and harmless notification simulations
- uses `flock` to prevent overlapping runs and a systemd timer rather than a long-running shell loop
- retries service recovery at bounded failure counts rather than restarting on every poll
- distinguishes a VPN-specific outage from loss of general Internet access
- suppresses reboot while general Internet access still works and rate-limits any permitted reboot to one per 12 hours
- records failure state under `/run` and the reboot-rate-limit timestamp under `/var/lib`

Problems that prevent direct reuse:

- paths, service name, interface, tunnel address and peer are specific to Raspi3-02
- the root-owned configuration is sourced as shell code rather than parsed as strict data
- the installer also installs unrelated notification, boot-report and camera-monitor components
- restart and reboot behavior is embedded in the device bundle instead of being an explicit reusable policy
- external connectivity endpoints and device assumptions need documented, generic defaults

Requirements recovered from the earlier discussion:

- a healthy OpenVPN service alone is insufficient; tunnel configuration and peer reachability must also be checked
- zero connected clients is normal for an OpenVPN server and must not be treated as a general server failure
- systemd checks must be time-bounded because an earlier generic OpenVPN status query hung
- send a recovery notification after a reported outage and state that no reboot occurred when recovery made it unnecessary
- do not write routine healthy messages to the journal
- disabling the systemd timer is the clean administrative stop mechanism
- an active SSH session may suppress a pending reboot, but it is not evidence that the VPN itself is healthy
- no reliable remote abort exists when both the VPN and every independent management path are unavailable; documentation must not imply otherwise

Recommended reusable design:

- create a focused `chapters/vpn-watchdog.md` and reusable assets under `src/monitoring/vpn-watchdog/`
- monitor an explicitly configured OpenVPN client instance, interface, optional expected local tunnel address and peer
- use time-bounded service and network checks and a strict root-owned configuration parser
- provide read-only `--check` and safe notification-simulation modes that never restart a service or reboot
- make service restart attempts configurable, sparse and bounded; notify on confirmed failure, recovery, successful restart and any reboot suppression
- when general Internet access still works, classify the incident as VPN-specific and never reboot
- keep healthy timer runs silent
- use the durable `raspi-notify` queue rather than direct SMTP
- install with read-only validation by default, explicit apply and rollback modes, and do not enable or start the timer
- support a temporary local reboot-inhibit marker and suppress reboot while interactive users are logged in
- retain a persistent minimum interval between any permitted reboots

Recommended reboot policy:

- Set `ALLOW_REBOOT=false` in the tracked example and reusable default.
- Require explicit per-device opt-in only after boot recovery, VPN recovery, firewall restoration and remote access have been tested on that device.
- Even after opt-in, reboot only for a broader connectivity failure, never for a VPN-only failure while the Internet remains reachable.
- Treat the timer, service restarts and reboots as separate activation decisions in the guide.

Approved device-specific refinements:

- Raspi3-02 normally has no independent remote-administration path outside its persistent client tunnel to Athens. Its intended final local profile may enable a reboot after 12 continuous hours of unresolved failure, with a 12-hour persistent minimum interval between watchdog reboots, after recovery testing succeeds.
- When the Raspi3-02 OpenVPN client process is active and independent Internet access works, loss of the Athens tunnel is treated as a likely remote-endpoint or path outage. OpenVPN continues its own retries; the watchdog must not restart the service or reboot Crete in this state.
- When the local client service is failed, or both the tunnel and independent Internet checks remain unavailable, the local state is not proven healthy. The explicitly enabled Raspi3-02 fallback may reboot after its 12-hour threshold and safeguards.
- Raspi4-01 and Raspi4-02 are OpenVPN servers but are not expected to have clients connected continuously. Server health must use the service, tunnel interface and listening socket, never client count.
- Server reboot remains disabled by default. Confirmed server failure sends multiple durable notifications before any separately approved optional reboot.

Implementation prepared for review:

- Added a focused general chapter and neutral assets under `src/monitoring/vpn-watchdog/` for `client` and `server` roles.
- Added layered client classification so an active reconnecting client plus working ordinary Internet suppresses both restart and reboot instead of mistaking Athens instability for a Crete host failure.
- Accounted for Debian's `Type=notify` OpenVPN unit behavior by accepting a live client `MainPID` as local-process evidence during reconnection, even when the unit is not in the simple `active` state.
- Added server service, interface and TCP/UDP listening-socket checks without any connected-client requirement.
- Added a 10-minute initial notice and reminders near 1, 6 and 11 hours, followed by a separately permitted 12-hour reboot threshold.
- Added separate safe defaults `ALLOW_SERVICE_RESTART=false` and `ALLOW_REBOOT=false`, bounded restart thresholds, a runtime reboot-inhibit marker, logged-in-user suppression and a persistent 12-hour reboot rate limit.
- Added read-only configuration and health validation plus notification-only simulations. The installer uses explicit apply and rollback modes and does not enable the timer, run a check, restart OpenVPN, send a notification or reboot.
- Simplified reader-facing setup language: prerequisite packages are installed directly when missing, OpenVPN client/server roles are named explicitly, repository paths are explained, and optional disable/recovery guidance is separated from normal activation.
- Clarified that installation needs only the `src/monitoring/vpn-watchdog/` asset directory. A full Raspberry Pi clone is convenient but not required; a copied asset directory may be used instead.
- Added the exact public clone command and standardized the suggested Raspberry Pi working copy at `~/Software/raspberry-born`, owned by the normal login user rather than `root`. The documented absolute form uses `/home/{USERNAME}/Software/raspberry-born`.
- The current installer intentionally manages one watchdog profile per host. A future Raspberry Pi that runs both OpenVPN client and server roles should use two isolated watchdog instances; implement that extension only when such a host exists.

## Required backup point

Before reconciliation changes beyond these planning files:

1. Create a timestamped external copy of the complete repository, including `.git`, untracked files and ignored files.
2. Record local commit `e88de61` and remote commit `2086acc` beside the backup.
3. Verify that the backup contains `chapters/ups.md` and the ignored OpenVPN notifier.
4. Do not rely only on `git stash`, because ignored and untracked source material is part of the recovery requirement.

Status: completed and verified.

- Backup path: `C:\Git\personal\raspberry-born-backup-20260919-224947`
- Source file count: 213
- Backup file count: 213
- Recorded local commit: `e88de611d0a73ae16acaa46d42963337f98fc040`
- Recorded remote commit: `2086acc784a1599a29e5d21cf6f7debf46f48254`
- Verified present: `.git`, `AGENTS.md`, `RECONCILIATION.md`, `chapters/ups.md`, `chapters/watchdog.md`, and `src/vpn/OpenVPN-email_inotifywait.sh`

## Action log

### 2026-09-19

- Completed the read-only repository audit.
- Refreshed remote-tracking metadata with `git fetch --prune origin`; no pull or merge was performed.
- Read the two referenced prior Codex tasks.
- Inventoried the final Raspi3-02 and UPS bundles without importing them.
- Confirmed the information-publication policy and final Raspi3-02/UPS deployment status with the user.
- Added `AGENTS.md` and this reconciliation ledger. No existing file was modified by this action.
- User confirmed that `chapters/watchdog.md` should be excluded from the first reconciliation and rebuilt later.
- Created and verified the complete external backup at `C:\Git\personal\raspberry-born-backup-20260919-224947`.
- Created branch `codex/reconcile-2026-09-19` from local commit `e88de61`.
- Created the planning checkpoint commit containing only `AGENTS.md` and `RECONCILIATION.md`.
- Added the earlier OpenVPN-watchdog and boot-email discussions to the investigation backlog without storing their private conversation URLs.
- Reviewed remote commit `20fcd5f`; user approved excluding its dated personal allowlist snapshot from the final guide while preserving the commit in history.

### 2026-09-20

- Reviewed remote commit `bd5a035`; user approved replacing it with the tested case-study structure and reusable `src/vpn/site-to-site/` assets described above.
- Reviewed remote commit `2086acc`; user approved its ignore-rule additions, documentation split and SSH guide subject to the targeted edits recorded above.
- User approved selective preservation of the README changes, replacement of the outdated auto-updates working edit, and deferral of the Grafana, Mosquitto and hardware-watchdog drafts.
- Verified that the external backup copies of `README.md` and `chapters/auto-updates.md` matched their working copies byte-for-byte.
- Restored those two tracked working files to the local baseline; all untracked and ignored files were left untouched.
- Rebased `codex/reconcile-2026-09-19` successfully onto `origin/main`. Local `main` and GitHub were not changed.
- Refined the Pi-hole decision: retain the useful allowlist knowledge as an explained, machine-readable service-compatibility list rather than deleting it entirely.
- Replaced the dated Pi-hole snapshot with an explained service-compatibility table, a machine-readable allowlist and preview, application, verification and rollback commands.
- Applied the approved SSH guide corrections: explicit Windows/Debian labels, Vim and VS Code conventions, generic usernames, user-key publication rules, and current WinSCP agent or `.ppk` workflows.
- Reviewed and approved the focused SSH documentation diff for commit.
- Completed the read-only comparison between the remote Athens-Crete guide, the final deployed Raspi3-02 routing bundle and the recorded live routing audit. No VPN file was changed or imported.
- User approved the generalized site-to-site asset design and requested an end-stage audit of both the automated and fully manual OpenVPN server setup methods.
- Implemented the generalized site-to-site assets and replacement case-study chapter. No Raspberry Pi was contacted or changed.
- User approved the site-to-site result, requested standalone wording without references to superseded guides, and established "Raspberry Pi" as the normal prose term unless the operating-system distinction matters.
- Final local validation passed for the approved VPN files; native nftables validation remains an explicit Raspberry Pi pre-deployment check.
- Committed the approved generalized Athens-Crete VPN case study and nftables assets in a focused reconciliation commit.
- Reconciled the README navigation for the tracked Athens-Crete VPN and NASPi guides. The UPS link remains intentionally deferred until the UPS chapter is committed, avoiding a broken link.
- User approved splitting the durable notification foundation from the UPS integration.
- Drafted the reusable notification queue, safe installer and replacement email chapter. No Raspberry Pi was contacted or changed.

### 2026-09-22

- Clarified the local SMTP password-file format and documented the expected notification queue verification results.
- Added expected post-recovery outcomes to the UPS guide and replaced the site-specific Internet-provider wording with generic Internet connectivity wording.
- User confirmed that the Mosquitto chapter remains deferred for a later dedicated topic.
- Reopened and rebuilt the hardware-watchdog guide using current Raspberry Pi, Debian watchdog, Linux kernel and systemd documentation. No watchdog was enabled or tested on a Raspberry Pi.

### 2026-09-23

- Clarified exactly where and how to add `kernel_watchdog_timeout=15`, including duplicate detection, `[all]` placement, Vim save instructions and verification before reboot.
- Replaced the vague classic-daemon handoff warning with explicit checks and migration steps that prevent systemd and `watchdog.service` from owning the hardware device simultaneously.
- User approved the notification, UPS-verification and rebuilt watchdog documentation changes. The notification foundation is authorized for its focused local commit; UPS and watchdog remain separate commit scopes.
- Committed the durable notification foundation locally with Linux executable modes for its installer, enqueue command and dispatcher. No push or deployment was performed.
- Added the approved hardware-watchdog guide to README navigation for its separate local commit.
- Committed the rebuilt hardware-watchdog guide and README navigation locally. No watchdog configuration, reboot or Raspberry Pi change was performed.
- Prepared the generalized UPS monitor assets, safe installer, reusable UPS chapter and README navigation. No Raspberry Pi was contacted or changed.
- User reviewed and approved the generalized UPS chunk for its focused local commit.
- Committed the reusable UPS chapter, monitor assets, safe installer and README navigation locally. No NUT configuration, service state, UPS state or Raspberry Pi was changed.

### 2026-09-24

- User approved daily Debian-Security installation without automatic reboot, durable reboot-required alerts, weekly reporting for broader updates and staggered approved full-upgrade maintenance.
- Prepared the replacement automatic-updates chapter and focused `src/maintenance/updates/` assets. No package, service, APT metadata, reboot state or Raspberry Pi was changed.
- User requested a prominent notification prerequisite and a complete opt-in procedure for the conditional 04:45 reboot. Added the documented workflow and repository assets; the reboot profile remains disabled by default and has not been deployed.
- User approved the completed automatic-updates scope. Committed it locally as a separate focused change after staged content, executable modes, whitespace and sensitive-data checks passed. Nothing was pushed or deployed.
- Completed a read-only comparison of the old Python boot-email files and the verified Raspi3-02 boot report. Recorded the reusable design boundaries without importing files, exposing local identifiers or changing a Raspberry Pi.
- User approved the reusable boot-report plan with public-IP lookup enabled by default and requested a safe provider such as Cloudflare. Prepared the generalized chapter and assets without contacting or changing a Raspberry Pi.

### 2026-09-25

- User clarified that general chapters should not call out host-by-host test history and asked how to discover an existing legacy boot-email mechanism. Removed the unnecessary hostname-specific paragraph, added reusable legacy-discovery commands and recorded the rule in `AGENTS.md`.
- User approved the completed reusable boot-report scope. Committed the chapter, assets and permanent documentation rule locally after staged scope, executable-mode, whitespace and sensitive-data checks passed. Nothing was pushed or deployed.
- Completed the read-only OpenVPN client-watchdog comparison. Recorded the reusable health checks, bounded recovery behavior, notification requirements and reboot-suppression boundaries without changing repository implementation files or any Raspberry Pi.
- User approved reboot-off reusable defaults and defined separate Raspi3-02 client and Raspi4 server policies. Prepared the inactive VPN-watchdog chapter and assets; no Raspberry Pi, OpenVPN service, timer or reboot state was changed.
- Simplified the VPN-watchdog chapter after review so it remains practical for rebuilding the owner's hosts and does not mix live-agent approval gates into ordinary reader instructions.
- Clarified the VPN-watchdog file-transfer assumption: the Raspberry Pi may use a full repository clone or a copied watchdog asset directory.
- Recorded the legacy username references in the 2FA chapter and archived Pi-hole guide for later focused cleanup; they remain outside this commit.
- Final VPN-watchdog validation passed for Bash syntax, both role configurations, Markdown fences, relative links, whitespace, LF line endings, staged executable modes and prohibited identifier patterns. Committed the focused scope locally; nothing was pushed or deployed.

## Next controlled chunk

1. Perform the planned read-only audit of the general OpenVPN server setup: compare `chapters/vpn.md`, `src/vpn/openvpn-install.sh` and the archived fully manual method without merging their approaches blindly.
2. Present the server-setup findings and a small set of decisions before editing those files.
3. Decide later, per device, whether proven recovery justifies enabling either the VPN-watchdog reboot fallback or the available conditional 04:45 update reboot profile.
4. Keep Grafana and Mosquitto deferred; do not update local `main`, deploy or push.
