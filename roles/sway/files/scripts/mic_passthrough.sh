#!/usr/bin/env bash

STATE_FILE="$HOME/.config/sway/scripts/mic_passthrough.sh-state"

if [ ! -f "${STATE_FILE}" ]; then
    pw-loopback & echo $! > "${STATE_FILE}"
else
    LOOPBACK_PID="$(cat "${STATE_FILE}")"
    if ps -p "${LOOPBACK_PID}"; then
        kill "${LOOPBACK_PID}"
    fi
    rm "${STATE_FILE}"
fi
