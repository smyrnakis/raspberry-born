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

As of 2026-10-08 after publishing the reconciliation branch:

- Reconciliation branch: `codex/reconcile-2026-09-19`.
- The branch is based on `origin/main` at `2086acc` and contains the planning checkpoint plus focused reconciliation commits.
- The three reviewed remote commits are now present in the branch history.
- Local `main` remains unchanged at `e88de61`.
- The reconciliation branch is published as
  `origin/codex/reconcile-2026-09-19`. Remote `main` remains unchanged.
- The automatic-updates, boot-report and VPN-watchdog commits are complete.
- The maintained OpenVPN server workflow and byte-preserved legacy archive are
  committed locally as `5345789`.
- The multi-recipient and boot-bound notification extension is committed
  locally as `e2eb2f1`.
- The UPS incident-message and outage-summary refinement is committed locally
  as `046dc9f`. No generic repository update was deployed.
- Remote commit `dc51366` (`Link Raspberry Pi network monitor`) was integrated
  by merge commit `9af51c8`. Its README link is present alongside all approved
  reconciliation-branch navigation additions.
- The rebuilt SSH password-and-TOTP guide is committed as `29136ad`.
- The approved Pi-hole v6 guide, optional GPIO LED service, archived legacy
  guide marker and deferred Raspberry Pi Zero 2 W redundancy design are
  committed as `96ae502`. The commit removes the copied legacy installer and
  blocklist-updater ZIP and repairs the OpenVPN chapter's Pi-hole link. No
  Raspberry Pi was changed.
- Against the current local `origin/main` reference, the branch is 21 commits
  ahead and zero commits behind.
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
- SSH authentication should allow either a valid SSH key by itself or the
  account password followed by TOTP. Password-only access must not be allowed,
  and SSH-key access must not request TOTP.
- Omit the obsolete Pi-hole `TO BE FIXED` external updater section. Retain the
  generic `/etc/hosts` mapping example and rebuild the optional Pi-hole LED
  integration with a current GPIO interface and managed service.
- Keep Pi-hole in `LOCAL` listening mode for directly connected trusted LAN and
  OpenVPN subnets. Do not use `ALL` or advertise a public secondary resolver,
  because either choice can bypass the intended filtering boundary.
- Preserve the three recorded threat, cryptocurrency-mining and phishing
  blocklists, but add them individually and rely on Pi-hole's weekly gravity
  refresh rather than a third-party updater.
- `chapters/pihole-redundancy.md` records a future active-active Raspberry Pi
  Zero 2 W design with restricted SSH, 2FA, unattended security updates,
  durable notifications and symmetric peer monitoring. It is a deferred design
  note only. Do not implement it or add monitoring assets until the discussion
  is explicitly resumed.
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

### General OpenVPN server setup assessment

Status: read-only audit completed on 2026-09-25. No server guide, installer, archived asset or Raspberry Pi was changed.

Sources compared:

- active guide `chapters/vpn.md`
- customized installer `src/vpn/openvpn-install.sh`
- archived manual guide and assets under `src/vpn/archive/`
- current upstream Nyr installer
- current OpenVPN 2.6 cipher-negotiation documentation
- current Easy-RSA release information
- Debian 12 OpenVPN package service layout

Security and repository scan:

- No live private key, password, personal email address, MAC address, public DDNS name or generated `.ovpn` profile was found in the tracked files reviewed.
- The installer and archived profile builder generate `.ovpn` files containing the client private key and the shared TLS key. These outputs are credentials and must remain outside Git, be transferred securely and not be kept in a general user home directory longer than necessary.
- Personal email placeholders in certificate metadata are unnecessary and conflict with the public-repository policy. Certificate identity fields should remain generic unless they serve a verified operational purpose.

Active guide and customized-installer findings:

