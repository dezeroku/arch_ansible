#!/usr/bin/env python3
"""
Purpose:
    This file does everything needed to merge config files for specific
resolutions and run i3/py3status etc. with provided options. It is named
resolution.py for historical reasons (I don't want to change it just now.).

Why:
    The whole reason why this setup is created: I had 2 computers at the time of
writing, one bigger laptop with 17 in. screen and 1920x1080 resolution and
smaller netbook 13 in. screen and 1280x800 resolution. Both were running i3 at
the time and I really wanted to have similar experience on them, so changing
config on one of them would automatically change config on second. I ended up
having one base config that contains settings shared between systems and
computer-specific configs which are chosen on runtime basing on resolution. (I
know it's not the best option out there, but until it's enough for my needs I
will probably just stick with it.) The program creates temporary config which
consists of base and resolution dependent config and then runs i3 on top of it.

Started 2017
Big clean up 2018
By d0ku"""

import subprocess
import argparse
import sys
import os
import time
import re
import getpass
from pathlib import Path

from base import get_resolution
from base import get_root_folder
from base import set_wallpaper

class CouldNotParseException(BaseException):
    """Is thrown when $$variable$$ can't be parsed in config file."""
    pass

def lock_decorator(lock_func):
    """Is executed before/after locking."""
    def wrapper(self, image_number=-1, timeout=0.5):
        # Suspend notifications.
        subprocess.run(["pkill", "-u", getpass.getuser(), "-USR1", "dunst"])

        process = lock_func(self, image_number)

        time.sleep(timeout)
        # Turn screen off.
        subprocess.run(["xset", "dpms", "force", "standby"])

        # Wait for lock to finish and restore notifications.
        process.wait()

        # Restore notifications.
        subprocess.run(["pkill", "-u", getpass.getuser(), "-USR2", "dunst"])

    return wrapper


class Locker:
    """All methods arguments should be already parsed ints."""
    default_color = "#cccccc"

    def __init__(self, lock_images_path):
        self.lock_images_path = lock_images_path

    @lock_decorator
    def lock_now(self, image_number=-1, timeout=0.5):
        """Lock screen and blank display."""
        final_path = os.path.join(self.lock_images_path,
                                  str(image_number)+"_lock.png")
        command = ["i3lock", "-n", "-c", "000000"]
        print(final_path)
        if (image_number != -1 and
                os.path.exists(final_path)):
            command += ["-i", final_path]

        command += ["&"]

        process = subprocess.Popen(command)

        return process

    def enable_lock_daemon(self, image_number=-1, timeout=0):
        """Set screen to lock on user inactivity period or suspend."""
        final_path = os.path.join(self.lock_images_path,
                                  str(image_number)+"_lock.png")
        print(final_path)
        base_command = ["xss-lock", "--",
                        get_root_folder()+"scripts/resolution.py", "lock",
                        "--lock-screen"]
        print(base_command)
        if (image_number != -1 and
                os.path.exists(final_path)):
            command = base_command
            command += ["--lock-image-number", str(image_number)]
            command += ["--lock-timeout", str(timeout)]
            command += ["--lock-images-path", self.lock_images_path]

            subprocess.run(command)
        else:
            command = base_command 

            subprocess.run(command)

