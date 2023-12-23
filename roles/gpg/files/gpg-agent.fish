if status is-interactive
    set -x GPG_TTY (tty)
    set -e SSH_AGENT_PID
    set -x SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
    gpg-connect-agent updatestartuptty /bye >/dev/null

    function gpg_agent_prepare --on-event fish_preexec
        gpg-connect-agent updatestartuptty /bye >/dev/null

        set -gx PINENTRY_USER_DATA "USE_TTY"

        if [ -n "$TMUX" ]
            # Refresh the variables
            # TODO: This will still leave the tmux in a "fighting state"
            # between variables from SSH and local.
            # The rule of thumb here is that the one connected later takes the lead
            # So in case of issue, reattaching to the session is recommended
            bass (tmux showenv -s)
        end

        if [ -n "$DISPLAY" ]
            set -gx PINENTRY_USER_DATA "USE_GTK2"
        end

        if [ -n "$WAYLAND_DISPLAY" ]
            set -gx PINENTRY_USER_DATA "USE_QT"
        end

        # Force the SSH_CLIENT to always use TTY,
        # even if X is forwarded
        if [ -n "$SSH_CLIENT" ]
            set -gx PINENTRY_USER_DATA "USE_TTY"
        end
    end
end
