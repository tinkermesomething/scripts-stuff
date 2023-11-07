# This is script to run the FAN control on my raspberry pi cluster. 
# It uses the data from prometheus from the each of the PIs to adjust the fan speed based on which Pi is running hottest. 
# I have this script running on the raspberry PI on which the FAN is connected. 
# I'm using a Noctua FAN with speed control. It's amazing how good and quiet it is. 
# I then proceeded to create a fan_control.service for it to run at boot.
# Again, for this to work, prometheus needs to be installed on each of the PIs as well the controller on the main PI to which the FAN is connected to. 
# As I installed grafana on it, it was a no brainer to use that data for this project. 

import RPi.GPIO as GPIO
import time
import os
import requests
from influxdb import InfluxDBClient

FAN_PIN = 12
TACHO_PIN = 16
PWM_FREQ = 25000
MIN_TEMP = 35
MAX_TEMP = 50
MIN_SPEED = 0
MAX_SPEED = 100

# Add the IP addresses of the other Raspberry Pi devices in the cluster
cluster_ips = ["IP 1", "IP 2", "IP 3", "IP 4"]

def get_cpu_temp():
    with open("/sys/class/thermal/thermal_zone0/temp", "r") as f:
        temp = int(f.read()) / 1000
    return temp

def get_remote_temp(ip):
    try:
        response = requests.get(f"http://{ip}:9100/metrics", timeout=5)
        for line in response.text.splitlines():
            if line.startswith("node_hwmon_temp_celsius"):
                temp = float(line.split()[-1])
                return temp
    except Exception as e:
        print(f"Error getting temperature from {ip}: {e}")
        return None

def get_cluster_temps():
    temps = [get_cpu_temp()]
    for ip in cluster_ips:
        remote_temp = get_remote_temp(ip)
        if remote_temp is not None:
            temps.append(remote_temp)
    return temps

def calculate_fan_speed(temps):
    max_temp = max(temps)
    if max_temp < MIN_TEMP:
        return 0
    elif max_temp > MAX_TEMP:
        return 100
    else:
        return int((max_temp - MIN_TEMP) / (MAX_TEMP - MIN_TEMP) * (MAX_SPEED - MIN_SPEED) + MIN_SPEED)

GPIO.setwarnings(False)
GPIO.setmode(GPIO.BCM)
GPIO.setup(FAN_PIN, GPIO.OUT)
fan = GPIO.PWM(FAN_PIN, PWM_FREQ)
fan.start(0)

try:
    while True:
        temps = get_cluster_temps()
        speed = calculate_fan_speed(temps)
        fan.ChangeDutyCycle(speed)
        print("Current temperatures: ", temps)
        print("Current fan speed: {}%".format(speed))
        
        client = InfluxDBClient(host='localhost', port=8086)
        client.switch_database('DB_name') # here you need to give the DB of the prometheus controller
        data = [
            {
                "measurement": "fan_control",
                "tags": {
                    "host": "your_host_name",
                },
                "fields": {
                    "temperature": max(temps),
                    "fan_speed": speed,
                }
            }
        ]
        client.write_points(data)
        
        time.sleep(5)
except KeyboardInterrupt:
    fan.stop()
    GPIO.cleanup()
  # when you run this script, it will output it's doing. 
