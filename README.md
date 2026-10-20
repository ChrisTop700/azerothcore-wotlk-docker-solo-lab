# AzerothCore WotLK (3.3.5a) Playerbot & AI Lab

A turn-key architecture and comprehensive setup guide for running a solo and small-group **World of Warcraft: Wrath of the Lich King (3.3.5a, Build 12340)** private server on **Windows 11/10 using WSL 2 and Docker Desktop**.

Featuring:
* **Living MMORPG World (Playerbots)**: Full playerbot simulation with autonomous questing, RDF dungeon matchmaking, open-world leveling, and alt-character summoning (`.bot add <alt>`).
* **Local LLM Dynamic Chatter**: Companion personality, party banter, and whisper conversations powered by local **Ollama** (`hermes3:8b` on RTX 4080) via `mod-llm-chatter`.
* **Dynamic Scaling**: Automatic creature and boss stat scaling for solo/small groups via `mod-autobalance`.
* **Living Economy**: Automated Auction House buyer/seller bots via `mod-ah-bot`.
* **Web Portal & Account Registration**: Self-service registration, announcements, and live realm status via BlizzCMS (`:8080`).
* **Interactive 3D Armory**: Character gear paperdoll, talent trees, achievements, and guild inspection via AzerothCore Armory (`:48733`).
* **Zero Host Toolchain Pollution**: Compiles and runs entirely within Docker containers.
* **Zero Client Map Extraction Hassle**: Client maps, DBC, VMaps, and MMaps are populated automatically via containerized extractors.
* **Automated Non-Blocking Backups**: Hot database and configuration backups directly to local storage or Network Attached Storage (NAS).
* **15-Minute Host Portability**: Complete decoupling of state from engine code for painless migration.

---

## Architecture Overview

```mermaid
flowchart TD
    subgraph WindowsHost ["Windows Host (Desktop / Client)"]
        WoWClient["WoW Client 3.3.5a (Build 12340)"]
        Browser["Web Browser (BlizzCMS :8080 / Armory :48733)"]
        NAS["Network Storage (NAS / SMB Share)"]
        DockerDesktop["Docker Desktop (WSL 2 Engine)"]
    end

    subgraph WSL2 ["WSL 2 (Ubuntu Filesystem)"]
        Repo["Core Source (trickerer/AzerothCore-wotlk-with-NPCBots)"]
        Modules["Modules: mod-autobalance, mod-ah-bot"]
        WebApps["Web Apps: BlizzCMS, AzerothCore Armory"]
        BackupScript["scripts/backup.sh (Daily Cron)"]
    end

    subgraph Containers ["Docker Container Stack"]
        AuthServer["ac-authserver (:3724)"]
        WorldServer["ac-worldserver (:8085, SOAP :7878) [NPCBots + AutoBalance + AHBot]"]
        DB["ac-database (MySQL 8.4 :3306)"]
        ClientData["ac-client-data-init (DBC, Maps, VMaps, MMaps)"]
        WebPortal["ac-web-portal (BlizzCMS :8080)"]
        Armory["ac-armory (AzerothCore Armory :48733)"]
    end

    WoWClient -->|Logon / Realmlist 127.0.0.1| AuthServer
    WoWClient -->|World Traffic| WorldServer
    Browser -->|HTTP :8080| WebPortal
    Browser -->|HTTP :48733| Armory
    WebPortal -->|SOAP :7878 (Account Creation)| WorldServer
    WebPortal -->|Query Auth & CMS Data| DB
    Armory -->|Query Characters & World| DB
    WorldServer <--> DB
    AuthServer <--> DB
    WorldServer <--> ClientData
    BackupScript -->|Hot-dump mysqldump| DB
    BackupScript -->|Stream compressed archives| NAS
```

---

## Repository Structure