- The chapter downloads a moving third-party script and then asks the reader to patch it by historical line number. This is fragile and cannot be reproduced safely after upstream changes.
- The chapter calls its repository copy a 2024 version, while the script header records a 2023 customization and differs substantially from current upstream.
- The local fork permits Debian 9 and pins Easy-RSA 3.1.2. Current upstream requires Debian 11 or later and uses Easy-RSA 3.2.7 as of this audit.
- Both the local fork and current upstream query a No-IP endpoint over plain HTTP to suggest the public address. A maintained repository implementation should use an HTTPS endpoint or require explicit input.
- The local fork forces `cipher AES-256-CBC` in server and client configuration. OpenVPN 2.5 and later use `data-ciphers` negotiation, and OpenVPN 2.6 defaults to modern AEAD ciphers. A legacy fallback should be added only for a confirmed older peer.
- The installer downloads and extracts Easy-RSA without verifying an archive hash or signature.
- One run installs packages, creates the CA and client credentials, changes IP forwarding and firewall state, enables services and starts OpenVPN. It has no read-only check, configuration preview, backup or failed-install rollback.
- The installer stores the unencrypted CA private key on the VPN server. This is a valid practical design only if it is documented deliberately, protected root-only and backed up securely. It conflicts with the chapter's later blanket recommendation for a separate CA machine.
- The installer creates its own persistent iptables systemd service, while the chapter separately tells the reader to add a UFW rule. Firewall ownership is therefore duplicated and unclear.
- The removal option disables services, removes the complete server PKI/configuration directory and purges OpenVPN. It is unsuitable as an ordinary maintenance command without an explicit verified backup and destructive confirmation boundary.
- Generic `service openvpn` commands do not identify the configured instance. Debian 12 packages provide `openvpn-server@.service`; the guide should use the exact instance, such as `openvpn-server@server.service`, and journal-based diagnostics.
- Direct-msmtp notification, root cron, NOPASSWD sudoers and status-log polling duplicate the newer durable notification queue and VPN watchdog. They should be retired from the core server guide.
- The LED procedure is device-specific and uses the deprecated sysfs GPIO interface. It does not belong in the general OpenVPN installation path.
- Pi-hole DNS integration needs a deliberate policy. Supplying a public resolver after Pi-hole allows clients to bypass Pi-hole filtering whenever they choose or fail over.
- The suggested long-term storage under `/etc/openvpn/client/YYYYMMDD` is not an adequate client-profile custody policy merely because it is under `/etc`.

Archived manual-method findings:

- The archive describes an older OpenVPN and Easy-RSA layout, `tls-auth`, `ncp-disable`, fixed `AES-256-CBC`, manually restricted TLS cipher suites and old `openvpn@server` service paths.
- It combines UFW edits, a permissive forwarding policy and a separate non-persistent iptables command without defining one firewall owner or rollback.
- Its archived `MakeOVPN.sh` does not quote client-controlled file names, contains a certificate-name output typo and embeds private client and shared TLS keys in generated profiles.
- It copies client private material into `/etc/openvpn/client` on the server and uses ambiguous recursive permission commands.
- The method is useful only as historical context. Git history already preserves it, so current-looking runnable archived assets create more risk than value.

Recommended direction:

- Keep one authoritative general OpenVPN server guide for Debian and Raspberry Pi OS.
- Replace the line-number patching workflow and broad third-party installer fork with repository-owned, focused and reviewable configuration assets and lifecycle commands.
- Separate server installation, client certificate/profile lifecycle, Pi-hole DNS policy, site-to-site routing, monitoring/notifications and optional hardware indicators.
- Make inspection and configuration rendering read-only by default. Use an explicit apply action, timestamped allowlisted backups, exact service units, validation and documented rollback.
- Use one declared firewall owner. Do not choose or migrate the live firewall implementation until Raspi4-01 and Raspi4-02 have been inspected read-only.
- Treat the archived manual guide and its configuration assets as superseded. Preserve their history in Git rather than presenting them as an alternative installation route.
- Inspect Raspi4-01 and Raspi4-02 read-only before finalizing the replacement so the guide preserves working deployment details and compatibility requirements.

Approved direction and archive requirement:

