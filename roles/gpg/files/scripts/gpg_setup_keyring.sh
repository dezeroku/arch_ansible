#!/usr/bin/env bash

set -euo pipefail

SCRIPTS_DIR="$(readlink -f "$(dirname "$0")")"

# shellcheck source=roles/gpg/files/scripts/lib.sh
. "$SCRIPTS_DIR/lib.sh"

function usage_doc() {
    cat << 'HEREDOC'
This script will generate ED25519 master key and 3 subkeys, each used for a specific purpose

It's recommended to point GNUPGHOME_TARGET to a LUKS encrypted directory
preferably on a secured and offline device used only for that purpose
Creating a secure environment is out of scope of this script

Env variables
GNUPGHOME_TARGET        directory that the keyring will be created in
REAL_NAME               name to use when creating the key
REAL_EMAIL              email to use when creating the key

Optional env variables
SEND_KEYS               if set to 'true' will upload the pubkey to a keyserver
USE_YUBIKEY_ENTROPY     if set to 'false' Yubikey won't be used for increasing entropy
                        Use this option when you don't have a Yubikey on hand
HEREDOC
}

require_value GNUPGHOME_TARGET
require_value REAL_NAME
require_value REAL_EMAIL

USE_YUBIKEY_ENTROPY="${USE_YUBIKEY_ENTROPY:-true}"
SEND_KEYS="${SEND_KEYS:-false}"

GNUPGHOME="$GNUPGHOME_TARGET"
export GNUPGHOME

chown "${USER}:${USER}" "${GNUPGHOME}"
chmod 0700 "${GNUPGHOME}"
mkdir "${GNUPGHOME}/to-backup"

cat > "${GNUPGHOME}/gpg.conf" << HEREDOC
personal-cipher-preferences AES256 AES192 AES
personal-digest-preferences SHA512 SHA384 SHA256
personal-compress-preferences ZLIB BZIP2 ZIP Uncompressed
default-preference-list SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed
cert-digest-algo SHA512
s2k-digest-algo SHA512
s2k-cipher-algo AES256
charset utf-8
fixed-list-mode
no-comments
no-emit-version
keyid-format 0xlong
list-options show-uid-validity
verify-options show-uid-validity
with-fingerprint
require-cross-certification
no-symkey-cache
use-agent
throw-keyids
HEREDOC

MASTER_PASSPHRASE="$(gpg --gen-random --armor 0 24)"

echo "${MASTER_PASSPHRASE}" > "${GNUPGHOME}/master-passphrase"

# Improved entropy via YubiKey
if [[ "${USE_YUBIKEY_ENTROPY}" == "true" ]]; then
    echoerr "Using Yubikey to increase entropy"
    echo "SCD RANDOM 512" | gpg-connect-agent | sudo tee /dev/random | hexdump -C
fi

gpg --batch --generate-key << HEREDOC
%echo Generating a master key
Key-Type: eddsa
Key-Curve: Ed25519
Key-Usage: cert
Name-Real: ${REAL_NAME}
Name-Email: ${REAL_EMAIL}
Passphrase: ${MASTER_PASSPHRASE}
Expire-Date: 5y
%commit
%echo done
HEREDOC

MASTER_KEY_ID="$(gpg --list-keys --with-fingerprint --with-colons | grep pub | cut -d ":" -f 5)"
MASTER_KEY_FINGERPRINT="$(gpg --list-keys --with-fingerprint --with-colons | grep fpr | cut -d ":" -f 10)"
gpg --batch --pinentry-mode loopback --passphrase "${MASTER_PASSPHRASE}" --quick-add-key "${MASTER_KEY_FINGERPRINT}" Ed25519 sign 1y
gpg --batch --pinentry-mode loopback --passphrase "${MASTER_PASSPHRASE}" --quick-add-key "${MASTER_KEY_FINGERPRINT}" Curve25519 encrypt 1y
gpg --batch --pinentry-mode loopback --passphrase "${MASTER_PASSPHRASE}" --quick-add-key "${MASTER_KEY_FINGERPRINT}" Ed25519 auth 1y

# Sign subkeys (this seems to be done by default)
#for subkey in $(gpg --list-keys --with-fingerprint --with-colons | grep sub | cut -d":" -f 5);
#do
#    gpg --default-key "${MASTER_KEY_ID}" --batch --pinentry-mode loopback --passphrase "${MASTER_PASSPHRASE}" --sign-key "${subkey}"
#done

gpg -K

gpg --export "${MASTER_KEY_ID}" | hokey lint

gpg --pinentry-mode loopback --passphrase "${MASTER_PASSPHRASE}" --armor --export-secret-keys "${MASTER_KEY_ID}" > "${GNUPGHOME}/to-backup/mastersub.key"
gpg --pinentry-mode loopback --passphrase "${MASTER_PASSPHRASE}" --armor --export-secret-subkeys "${MASTER_KEY_ID}" > "${GNUPGHOME}/to-backup/sub.key"

echoerr "Creating a revocation cert"
printf "Y\n0\n\nY\n" | gpg --command-fd 0 --pinentry-mode loopback --passphrase "${MASTER_PASSPHRASE}" --output "${GNUPGHOME}/to-backup/revoke.asc" --gen-revoke "${MASTER_KEY_ID}"

echoerr "${GNUPGHOME}/to-backup"
ls "${GNUPGHOME}/to-backup"

export_public_key

if [[ "$SEND_KEYS" == "true" ]]; then
    gpg --send-keys "${MASTER_KEY_ID}"
fi
