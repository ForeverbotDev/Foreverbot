#!/usr/bin/env python3
"""
scripts/enrich_database_fully.py

Exhaustive data enrichment pipeline for Warcraft Forever:
- Parses item_template, quest_template, and creature_template from world_full_14_june_2021.sql.
- Extracts complete ground-truth stats, weapon damage/speed, armor, block, resistances, durability, bonding, and sell prices.
- Extracts authentic quest item choices, rewards, turn-in dialogues, and story lore.
- Resolves precise drop sources from the loot table, vendor sources, and quest reward links.
- Extracts NPC subnames/titles (e.g., <Weaponsmith>, <Flight Master>).
- Updates wow_forever.db cleanly.
"""

import os
import sys
import re
import sqlite3

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DB_PATH = os.path.join(BASE_DIR, "wow_forever.db")
SQL_FILE = os.path.join(BASE_DIR, "scratch", "ground_truth", "world_full_14_june_2021.sql")

STAT_NAMES = {
    0: "Mana",
    1: "Health",
    3: "Agility",
    4: "Strength",
    5: "Intellect",
    6: "Spirit",
    7: "Stamina",
    12: "Defense Rating",
    13: "Dodge",
    14: "Parry",
    15: "Block Rating",
    16: "Hit Rating",
    17: "Ranged Hit",
    18: "Spell Hit",
    19: "Critical Strike",
    20: "Ranged Crit",
    21: "Spell Crit",
    28: "Attack Power",
    29: "Ranged Attack Power",
    30: "Feral Attack Power",
    31: "Spell Damage",
    32: "Healing",
    33: "Mana per 5 sec",
    38: "Attack Power",
}

BONDING_NAMES = {
    1: "Binds when picked up",
    2: "Binds when equipped",
    3: "Binds when used",
    4: "Quest Item",
}


def format_money(copper: int) -> str:
    if not copper or copper <= 0:
        return ""
    g = copper // 10000
    s = (copper % 10000) // 100
    c = copper % 100
    parts = []
    if g > 0:
        parts.append(f"{g}g")
    if s > 0:
        parts.append(f"{s}s")
    if c > 0 or not parts:
        parts.append(f"{c}c")
    return " ".join(parts)


def parse_sql_row_tokens(s: str):
    s = s.strip()
    if s.startswith("("):
        s = s[1:]
    if s.endswith(";"):
        s = s[:-1].strip()
    if s.endswith(","):
        s = s[:-1].strip()
    if s.endswith(")"):
        s = s[:-1]

    tokens = []
    curr = []
    in_str = False
    escaped = False

    for ch in s:
        if in_str:
            if escaped:
                curr.append(ch)
                escaped = False
            elif ch == "\\":
                escaped = True
            elif ch == "'":
                in_str = False
            else:
                curr.append(ch)
        else:
            if ch == "'":
                in_str = True
            elif ch == ",":
                token = "".join(curr).strip()
                tokens.append(token)
                curr = []
            else:
                curr.append(ch)

    tokens.append("".join(curr).strip())
    return tokens


