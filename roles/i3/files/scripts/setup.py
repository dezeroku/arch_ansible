"""Initial installation and setup of my Arch Linux config.
Should handle installing packages and linking up some dotfiles.

Steps:
    Install AUR helper (yay currently) Ok
    Install stuff Ok
    Install AUR stuff Ok
    Some setup for npm Ok
    Link dotfiles (symlinking mimeapps.list) Ok
    Set up apps configs
    Install language packages (go, python, js etc.)
    Configure MIME and let apps update their plugins or whatever
    Configure thefuck
    add required shell sources
    Enable vnstat
By d0ku 2018"""

import subprocess
import argparse
import sys
import os
import shutil

# Parsing apps list files.
import file_parser

def dotfiles_symlink(dotfiles_dir, backup_dir="~/backup_dotfiles"):
    """Symlink all files belows to correct locations (backing up previous
    entries in backup_dir). Also symlinks MIME settings file."""

    dotfiles_dir = os.path.abspath(dotfiles_dir) + "/"
    backup_dir = os.path.expanduser(backup_dir)
    # Create backup directory if one does not already exist.
    if not os.path.exists(backup_dir):
        os.makedirs(backup_dir)

    files = {"Xresources":"~/.Xresources",
             "rc.conf":"~/.config/ranger/rc.conf",
             "vimrc":"~/.vimrc",
             "tmux.conf":"~/.tmux.conf",
             "dunstrc":"~/.config/dunst/dunstrc",
             "rofi_config":"~/.config/rofi/config",
             "qute_config.py":"~/.config/qutebrowser/config.py",
             "mimeapps.list":"~/.config/mimeapps.list",
             "ycm_extra_conf.py":"~/.ycm_extra_conf.py",
             "zshrc":"~/.zshrc",
             "tern-config":"~/.tern-config",
             "picom.conf":"~/.config/picom.conf",
             "emacs":"~/.emacs",
             "vimrc":"~/.config/nvim/init.vim",
             "ssh_config":"~/.ssh/config"}

    for replace, original in files.items():
        original = os.path.expanduser(original)
        print(original)
        if os.path.islink(original):
            # If there is a symlink in final location, unlink it.
            os.unlink(original)
            #print("Delinking: " + original)
        if os.path.exists(original):
            # If there is a file in final location, back it up.
            shutil.move(original, backup_dir + "/" + replace)
            print("Backed up " + original + " in " + backup_dir + "/" + replace)
        try:
            os.symlink(dotfiles_dir  + replace, original)
        except FileNotFoundError:
            # If there is no parent directory, create it.
            os.makedirs(os.path.dirname(original))
            os.symlink(dotfiles_dir  + replace, original)
        print("Symlinked " + dotfiles_dir + replace + " to " + original)

def source_shell_files(shell_files_dir, output_file="~/.bash_profile"):
    """Write source 'script_name' for specific scripts in shell_files_dir to
    output_file."""
    file_names = ['path', 'aliases']
    shell_files_dir = os.path.abspath(shell_files_dir)

    with open(output_file, "a") as output:
        for file_name in file_names:
            output.write("source " + shell_files_dir + "/" + file_name + "\n")

def add_to_path(path, output_file="~/.bash_profile"):
    """Adds specified text to shell path configuration, first expanding it."""
    path = os.path.abspath(path)
    with open (output_file, "a") as output:
        output.write('export PATH="$PATH:' + path + '"')


def setup_npm_stuff(dir_name):
    """Create directory in path provided by user and force npm to use it."""
    npm_dir = os.path.abspath(os.path.expanduser(dir_name))
    try:
        os.makedirs(npm_dir)
    except FileExistsError:
        print("Could not set npm.")
        print("Error: Directory already exists")
        sys.exit(1)

    result = subprocess.run(["npm", "config", "set", "prefix", npm_dir])

    if result.returncode != 0:
        print("Could not set up npm global config dir.")
        sys.exit(1)

def install_yay():
    """Installs yay AUR helper."""
    result = subprocess.run(["sh", "setup/install_yay.sh"])
    return result

def install_offical_repos_apps():
    """Display to user and install chosen apps from
    ./apps_list/arch_repo_apps.txt"""
    groups = file_parser.parse_apps_list("apps_list/arch_repo_apps.txt")

def get_argparser_parser(parser=argparse.ArgumentParser()):
    parser.add_argument("--parse-app-file", help="Parses file provided\
                        as an argument and pretty prints all groups. It should\
                        be used mainly as a tool to check whether\
                        configuration file is correct.")
    parser.set_defaults(func=parse_func)

    return parser

def get_argparser_installer(parser=argparse.ArgumentParser()):
    exsclusive = parser.add_mutually_exclusive_group()

    group = exsclusive.add_argument_group()
    group.add_argument("--install-from-file", help="Parses file provided as\
                        an argument. Displays all groups to used, and installs\
                        those apps that will be accepted by user.")
    group.add_argument("--install-command", help="Command issued to package\
                        manager preceeding apps list. (Don't add '-' to it.",
                        default="Syu")
    group.add_argument("--package-manager", help="Package manager name.\
                        That's the first argument of shell call to\
                        install.",default="pacman")
    group.add_argument("--do-not-reinstall", help="Adds --needed options to\
                       program call, so pacman does not reinstall already\
                       installed packages. (Should be used only with\
                       pacman-compatible package managers.)",
                       action="store_true")

    exsclusive.add_argument("--install-aur-helper", help="Installs AUR helper\
                            basing on provided string.")

    parser.set_defaults(func=install_func)

    return parser

