# Initialize, so the `pyenv shell` commands works correctly
status is-login; and pyenv init --path | source
status is-interactive; and pyenv init - | source
