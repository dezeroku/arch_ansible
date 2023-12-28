# Set up plugins
source ~/.config/fish/plugins.fish

if status is-interactive
    fish_vi_key_bindings
    fzf_key_bindings
end

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
# Special treatment for it, source it explicitly as it may be reused in
# scriptlets from other roles
source ~/.config/fish/ansible/fish/blocks.fish

# Source all the scriptlets that could have been installed by other roles
for scriptlet_file in ~/.config/fish/ansible/**/*.fish
    source $scriptlet_file
end

# Allow node specific customizations.
if test -e ~/.config/fish/custom.fish
    source ~/.config/fish/custom.fish
end
