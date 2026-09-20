# Initial settings

### Change default password
```
pi@raspberrypi:~ $ passwd
Changing password for pi.
Current password:
New password:
Retype new password:
passwd: password updated successfully
```

### Rename default user `pi`

Set `root` password:
```
sudo passwd root
Changing password for root.
New password:
Retype new password:
passwd: password updated successfully
```

Permit `root` login by changing `PermitRootLogin` to `yes` in `/etc/ssh/sshd_config`:
``` bash
sudo nano /etc/ssh/sshd_config	-->	PermitRootLogin yes
```

**Reboot** and log in as `root`.

Create new user and copy user's `pi` data (replace *`{newusername}`* with the new username):
``` bash
usermod -m -d /home/{newusername} -l {newusername} pi
```

### Add new user to ***sudoers***:
``` bash
visudo
```
Replace user `pi` or add a new line if not there (replace *`{newusername}`* with the new username):
``` bash
{newusername}   ALL=(ALL) ALL
```

### Add SSH keys

Generate a different SSH key for each laptop. Keep private keys only on the laptop and add only the public keys to the Raspberry Pi.

Follow the detailed [SSH key guide](ssh-keys.md) for:

- Windows Terminal
- WinSCP
- adding the laptop key to each Raspberry Pi
- testing and removing laptop keys

**Before closing** the existing connection, verify on a new terminal that the new key authentication works fine!

Logout `root` user:
``` bash
logout
```

<br>

Repeat [Add the public key to a Raspberry Pi](ssh-keys.md#add-the-public-key-to-a-raspberry-pi) for the main user.

<br>
