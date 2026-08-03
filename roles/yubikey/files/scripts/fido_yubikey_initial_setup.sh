#!/usr/bin/env bash

set -euo pipefail

SCRIPTS_DIR="$(readlink -f "$(dirname "$0")")"

# shellcheck source=roles/gpg/files/scripts/lib.sh
. "$SCRIPTS_DIR/lib.sh"

function usage_doc() {
    cat << 'HEREDOC'
This script will set sane defaults and configure the Yubikey to safely store FIDO key

It takes care of:
- setting the PIN
- storing a secure key onto the Yubi

Env variables
TARGET_YUBIKEY_PIN          what pin should be set

Optional env variables
CURRENT_YUBIKEY_PIN         needed if the key is being reconfigured (has a different PIN than factory default)
HEREDOC
}

mapfile -t ykman_serials < <(ykman list --serials)

if [[ "${#ykman_serials[@]}" != "1" ]]; then
    echoerr "This script assumes that exactly one Yubikey is connected during the provisioning"
    echoerr "Detected values are: ${ykman_serials[*]}"
    exit 1
fi

yubi_serial="${ykman_serials[*]}"

echoerr "Proceeding with Yubi: ${yubi_serial}"

require_value TARGET_YUBIKEY_PIN

if ! ykman fido info | grep -q "PIN:.* Not set"; then
    echoerr "FIDO PIN is already set, proceeding with CURRENT_YUBIKEY_PIN"
    require_value CURRENT_YUBIKEY_PIN
fi

suffix=()
if [ -n "${CURRENT_YUBIKEY_PIN:-}" ]; then
    suffix=(--pin "${CURRENT_YUBIKEY_PIN}")
fi

ykman fido access change-pin --new-pin "${TARGET_YUBIKEY_PIN}" "${suffix[@]}"

#key_id="dezeroku-${yubi_serial}"
key_id="dezeroku"

if ! ykman fido credentials list --pin "${TARGET_YUBIKEY_PIN}" | grep -q "ssh:${key_id}"; then
    echoerr "SSH key not present, provisioning"
    ssh-keygen -t ed25519-sk -O resident -O "application=ssh:${key_id}" -N "" -f "${HOME}/.ssh/id_ed25519_sk_${key_id}"
else
    echoerr "SSH key already present, skipping provisioning"
    echoerr "Use \`ssh-keygen -K\` to recover the stub directly from the Yubikey"
fi
