# Project instructions

## Purpose

This repository is the durable source of truth for preparing, configuring and operating the owner's Raspberry Pi systems.

Write documentation as a step-by-step guide tailored to the owner's environment while remaining understandable and reusable by other Raspberry Pi administrators.

## Platforms and tools

- Target Debian and Raspberry Pi OS systems. Do not assume Ubuntu behavior.
- State the tested or assumed Debian release and Raspberry Pi model when behavior may differ.
- Prefer `vim` in Debian commands and documentation.
- The Windows administration laptop uses PowerShell and VS Code.
- Clearly label commands as either Windows laptop commands or Raspberry Pi commands.
- Use "Raspberry Pi" in ordinary prose. Mention Debian or Raspberry Pi OS only when the operating-system distinction affects the instructions.

## Public repository information policy

The following may be documented:

- Raspberry Pi hostnames
- Private LAN and VPN address ranges
- Non-sensitive service topology
- Generic usernames and example paths when needed

Do not commit:

- Passwords, tokens or application passwords
- Private SSH keys or private VPN key material
- VPN profiles such as `.ovpn` files
- Personal email addresses
- Device MAC addresses
- Public DDNS names
- Credentials, recovery codes or machine-specific secret files

Use obvious placeholders for excluded values. Before importing a live configuration or external bundle, inspect and sanitize it.

## Documentation and implementation

- Explain the goal, assumptions, safety impact, implementation, verification and rollback where relevant.
- Prefer a general reusable guide, with a separate device-specific document when a Raspberry Pi has a specialized role.
- Keep general scripts reusable. Store site-specific values in documented configuration templates rather than embedding them in scripts.
- Link each operational chapter to its maintained scripts and configuration templates under `src/`.
- Distinguish verified deployed behavior from proposed or untested instructions.
- Do not preserve obsolete instructions merely because they already exist. Mark or replace them deliberately after review.
- Prefer the durable queued notification design over scripts that call SMTP directly. Migrate older notification instructions gradually and keep compatibility explicit during the transition.

## Safety and remote administration

- Begin Raspberry Pi inspections with read-only commands.
- Ask before package installation or upgrades, service restarts, reboots, firewall changes, storage changes, or other potentially disruptive operations.
- Never disable SSH host-key verification.
- Do not expose secrets through commands, logs, documentation or Git history.
- Preserve existing user changes unless replacement is explicitly approved.
- Do not assume a generated configuration was deployed. Record deployment and validation evidence.

## Git workflow

- Read `RECONCILIATION.md` before starting repository work and update it when a decision or material action changes project state.
- Keep changes small and reviewable, with clear commit messages.
- Do not merge, rebase, reset, commit or push without confirming that the current reconciliation step authorizes it.
- Review staged content for secrets and unintended machine-specific data before every commit.
- Keep temporary experiments, generated output and sensitive operational files out of Git.

## Known systems

- `Raspi4-01`: Raspberry Pi 4 in Athens, 500 GB HDD, OpenVPN server, Pi-hole and custom services.
- `Raspi4-02`: Raspberry Pi 4 in Geneva, 500 GB SSD, OpenVPN server, Pi-hole and custom services.
- `Raspi3-02`: Raspberry Pi 3 in Crete, persistent OpenVPN client to Athens, UPS monitoring and specialized remote-site services.
