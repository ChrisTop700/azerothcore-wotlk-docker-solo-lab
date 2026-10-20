# Google Gemini Free Tier & Real-Gamer Bot Personalities Guide

This guide details how to connect your AzerothCore Playerbots to the **Google Gemini Free Tier** (using a secondary Google account) and how to give your companion bots consistent, **authentic "real person / guildmate" personalities** with awareness of **Classic, TBC, and Wrath items**.

---

## 1. Why Google Gemini Free Tier?

* **100% Free**: Google AI Studio provides **15 requests per minute** and **1,500 requests per day** for models like `gemini-2.5-flash` and `gemini-1.5-flash` at zero cost.
* **Massive Context & Memory**: Gemini effortlessly handles long backstories, party history, and item stats without hitting token caps.
* **Instant In-Game Responses**: With `ThinkingBudget = 0`, Gemini Flash responds in under 400ms—feeling like a real player typing in party or whisper chat.
* **Separation of Accounts**: Keeps your gaming lab completely isolated from your primary developer or production Google credentials.

---

## 2. Getting Your Free Gemini API Key (Secondary Account)

1. Open an incognito/private browser window or log into your **secondary Google account**.
2. Navigate to **Google AI Studio**: [https://aistudio.google.com/app/apikey](https://aistudio.google.com/app/apikey)
3. Click **"Create API key"** (select "Create API key in new project").
4. Copy your key (starts with `AIza...`).

---

## 3. Switching to Gemini Cloud

Run the automated switcher script from PowerShell:

```powershell
.\scripts\setup-gemini-cloud.ps1
```
*(It will prompt for your API key, update the bridge config, restart the Docker container, and verify the live connection).*

Or pass it directly:
```powershell
.\scripts\setup-gemini-cloud.ps1 -ApiKey "AIzaSy..." -Model "gemini-2.5-flash"
```

### Reverting to Local Ollama Anytime
If you ever want to run 100% offline without internet:
```powershell
.\scripts\setup-gemini-cloud.ps1 -SwitchToOllama
```

---

## 4. How Item Awareness Works (Classic, TBC, and Wrath)

Whenever you or a bot shift-clicks an item link in chat (e.g. `[Thunderfury, Blessed Blade of the Windseeker]`, `[Betrayer of Humanity]`, `[Darkmoon Card: Greatness]`):

1. **Local Database Interception**: The bridge parses the item ID directly from the chat packet.
2. **Instant MySQL Lookup**: It queries `acore_world.item_template` for:
   * Item Quality (Poor to Legendary)
   * Item Class & Subclass (Plate, Mail, 2H Mace, Wand, etc.)
   * Item Level (iLvl) & Stats
   * Flavor text / Description
3. **Context Injection**: The LLM receives the parsed item data along with the bot's class and current level.

### Real Gamer Reactions:
Because bots know their class, role, and personality, they react like real guildmates:
* **Upgrade**: *"Dude, roll on [Titansteel Destroyer]! That's a massive upgrade over my dungeon blue, I need the expertise."*
* **Wrong Spec/Stat**: *"Why would I roll on Spirit/Spell Power cloth on a Mage? That's healer gear, give it to the Priest or vendor it for repairs."*
* **Nostalgia & Memes**: If someone links `[Thunderfury]`, the bot might joke about trade chat spam or 2005 Molten Core binding drops.

---

## 5. Building "Real Person" Bot Personalities

Instead of stiff, theatrical Shakespearean RP (*"Greetings noble traveler, let us vanquish the scourge"*), you can define companions that feel like authentic human guildmates:

### Personality Profiles File: `config/bot_personalities.json`
Edit [config/bot_personalities.json](file:///C:/Users/chris/Documents/antigravity/azerothcore-wotlk-docker-solo-lab/config/bot_personalities.json) to customize your alts:

```json
{
  "Pier": {
    "traits": ["witty", "impatient", "curious"],
    "role": "ranged_dps",
    "tone": "sharp, sarcastic, fast-talking gnome mage",
    "backstory": "Your long-time dungeon partner since Vanilla Scarlet Monastery. Always counting mana gems, complains loudly when the tank pulls without waiting for drinking, and gets way too excited when high-crit cloth drops.",
    "farewell_msg": "Portals are ready whenever you want to roll out again."
  },
  "Berthalkwa": {
    "traits": ["patient", "chill", "observant"],
    "role": "ranged_dps",
    "tone": "relaxed, low-key dad-gamer vibe, speaks casually",
    "backstory": "Leveled through the Barrens and Outland with you. Plays late nights with a drink on his desk. Doesn't stress about optimal parses, just loves taming rare beasts, sharing food, and chatting about Northrend scenery.",
    "farewell_msg": "Catch you on the next run, man. Feed your pets."
  }
}
```

### Applying Profiles to the Server Database
To push changes from your JSON file to the game database:
```powershell
.\scripts\manage-bot-personalities.ps1 -Apply
```

### Viewing All Active Bot Personalities
```powershell
.\scripts\manage-bot-personalities.ps1 -List
```

### Updating a Bot Directly from Terminal
```powershell
.\scripts\manage-bot-personalities.ps1 -Name Pier -Tone "speedrunner, impatient" -Backstory "Refuses to do dungeons without a mount."
```

---

## 6. In-Game Bot Commands

You can also inspect or tweak bot backstories directly in-game while playing:

| In-Game Command | Description |
| :--- | :--- |
| `.llmc get <botGuid>` | View the bot's current traits, tone, and backstory in chat. |
| `.llmc setbackstory <botGuid> <text>` | Overwrite the bot's backstory on the fly. |
| `.llmc regenbackstory <botGuid>` | Instruct the LLM to generate a fresh backstory based on their class/race. |
| `.llmc forget <botGuid>` | Clear short-term session conversation memory for that bot. |
