#!/usr/bin/env bash

set -e

[ -n "${1}" ] && CONTAINER_NAME="${1}"
[ -z "${CONTAINER_NAME}" ] && echo "You need to provide CONTAINER_NAME as an arg!" && exit 1

CONTAINER_MOUNT_PATH="${HOME}/encrypted-volumes/${CONTAINER_NAME}"
CONTAINER_PATH="${HOME}/.encrypted-volumes/${CONTAINER_NAME}"

set -x

sudo cryptsetup luksOpen "${CONTAINER_PATH}" "${CONTAINER_NAME}"
sudo mount "/dev/mapper/${CONTAINER_NAME}" "${CONTAINER_MOUNT_PATH}"
