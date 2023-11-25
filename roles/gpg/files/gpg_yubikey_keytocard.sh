#!/usr/bin/env bash

# This is not executable by default
# as it's not a common ocurrence setup and running with sh requires more attendance
#
# The setup is based on https://github.com/drduh/YubiKey-Guide
# Its role is to set up the keys stored in GNUPGHOME on a connected Yubikey
# It does so in a non-destructive way (copying the GNUPGHOME to a tmp location
# that's cleaned at the end of execution), so it's easier to set up multiple keys.
# Remember that it means that the GNUPGHOME will still contain private keys, after
# the operation is done, contrary to just using the `keytocard` gpg command directly
#
# It's assumed that the keyring was created with `gpg_setup_keyring.sh` script and contains
# only a single master key, with 3 subkeys, each for a different procedure.
# Remember to upload the key to a keyserver, if that's what you want
#
# TODO: it still works messy with the gpg-agent, sometimes it doesn't want to connect
# I don't really want to investigate it further at this point
# As a workaround, usually killing all gpg-agent instances and waiting few minutes helps
# Also the automation for pinentry would be nice, but it doesn't seem to work at the moment

set -euo pipefail

function require_value() {
    var_name="${1:-}"
    if [ -z "${!var_name:-}" ]; then
        echo "${var_name} variable must be defined"
        return 1
    fi
}

function cleanup() {
    if [ -n "${GNUPGHOME}" ]; then
        echo "Cleaning up the temporary GPG keyring: ${GNUPGHOME}"
        rm -rf "${GNUPGHOME}"
    fi
}

require_value GNUPGHOME_ORIGINAL
require_value YUBIKEY_ADMIN_PIN

# Create a temporary GNUPGHOME
GNUPGHOME="$(mktemp -d)"
cp -avi "${GNUPGHOME_ORIGINAL}/"* "${GNUPGHOME}"
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
echo "Provide the following master passphrase:"
echo "${MASTER_PASSPHRASE}"
echo "Provide the following yubikey admin pin:"
echo "${YUBIKEY_ADMIN_PIN}"

echo "Copying the signing key"
printf "key 1\nkeytocard\n1\n%s\n%s\n%s\n" "${MASTER_PASSPHRASE}" "${YUBIKEY_ADMIN_PIN}" "${YUBIKEY_ADMIN_PIN}" | gpg --command-fd 0 --status-fd 1 --passphrase "${MASTER_PASSPHRASE}" --edit-key "${MASTER_KEY_ID}"

echo "Copying the encryption key"
printf "key 2\nkeytocard\n2\n%s\n%s\n%s\n" "${MASTER_PASSPHRASE}" "${YUBIKEY_ADMIN_PIN}" "${YUBIKEY_ADMIN_PIN}" | gpg --command-fd 0 --status-fd 1 --passphrase "${MASTER_PASSPHRASE}" --edit-key "${MASTER_KEY_ID}"

echo "Copying the authentication key"
printf "key 3\nkeytocard\n3\n%s\n%s\n%s\n" "${MASTER_PASSPHRASE}" "${YUBIKEY_ADMIN_PIN}" "${YUBIKEY_ADMIN_PIN}" | gpg --command-fd 0 --status-fd 1 --passphrase "${MASTER_PASSPHRASE}" --edit-key "${MASTER_KEY_ID}"

[[ ! "$MASTER_KEY_ID" =~ ^"0x" ]] && MASTER_KEY_ID="0x${MASTER_KEY_ID}"
KEY_URL="hkps://keyserver.ubuntu.com:443/pks/lookup?op=get&search=${MASTER_KEY_ID}"

echo "Adding the URL to public key"
printf "admin\nurl\n%s\nquit\n" "${KEY_URL}" | gpg --command-fd 0 --status-fd 1 --pinentry-mode loopback --passphrase "${YUBIKEY_ADMIN_PIN}" --edit-card

gpg --card-status
gpg -K
