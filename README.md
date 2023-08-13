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

- username
- ssh key generation options
- email (to be used in e.g. git commits)
- shell you're going to use

There is a single `base.yaml` configuration which should be used as a starting point and customized per each machine where it's used, e.g. the `g751` switches should be kept off on non-NVIDIA-Optimus devices (such as `Asus G751JM` for which they were written).

`i3` role supports `1920x1080` (default in the role), `1366x768` and `1280x800` resolutions.
Using this role on a device with a different resolution may result in a distorted wallpaper/lockscreen images, but shouldn't break anything.

## Commands

To install the dependencies (roles) run:

```
ansible-galaxy install -r requirements.yml
```

At the moment there's `all.yml` playbook defined, that contains all roles available (sorted alphabetically).
It can be used to run single roles, e.g. to set up vim on `base` machine

```
ansible-playbook -i base.yaml -i custom.yaml all.yml --tags vim
```

You'll most likely want to override some of the variables depending on your environment (e.g. you want to use a different git email for work and private stuff).
This can be done with just modifying the whole inventory file or maintaining multiple copies, but your best bet is probably to define an override file like `custom.yaml`
that would only contain the variables that actually differ from the defaults defined in `base.yaml`.
This way it's much easier to update to the newer versions and keep everything tidy.
Examples listed below are done with the `custom.yaml` file override in mind.

Note: Ansible doesn't like to merge the dictionaries from two inventories, the latter one just overrides the former.
Remember about this when adding new variables.

So to run a `vim` on `work` machine you could use something like:

```
ansible-playbook -i base.yaml -i work.yml all.yml --tags vim
```

It can also be used to install all packages listed, if no tags are provided.

### First time

Tip: If you don't have a passwordless sudo set up (and you probably shouldn't) you can add `--ask-become-pass` flag to each call, so Ansible can elevate
privileges when needed (e.g. for pacman operations).
Of course this will only work after user with sudo access is actually set up, it's probably best to do the initial setup as root.

If you don't want to install all packages but still want to have a proper setup of specific "groups" you can use few high-level tags tags.

```
ansible-playbook -i base.yaml -i custom.yaml all.yml --tags core
ansible-playbook -i base.yaml -i custom.yaml all.yml --tags cli # sets up fzf, fish, etc.
ansible-playbook -i base.yaml -i custom.yaml all.yml --tags desktop # sets up i3, i3lock and friends
ansible-playbook -i base.yaml -i custom.yaml all.yml --tags desktop-tools # archiver, doc viewers, etc.
ansible-playbook -i base.yaml -i custom.yaml all.yml --tags media # VNC, MPV, spotify, etc.
ansible-playbook -i base.yaml -i custom.yaml all.yml --tags virtualization # qemu, vagrant, virtualbox
ansible-playbook -i base.yaml -i custom.yaml all.yml --tags social # discord
ansible-playbook -i base.yaml -i custom.yaml all.yml --tags browser # qutebrowser, firefox
ansible-playbook -i base.yaml -i custom.yaml all.yml --tags languages # python, golang, rust
ansible-playbook -i base.yaml -i custom.yaml all.yml --tags editors # vim, nvim, emacs
ansible-playbook -i base.yaml -i custom.yaml all.yml --tags docker # just docker
ansible-playbook -i base.yaml -i custom.yaml all.yml --tags utils # stuff that doesn't fall into any category really, but is generally useful
ansible-playbook -i base.yaml -i custom.yaml all.yml --tags work # work related stuff, e.g. jira CLI (requires work.enabled = true in yaml config)
ansible-playbook -i base.yaml -i custom.yaml all.yml --tags office # libreoffice, latex
ansible-playbook -i base.yaml -i custom.yaml all.yml --tags gaming # Steam
ansible-playbook -i base.yaml -i custom.yaml all.yml --tags vpn # OpenVPN, wireguard tooling
```

There are also few specific packages (such as android_studio or intellij_idea) that are not part of any group and need to installed using individual tags.
Similar for things that are not used by me at the moment, but can be useful in the future, e.g. ZSH setup.

To get all the groups and leave out the single packages you can use the `install-all-groups` scriptlet.

## Things that require manual setup anyway (pretty much configuration dependent)

- autorandr

## Testing

Testing on host is probably the easiest approach, for end-to-end testing the `vagrant` role sets up Vagrant VM in `~/archlinux_vm` which can be used with ansible with minimal effort.

Please remember that if the initial `pacman -Syu` updates some components (e.g. kernel) it might be necessary to reboot before continuing with the testing.
As an example, starting `docker` is not possible after kernel update and without reboot.

### Some useful commands

- `vagrant up`
- `vagrant halt`
- `vagrant destroy`
- `vagrant provision`
- `vagrant ssh`

## Installation from scratch

These are mostly notes for myself on how to set up an Arch system with encryption on a UEFI enabled device.

- Follow [Installation Guide](https://wiki.archlinux.org/title/installation_guide) until you get to partitioning
- Follow [LVM_on_LUKS](https://wiki.archlinux.org/title/dm-crypt/Encrypting_an_entire_system#LVM_on_LUKS) for partitioning
  Basic setup without separate home can be followed

- Bootstrap with the following list `pacstrap -K /mnt base base-devel linux linux-firmware lvm2 networkmanager ansible git neovim refind`

- Follow the guide again until you get to initramfs, then set up according to the `LVM_on_LUKS` article

- Run `refind-install` to set up the bootloader
- Uncomment the `extra_kernel_version_strings` line in `/boot/EFI/refind/refind.conf`

- Modify the `/boot/refind_linux.conf`, so it looks similar to this:

```
# Choose proper microcode depending on your CPU here
# You'll need to install amd-ucode or intel-ucode
# You can run `blkid | grep UUID=` to get UUIDs of the partitions
"Boot with microcode updates" "initrd=\intel-ucode.img initrd=\initramfs-%v.img cryptdevice=UUID=<LUKS PARTITION UUID>:<LVM name> root=/dev/<volume group name>/<root name> resume=/dev/<volume group name>/<swap name>
...
```

- Modify your `/etc/fstab` so it looks roughly like this:

```
/dev/mapper/<GroupName>-<root name> / ext4 rw,relatime 0 0

/dev/mapper/<GroupName>-<swap name> swap swap defaults 0 0

UUID=<UUID of the EFI/boot partition> /boot vfat defaults 0 0
```

- Reboot into the freshly installed system

- Start the `NetworkManager` service and obtain Internet connectivity with `nmcli`
  For the wired connection:

```
nmcli device connect <interface name>
```

- Clone this repo, prepare `custom.yaml` and run as usual
- One-shot action, run the `passwd <username>` to set up the password for a user that was created by this repo
