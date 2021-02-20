#!/usr/bin/python3

import sys
import time
import urllib
import Adafruit_DHT
import RPi.GPIO as GPIO

if sys.version_info[0] < 3:
    import httplib
else:
    import http.client

DHTpin = 23                 # DHT data pin
key = "XXXXXXXXXXXXXXXX"    # Thingspeak API write key
previousTemperature = 100
previousHumidity = 100

showDebugs = False


def writeDataFile(humidity, temperature):
    # Writing last measured values (humidity & temperature) to files for further usage by other scripts

    try:
        fh = open('/home/{YOUR-USERNAME}/Software/thingspeak/humidity','wt')
        fh.write(str(humidity))
        fh.close()

        ft = open('/home/{YOUR-USERNAME}/Software/thingspeak/temperature','wt')
        ft.write(str(temperature))
        ft.close()
        if showDebugs: print("[THINKGSPEAK] files written")
    except:
        print("[THINKGSPEAK] Failed to write files !")


def validateDHT(humidity, temperature):
    # DHT11 range is 0-50 degrees C for temperature and 20-90 % for humidity
    # This function validates that:
    #   - the numbers are inside the above ranges
    #   - current measurement is no more than 5 numbers different than the previous measurement
    #     If |current - previous| > 5 : re-measure for up to 4 times every 2 sec
    #
    # The above validations are needed for two reasons:
    #   - DHT11 tends to be a bit unstable and easily affected by environment variations
    #   - in my setup, the DHT11's cable is approx 1.5m long. This is not recommended!

    global previousTemperature
    global previousHumidity
    whileCounter = 0

    while ( abs(previousHumidity - humidity) > 5 or abs(previousTemperature - temperature) > 5 ) and whileCounter < 4 \
        or humidity < 20 or humidity > 90 or temperature < 0 or temperature > 50 :

        whileCounter += 1
        time.sleep(2)

        humidity, temperature = Adafruit_DHT.read_retry(Adafruit_DHT.DHT11, DHTpin)
        if showDebugs: print("[THINKGSPEAK] RE-MEASUREMENT T:",temperature,"H:",humidity,"whileCounter:",whileCounter)

    previousHumidity = humidity
    previousTemperature = temperature

    writeDataFile(humidity, temperature)
    return humidity, temperature


def measure_send():
    global previousTemperature
    global previousHumidity

    # get CPU temperature
    tempCPU = int(open('/sys/class/thermal/thermal_zone0/temp').read()) / 1e3
    if showDebugs: print("[THINKGSPEAK] CPU temperature:",tempCPU)

    # get load averages
    loadAll = open('/proc/loadavg').read()
    load1 = loadAll[0:4]
    load5 = loadAll[5:9]
    load15 = loadAll[10:14]
    if showDebugs: print("[THINKGSPEAK] Average-1:",load1, "Average-5:",load5, "Average-15:",load15)

    try:
        # get room temperature & humidity
        humRoom, tempRoom = Adafruit_DHT.read_retry(Adafruit_DHT.DHT11, DHTpin)
        if showDebugs:
            print("[THINKGSPEAK] FIRST measuremet T:",tempRoom,"H:",humRoom)
            print("[THINKGSPEAK] previousTemperature:",previousTemperature,"previousHumidity:",previousHumidity)

        if previousHumidity == 100 or previousTemperature == 100 :
            if showDebugs: print("[THINKGSPEAK] initialising 'previous' values")
            previousHumidity = humRoom
            previousTemperature = tempRoom

        humidityRoom, temperatureRoom = validateDHT(humRoom, tempRoom)
        if showDebugs: print("[THINKGSPEAK] >>>> VALIDATED measurement T:",temperatureRoom, "H:",humidityRoom)

        # Parameters WITH DHT11
        if sys.version_info[0] < 3:
            # Python 2.7
            params = urllib.urlencode({'field1': temperatureRoom, 'field2': humidityRoom, 'field3': tempCPU, 'field4': load1, 'field5': load5, 'field6': load15,'key':key })
        else:
            # Python 3
            params = urllib.parse.urlencode({'field1': temperatureRoom, 'field2': humidityRoom, 'field3': tempCPU, 'field4': load1, 'field5': load5, 'field6': load15,'key': key })
    except:
        print("[THINKGSPEAK] Failed to read DHT11 !")
        # Parameters WITHOUT DHT11
        if sys.version_info[0] < 3:
            # Python 2.7
            params = urllib.urlencode({'field3': tempCPU, 'field4': load1, 'field5': load5, 'field6': load15,'key': key })
        else:
            # Python 3
            params = urllib.parse.urlencode({'field3': tempCPU, 'field4': load1, 'field5': load5, 'field6': load15,'key': key })

    headers = {"Content-typZZe": "application/x-www-form-urlencoded","Accept": "text/plain"}
    if sys.version_info[0] < 3:
        conn = httplib.HTTPConnection("api.thingspeak.com:80")
    else:
        conn = http.client.HTTPConnection("api.thingspeak.com:80")
    try:
        conn.request("POST", "/update", params, headers)
        response = conn.getresponse()
        if showDebugs: print("[THINKGSPEAK] connection to Thingspeak:", response.status, response.reason)
        data = response.read()
        conn.close()
    except:
        if showDebugs: print("[THINKGSPEAK] connection to Thingspeak failed !")


if __name__ == "__main__":
    while True:
        measure_send()
        time.sleep(60)