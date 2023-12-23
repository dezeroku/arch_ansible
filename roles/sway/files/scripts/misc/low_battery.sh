#!/bin/sh

# This script should be added to crontab to run every 5min.
# Use it only if your computer is ACPI compatible and you have acpi installed.

# You can adjust low_battery value to display notification basing on the battery level.
low_battery=20;

percentage=$(acpi -b | grep -P -o '[0-9]+(?=%)')

if [ "$percentage" -lt "$low_battery" ] && [ "$percentage" -ne 10 ]; then
     DISPLAY=:0.0 /usr/bin/notify-send "Low battery" "You only got $percentage% left";
fi;
