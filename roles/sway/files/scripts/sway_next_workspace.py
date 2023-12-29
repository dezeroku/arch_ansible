#!/usr/bin/env python3
import os
import sys
import json
import subprocess

stdoutdata = subprocess.getoutput("swaymsg -t get_workspaces")
your_next_workspace = "strange_name_to_not_use"
# print(stdoutdata)
next_break = False
data = json.loads(stdoutdata)
for x in data:
    if next_break == True:
        your_next_workspace = x["name"]
        break
    if x["visible"] == True and x["focused"] == True:
        print(x)
        your_current_workspace = x["name"]
        print(your_current_workspace)

        next_break = True

if your_next_workspace == "strange_name_to_not_use":
    your_next_workspace = data[0]["name"]

os.system(
    "swaymsg -t command move container to workspace "
    + your_next_workspace
    + " && swaymsg -t command workspace next"
)
