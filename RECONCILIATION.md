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

As of 2026-09-20:

- Reconciliation branch: `codex/reconcile-2026-09-19`; its unpublished checkpoint hash may change when approved ledger updates are amended.
- The branch is based on `origin/main` at `2086acc` and contains the planning checkpoint plus focused reconciliation commits.
- The three reviewed remote commits are now present in the branch history.
- Local `main` remains unchanged at `e88de61`.
- Nothing has been pushed.
- The tracked working tree is clean.
- The deferred untracked chapters remain present: `grafana.md`, `mosquitto.md`, `ups.md` and `watchdog.md`.

## Confirmed project decisions

- The repository should read as a step-by-step guide tailored to the owner's systems but understandable by anyone.
- Hostnames and private LAN or VPN address ranges may be committed.
- MAC addresses, personal email addresses and public DDNS names must not be committed.
- Passwords, tokens, VPN profiles and private keys must never be committed.
- Debian and Raspberry Pi OS are the target platforms. Ubuntu-specific guidance is not authoritative.
- Prefer Vim for Debian editing commands. The Windows laptop uses PowerShell and VS Code.
- `chapters/grafana.md` will not be included in the current reconciliation. Rebuild it in a dedicated session.
- `chapters/mosquitto.md` will not be included in the current reconciliation. Rebuild it in a dedicated session.
- `chapters/ups.md` is intended for inclusion after style, portability and sanitization review.
- The current `chapters/watchdog.md` will be excluded from the first reconciliation and rebuilt later as a safe hardware-watchdog guide.
- UPS scripts and configuration templates should be maintained under `src/`, with the chapter explaining their purpose, operation, installation and verification.
- The Raspi3-02 installation is complete and tested.
- The durable mail queue and UPS watchdog are deployed successfully on Raspi3-02.
- The final UPS shutdown and restart test succeeded.
- The UPS guide must remain reusable for any Raspberry Pi while noting Raspi3-02 as a tested deployment.
- Raspi3-02 needs a dedicated device-specific operational chapter covering its networking, discovery, camera, monitoring, storage-write protections and remote-site role.
- The durable queued email design should become the general notification mechanism for all Raspberry Pis. Older direct-msmtp scripts and instructions will be migrated gradually.
- Raspi4-01 and Raspi4-02 will be inspected read-only later when access details are supplied.
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

### `2086acc` SSH documentation

Status: reviewed and approved for reconciliation with targeted edits.

Approved decisions:

- Keep the expanded SSH private-key ignore rules, then review broader secret-file protection separately so patterns do not hide legitimate templates by accident.
- Keep the README link and simplify `chapters/initial-settings.md` so the dedicated SSH chapter is the authoritative procedure.
- Keep the new `chapters/ssh-keys.md` guide after adapting it to project conventions and current tool behavior.

Required edits to the SSH guide:

- Clearly label commands for the Windows laptop versus Debian Raspberry Pis.
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

Status: leave `chapters/grafana.md`, `chapters/mosquitto.md` and `chapters/watchdog.md` untracked and untouched during the first reconciliation. Their complete copies are also present in the verified backup. Review `chapters/ups.md` separately as the only untracked chapter currently intended for inclusion.

### `chapters/ups.md`

Status: candidate for inclusion.

- Matches the UPS task's final documentation-stage copy by SHA-256.
- Must be reviewed for repository style, generic applicability, sanitization and links to maintained `src/` assets.
- The general guide should not embed Raspi3-02-only paths or values except in a clearly labelled tested-example section.

### `chapters/watchdog.md`

Status: exclude from the first reconciliation and rebuild later.

Findings:

- It documents the hardware watchdog, not the VPN, camera or UPS application watchdogs.
- It already uses Vim, which matches project policy.
- `/boot/config.txt` is version-dependent and may be `/boot/firmware/config.txt` on current Raspberry Pi OS.
- It immediately installs a package and requests a reboot without a read-only discovery phase or approval boundary.
- `max-load-1 = 24` is unexplained and not suitable as a universal value.
- Monitoring `wlan0` could cause unwanted reboots and needs explicit assumptions.
- The fork-bomb test is destructive and unsuitable for a general guide.

Decision: exclude the current file from the first reconciliation commit and rebuild it later as a safe hardware-watchdog guide.

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

## Next controlled chunk

1. Reconcile the SSH documentation from remote commit `2086acc` using the approved targeted edits.
2. Review the exact SSH diff before committing it.
3. Keep the larger VPN replacement for a separate later commit.
4. Do not update local `main` or push anything.
