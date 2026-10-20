#!/usr/bin/env bash
set -eo pipefail

# ==============================================================================
# AzerothCore WotLK (3.3.5a) Automated Hot-Backup Script
# Backs up live MySQL state (auth, characters, world) and module configs.
# Compatible with local directories or network storage mounted via DrvFs/CIFS.
# ==============================================================================

# Target backup directory (can be overridden via environment variable)
BACKUP_DEST="${BACKUP_DEST:-/mnt/nas_backup}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="${BACKUP_DEST}/${TIMESTAMP}"
RETENTION_DAYS="${RETENTION_DAYS:-14}"

# Database container connection details
DB_CONTAINER="${DB_CONTAINER:-ac-database}"
DB_USER="${DB_USER:-root}"
DB_PASS="${DB_PASS:-password}"

# Repository root directory
REPO_DIR="${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# Ensure target mountpoint / directory is available
if [ -d "/mnt/nas_backup" ] && ! mountpoint -q /mnt/nas_backup; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Mountpoint /mnt/nas_backup exists but is unmounted. Attempting mount..."
    mount /mnt/nas_backup 2>/dev/null || true
fi

mkdir -p "${BACKUP_DIR}"
echo "[$(date +'%Y-%m-%d %H:%M:%S')] Starting AzerothCore backup to ${BACKUP_DIR}..."

# 1. Verify that database container is actively running
if ! docker ps --format '{{.Names}}' | grep -q "^${DB_CONTAINER}\$"; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Error: Database container '${DB_CONTAINER}' is not running."
    exit 1
fi

# 2. Dump Live Accounts & Characters (Characters, Gear, Bot levels/rosters, AH)
echo "[$(date +'%Y-%m-%d %H:%M:%S')] Exporting auth and characters databases..."
docker exec "${DB_CONTAINER}" mysqldump \
  -u"${DB_USER}" -p"${DB_PASS}" \
  --single-transaction --quick --routines --triggers \
  --databases acore_auth acore_characters 2>/dev/null \
  | gzip -9 > "${BACKUP_DIR}/acore_live_data_${TIMESTAMP}.sql.gz"

# 3. Dump World Database (includes custom bot spawns, world edits)
echo "[$(date +'%Y-%m-%d %H:%M:%S')] Exporting world database..."
docker exec "${DB_CONTAINER}" mysqldump \
  -u"${DB_USER}" -p"${DB_PASS}" \
  --single-transaction --quick \
  acore_world 2>/dev/null \
  | gzip -9 > "${BACKUP_DIR}/acore_world_${TIMESTAMP}.sql.gz"

# 4. Archive Active Module Configurations
echo "[$(date +'%Y-%m-%d %H:%M:%S')] Archiving module configurations..."
if [ -d "${REPO_DIR}/env/dist/etc/modules" ]; then
    tar -czf "${BACKUP_DIR}/modules_config_${TIMESTAMP}.tar.gz" -C "${REPO_DIR}" env/dist/etc/modules/
fi

echo "[$(date +'%Y-%m-%d %H:%M:%S')] Backup complete! Archive size: $(du -sh "${BACKUP_DIR}" | cut -f1)"

# 5. Prune backups older than retention limit
if [ -d "${BACKUP_DEST}" ]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Pruning backups older than ${RETENTION_DAYS} days..."
    find "${BACKUP_DEST}" -mindepth 1 -maxdepth 1 -type d -mtime +"${RETENTION_DAYS}" -exec rm -rf {} +
fi

echo "[$(date +'%Y-%m-%d %H:%M:%S')] Backup process finished successfully."
