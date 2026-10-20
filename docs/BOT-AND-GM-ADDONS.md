# Essential Client Addons: Bot Management & GM Administration

This guide covers the client addons for managing **NPCBots** and performing in-game **GM server administration** on an AzerothCore (WotLK 3.3.5a) server.

---

## 1. Bot Management Addons

Instead of typing console commands (`.npcbot ...`) during combat, these addons give you visual interfaces for bot actions, party coordination, and equipment.

### A. [NetherBot](https://github.com/NetherstormX/NetherBot)
The primary UI command wrapper built specifically for `trickerer`'s NPCBots system on 3.3.5a.

* **Key Features:**
  * **Command Wheel & Action HUD**: Instant buttons for Attack, Follow, Hold Position, and adjusting follow distance.
  * **Spawning & Recruitment Panel**: Visual catalog to browse available bots by class and summon or recruit them to your party with one click.
  * **Bot Party/Raid Frames**: Displays your bot party's health, mana, active roles, and combat states.

### B. [NpcBotEqManager (nbem)](https://github.com/Torrozin/mod-nbem-scan-and-npcboteqmanager)
A companion character-sheet addon specifically for outfitting your bots.

* **Key Features:**
  * **Visual Equipment Slots**: Target any hired bot to open an equipment window displaying their armor, weapons, rings, and trinkets.
  * **Drag-and-Drop Gearing**: Drag items directly from your inventory to equip matching weapons and armor on your bots.
  * **Talents & Specs**: Visual toggles to configure bot talent specializations (e.g., toggling a Paladin bot between Protection tank, Holy healer, or Retribution DPS).

---

## 2. In-Game GM & Administration Addons

### A. [AzerothAdmin](https://github.com/superstyro/AzerothAdmin)
The modern port of the classic *TrinityAdmin / MangAdmin* built specifically for **AzerothCore 3.3.5a**.

* **Key Features:**
  * **Minimap Quick Access**: One-click launcher from the minimap.
  * **Comprehensive Teleport Menu**: Hierarchical tree covering all Eastern Kingdoms, Kalimdor, Outland, and Northrend dungeons, raids, battlegrounds, and points of interest.
  * **GM Toggles**: Instant toggles for God Mode (`.gm on`), Fly Mode (`.gm fly on`), Invisibility, Movement Speed, and Instant Revive.
  * **NPC & GameObject Spawner**: In-game database search for creatures and game objects with 3D model previews (via `AzerothAdmin_Models`), with click-to-spawn and delete tools.
  * **Server Maintenance**: Broadcast server-wide announcements, trigger countdown reboots, and reload configuration and database tables (`.reload config`, `.reload creature_template`).

### B. [GM Genie](https://github.com/WotLK-Addons/GM-Genie)
A lightweight alternative HUD/action bar for GM shortcuts, player lookups, and fast ticket handling if you prefer a minimal bar over a full-screen window.

---

## 3. Client Installation

1. Download or clone the addon repositories.
2. Place the addon folders inside your WoW client directory:
   ```text
   <WoW-Client-Root>/Interface/AddOns/
   ├── AzerothAdmin/
   ├── AzerothAdmin_Models/
   ├── NetherBot/
   └── NpcBotEqManager/
   ```
3. At the character selection screen:
   - Click the **AddOns** button in the lower-left corner.
   - Check **"Load out of date AddOns"**.
   - Ensure all addon modules are checked/enabled.
4. Log into your character. The **NetherBot** control wheel and **AzerothAdmin** minimap icon will appear automatically.
