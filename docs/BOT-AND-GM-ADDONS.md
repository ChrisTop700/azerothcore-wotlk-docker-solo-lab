# Essential Client Addons: Bot Management & GM Administration

This guide covers the client addons for managing **Playerbots** and performing in-game **GM server administration** on an AzerothCore (WotLK 3.3.5a) server.

---

## 1. Bot Management Addon: [CleanBot](https://github.com/bennybroseph/CleanBot)

The modern, sleek UI addon built specifically for **AzerothCore `mod-playerbots`** on 3.3.5a.

* **Key Features:**
  * **Main Dashboard (`/cb`, `/bot`, `/cleanbot`)**:
    * **Manage Tab**: Account linking for alts (`.playerbots account link`), custom preset rosters, one-click login/logout, party invite/remove.
    * **Individual Tab**: Full bot paperdoll, drag-and-drop equipment, bag inspection, talent review, and role/strategy toggles (Tank, Healer, DPS, AoE, Cooldowns).
    * **Group Tab**: Mass bot selection by class or role to coordinate raid teams.
  * **Mini Action Bar HUD**:
    * Clean floating bar for quick combat control: Attack, Pull, Follow, Stay, Runaway, Passive, Summon, Release, Revive, and Recruit.
  * **Solo Lab AI & Prep Extensions**:
    * **Party Banter**: 1-click prompt to party chat triggering local Ollama / Gemini AI bot dialogue.
    * **Whisper Companion**: Direct check-in whisper to your targeted companion.
    * **Rebuff & Autogear**: Instantly refresh party buffs and equip optimal gear upgrades.

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

1. Addon files reside inside your WoW client directory:
   ```text
   <WoW-Client-Root>/Interface/AddOns/
   ├── AzerothAdmin/
   ├── AzerothAdmin_Models/
   └── CleanBot/
   ```
2. At the character selection screen:
   - Click the **AddOns** button in the lower-left corner.
   - Check **"Load out of date AddOns"**.
   - Ensure all addon modules are checked/enabled.
3. In-game commands:
   - `/bot` or `/cb` opens the CleanBot Management Panel.
   - Minimap icon toggles the floating Mini Action Bar.
