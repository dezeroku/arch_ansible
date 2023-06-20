## Arch setup roles written in Ansible

In the past, when I was distro-hopping at least once every two months, I've found it that it's not easy to keep track of all dotfiles and applications that I use.
I've decided to do something with that, first approach was to define my own ["high level package manager"](https://github.com/dezeroku/i3_config) and I got tired with it quite soon (the fact that I was only starting to learn programming at all wasn't helpful).
Some time later I've stumbled upon Ansible in one of the courses I was taking and it seemed to be just perfect for the job, with all its dependencies management, changing state only when it's required etc., so I've decided to move my config to it.
Fast-forward till today, this repository contains a bunch of roles that I am using everytime I need to set up an Arch install.
It's not distro-agnostic, but serves as good starting point when I am experimenting with distros like Gentoo.

## What's done

- [x] Small roles that are supposed to set up single functionality (i3 kind of breaks this rule)
- [x] Dependencies correctly defined between these roles
- [ ] Playbooks for common groups like audio related applications, xorg etc.

Currently I am refactoring most of the roles I've written in the beginning, due to them being very monolithic.

## Profiles

At the moment configuration is based global variables, take a look at `base.yaml` for more details. The most important ones are:
* username
* ssh key generation options
* email (to be used in e.g. git commits)
* shell you're going to use

There is a single `base.yaml` configuration which should be used as a starting point and customized per each machine where it's used, e.g. the `g751` switches should be kept off on non-NVIDIA-Optimus devices (such as `Asus G751JM` for which they were written).

`i3` role supports `1920x1080` (also can be set as `none`), `1366x768` and `1280x800` resolutions.
Using this role on a device with a different resolution may result in a distorted wallpaper/lockscreen images, but shouldn't break anything.

## Commands

At the moment there's `all.yml` playbook defined, that contains all roles available (sorted alphabetically).
It can be used to run single roles, e.g. to set up vim on `base` machine
```
sudo ansible-playbook -i base.yaml all.yml --tags vim
```

In general to run `<role>` on `<machine>` use
```
sudo ansible-playbook -i <machine>.yaml all.yml --tags <role>
```

It can also be used to install all packages listed.

## Credits

* Heavily inspired by [spark](https://github.com/pigmonkey/spark). If you're looking to implement something similar, then you should probably base on this repository.
* Take a look at [dotfiles repo](https://github.com/tojatos/dotfiles) from @tojatos (especially ZSH theme).
