#!/usr/bin/env bash

set -euo pipefail

SCRIPTS_DIR="$(readlink -f "$(dirname "$0")")"

# shellcheck source=roles/gpg/files/scripts/lib.sh
. "$SCRIPTS_DIR/lib.sh"

function usage_doc() {
    cat << 'HEREDOC'
This script will set sane defaults and configure the Yubikey to safely store GPG keys

It takes care of:
- setting the number of retries to 10 for all the actions (pin, admin pin, reset pin)
- enabling the KDF to store the hash of a pin
- changing the GPG PIN
- changing the GPG Admin PIN
- setting the owner's name
- setting the language preference
- setting the owner's email (Login data field)

Please note that reset PIN is not set by default

Env variables
USER_FAMILY_NAME            what family name should be saved to the key
USER_GIVEN_NAME             what given name should be saved to the key
USER_EMAIL                  what email should be saved to the key
TARGET_YUBIKEY_PIN          what pin should be set
TARGET_YUBIKEY_ADMIN_PIN    what admin pin should be set

Optional env variables
CURRENT_YUBIKEY_PIN         needed if the key is being reconfigured (has a different PIN than factory default)
CURRENT_YUBIKEY_ADMIN_PIN   same as above, but for admin pin
HEREDOC
}

require_value USER_FAMILY_NAME
require_value USER_GIVEN_NAME
require_value USER_EMAIL
require_value TARGET_YUBIKEY_PIN
require_value TARGET_YUBIKEY_ADMIN_PIN

# Use the default PINs for initial setups (if different ones are not provided explicitly)
CURRENT_YUBIKEY_PIN="${CURRENT_YUBIKEY_PIN:-123456}"
CURRENT_YUBIKEY_ADMIN_PIN="${CURRENT_YUBIKEY_ADMIN_PIN:-12345678}"

echoerr "Move the built-in OTP to second slot (long-press), if feasible"
if OTP_SLOT=$(ykman otp info | grep "empty"); then
    OTP_SLOT="$(echo "${OTP_SLOT}" | cut -d ":" -f1)"
    if [[ "${OTP_SLOT}" != "Slot 1" ]]; then
        echoerr "Empty slot 2 detected for OTP"
        echoerr "Moving slot 1 to slot 2 (long press)"
        ykman otp swap -f
    fi
fi

echoerr "Setting up the user info"
printf "admin\nname\n%s\n%s\n" "${USER_FAMILY_NAME}" "${USER_GIVEN_NAME}" | gpg --command-fd 0 --status-fd 1 --pinentry-mode loopback --passphrase "${CURRENT_YUBIKEY_ADMIN_PIN}" --card-edit
printf "admin\nlang\nen\n" | gpg --command-fd 0 --status-fd 1 --pinentry-mode loopback --passphrase "${CURRENT_YUBIKEY_ADMIN_PIN}" --card-edit
printf "admin\nlogin\n%s\n" "${USER_EMAIL}" | gpg --command-fd 0 --status-fd 1 --pinentry-mode loopback --passphrase "${CURRENT_YUBIKEY_ADMIN_PIN}" --card-edit

echoerr "Enabling the KDF"
printf "admin\nkdf-setup\n" | gpg --command-fd 0 --status-fd 1 --pinentry-mode loopback --passphrase "${CURRENT_YUBIKEY_ADMIN_PIN}" --card-edit

echoerr "Changing the user PIN"
ykman -l DEBUG openpgp access change-pin --pin "${CURRENT_YUBIKEY_PIN}" --new-pin "${TARGET_YUBIKEY_PIN}"
# If if were to be used later in the script
CURRENT_YUBIKEY_PIN="${TARGET_YUBIKEY_PIN}"

echoerr "Changing the admin PIN"
ykman -l DEBUG openpgp access change-admin-pin --admin-pin "${CURRENT_YUBIKEY_ADMIN_PIN}" --new-admin-pin "${TARGET_YUBIKEY_ADMIN_PIN}"
# If if were to be used later in the script
CURRENT_YUBIKEY_ADMIN_PIN="${TARGET_YUBIKEY_ADMIN_PIN}"

echoerr "Setting the number of retries"
ykman openpgp access set-retries 10 10 10 -f -a "${CURRENT_YUBIKEY_ADMIN_PIN}"

# Switching between gpg and ykman works kinda messy for me, allow the operation to fail once, so it switches into the correct GPG mode
printf "quit\n" | gpg --command-fd 0 --status-fd 1 --pinentry-mode loopback --passphrase "${CURRENT_YUBIKEY_ADMIN_PIN}" --card-edit || true

echoerr "Listing the final GPG card configuration"
printf "list\n" | gpg --command-fd 0 --status-fd 1 --pinentry-mode loopback --passphrase "${CURRENT_YUBIKEY_ADMIN_PIN}" --card-edit
