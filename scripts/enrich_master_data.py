#!/usr/bin/env python3
"""
scripts/enrich_master_data.py

Master data compilation and enrichment script for Warcraft Forever:
- Ingests 26,369 item JSONs from scratch/ground_truth/forever_cache/item/
  extracting official Blizzard icons, Equip effects, Use effects, Chance on Hit, and Set bonuses.
- Ingests 10,152 NPC JSONs from scratch/ground_truth/forever_cache/npc/
  extracting exact pinpoint zone coordinates.
- Ingests ItemSet.csv for official item set names and tier associations.
- Ingests world_full_14_june_2021.sql for ground-truth stats, damage, delay, armor, block,
  resistances, durability, bonding, sell prices, quest dialogs, item rewards, and NPC subnames.
- Enriches wow_forever.db with 100% Blizzard-accurate details.
"""

import os
import sys
import re
import csv
import json
import sqlite3

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DB_PATH = os.path.join(BASE_DIR, "wow_forever.db")
SQL_FILE = os.path.join(BASE_DIR, "scratch", "ground_truth", "world_full_14_june_2021.sql")
CACHE_DIR = os.path.join(BASE_DIR, "scratch", "ground_truth", "forever_cache")
CLIENT_DIR = os.path.join(BASE_DIR, "scratch", "ground_truth", "forever_client", "1.60.1.70685")

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


