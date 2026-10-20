#!/usr/bin/env python3
"""
AzerothCore Playerbot Personality Manager & World Populator
Manages realistic "real-gamer" personalities (traits, tone, backstories, item reactions)
in the server database (llm_bot_identities) without external python database dependencies.
"""

import argparse
import hashlib
import json
import os
import random
import subprocess
import sys

CONTAINER_NAME = "ac-database"
DB_USER = "root"
DB_PASS = "password"
DB_NAME = "acore_characters"

RACE_MAP = {
    1: "Human", 2: "Orc", 3: "Dwarf", 4: "Night Elf", 5: "Undead",
    6: "Tauren", 7: "Gnome", 8: "Troll", 10: "Blood Elf", 11: "Draenei"
}

CLASS_MAP = {
    1: "Warrior", 2: "Paladin", 3: "Hunter", 4: "Rogue", 5: "Priest",
    6: "Death Knight", 7: "Shaman", 8: "Mage", 9: "Warlock", 11: "Druid"
}

ROLE_MAP = {
    "Warrior": "melee_dps", "Paladin": "tank", "Hunter": "ranged_dps",
    "Rogue": "melee_dps", "Priest": "healer", "Death Knight": "melee_dps",
    "Shaman": "healer", "Mage": "ranged_dps", "Warlock": "ranged_dps",
    "Druid": "healer"
}

# 10 Distinct Real-Gamer Archetypes
ARCHETYPES = [
    {
        "id": "tryhard_parser",
        "weight": 15,
        "tone_template": "fast-talking min-maxer, uses WoW meta slang (BiS, parse, aggro, cooldowns, zug zug)",
        "traits": ["competitive", "impatient", "analytical", "perfectionist", "ambitious"],
        "backstory_template": "Obsessed with top DPS parse rankings on Recount. Pre-pots before every dungeon pull, min-maxes {class} gemming to the exact hit cap, and is determined to get BiS weapon upgrades in Northrend.",
        "farewells": ["Gotta go sim my gear. Later.", "gg, good dps everyone.", "Catch you on the next raid lockout, peace."]
    },
    {
        "id": "casual_dad_gamer",
        "weight": 20,
        "tone_template": "laid-back dad-gamer vibe, types lowercase, speaks like a relaxed guildmate",
        "traits": ["patient", "relaxed", "friendly", "pragmatic", "low-key"],
        "backstory_template": "Long-time casual {race} {class} who plays late evenings with a cold drink on the desk. Doesn't stress over optimal parses, just loves exploring, leveling professions, and sharing friendly banter in party chat.",
        "farewells": ["Kids are waking up, gotta log. Fun run everyone!", "Take care folks, good dungeon.", "Later man, talk tomorrow."]
    },
    {
        "id": "grumpy_vet_tank",
        "weight": 10,
        "tone_template": "gruff veteran tank, direct, disciplined, says 'you spank it you tank it'",
        "traits": ["stoic", "blunt", "protective", "disciplined", "experienced"],
        "backstory_template": "Has tanked since 40-man Molten Core in 2005. Patient with boss mechanics, but has zero tolerance for impatient DPS who attack before threat is established. Reliable as a granite wall.",
        "farewells": ["Repair your gear. I'm out.", "Good heals. Later.", "Don't pull without me next time."]
    },
    {
        "id": "neurotic_healer",
        "weight": 10,
        "tone_template": "nervous, fast-typing healer, constantly calls out mana breaks and LoS",
        "traits": ["alert", "anxious", "dedicated", "reactive", "supportive"],
        "backstory_template": "Dedicated {class} healer who sweats through every double-trash pull. Constantly yelling 'drinking for 5 sec!' and watching party health bars like a hawk, but pulls off miraculous clutch saves when things get chaotic.",
        "farewells": ["My heart was racing on that last pull haha, need a stretch. Later!", "Need to refill water and buy drinks, cya!", "Good run everyone, stay safe."]
    },
    {
        "id": "nostalgic_boomer",
        "weight": 10,
        "tone_template": "nostalgic 2005 vanilla/TBC veteran, reminisces about old-school WoW",
        "traits": ["reflective", "observant", "warm", "talkative", "sentimental"],
        "backstory_template": "Played since the 2005 open beta. Compares every Wrath dungeon to 45-minute Stratholme runs and original Karazhan. Remembers farming old-school reputation and loves admiring classic weapon models.",
        "farewells": ["Ah, reminds me of the good old days in 2006. Catch you later!", "Have fun in Northrend, see ya.", "Take care folks, nostalgic run."]
    },
    {
        "id": "pvp_duelist",
        "weight": 10,
        "tone_template": "competitive arena junkie, talks about line-of-sight, resilience, and burst windows",
        "traits": ["aggressive", "confident", "tactical", "sharp", "restless"],
        "backstory_template": "Spends 80% of his time outside capital city gates dueling everyone in sight. Knows every class cooldown and interrupt timing by heart, and treats every dungeon boss like a 3v3 arena match.",
        "farewells": ["Off to queue 2s with my buddy, peace.", "1v1 me outside the gates later.", "Good games, cya."]
    },
    {
        "id": "speedrunner",
        "weight": 8,
        "tone_template": "high-tempo speedrunner, always jumping, loves chain pulls and skips",
        "traits": ["energetic", "restless", "daring", "impatient", "swift"],
        "backstory_template": "Wants to blast through every instance in under 15 minutes. Always jumping around during trash packs, looking for terrain shortcuts, and pushing the tank to chain-pull without pausing.",
        "farewells": ["Zoom zoom. Super fast run, thanks!", "Gotta sprint, cya!", "Next one even faster. Peace."]
    },
    {
        "id": "theorycrafter",
        "weight": 7,
        "tone_template": "inquisitive theorycrafter, loves discussing off-meta specs and stat math",
        "traits": ["inquisitive", "inventive", "analytical", "versatile", "eccentric"],
        "backstory_template": "Has spreadsheets calculating stat weights for {class} talents. Loves testing weird hybrid talent builds and explaining why a piece of gear with 5 less item level is actually mathematically superior.",
        "farewells": ["Logging onto my alt to test new glyphs, cya.", "Fun run, going to check combat logs.", "Later!"]
    },
    {
        "id": "chill_mellow",
        "weight": 5,
        "tone_template": "ultra-chill, uses 'vibes' and 'all good', never tilts at wipes",
        "traits": ["mellow", "easygoing", "cheerful", "unflappable", "warm"],
        "backstory_template": "Listens to chill music while casually questing across Northrend. Doesn't care if the group wipes three times on a boss, just laughs it off, drops a campfire, and keeps the party morale high.",
        "farewells": ["Good vibes only, peace out friends.", "Fun times, catch you later.", "Stay cozy, cya."]
    },
    {
        "id": "wholesome_noob",
        "weight": 5,
        "tone_template": "friendly, polite, super appreciative, fascinated by the game world",
        "traits": ["earnest", "humble", "enthusiastic", "helpful", "polite"],
        "backstory_template": "Recently reached Northrend and is in complete awe of flying mounts and giant dragon bosses. Asks honest questions about class mechanics and says 'thank you so much!' after every quest and dungeon.",
        "farewells": ["Thank you so much for the group, that was awesome! Have a great night!", "Thanks for showing me the way, cya!", "Take care everyone, thank you!"]
    }
]