- The user approved replacing the customized third-party installer with a repository-owned focused implementation.
- Keep the existing automated and manual documents and assets for historical reference in a dedicated top-level `archive/openvpn/` tree.
- Archived material must have a prominent README stating that it is superseded, may contain unsafe or incompatible instructions and must not be executed as a current guide.
- The archive is not linked as an alternative installation method from the main README or active OpenVPN chapter.

Approved replacement design:

- Keep the user-facing setup in one command-first file: `chapters/vpn.md`. Put explanations and limitations next to the commands they affect instead of adding design or planning sections.
- Keep `src/vpn/server/README.md` to a minimal asset pointer. Implementation scripts and templates may remain under `src/`, but readers should not need to assemble the procedure from multiple README files.
- Preserve external port `11194` as the tailored example. Both the archived manual profile and the archived automated guide's worked installation use `11194`; no `40194` occurrence was found in the current repository or its OpenVPN history.

#### Repository layout

```text
chapters/vpn.md                         authoritative server guide
src/vpn/server/README.md                asset scope and safety model
src/vpn/server/vpn-server.conf.example  non-secret local choices
src/vpn/server/server.conf.template     maintained OpenVPN template
src/vpn/server/install-server.sh        check, apply and rollback
src/vpn/server/manage-client.sh         list, create, export and revoke clients
src/vpn/server/firewall/                one audited firewall implementation
archive/openvpn/README.md               superseded-material warning
archive/openvpn/automated/              old chapter, installer and related assets
archive/openvpn/manual/                 old manual guide and its assets
archive/openvpn/extras/                 old email and GPIO LED scripts
```

- Keep `src/vpn/site-to-site/` active and separate. The general server installer must not silently apply the Athens-Crete routing configuration.
- Keep `chapters/vpn-watchdog.md` and the durable notification queue as separate post-install integrations linked from the main guide.
- Add `.ovpn`, PKCS#12 exports and the local server configuration/output paths to Git ignore protection without using an overly broad pattern that hides legitimate templates.

#### Guide scope and sequence

1. State supported Debian/Raspberry Pi OS and OpenVPN versions and distinguish a new installation from adopting an existing server.
2. Run a read-only inventory of interfaces, routes, ports, package versions, exact OpenVPN instance units, configuration locations, PKI, forwarding, firewall owner, router/NAT assumptions, Pi-hole behavior and existing clients.
3. Record local choices in an ignored root-owned configuration copied from `vpn-server.conf.example`.
4. Install required Debian packages as an explicit documented step. Do not run an unconditional full system upgrade.
5. Initialize or adopt the PKI without overwriting an existing CA, certificate, key or CRL.
6. Render and validate the OpenVPN and firewall configuration before installation.
7. Apply only after an explicit command, with timestamped allowlisted backups and automatic restoration when validation fails.
8. Enable or restart the exact `openvpn-server@server.service` instance in a separate, clearly identified disruptive step.
9. Verify the listener, tunnel, forwarding, DNS, Internet routing policy, client connection, journal and reboot recovery with expected results.
10. Add clients, transfer profiles, revoke clients, renew certificates, back up the PKI and roll back configuration through separate lifecycle sections.

#### Server configuration choices

- Default to UDP and allow different external router and internal OpenVPN ports. Explain both values and the required router port-forward without embedding a live public address or DDNS name.
- Support an explicit full-tunnel or split-tunnel choice. Do not assume all deployments need `redirect-gateway` or Internet NAT.
- Use `topology subnet`, client certificates, `tls-crypt`, `tls-version-min 1.2`, a CRL and current `data-ciphers` negotiation. Do not force legacy CBC or compatibility mode unless a tested client requires it.
- Keep restrictive-network TCP access as an optional second OpenVPN instance with its own service, port, status file and client profile. Do not suggest changing the main UDP profile in place without a complete multi-instance procedure.
- Use the systemd journal and the instance status file for diagnostics. Do not maintain duplicate flat logs merely to support old polling scripts.
- Do not add direct SMTP hooks, root cron jobs, passwordless sudo notification scripts or GPIO behavior to the core server configuration.

#### PKI and secret model

