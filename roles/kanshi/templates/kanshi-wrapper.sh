#!/usr/bin/env bash

# Automatically reload config file when changed
# It's assumed that the config file is already in place

CONFIG_FILE="$HOME/.config/kanshi/config"

kanshi &
PID="$!"

while ps -p $PID >/dev/null ; do
    inotifywait --quiet --event modify "${CONFIG_FILE}"
    echo "Reloading kanshi"
    kill -s SIGHUP "$PID"
done
