# PLUGINS
fundle plugin 'edc/bass'
fundle plugin 'danhper/fish-fastdir'
#fundle plugin 'danhper/fish-ssh-agent'
#Currently setting up ssh-agent is done with keychain in custom on each node.
fundle plugin 'oh-my-fish/theme-bobthefish'
fundle plugin 'evanlucas/fish-kubectl-completions'
fundle plugin 'decors/fish-colors'

fundle init


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
alias v="vim"

# PATHS
set -x PATH /opt/GNAT/2019/bin $PATH
set -x PATH /opt/GNAT/2019-arm-elf/bin $PATH
set -x PATH $HOME/go/bin $PATH
set -x PATH $HOME/.local/bin $PATH
set -x PATH $HOME/npm_global/bin $PATH
set -x PATH $HOME/bin $PATH
set -x PATH $HOME/.local/bin $PATH

# MISC
set -x EDITOR vim

# Allow node specific customizations.
if test -e ~/.config/fish/custom.fish
    source ~/.config/fish/custom.fish
end
