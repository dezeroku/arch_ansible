#!/usr/bin/env bash

# GNUPGHOME_CURRENT=<path to GNUPGP keyring directory> sh gpg_extend_subkeys.sh
#
# This script will set validity of each subkey in the ring to 1y (starting from now)
#
# It's not executable (+x) by default,
# as it's not a common ocurrence setup and running with sh requires more attendance
#
# The setup is based on https://github.com/drduh/YubiKey-Guide
# Its role is to extend the validity of subkeys stored in GNUPGHOME by a year
#
# It's assumed that the keyring was created with `gpg_setup_keyring.sh` script and contains
# only a single master key, with 3 subkeys, each for a different procedure.
#
# Running this script will usually be followed by a call to gpg_yubikey_keytocard.sh
# to update the keys stored on a smartcard.

set -euo pipefail

function require_value() {
    var_name="${1:-}"
    if [ -z "${!var_name:-}" ]; then
        echo "${var_name} variable must be defined"
        return 1
    fi
}

require_value GNUPGHOME_CURRENT

export GNUPGHOME="$GNUPGHOME_CURRENT"

# Read entries from the keyring
MASTER_PASSPHRASE="$(cat "${GNUPGHOME}/master-passphrase")"
MASTER_KEY_ID="$(gpg --list-keys --with-fingerprint --with-colons | grep pub | cut -d ":" -f 5)"

for key in {1,2,3}; do
    echo "Extending validity, key $key"
    printf "key %s\nexpire\n1y\ny\nsave\n" "$key" | gpg --command-fd 0 --status-fd 1 --pinentry-mode loopback --passphrase "${MASTER_PASSPHRASE}" --edit-key "${MASTER_KEY_ID}"
done;

gpg -K
