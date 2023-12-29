# Changelog

Due to the nature of this project, proper releases don't really make sense.
Rolling release of Arch justifies just running the `master` version of the repo at all times.
The only breaking changes that can happen in the repo that can be remedied are:

1. renamed variables in `base.yml` and `custom.yml`

## Proper prefixes for role-specific variables

Obsoleted variables:

1. `user_pub_name` -> `user_name` covers all use-cases anyway

Changed variables:

1. `user_gpg_key` -> `gpg_user_key`
2. `user_always_git_gpg` -> `gpg_sign_git_commits`
3. `work_jira_user` -> `jira_user`
4. `work_jira_endpoint` -> `jira_endpoint`
5. `time_hwclock` -> `ntp_hwclock`
6. `time_timezone` -> `ntp_timezone`
7. `user_generate_ssh_key` -> `create_user_generate_ssh_key`
8. `user_ssh_key_type` -> `create_user_ssh_key_type`

## G751 scripts deprecation

Obsoleted variables:

1. `i3_setup_g751_scripts`
2. `i3_nopasswd_g751_scripts`
3. `i3_nvidia_optimus_direct_rendering`

## Xorg to Wayland (Sway) migration

Changed variables:

1. `i3_disable_touchpad` -> renamed to `sway_disable_touchpad`
2. `i3_autostart_yubikey_otp` -> renamed to `yubikey_sway_autostart_otp`
3. `i3_dpi` -> equivalent to `sway_output_scale`, requires alignment

New variables:

1. `helper_sway_plugin_enabled`
2. `bluetooth_install_gui`
3. `networkmanager_install_gui`
