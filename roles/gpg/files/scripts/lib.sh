#!/usr/bin/env bash

# This file contains common functions to be used throughout the GPG framework

function usage() {
    echo "$0"
    echo
    [[ $(type -t usage_doc) == function ]] && usage_doc || echo "No script specific docs present"
    echo
    cat << 'HEREDOC'
The setup is based on https://github.com/drduh/YubiKey-Guide
Its role is to extend the validity of subkeys stored in GNUPGHOME by a year

It's assumed that the keyring was created with `gpg_setup_keyring.sh` script and contains
only a single master key, with 3 subkeys, each for a different procedure.
HEREDOC
}

function echoerr() {
	echo "$@" 1>&2
}

function require_value() {
    var_name="${1:-}"
    if [ -z "${!var_name:-}" ]; then
        echo "${var_name} variable must be defined"
        echo ""
        usage
        return 1
    fi
}

function export_public_key() {
    PUBLIC_KEY_FILE="${HOME}/gpg-${MASTER_KEY_ID}-$(date +%F).asc"

    gpg --armor --export "${MASTER_KEY_ID}" | tee "${PUBLIC_KEY_FILE}"
    echo "Public key can be accessed at ${PUBLIC_KEY_FILE}"
}
