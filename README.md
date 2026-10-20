# AzerothCore WotLK (3.3.5a) Playerbot & AI Lab

A turn-key architecture and comprehensive setup guide for running a solo and small-group **World of Warcraft: Wrath of the Lich King (3.3.5a, Build 12340)** private server on **Windows 11/10 using WSL 2 and Docker Desktop**.

Featuring:
* **Living MMORPG World (Playerbots)**: Full playerbot simulation with autonomous questing, RDF dungeon matchmaking, open-world leveling, and alt-character summoning (`.playerbots bot add <alt>` or CleanBot UI).
* **Local LLM Dynamic Chatter**: Companion personality, party banter, and whisper conversations powered by local **Ollama** (`hermes3:8b` on RTX 4080) or **Google Gemini Free-Tier** via `mod-llm-chatter`.
* **In-Game Companion Management (CleanBot)**: Modern paperdoll equipment management, drag-and-drop gearing, strategy presets, and custom Solo Lab AI Chatter action buttons.
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
        WoWClient["WoW Client 3.3.5a (Build 12340) + CleanBot UI"]
        Browser["Web Browser (BlizzCMS :8080 / Armory :48733)"]
        NAS["Network Storage (NAS / SMB Share)"]
        OllamaLocal["Local Ollama AI (RTX 4080 :11434)"]
        DockerDesktop["Docker Desktop (WSL 2 Engine)"]
    end

    subgraph WSL2 ["WSL 2 (Ubuntu Filesystem)"]
        Repo["Core Source: AzerothCore (Playerbot Branch)"]
        Modules["Modules: mod-playerbots, mod-autobalance, mod-ah-bot, mod-llm-chatter"]
        WebApps["Web Apps: BlizzCMS, AzerothCore Armory"]
        BackupScript["scripts/backup.sh (Daily Cron)"]
    end

    subgraph Containers ["Docker Container Stack"]
        AuthServer["ac-authserver (:3724)"]
        WorldServer["ac-worldserver (:8085, SOAP :7878) - Playerbots, AutoBalance, AHBot"]
        DB["ac-database (MySQL 8.4 :3306)"]
        ClientData["ac-client-data-init (DBC, Maps, VMaps, MMaps)"]
        WebPortal["ac-web-portal (BlizzCMS :8080)"]
        Armory["ac-armory (AzerothCore Armory :48733)"]
        LLMBridge["ac-llm-chatter-bridge (Dynamic Chat, Memory, Item Lookups)"]
    end

    subgraph CloudAI ["Cloud AI (Optional Free Tier)"]
        GeminiCloud["Google Gemini API (Dual-Account Pool & Cascade)"]
    end

    DockerDesktop -->|Drives| Containers
    Repo -->|Mount / Build| WorldServer
    Modules -->|Compile Modules| WorldServer
    WoWClient -->|Logon / Realmlist 127.0.0.1| AuthServer
    WoWClient -->|World Traffic :8085| WorldServer
    WoWClient -->|CleanBot Addon Messages & Whispers| WorldServer
    Browser -->|HTTP :8080| WebPortal
    Browser -->|HTTP :48733| Armory
    WebPortal -->|SOAP :7878 (Account Creation)| WorldServer
    WebPortal -->|Query Auth and CMS Data| DB
    Armory -->|Query Characters and World| DB
    WorldServer -->|Read / Write World & Bot State| DB
    AuthServer -->|Read / Write Account Data| DB
    WorldServer -->|Load DBC, Maps & MMaps| ClientData
    WorldServer -->|Chat Events & Banter Triggers| LLMBridge
    LLMBridge -->|Primary: Cloud AI| GeminiCloud
    LLMBridge -->|Fallback: Local Ollama| OllamaLocal
    LLMBridge -->|Query item_template| DB
    BackupScript -->|Hot-dump mysqldump| DB
    BackupScript -->|Stream compressed archives| NAS