class Runner:
    """Manage starting and restarting i3wm and py3status configuration,
    considering files located in self.config_folder_path."""

    def __init__(self, config_folder_path):
        # config_folder_path should point to root i3_config directory

        # Here we add ending to path.
        self.config_folder_path = config_folder_path + "configs/"
        self.resolution = get_resolution()
        self.set_up_files()

        # Dictionary, it maps $$VARIABLE$$ alike words to values to be written
        # in final config.
        self.words_to_parse = {}
        self.words_to_parse['BASE'] = config_folder_path
        self.words_to_parse['USERNAME'] = getpass.getuser()
        self.words_to_parse['HOME'] = (os.path.abspath(os.path.expanduser("~"))
                                      + "/")
        self.words_to_parse['RESOLUTION'] = self.resolution

    def set_up_files(self):
        """Check for existence of all necessary files and add required
        variables."""
        if not os.path.exists(self.config_folder_path):
            print("Provided config_folder_path does not exist in a\
                  filesystem.", file=sys.stderr)

        base_config_folder = self.config_folder_path + "base/"

        if not os.path.exists(base_config_folder):
            print("Could not found 'base' folder containing base\
                            configuration in config_folder_path (" +
                  self.config_folder_path + ") location.",
                  file=sys.stderr)

        self.base_config_file = base_config_folder + "config"

        if not os.path.exists(self.base_config_file):
            print("Could not found 'config' file containing base\
                            configuration in config_folder_path/base/ (" +
                  self.config_folder_path + ") location.",
                  file=sys.stderr)


        # Check for fallback config.
        self.config_fallback_file = (self.config_folder_path +
                                     "/base/config_fallback")
        if not os.path.exists(self.config_fallback_file):
            print("Exiting, could not find config fallback file at " +
                  self.config_fallback_file, file=sys.stderr)
            sys.exit(1)

        resolution_config_folder = self.config_folder_path + self.resolution + "/"

        self.parse_resolution_file = False

        if not os.path.exists(resolution_config_folder):
            print("Could not locate resolution based config folder in\
                  config_folder_path (" + resolution_config_folder + ")\
                  location.", file=sys.stderr)
        else:
            self.resolution_config_file = (resolution_config_folder +
                                           "config")
            if not os.path.exists(self.resolution_config_file):
                print("Could not locate resolution based config file in\
                    config_folder_path (" + self.resolution_config_file + ")\
                    location.", file=sys.stderr)
            else:
                # Everything went fine.
                self.parse_resolution_file = True


    def set_up_files_current(self):
        """Create current directory if not exists. Check for overwrite."""
        current_config_path = self.config_folder_path + "current/"
        if not os.path.exists(current_config_path):
            print("Current config folder does not exist, creating as " +
                  current_config_path, file=sys.stderr)
            os.makedirs(current_config_path)

        self.current_config_file = current_config_path + "config"
        if os.path.exists(self.current_config_file):
            print("Current config file does already exist, overwriting " +
                  self.current_config_file, file=sys.stderr)

    def _create_config(self):
        """Merges config files basing on self.config_folder_path and resolution
        detected by get_resolution."""

        self.set_up_files_current()

        current_time_str = time.strftime("%b %d %Y %H:%M:%S", time.gmtime())
        with open(self.current_config_file, "w") as current_config:
            current_config.write("# Config file automatically generated by\
                                 Runner (" + current_time_str + ")\n")
            current_config.write("# Don't edit this file, instead read\
                                 documentation at\
                                 https://github.com/d0ku/i3_config and edit\
                                 files accordingly.\n")
            if self.parse_resolution_file:
                current_config.write("# Merging with resolution file (" +
                                     self.resolution + ")\n")
            else:
                current_config.write("# Could not read resolution file. Read\
                                     log and fix that. Using fallback base\
                                     config for now.\n")

            try:
                with open(self.base_config_file, "r") as base_config:
                    for line in base_config:
                        current_config.write(self.parse_line(line))

                current_config.write("\n\n\n")

                if self.parse_resolution_file:
                    with open(self.resolution_config_file, "r") as res_config:
                        for line in res_config:
                            current_config.write(self.parse_line(line))
                else:
                    with open(self.config_fallback_file, "r") as fall_config:
                        for line in fall_config:
                            current_config.write(self.parse_line(line))

                print("Successfully written current config: " +
                      self.current_config_file, file=sys.stderr)
            except CouldNotParseException:
                sys.exit(1)

    def parse_line(self, line):
        """Parses line of i3 config replacing all $$VARIABLE$$ alike words with
        object dictionary value."""
        # TODO: write some tests for this method.
        # If line is commented, don't parse it.
        if line[0] == "#":
            return line

        reg_str = "\\$\\$[^\\$]*\\$\\$"
        reg = re.compile(reg_str)

        variables = reg.findall(line)

        for variable in variables:
            var = variable[2:-2]
            try:
                line = line.replace(variable, self.words_to_parse[var])
            except KeyError:
                print("Could not match " + variable +" with any variable.",
                      file=sys.stderr)
                raise CouldNotParseException("Could not match " + variable +
                                             " with any variable.")

        return line

    def start_i3(self):
        """Start i3wm accordingly to parameters in config_folder_path"""
        self._create_config()
        subprocess.run("i3 -c " + self.current_config_file, shell=True)
        #os.system("i3 -c " + self.current_config_file)

    def start_i3_debug(self):
        """Start i3wm accordingly to parameters in config_folder_path (with
        debug options)."""
        self._create_config()
        subprocess.run(["i3", "-c", self.current_config_file, "--shmlog-size=26214400"])

    def restart_i3_config(self):
        """Recreate temporal config and force i3wm to use it."""
        self._create_config()
        subprocess.run(["i3-msg", "-t", "command", "restart"])

    def start_py3status(self):
        """Start py3status status bar application, accordingly to parameters
        in config_folder_path."""
        success = False
        status_config_folder = (self.config_folder_path + self.resolution +
                                "/")
        print(status_config_folder)
        if os.path.exists(status_config_folder):
            status_config_file = (status_config_folder +
                                  "i3status.conf")
            if os.path.exists(status_config_file):
                print("Successfully found resolution i3status.conf",
                      file=sys.stderr)
                success = True

        if not success:
            print("Could not load or run resolution i3status.conf, falling\
                  back to default config_path/base/i3status.conf",
                  file=sys.stderr)
            status_config_file = (self.config_folder_path + "base/i3status.conf")

        subprocess.run(["py3status", "-c", status_config_file])

