#!/usr/bin/env bash

# Find a nice filename for the screenshot in a directory
# Based on the current date and time
# e.g you'll get:
# 19_16-13_0.png
# 19_16-13_1.png
# 19_16-13_2.png
# 19_16-13_3.png
# 19_16-14_0.png
# etc.

function get_full_path() {
    echo "${DIRECTORY}/${SUBDIRECTORY}/${FILENAME}"
}

function get_free_filename() {
    FILENAME="${PREFIX}_${NUMBER}${SUFFIX}"
    while [ -f "$(get_full_path)" ]; do
        # We really don't take enough screenshots
        # to justify making this logic prettier
        FILENAME="${PREFIX}_${NUMBER}${SUFFIX}"
        NUMBER=$(( NUMBER + 1 ))
    done

    # Reserve the filename
    touch "$(get_full_path)"
}

set -euo pipefail

[ -z "${1:-}" ] && echo "Provide the directory" && exit 1

DIRECTORY="$(readlink -f "$1")"

TMPDIR=${TMPDIR:-/tmp}
LOCKFILE="${TMPDIR}/screenshot-filename.sh.lock"
SUBDIRECTORY="$(date -u +%Y)/$(date -u +%m)"
PREFIX="$(date -u +%d_%H-%M)"
NUMBER="0"
SUFFIX=".png"

mkdir -p "${DIRECTORY}/${SUBDIRECTORY}"

(
flock -x -w 10 200
get_free_filename
get_full_path
) 200> "${LOCKFILE}"
