if status is-interactive
    set -x GPG_TTY (tty)
    set -x SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
    gpgconf --launch gpg-agent
    echo "UPDATESTARTUPTTY" | gpg-connect-agent > /dev/null
end
