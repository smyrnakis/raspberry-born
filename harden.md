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

``` bash
sudo nano /etc/ssh/sshd_config  -->  PermitRootLogin no
```

Add at the end of the `sshd_config` file:

``` bash
Match Address 192.168.178.*,127.0.0.1
      PermitRootLogin prohibit-password
```

<br>

### fail2ban

*Article: https://pimylifeup.com/raspberry-pi-fail2ban/*

``` bash
sudo apt-get install fail2ban

sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

sudo nano /etc/fail2ban/jail.local
```

Change the values `bantime`, `findtime` & `maxretry` :

``` bash
bantime  = 30m
findtime  = 15m
maxretry = 3
```

Enable it by changing the value of `enabled` under the `[sshd]`:

``` bash
enabled = true
filter = sshd
banaction = iptables-multiport
```

Restart service:

``` bash
sudo service fail2ban restart
```

To check if *iptables* is running correctly:

``` bash
sudo tail -f /var/log/fail2ban.log
```

To check *iptables* rules (banned IPs):

``` bash
sudo iptables -L -n --line
```

Remove a banned IP using (replace *{line}* with line's number):

``` bash
sudo iptables -D f2b-sshd {line}
```

<br>

### Enable 2-factor authentication

Instructions [HERE](https://github.com/smyrnakis/raspberry-born/blob/main/2FA.md) .

<br>

### Uncomplicated Firewall (UFW)

Instructions [HERE](https://github.com/smyrnakis/raspberry-born/blob/main/ufw.md) .

<br>