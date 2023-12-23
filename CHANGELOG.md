# Changelog

Due to the nature of this project, proper releases don't really make sense.
Rolling release of Arch justifies just running the `master` version of the repo at all times.
The only breaking changes that can happen in the repo that can be remedied are:

1. renamed variables in `base.yml` and `custom.yml`

## G751 scripts deprecation

Obsoleted variables:

1. `i3_setup_g751_scripts`
2. `i3_nopasswd_g751_scripts`
3. `i3_nvidia_optimus_direct_rendering`

Changed variables: N/A

New variables: N/A

## Xorg to Wayland (Sway) migration

Obsoleted variables: N/A

Changed variables:

1. `i3_disable_touchpad` -> renamed to `sway_disable_touchpad`
2. `i3_autostart_yubikey_otp` -> renamed to `yubikey_sway_autostart_otp`
3. `i3_dpi` -> equivalent to `sway_output_scale`, requires alignment

New variables:

1. `helper_sway_plugin_enabled`
2. `bluetooth_install_gui`
3. `networkmanager_install_gui`
