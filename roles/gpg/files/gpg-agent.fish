if status is-interactive
    set -x GPG_TTY (tty)
    set -e SSH_AGENT_PID
    set -x SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
    gpg-connect-agent updatestartuptty /bye >/dev/null

    if [ -n "$DISPLAY" ]
        set -x PINENTRY_USER_DATA "USE_GTK2"
    end

    # Force the SSH_CLIENT to always use TTY,
    # even if X is forwarded
    if [ -n "$SSH_CLIENT" ]
        set -x PINENTRY_USER_DATA "USE_TTY"
    end

    function tmux_name --on-event fish_preexec
        gpg-connect-agent updatestartuptty /bye >/dev/null
    end
end
