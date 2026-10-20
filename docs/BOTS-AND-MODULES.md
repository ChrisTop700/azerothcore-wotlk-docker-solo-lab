# Bot Companion Management & In-Game Cheatsheet

This reference details how to summon, control, and equip **Playerbots**, as well as how **AutoBalance** interacts with your party.

---

## 1. Playerbots In-Game Commands

Playerbots are real player characters stored in the `characters` database. You can manage them through chat commands, whispers, or visually using the [CleanBot](https://github.com/bennybroseph/CleanBot) addon.

### Summoning & Grouping
* `.playerbots bot add <CharacterName>` — Log in an alt character or world bot and add them to your party.
  *(Example: `.playerbots bot add Pier`)*
* `.playerbots bot remove <CharacterName>` — Dismiss the bot from your party and save character progress to the database.
* `.playerbots bot addclass <class> [male|female]` — Summon a level-matched bot of a specific class.
  *(Example: `.playerbots bot addclass warrior male`)*
* `.playerbots bot list` — View all active bots under your command.

### Account Linking (For Alt Accounts)
To summon characters created on separate accounts:
1. Log into your alt account and set a security key:
   ```text
   .playerbots account setKey <mySecretKey>
   ```
2. Log into your main character and link the account:
   ```text
   .playerbots account link <altAccountName> <mySecretKey>
   ```
3. Once linked, you can summon any character on that account with `.playerbots bot add <name>` or via the CleanBot Manage tab.

### Tactical Combat & Movement Directives
You can command bots via `/party` or by whispering individual bots:
* **Attack / Pull**:
  * Whisper `attack` or type `/party do attack my target` — Orders bots to engage your target.
  * Whisper `pull` or type `/party pull my target` — Orders tank bots to pull your target.
* **Movement & Stance**:
  * Whisper `follow` — Bots follow closely behind you.
  * Whisper `stay` or `hold` — Bots hold their current position.
  * Whisper `flee` or `runaway` — Bots disengage and retreat toward you.
  * Whisper `passive` — Bots cease attacking and stand down.
* **Prep & Recovery**:
  * Whisper `rebuff` — Bots refresh missing class buffs and auras.
  * Whisper `food` / `drink` — Bots sit and recover health/mana.
  * Whisper `release` — Dead bots release spirit.
  * Whisper `revive` — Living bots resurrect fallen party members.

### Equipment & Roles
* **Role Selection**:
  * Whisper `tank` — Configures bot for tanking stance, threat generation, and defensive cooldowns.
  * Whisper `heal` — Prioritizes healing and dispelling party members.
  * Whisper `dps` — Focuses on damage rotations and crowd control.
* **Gearing**:
  * Whisper `equip` or `autogear` — Bot equips the highest item level / best stats from their bags.
  * Trade items directly to bots via the trade window; they accept suitable gear upgrades.
  * Drag-and-drop gear into their paperdoll using the **CleanBot** Individual tab.

---

## 2. Essential In-Game Macros

Create these macros in your WoW client for rapid command without typing:

### Macro 1: "Bots Attack My Target"
```text
/party do attack my target
```

### Macro 2: "Bots Pull Target"
```text
/party pull my target
```

### Macro 3: "Bots Fall Back"
```text
/party follow
/party stay
```

### Macro 4: "Rebuff & Prep"
```text
/party rebuff
/party autogear
```

---

## 3. AutoBalance Mechanics & Synergy

`mod-autobalance` dynamically scales creature and boss attributes in real-time based on group size:

* **Party Size Calculation**: 
  AutoBalance naturally detects Playerbots in your party. If you enter a 5-man dungeon with yourself and 2 bots, the instance dynamically scales enemy health and damage to a **3-person difficulty**.
* **Solo Dungeon Crawling**:
  If you dismiss all bots and enter an instance solo, AutoBalance will scale creature health, melee damage, and spell damage down to single-player levels.
* **Boss CC & Mechanics**:
  AutoBalance modifies boss mechanic timers to prevent wipe situations when running undersized groups (e.g., boss mechanics that normally incapacitate multiple party members simultaneously).
