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

Note that scdaemon.conf and gpg-agent.conf are seeded from ~/.gnupg, as the temporary
keyring would otherwise run scdaemon with defaults and fail to reach the smartcard.

The master passphrase and the Admin PIN are answered by a scripted pinentry, generated
into the temporary keyring, so nothing has to be typed in by hand. It tells the two
secrets apart by the prompt text and refuses to answer a re-prompt, so a wrong Admin PIN
costs a single attempt instead of blocking the applet.

Env variables
GNUPGHOME_CURRENT        should point to the GNUPGP keyring directory
YUBIKEY_ADMIN_PIN        should contain Admin PIN to the Yubikey
MIN_ADMIN_PIN_RETRIES    refuse to start below that many Admin PIN attempts (default 10)
HEREDOC
}

function cleanup() {
    if [ -n "${GNUPGHOME}" ]; then
        # The agent of the temporary keyring would otherwise outlive it and keep
        # holding the reader, which wedges the card for the next run
        gpgconf --kill all || true
        echoerr "Cleaning up the temporary GPG keyring: ${GNUPGHOME}"
        rm -rf "${GNUPGHOME}"
    fi
}

function write_auto_pinentry() {
    local pinentry_path="${GNUPGHOME}/auto-pinentry"

    printf '%s' "${YUBIKEY_ADMIN_PIN}" > "${GNUPGHOME}/yubikey-admin-pin"
    chmod 0600 "${GNUPGHOME}/yubikey-admin-pin"

    cat > "${pinentry_path}" << HEREDOC
#!/usr/bin/env bash
SECRET_DIR="${GNUPGHOME}"
HEREDOC

    cat >> "${pinentry_path}" << 'HEREDOC'
# Assuan pinentry answering from the temporary keyring instead of prompting.
set -u

passphrase="$(cat "${SECRET_DIR}/master-passphrase")"
admin_pin="$(cat "${SECRET_DIR}/yubikey-admin-pin")"

function assuan_escape() {
    local escaped="${1//\%/%25}"
    escaped="${escaped//$'\r'/%0D}"
    printf '%s' "${escaped//$'\n'/%0A}"
}

wanted="passphrase"
refuse=""

printf 'OK Pleased to meet you\n'
while IFS= read -r line; do
    case "${line}" in
        SETDESC*|SETPROMPT*)
            case "${line}" in
                *"Admin PIN"*) wanted="admin" ;;
                # The user PIN is not ours to guess, so it must not be answered
                *PIN*) [ "${wanted}" = "admin" ] || wanted="pin" ;;
            esac
            printf 'OK\n'
            ;;
        SETERROR*)
            # A re-prompt means the previous answer was rejected; answering again
            # would spend the remaining attempts and block the applet
            refuse="yes"
            printf 'OK\n'
            ;;
        GETPIN*)
            if [ -n "${refuse}" ] || [ "${wanted}" = "pin" ]; then
                printf 'ERR 83886179 Operation cancelled\n'
            elif [ "${wanted}" = "admin" ]; then
                printf 'D %s\nOK\n' "$(assuan_escape "${admin_pin}")"
            else
                printf 'D %s\nOK\n' "$(assuan_escape "${passphrase}")"
            fi
            wanted="passphrase"
            ;;
        'GETINFO pid'*)
            printf 'D %s\nOK\n' "$$"
            ;;
        RESET*)
            wanted="passphrase"
            printf 'OK\n'
            ;;
        BYE*)
            printf 'OK closing connection\n'
            exit 0
            ;;
        *)
            printf 'OK\n'
            ;;
    esac
done
HEREDOC

    chmod 0700 "${pinentry_path}"

    # A copied pinentry-program would otherwise win over the generated one
    if [ -e "${GNUPGHOME}/gpg-agent.conf" ]; then
        grep -v '^[[:space:]]*pinentry-program' "${GNUPGHOME}/gpg-agent.conf" \
            > "${GNUPGHOME}/gpg-agent.conf.new" || true
        mv "${GNUPGHOME}/gpg-agent.conf.new" "${GNUPGHOME}/gpg-agent.conf"
    fi
    printf 'pinentry-program %s\n' "${pinentry_path}" >> "${GNUPGHOME}/gpg-agent.conf"
}

function subkey_fingerprint() {
    gpg --list-keys --with-colons | awk -F: -v capability="$1" '
        /^sub:/ { wanted = ($2 !~ /^[redi]$/) && index($12, capability) > 0 }
        /^fpr:/ && wanted { print $10; wanted = 0 }
    '
}

function subkey_keyid() {
    gpg --list-keys --with-colons | awk -F: -v capability="$1" '
        $1 == "sub" && $2 !~ /^[redi]$/ && index($12, capability) > 0 { print $5 }
    '
}

