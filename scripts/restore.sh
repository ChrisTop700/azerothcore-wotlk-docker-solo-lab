#!/usr/bin/env bash
set -eo pipefail

# ==============================================================================
# AzerothCore WotLK (3.3.5a) Disaster Recovery & Restore Script
# Restores compressed database archives and module configurations into Docker.
# ==============================================================================

if [ -z "$1" ]; then
    echo "Usage: $0 <path_to_backup_folder>"
    echo "Example: $0 /mnt/nas_backup/20261020_053109"
    exit 1
fi

BACKUP_FOLDER="$1"
DB_CONTAINER="${DB_CONTAINER:-ac-database}"
DB_USER="${DB_USER:-root}"
DB_PASS="${DB_PASS:-password}"
REPO_DIR="${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

if [ ! -d "${BACKUP_FOLDER}" ]; then
    echo "Error: Backup directory '${BACKUP_FOLDER}' does not exist."
    exit 1
fi

echo "[$(date +'%Y-%m-%d %H:%M:%S')] Starting restore from ${BACKUP_FOLDER}..."

# 1. Check if database container is available
if ! docker ps --format '{{.Names}}' | grep -q "^${DB_CONTAINER}\$"; then
    echo "Error: Container '${DB_CONTAINER}' is not running. Please start the stack first via 'docker compose up -d'."
    exit 1
fi

# 2. Restore live data (auth & characters)
LIVE_DATA_FILE=$(find "${BACKUP_FOLDER}" -name "acore_live_data_*.sql.gz" | head -n 1)
if [ -f "${LIVE_DATA_FILE}" ]; then
    echo "Restoring auth and characters databases from ${LIVE_DATA_FILE}..."
    gunzip -c "${LIVE_DATA_FILE}" | docker exec -i "${DB_CONTAINER}" mysql -u"${DB_USER}" -p"${DB_PASS}"
else
    echo "Warning: No acore_live_data_*.sql.gz archive found in ${BACKUP_FOLDER}."
fi

# 3. Restore world database
WORLD_DATA_FILE=$(find "${BACKUP_FOLDER}" -name "acore_world_*.sql.gz" | head -n 1)
if [ -f "${WORLD_DATA_FILE}" ]; then
    echo "Restoring world database from ${WORLD_DATA_FILE}..."
    gunzip -c "${WORLD_DATA_FILE}" | docker exec -i "${DB_CONTAINER}" mysql -u"${DB_USER}" -p"${DB_PASS}" acore_world
else
    echo "Warning: No acore_world_*.sql.gz archive found in ${BACKUP_FOLDER}."
fi

# 4. Restore module configurations
CONFIG_FILE=$(find "${BACKUP_FOLDER}" -name "modules_config_*.tar.gz" | head -n 1)
if [ -f "${CONFIG_FILE}" ]; then
    echo "Restoring module configurations from ${CONFIG_FILE}..."
    tar -xzf "${CONFIG_FILE}" -C "${REPO_DIR}"
fi

echo "[$(date +'%Y-%m-%d %H:%M:%S')] Restarting worldserver container to apply changes..."
docker compose restart ac-worldserver

echo "[$(date +'%Y-%m-%d %H:%M:%S')] Restore completed successfully!"