def get_parser_locker(parser):
    """Fill parser for 'lock' subcommand."""
    home_directory = str(Path.home())
    locking = parser.add_mutually_exclusive_group()
    locking.add_argument("--lock-screen",
                         help="Locks screen and blanks display.",
                         action="store_true", default=False)
    locking.add_argument("--set-up-locker", help="Start process in \
                        background which checks whether screen has to be \
                        locked due to inactivity or system suspend.",
                         action="store_true", default=False)

    parser.add_argument("--lock-images-path", help="Point to directory\
                        which contains correctly descripted images to use with\
                        lockscreen. (absolute path)",
                        default=get_root_folder() + "/configs/" +
                        get_resolution() +
                        "/wallpapers/")

    parser.add_argument("--lock-image-number", help="Number of image\
                        that should be used as a lockscreen wallpaper. Number\
                        must be compliant with naming standards.", type=int,
                        default=0)

    parser.add_argument("--lock-timeout", help="Time after which system will lock\
                        and system will go blank.", type=float, default=0.5)

def get_parser_runner(parser):
    """Fill parser for 'run' subcommand."""
    exclusive = parser.add_mutually_exclusive_group()

    exclusive.add_argument("--start-i3", help="Starts i3wm with \
                           provided parameters.", action="store_true",
                           default=False)
    exclusive.add_argument("--start-i3-debug", help="Starts i3wm with \
                           provided parameters (debug mode).",
                           action="store_true", default=False)
    exclusive.add_argument("--restart-i3-config", help="Recreates the\
                           config file and forces i3 refresh to use it.",
                           action="store_true", default=False)
    exclusive.add_argument("--start-py3status", help="Starts status bar\
                           manager.", action="store_true", default=False)

    parser.add_argument("--config-path", help="Root path of folder\
                        containing config subfolders and files (absolute)",
                        default=get_root_folder())

def get_parser_misc(parser):
    """Fill parser for 'misc' subcommand."""
    exclusive = parser.add_mutually_exclusive_group()

    exclusive.add_argument("--set-wallpaper", help="Sets image at provided\
                           path as a wallpaper.")


def set_up_parsers():
    """Return parser for all subcommands and main help."""
    parser = argparse.ArgumentParser("Main manager for system.")
    parser.set_defaults(func=default_parser)

    parser_getter = parser.add_subparsers()

    parser_runner = parser_getter.add_parser("run", help='Handle starting i3\
                                            functionality')
    get_parser_runner(parser_runner)
    parser_runner.set_defaults(func=runner)

    parser_locker = parser_getter.add_parser("lock", help='Handle lock\
                                             functionality')
    get_parser_locker(parser_locker)
    parser_locker.set_defaults(func=locker)

    parser_misc = parser_getter.add_parser("misc", help='Miscellanous\
                                          functionality')
    get_parser_misc(parser_misc)
    parser_misc.set_defaults(func=misc)

    return parser

def runner(args):
    """That function is run, when 'run' subcommand was chosen."""
    runner = Runner(args.config_path)

    if args.start_i3:
        runner.start_i3()
    if args.start_i3_debug:
        runner.start_i3()
    elif args.restart_i3_config:
        runner.restart_i3_config()
    elif args.start_py3status:
        runner.start_py3status()

def locker(args):
    """That function is run, when 'lock' subcommand was chosen."""
    locker = Locker(args.lock_images_path)
    image_number = args.lock_image_number

    timeout = args.lock_timeout
    if args.lock_screen:
        locker.lock_now(image_number, timeout)
    elif args.set_up_locker:
        locker.enable_lock_daemon(image_number, timeout)

def misc(args):
    """That function is run, when 'misc' subcommand was chosen."""

    if args.set_wallpaper:
        set_wallpaper(args.set_wallpaper)

def default_parser(args):
    """That function is run, when no subcommand is provided."""

    # TODO: Write better info.
    print("Currently this program can only be run with subprogram options.")
    print("Try to run 'python3 " + sys.argv[0] + " -h' to get some details.")

def main():
    """Run when script is called directly and not as a library."""
    parser = set_up_parsers()

    args = parser.parse_args()
    args.func(args)

if __name__ == "__main__":
    main()
