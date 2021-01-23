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

Restart SSH service:
``` bash
sudo service ssh restart
```

<br>

### fail2ban

:warning:
> fail2ban may not work correctly with OpenVpn and/or Pi-hole or any combination of those! To be updated...

*Article: https://pimylifeup.com/raspberry-pi-fail2ban/*

<br>

Install and prepare the config file:
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

Instructions [HERE](https://github.com/smyrnakis/raspberry-born/blob/main/chapters/2FA.md) .

<br>

### Uncomplicated Firewall (UFW)  -  iptables

> Although not mandatory, it's crucial to install *ufw* in order to secure the Raspberry Pi **and** to ensure that the SSH port is not getting locked by any future operation that might affect *iptables*.

*Article: https://manpages.ubuntu.com/manpages/bionic/man8/ufw.8.html*

*Article (iptables): https://www.digitalocean.com/community/tutorials/how-to-list-and-delete-iptables-firewall-rules*

<br>

#### UFW

Install *ufw* :
``` bash
sudo apt install ufw
```

Do not forget to permit SSH service!
``` bash
sudo ufw allow ssh

# if fail2ban is NOT installed, consider using:
sudo ufw limit ssh

# enable ufw
sudo ufw enable
```

Check the status of the service:
``` bash
sudo ufw status
```

To disable the service, use:
``` bash
sudo ufw disable
```

#### iptables

*For the `iptables` commands, it's better if you enter elevated mode by using:*
``` bash
sudo su
```

<!--

Enable the firewall:
``` bash
/etc/init.d/iptables start
```

Enable start of `iptables` on boot:
``` bash
chkconfig iptables on
```

Stop the firewall:
``` bash
/etc/init.d/iptables save
/etc/init.d/iptables stop
```

Disable start of `iptables` on boot:
``` bash
chkconfig iptables off
```

-->

Save the rules to a file:
``` bash
mkdir /etc/iptables

# IPv4 rules
iptables-save > /etc/iptables/rules.v4

# Ipv6 rules
ip6tables-save > /etc/iptables/rules.v6
```

Restore rules
``` bash
iptables-restore < /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6
```

<br>

### Log files

- `/var/log/syslog` : main log for all services
- `/var/log/messages` : all systems log
- `/var/log/auth.log` : authentication attempts
- `/var/log/mail.log` : mail server
- `/var/log/pihole.log` : Pi-hole log
- `/var/log/openvpn.log` : OpenVPN log
- `/var/log/openvpn-status.log` : OpenVPN connections log

<br>

### Interesting articles

- [17 security tips for your Raspberry Pi](https://raspberrytips.com/security-tips-raspberry-pi/)

<br>
