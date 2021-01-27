#!/bin/bash

# This script is monitoring OpenVPN log ( /var/log/openvpn-status.log )
# and controls an LED according to active VPN connections.
#
# On script's startup, the LED blinks for 3 times.
# Do not forget to use a resistor on the LED!

echo "Starting script 'OpenVPN-LEDs.sh' to monitor OpenVPN log ..."

# configure pin as output
# YELLOW LED
echo "16" > /sys/class/gpio/export
echo "out" > /sys/class/gpio/gpio16/direction


# LED controlling functions
longBlink ()
{
    echo "1" > /sys/class/gpio/gpio16/value
    sleep 0.5
    echo "0" > /sys/class/gpio/gpio16/value
    sleep 0.25
}

shortBlink ()
{
    echo "1" > /sys/class/gpio/gpio16/value
    sleep 0.07
    echo "0" > /sys/class/gpio/gpio16/value
    sleep 0.1
}

# check openvpn-status log for connected clients
operation ()
{
    # extract 'client name' , 'source IP' , 'connected since'
    CONNCLIENTS=$( cat /var/log/openvpn-status.log | tail -n +4 | grep 'CLIENT_LIST' | awk -F ',' '{print $2,$3,$8}' )

    if [[ ! -z "$CONNCLIENTS" ]]; then
        # echo "$CONNCLIENTS" | while read LINE; do echo "Client: $LINE"; done;
        echo "$CONNCLIENTS" | while read LINE; do
            #echo "OpenVPN-LED : blink!"
            longBlink
            sleep 0.5
        done
    fi
}


# slow blink LED 3 times on script start
for i in {0..3..1}
    do
        longBlink
done


# infinite loop
while true
do
    operation

    sleep 5
done