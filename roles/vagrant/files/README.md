# arch_vm

The idea of this setup is to end-to-end test the Ansible setup described in
[arch_ansible](https://github.com/dezeroku/arch_ansible) repository.

It's not really recommended or needed to run this after every change, but it
can be quite useful to test potentially breaking changes (e.g. switching the
base shell or editor settings) in a fresh env.

With the `pacoloco` role being used properly the Arch mirrors aren't really affected,
there's still traffic going out to github and related services.

## Basic usage

The core loop that you'd want to go through is:
```
vagrant up
vagrant destroy
```

Optionally `vagrant provision` can be used to just call the provisioning without
refreshing the machine.

It's worth noting that while this setup can be used for development (e.g. `vagrant ssh`
directly into the VM and test whatever you want there), but still testing on the live
system is preferred.
