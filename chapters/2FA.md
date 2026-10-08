# SSH password and TOTP authentication

This guide configures SSH with two allowed login methods:

1. A valid SSH key by itself.
2. The account password followed by a time-based one-time password (TOTP).

Password-only login is not allowed. SSH-key login does not request a TOTP code.

The procedure applies to current Raspberry Pi OS and Debian releases using
OpenSSH, PAM and systemd. Complete [SSH key setup](ssh-keys.md) before changing
remote authentication.

> [!WARNING]
> Keep the current SSH session open until both login methods have been tested
> successfully from a second terminal. A PAM or OpenSSH configuration error can
> prevent new remote logins.

## 1. Inspect the current configuration

Run these read-only commands on the **Raspberry Pi**:

```bash
cat /etc/os-release
sudo sshd -T | grep -E \
  'authenticationmethods|kbdinteractiveauthentication|passwordauthentication|pubkeyauthentication|usepam|permitrootlogin'
sudo grep -RnsE \
  '^[[:space:]]*(AuthenticationMethods|KbdInteractiveAuthentication|ChallengeResponseAuthentication|PasswordAuthentication|PubkeyAuthentication|UsePAM|PermitRootLogin)[[:space:]]' \
  /etc/ssh/sshd_config /etc/ssh/sshd_config.d 2>/dev/null || true
grep -nE 'common-auth|pam_google_authenticator' /etc/pam.d/sshd
timedatectl status
timedatectl show -p NTPSynchronized --value
```

Expected results:

- `sshd -T` prints the effective SSH configuration.
- `/etc/pam.d/sshd` normally contains `@include common-auth` on Debian.
- The final command should print `yes`. Correct time synchronization is
  required for TOTP codes.

Resolve unexpected SSH overrides or unsynchronized time before continuing.

## 2. Install the PAM module

On the **Raspberry Pi**:

```bash
sudo apt update
sudo apt install libpam-google-authenticator
```

The package works with any compatible TOTP application. It does not require the
Google Authenticator mobile application specifically.

## 3. Enrol the SSH user

Run this as the ordinary user who will log in with password and TOTP. Do not run
it through `sudo`:

```bash
google-authenticator
```

Use these answers:

```text
Make authentication tokens time-based: y
Update ~/.google_authenticator: y
Disallow reuse of the same token: y
Increase the time-skew window: n
Enable rate limiting: y
```

Scan the QR code with the chosen TOTP application and confirm that its current
code matches the code shown by the command.

Store the emergency scratch codes securely. Each scratch code can be used only
once. The QR code, secret key, `~/.google_authenticator` file and scratch codes
are authentication secrets. Do not put them in Git, documentation, email or
ordinary notes.

Check the secret file:

```bash
chmod 600 ~/.google_authenticator
ls -l ~/.google_authenticator
```

Expected result: the file is owned by the login user and accessible only by
that user, normally shown as `-rw-------`.

Repeat this section for every account that must support password and TOTP
login. An account without this file can still use an authorized SSH key, but
its password-and-TOTP login will fail.

## 4. Back up the authentication configuration

On the **Raspberry Pi**:

```bash
BACKUP_DIR="/root/ssh-2fa-backup-$(date +%Y%m%d-%H%M%S)"
sudo install -d -m 700 "$BACKUP_DIR"
sudo cp -a /etc/pam.d/sshd "$BACKUP_DIR/pam-sshd"
sudo cp -a /etc/ssh/sshd_config "$BACKUP_DIR/sshd_config"
printf 'Backup directory: %s\n' "$BACKUP_DIR"
```

Keep the displayed path until configuration and testing are complete.

The following command must report that the managed SSH snippet does not already
exist:

```bash
sudo test ! -e /etc/ssh/sshd_config.d/00-raspberry-born-2fa.conf \
  && echo "managed SSH snippet is available"
```

If it produces no output, inspect the existing file instead of replacing it.

## 5. Require the password and TOTP through PAM

On the **Raspberry Pi**:

```bash
sudo vim /etc/pam.d/sshd
```

Find this existing Debian line:

```text
@include common-auth
```

Keep it and add the Google Authenticator module immediately after it:

```text
@include common-auth
auth required pam_google_authenticator.so
```

Do not add the `nullok` option. `common-auth` checks the account password and
`pam_google_authenticator.so` checks the TOTP code. Both must succeed.

Verify the relevant lines:

