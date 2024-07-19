#!/usr/bin/env bash

set -euo pipefail

SCRIPTS_DIR="$(readlink -f "$(dirname "$0")")"

# shellcheck source=roles/gpg/files/scripts/lib.sh
. "$SCRIPTS_DIR/lib.sh"

function usage_doc() {
    cat << 'HEREDOC'
This script will move subkeys from the keyring to a connect Yubikey

It does so in a non-destructive way (copying the keyring to a tmp location
that's cleaned at the end of execution), so it's easier to set up multiple smartcards.
Remember that it means that the GNUPGHOME_CURRENT will still contain private keys, after
the operation is done, contrary to just using the `keytocard` gpg command directly

TODO: it still works messy with the gpg-agent, sometimes it doesn't want to connect
I don't really want to investigate it further at this point
As a workaround, usually killing all gpg-agent instances and waiting few minutes helps
Also the automation for pinentry would be nice, but it doesn't seem to work at the moment

Env variables
GNUPGHOME_CURRENT   should point to the GNUPGP keyring directory
YUBIKEY_ADMIN_PIN   should contain Admin PIN to the Yubikey
HEREDOC
}

function cleanup() {
    if [ -n "${GNUPGHOME}" ]; then
        echoerr "Cleaning up the temporary GPG keyring: ${GNUPGHOME}"
        rm -rf "${GNUPGHOME}"
    fi
}

require_value GNUPGHOME_CURRENT
require_value YUBIKEY_ADMIN_PIN

# Create a temporary GNUPGHOME
GNUPGHOME="$(mktemp -d)"
cp -avi "${GNUPGHOME_CURRENT}/"* "${GNUPGHOME}"
export GNUPGHOME

trap cleanup EXIT

# Read entries from the keyring
MASTER_PASSPHRASE="$(cat "${GNUPGHOME}/master-passphrase")"
MASTER_KEY_ID="$(gpg --list-keys --with-fingerprint --with-colons | grep pub | cut -d ":" -f 5)"

#gpgconf --kill gpg-agent
gpg --card-status

#gpg-connect-agent 'help' /bye
#gpg-connect-agent 'SCD HELP' /bye

# TODO: pass it via the CLI, as it should be done
echoerr "Provide the following master passphrase:"
echoerr "${MASTER_PASSPHRASE}"
echoerr "Provide the following yubikey admin pin:"
echoerr "${YUBIKEY_ADMIN_PIN}"

echoerr "Copying the signing key"
printf "key 1\nkeytocard\n1\n%s\n%s\n%s\n" "${MASTER_PASSPHRASE}" "${YUBIKEY_ADMIN_PIN}" "${YUBIKEY_ADMIN_PIN}" | gpg --command-fd 0 --status-fd 1 --passphrase "${MASTER_PASSPHRASE}" --edit-key "${MASTER_KEY_ID}"

echoerr "Copying the encryption key"
printf "key 2\nkeytocard\n2\n%s\n%s\n%s\n" "${MASTER_PASSPHRASE}" "${YUBIKEY_ADMIN_PIN}" "${YUBIKEY_ADMIN_PIN}" | gpg --command-fd 0 --status-fd 1 --passphrase "${MASTER_PASSPHRASE}" --edit-key "${MASTER_KEY_ID}"

echoerr "Copying the authentication key"
printf "key 3\nkeytocard\n3\n%s\n%s\n%s\n" "${MASTER_PASSPHRASE}" "${YUBIKEY_ADMIN_PIN}" "${YUBIKEY_ADMIN_PIN}" | gpg --command-fd 0 --status-fd 1 --passphrase "${MASTER_PASSPHRASE}" --edit-key "${MASTER_KEY_ID}"

[[ ! "$MASTER_KEY_ID" =~ ^"0x" ]] && MASTER_KEY_ID="0x${MASTER_KEY_ID}"
KEY_URL="hkps://keyserver.ubuntu.com:443/pks/lookup?op=get&search=${MASTER_KEY_ID}"

echoerr "Adding the URL to public key"
printf "admin\nurl\n%s\nquit\n" "${KEY_URL}" | gpg --command-fd 0 --status-fd 1 --pinentry-mode loopback --passphrase "${YUBIKEY_ADMIN_PIN}" --edit-card

gpg --card-status
gpg -K
