# Backup Raspberry Pi

*Article: https://raspberrytips.com/backup-raspberry-pi/*

<br>

## Manual backup

> This involves physical access to your your Raspberry Pi. It is also required to shut it down and eject the microSD card.

Plug and mount the microSD card on another computer in order to create a full backup.

#### Mac
``` bash
# list all connected drives & identify the microSD card
sudo diskutil list

# OR
sudo df -h

# create an .img file from the microSD card
# (in the example bellow, the microSD is "/dev/disk2")
sudo dd bs=4M if=/dev/disk2 of=/Users/{USERNAME}/RaspiBackup.img
```

##### Restore backup

:warning: **All contents of `/dev/disk2` will be erased! Be sure it's the correct disk!** :warning:

``` bash
sudo dd bs=4M if=/Users/{USERNAME}/RaspiBackup.img of=/dev/disk2
```

#### Windows
``` powershell
# TO BE FIXED
```

<br>

## Automatic backup on an external USB drive

*Guide using `rpi-clone`, available [here](https://github.com/billw2/rpi-clone).*

<br>

Connect a *USB drive* or an external *memory card*.
``` bash
# list all connected drives & identify the connected USB drive
sudo fdisk -l

Disk /dev/sda: 14.5 GiB, 15523119104 bytes, 30318592 sectors
Disk model: Mass-Storage
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0x00000000
```

### Format USB drive (if needed)

:warning: **All contents of `/dev/sda` will be erased! Be sure it's the correct disk!** :warning:

``` bash
sudo fdisk /dev/sda

Welcome to fdisk (util-linux 2.33.1).
Changes will remain in memory only, until you decide to write them.
Be careful before using the write command.

# Delete and Add a partition by typing the following commands + <enter>
d   # delete partition
n   # add partition
p   # type 'primary'
1   # partition number
# 'First sector' & 'Last sector' : keep the default - hit <enter> for both

# If the following message appears, select 'Y':
Partition No1 contains a vfat signature.
Do you want to remove the signature? [Y]es/[N]o: Y

w   # write changes
```

Next, format the partition:
``` bash
sudo mkfs -t ext4 /dev/sda1

Allocating group tables: done
Writing inode tables: done
Creating journal (16384 blocks): done
Writing superblocks and filesystem accounting information: done
```

### Prepare `rpi-clone`
``` bash
cd ~/Software
git clone https://github.com/billw2/rpi-clone.git

cd rpi-clone
sudo cp rpi-clone rpi-clone-setup /usr/local/sbin
```

### Using `rpi-clone`

```bash
# check rpi-clone version
sudo rpi-clone -V

# clone microSD card to external device 'sda'
sudo rpi-clone sda

Booted disk: mmcblk0 15.6GB                Destination disk: sda 15.5GB
---------------------------------------------------------------------------
Part      Size    FS     Label           Part   Size    FS     Label
1 /boot   256.0M  fat32  --              1      256.0M  fat32  --
2 root     14.3G  ext4   rootfs          2       14.2G  ext4   BKPraspi
---------------------------------------------------------------------------
== SYNC mmcblk0 file systems to sda ==
/boot                 (46.0M used)   : SYNC to sda1 (256.0M size)
/                     (7.3G used)    : SYNC to sda2 (14.2G size)
---------------------------------------------------------------------------
Run setup script       : no.
Verbose mode           : no.
-----------------------:

Ok to proceed with the clone?  (yes/no): yes
```

To execute the script in *quite mode*, use the `-q` option:
``` bash
# quietly clone microSD to external device 'sda'
sudo rpi-clone sda -q
```

<br>


## Automatic backup on a *Network Share*

> :warning: the following part has **not** been tested :warning:

> The following guide will describe how to automatically backup your Raspberry Pi's SD card on a *Network Attached Storage* (NAS) in the same network.

*Guide using `bkup_rpimage`, available [here](https://github.com/lzkelley/bkup_rpimage).*

<br>

### Prepare the NAS

Depending on your NAS's capabilities and in order to increase security, it's better if you can create a *network share* and a *user account* that will be used only from the Raspberry Pi.

This *user account* should **not have access** rights to any other folder in your NAS.

For the purpose of this guide, we assume:
```
NAS IP        :  192.168.1.50
Network share :  /raspberry
Username      :  raspi
Password      :  ******
```

### Mount share on Raspberry

Create a directory where you will mount the *network share* you created in the previous step.
``` bash
sudo mkdir /mnt/NAS
```

Mount the share:
``` bash
mount -t cifs -o user=raspi,rw,file_mode=0777,dir_mode=0777 //192.168.1.50/raspberry /mnt/NAS
Password for raspi@//192.168.1.50/raspberry:  ******
```

#### Debug mount issues

You can verify that the mount was successful by using the command `df -h` :
``` bash
Filesystem                  Size  Used Avail Use% Mounted on
/dev/root                   14G  7.2G  6.2G  54% /
devtmpfs                    430M     0  430M   0% /dev
tmpfs                       463M  5.4M  458M   2% /dev/shm
tmpfs                       463M   13M  451M   3% /run
tmpfs                       5.0M  4.0K  5.0M   1% /run/lock
tmpfs                       463M     0  463M   0% /sys/fs/cgroup
/dev/mmcblk0p1              253M   47M  206M  19% /boot
tmpfs                       93M     0   93M   0% /run/user/999
tmpfs                       93M     0   93M   0% /run/user/1000
//192.168.1.50/raspberry    7.3T  1.4T  5.9T  20% /mnt/NAS
```

You can check `kern.log` for issues during the mount.
``` bash
sudo tail -f /var/log/kern.log
```

If you see only the following, then no errors should have occurred:
``` bash
Jan 19 10:07:58 MyRaspberry kernel: [85156.395392] CIFS: Attempting to mount //192.168.1.50/raspberry
```

#### Auto mount at boot

Create the `credentials` file that will store your SAMBA *username* & *password* in `/etc/samba/`:
``` bash
sudo touch /etc/samba/credentials
```

Add **only** two lines with the exact text (replacing `{YOUR-USERNAME}` and `{YOUR-PASSWORD}`). The credentials are those of the *network server*, not your Raspberry Pi login.
``` bash
username={YOUR-USERNAME}
password={YOUR-PASSWORD}
```

Make `root` the owner and give only *read* permissions:
``` bash
chown root:root /etc/samba/credentials
sudo chmod 400 /etc/samba/credentials
```

Edit the `etc/fstab` file and add the following line (replacing accordingly):
``` bash
//192.168.1.50/Raspberry /mnt/NAS cifs _netdev,credentials=/etc/samba/credentials,rw,file_mode=0777,dir_mode=0777,comment=systemd.automount,x-systemd.mount-timeout=30  0  0
```

### Prepare `bkup_rpimage`
``` bash
cd ~/Software
git clone https://github.com/lzkelley/bkup_rpimage

cd bkup_rpimage
sudo chmod +x bkup_rpimage.sh
```

> This script needs `pv` program. If not installed, install it using:
> ``` bash
> sudo apt-get install pv
> ```
> More info: [https://linux.die.net/man/1/pv](https://linux.die.net/man/1/pv)

### Using `bkup_rpimage`
``` bash
sudo bash bkup_rpimage.sh start -c /tmp/raspi-backup.img
```

### Automate backup procedure
Create a file `backup_handler.sh` in the same location with `bkup_rpimage` files:

``` bash
cd ~/Software/bkup_rpimage
touch backup_handler.sh
```

Edit the file ( `nano backup_handler.sh` ) and add the following content:
``` bash
#!/bin/bash

SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/games:/usr/games

# c : create img file if not exist
# z : compress image
# d : delete image after compression
# l : create log file named {IMAGE-NAME}-YYYYmmddHHMMSS.log

/bin/bash bkup_rpimage.sh start -czdl /mnt/NAS/$(date +%Y-%m-%d)_$(uname -n).img
```

Note that you need to update the path according to what you have set in the previous steps.

Test that automatic script works and that the compressed image file is created in the Network Share:
``` bash
sudo bash backup_handler.sh
```

Add the above script at `crontab` to execute automatically:
``` bash
sudo crontab -e
```

Add the following (replacing `{USERNAME}` with your username) in order to have the script executing weekly at 4:30 am :
``` bash
30 4 * * 1 /home/{USERNAME}/Software/bkup_rpimage/backup_handler.sh
```

<br>
