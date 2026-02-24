#!/usr/bin/env bash
set -euo pipefail

# Backs up the mc-data Docker volume to a timestamped .tar.gz on the host.
# Usage: ./scripts/volume-backup.sh [output_directory]

VOLUME_NAME="private-minecraft-server_mc-data"
BACKUP_DIR="${1:-$(pwd)/backups}"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_FILE="mc_volume_${TIMESTAMP}.tar.gz"

mkdir -p "${BACKUP_DIR}"

echo "Backing up volume '${VOLUME_NAME}' to ${BACKUP_DIR}/${BACKUP_FILE} ..."

docker run --rm \
  -v "${VOLUME_NAME}":/source:ro \
  -v "${BACKUP_DIR}":/backup \
  alpine \
  tar -czf "/backup/${BACKUP_FILE}" -C /source .

echo "Backup complete: ${BACKUP_DIR}/${BACKUP_FILE}"
