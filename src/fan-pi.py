#!/usr/bin/python3

import RPi.GPIO as IO
import time
import subprocess
import datetime
import syslog

servo = 18
allowLog = True

IO.setwarnings(False)
IO.setmode (IO.BCM)
IO.setup(servo,IO.OUT)
fan = IO.PWM(servo,25000)
fan.start(0)

def get_temp():
    output = subprocess.run(['vcgencmd', 'measure_temp'], capture_output=True)
    temp_str = output.stdout.decode()
    try:
        return float(temp_str.split('=')[1].split('\'')[0])
    except (IndexError, ValueError):
        syslog.syslog('[X-C1] Could not get CPU temperature! Fan duty cycle: {}%'.format(temp, fan_duty))
        raise RuntimeError('[X-C1] Could not get CPU temperature')

while True:
    now = datetime.datetime.now()
    temp = get_temp()                        # Get the current CPU temperature

    # Check if it's between 12am and 8am
    if now.hour >= 0 and now.hour < 8:
        # If temperature is above 50, use normal duty cycles
        if temp > 50:
            fan_duty = 100 if temp > 70 else \
                       85 if temp > 60 else \
                       70 if temp > 50 else \
                       50
        # Otherwise, reduce all duty cycles by 10
        else:
            fan_duty = 90 if temp > 70 else \
                       75 if temp > 60 else \
                       60 if temp > 50 else \
                       40 if temp > 40 else \
                       15 if temp > 32 else \
                       5 if temp > 25 else \
                       50   # fail-safe, in case we can't get the CPU temperature
    # Otherwise, use normal duty cycles
    else:
        fan_duty = 100 if temp > 70 else \
                   85 if temp > 60 else \
                   70 if temp > 50 else \
                   50 if temp > 40 else \
                   25 if temp > 32 else \
                   15 if temp > 25 else \
                   50   # fail-safe, in case we can't get the CPU temperature

    # Set the fan duty cycle based on temperature and time
    fan.ChangeDutyCycle(fan_duty)

    # Log temperature and fan duty cycle to syslog every 5 minutes
    if now.minute % 5 == 0 and allowLog == True:
        syslog.syslog('[X-C1] Current CPU temperature: {}C, Fan duty cycle: {}%'.format(temp, fan_duty))
        allowLog = False

    if now.minute % 5 != 0:
        allowLog = True

    # Sleep for 5 seconds
    time.sleep(5)