```text
├── docs/
│   ├── SETUP-GUIDE.md                # End-to-end Windows + WSL 2 + Docker setup instructions
│   ├── BOTS-AND-MODULES.md           # NPCBot commands, party management, and AutoBalance tuning
│   ├── BOT-AND-GM-ADDONS.md          # In-game UI addons for bot control (NetherBot/nbem) and GM tools
│   ├── BACKUP-AND-DISASTER-RECOVERY.md # NAS mount guide (DrvFs/fstab) and restore playbook
│   └── WEB-PORTAL-GUIDE.md           # BlizzCMS web registration, account management & armory guide
├── scripts/
│   ├── backup.sh                     # Non-blocking live database and config backup script
│   └── restore.sh                    # Disaster recovery and host migration import script
└── README.md
```

---

## Quick Start Summary

For the full detailed walkthrough, see [docs/SETUP-GUIDE.md](docs/SETUP-GUIDE.md).

### 1. Prerequisites
* Windows 10/11 with WSL 2 and Ubuntu installed (`wsl --install -d Ubuntu`).
* Docker Desktop installed with **WSL Integration** enabled for Ubuntu.
* Clean World of Warcraft 3.3.5a client (Build 12340).

### 2. Clone Core & Modules (Inside WSL)
```bash
# Inside WSL terminal (ext4 filesystem for maximum I/O speed):
cd ~
git clone --depth 1 -b npcbots_3.3.5 https://github.com/trickerer/AzerothCore-wotlk-with-NPCBots.git azerothcore-wotlk
cd azerothcore-wotlk/modules
git clone --depth 1 https://github.com/azerothcore/mod-autobalance.git
git clone --depth 1 https://github.com/azerothcore/mod-ah-bot.git
```

### 3. Initialize Configurations
```bash
cd ~/azerothcore-wotlk
mkdir -p env/dist/etc/modules
cp modules/mod-autobalance/conf/AutoBalance.conf.dist env/dist/etc/modules/AutoBalance.conf
cp modules/mod-ah-bot/conf/mod_ahbot.conf.dist env/dist/etc/modules/mod_ahbot.conf
```

### 4. Build and Start
```bash
docker compose up -d --build
```

### 5. Create GM Account
```bash
docker attach ac-worldserver
# Inside console:
account create <username> <password>
account set gmlevel <username> 3 -1
# Detach safely: Ctrl + P, then Ctrl + Q
```

### 6. Point Client to Server
Edit `Data/enUS/realmlist.wtf` (or `enGB`) in your WoW client:
```text
set realmlist 127.0.0.1
```

---

## Bot Control & AutoBalance

* **AutoBalance**: Automatically scales 5-man dungeons and 10/25-man raids based on your active party size.
* **NPCBots**: Hire companion tanks, healers, and DPS from class trainers or taverns using in-game commands:
  * `.npcbot lookup <class>` — Search for available bots.
  * `.npcbot spawn <entry>` — Spawn bot.
  * Target bot and type `.npcbot add` — Add bot to party.
  * Full macro set and command syntax in [docs/BOTS-AND-MODULES.md](docs/BOTS-AND-MODULES.md).
* **Companion & GM Addons**: Visual control via NetherBot, NpcBotEqManager, and AzerothAdmin documented in [docs/BOT-AND-GM-ADDONS.md](docs/BOT-AND-GM-ADDONS.md).

---

## Automated Backups & Portability

The included [`scripts/backup.sh`](scripts/backup.sh) performs non-blocking hot database dumps of accounts, characters, bot rosters, and module configs directly to local or network storage without taking the server down.

To migrate to a new server in under 15 minutes, see [docs/BACKUP-AND-DISASTER-RECOVERY.md](docs/BACKUP-AND-DISASTER-RECOVERY.md).

---

## License & Credits

* Core game server provided by [AzerothCore](https://www.azerothcore.org/) and [trickerer](https://github.com/trickerer/AzerothCore-wotlk-with-NPCBots).
* AutoBalance module by the [AzerothCore Community](https://github.com/azerothcore/mod-autobalance).
* AuctionHouseBot by the [AzerothCore Community](https://github.com/azerothcore/mod-ah-bot).
* For educational, solo, and private lab testing purposes only.
