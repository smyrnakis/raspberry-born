
#!/bin/bash

# This script is monitoring Pi-hole log ( /var/log/pihole.log ) and controls two LEDs according to the DNS handle.
# On string ": gravity blocked" --> RED led (GPIO21) blinks.
# On string ": reply" --> GREEN led (GPIO20) blinks.
# On script's startup, both LEDs blink consecutively for 3 times.
# Do not forget to use a resistor with each LED!

echo "Starting script 'pihole-LEDs.sh' to monitor pihole log ..."

# configure pins as output
# GREEN LED
echo "20" > /sys/class/gpio/export
echo "out" > /sys/class/gpio/gpio20/direction

# RED LED
echo "21" > /sys/class/gpio/export
echo "out" > /sys/class/gpio/gpio21/direction


# LED controlling functions
longBlink ()
{
    if [[ "$1" == "green" ]]; then
        echo "1" > /sys/class/gpio/gpio20/value
        sleep 0.75
        echo "0" > /sys/class/gpio/gpio20/value
        sleep 0.25
    fi
    if [[ "$1" == "red" ]]; then
        echo "1" > /sys/class/gpio/gpio21/value
        sleep 0.75
        echo "0" > /sys/class/gpio/gpio21/value
        sleep 0.25
    fi
}

shortBlink ()
{
    if [[ "$1" == "green" ]]; then
        echo "1" > /sys/class/gpio/gpio20/value
        sleep 0.1
        echo "0" > /sys/class/gpio/gpio20/value
        sleep 0.1
    fi
    if [[ "$1" == "red" ]]; then
        echo "1" > /sys/class/gpio/gpio21/value
        sleep 0.1
        echo "0" > /sys/class/gpio/gpio21/value
        sleep 0.1
    fi
}

# slow blink LEDs 3 times on script start
for i in {0..3..1}
    do
        longBlink green
        longBlink red
done

# tail pihole log for blocked / allowed strings
tail -f /var/log/pihole.log | while read INPUT
do
    if [[ "$INPUT" == *": gravity blocked"* ]]; then
        shortBlink red
        #echo "pihole block"
    fi
    if [[ "$INPUT" == *": reply"* ]]; then
        shortBlink green
        #echo "pihole allow"
    fi
done