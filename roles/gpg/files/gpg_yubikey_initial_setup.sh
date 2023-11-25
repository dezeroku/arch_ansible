#!/usr/bin/env bash

# This is not executable by default
# as it's not a common ocurrence setup and running with sh requires more attendance
#
# The setup is based on https://github.com/drduh/YubiKey-Guide
#
# It takes care of:
# - setting the number of retries to 10 for all the actions (pin, admin pin, reset pin)
# - enabling the KDF to store the hash of a pin
# - changing the GPG PIN
# - changing the GPG Admin PIN
# - setting the owner's name
# - setting the language preference
# - setting the owner's email (Login data field)
#
# Please note that reset PIN is not set by default
#

set -euo pipefail

function require_value() {
    var_name="${1:-}"
    if [ -z "${!var_name:-}" ]; then
        echo "${var_name} variable must be defined"
        return 1
    fi
}

require_value USER_FAMILY_NAME
require_value USER_GIVEN_NAME
require_value USER_EMAIL
require_value TARGET_YUBIKEY_PIN
require_value TARGET_YUBIKEY_ADMIN_PIN

# Use the default PINs for initial setups (if different ones are not provided explicitly)
CURRENT_YUBIKEY_PIN="${CURRENT_YUBIKEY_PIN:-123456}"
CURRENT_YUBIKEY_ADMIN_PIN="${CURRENT_YUBIKEY_ADMIN_PIN:-12345678}"

echo "Setting up the user info"
printf "admin\nname\n%s\n%s\n" "${USER_FAMILY_NAME}" "${USER_GIVEN_NAME}" | gpg --command-fd 0 --status-fd 1 --pinentry-mode loopback --passphrase "${CURRENT_YUBIKEY_ADMIN_PIN}" --card-edit
printf "admin\nlang\nen\n" | gpg --command-fd 0 --status-fd 1 --pinentry-mode loopback --passphrase "${CURRENT_YUBIKEY_ADMIN_PIN}" --card-edit
printf "admin\nlogin\n%s\n" "${USER_EMAIL}" | gpg --command-fd 0 --status-fd 1 --pinentry-mode loopback --passphrase "${CURRENT_YUBIKEY_ADMIN_PIN}" --card-edit

echo "Enabling the KDF"
printf "admin\nkdf-setup\n" | gpg --command-fd 0 --status-fd 1 --pinentry-mode loopback --passphrase "${CURRENT_YUBIKEY_ADMIN_PIN}" --card-edit

echo "Changing the user PIN"
ykman -l DEBUG openpgp access change-pin --pin "${CURRENT_YUBIKEY_PIN}" --new-pin "${TARGET_YUBIKEY_PIN}"
# If if were to be used later in the script
CURRENT_YUBIKEY_PIN="${TARGET_YUBIKEY_PIN}"

echo "Changing the admin PIN"
ykman -l DEBUG openpgp access change-admin-pin --admin-pin "${CURRENT_YUBIKEY_ADMIN_PIN}" --new-admin-pin "${TARGET_YUBIKEY_ADMIN_PIN}"
# If if were to be used later in the script
CURRENT_YUBIKEY_ADMIN_PIN="${TARGET_YUBIKEY_ADMIN_PIN}"

echo "Setting the number of retries"
ykman openpgp access set-retries 10 10 10 -f -a "${CURRENT_YUBIKEY_ADMIN_PIN}"


# Switching between gpg and ykman works kinda messy for me, allow the operation to fail once, so it switches into the correct GPG mode
printf "quit\n" | gpg --command-fd 0 --status-fd 1 --pinentry-mode loopback --passphrase "${CURRENT_YUBIKEY_ADMIN_PIN}" --card-edit || true

echo "Listing the final GPG card configuration"
printf "list\n" | gpg --command-fd 0 --status-fd 1 --pinentry-mode loopback --passphrase "${CURRENT_YUBIKEY_ADMIN_PIN}" --card-edit
