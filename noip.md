# Install & configure *noip* client

*Article: http://www.noip.com/support/knowledgebase/install-ip-duc-onto-raspberry-pi/*

### Create a folder
``` bash
mkdir ~/Software/noip
```

### Download
``` bash
cd ~/Software/noip

wget https://www.noip.com/client/linux/noip-duc-linux.tar.gz

tar vzxf noip-duc-linux.tar.gz

rm noip-duc-linux.tar.gz

cd noip-2.1.9-1
```

### Install & configure
``` bash
sudo make

sudo make install
```

```
Auto configuration for Linux client of no-ip.com.

Please enter the login/email string for no-ip.com  XXXXXX@gmail.com
Please enter the password for user 'XXXXXX@gmail.com'  *********

3 hosts are registered to this account.
Do you wish to have them all updated?[N] (y/N)  N
Do you wish to have host [XXXXXX] updated?[N] (y/N)  N
Do you wish to have host [YYYYYY] updated?[N] (y/N)  N
Do you wish to have host [ZZZZZZ] updated?[N] (y/N)  y

Please enter an update interval:[30]  5

Do you wish to run something at successful update?[N] (y/N)  N

New configuration file '/tmp/no-ip2.conf' created.
mv /tmp/no-ip2.conf /usr/local/etc/no-ip2.conf
```

### Extra

#### Start noip
```
sudo /usr/local/bin/noip2
```

#### Check if the service is running
``` bash
sudo noip2 -S
```

#### Configure autostart at system boot

Instructions [HERE](https://github.com/smyrnakis/raspberry-born/blob/main/autostart.md).

<br>
