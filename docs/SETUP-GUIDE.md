# End-to-End Setup Guide: Windows + WSL 2 + Docker Desktop

This guide walks through configuring a solo/small-group **AzerothCore (WotLK 3.3.5a)** private server on Windows using WSL 2 and Docker Desktop.

---

## 1. Prerequisites

### Windows & WSL 2
1. Ensure hardware virtualization (VT-x or AMD-V) is enabled in your BIOS/UEFI.
2. Open PowerShell as Administrator and ensure WSL 2 and Ubuntu are installed:
   ```powershell
   wsl --install -d Ubuntu
   ```
3. Set WSL 2 as your default version:
   ```powershell
   wsl --set-default-version 2
   ```

### Docker Desktop
1. Download and install [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/).
2. Open **Docker Desktop Settings** (gear icon) → **Resources** → **WSL Integration**:
   - Check **Enable integration with my default WSL distro**.
   - Under *Additional distributions*, toggle ON **Ubuntu**.
   - Click **Apply & restart**.

---

## 2. Setting Up the Server in WSL

> [!IMPORTANT]
> Always clone the repository into the **native Linux filesystem (`~/` or `/home/<user>/`)** inside WSL, **never** on `/mnt/c/`. Compilation inside the native Linux ext4 filesystem is significantly faster than NTFS bind-mounts.

### Step 1: Open Your WSL Terminal
Open PowerShell or Windows Terminal and start Ubuntu:
```powershell
wsl -d Ubuntu
```

### Step 2: Clone Core with NPCBots
We use the actively maintained `trickerer/AzerothCore-wotlk-with-NPCBots` core repository (branch `npcbots_3.3.5`) because NPCBots requires deeper C++ engine hooks than standalone scripting modules provide:

```bash
cd ~
git clone --depth 1 -b npcbots_3.3.5 https://github.com/trickerer/AzerothCore-wotlk-with-NPCBots.git azerothcore-wotlk
```

### Step 3: Clone Companion Modules
Clone `mod-autobalance` and `mod-ah-bot` directly into the `modules/` folder:

```bash
cd ~/azerothcore-wotlk/modules

# 1. Dynamic creature/boss stat scaling for small parties
git clone --depth 1 https://github.com/azerothcore/mod-autobalance.git

# 2. Automated Auction House buyer/seller bot
git clone --depth 1 https://github.com/azerothcore/mod-ah-bot.git
```

---

## 3. Configuration Setup

In AzerothCore Docker deployments, configuration files mounted into `./env/dist/etc/` override defaults without needing container rebuilds.

```bash
cd ~/azerothcore-wotlk

# Create the module configuration directory
mkdir -p env/dist/etc/modules

# Copy default configurations
cp modules/mod-autobalance/conf/AutoBalance.conf.dist env/dist/etc/modules/AutoBalance.conf
cp modules/mod-ah-bot/conf/mod_ahbot.conf.dist env/dist/etc/modules/mod_ahbot.conf
```

### Recommended Configuration Adjustments

* **AutoBalance (`env/dist/etc/modules/AutoBalance.conf`)**:
  - `AutoBalance.Enable = 1`
  - `AutoBalance.DungeonMinScaling = 1` (Allows 5-man dungeons to scale down to 1 player).
  - `AutoBalance.RaidMinScaling = 1` (Allows raids to scale down to small groups).
  - *Note:* AutoBalance automatically factors active NPCBots into party size calculations.

* **NPCBots (`src/server/apps/worldserver/worldserver.conf.dist` or environment overrides)**:
  - NPCBots are enabled by default (`NpcBot.Enable = 1`).
  - Max bots allowed per group defaults to 39, enabling full 5-man, 10-man, or 25-man formations.

* **Auction House Bot (`env/dist/etc/modules/mod_ahbot.conf`)**:
  - `AuctionHouseBot.EnableSeller = 1` (Generates random trade goods, consumables, and gear across all quality tiers).
  - `AuctionHouseBot.EnableBuyer = 1` (Periodically buys items posted by players).

---

## 4. Building and Starting the Stack

Build the containers and launch the server services:

```bash
cd ~/azerothcore-wotlk
docker compose up -d --build
```

### What Happens During Build:
1. **`ac-database`**: Launches MySQL 8.4 and initializes schemas.
2. **`ac-client-data-init`**: Downloads/extracts pre-built client data (DBC, maps, vmaps, mmaps) directly into a named Docker volume (`ac-client-data`), eliminating hours of manual client file extraction.
3. **`ac-db-import`**: Automatically discovers and imports SQL tables and updates for the core and all modules.
4. **`ac-authserver`**: Compiles and launches the logon authentication service.
5. **`ac-worldserver`**: Compiles the core engine with NPCBots and modules, then launches the world service.

Verify that all containers are healthy:
```bash
docker compose ps
```

---

## 5. Account Creation and GM Setup

To interact with the running worldserver console:

1. **Attach to the console:**
   ```bash
   docker attach ac-worldserver
   ```
2. **Create your account and grant Administrator privileges:**
   ```text
   account create <username> <password>
   account set gmlevel <username> 3 -1
   ```
3. **Detach safely without stopping the server:**
   Press `Ctrl + P`, then `Ctrl + Q`.
   *(Do NOT press `Ctrl + C`, as that sends SIGINT and shuts down the worldserver).*

---

## 6. Client Connection

1. Open your **World of Warcraft: Wrath of the Lich King (3.3.5a, Build 12340)** client directory.
2. Navigate to `Data/enUS/realmlist.wtf` (or your localized directory such as `Data/enGB/realmlist.wtf`).
3. Open `realmlist.wtf` in a text editor and set:
   ```text
   set realmlist 127.0.0.1
   ```
4. Launch `WoW.exe` and log in using your newly created account credentials.