- Practical default: keep the CA on the OpenVPN server, protect the CA private key with a strong passphrase, restrict it to `root` and maintain an encrypted offline backup. This keeps client issuance manageable while improving on the current unencrypted CA key.
- Keep the server private key unencrypted but root-only because the service must start unattended. Back it up only as part of the encrypted PKI backup.
- Use one certificate and private key per client device. Never reuse one profile across a phone, laptop and Raspberry Pi.
- Password-protect client private keys for laptops, phones and other interactive devices. OpenVPN Connect can save the private-key password so the user does not need to enter it on every connection.
- Do not add `setenv ALLOW_PASSWORD_SAVE 0` to generated profiles. Clearly distinguish a client private-key password from optional server-side username/password authentication; the planned certificate-only server does not require adding a second login password.
- For OpenVPN Connect on Android and iOS, document saving the password in the device keychain and require a strong device screen lock. For Windows and macOS, document the corresponding saved private-key-password option.
- For unattended Raspberry Pi clients, permit an unencrypted client key only when it is root-owned, mode `0600`, unique to that device and promptly revocable. Storing its password beside it would not materially improve protection.
- Document an optional client-generated CSR workflow for administrators who do not want client private keys created on the server, without making that advanced path the main setup.
- Never place a CA key, server key, client key, TLS key, live profile, passphrase, endpoint or DDNS name in Git.

#### Generated client profiles

- Generate one inline `.ovpn` profile per client. It normally contains connection directives, the public CA certificate, the public client certificate, the client private key and the `tls-crypt` shared secret. It also contains the real endpoint and port.
- Because the inline profile contains authentication secrets, possession of an unencrypted working profile can be sufficient to connect until its certificate is revoked.
- Create exports temporarily under `/root/openvpn-client-exports/`, with the directory mode `0700` and each profile mode `0600`. Do not use `/etc/openvpn/client/` as an export archive because Debian uses that path for active OpenVPN client instances.
- Transfer profiles over verified SSH using `scp`, SFTP or WinSCP. Never disable SSH host-key checking and never send profiles by ordinary email or store them in the repository.
- Keep durable profile copies in a separate encrypted secrets store or encrypted offline backup on the administration laptop. After successful import and backup verification, remove the temporary server export.
- The Easy-RSA PKI may retain a generated client private key for convenient re-export in the practical default workflow. The guide must state this clearly and offer the CSR workflow when keeping client private keys only on their destination is required.
- Record only non-secret inventory in Git or the device runbook: client certificate name, owning device, issuing server, serial or fingerprint, issue date, expiry date and revocation status. Do not record the profile contents or public endpoint.
- Provide target-specific import notes for Windows, mobile devices and unattended Raspberry Pi clients, including deletion of temporary transfer copies after import.
- Optimize the normal laptop and mobile workflow for import once, save the private-key password in OpenVPN Connect and connect later without repeated password entry.

#### Pi-hole compatibility

- Cover both Pi-hole on the OpenVPN server and Pi-hole on another LAN host.
- Push only the Pi-hole DNS address by default so ordinary DNS requests from VPN clients are filtered. Do not also push a public resolver because that creates an intentional filtering bypass.
- If DNS resilience is preferred over guaranteed filtering, document a public fallback as an explicit alternative policy and explain the tradeoff.
- Verify Pi-hole's current interface-listening mode, UDP and TCP port 53 access from the VPN subnet, routing and return path before changing it.
- Prefer Pi-hole's `Allow only local requests` mode when OpenVPN and Pi-hole run on the same Raspberry Pi and Pi-hole recognizes the tunnel subnet as locally attached.
- `Permit all origins` makes Pi-hole answer DNS requests arriving on any interface and from non-local source networks. It does not itself open a router port, but it removes Pi-hole's source-network safeguard and can create an Internet-accessible open resolver if firewall or router rules expose port 53.
- Do not select `Permit all origins` merely to make the VPN work. If a routed VPN design genuinely requires it, permit DNS only from the intended LAN and VPN ranges in the firewall and verify that public interfaces cannot reach port 53.
- Verify with direct DNS queries to the Pi-hole VPN or LAN address and confirm the request appears in Pi-hole before declaring the integration complete.
- Note that pushed DNS settings cover normal DNS. Client-side encrypted DNS, Android Private DNS, browser DNS-over-HTTPS or applications with built-in resolvers can bypass Pi-hole and need separate client policy if complete enforcement is required.
- Keep the detailed Pi-hole-side settings in `chapters/pihole.md` and link the two chapters in both directions so they cannot drift independently.

