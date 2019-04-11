"""Parser module responsible for parsing apps list files, and returning groups
ready to display to user.
App objects already have methods implemented that prompt for user decision for
installation.
By d0ku 2018"""

import sys
import re

from base import SetupError

class AppsListParserError(SetupError):
    """Thrown when there was error in parsing apps list."""
    message = "There was an error in parsing apps list."
    def __init__(self, line_number):
        self.line_number = line_number

class IncorrectAppsListError(AppsListParserError):
    """Thrown when there was a problem with specific group."""
    def __init__(self, line_number, group_name, description=""):
        self.line_number = line_number
        self.group_name = group_name
        self.description = description
        self.message = ("There was a problem when parsing group " +
                        self.group_name)

class AppsGroupNotClosedError(AppsListParserError):
    """Thrown when there is group open, but end of file was ended without it
    being closed."""
    message = "There was a try to open new group, but previous is not yet closed."
    def __init__(self, line_number, group_name):
        self.line_number = line_number
        self.group_name = group_name

class AppsGroupClosedNotStartedError(AppsListParserError):
    """Thrown when there is group closed, but there is no group open to be
    closed."""
    message = "Group close tag detected, but no group is open."
    pass

class AppsGroupDoesNotExistAppAddedError(AppsListParserError):
    """Thrown when there is no currently open group, but parser sees app to be
    added to group."""
    message = "Application name detected, but there is no opened group to add \
            app to currently."
    pass

class AppsGroupAlreadyOpenedError(AppsListParserError):
    """Throw when there is already app group opened, but parser see new app
    group to be open. (New group opening, with previously opened group not
    closed."""
    def __init__(self, line_number, group_name):
        self.line_number = line_number
        self.group_name = group_name
        self.message = ("Group open tag detected, but current group (" +
                        self.group_name + ") is not yet closed.")

class AppsGroup:
    """Displays apps to user and checks whether he wants it to be installed or
    not."""

    def __init__(self, name):
        self.name = name
        self.applications = []
        self.accepted = []

    def add_application(self, app_name):
        """Adds application to list of apps that should be displayed to
        user."""
        self.applications.append(app_name)

    def pretty_print(self):
        """Prints group details on screen."""
        print("Group name: " + self.name)
        print("Apps to install: ")
        for app in self.accepted:
            print("- " + app.name)
            if app.description:
                print("    " + app.description)
        print("Apps in group: ")
        for app in self.applications:
            print("- " + app.name, end="")
            if app.description:
                print(" (" + app.description + ")")
            else:
                print("")
        print("")

    def process_one(self):
        """Displays to user whether he wants to install first of the not yet
        listed apps. It moves it to accepted if user accepts or deletes that
        app from queue. Returns False when queue is empty, True otherwise."""
        if not self.applications:
            return False
        app = self.applications.pop()

        print("App name: "+app.name)
        if app.description:
            print(app.description)

        print("\n")
        install = get_user_input_install()
        if install:
            self.accepted.append(app)

        return True

    def process_all(self):
        """Processes all apps in group, using self.process_one."""
        print("Processing group: " + self.name)
        while self.process_one():
            pass
        print("All apps from group processed.")
        if self.accepted:
            print("To be installed: ")
            for app in self.accepted:
                print(app.name + " ")
            return True

        print("Nothing to be installed.")
        return False

class App:
    """Contains info about one application from list."""
    def __init__(self, name, description=False):
        self.name = name
        self.description = description

    def __eq__(self, other):
        return self.name == other.name and self.description == other.description

def parse_apps_list(file_name):
    """That function returns groups of applications to install (AppsGroup).
    All files that go through this function should be correctly prepared:
    $$ tags start a group and name of a group should be between them.
    ?? tags end group of apps
    ** tags are a description of app functionality
    There should be one app/group tag per line.
    Lines starting with '#' are ignored.
    Empty lines are allowed and ignored.
    If line contains a group name, it must end immediately after $$ (no
    whitespaces allowed).
    All description must fit in one line.
    Same goes for ** and ??
    Example:
        $$GUI$$
        xorg
        i3 **window manager**
        ??
    defines a group of apps called GUI, that consists of xorg and i3 to be
    installed. i3 also has description 'window manager'"""
    groups = []

    group_start_str = "\\$\\$.*\\$\\$[\\ ]*$"
    group_end_str = "^\\?\\?[\\ ]*$"
    description_str = "\\*\\*.*\\*\\*[\\ ]*$"
    just_app_name_str = "^[^\\$\\*\\?\\n\\ ]*"
    comment_or_empty_str = "(^[\\ ]*#|^[\\ ]*$)"

    group_start = re.compile(group_start_str)
    group_end = re.compile(group_end_str)
    description = re.compile(description_str)
    just_app_name = re.compile(just_app_name_str)
    comment_str = re.compile(comment_or_empty_str)

    with open(file_name, "r") as app_list:
        curr_group = None
        counter = 0
        for line in app_list:
            counter += 1
            if comment_str.match(line):
                # We don't care about commented out or empty lines.
                continue
            match = group_start.search(line)
            if match:
                if curr_group is not None:
                    raise AppsGroupAlreadyOpenedError(str(counter),
                                                      curr_group.name)
                # BUG: When new group is created here, it already contains one
                # app.

                # Here curr_group is still None.
                curr_group = AppsGroup(match.group()[2:-2])
                # Here curr_group already has application.
                continue

            match = group_end.search(line)
            if match:
                if curr_group is None:
                    raise AppsGroupClosedNotStartedError(str(counter))
                groups.append(curr_group)
                curr_group = None
                continue

            match = description.search(line)
            if match:
                if curr_group is None:
                    raise AppsGroupDoesNotExistAppAddedError(str(counter))
                app_descr = match.group()[2:-2]
                match = just_app_name.search(line)
                app_name = match.group()
                app = App(app_name, app_descr)
                curr_group.add_application(app)
                continue

            match = just_app_name.search(line)
            if match:
                if curr_group is None:
                    raise AppsGroupDoesNotExistAppAddedError(str(counter))
                app_name = match.group()
                app = App(app_name)
                curr_group.add_application(app)
                continue

            raise IncorrectAppsListError(str(counter), "N/A", "Could not match\
                                         that line as either non-important,\
                                         group start, group end or app. Check\
                                         for any strange whitespaces.")


    if curr_group is not None:
        raise AppsGroupNotClosedError(str(counter), curr_group.name)
    return groups

def get_user_input_install():
    """Display install dialog."""
    # That loop will surely end, so it's safe to use here.
    print("")
    while True:
        temp = input("Do you want to install? [Y]/n? ")
        if temp in ("", "Y", "y"):
            return True
        if temp in ("n", "N"):
            return False
        print("You have to choose between Y|y and N|n !")