def run_sql(sql_query: str) -> str:
    """Execute a query against ac-database container via docker exec."""
    cmd = [
        "docker", "exec", "-i", CONTAINER_NAME,
        "mysql", f"-u{DB_USER}", f"-p{DB_PASS}",
        DB_NAME, "-e", sql_query
    ]
    res = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8")
    if res.returncode != 0:
        clean_err = "\n".join([l for l in res.stderr.splitlines() if "Using a password" not in l])
        raise RuntimeError(f"Database query failed: {clean_err}")
    lines = [l for l in res.stdout.splitlines() if "Using a password" not in l]
    return "\n".join(lines)


def get_character_by_name(name: str):
    """Fetch GUID, race, and class for a character name."""
    escaped_name = name.replace("'", "''")
    out = run_sql(f"SELECT guid, name, race, class, level FROM characters WHERE LOWER(name) = LOWER('{escaped_name}');")
    lines = out.strip().splitlines()
    if len(lines) < 2:
        return None
    cols = lines[1].split("\t")
    return {
        "guid": int(cols[0]),
        "name": cols[1],
        "race": RACE_MAP.get(int(cols[2]), f"Race_{cols[2]}"),
        "class": CLASS_MAP.get(int(cols[3]), f"Class_{cols[3]}"),
        "level": int(cols[4])
    }


def list_personalities():
    """List all bot identities currently in database."""
    print("=" * 80)
    print(" Active Bot Personalities in Server Database (llm_bot_identities)")
    print("=" * 80)
    out = run_sql(
        "SELECT b.bot_guid, b.bot_name, b.role, b.tone, b.backstory, c.race, c.class, c.level "
        "FROM llm_bot_identities b "
        "LEFT JOIN characters c ON b.bot_guid = c.guid "
        "ORDER BY b.bot_name ASC;"
    )
    lines = out.strip().splitlines()
    if len(lines) < 2:
        print(" [!] No custom bot personalities configured yet in database.")
        print("     Apply defaults using: python manage_bot_personalities.py --apply")
        return

    print(f" Total Configured Personalities: {len(lines) - 1}\n")
    for line in lines[1:]:
        cols = line.split("\t")
        if len(cols) >= 5:
            guid = cols[0]
            name = cols[1]
            role = cols[2] if cols[2] != "NULL" else "any"
            tone = cols[3] if cols[3] != "NULL" else "default"
            backstory = cols[4] if cols[4] != "NULL" else "(No backstory)"
            race = RACE_MAP.get(int(cols[5]), "") if len(cols) > 5 and cols[5] != "NULL" else ""
            cls = CLASS_MAP.get(int(cols[6]), "") if len(cols) > 6 and cols[6] != "NULL" else ""
            lvl = f"Lvl {cols[7]}" if len(cols) > 7 and cols[7] != "NULL" else ""

            print(f" * Bot: {name:<12} (GUID: {guid:<3}) [{race} {cls} {lvl}]")
            print(f"   Role: {role} | Tone: {tone}")
            print(f"   Backstory: {backstory}\n")
    print("=" * 80)