#### Firewall and fresh-installation safety

- The new guide targets fresh Raspberry Pi installations. It does not migrate, replace or normalize Raspi4-01 or Raspi4-02.
- Use one documented firewall owner for the fresh-installation design. Do not combine an installer-created iptables service, UFW rules and nftables rules.
- Never flush an existing ruleset or replace `/etc/nftables.conf` blindly. Render the proposed rules, validate them and show the diff first.
- Keep router port-forwarding outside the Raspberry Pi installer and document it as a separate network-device action.
- Refuse to apply the fresh-installation workflow when an existing OpenVPN server configuration or PKI is detected. Direct the reader to back up and assess that host manually rather than treating it as a fresh installation.
- Back up any pre-existing firewall and forwarding files touched during setup, even on a nominally fresh host.
- Do not provide a one-command destructive uninstall. Rollback restores the managed files from a selected backup; package purge and PKI deletion require a separate manual procedure.

#### Existing installations

- Raspi4-01 and Raspi4-02 remain unchanged and are not prerequisites for writing the new-installation guide.
- Do not spend project time migrating the existing servers unless the user opens a later dedicated task for that purpose.
- A future read-only inspection may still be useful for documenting their device runbooks, but it must not delay the fresh-installation chapter.

First implementation chunk prepared for review:

- Moved the previous automated guide, customized installer and Diffie-Hellman file to `archive/openvpn/automated/` without changing their contents.
- Moved the older manual guide and supporting assets to `archive/openvpn/manual/` without changing their contents.
- Moved both tracked notification/LED scripts and the formerly ignored inotify notification script to `archive/openvpn/extras/`.
- Added `archive/openvpn/README.md` with a prominent warning that the material is superseded and must not be used as current instructions.
- Replaced `chapters/vpn.md` with a clearly marked, non-deployable scaffold for the approved fresh-installation design.
- Added `src/vpn/server/README.md` and `vpn-server.conf.example`. No installer, server template or firewall asset exists yet, so the scaffold cannot be mistaken for a complete deployment procedure.
- Simplified the temporary chapter scaffold and asset README after user review. The final chapter will contain exact commands and nearby explanations rather than design decisions or a planned-procedure essay.
- Changed the example external router port from `1194` to the repository's established tailored value `11194`; the internal OpenVPN listening port remains `1194`.
- Replaced the old Pi-hole `Permit all origins` default with the safe local-request policy, VPN-only Pi-hole DNS expectations and an explanation of encrypted-DNS bypass.
- Removed the obsolete ignored-notifier rule and added Git ignore protection for live server configuration, generated output, `.ovpn`, `.p12` and `.pfx` files, plus LF attributes for maintained server assets.
- Verified that every previously tracked archived file has the same Git blob hash after the move. Verified the formerly ignored notifier byte-for-byte against the external backup.
- Markdown structure, relative links, strict configuration-schema syntax, ignore behavior, whitespace and prohibited sensitive-data patterns passed local validation.
- Nothing was staged, committed, pushed or deployed. No Raspberry Pi was contacted or changed.

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
- Completed the read-only audit of the active and archived general OpenVPN server installation methods. Confirmed that neither method is suitable as the future authoritative workflow without redesign; no VPN implementation file or Raspberry Pi was changed.
- Confirmed that later focused reviews must replace hardcoded username paths in `chapters/2FA.md` and `src/archive/pihole.md`; no change to those files was made in this chunk.

### 2026-09-26

