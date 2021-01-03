# Tips 'n' tricks to secure the Raspberry Pi

### Allow `root` login **only** with key authentication

Disallow `root` login using password by changing `PermitRootLogin` to `prohibit-password` in `/etc/ssh/sshd_config`:
``` bash
sudo nano /etc/ssh/sshd_config	-->	PermitRootLogin prohibit-password
```

Restart SSH service:
``` bash
sudo service ssh restart
```

Delete and lock password for `root` user:
``` bash
sudo passwd -d -l root
```

<br>

### Allow `root` login **only** from local network

*TO BE FIXED*

<br>

### fail2ban

*TO BE FIXED*

<br>

### Enable 2-factor authentication

Instructions [HERE](https://github.com/smyrnakis/raspberry-born/blob/main/2FA.md) .

<br>

### Uncomplicated Firewall (UFW)

*TO BE FIXED*

<br>