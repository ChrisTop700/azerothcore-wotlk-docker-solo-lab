# Playerbots & Local LLM Chatter Guide

This guide details how to summon your offline alts, interact with autonomous random bots in the open world, and manage AI-powered dynamic chat powered by local LLMs via **Ollama**.

---

## 1. Summoning Your Offline Characters as Companion Bots

One of the defining features of this setup is the ability to summon your own alternate characters into the world to form parties, run dungeons, and level up together.

### Summoning & Grouping
* Target yourself or an open space and type:
  ```text
  .bot add <CharacterName>
  ```
  *(Example: `.bot add Pier`)*
* Your offline character will log into the game world, run to you, and join your group.
* To dismiss the bot and save their progress:
  ```text
  .bot remove <CharacterName>
  ```

### Real Progression & Equipment
* Any experience points (XP), gold, and loot earned while adventuring as a bot are **permanently saved** to the character's database record.
* When you log out and log directly into that character later, all acquired levels and items will be in their bags and equipment slots.

### Directing Roles & Tactics
Whisper your bot directly in-game or type in `/party`:
* **Role assignment**:
  * Whisper `tank` — Bot assumes tanking stance, focuses on threat generation, and pulls for the party.
  * Whisper `heal` — Bot focuses on party health, dispelling, and reactive healing.
  * Whisper `dps` — Bot prioritizes damage rotations and crowd control.
* **Stance & Position**:
  * Whisper `stay` or `hold` — Bot holds current coordinates.
  * Whisper `follow` — Bot resumes following behind you.
  * Whisper `flee` — Bot disengages combat and sprints toward you.
* **Gear & Inventory**:
  * Whisper `equip` — Bot inspects their bags and equips any item upgrades.
  * Trade items directly to the bot via the trade window; they will accept suitable gear.

---

## 2. World Random Bots (`rndbot`)

The server automatically generates and maintains a living population of autonomous bots roaming the world:

* **Open-World Presence**: Bots explore zones matching their level bracket, defeat creatures, harvest nodes, and complete quest objectives.
* **Random Dungeon Finder (RDF)**: You can open your Dungeon Finder interface (`I`), queue for a dungeon as DPS, Tank, or Healer, and autonomous bots will fill the remaining roles to pop the queue.
* **World PvP & Battlegrounds**: Bots participate in Battlegrounds (Warsong Gulch, Arathi Basin) and engage opposing-faction players in contested zones.
* **Social Interaction**: Random bots appear on `/who`, belong to guilds, ride mounts, and can be invited to groups or challenged to duels outside capital cities.

---

## 3. Local LLM Chatter (`mod-llm-chatter` + Ollama)

Bots are connected directly to your local **Ollama** engine running **`hermes3:8b`** via an asynchronous Python bridge service.

### How It Works
* **Zero Frame Drops / Lag**: Game ticks run purely on the C++ engine. When a chat trigger occurs (whisper, party dialogue, boss death, wipe, zone transition), the game notifies the background bridge asynchronously.
* **Context-Aware Prompts**: The LLM receives dynamic game state:
  * Bot class, race, and talent specialization (e.g., an undead warlock vs. a dwarf paladin).
  * Current zone, subzone, weather, and time of day.
  * Recent combat milestones, loot drops, and party health.
* **Private Whispers & Banter**: Whisper any bot or speak in party chat to converse in natural language; they will reply in-character without breaking immersion.

### Managing the Chatter Bridge
The bridge runs inside Docker as `ac-llm-chatter-bridge`:
```bash
# View live LLM bridge logs & health report
docker logs -f ac-llm-chatter-bridge

# Restart the chatter bridge after model or config updates
docker restart ac-llm-chatter-bridge
```
