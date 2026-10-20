# Bot Companion Management & In-Game Cheatsheet

This reference details how to hire, control, and equip **NPCBots**, as well as how **AutoBalance** interacts with your party.

---

## 1. NPCBots In-Game Commands

All commands require GM permissions (level 2 or 3) unless enabled for regular players in `worldserver.conf`.

### Spawning & Finding Bots
* `.npcbot lookup <class>` — Search for available NPC bot entries by class (e.g., `warrior`, `paladin`, `hunter`, `rogue`, `priest`, `deathknight`, `shaman`, `mage`, `warlock`, `druid`).
* `.npcbot spawn <entry_id>` — Permanently spawn a specific bot NPC at your player coordinates.

### Recruiting & Dismissing
* Target an NPC bot in the world and type:
  ```text
  .npcbot add
  ```
  *(The bot joins your party as a companion).*
* To dismiss a bot from your party:
  ```text
  .npcbot remove
  ```
* To view current bot stats and role:
  ```text
  .npcbot info
  ```

### Tactical Combat Directives
* `.npcbot command attack` — Orders party bots to engage your current target.
* `.npcbot command follow` — Forces bots to cease combat and immediately return to your side.
* `.npcbot command hold` — Orders bots to hold their current position.
* `.npcbot distance <value>` — Sets the follow distance behind your character (default: `30`).

### Roles, Specs, & Equipment
* Right-click or interact with recruited bots to:
  * Select their talent tree / specialization (e.g., Holy vs. Protection Paladin).
  * Enable/disable specific spells and buffs.
  * Trade equipment directly to them (bots equip weapons, armor, rings, and trinkets matching their class).

---

## 2. Essential In-Game Macros

Create these macros in your WoW client for smooth party command:

### Macro 1: "Bots Engage"
```text
/npcbot command attack
```

### Macro 2: "Bots Fall Back"
```text
/npcbot command follow
/npcbot command hold
```

### Macro 3: "Recruit Target"
```text
/npcbot add
```

---

## 3. AutoBalance Mechanics & Synergy

`mod-autobalance` dynamically scales creature and boss attributes in real-time based on group size:

* **Party Size Calculation**: 
  AutoBalance naturally detects NPCBots in your party. If you enter a 5-man dungeon with yourself and 2 bots, the instance will automatically scale health and damage to a **3-person difficulty**.
* **Solo Dungeon Crawling**:
  If you dismiss all bots and enter an instance solo, AutoBalance will scale creature health, melee damage, and spell damage down to single-player levels.
* **Boss CC & Mechanics**:
  AutoBalance modifies boss mechanic timers to prevent wipe situations when running undersized groups (e.g., boss mechanics that normally incapacitate multiple party members simultaneously).
