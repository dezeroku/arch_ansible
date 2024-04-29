## Arch setup roles written in Ansible

In the past, I have found out that keeping track of all the dotfiles is not easy, especially when multiple devices come into play.
I have decided to do something with that, first approach was to define my own ["package manager"](https://github.com/dezeroku/i3_config) and
very soon it became apparent that writing such a thing from scratch is not a great idea
(the fact that I was a programming newbie was not really helpful).

Later on I have stumbled upon Ansible in one of the courses I was taking and it seemed perfect for the job, with proper dependencies management,
changing state only when it is required and so on, so I have decided to move my config to it.

Fast-forward till today, this repository contains a bunch of roles that I use when setting up a fresh Arch install.
It is not distro-agnostic, but most of the config (except for the `pacman` and `AUR` usage) should be usable as-is.

## What's done

- [x] Small roles that are supposed to set up single functionality (i3 kind of breaks this rule)
- [x] Dependencies correctly defined between these roles
- [x] Playbooks for common groups like audio related applications, `wayland`, etc.

## Profiles

At the moment configuration is based on few global variables (and can be fine-tuned with role-specifc ones), take a look at `base.yml` for few examples.
The most important ones are:

- username
- ssh key generation options
- email (to be used in e.g. git commits)
- shell you are going to use

There is a single `base.yml` configuration which should be used as a starting point and customized per each machine where it is used.
After all workflows and required tools differ a lot between e.g. laptops and headless servers.

## Commands

To install the dependencies (roles) run:

```
ansible-galaxy install -r requirements.yml
```

The `site.yml` playbook serves as an entry point to the whole system.

It can be used to run single roles, e.g. to set up vim:

```
ansible-playbook site.yml --tags vim
```

or package groups:

```
ansible-playbook site.yml --tags mail
```

Groups and tags can be checked by looking in the `playbooks/` directory and `site.yml` file.

Device specific customizations should be put in `custom.yml` file.
Values from it will override the ones from `base.yml`.

Note: Ansible does not like to merge dictionaries from two inventories, the latter one just overrides the former.
Remember about this, as it requires you to copy the whole dictionary from `base.yml` when you want to modify only a single key.

### First time

This repository can be run as root on the first boot, it will then take care of creating the user.

In subsequent runs it's recommended to add `--ask-become-pass` flag to the call, so Ansible can elevate privileges when needed (e.g. for `pacman`).

To get all the groups and leave out the single packages you can use the `install-common-groups` scriptlet.
In practice all devices will require different sets of applications to be installed, so this list should be customized.

## Things that require manual setup after installation

- `kanshi` for auto-switching displays

## Testing

Testing on host is likely the easiest approach, for end-to-end testing the `vagrant` role sets up a Vagrant VM in `~/archlinux_vm` which can be used with ansible with minimal effort.

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
"Boot with microcode updates" "initrd=\initramfs-%v.img cryptdevice=UUID=<LUKS PARTITION UUID>:archlvm root=/dev/ArchGroup/root resume=/dev/ArchGroup/swap
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
- (optionally) set up the decryption over SSH at boot time following the [wiki article](https://wiki.archlinux.org/title/Dm-crypt/Specialties).
  I am using the `mkinitcpio-tinyssh` based approach at this time:
  - Install `mkinitcpio-tinyssh mkinitcpio-netconf mkinitcpio-utils` packages
  - Follow the [Github issue](https://github.com/grazzolini/mkinitcpio-tinyssh/issues/10) and apply the patch from it locally
  - Copy your public key under `/etc/tinyssh/root_key`
  - Add the `netconf tinyssh encryptssh (replaces encrypt)` hooks before the `lvm2` and `filesystems` in `/etc/mkinitcpio.conf`
  - Regenerate the initramfs with `# mkinitcpio -P`. Take a good look at the `tinyssh` hook logs as the issue mentioned above will occur now and fail silently, if it's not patched
  - Add `ip=dhcp netconf_timeout=30` to kernel parameters in `/boot/refind_linux.conf`
  - Now you can ssh into the host at startup with `root` username and provide the encryption passphrase
