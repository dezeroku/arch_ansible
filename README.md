## Ansible version of i3\_config

Heavily inspired by [spark](https://github.com/pigmonkey/spark) .

Individual tags for each role.

## Assumptions

You already have Archlinux base & base-devel installed, and you only want to set up system for daily-usage.


All roles prefixed with 'aur' depend on aur_builder user with sudo rights (aur_builder role).

## Base 'profiles'

| Name | Resolution |
| ---- | ---------- |
| x200 | 1280x800   |
| x230 | 1366x768   |
| g751 | 1920x1080  |

## Basic command
Run all roles for g751 pc on localhost.
```
ansible-playbook all.yml -i inventory -e pc=g751
```

### TODO

1. Better handling of dependencies.
2. README for specific roles
3. Fix some roles which deadlock (e.g. vim related)


### Credits

Take a look at [dotfiles repo](https://github.com/tojatos/dotfiles) from @tojatos (especially ZSH theme).
