## Ansible version of i3\_config

Heavily inspired by (spark)[https://github.com/pigmonkey/spark] .

Individual tags for each role.

## Assumptions

You already have Archlinux base & base-devel installed, and you only want to set up system.


All roles prefixed with 'aur' depend on aur_builder user with sudo rights (aur_builder role).

## Base 'profiles'

| Name | Resolution |
| ---- | ---------- |
| x230 | 1366x768   |
| g751 | 1920x1080  |

## Basic command
Run all roles for g751 pc on localhost.
```
ansible-playbook all.yml -i inventory -e pc=g751
```

### TODO
Dependencies should be solved more explicitly.