- User approved the repository-owned OpenVPN server direction and requested that all existing automated and manual material be retained in a dedicated legacy/archive location.
- Prepared the detailed replacement proposal covering archival layout, server setup, PKI custody, generated profile contents and storage, unattended clients, Pi-hole DNS policy, firewall ownership, adoption of existing servers, validation and rollback.
- User approved the detailed replacement proposal and clarified that it is intended for fresh installations, not migration of Raspi4-01 or Raspi4-02.
- Recorded the usability requirement that OpenVPN Connect users on laptops and phones can save the password protecting the client private key and connect later without retyping it.
- Confirmed Pi-hole-only pushed DNS as the default for VPN clients, documented the meaning and exposure risk of `Permit all origins`, and recorded the limitation that client-side encrypted DNS can bypass pushed DNS.
- User explicitly authorized the first implementation chunk.
- Archived the superseded OpenVPN material without rewriting it, created the non-deployable replacement scaffold and configuration schema, updated the Pi-hole VPN policy and added generated-profile ignore rules.
- User requested a shorter, single-file, command-first guide. Simplified the chapter scaffold and asset README and restored external port `11194` from the archived setup evidence.
- Replaced the placeholder with the first command-first setup chunk: fresh-host inspection, Debian package installation, protected Easy-RSA CA creation, server credentials, maintained OpenVPN 2.6 template and read-only validation before activation.
- Removed the unused `vpn-server.conf.example` schema so local choices are not duplicated between a separate configuration file and the authoritative chapter. Kept `src/vpn/server/README.md` as a minimal asset pointer.
- This chunk deliberately does not activate OpenVPN or change forwarding, nftables, router or Pi-hole service state. No Raspberry Pi was contacted.
- No Raspberry Pi was contacted or changed. The chunk remains uncommitted for review.

### 2026-09-29

- Added expected outcomes and stop conditions for every fresh-installation inspection command in the OpenVPN server chapter.
- Selected a 15-year CA and 5-year server/client certificates with RSA 3072 and SHA-256 as the maintenance/security balance. Added daily certificate-expiry monitoring with durable notices beginning at 180 days for the CA and 90 days for issued certificates.
- Made DNS conditional: same-host or LAN Pi-hole remains the only resolver when filtering is required; installations without Pi-hole use the Cloudflare resolver pair in the documented example.
- Clarified the later Pi-hole installation path: remove all public DNS pushes, add the Pi-hole address, restart the OpenVPN server and reconnect clients; existing client profiles remain valid.
- Clarified that the installed client-management command is a stable snapshot and does not need reinstalling for each client. Added source-commit recording, checksum verification, reviewed fast-forward updates, Bash validation, a read-only post-update check and rollback to the previous installed copy.
- Promoted unattended Raspberry Pi client creation to its own subsection and explained the ownership, group, mode and temporary-copy behavior of the profile-transfer `install` command.
- Completed the command-first fresh-server workflow: IPv4 forwarding, dedicated non-flushing nftables tables, router forwarding, exact service activation, password-protected interactive client profiles, unattended-device profiles, secure transfer, external verification, certificate renewal, revocation, reboot recovery and configuration rollback.
- Added maintained nftables, sysctl, client-management and certificate-monitoring assets under `src/vpn/server/`. No live endpoint, profile, key or other secret was added.
- Git Bash syntax validation passed for both new scripts. Markdown fences, relative paths, whitespace and sensitive-data checks remain required before approval. Native nftables and OpenVPN parsing remain Raspberry Pi pre-deployment checks.
- Nothing was staged, committed, pushed or deployed. No Raspberry Pi was contacted.

### 2026-10-06

- Committed the approved OpenVPN server workflow and legacy archive locally as
  `5345789`. Nothing was pushed or deployed, and no Raspberry Pi was contacted.
- Extended the generic durable notification design so `MAIL_TO` can contain one or more comma-separated recipient addresses without spaces.
- Updated both installer-time and dispatcher-time validation, separate SMTP envelope recipients, the visible `To:` header, the public configuration example and the notification documentation.
- Reviewed the concurrent notification and UPS updates together. The generic
  UPS monitor correctly depends on the extended `raspi-notify` interface, and
  the boot-only shutdown notice remains separate from the durable restoration
  summary.
- Tightened sender and recipient validation so the implementation now rejects
  the quotes, display names, semicolons and angle brackets prohibited by the
  documentation.
