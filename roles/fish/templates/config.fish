# Set up plugins
source ~/.config/fish/plugins.fish

fish_vi_key_bindings
fzf_key_bindings

#set -g theme_color_scheme terminal

# THEME
set theme_show_exit_status yes
set theme_color_scheme zenburn

# GPG
set GPG_TTY (tty)

# ALIASES
alias ls="ls --color=auto --group-directories-first"
alias grep="grep --color=auto"
alias emac="emacsclient -nw"
alias e="emacsclient -nw"
alias v="nvim"

function jira
    # Obtain the "real binary" path to avoid infinite loop
    set -l jira_bin
    set jira_bin (which jira)

    "$HOME/.jira.d/get-jira-cookies-from-qutebrowser.sh" && "$jira_bin" $argv
end

# PATHS
#set -x PATH $HOME/opt/GNAT/2020/bin $PATH
set -x PATH $HOME/go/bin $PATH
set -x PATH $HOME/.local/bin $PATH
set -x PATH $HOME/npm_global/bin $PATH
set -x PATH $HOME/bin $PATH
set -x PATH $HOME/scripts $PATH
set -x PATH $HOME/.local/bin $PATH

# MISC
set -x EDITOR nvim
set -x SUDO_EDITOR rvim

# UTILS
function tmp
    cd (mktemp -d)
end

# BLOCKS (functions that can be used in other functions)
source ~/.config/fish/blocks.fish

# AWS
source ~/.config/fish/aws.fish

# Kubernetes and friends
source ~/.config/fish/kubernetes.fish

# Allow node specific customizations.
if test -e ~/.config/fish/custom.fish
    source ~/.config/fish/custom.fish
end
