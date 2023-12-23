# This is fishy (sigh)
# It'll also set the value on TTY level
status is-login; and export XDG_CURRENT_DESKTOP=sway
alias sway="sway > {{ sway_log_file }} 2>&1"
