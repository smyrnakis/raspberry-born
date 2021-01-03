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
{newusername}   ALL=(ALL)   NOPASSWD:  ALL
```

### Add SSH keys

Generate keys:

##### Windows

Use [PuTTY](https://www.putty.org/) *"PuTTY Key Generator"*

- Use both *Save private key* and *Conversions* --> *Export OpenSSH key*.


##### Mac

``` bash
# TO_BE_FIXED
```

Import keys:
``` bash
cd
mkdir .ssh
touch .ssh/authorized_keys
echo "ssh-rsa....." >> .ssh/authorized_keys
chmod 700 .ssh
chmod 600 .ssh/authorized_keys
```

Logout `root` user:
``` bash
logout
```

<br>

*Repeat **["Add SSH keys"](https://github.com/smyrnakis/raspberry-born#add-ssh-keys)** for main user.*

<br>