def get_argparser_setup(parser=argparse.ArgumentParser()):
    exclusive = parser.add_mutually_exclusive_group()

    exclusive.add_argument("--set-up-npm-dir", help="Creates dir at specified\
                        location and tells npm to use it as global config dir.")
    exclusive.add_argument("--symlink-dotfiles", help="Symlinks dotfiles\
                           from dir provided in first argument, backing up\
                           original dotfiles in folder provided as\
                           second_argument.", nargs=2, metavar=('dotfiles_dir',
                                                                'backup_dir'))
    exclusive.add_argument("--source-shell-files", help="Sources specific\
                           files from input_folder to output_file.", nargs=2,
                           metavar=('input_folder', 'output_file'))
    exclusive.add_argument("--add-to-path", help="Adds specified path to PATH\
                           in specified file.", nargs=2,
                           metavar=("path_to_add", "output_file"))

    parser.set_defaults(func=setup_func)

    return parser

def get_parser_groups(file_name):
    try:
        groups = file_parser.parse_apps_list(file_name)
    except file_parser.AppsListParserError as e:
        print("There was an error on line: " + e.line_number)
        print("Error name: " + e.__class__.__name__)
        print("Error message: " + e.message)
        sys.exit(1)
    except FileNotFoundError as e:
        print("There was an error on line: N/A")
        print("Error name: " + e.__class__.__name__)
        print("Error: Could not open file " + e.filename)
        sys.exit(1)

    return groups

def main_func(args):
    """That function is called when setup.py was run without any detected
    subparser command."""
    print("This command should only be run with subcommand parameters.")
    print("Run 'python3 " + sys.argv[0] + " -h' to get more info.")

def setup_func(args):
    """That function is called when setup.py was run with 'setup' subparser
    command."""
    if args.set_up_npm_dir:
        setup_npm_stuff(args.set_up_npm_dir)
    elif args.symlink_dotfiles:
        dotfiles_symlink(args.symlink_dotfiles[0], args.symlink_dotfiles[1])
    elif args.source_shell_files:
        source_shell_files(args.source_shell_files[0],
                           args.source_shell_files[1])
    elif args.add_to_path:
        add_to_path(args.add_to_path[0], args.add_to_path[1])

def parse_func(args):
    """Function that is called when 'parse' parser command was chosen."""
    """Parse configuration file and display found groups. Mainly used for
    checking whether configuration file is correct."""
    if args.parse_app_file:
        groups = get_parser_groups(args.parse_app_file)
        for group in groups:
            group.pretty_print()

def install_func(args):
    """Function that is called when 'install' parser command was chosen."""
    if args.install_from_file:
        groups = get_parser_groups(args.install_from_file)
        package_manager = args.package_manager
        install_command = "-" + args.install_command
        to_install_apps = []
        command = [package_manager, install_command]
        if args.do_not_reinstall:
            command.append("--needed")
        result = input("If you want to just install all apps, write 'AGREED',\
                       otherwise all groups will be displayed.")

        if result == 'AGREED':
            for group in groups:
                to_install_apps += group.applications
        else:
            for group in groups:
                group.process_all()
                to_install_apps += group.accepted

        print("To install: ", end=" ")
        for app in to_install_apps:
            print(app.name, end=" ")

        print("")

        to_install_str = [app.name for app in to_install_apps]

        command_str = ""
        for temp in command:
            command_str += temp
            command_str += " "
        for app in to_install_str:
            command_str += app
            command_str += " "

        print("Running: " + command_str)

        result = subprocess.run([package_manager, install_command] + to_install_str,
                                stdin=sys.stdin, stdout=sys.stdout, stderr=sys.stderr)

        if result.returncode != 0:
            print("Error: Could not install apps!")
            sys.exit(1)
    elif args.install_aur_helper:
        if args.install_aur_helper == "yay":
            result = install_yay()
            if result.returncode != 0:
                print("Error: Could not install yay.")
                sys.exit(1)
        else:
            print("Error: Currently only yay install is supported that way.")
            sys.exit(1)

def main():
    """Function which is called, when script is executed directly and not used
    as a library."""
    main_parser = argparse.ArgumentParser("Main utility for setting up fresh\
                                          Arch Linux.")
    main_parser.set_defaults(func=main_func)

    subparsers = main_parser.add_subparsers(help="Subcommands for utility.")

    parser_parser = subparsers.add_parser("parse")
    get_argparser_parser(parser_parser)
    install_parser = subparsers.add_parser("install")
    get_argparser_installer(install_parser)
    setup_parser = subparsers.add_parser("setup")
    get_argparser_setup(setup_parser)

    args = main_parser.parse_args()
    args.func(args)
    #install_yay()
    #install_offical_repos_apps()

if __name__ == "__main__":
    main()