def clean_tooltip_effects(html: str) -> str:
    if not html:
        return ""
    text = re.sub(r"<br\s*/?>", "\n", html)
    text = re.sub(r"</tr>", "\n", text)
    text = re.sub(r"<[^>]+>", "", text)
    text = text.replace("&nbsp;", " ").replace("&quot;", "\"").replace("&apos;", "'")
    lines = [l.strip() for l in text.split("\n") if l.strip()]
    effects = []
    for l in lines:
        if (l.startswith("Equip:") or l.startswith("Use:") or l.startswith("Chance on hit:") or l.startswith("Set:") or l.startswith("Classes:") or l.startswith("Requires: Race")) and not l.startswith("Requires Level"):
            effects.append(l)
    return " • ".join(effects)


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
    print("🌟 MASTER DATA COMPILATION & ENRICHMENT PIPELINE")
    print("=" * 70)

    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()

    # Ensure required columns exist on items
    item_cols = [
        ("bonding", "TEXT"),
        ("sell_price", "TEXT"),
        ("icon", "TEXT"),
        ("effects", "TEXT"),
        ("item_set", "TEXT")
    ]
    for col, col_type in item_cols:
        try:
            cur.execute(f"ALTER TABLE items ADD COLUMN {col} {col_type}")
        except sqlite3.OperationalError:
            pass

    # Ensure required columns exist on creatures
    creature_cols = [
        ("coords", "TEXT")
    ]
    for col, col_type in creature_cols:
        try:
            cur.execute(f"ALTER TABLE creatures ADD COLUMN {col} {col_type}")
        except sqlite3.OperationalError:
            pass

    # Ensure required columns exist on quests
    quest_cols = [
        ("details", "TEXT"),
        ("completion_text", "TEXT")
    ]
    for col, col_type in quest_cols:
        try:
            cur.execute(f"ALTER TABLE quests ADD COLUMN {col} {col_type}")
        except sqlite3.OperationalError:
            pass

    # 1. Parse ItemSet.csv
    item_to_set = {}
    item_set_csv = os.path.join(CLIENT_DIR, "ItemSet.csv")
    if os.path.exists(item_set_csv):
        print("[*] Parsing ItemSet.csv for set affiliations...")
        with open(item_set_csv, "r", encoding="utf-8", errors="ignore") as f:
            reader = csv.reader(f)
            header = next(reader)
            for row in reader:
                if len(row) > 5:
                    set_name = row[1].strip("\" ")
                    for col_val in row[5:]:
                        try:
                            iid = int(col_val)
                            if iid > 0:
                                item_to_set[iid] = set_name
                        except:
                            pass
        print(f"    -> Mapped {len(item_to_set):,} items to official item sets.")

    # 2. Parse forever_cache/item for icons and effects
    cache_item_dir = os.path.join(CACHE_DIR, "item")
    item_cache_data = {} # id -> (icon, effects)
    if os.path.exists(cache_item_dir):
        print(f"[*] Parsing {len(os.listdir(cache_item_dir)):,} item JSONs from cache for icons and effects...")
        for fname in os.listdir(cache_item_dir):
            if fname.endswith(".json"):
                try:
                    iid = int(fname[:-5])
                    with open(os.path.join(cache_item_dir, fname), "r", encoding="utf-8", errors="ignore") as fp:
                        d = json.load(fp)
                        icon = d.get("icon", "")
                        effects = clean_tooltip_effects(d.get("tooltip", ""))
                        if icon or effects:
                            item_cache_data[iid] = (icon, effects)
                except:
                    pass
        print(f"    -> Extracted Blizzard icons/effects for {len(item_cache_data):,} items.")

    # 3. Parse forever_cache/npc for coordinates
    cache_npc_dir = os.path.join(CACHE_DIR, "npc")
    npc_coords_data = {} # cid -> "XX.X, YY.Y"
    if os.path.exists(cache_npc_dir):
        print(f"[*] Parsing {len(os.listdir(cache_npc_dir)):,} NPC JSONs from cache for map coordinates...")
        for fname in os.listdir(cache_npc_dir):
            if fname.endswith(".json"):
                try:
                    cid = int(fname[:-5])
                    with open(os.path.join(cache_npc_dir, fname), "r", encoding="utf-8", errors="ignore") as fp:
                        d = json.load(fp)
                        m = d.get("map")
                        if m and isinstance(m, dict) and m.get("coords"):
                            coords_dict = m["coords"]
                            if coords_dict:
                                first_key = list(coords_dict.keys())[0]
                                pts = coords_dict[first_key]
                                if pts and len(pts) > 0:
                                    first_pt = pts[0]
                                    npc_coords_data[cid] = f"{first_pt[0]:.1f}, {first_pt[1]:.1f}"
                except:
                    pass
        print(f"    -> Extracted pinpoint coordinates for {len(npc_coords_data):,} NPCs.")

    # 4. Stream world_full_14_june_2021.sql for ground truth stats, quests, loot, creatures
    print("[*] Preloading database reference tables...")
    cur.execute("SELECT id, name FROM items")
    item_id_to_name = dict(cur.fetchall())

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

    cur.execute("SELECT npc_name, zone, coordinates, item_name FROM vendors")
    vendor_sources = {}
    for v_name, v_zone, v_coords, i_name in cur.fetchall():
        if i_name and i_name not in vendor_sources:
            coord_str = f" [{v_coords}]" if v_coords else ""
            zone_str = f" ({v_zone})" if v_zone else ""
            vendor_sources[i_name] = f"Sold by: {v_name}{zone_str}{coord_str}"

    print("[*] Streaming ground-truth SQL dump (world_full_14_june_2021.sql)...")
    item_sql_data = {}     # entry -> (desc, stats_str, bonding_str, sell_str)
    quest_sql_data = {}    # q_id -> (details, objectives, offer_reward, final_rewards)
    creature_sql_data = {} # cid -> (sub_clean, avg_hp)
    quest_item_rewards = {}# iid -> "Quest: <Title>"

    current_table = None
    line_count = 0

    with open(SQL_FILE, "r", encoding="utf-8", errors="ignore") as f:
        for line in f:
            line_count += 1
            if line_count % 150000 == 0:
                print(f"    ... scanned {line_count:,} SQL lines ...")

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

            # Parse ITEM_TEMPLATE
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

                        item_sql_data[entry] = (desc, stats_str, bonding_str, sell_str)
                    except:
                        pass

            # Parse QUEST_TEMPLATE
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
                                if ci > 0: choice_items.append(ci)
                            except:
                                pass

                        rew_items = []
                        for ri_idx in (80, 81, 82, 83):
                            try:
                                ri = int(tokens[ri_idx])
                                if ri > 0: rew_items.append(ri)
                            except:
                                pass

                        rew_xp = int(tokens[98]) if tokens[98].isdigit() else 0
                        rew_money = int(tokens[99]) if tokens[99].isdigit() else 0

                        for iid in choice_items + rew_items:
                            if iid not in quest_item_rewards:
                                quest_item_rewards[iid] = f"Quest Reward: {title}"

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
                        quest_sql_data[q_id] = (details, objectives, offer_reward, final_rewards)
                    except:
                        pass

            # Parse CREATURE_TEMPLATE
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

                        creature_sql_data[cid] = (sub_clean, avg_hp)
                    except:
                        pass

    print("[*] Stream complete. Updating SQLite database tables...")

    # UPDATE ITEMS
    cur.execute("SELECT id, name, source, stats, description FROM items")
    all_db_items = cur.fetchall()
    print(f"[*] Updating {len(all_db_items):,} items in wow_forever.db...")

    item_update_batch = []
    for i_id, name, ex_source, ex_stats, ex_desc in all_db_items:
        # SQL values
        sql_info = item_sql_data.get(i_id, ("", "", "", ""))
        sql_desc, sql_stats, sql_bonding, sql_sell = sql_info

        # Cache values (icon, effects)
        cache_info = item_cache_data.get(i_id, ("", ""))
        cache_icon, cache_effects = cache_info

        # Set affiliation
        set_name = item_to_set.get(i_id, "")

        # Source resolution
        resolved_source = None
        if i_id in quest_item_rewards:
            resolved_source = quest_item_rewards[i_id]
        elif i_id in item_drop_sources:
            resolved_source = item_drop_sources[i_id]
        elif name in vendor_sources:
            resolved_source = vendor_sources[name]
        elif ex_source and ex_source != "World Drop / Various" and ex_source != "World Drop":
            resolved_source = ex_source
        else:
            resolved_source = "World Drop across Azeroth"

        final_stats = sql_stats if sql_stats else (ex_stats or "")
        final_desc = sql_desc if sql_desc else (ex_desc or "")

        item_update_batch.append((
            final_stats,
            final_desc,
            resolved_source,
            sql_bonding,
            sql_sell,
            cache_icon,
            cache_effects,
            set_name,
            i_id
        ))

    cur.executemany("""
        UPDATE items
        SET stats = ?,
            description = ?,
            source = ?,
            bonding = ?,
            sell_price = ?,
            icon = ?,
            effects = ?,
            item_set = ?
        WHERE id = ?
    """, item_update_batch)
    conn.commit()
    print(f"    -> Successfully updated {len(item_update_batch):,} items with icons, effects, stats, and sets.")

    # UPDATE CREATURES
    cur.execute("SELECT id, location_details, health FROM creatures")
    all_db_creatures = cur.fetchall()
    print(f"[*] Updating {len(all_db_creatures):,} creatures in wow_forever.db...")

    creature_update_batch = []
    for cid, ex_loc, ex_hp in all_db_creatures:
        sql_sub, sql_hp = creature_sql_data.get(cid, ("", 0))
        cache_coords = npc_coords_data.get(cid, "")

        new_loc = ex_loc
        if sql_sub and (not ex_loc or ex_loc == "" or ex_loc.startswith("<")):
            new_loc = sql_sub

        new_hp = sql_hp if sql_hp > 0 else ex_hp

        creature_update_batch.append((
            new_loc,
            new_hp,
            cache_coords,
            cid
        ))

    cur.executemany("""
        UPDATE creatures
        SET location_details = ?,
            health = ?,
            coords = ?
        WHERE id = ?
    """, creature_update_batch)
    conn.commit()
    print(f"    -> Successfully updated {len(creature_update_batch):,} creatures with subnames, health, and coords.")

    # UPDATE QUESTS
    print(f"[*] Updating quests with item rewards and dialogue...")
    quest_update_batch = []
    for q_id, (details, objectives, offer_reward, final_rewards) in quest_sql_data.items():
        clean_det = details if details else offer_reward
        clean_comp = offer_reward
        quest_update_batch.append((
            final_rewards,
            clean_det,
            clean_comp,
            q_id
        ))

    cur.executemany("""
        UPDATE quests
        SET rewards = CASE WHEN ? != '' THEN ? ELSE rewards END,
            details = CASE WHEN (details IS NULL OR details = '') THEN ? ELSE details END,
            completion_text = CASE WHEN (completion_text IS NULL OR completion_text = '') THEN ? ELSE completion_text END
        WHERE id = ?
    """, [(r, r, d, c, q) for (r, d, c, q) in quest_update_batch])
    conn.commit()
    print(f"    -> Successfully updated {len(quest_update_batch):,} quests with ground truth reward structures.")

    conn.close()
    print("\n" + "=" * 70)
    print("✅ MASTER DATA ENRICHMENT COMPLETE")
    print("=" * 70)


if __name__ == "__main__":
    main()
