#!/bin/sh

echo "message-info 'spawn_mpv: $QUTE_URL'" >> "${QUTE_FIFO}"

# Allow passing params via CLI
# shellcheck disable=SC2068
mpv --hwdec=auto --force-window=immediate ${@} "$QUTE_URL"
