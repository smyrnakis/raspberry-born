# Install and enable 2FA

### Install *Google authenticator*
``` bash
sudo apt-get install libpam-google-authenticator
```

### Configure Google Authenticator
``` bash
google-authenticator

Do you want authentication tokens to be time-based (y/n) y
```

Save the **secret key**, the **verification code** and the **emergency scratch codes**.

<br>

``` bash
Do you want me to update your "/home/tolis/.google_authenticator" file? (y/n) y

Do you want to disallow multiple uses of the same authentication
token? This restricts you to one login about every 30s, but it increases
your chances to notice or even prevent man-in-the-middle attacks (y/n) y

By default, a new token [...] client and server.
Do you want to do so? (y/n) y

[...]
Do you want to enable rate-limiting? (y/n) y
```

### Configure PAM and SSH

Add the line "`auth required pam_google_authenticator.so`" in the file `sshd`:
``` bash
sudo nano /etc/pam.d/sshd
```

Change the `ChallengeResponseAuthentication` to `yes` in `sshd_config`:
``` bash
sudo nano /etc/ssh/sshd_config
```

Restart SSH service
``` bash
sudo /etc/init.d/ssh restart
```
<br>
