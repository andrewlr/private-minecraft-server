#!/usr/bin/env bash
set -euo pipefail

# Restores a .tar.gz backup into the mc-data Docker volume.
# WARNING: This removes all existing data in the volume before restoring.
# Usage: ./scripts/volume-restore.sh <path_to_backup.tar.gz>

VOLUME_NAME="private-minecraft-server_mc-data"

if [ -z "${1:-}" ]; then
  echo "Usage: $0 <path_to_backup.tar.gz>"
  exit 1
fi

BACKUP_FILE="$(realpath "$1")"
BACKUP_DIR="$(dirname "${BACKUP_FILE}")"
BACKUP_NAME="$(basename "${BACKUP_FILE}")"

if [ ! -f "${BACKUP_FILE}" ]; then
  echo "Error: file not found: ${BACKUP_FILE}"
  exit 1
fi

read -r -p "This will DELETE all data in volume '${VOLUME_NAME}' and restore from ${BACKUP_NAME}. Continue? [y/N] " confirm
if [[ ! "${confirm}" =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

echo "Clearing volume '${VOLUME_NAME}' ..."
docker run --rm \
  -v "${VOLUME_NAME}":/target \
  alpine \
  sh -c "rm -rf /target/*"

echo "Restoring from ${BACKUP_NAME} ..."
docker run --rm \
  -v "${VOLUME_NAME}":/target \
  -v "${BACKUP_DIR}":/backup:ro \
  alpine \
  tar -xzf "/backup/${BACKUP_NAME}" -C /target

echo "Restore complete."
