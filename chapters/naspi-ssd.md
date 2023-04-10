# Clone microSD to SSD & boot from the SSD

*Article 1: https://www.tomshardware.com/how-to/boot-raspberry-pi-4-usb*

*Article 2: https://wiki.geekworm.com/How_to_View/Partition/Format/Mount_HDD/SSD*

*Article 3: https://github.com/billw2/rpi-clone*

<br>

## Preparation

Ensure the system is updated:
``` bash
sudo apt-get update && sudo apt-get upgrade -y
```

## Enable boot from SSD

On your laptop:
1. Insert a spare *microSD* card and start **Raspberry Pi Imager** (download from [HERE](https://www.raspberrypi.org/downloads/))
2. Under *Operating System* select **Misc utility images**
3. Click on **Bootloader** and then **USB Boot**
4. Under *Storage* select the microSD card and click on **WRITE**

On the Raspberry Pi:
1. Shutdown the Raspberry Pi
2. Remove the microSD card with the OS
3. Insert the microSD you prepared above
4. Power up the Raspberry Pi and wait some seconds until the *green LED* flashes continuously (approximately 30 sec)
5. Power Off the Raspberry Pi and re-insert the microSD with the OS

<br>

## Copy microSD to SSD

The quickest way is to connect the Raspberry Pi on a screen and use the GUI **SD Card Copier** under *Accessories*.

After finishing the process, shutdown the Raspberry Pi, remove the microSD and power it up again. It will now boot from the SSD. 

<br>

<!--
## Partition the drive 

Check if the USB SSD drive is recognised:
``` bash
sudo fdisk -l
```

You should see something like this:
``` bash
Disk /dev/sda: 447.13 GiB, 480103981056 bytes, 937703088 sectors
Disk model: 2115
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 33553920 bytes
```

Create the first partition of `16Gb`:
``` bash
sudo fdisk /dev/sda

Command (m for help): p

Command (m for help): n

Partition number (1-4, default 1): 1

First sector (65535-937703087, default 65535):

Last sector, +/-sectors or +/-size{K,M,G,T,P} (65535-937703087, default 937703087): +16G
```

Create a second partition in the remaining space:
``` bash
Command (m for help): p

Command (m for help): n

Partition number (1-4, default 1): 2

First sector (33619455-937703087, default 33619455):

Last sector, +/-sectors or +/-size{K,M,G,T,P} (33619455-937703087, default 937703087):
```

View the created partitions using the `p` command:
``` bash
Command (m for help): p
Disk /dev/sda: 447.13 GiB, 480103981056 bytes, 937703088 sectors
Disk model: 2115
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 33553920 bytes
Disklabel type: dos
Disk identifier: 0xbac72ff0

Device     Boot    Start       End   Sectors   Size Id Type
/dev/sda1          65535  33619454  33553920    16G 83 Linux
/dev/sda2       33619455 937703087 904083633 431.1G 83 Linux
```

To exit `fdisk` use the command `q`:
``` bash
Command (m for help): q
```

<br>
-->