source ~/.config/fish/plugins.fish

if status is-interactive
    fish_vi_key_bindings
    fzf_key_bindings
end

# THEME
set theme_show_exit_status yes
set theme_color_scheme zenburn

# ALIASES
alias ls="ls --color=auto --group-directories-first"
alias grep="grep --color=auto"
alias emac="emacsclient -nw"
alias e="emacsclient -nw"
alias v="nvim"

function tmp
    cd (mktemp -d)
end

# PATHS
set -x PATH $HOME/.local/bin $PATH
set -x PATH $HOME/bin $PATH
set -x PATH $HOME/scripts $PATH
set -x PATH $HOME/.local/bin $PATH

# MISC
set -x EDITOR nvim
set -x SUDO_EDITOR rvim

# BLOCKS (functions that can be used in other functions)
source ~/.config/fish/blocks.fish

# Source all the scriptlets that could have been installed by other roles
for scriptlet_file in ~/.config/fish/ansible/**/*.fish
    source $scriptlet_file
end

# Allow node specific customizations.
if test -e ~/.config/fish/custom.fish
    source ~/.config/fish/custom.fish
end