def apply_json(json_path: str):
    """Read JSON file and upsert entries into llm_bot_identities."""
    if not os.path.exists(json_path):
        print(f"Error: Profile file not found: {json_path}")
        sys.exit(1)

    with open(json_path, "r", encoding="utf-8") as f:
        profiles = json.load(f)

    applied = 0
    print(f"Applying bot personality profiles from {json_path}...")

    for name, data in profiles.items():
        if name.startswith("_"):
            continue

        char = get_character_by_name(name)
        if not char:
            print(f" [SKIP] Character '{name}' not found in database.")
            continue

        guid = char["guid"]
        real_name = char["name"]
        traits = data.get("traits", ["adaptable", "loyal", "focused"])
        trait1 = traits[0] if len(traits) > 0 else "adaptable"
        trait2 = traits[1] if len(traits) > 1 else "loyal"
        trait3 = traits[2] if len(traits) > 2 else "focused"
        role = data.get("role", ROLE_MAP.get(char["class"], "companion"))
        tone = data.get("tone", "casual guildmate")
        farewell = data.get("farewell_msg", "See ya later.")
        backstory = data.get("backstory", "")

        e_name = real_name.replace("'", "''")
        e_t1 = trait1.replace("'", "''")
        e_t2 = trait2.replace("'", "''")
        e_t3 = trait3.replace("'", "''")
        e_role = role.replace("'", "''")
        e_tone = tone.replace("'", "''")
        e_farewell = farewell.replace("'", "''")
        e_backstory = backstory.replace("'", "''")

        upsert_sql = f"""
        INSERT INTO llm_bot_identities 
            (bot_guid, bot_name, trait1, trait2, trait3, role, tone, farewell_msg, backstory, identity_version)
        VALUES 
            ({guid}, '{e_name}', '{e_t1}', '{e_t2}', '{e_t3}', '{e_role}', '{e_tone}', '{e_farewell}', '{e_backstory}', 1)
        ON DUPLICATE KEY UPDATE
            bot_name = '{e_name}',
            trait1 = '{e_t1}',
            trait2 = '{e_t2}',
            trait3 = '{e_t3}',
            role = '{e_role}',
            tone = '{e_tone}',
            farewell_msg = '{e_farewell}',
            backstory = '{e_backstory}',
            identity_version = identity_version + 1;
        """
        run_sql(upsert_sql)
        print(f" [OK] Updated identity for {real_name} (GUID {guid}, {char['race']} {char['class']})")
        applied += 1

    print(f"\nDone! Successfully updated {applied} bot personalities from JSON.")


TANK_CLASSES = {"Warrior", "Paladin", "Death Knight", "Druid"}
HEALER_CLASSES = {"Priest", "Paladin", "Shaman", "Druid"}

def generate_persona_for_char(guid: int, name: str, race_id: int, class_id: int, level: int):
    """Procedurally create a realistic, unique gamer persona based on archetype distribution and class capabilities."""
    race = RACE_MAP.get(race_id, "Adventurer")
    cls = CLASS_MAP.get(class_id, "Fighter")

    # Filter archetypes based on what the class can actually do
    eligible_archetypes = []
    for arch in ARCHETYPES:
        if arch["id"] == "grumpy_vet_tank" and cls not in TANK_CLASSES:
            continue
        if arch["id"] == "neurotic_healer" and cls not in HEALER_CLASSES:
            continue
        eligible_archetypes.append(arch)

    # Use character name + guid as hash seed for deterministic variety
    seed_val = int(hashlib.md5(f"{name}_{guid}".encode()).hexdigest(), 16)
    rng = random.Random(seed_val)

    # Weighted random selection of archetype
    archetype_weights = [a["weight"] for a in eligible_archetypes]
    archetype = rng.choices(eligible_archetypes, weights=archetype_weights, k=1)[0]

    # Assign combat role matching archetype and class
    if archetype["id"] == "grumpy_vet_tank":
        role = "tank"
    elif archetype["id"] == "neurotic_healer":
        role = "healer"
    else:
        role = ROLE_MAP.get(cls, "companion")

    # Pick 3 non-overlapping traits
    available_traits = list(archetype["traits"])
    rng.shuffle(available_traits)
    traits = available_traits[:3] if len(available_traits) >= 3 else ["adaptable", "loyal", "focused"]

    # Generate backstory and tone
    backstory = archetype["backstory_template"].replace("{race}", race).replace("{class}", cls)
    tone = archetype["tone_template"]
    farewell = rng.choice(archetype["farewells"])

    return {
        "guid": guid,
        "name": name,
        "race": race,
        "class": cls,
        "level": level,
        "role": role,
        "tone": tone,
        "traits": traits,
        "backstory": backstory,
        "farewell": farewell,
        "archetype_id": archetype["id"]
    }


