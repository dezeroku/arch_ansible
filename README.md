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

At the moment there's `site.yml` playbook defined, that contains all roles available (sorted alphabetically).
It can be used to run single roles, e.g. to set up vim on `base` machine

```
ansible-playbook -i base.yaml -i custom.yml site.yml --tags vim
```

You'll most likely want to override some of the variables depending on your environment (e.g. you want to use a different git email for work and private stuff).
This can be done with just modifying the whole inventory file or maintaining multiple copies, but your best bet is probably to define an override file like `custom.yml`
that would only contain the variables that actually differ from the defaults defined in `base.yaml`.
This way it's much easier to update to the newer versions and keep everything tidy.
Examples listed below are done with the `custom.yml` file override in mind.

Note: Ansible doesn't like to merge the dictionaries from two inventories, the latter one just overrides the former.
Remember about this when adding new variables.

So to run a `vim` on `work` machine you could use something like:

```
ansible-playbook -i base.yaml -i work.yml site.yml --tags vim
```

It can also be used to install all packages listed, if no tags are provided.

### First time

Tip: If you don't have a passwordless sudo set up (and you probably shouldn't) you can add `--ask-become-pass` flag to each call, so Ansible can elevate
privileges when needed (e.g. for pacman operations).
Of course this will only work after user with sudo access is actually set up, it's probably best to do the initial setup as root.

If you don't want to install all packages but still want to have a proper setup of specific "groups" you can use few high-level tags tags.

```
ansible-playbook -i base.yaml -i custom.yml site.yml --tags core
ansible-playbook -i base.yaml -i custom.yml site.yml --tags cli # sets up fzf, fish, etc.
ansible-playbook -i base.yaml -i custom.yml site.yml --tags desktop # sets up i3, i3lock and friends
ansible-playbook -i base.yaml -i custom.yml site.yml --tags desktop-tools # archiver, doc viewers, etc.
ansible-playbook -i base.yaml -i custom.yml site.yml --tags media # VNC, MPV, spotify, etc.
ansible-playbook -i base.yaml -i custom.yml site.yml --tags virtualization # qemu, vagrant, virtualbox
ansible-playbook -i base.yaml -i custom.yml site.yml --tags social # discord
ansible-playbook -i base.yaml -i custom.yml site.yml --tags browser # qutebrowser, firefox
ansible-playbook -i base.yaml -i custom.yml site.yml --tags languages # python, golang, rust
ansible-playbook -i base.yaml -i custom.yml site.yml --tags editors # vim, nvim, emacs
ansible-playbook -i base.yaml -i custom.yml site.yml --tags docker # just docker
ansible-playbook -i base.yaml -i custom.yml site.yml --tags utils # stuff that doesn't fall into any category really, but is generally useful
ansible-playbook -i base.yaml -i custom.yml site.yml --tags work # work related stuff, e.g. jira CLI (requires work.enabled = true in yaml config)
ansible-playbook -i base.yaml -i custom.yml site.yml --tags office # libreoffice, latex
ansible-playbook -i base.yaml -i custom.yml site.yml --tags vpn # OpenVPN, wireguard tooling
```

There are also few specific packages (such as android_studio or intellij_idea) that are not part of any group and need to installed using individual tags.
Similar for things that are not used by me at the moment, but can be useful in the future, e.g. ZSH setup.

To get all the groups and leave out the single packages you can use the `install-common-groups` scriptlet.

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
  Basic setup without separate home can be followed. Rough idea for the setup:

```
parted <device>
  mklabel gpt
  yes
  mkpart "EFI" fat32 1MiB 1001MiB
  set 1 esp on
  mkpart "ARCH" ext4 1001MiB 100%

cryptsetup luksFormat /dev/<device>2
cryptsetup open /dev/<device>2 archlvm

pvcreate /dev/mapper/archlvm
vgcreate ArchGroup /dev/mapper/archlvm

# Make it at least the same size as your RAM
# if you want hibernation to work easily
lvcreate -L 32G ArchGroup -n swap
lvcreate -l 100%FREE ArchGroup -n root

mkfs.ext4 /dev/ArchGroup/root
mkswap /dev/ArchGroup/swap
mkfs.fat -F32 /dev/<device>1

mount /dev/ArchGroup/root /mnt
mount --mkdir /dev/<device>1 /mnt/boot
swapon /dev/ArchGroup/swap
```

- Bootstrap with the following list `pacstrap -K /mnt <intel-ucode or amd-ucode depending on your CPU> base base-devel linux linux-firmware lvm2 networkmanager ansible git neovim refind`

- Follow the guide again until you get to initramfs, then set up according to the `LVM_on_LUKS` article. Additionally you can add the `resume` hook after both `filesystems` and `lvm2`, but before `fsck` if you want to use hibernation later on.

- Run `refind-install` to set up the bootloader
- Uncomment the `extra_kernel_version_strings` line in `/boot/EFI/refind/refind.conf`

- Modify the `/boot/refind_linux.conf`, so it looks similar to this:

```
# Choose proper microcode depending on your CPU here
# You'll need to install amd-ucode or intel-ucode as listed above
# You can run `blkid | grep UUID=` to get UUIDs of the partitions
# Add the `resume=` param if you want to use the hibernation
"Boot with microcode updates" "(initrd=\intel-ucode.img or initrd=\amd-ucode.img depending on your CPU) initrd=\initramfs-%v.img cryptdevice=UUID=<LUKS PARTITION UUID>:archlvm root=/dev/ArchGroup/root resume=/dev/ArchGroup/swap
...
```

- Modify your `/etc/fstab` so it looks roughly like this:

```
/dev/mapper/ArchGroup-root / ext4 rw,relatime 0 1

/dev/mapper/ArchGroup-swap swap swap defaults 0 0

UUID=<UUID of the EFI/boot partition> /boot vfat defaults 0 2
```

- Reboot into the freshly installed system

- Start the `NetworkManager` service and obtain Internet connectivity with `nmcli`
  For the wired connection:

```
nmcli device connect <interface name>
```

For Wi-Fi:

```
nmcli device wifi connect <AP name> password <password>
```

- Clone this repo, prepare `custom.yml` (copy `install-common-groups` to a separate file if you want to manage groups independently) and run as usual
- One-shot action, run the `passwd <username>` to set up the password for a user that was created by this repo
