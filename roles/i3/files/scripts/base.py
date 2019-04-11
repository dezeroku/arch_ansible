"""All the stuff that is used in this folder."""
import os
import sys
import subprocess

class SetupError(Exception):
    """Base for all exceptions."""
    pass

def get_root_folder():
    """Returns root i3_config folder path, basing on resolution.py (this file)
    script location."""
    # We need to go to parent of scripts folder and add slash at the end.
    return (os.path.split(os.path.dirname(os.path.realpath(sys.argv[0])))[0] +
            "/")

def get_resolution():
    """Return resolution of main monitor as a string. Example outputs:
        1280x800
        1920x1080
        1024x768
        """
    # TODO: This must be possible to be done easier.
    command = "xrandr  | grep \* | cut -d' ' -f4"
    result = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE)
    res = None
    for line in result.stdout.readlines():
        res = line
        break

    if res is None:
        print("Could not get resolution!", file=sys.stderr)
        sys.exit(1)

    temp = res.decode("utf-8")

    resolution = ""
    for character in temp:
        if character != "\n":
            resolution += character

    return resolution

def set_wallpaper(image_path):
    """Set image at provided path as a wallpaper (requires feh to run)."""
    if os.path.exists(image_path):
        os.system("feh --bg-scale " + image_path)
    else:
        print("Could not find image at " + image_path, file=sys.stderr)
        sys.exit(1)
