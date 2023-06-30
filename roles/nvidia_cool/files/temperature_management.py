#!/usr/bin/python3
"""Basic Fan speed control for GPU and CPU.
   d0ku 2018"""

import argparse
import subprocess
import threading
import time
import math
import signal
import sys
import os

SLEEP_TIME = 0.3


def set_cpu_fan(speed):
    """Set speed in provided cpu fan speed files."""
    # Check if a file exists, if it exists write speed value to it.
    base_command = "echo "

    write_command = "sudo tee "

    fan_address = "/sys/devices/platform/asus-nb-wmi/hwmon/hwmon1/pwm1"
    second_fan_adrress = "/sys/devices/platform/asus-nb-wmi/hwmon/hwmon2/pwm1"

    addresses = []

    addresses.append(fan_address)
    addresses.append(second_fan_adrress)

    # TODO: write 0 to pwm_enable to disable pwm, and give it value of 1 in
    # reset to restore pwm
    for address in addresses:
        if os.path.isfile(address):
            to_execute = base_command + str(speed) + " | " + write_command + address
            # Debug print
            # print(to_execute)
            try:
                subprocess.check_output(to_execute, shell=True)
            except subprocess.CalledProcessError:
                pass


def set_gpu_fan(speed):
    """Set spped step for GPU fan."""
    command = "sudo /usr/bin/acer_ec.pl writetemp 152 " + str(speed)

    result = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE)
    result = str(result.stdout.readline().decode("utf-8"))
    print(result)


def get_cpu_temperature():
    with open("/sys/class/thermal/thermal_zone0/temp", "r") as temperature_file:
        temperature = float(temperature_file.read()) / 1000
    return temperature


def get_gpu_temperature():
    # This may be easier...
    # nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader -l 3
    command = "nvidia-smi | grep Default"
    result = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE)
    result = str(result.stdout.readline().decode("utf-8"))
    # result = result.split(" ")
    # print(result)
    # result = result[len(result)-1]
    result = result[8:10]
    # print(result)

    result = float(result)
    return result


def cpu_fan_react():
    previous_speed = -1
    while True:
        time.sleep(SLEEP_TIME)
        temperature = get_cpu_temperature()
        temp = math.floor(temperature / 85 * 255)
        if temp > 255:
            temp = 254
        # print(temp)

        if previous_speed != temp:
            set_cpu_fan(temp)
            print("CPU: " + str(temp) + " for " + str(temperature) + " degrees.")
        previous_speed = temp


def gpu_fan_react():
    previous_speed = -1
    while True:
        time.sleep(SLEEP_TIME)
        temperature = get_gpu_temperature()
        temp = math.floor(temperature / 85 * 8)
        # print(temp)
        if temp > 8:
            temp = 8

        if previous_speed != temp:
            set_gpu_fan(temp)
            print("GPU: " + str(temp) + " for " + str(temperature) + " degrees.")

        previous_speed = temp


# Restore default state of fans.
def reset():
    pass


def signal_handler(signal, frame):
    reset()
    print("Default state successfully restored!")
    sys.exit(0)


if __name__ == "__main__":
    # signal.signal(signal.SIGINT, signal_handler)
    # signal.pause()

    parser = argparse.ArgumentParser("Control CPU/GPU fan speed (Asus G751JM)")
    parser.add_argument(
        "--gpu", help="Custom automatic control over GPU fan.", action="store_true"
    )
    parser.add_argument(
        "--cpu", help="Custom automatic control over CPU fan.", action="store_true"
    )
    parser.add_argument(
        "--both",
        help="Custom automatic control over CPU and\
                        GPU fan.",
        action="store_true",
    )
    parser.add_argument("--reset", action="store_true")
    args = parser.parse_args()

    if args.gpu:
        gpu_thread = threading.Thread(target=gpu_fan_react)
        gpu_thread.start()
        gpu_thread.join()
    elif args.cpu:
        cpu_thread = threading.Thread(target=cpu_fan_react)
        cpu_thread.start()
        cpu_thread.join()
    elif args.both:
        gpu_thread = threading.Thread(target=gpu_fan_react)
        gpu_thread.start()

        cpu_thread = threading.Thread(target=cpu_fan_react)
        cpu_thread.start()

        cpu_thread.join()
        gpu_thread.join()
    elif args.reset:
        reset()