- General UPS subject examples now use `[HOSTNAME]`, and the shutdown notice
  describes the expected shutdown rather than claiming success before it
  completes.
- Notification Bash syntax, recipient-list rejection, boot-only argument
  ordering and whitespace checks passed locally.
- Committed the generic notification extension locally as `e2eb2f1`.
- The Raspi3-specific UPS implementation had previously been validated and
  synchronized with its saved bundle. The generic UPS refinement was committed
  locally as `046dc9f` without deployment or Raspberry Pi changes.
- Inspected remote-only commit `dc51366`. Its two-line README addition links the
  separate `raspi-network-monitor` repository and does not replace the local
  README additions, but it still requires an approved integration step.
- Refreshed `origin`, confirmed that `dc51366` remained the only remote-only
  commit, and integrated it with merge commit `9af51c8`.
- Verified that the merge added only the network-monitor README entry and
  preserved the automatic-updates, boot-report, notification, VPN-watchdog,
  site-to-site VPN, UPS, hardware-watchdog and NASPi entries.
- The tracked working tree was clean after the merge. Grafana and Mosquitto
  remained untouched and untracked.
- Kept all real recipient addresses out of Git. Nothing was pushed or deployed,
  and no Raspberry Pi was contacted or changed.

### 2026-10-07

- Reviewed the existing 2FA and Pi-hole chapters against current official
  OpenSSH, Debian, Google Authenticator PAM and Pi-hole documentation.
- User clarified that SSH keys must remain a complete login method without a
  TOTP prompt, while password access must require both the account password and
  TOTP.
- Rebuilt `chapters/2FA.md` around the two explicit OpenSSH alternatives
  `publickey` and `keyboard-interactive:pam`, retaining Debian password checking
  inside PAM and disabling the separate password-only SSH method.
- Added read-only inspection, time-synchronization checks, per-user enrolment,
  configuration backup, syntax and effective-value validation, second-session
  tests, expected results, recovery and rollback.
- Updated the README description. Nothing was committed, pushed or deployed,
  and no Raspberry Pi was contacted or changed.

### 2026-10-08

- User approved the rebuilt 2FA chapter for commit and publication on the
  reconciliation branch.
- User approved omitting the obsolete Pi-hole external-updater placeholder,
  retaining the generic `/etc/hosts` example and retaining the optional LED
  idea through a modern implementation.
- Refreshed remote metadata before the approved publication step. The branch
  remained 18 commits ahead and zero behind `origin/main`; no remote branch
  named `codex/reconcile-2026-09-19` existed.
- Committed the approved SSH password-and-TOTP guide, README description and
  ledger decisions as `29136ad` (`Modernize SSH password and TOTP guide`).
- Published `codex/reconcile-2026-09-19` to GitHub and configured the local
  branch to track it. Remote `main` was not changed.
- The local branch and its remote tracking branch matched after publication.
  Grafana and Mosquitto remained untracked and were not published.
- User approved the rebuilt Pi-hole chapter, including its current resolver and
  firewall clarifications.
- Added `chapters/pihole-redundancy.md` as a deferred design note and linked it
  from the active Pi-hole guide. No redundancy implementation or deployment
  was started.
- Completed the staged scope, whitespace and sensitive-content review, then
  committed the approved Pi-hole work as `96ae502` (`Modernize Pi-hole setup
  and archive legacy assets`). Grafana and Mosquitto were excluded.

## Next controlled chunk

1. Review the remaining copied third-party archives and backup scripts. Decide
   individually whether each should be retrieved from upstream, archived,
   replaced, or removed. Do not modify them during the audit.
2. Keep native nftables/OpenVPN parsing and deployment verification as explicit
   fresh-Raspberry-Pi checks; do not claim deployment evidence from Windows
   validation.
3. Decide later, per device, whether proven recovery justifies enabling either
   the VPN-watchdog reboot fallback or the available conditional 04:45 update
   reboot profile.
4. Keep Grafana and Mosquitto deferred for clean rebuilds; do not update local
   `main`, deploy or push.
