## Arch setup roles written in Ansible

In the past, when I was distro-hopping at least once every two months, I've found it that it's not easy to keep track of all dotfiles and applications that I use.
I've decided to do something with that, first approach was to define my own ["high level package manager"](https://github.com/d0ku/i3_config) and I got tired with it quite soon (the fact that I was only starting to learn programming at all wasn't helpful).
Some time later I've stumbled upon Ansible in one of the courses I was taking and it seemed to be just perfect for the job, with all its dependencies management, changing state only when it's required etc., so I've decided to move my config to it.
Fast-forward till today, this repository contains a bunch of roles that I am using everytime I need to set up an Arch install.
It's not distro-agnostic, but serves as good starting point when I am experimenting with distros like Gentoo.

## What's done

- [x] Small roles that are supposed to set up single functionality (i3 kind of breaks this rule)
- [x] Dependencies correctly defined between these roles
- [ ] Playbooks for common groups like audio related applications, xorg etc.

Currently I am refactoring most of the roles I've written in the beginning, due to them being very monolithic.

## Profiles

At the moment configuration is based on some global variables, which are:

* username
* ssh key generation options
* email (to be used in e.g. git configuration)
* shell you're going to use

There are some roles which are tied to specific hardware, for example `g751` requires additional service for managing GPU fan speed, resolutions also differ between machines.
That's one of the things I am currently working on, that kind of hardcoding some configurations is ugly and should be refactored.

| Name                 | Resolution |
| ----                 | ---------- |
| x200 (Thinkpad X200) | 1280x800   |
| x230 (Thinkpad X230) | 1366x768   |
| g751 (Asus G751JM)   | 1920x1080  |

## Commands

At the moment there's `all.yml` playbook defined, that contains all roles available (sorted alphabetically).
It can be used to run single roles, e.g. to set up vim on `x230` machine
```
ansible-playbook all.yml -i inventory -e pc=x230 --tags vim
```

It can also be used to installed all packages (some rules can be commented if not needed, ugly solution at the moment).

## Credits

* Heavily inspired by [spark](https://github.com/pigmonkey/spark). If you're looking to implement something similar, then you should probably base on this repository.
* Take a look at [dotfiles repo](https://github.com/tojatos/dotfiles) from @tojatos (especially ZSH theme).