```

---

## Repository Structure

```text
├── config/
│   └── bot_personalities.json        # Custom "real-gamer" bot companion personalities & backstories
├── docs/
│   ├── SETUP-GUIDE.md                # End-to-end Windows + WSL 2 + Docker setup instructions
│   ├── BOTS-AND-MODULES.md           # Playerbot commands, party management, and AutoBalance tuning
│   ├── BOT-AND-GM-ADDONS.md          # In-game UI addons for bot control (CleanBot) and GM tools
│   ├── PLAYERBOTS-AND-LLM-CHATTER.md # Playerbot summoning & dynamic chatter overview
│   ├── GEMINI-CLOUD-AND-PERSONALITIES.md # Google Gemini Free-Tier & item-aware gamer personalities
│   ├── BACKUP-AND-DISASTER-RECOVERY.md # NAS mount guide (DrvFs/fstab) and restore playbook
│   └── WEB-PORTAL-GUIDE.md           # BlizzCMS web registration, account management & armory guide
├── scripts/
│   ├── setup-gemini-cloud.ps1        # Switch chatter bridge to Google Gemini Free Tier
│   ├── manage-bot-personalities.ps1  # Sync JSON bot backstories & tones with server database
│   ├── manage_bot_personalities.py   # Python backend for bot personality management
│   ├── backup.sh                     # Non-blocking live database and config backup script
│   ├── restore.sh                    # Disaster recovery and host migration import script
│   ├── start-server.ps1              # Starts Docker Desktop, Ollama (0.0.0.0), and core game containers
│   ├── start-web.ps1                 # Starts BlizzCMS portal (:8080) and Armory (:48733)
│   ├── start-ollama.ps1              # Starts local Ollama server bound to 0.0.0.0:11434
│   ├── stop-server.ps1               # Gracefully stops all game + web containers and unloads Ollama
│   └── stop-ollama.ps1               # Unloads active Ollama models from VRAM and stops background runner
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
git clone --depth 1 -b Playerbot https://github.com/mod-playerbots/azerothcore-wotlk.git azerothcore-wotlk
cd azerothcore-wotlk/modules
git clone --depth 1 https://github.com/mod-playerbots/mod-playerbots.git
git clone --depth 1 https://github.com/azerothcore/mod-autobalance.git
git clone --depth 1 https://github.com/azerothcore/mod-ah-bot.git
```

### 3. Initialize Configurations
```bash
cd ~/azerothcore-wotlk
mkdir -p env/dist/etc/modules
cp modules/mod-playerbots/conf/playerbots.conf.dist env/dist/etc/modules/playerbots.conf
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

* **AutoBalance**: Automatically scales 5-man dungeons and 10/25-man raids based on your active party size (solo or with bots).
* **Playerbots**: Summon your alts or random world bots using commands or the UI:
  * `.playerbots bot add <CharacterName>` — Add alt character to group.
  * `.playerbots bot addclass <class> [male|female]` — Add level-matched bot.
  * Whisper `tank`, `heal`, `dps`, `follow`, `stay`, `pull`, or `rebuff`.
  * Full macro set and command syntax in [docs/BOTS-AND-MODULES.md](docs/BOTS-AND-MODULES.md).
* **CleanBot & GM Addons**: Visual control via CleanBot (`/bot` or `/cb`) with drag-and-drop gear management, strategy presets, and AI banter action buttons, plus GM administration via AzerothAdmin documented in [docs/BOT-AND-GM-ADDONS.md](docs/BOT-AND-GM-ADDONS.md).

---

## Automated Backups & Portability

The included [`scripts/backup.sh`](scripts/backup.sh) performs non-blocking hot database dumps of accounts, characters, bot rosters, and module configs directly to local or network storage without taking the server down.

To migrate to a new server in under 15 minutes, see [docs/BACKUP-AND-DISASTER-RECOVERY.md](docs/BACKUP-AND-DISASTER-RECOVERY.md).

---

## License & Credits

* Core game server provided by [AzerothCore](https://www.azerothcore.org/) and the [mod-playerbots](https://github.com/mod-playerbots) project.
* AutoBalance module by the [AzerothCore Community](https://github.com/azerothcore/mod-autobalance).
* AuctionHouseBot by the [AzerothCore Community](https://github.com/azerothcore/mod-ah-bot).
* CleanBot addon by [bennybroseph](https://github.com/bennybroseph/CleanBot).
* For educational, solo, and private lab testing purposes only.
