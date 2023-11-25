#!/usr/bin/env bash
set -e

[ -n "${1}" ] && CONTAINER_NAME="${1}"
[ -z "${CONTAINER_NAME}" ] && echo "You need to provide CONTAINER_NAME as an arg!" && exit 1

CONTAINER_MOUNT_PATH="${HOME}/encrypted-volumes/${CONTAINER_NAME}"
CONTAINER_PATH="${HOME}/.encrypted-volumes/${CONTAINER_NAME}"

[ -e "${CONTAINER_MOUNT_PATH}" ] && echo "${CONTAINER_MOUNT_PATH} already exists!" && exit 1
[ -e "${CONTAINER_PATH}" ] && echo "${CONTAINER_PATH} already exists!" && exit 1

set -x

mkdir -p "${HOME}/encrypted-volumes"
mkdir -p "${HOME}/.encrypted-volumes"

fallocate -l 512M "${CONTAINER_PATH}"
dd if=/dev/zero of="${CONTAINER_PATH}" bs=1M count=512
sudo cryptsetup -y luksFormat "${CONTAINER_PATH}"

sudo cryptsetup luksOpen "${CONTAINER_PATH}" "${CONTAINER_NAME}"

sudo mkfs.ext4 -j "/dev/mapper/${CONTAINER_NAME}"

echo "Prepare future mountpoint"
mkdir -p "${CONTAINER_MOUNT_PATH}"
chmod 0000 "${CONTAINER_MOUNT_PATH}"

sudo mount "/dev/mapper/${CONTAINER_NAME}" "${CONTAINER_MOUNT_PATH}"

sudo chown "$USER:$USER" "${CONTAINER_MOUNT_PATH}"

#sudo umount "${CONTAINER_MOUNT_PATH}"
#sudo cryptsetup luksClose "${CONTAINER_NAME}"