# Subkeys are addressed by key ID rather than by their position in the keyring: the
# order of "key N" is the creation order, which need not be signing/encryption/auth
function copy_subkey_to_card() {
    local capability="$1" slot="$2" description="$3"
    local key_ids key_count

    key_ids="$(subkey_keyid "${capability}")"
    key_count="$(printf '%s' "${key_ids}" | grep -c . || true)"

    if [ "${key_count}" -ne 1 ]; then
        echoerr "Expected exactly one usable ${description} subkey, found ${key_count}"
        return 1
    fi

    echoerr "Copying the ${description} key ${key_ids} to slot ${slot}"
    printf "key %s\nkeytocard\n%s\ny\n" "${key_ids}" "${slot}" \
        | gpg --command-fd 0 --status-fd 1 --edit-key "${MASTER_KEY_ID}"
}

# gpg exits 0 even when a keytocard is declined, so the card has to be read back
function verify_card_keys() {
    local slots=("Signature:s" "Encryption:e" "Authentication:a")
    local on_card slot_name capability expected actual failed=0

    on_card="$(gpg --card-status --with-colons | awk -F: '/^fpr:/ { print $2":"$3":"$4 }')"

    for index in 0 1 2; do
        slot_name="${slots[index]%%:*}"
        capability="${slots[index]##*:}"
        expected="$(subkey_fingerprint "${capability}")"
        actual="$(printf '%s' "${on_card}" | cut -d: -f$((index + 1)))"

        if [ -z "${expected}" ] || [ "${expected}" != "${actual}" ]; then
            echoerr "${slot_name} slot holds '${actual:-none}', expected '${expected:-unknown}'"
            failed=1
        fi
    done

    if [ "${failed}" -ne 0 ]; then
        echoerr "The card was not provisioned as expected"
        return 1
    fi

    echoerr "All three subkeys verified on the card"
}

function require_admin_pin_retries() {
    local admin_retries
    admin_retries="$(gpg --card-status --with-colons | awk -F: '/^pinretry:/ { print $4 }')"

    if [ -z "${admin_retries}" ]; then
        echoerr "Could not read the Admin PIN retry counter from the card"
        return 1
    fi

    if [ "${admin_retries}" -lt "${MIN_ADMIN_PIN_RETRIES}" ]; then
        echoerr "Admin PIN retry counter is ${admin_retries}, expected at least ${MIN_ADMIN_PIN_RETRIES}"
        echoerr "Verify the Admin PIN manually before risking the remaining attempts"
        return 1
    fi

    echoerr "Admin PIN retry counter: ${admin_retries}"
}

require_value GNUPGHOME_CURRENT
require_value YUBIKEY_ADMIN_PIN

MIN_ADMIN_PIN_RETRIES="${MIN_ADMIN_PIN_RETRIES:-10}"

# The scripted pinentry matches on the prompt text, which is only stable in English
export LC_ALL=C

# Create a temporary GNUPGHOME
GNUPGHOME="$(mktemp -d)"
cp -avi "${GNUPGHOME_CURRENT}/"* "${GNUPGHOME}"
export GNUPGHOME

trap cleanup EXIT

# The smartcard/agent config lives in the user's real keyring, not in GNUPGHOME_CURRENT.
# Without it scdaemon falls back to the built-in CCID driver (no PC/SC fallback since
# GnuPG 2.4) and cannot claim a reader already held by pcscd.
for config_file in scdaemon.conf gpg-agent.conf; do
    if [ ! -e "${GNUPGHOME}/${config_file}" ] && [ -e "${HOME}/.gnupg/${config_file}" ]; then
        cp -av "${HOME}/.gnupg/${config_file}" "${GNUPGHOME}/"
    fi
done

write_auto_pinentry

# Read entries from the keyring
MASTER_KEY_ID="$(gpg --list-keys --with-fingerprint --with-colons | grep pub | cut -d ":" -f 5)"

gpg --card-status

require_admin_pin_retries

gpg-connect-agent 'help' /bye
gpg-connect-agent 'SCD HELP' /bye

copy_subkey_to_card s 1 signing
copy_subkey_to_card e 2 encryption
copy_subkey_to_card a 3 authentication

verify_card_keys

[[ ! "$MASTER_KEY_ID" =~ ^"0x" ]] && MASTER_KEY_ID="0x${MASTER_KEY_ID}"
KEY_URL="hkps://keyserver.ubuntu.com:443/pks/lookup?op=get&search=${MASTER_KEY_ID}"

echoerr "Adding the URL to public key"
printf "admin\nurl\n%s\nquit\n" "${KEY_URL}" | gpg --command-fd 0 --status-fd 1 --pinentry-mode loopback --passphrase "${YUBIKEY_ADMIN_PIN}" --edit-card

gpg --card-status
gpg -K