```bash
grep -nE 'common-auth|pam_google_authenticator' /etc/pam.d/sshd
```

## 6. Configure the two allowed SSH login methods

On the **Raspberry Pi**:

```bash
sudo install -d -o root -g root -m 755 /etc/ssh/sshd_config.d
sudo vim /etc/ssh/sshd_config.d/00-raspberry-born-2fa.conf
```

Add:

```text
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication yes
UsePAM yes
AuthenticationMethods publickey keyboard-interactive:pam
PermitRootLogin no
```

Although `PasswordAuthentication` is set to `no`, password login remains
available through `keyboard-interactive:pam`. This is intentional: PAM asks for
the account password and then the TOTP code. The setting disables the separate
password-only SSH method.

`AuthenticationMethods` contains two space-separated alternatives:

- `publickey`: a valid SSH key completes authentication without TOTP.
- `keyboard-interactive:pam`: PAM requires both the account password and TOTP.

Set safe ownership and permissions:

```bash
sudo chown root:root /etc/ssh/sshd_config.d/00-raspberry-born-2fa.conf
sudo chmod 644 /etc/ssh/sshd_config.d/00-raspberry-born-2fa.conf
```

## 7. Validate before reloading SSH

On the **Raspberry Pi**:

```bash
sudo sshd -t
sudo sshd -T | grep -E \
  'authenticationmethods|kbdinteractiveauthentication|passwordauthentication|pubkeyauthentication|usepam|permitrootlogin'
```

`sshd -t` should produce no output and exit successfully. The effective
configuration should contain:

```text
authenticationmethods publickey keyboard-interactive:pam
kbdinteractiveauthentication yes
passwordauthentication no
pubkeyauthentication yes
usepam yes
permitrootlogin no
```

Do not reload SSH if the syntax check fails or the effective values differ.
Check for an earlier conflicting option in `/etc/ssh/sshd_config` or another
file under `/etc/ssh/sshd_config.d/`.

## 8. Reload SSH

Keep the current session open, then run on the **Raspberry Pi**:

```bash
sudo systemctl reload ssh
systemctl is-active ssh
sudo journalctl -u ssh --since "5 minutes ago" --no-pager
```

Expected results:

- The reload command completes without an error.
- `systemctl is-active ssh` prints `active`.
- The journal contains no configuration or PAM loading error.

## 9. Test both login methods

Open a second terminal on the **Windows laptop**. Do not close the original SSH
session.

### Test SSH-key login

Use an SSH alias already configured by [ssh-keys.md](ssh-keys.md):

```powershell
ssh -o PreferredAuthentications=publickey -o PasswordAuthentication=no {SSH-ALIAS}
```

Expected result: the key login succeeds without asking for the account password
or a TOTP code.

### Test password and TOTP login

Force the client not to offer a key:

```powershell
ssh -o PubkeyAuthentication=no -o PreferredAuthentications=keyboard-interactive {USERNAME}@{HOSTNAME-OR-IP}
```

Expected result:

1. SSH requests the account password.
2. SSH requests a verification code.
3. Login succeeds only when both are correct.

Also confirm that an incorrect TOTP code is rejected. After successful tests,
close the test sessions and then close the original session.

## 10. Recovery and maintenance

If the phone is lost but SSH-key login still works, log in with the key and run
`google-authenticator` again to replace the old TOTP secret. Update the
authenticator application and store the newly generated emergency codes.

To remove TOTP access for one user while retaining key access:

```bash
rm ~/.google_authenticator
```

This removes that user's password-and-TOTP method. It does not remove their SSH
keys.

## Roll back

Use the original open SSH session. Replace `{BACKUP-DIRECTORY}` with the path
created in section 4:

```bash
sudo cp -a "{BACKUP-DIRECTORY}/pam-sshd" /etc/pam.d/sshd
sudo rm -f /etc/ssh/sshd_config.d/00-raspberry-born-2fa.conf
sudo sshd -t
sudo systemctl reload ssh
```

Test a new SSH connection before closing the recovery session.

## References

- [OpenSSH `AuthenticationMethods`](https://man.openbsd.org/sshd_config#AuthenticationMethods)
- [Debian OpenSSH PAM configuration](https://sources.debian.org/src/openssh/1%3A10.0p1-7~bpo12%2B1/debian/openssh-server.sshd.pam.in/)
- [Google Authenticator PAM module](https://github.com/google/google-authenticator-libpam)
