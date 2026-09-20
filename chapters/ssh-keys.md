# SSH keys

Use a different SSH key for each laptop. The same laptop key can be added to all Raspberry Pis that the laptop needs to access.

> Never copy a private key to a Raspberry Pi, cloud storage or any Git repository. Copy only the public key (`.pub`) to the Raspberry Pis. Do not commit either private or public user keys to this repository.

## Prepare Windows OpenSSH

On the **Windows laptop**, open PowerShell and check that the Windows OpenSSH client is available:

``` powershell
ssh -V
Get-Command ssh-keygen
```

Create the local SSH directory if it does not exist:

``` powershell
$sshDirectory = Join-Path $env:USERPROFILE '.ssh'
New-Item -ItemType Directory -Force -Path $sshDirectory
```

## Generate a laptop key

Use the Windows computer name in the key filename and comment:

``` powershell
$laptopName = $env:COMPUTERNAME.ToLower()
$keyPath = Join-Path $env:USERPROFILE ".ssh\id_ed25519_$laptopName"

ssh-keygen -t ed25519 -a 100 -C "$env:USERNAME-$laptopName" -f $keyPath
```

Enter a strong passphrase when requested. Do not leave the passphrase empty.

The command creates two files:

- `$keyPath` : private key - keep it only on this laptop
- `$keyPath.pub` : public key - add this file to the Raspberry Pis

Display the fingerprint and keep it in the installation notes:

``` powershell
ssh-keygen -lf "$keyPath.pub"
```

Restrict the private key permissions to the Windows account that owns it:

``` powershell
$owner = (Get-Acl -LiteralPath $keyPath).Owner
icacls.exe $keyPath /inheritance:r /grant:r "$($owner):(F)"
icacls.exe $keyPath
```

## Add the public key to a Raspberry Pi

On the **Windows laptop**, display and copy the complete public key:

``` powershell
Get-Content -Raw "$keyPath.pub"
```

Log in using an existing password or trusted key. On the **Raspberry Pi**, prepare `authorized_keys`:

``` bash
install -d -m 700 ~/.ssh
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
vim ~/.ssh/authorized_keys
```

Paste the new public key on a **single new line**, save and exit.

Check the last lines and permissions:

``` bash
tail -n 5 ~/.ssh/authorized_keys
ls -ld ~/.ssh
ls -l ~/.ssh/authorized_keys
```

Repeat this section for every Raspberry Pi that this laptop needs to access. Repeat it for every Raspberry Pi user that needs a separate login.

## Configure Windows Terminal SSH

On the **Windows laptop**, open or create `%USERPROFILE%\.ssh\config` with VS Code:

``` powershell
code "$env:USERPROFILE\.ssh\config"
```

Add one block for each Raspberry Pi. Replace the values in `{brackets}`:

``` sshconfig
Host raspi4-01-local
    HostName {LOCAL-IP-OR-HOSTNAME}
    User {PI-USERNAME}
    IdentityFile ~/.ssh/id_ed25519_{LAPTOP-NAME}
    IdentitiesOnly yes

Host raspi4-01-remote
    HostName {REMOTE-HOSTNAME}
    Port {SSH-PORT}
    User {PI-USERNAME}
    IdentityFile ~/.ssh/id_ed25519_{LAPTOP-NAME}
    IdentitiesOnly yes
```

Connect using the short name:

``` powershell
ssh raspi4-01-local
ssh raspi4-01-remote
```

Before accepting a new or changed Raspberry Pi host key, display its fingerprint through an existing trusted connection or locally on the **Raspberry Pi**:

``` bash
sudo ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
```

Compare it with the fingerprint shown by Windows SSH. Do not accept an unexpected changed host key.

**Before closing** the existing connection, verify in a new Windows Terminal that the new key authentication works!

## Use the same key with WinSCP

Do not generate a second key pair for WinSCP. Use one of the following methods.

### Option A: use the Windows OpenSSH agent

This avoids creating a second private-key file. First complete the [optional `ssh-agent` setup](#optional-cache-the-passphrase-on-windows) below and confirm that `ssh-add -l` lists the laptop key.

Configure the WinSCP site:

1. Select **SFTP** and enter the Raspberry Pi hostname, port and username.
2. Leave **Advanced** --> **SSH** --> **Authentication** --> **Private key file** empty.
3. Save the site and connect. WinSCP can use the key loaded in the Windows OpenSSH agent.
4. Verify the server host-key fingerprint before accepting it.

### Option B: convert the OpenSSH key to `.ppk`

When a private-key file is selected directly, WinSCP uses PuTTY's `.ppk` format. Convert the existing OpenSSH key:

1. Open **WinSCP**.
2. On the Login window, select **Tools** --> **PuTTYgen**.
3. Select **Load** and choose the OpenSSH private key: `id_ed25519_{LAPTOP-NAME}`.
4. Enter the key passphrase.
5. Select **Save private key** and save it beside the OpenSSH key as `id_ed25519_{LAPTOP-NAME}.ppk`.
6. Keep the same strong passphrase on the `.ppk` file.

Restrict the `.ppk` private-key permissions:

``` powershell
$ppkPath = "$keyPath.ppk"
$owner = (Get-Acl -LiteralPath $ppkPath).Owner
icacls.exe $ppkPath /inheritance:r /grant:r "$($owner):(F)"
icacls.exe $ppkPath
```

Configure the WinSCP site:

1. Select **SFTP** and enter the Raspberry Pi hostname, port and username.
2. Select **Advanced** --> **SSH** --> **Authentication**.
3. Select `id_ed25519_{LAPTOP-NAME}.ppk` under **Private key file**.
4. Save the site and connect.
5. Verify the server host-key fingerprint before accepting it.

The OpenSSH and `.ppk` files contain the same private key in different formats. Protect both files and never copy either one to a Raspberry Pi, cloud storage or Git.

## Replace an existing shared key

Do not remove the old shared key yet.

1. Add the new laptop public key to every required Raspberry Pi.
2. Test the new key using Windows Terminal.
3. Test the converted `.ppk` key using WinSCP.
4. Keep an existing SSH connection open while testing.
5. Prepare and test the individual key on the next laptop.
6. Only after the individual laptop keys work, remove the old shared public-key line from each Raspberry Pi.

Removing the old public-key line from `authorized_keys` does not delete any local files. Delete the old private-key copies separately only after all required Raspberry Pis are reachable with the new keys.

## Optional: cache the passphrase on Windows

Run the following two commands once from **PowerShell as Administrator**:

``` powershell
Set-Service -Name ssh-agent -StartupType Automatic
Start-Service ssh-agent
```

Then add the key from a normal PowerShell window:

``` powershell
$laptopName = $env:COMPUTERNAME.ToLower()
$keyPath = Join-Path $env:USERPROFILE ".ssh\id_ed25519_$laptopName"

ssh-add $keyPath
ssh-add -l
```

The private key remains passphrase-protected on disk. WinSCP can use the loaded OpenSSH key directly, or continue using the converted `.ppk` file.

## Remove a lost or retired laptop

On every Raspberry Pi, edit the relevant user's `authorized_keys` file:

``` bash
vim ~/.ssh/authorized_keys
```

Delete the single line whose comment matches the lost or retired laptop. Keep the other laptop keys unchanged.

Test access from another trusted laptop before closing the current connection.
