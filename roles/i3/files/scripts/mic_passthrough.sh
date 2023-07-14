#!/bin/sh
if ! pactl list short | grep -q module-loopback; then
    pactl load-module module-loopback latency_msec=50
else
    pactl unload-module module-loopback
fi;
