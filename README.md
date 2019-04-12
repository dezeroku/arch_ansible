## Ansible version of i3\_config

## Assumptions

You already have Archlinux base & base-devel & rsync installed, and you only want to set up system.

## Basic command
e.g
```
ansible-playbook all.yml -i inventory -e pc:g751 --tags configure
```
