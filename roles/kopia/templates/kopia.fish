set -x KOPIA_USE_KEYRING {{ "true" if kopia_use_keyring else "false" }}
set -x KOPIA_CHECK_FOR_UPDATES false
