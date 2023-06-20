## Arch setup roles written in Ansible

In the past, when I was distro-hopping at least once every two months, I've found it that it's not easy to keep track of all dotfiles and applications that I use.
I've decided to do something with that, first approach was to define my own ["high level package manager"](https://github.com/dezeroku/i3_config) and I got tired with it quite soon (the fact that I was only starting to learn programming at all wasn't helpful).
Some time later I've stumbled upon Ansible in one of the courses I was taking and it seemed to be just perfect for the job, with all its dependencies management, changing state only when it's required etc., so I've decided to move my config to it.
Fast-forward till today, this repository contains a bunch of roles that I am using everytime I need to set up an Arch install.
It's not distro-agnostic, but serves as good starting point when I am experimenting with distros like Gentoo.

## What's done

- [x] Small roles that are supposed to set up single functionality (i3 kind of breaks this rule)
- [x] Dependencies correctly defined between these roles
- [x] Playbooks for common groups like audio related applications, xorg etc.

Currently I am refactoring most of the roles I've written in the beginning, due to them being very monolithic.

## Profiles

At the moment configuration is based global variables, take a look at `base.yaml` for more details. The most important ones are:
* username
* ssh key generation options
* email (to be used in e.g. git commits)
* shell you're going to use

There is a single `base.yaml` configuration which should be used as a starting point and customized per each machine where it's used, e.g. the `g751` switches should be kept off on non-NVIDIA-Optimus devices (such as `Asus G751JM` for which they were written).

`i3` role supports `1920x1080` (default in the role), `1366x768` and `1280x800` resolutions.
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

It can also be used to install all packages listed, if no tags are provided.

### First time
If you don't want to install all packages but still want to have a proper setup of specific "groups" you can use few high-level tags tags.
```
sudo ansible-playbook -i <machine>.yaml all.yml --tags core
sudo ansible-playbook -i <machine>.yaml all.yml --tags cli # sets up fzf, fish, etc.
sudo ansible-playbook -i <machine>.yaml all.yml --tags desktop # sets up i3, i3lock and friends
sudo ansible-playbook -i <machine>.yaml all.yml --tags desktop-tools # archiver, doc viewers, etc.
sudo ansible-playbook -i <machine>.yaml all.yml --tags media # VNC, MPV, spotify, etc.
sudo ansible-playbook -i <machine>.yaml all.yml --tags virtualization # qemu, vagrant, virtualbox
sudo ansible-playbook -i <machine>.yaml all.yml --tags social # discord
sudo ansible-playbook -i <machine>.yaml all.yml --tags browser # qutebrowser, firefox
sudo ansible-playbook -i <machine>.yaml all.yml --tags languages # python, golang, rust
sudo ansible-playbook -i <machine>.yaml all.yml --tags editors # vim, nvim, emacs
sudo ansible-playbook -i <machine>.yaml all.yml --tags docker # just docker
sudo ansible-playbook -i <machine>.yaml all.yml --tags utils # stuff that doesn't fall into any category really, but is generally useful
sudo ansible-playbook -i <machine>.yaml all.yml --tags work # work related stuff, e.g. jira CLI (requires work.enabled = true in yaml config)
sudo ansible-playbook -i <machine>.yaml all.yml --tags office # libreoffice, latex
sudo ansible-playbook -i <machine>.yaml all.yml --tags gaming # Steam
sudo ansible-playbook -i <machine>.yaml all.yml --tags vpn # OpenVPN, wireguard tooling
```

There are also few specific packages (such as android-studio or intellij-idea) that are not part of any group and need to installed using individual tags.
Similar for things that are not used by me at the moment, but can be useful in the future, e.g. ZSH setup.

To get all the groups and leave out the single packages:
```
sudo ansible-playbook -i <machine>.yaml all.yml --tags core,cli,desktop,desktop-tools,media,virtualization,social,browser,languages,editors,docker,utils,work,office,gaming,vpn
```

## Credits

* Heavily inspired by [spark](https://github.com/pigmonkey/spark). If you're looking to implement something similar, then you should probably base on this repository.
* Take a look at [dotfiles repo](https://github.com/tojatos/dotfiles) from @tojatos (especially ZSH theme).
* AUR library file in version `v0.10.0` taken from [kewlfft/ansible-aur](https://github.com/kewlfft/ansible-aur)
