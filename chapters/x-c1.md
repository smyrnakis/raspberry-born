# Install & configure ***X-C1*** board

*Article 1: https://wiki.geekworm.com/NASPi*

*Article 2: https://wiki.geekworm.com/NASPi#X-C1_V1.3_GPIO_Use*

*Article 3: https://wiki.geekworm.com/X-C1_Software*

*Article 4: https://wiki.geekworm.com/NASPi#FAQ*

*Assembly Video: https://www.youtube.com/watch?v=ithz2Mg5Vrc*

<br>

## Preparation

Ensure the system is updated:
``` bash
sudo apt-get update && sudo apt-get upgrade -y
```

Install needed packages:
``` bash
sudo apt-get install -y git pigpio 
sudo apt-get install -y python-pigpio python3-pigpio
sudo apt-get install -y python-smbus python3-smbus
```

## Installation

Clone *X-C1* installation files under `Software` directory:
``` bash
mkdir Software
git clone https://github.com/geekworm-com/x-c1.git
cd x-c1
sudo chmod +x *.sh
```

Install and configure:
``` bash
sudo bash install.sh
```

Add the `xoff` alias in your profile.
``` bash
# for BASH
vim ~/.bashrc

# add under aliases
alias xoff='sudo /usr/local/bin/x-c1-softsd.sh'

# for ZSH
vim ~/.zshrc

# add under aliases
alias xoff="sudo /usr/local/bin/x-c1-softsd.sh"
```

**Important:** make sure that `Python3` is used in the `rc.local` file when calling the `fan.py` script:
```bash
sudo vim /etc/rc.local
```

Check that `Python3` is used:
```bash
python3 /home/{YOUR-USERNAME}/Software/x-c1/fan.py &
```

Finish the installation by rebooting the Raspberry Pi:
``` bash
sudo reboot
```

<br>

## Notes

### Power button
* Press: **turn on**
* Press & hold:
    * 1~2 seconds: **reboot**
    * 3 seconds: **safe shutdown**
    * \> 8 seconds: **force shutdown**

<br>

### Terminal shut down
:warning: Do not use the `shutdown` command as this will not power down the X-C1 board!<p>
To shut down from the terminal, use the `xoff` command.

<br>

### Update `RPi.GPIO`

```bash
sudo pip install --upgrade RPi.GPIO

# for Python3
sudo pip3 install --upgrade RPi.GPIO
```

<br>

### Fan / temperature control

If you want to adjust the fan's thresholds, you need to edit the `$HOME/Software/x-c1/fan.py` file.

``` bash
vim $HOME/Software/x-c1/fan.py
```

In the example bellow, the `30` is the temperature threshold and the `40` is the PWM speed of the fan:
``` bash
if(temp > 30):
          pwm.set_PWM_dutycycle(servo, 40)
```

A PWM of value of `0` means stopped fan.<p>
A PWM of value of `100` means fan works full speed.

<br>

An updated script with reduced duty cycle at night, syslog reporting and newer Python functions is available here: [fan.py](https://github.com/smyrnakis/raspberry-born/blob/main/src/fan.py)

It is recommended that you replace the code in `$HOME/Software/x-c1/fan.py` with the above one.


<br>

### Debugging

To see the generated logs of `fan.py`, use the following command:

``` bash
sudo cat /var/log/syslog | grep 'fan.py'
```