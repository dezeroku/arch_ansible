#!/usr/bin/env bash
swaymsg -t get_tree \
    | jq -r '.. | objects
        | select(.type == "con")
        | select(.app_id != null or (.window_properties.class? != null))
        | select(.name != null)
        | "\(.id)\t\(.app_id // .window_properties.class) — \(.name)"' \
    | fuzzel --no-exit-on-keyboard-focus-loss --dmenu \
    | cut -f1 \
    | xargs -I{} swaymsg "[con_id={}] focus"
