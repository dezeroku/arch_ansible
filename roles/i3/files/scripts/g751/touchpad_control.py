import sys,os
from pathlib import Path

#ADD BETTER TOGGLE SUPPORT

touchpad_name="\'ETPS/2 Elantech Touchpad\'" #write you touchpad device identifier in that field
path = (os.path.split(os.path.dirname(os.path.realpath(sys.argv[0])))[0] + "/" +
        "temp/")

if len(sys.argv)<2:
    print("See help") # I should write that help by the way :P 
    sys.exit(1)

if sys.argv[1]=="turn_on":
    os.system("xinput enable "+touchpad_name)

if sys.argv[1]=="turn_off":
    os.system("xinput disable "+touchpad_name)

state=False

if sys.argv[1]=="toggle":
    with open(path+"state.txt","r") as state_file:
        if state_file.read()=="enabled":
            state=True
    if state==True:
        os.system("xinput disable "+touchpad_name)
        with open(path+"state.txt","w") as state_file:
            state_file.write("disabled")
    if state==False:
        os.system("xinput enable "+touchpad_name)
        with open(path+"state.txt","w") as state_file:
            state_file.write("enabled")
    #os.system("sh ~/.config/i3/scripts/touchpad_toggle")
