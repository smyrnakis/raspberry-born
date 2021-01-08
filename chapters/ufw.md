# Install and configure Uncomplicated FireWall (UFW)

*Article: https://manpages.ubuntu.com/manpages/bionic/man8/ufw.8.html*

*Article (iptables): https://www.digitalocean.com/community/tutorials/how-to-list-and-delete-iptables-firewall-rules*

<br>

### Install *ufw*

``` bash
sudo apt install ufw
```

### Initial settings

``` bash
sudo ufw allow ssh
# if fail2ban is NOT installed, consider using 'sudo ufw limit ssh'

sudo ufw enable
```

### Check status

``` bash
sudo ufw status
```