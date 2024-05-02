#!/usr/bin/env bash

set -euo pipefail

MAIL_ADDRESS="$1"

TOKEN_DIR="$HOME/.vdirsyncer/tokens"
mkdir -p "$TOKEN_DIR"

TOKEN_FILE="$TOKEN_DIR/$MAIL_ADDRESS"
touch "$TOKEN_FILE"
chmod 0600 "$TOKEN_FILE"

mailctl access "$MAIL_ADDRESS" > /dev/null

# Using mailctl access directly will not work
# as we need to access the whole JSON here
# Thus we get it from gnome-keyring in the expanded format
secret-tool lookup mailctl "$MAIL_ADDRESS" > "$TOKEN_FILE"

echo "$TOKEN_FILE"
