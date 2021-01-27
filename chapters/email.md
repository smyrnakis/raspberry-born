# Send emails from Raspberry Pi

*Article 1: https://www.mankier.com/1/msmtp*

*Article 2: https://wiki.archlinux.org/index.php/Msmtp*

<br>

## Install `msmtp`

``` bash
sudo apt-get install msmtp
```

## Configure `msmtp`

Create a configuration file named `msmtprc`. This file can be located in each user's home folder or in `/etc` if it will be the same configuration for all users.
``` bash
# one configuration file on this system
# since the emails will be send only from the root user,
# the permissions are set accordingly

sudo touch /etc/msmtprc
sudo chmod 640 /etc/msmtprc
```

For *GMAIL* account, add the following and replace `{YOUR-GMAIL}` and `{YOUR-PASSWORD}`.
Replace also the `{FROM-NAME}` which should be the name appearing on recipients.
``` bash
account default
host smtp.gmail.com
port 587
tls on
tls_starttls on
tls_trust_file /etc/ssl/certs/ca-certificates.crt

auth login
user {YOUR-GMAIL}
password {YOUR-PASSWORD}
from {FROM-NAME}

account account2
```

> It is recommended that you create an **Application password** in your Gmail account's *"Security Settings"* and use this password in the `msmtprc` file.
> 
> It is possible to avoid typing *clear text* password in the configuration file. More info here: [https://www.mankier.com/1/msmtp#Examples](https://www.mankier.com/1/msmtp#Examples) .


## Test email

Replace `{RECIPIENT-EMAIL}` with the recipient's email:
``` bash
# since the config file is readable only by 'root' user:
sudo su

echo -e "Subject: Test Mail\r\n\r\nThis is a test mail." | msmtp --from=default --syslog=on -t {RECIPIENT-EMAIL}
```

## Debugging

You can print debugging messages in the console by adding the `--debug` command:

``` bash
echo -e "Subject: Test Mail\r\n\r\nThis is a test mail." | msmtp --debug --from=default --syslog=on -t {RECIPIENT-EMAIL}
```

The command `--syslog=on` enables logging on `syslog` which you can examine with:
``` bash
sudo cat /var/log/syslog | grep msmtp
```

<br>
