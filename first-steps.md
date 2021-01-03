# Prepare SD

#### Download image

- Download the latest image from the [official website](https://www.raspberrypi.org/software/)

#### Write image

- Download and install *balenaEtcher* from the [official website](https://www.balena.io/etcher/)
- Write image to microSD

#### Enable SSH

- Create an empty file named `ssh` in the root of `boot` drive

##### Mac

``` bash
cd /Volumes/boot
touch ssh
```

##### Windows

``` powershell
# cd to the microSD, here D:\
D:
New-Item -ItemType file ssh
```

OR

``` cmd
rem cd to the microSD, here D:\
D:
echo $null >> filename
```

<br>

# First login

Find the local IP address of the Raspberry Pi
  - [Fing app](https://play.google.com/store/apps/details?id=com.overlook.android.fing&hl=en&gl=US) for Android.

SSH to the Raspberry Pi with default user `pi` and password `raspberry`

``` bash
ssh pi@192.168.178.31
```

### Update and configure

Update OS

``` bash
sudo apt-get update -y && sudo apt-get upgrade -y && sudo apt-get clean
```

raspi-config

``` bash
sudo raspi-config
```

##### System Options --> Hostname

Change the default hostname.

##### System Options --> Boot / Auto Login

Disable auto login. Choose `Console`.

##### Localisation Options --> Timezone

Select timezone.

##### Advanced Options --> Expand Filesystem

Go to `Advanced Options` and select `Expand Filesystem`.

<br>

**Reboot**

<br>