def main():
    print("=" * 70)
    print("🚀 EXHAUSTIVE DATA ENRICHMENT PIPELINE FOR WOW FOREVER")
    print("=" * 70)

    if not os.path.exists(SQL_FILE):
        print(f"Error: SQL file missing: {SQL_FILE}")
        sys.exit(1)

    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()

    # Ensure required columns exist on items
    for col, col_type in [("bonding", "TEXT"), ("sell_price", "TEXT")]:
        try:
            cur.execute(f"ALTER TABLE items ADD COLUMN {col} {col_type}")
        except sqlite3.OperationalError:
            pass

    # Ensure required columns exist on quests
    for col, col_type in [("details", "TEXT"), ("completion_text", "TEXT")]:
        try:
            cur.execute(f"ALTER TABLE quests ADD COLUMN {col} {col_type}")
        except sqlite3.OperationalError:
            pass

    # Preload item names for quest reward formatting
    cur.execute("SELECT id, name FROM items")
    item_id_to_name = dict(cur.fetchall())
    print(f"[*] Loaded {len(item_id_to_name):,} item names for reference mapping.")

    # Preload loot table to find top creature drops per item
    cur.execute("""
        SELECT l.item_id, c.name, c.zone, l.drop_chance
        FROM loot l
        JOIN creatures c ON l.creature_id = c.id
        ORDER BY l.item_id, l.drop_chance DESC
    """)
    item_drop_sources = {}
    for i_id, c_name, c_zone, drop_pct in cur.fetchall():
        if i_id not in item_drop_sources and drop_pct >= 0.05:
            pct_str = f"{drop_pct:.1f}%" if drop_pct >= 1 else f"{drop_pct:.2f}%"
            zone_str = f" ({c_zone})" if c_zone and c_zone != "Various" else ""
            item_drop_sources[i_id] = f"Dropped by: {c_name}{zone_str} ({pct_str})"
    print(f"[*] Indexed {len(item_drop_sources):,} confirmed creature drop sources.")

    # Preload vendor wares
    cur.execute("SELECT npc_name, zone, coordinates, item_name FROM vendors")
    vendor_sources = {}
    for v_name, v_zone, v_coords, i_name in cur.fetchall():
        if i_name and i_name not in vendor_sources:
            coord_str = f" [{v_coords}]" if v_coords else ""
            zone_str = f" ({v_zone})" if v_zone else ""
            vendor_sources[i_name] = f"Sold by: {v_name}{zone_str}{coord_str}"
    print(f"[*] Indexed {len(vendor_sources):,} confirmed vendor item sources.")

    print("\n[*] Streaming ground-truth SQL dump (world_full_14_june_2021.sql)...")

    item_updates = []
    quest_updates = []
    creature_updates = []
    quest_item_rewards = {} # item_id -> "Quest: <Title> (<Zone>)"

    current_table = None
    line_count = 0

    with open(SQL_FILE, "r", encoding="utf-8", errors="ignore") as f:
        for line in f:
            line_count += 1
            if line_count % 100000 == 0:
                print(f"    ... processed {line_count:,} SQL lines ...")

            if "INSERT INTO `item_template`" in line:
                current_table = "item_template"
                continue
            elif "INSERT INTO `quest_template`" in line:
                current_table = "quest_template"
                continue
            elif "INSERT INTO `creature_template`" in line:
                current_table = "creature_template"
                continue
            elif line.startswith("INSERT INTO") or line.startswith("CREATE TABLE"):
                current_table = None
                continue

            if not current_table or not line.startswith("\t("):
                continue

            # Process ITEM_TEMPLATE
            if current_table == "item_template":
                tokens = parse_sql_row_tokens(line)
                if len(tokens) >= 119:
                    try:
                        entry = int(tokens[0])
                        desc = tokens[5].strip()
                        sell_copper = int(tokens[11]) if tokens[11].isdigit() else 0
                        delay = int(tokens[47]) if tokens[47].isdigit() else 0
                        dmg_min = float(tokens[50]) if tokens[50].replace(".", "", 1).isdigit() else 0
                        dmg_max = float(tokens[51]) if tokens[51].replace(".", "", 1).isdigit() else 0
                        block = int(tokens[65]) if tokens[65].isdigit() else 0
                        armor = int(tokens[66]) if tokens[66].isdigit() else 0
                        bonding = int(tokens[108]) if tokens[108].isdigit() else 0
                        durability = int(tokens[118]) if tokens[118].isdigit() else 0

                        # Collect stats
                        stat_parts = []
                        if dmg_max > 0:
                            spd = delay / 1000.0 if delay > 0 else 2.0
                            dps = ((dmg_min + dmg_max) / 2.0) / spd if spd > 0 else 0
                            stat_parts.append(f"{int(dmg_min)} - {int(dmg_max)} Damage (Speed {spd:.2f}) ({dps:.1f} DPS)")

                        if armor > 0:
                            stat_parts.append(f"{armor} Armor")
                        if block > 0:
                            stat_parts.append(f"{block} Block")

                        attr_parts = []
                        for s_idx in (27, 29, 31, 33, 35, 37, 39, 41, 43, 45):
                            try:
                                s_type = int(tokens[s_idx])
                                s_val = int(tokens[s_idx + 1])
                                if s_type in STAT_NAMES and s_val != 0:
                                    sign = "+" if s_val > 0 else ""
                                    attr_parts.append(f"{sign}{s_val} {STAT_NAMES[s_type]}")
                            except:
                                pass
                        if attr_parts:
                            stat_parts.append(", ".join(attr_parts))

                        # Resistances
                        res_parts = []
                        res_names = [(67, "Holy"), (68, "Fire"), (69, "Nature"), (70, "Frost"), (71, "Shadow"), (72, "Arcane")]
                        for r_idx, r_name in res_names:
                            try:
                                r_val = int(tokens[r_idx])
                                if r_val > 0:
                                    res_parts.append(f"+{r_val} {r_name} Resistance")
                            except:
                                pass
                        if res_parts:
                            stat_parts.append(", ".join(res_parts))

                        if durability > 0:
                            stat_parts.append(f"{durability} / {durability} Durability")

                        stats_str = " • ".join(stat_parts)
                        bonding_str = BONDING_NAMES.get(bonding, "")
                        sell_str = format_money(sell_copper)

                        item_updates.append((entry, desc, stats_str, bonding_str, sell_str))
                    except Exception:
                        pass

            # Process QUEST_TEMPLATE
            elif current_table == "quest_template":
                tokens = parse_sql_row_tokens(line)
                if len(tokens) >= 106:
                    try:
                        q_id = int(tokens[0])
                        title = tokens[4].strip()
                        details = tokens[5].strip()
                        objectives = tokens[6].strip()
                        offer_reward = tokens[33].strip()
                        choice_items = []
                        for ci_idx in (68, 69, 70, 71, 72, 73):
                            try:
                                ci = int(tokens[ci_idx])
                                if ci > 0:
                                    choice_items.append(ci)
                            except:
                                pass
                        rew_items = []
                        for ri_idx in (80, 81, 82, 83):
                            try:
                                ri = int(tokens[ri_idx])
                                if ri > 0:
                                    rew_items.append(ri)
                            except:
                                pass

                        rew_xp = int(tokens[98]) if tokens[98].isdigit() else 0
                        rew_money = int(tokens[99]) if tokens[99].isdigit() else 0

                        # Map item rewards to this quest
                        for iid in choice_items + rew_items:
                            if iid not in quest_item_rewards:
                                quest_item_rewards[iid] = f"Quest Reward: {title}"

                        # Build rewards text
                        rew_components = []
                        if choice_items:
                            names = [f"[{item_id_to_name.get(iid, f'Item #{iid}')}]" for iid in choice_items]
                            rew_components.append("Choice of: " + ", ".join(names))
                        if rew_items:
                            names = [f"[{item_id_to_name.get(iid, f'Item #{iid}')}]" for iid in rew_items]
                            rew_components.append("Reward: " + ", ".join(names))
                        if rew_xp > 0:
                            rew_components.append(f"{rew_xp:,} XP")
                        if rew_money > 0:
                            rew_components.append(format_money(rew_money))

                        final_rewards = " • ".join(rew_components)
                        quest_updates.append((q_id, details, objectives, offer_reward, final_rewards))
                    except Exception:
                        pass

            # Process CREATURE_TEMPLATE
            elif current_table == "creature_template":
                tokens = parse_sql_row_tokens(line)
                if len(tokens) >= 26:
                    try:
                        cid = int(tokens[0])
                        subname = tokens[17].strip()
                        hp_min = int(tokens[21]) if tokens[21].isdigit() else 0
                        hp_max = int(tokens[22]) if tokens[22].isdigit() else 0
                        avg_hp = (hp_min + hp_max) // 2 if hp_max > 0 else hp_min

                        sub_clean = subname.strip("'\"") if subname != "NULL" else ""
                        if sub_clean:
                            sub_clean = f"<{sub_clean}>"

                        creature_updates.append((cid, sub_clean, avg_hp))
                    except Exception:
                        pass

    print(f"\n[*] Parsing complete!")
    print(f"    - Parsed {len(item_updates):,} items from ground-truth item_template.")
    print(f"    - Parsed {len(quest_updates):,} quests with item rewards.")
    print(f"    - Parsed {len(creature_updates):,} creatures with subnames/health.")

    # 1. Update items in wow_forever.db
    print("\n[*] Applying comprehensive item enrichments to wow_forever.db...")
    item_rows = 0
    for entry, desc, stats_str, bonding_str, sell_str in item_updates:
        # Resolve source
        resolved_source = None
        if entry in quest_item_rewards:
            resolved_source = quest_item_rewards[entry]
        elif entry in item_drop_sources:
            resolved_source = item_drop_sources[entry]

        # Get existing item row
        cur.execute("SELECT name, source, stats, description FROM items WHERE id = ?", (entry,))
        existing = cur.fetchone()
        if existing:
            ex_name, ex_source, ex_stats, ex_desc = existing

            if not resolved_source:
                if ex_name in vendor_sources:
                    resolved_source = vendor_sources[ex_name]
                elif ex_source and ex_source != "World Drop / Various" and ex_source != "World Drop":
                    resolved_source = ex_source
                else:
                    resolved_source = "World Drop across Azeroth"

            final_stats = stats_str if stats_str else (ex_stats or "")
            final_desc = desc if desc else (ex_desc or "")

            cur.execute("""
                UPDATE items
                SET stats = ?,
                    description = ?,
                    source = ?,
                    bonding = ?,
                    sell_price = ?
                WHERE id = ?
            """, (final_stats, final_desc, resolved_source, bonding_str, sell_str, entry))
            item_rows += 1

    conn.commit()
    print(f"    -> Successfully enriched {item_rows:,} items with authentic stats, sources, and sell values!")

    # 2. Update quests in wow_forever.db
    print("\n[*] Applying quest rewards and full texts to wow_forever.db...")
    quest_rows = 0
    for q_id, details, objectives, offer_reward, final_rewards in quest_updates:
        cur.execute("SELECT zone FROM quests WHERE id = ?", (q_id,))
        row = cur.fetchone()
        if row:
            clean_det = details if details else offer_reward
            clean_comp = offer_reward
            if final_rewards:
                cur.execute("""
                    UPDATE quests
                    SET rewards = ?,
                        details = CASE WHEN (details IS NULL OR details = '') THEN ? ELSE details END,
                        completion_text = CASE WHEN (completion_text IS NULL OR completion_text = '') THEN ? ELSE completion_text END
                    WHERE id = ?
                """, (final_rewards, clean_det, clean_comp, q_id))
            quest_rows += 1

    conn.commit()
    print(f"    -> Successfully enriched {quest_rows:,} quests with item reward lists!")

    # 3. Update creatures in wow_forever.db
    print("\n[*] Applying creature subnames and health to wow_forever.db...")
    c_rows = 0
    for cid, sub_clean, avg_hp in creature_updates:
        if sub_clean or avg_hp > 0:
            cur.execute("SELECT location_details, health FROM creatures WHERE id = ?", (cid,))
            ex = cur.fetchone()
            if ex:
                ex_loc, ex_hp = ex
                new_loc = ex_loc
                if sub_clean and (not ex_loc or ex_loc == "" or ex_loc.startswith("<")):
                    new_loc = sub_clean
                new_hp = avg_hp if avg_hp > 0 else ex_hp
                cur.execute("UPDATE creatures SET location_details = ?, health = ? WHERE id = ?", (new_loc, new_hp, cid))
                c_rows += 1

    conn.commit()
    print(f"    -> Successfully enriched {c_rows:,} creatures with subnames and health!")

    conn.close()
    print("\n" + "=" * 70)
    print("✅ DATABASE ENRICHMENT COMPLETE! PROCEEDING TO LUA EXPORT.")
    print("=" * 70)


if __name__ == "__main__":
    main()
