alias k="kubectl"

alias tf="terraform"

# Plugins for kubectl
set -gx PATH $PATH $HOME/.krew/bin

# Enable completion for k9s
# k9s completion fish | source

# Enable completion for kubectl
kubectl completion fish | source
