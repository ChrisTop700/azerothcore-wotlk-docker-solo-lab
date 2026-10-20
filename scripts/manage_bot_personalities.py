#!/usr/bin/env python3
"""
AzerothCore Playerbot Personality Manager
Syncs custom gamer backstories, tones, and traits between JSON and the MySQL database (llm_bot_identities).
Works directly using Docker CLI without requiring external python database libraries.
"""

import argparse
import json
import os
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
    # Filter out mysql password warnings from stdout/stderr
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
    out = run_sql("SELECT b.bot_guid, b.bot_name, b.role, b.tone, b.backstory, c.race, c.class, c.level FROM llm_bot_identities b LEFT JOIN characters c ON b.bot_guid = c.guid ORDER BY b.bot_name ASC;")
    lines = out.strip().splitlines()
    if len(lines) < 2:
        print(" [!] No custom bot personalities configured yet in database.")
        print("     Apply defaults using: python manage_bot_personalities.py --apply")
        return

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

            print(f"\n * Bot: {name} (GUID: {guid}) [{race} {cls} {lvl}]")
            print(f"   Role: {role} | Tone: {tone}")
            print(f"   Backstory: {backstory}")
    print("\n" + "=" * 80)


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
            continue  # Skip comments/metadata

        char = get_character_by_name(name)
        if not char:
            print(f" [SKIP] Character '{name}' not found in database. Create character first.")
            continue

        guid = char["guid"]
        real_name = char["name"]
        traits = data.get("traits", ["adaptable", "loyal", "focused"])
        trait1 = traits[0] if len(traits) > 0 else "adaptable"
        trait2 = traits[1] if len(traits) > 1 else "loyal"
        trait3 = traits[2] if len(traits) > 2 else "focused"
        role = data.get("role", "companion")
        tone = data.get("tone", "casual guildmate")
        farewell = data.get("farewell_msg", "See ya later.")
        backstory = data.get("backstory", "")

        # Escape SQL values
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

    print(f"\nDone! Successfully updated {applied} bot personalities.")


def set_single(name: str, tone: str = None, backstory: str = None, role: str = None):
    """Set identity fields for a single bot by name."""
    char = get_character_by_name(name)
    if not char:
        print(f"Error: Character '{name}' not found.")
        sys.exit(1)

    guid = char["guid"]
    real_name = char["name"]

    updates = []
    if tone:
        updates.append(f"tone = '{tone.replace('\'', '\'\'')}'")
    if backstory:
        updates.append(f"backstory = '{backstory.replace('\'', '\'\'')}'")
    if role:
        updates.append(f"role = '{role.replace('\'', '\'\'')}'")

    if not updates:
        print("No changes specified.")
        return

    update_clause = ", ".join(updates)
    sql = f"""
    INSERT INTO llm_bot_identities 
        (bot_guid, bot_name, trait1, trait2, trait3, role, tone, farewell_msg, backstory, identity_version)
    VALUES 
        ({guid}, '{real_name}', 'loyal', 'pragmatic', 'chill', 'companion', 'casual', 'Later!', '', 1)
    ON DUPLICATE KEY UPDATE
        {update_clause},
        identity_version = identity_version + 1;
    """
    run_sql(sql)
    print(f"Successfully updated {real_name} (GUID: {guid}).")


def main():
    parser = argparse.ArgumentParser(description="AzerothCore Bot Personality Manager")
    parser.add_argument("--list", action="store_true", help="List all configured bot personalities")
    parser.add_argument("--apply", nargs="?", const="config/bot_personalities.json", help="Apply JSON file to database")
    parser.add_argument("--set", action="store_true", help="Set properties for a single bot")
    parser.add_argument("--name", help="Character name for --set")
    parser.add_argument("--tone", help="Speaking tone description for --set")
    parser.add_argument("--backstory", help="Backstory text for --set")
    parser.add_argument("--role", help="Preferred combat role for --set")

    args = parser.parse_args()

    if args.list:
        list_personalities()
    elif args.apply:
        apply_json(args.apply)
    elif args.set:
        if not args.name:
            print("Error: --name is required when using --set")
            sys.exit(1)
        set_single(args.name, tone=args.tone, backstory=args.backstory, role=args.role)
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
