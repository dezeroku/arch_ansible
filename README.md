## Ansible version of i3\_config

Heavily inspired by (spark)[https://github.com/pigmonkey/spark] .

## Assumptions

You already have Archlinux base & base-devel installed, and you only want to set up system.


All roles prefixed with 'aur' depend on aur_builder user with sudo rights (aur_builder role).
## Basic command
e.g
```
ansible-playbook all.yml -i inventory -e pc:g751 --tags configure
```
