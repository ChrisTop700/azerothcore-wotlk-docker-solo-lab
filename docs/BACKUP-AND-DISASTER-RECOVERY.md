# Backup Strategy, Network Storage, & Disaster Recovery

This document explains how to configure automated hot backups to a Network Attached Storage (NAS) device and how to migrate your entire server to a new host in under 15 minutes.

---

## 1. Zero-Downtime Backup Strategy

AzerothCore stores all persistent state inside **MySQL**:
* `acore_auth`: User accounts, GM levels, realm list settings.
* `acore_characters`: Player characters, quest progress, equipment, bot levels/gear, auction listings.
* `acore_world`: Any world edits or static bot spawns you created in-game.

Because Docker containers and compiled binaries are disposable, you only ever need to back up:
1. Compressed MySQL database dumps.
2. Active module `.conf` files.

---

## 2. Mounting Network Storage in WSL 2

WSL 2 allows mounting Windows SMB/UNC network shares directly into the Linux filesystem using **DrvFs**.

### Temporary Mount (Test Connection)
```bash
sudo mkdir -p /mnt/nas_backup
sudo mount -t drvfs '\\<YOUR-NAS-IP-OR-HOST>\<SHARE-NAME>\<BACKUP-FOLDER>' /mnt/nas_backup
```

### Permanent Auto-Mount via `/etc/fstab`
To automatically mount your network share whenever WSL boots, add an entry to `/etc/fstab`:

1. Open `/etc/fstab` in a text editor as root:
   ```bash
   sudo nano /etc/fstab
   ```
2. Add the following line (double backslashes for escaping):
   ```text
   \\\\<YOUR-NAS-IP-OR-HOST>\\<SHARE-NAME>\\<BACKUP-FOLDER> /mnt/nas_backup drvfs defaults,nofail,uid=1000,gid=1000 0 0
   ```
3. Test the mount:
   ```bash
   sudo mount -a
   ls -la /mnt/nas_backup
   ```

---

## 3. Running Automated Backups

The [`scripts/backup.sh`](../scripts/backup.sh) script automatically performs a hot export of the database and module configurations, compresses them with `gzip -9`, streams them directly to your destination, and prunes archives older than the retention period.

### Running on Demand
```bash
# Uses default /mnt/nas_backup
bash scripts/backup.sh

# Or override destination and retention inline
BACKUP_DEST="/mnt/nas_backup/acore" RETENTION_DAYS=30 bash scripts/backup.sh
```

### Scheduling Automatic Nightly Backups (Cron)
1. Open crontab in WSL:
   ```bash
   crontab -e
   ```
2. Add a rule to execute every night at 4:00 AM:
   ```cron
   0 4 * * * /bin/bash /path/to/scripts/backup.sh >> /var/log/acore_backup.log 2>&1
   ```

---

## 4. Disaster Recovery & Host Migration Playbook

When migrating to a new machine or restoring after a hardware failure:

### Step 1: Prepare New Host
Install Docker Desktop and WSL 2 on the new machine.

### Step 2: Clone Core & Modules
```bash
git clone --depth 1 -b npcbots_3.3.5 https://github.com/trickerer/AzerothCore-wotlk-with-NPCBots.git ~/azerothcore-wotlk
cd ~/azerothcore-wotlk/modules
git clone --depth 1 https://github.com/azerothcore/mod-autobalance.git
git clone --depth 1 https://github.com/azerothcore/mod-ah-bot.git
```

### Step 3: Start Containers
```bash
cd ~/azerothcore-wotlk
docker compose up -d --build
```

### Step 4: Restore Backup Snapshot
Use [`scripts/restore.sh`](../scripts/restore.sh) or restore manually:
```bash
# Extract configs
tar -xzf /mnt/nas_backup/<TIMESTAMP>/modules_config_*.tar.gz -C ~/azerothcore-wotlk/

# Stream databases directly into MySQL container
gunzip -c /mnt/nas_backup/<TIMESTAMP>/acore_live_data_*.sql.gz | docker exec -i ac-database mysql -u root -p<DB_PASSWORD>
gunzip -c /mnt/nas_backup/<TIMESTAMP>/acore_world_*.sql.gz | docker exec -i ac-database mysql -u root -p<DB_PASSWORD> acore_world

# Restart worldserver to load restored state
docker compose restart ac-worldserver
```

Your server is now running on the new host with all characters, accounts, items, and bot companions fully restored.
