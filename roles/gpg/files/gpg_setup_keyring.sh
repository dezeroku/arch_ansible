#!/usr/bin/env bash

# This is not executable by default
# as it's not a common ocurrence setup and running with sh requires more attendance
#
# The setup is based on https://github.com/drduh/YubiKey-Guide
# It's recommended to run this setup in a LUKS encrypted directory
# preferably on a secured and offline device used only for that purpose
#
# It generates ED25519 master key and 3 subkeys, each used for a specific purpose
#
# Creating a secure environment and making sure that EXTERNAL_BACKUP_DIR is encrypted
# is out of scope of this script
#
# It also removes the GNUPGHOME at the end, leaving only EXTERNAL_BACKUP_DIR in place

set -euo pipefail

function require_value() {
    var_name="${1:-}"
    if [ -z "${!var_name:-}" ]; then
        echo "${var_name} variable must be defined"
        return 1
    fi
}

require_value GNUPGHOME
require_value REAL_NAME
require_value REAL_EMAIL
# It's enough for this to be a separate encrypted container on a safe machine
require_value EXTERNAL_BACKUP_DIR
USE_YUBIKEY_ENTROPY="${USE_YUBIKEY_ENTROPY:-true}"

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
    echo "Using Yubikey to increase entropy"
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

echo "Creating a revocation cert"
printf "Y\n0\n\nY\n" | gpg --command-fd 0 --pinentry-mode loopback --passphrase "${MASTER_PASSPHRASE}" --output "${GNUPGHOME}/to-backup/revoke.asc" --gen-revoke "${MASTER_KEY_ID}"

echo "${GNUPGHOME}/to-backup"
ls "${GNUPGHOME}/to-backup"

cp -avi "${GNUPGHOME}/"* "${EXTERNAL_BACKUP_DIR}"

PUBLIC_KEY_FILE="${HOME}/gpg-${MASTER_KEY_ID}-$(date +%F).asc"

gpg --armor --export "${MASTER_KEY_ID}" | tee "${PUBLIC_KEY_FILE}"
echo "Public key can be accessed at ${PUBLIC_KEY_FILE}"

echo "Removing the ${GNUPGHOME}"
rm -rf "${GNUPGHOME}"