def populate_world(count: int = 100, overwrite: bool = False):
    """Populate database characters with diverse, procedural real-gamer personalities."""
    print("=" * 80)
    print(" Populating World with Diverse Real-Gamer Bot Personalities")
    print("=" * 80)

    # Fetch characters without identities (or all if overwrite)
    if overwrite:
        query = "SELECT guid, name, race, class, level FROM characters ORDER BY level DESC, guid ASC;"
    else:
        query = (
            "SELECT c.guid, c.name, c.race, c.class, c.level "
            "FROM characters c "
            "LEFT JOIN llm_bot_identities b ON c.guid = b.bot_guid "
            "WHERE b.bot_guid IS NULL "
            "ORDER BY c.level DESC, c.guid ASC;"
        )

    out = run_sql(query)
    lines = out.strip().splitlines()
    if len(lines) < 2:
        print("All matching characters already have personalities assigned. Use --overwrite to regenerate.")
        return

    chars_to_process = lines[1:]
    if count > 0:
        chars_to_process = chars_to_process[:count]

    print(f"Generating personalities for {len(chars_to_process)} characters...\n")

    applied = 0
    archetype_counts = {}

    for line in chars_to_process:
        cols = line.split("\t")
        if len(cols) < 5:
            continue
        guid = int(cols[0])
        name = cols[1]
        race_id = int(cols[2])
        class_id = int(cols[3])
        level = int(cols[4])

        persona = generate_persona_for_char(guid, name, race_id, class_id, level)

        e_name = persona["name"].replace("'", "''")
        e_t1 = persona["traits"][0].replace("'", "''")
        e_t2 = persona["traits"][1].replace("'", "''")
        e_t3 = persona["traits"][2].replace("'", "''")
        e_role = persona["role"].replace("'", "''")
        e_tone = persona["tone"].replace("'", "''")
        e_farewell = persona["farewell"].replace("'", "''")
        e_backstory = persona["backstory"].replace("'", "''")

        upsert_sql = f"""
        INSERT INTO llm_bot_identities 
            (bot_guid, bot_name, trait1, trait2, trait3, role, tone, farewell_msg, backstory, identity_version)
        VALUES 
            ({guid}, '{e_name}', '{e_t1}', '{e_t2}', '{e_t3}', '{e_role}', '{e_tone}', '{e_farewell}', '{e_backstory}', 1)
        ON DUPLICATE KEY UPDATE
            bot_name = '{e_name}',
            trait1 = '{e_t1}',
            trait2 = '{e_t2}',
            trait3 = '{e_t3}',
            role = '{e_role}',
            tone = '{e_tone}',
            farewell_msg = '{e_farewell}',
            backstory = '{e_backstory}',
            identity_version = identity_version + 1;
        """
        run_sql(upsert_sql)
        applied += 1
        arch = persona["archetype_id"]
        archetype_counts[arch] = archetype_counts.get(arch, 0) + 1

    print(f"\nDone! Assigned unique real-gamer personalities to {applied} bots.")
    print("\nArchetype Distribution:")
    for arch, cnt in sorted(archetype_counts.items(), key=lambda x: -x[1]):
        pct = (cnt / applied) * 100
        print(f" * {arch:<22}: {cnt:>3} bots ({pct:.1f}%)")
    print("=" * 80)


def main():
    parser = argparse.ArgumentParser(description="AzerothCore Bot Personality Manager")
    parser.add_argument("--list", action="store_true", help="List all configured bot personalities")
    parser.add_argument("--apply", nargs="?", const="config/bot_personalities.json", help="Apply JSON file to database")
    parser.add_argument("--populate-world", nargs="?", const=100, type=int, help="Populate world bots with diverse personalities (default 100)")
    parser.add_argument("--overwrite", action="store_true", help="Overwrite existing personalities when populating world")

    args = parser.parse_args()

    if args.list:
        list_personalities()
    elif args.populate_world is not None:
        populate_world(count=args.populate_world, overwrite=args.overwrite)
    elif args.apply:
        apply_json(args.apply)
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
