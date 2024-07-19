#!/usr/bin/env bash

set -euo pipefail

SCRIPTS_DIR="$(readlink -f "$(dirname "$0")")"

# shellcheck source=roles/gpg/files/scripts/lib.sh
. "$SCRIPTS_DIR/lib.sh"

function usage_doc() {
    cat << 'HEREDOC'
This script will set validity of each subkey in the ring to 1y (starting from now)

Remember that you'll have to reimport the exported key into your keyrings

Env variables
GNUPGHOME_CURRENT   should point to the GNUPGP keyring directory

Optional env variables
SEND_KEYS           if set to 'true' will upload the pubkey to a keyserver
HEREDOC
}

require_value GNUPGHOME_CURRENT

export GNUPGHOME="$GNUPGHOME_CURRENT"
SEND_KEYS="${SEND_KEYS:-false}"

# Read entries from the keyring
MASTER_PASSPHRASE="$(cat "${GNUPGHOME}/master-passphrase")"
MASTER_KEY_ID="$(gpg --list-keys --with-fingerprint --with-colons | grep pub | cut -d ":" -f 5)"

for key in {1,2,3}; do
    echoerr "Extending validity, key $key"
    printf "key %s\nexpire\n1y\ny\nsave\n" "$key" | gpg --command-fd 0 --status-fd 1 --pinentry-mode loopback --passphrase "${MASTER_PASSPHRASE}" --edit-key "${MASTER_KEY_ID}"
done;

gpg -K

export_public_key

if [[ "$SEND_KEYS" == "true" ]]; then
    gpg --send-keys "${MASTER_KEY_ID}"
fi
