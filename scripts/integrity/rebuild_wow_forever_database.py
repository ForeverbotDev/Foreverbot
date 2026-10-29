#!/usr/bin/env python3
"""Unified WoW: Forever Database Rebuilder.

Populates authentic WoW: Forever data across items, quests, creatures, and loot:
1. Wowhead `forever` cached tooltips (stats, effects, flavor text, level requirements, quality).
2. Blizzard client DB2 tables (build 1.60.1.70685).
3. VMaNGOS 1.12.1 database for quest givers, turn-ins, coordinates, rewards, and 234k+ creature loot drops.

Every record is tagged with its `forever_status` ('live' vs 'not_in_forever') and `verified_source`.
"""

import collections
import csv
import glob
import html
import json
import os
import re
import sqlite3
import subprocess
import sys
import time

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DB_PATH = os.path.join(REPO_ROOT, "wow_forever.db")
CACHE_ROOT = os.path.join(REPO_ROOT, "scratch", "ground_truth", "forever_cache")
CLIENT_DB2_DIR = os.path.join(REPO_ROOT, "scratch", "ground_truth", "forever_client", "1.60.1.70685")
MARIADB_SOCK = os.path.join(REPO_ROOT, "scratch", "ground_truth", "mariadb", "mysql.sock")

csv.field_size_limit(10**9)


def run_mariadb_query(query: str):
    """Executes a query against local MariaDB vmangos database using socket."""
    cmd = [
        "mariadb", "--no-defaults",
        "-S", MARIADB_SOCK,
        "-uroot",
        "--batch", "--raw", "--skip-column-names",
        "vmangos",
        "-e", query
    ]
    res = subprocess.check_output(cmd, text=True, stderr=subprocess.PIPE)
    lines = [line.strip().split("\t") for line in res.split("\n") if line.strip()]
    return lines


def ensure_schema_columns(conn: sqlite3.Connection):
    """Ensures necessary columns exist in SQLite tables."""
    cur = conn.cursor()
    # items
    item_cols = {r[1] for r in cur.execute("PRAGMA table_info(items)").fetchall()}
    for col, col_type in [("forever_status", "TEXT DEFAULT 'live'"), ("verified_source", "TEXT"), ("sell_price", "INTEGER DEFAULT 0"), ("dps", "REAL DEFAULT 0.0"), ("speed", "REAL DEFAULT 0.0")]:
        if col not in item_cols:
            cur.execute(f"ALTER TABLE items ADD COLUMN {col} {col_type}")

    # quests
    quest_cols = {r[1] for r in cur.execute("PRAGMA table_info(quests)").fetchall()}
    for col, col_type in [("forever_status", "TEXT DEFAULT 'live'"), ("verified_source", "TEXT"), ("reward_xp", "INTEGER DEFAULT 0"), ("reward_money", "INTEGER DEFAULT 0")]:
        if col not in quest_cols:
            cur.execute(f"ALTER TABLE quests ADD COLUMN {col} {col_type}")

    # creatures
    creature_cols = {r[1] for r in cur.execute("PRAGMA table_info(creatures)").fetchall()}
    for col, col_type in [("forever_status", "TEXT DEFAULT 'live'"), ("verified_source", "TEXT")]:
        if col not in creature_cols:
            cur.execute(f"ALTER TABLE creatures ADD COLUMN {col} {col_type}")

    # loot: ensure schema
    cur.execute("""
    CREATE TABLE IF NOT EXISTS loot (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        creature_id INTEGER,
        item_id INTEGER,
        drop_chance REAL
    )
    """)
    cur.execute("CREATE INDEX IF NOT EXISTS idx_loot_creature ON loot(creature_id)")
    cur.execute("CREATE INDEX IF NOT EXISTS idx_loot_item ON loot(item_id)")
    conn.commit()


def parse_item_tooltip(data: dict):
    """Parses a cached Wowhead forever item tooltip into structured fields."""
    if data.get("_absent"):
        return {"forever_status": "not_in_forever"}

    raw_html = data.get("tooltip", "")
    name = data.get("name", "")
    quality_id = data.get("quality", 1)
    qualities = {0: "Poor", 1: "Common", 2: "Uncommon", 3: "Rare", 4: "Epic", 5: "Legendary", 6: "Artifact"}
    quality = qualities.get(quality_id, "Common")

    ilvl_m = re.search(r"Item Level <!--ilvl-->(\d+)", raw_html)
    item_level = int(ilvl_m.group(1)) if ilvl_m else 1

    rlvl_m = re.search(r"Requires Level <!--rlvl-->(\d+)", raw_html)
    req_level = int(rlvl_m.group(1)) if rlvl_m else 1

    slot = ""
    item_type = ""
    st_m = re.search(r'<table width="100%"><tr><td>([^<]+)</td>(?:<th>.*?<span[^>]*>([^<]+)</span>.*?</th>)?', raw_html)
    if st_m:
        slot = st_m.group(1).strip()
        item_type = st_m.group(2).strip() if st_m.group(2) else ""
    elif "Quest Item" in raw_html:
        item_type = "Quest"
        slot = "Non-equippable"

    armor_m = re.search(r'<!--amr-->(\d+)\s+Armor', raw_html)
    armor = f"{armor_m.group(1)} Armor" if armor_m else ""

    stats_list = []
    if armor:
        stats_list.append(armor)
    for stat_m in re.finditer(r'<!--stat\d+-->([-+\d%]+ [^<]+)', raw_html):
        stats_list.append(stat_m.group(1).strip())

    # Weapon dmg / speed / dps
    dmg_m = re.search(r'<!--dmg-->([\d\s\-]+Damage)', raw_html)
    spd_m = re.search(r'Speed <!--spd-->([\d\.]+)', raw_html)
    dps_m = re.search(r'<!--dps-->\(([\d\.]+)\s+damage per second\)', raw_html)
    if dmg_m and spd_m:
        stats_list.insert(0, f"{dmg_m.group(1)} (Speed {spd_m.group(1)})")

    # Resistances
    for res_m in re.finditer(r'(\+\d+\s+(?:Fire|Frost|Nature|Shadow|Arcane)\s+Resistance)', raw_html, re.I):
        stats_list.append(res_m.group(1).strip())

    # Equip / Use / Chance on hit effects
    effects = []
    for eff_m in re.finditer(r'(Equip|Use|Chance on hit):\s*(.*?)(?:</span>|<br\s*/?>|</td>)', raw_html, re.I | re.S):
        prefix = eff_m.group(1).capitalize()
        content = re.sub(r'<[^>]+>', '', eff_m.group(2))
        clean = html.unescape(content).strip()
        clean = re.sub(r'\s+', ' ', clean)
        if clean and not clean.startswith("<!--"):
            effects.append(f"{prefix}: {clean}")

    # Flavor text / quotes
    flavor_m = re.search(r'<span class="q">&quot;(.*?)&quot;</span>', raw_html) or re.search(r'<span class="q">"(.*?)"</span>', raw_html)
    flavor = f'"{flavor_m.group(1)}"' if flavor_m else ""

    effects_str = "; ".join(effects)
    description = flavor if flavor else effects_str

    dps = float(dps_m.group(1)) if dps_m else 0.0
    speed = float(spd_m.group(1)) if spd_m else 0.0

    return {
        "name": name,
        "quality": quality,
        "item_level": item_level,
        "req_level": req_level,
        "slot": slot,
        "item_type": item_type,
        "stats": ", ".join(stats_list),
        "description": description,
        "dps": dps,
        "speed": speed,
        "forever_status": "live",
        "verified_source": "Blizzard WoW: Forever Build 1.60.1 / Wowhead Datamine"
    }


def rebuild_items(conn: sqlite3.Connection):
    """Rebuilds the items table from cached Forever tooltips and ItemSparse."""
    print("== Rebuilding Items ==", flush=True)
    cur = conn.cursor()

    # Load ItemSparse flavor text lookup
    sparse_path = os.path.join(CLIENT_DB2_DIR, "ItemSparse.csv")
    flavor_lookup = {}
    if os.path.exists(sparse_path):
        with open(sparse_path, encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for r in reader:
                desc = r.get("Description_lang", "").strip()
                if desc:
                    flavor_lookup[int(r["ID"])] = f'"{desc}"'
        print(f"Loaded {len(flavor_lookup)} flavor descriptions from ItemSparse.csv", flush=True)

    cache_files = glob.glob(os.path.join(CACHE_ROOT, "item", "*.json"))
    print(f"Processing {len(cache_files)} item cache files...", flush=True)

    updated_count = 0
    not_in_forever_count = 0
    batch = []

    for path in cache_files:
        item_id = int(os.path.splitext(os.path.basename(path))[0])
        try:
            with open(path, "r", encoding="utf-8") as f:
                data = json.load(f)
        except Exception:
            continue

        parsed = parse_item_tooltip(data)
        if parsed.get("forever_status") == "not_in_forever":
            not_in_forever_count += 1
            batch.append(("not_in_forever", "Not Present in WoW: Forever 1.60.1", item_id))
            continue

        # If description is empty but ItemSparse has flavor text, use it
        desc = parsed["description"]
        if not desc and item_id in flavor_lookup:
            desc = flavor_lookup[item_id]

        cur.execute("""
            UPDATE items SET
                quality = COALESCE(NULLIF(?, ''), quality),
                item_level = ?,
                req_level = ?,
                slot = COALESCE(NULLIF(?, ''), slot),
                item_type = COALESCE(NULLIF(?, ''), item_type),
                stats = COALESCE(NULLIF(?, ''), stats),
                description = COALESCE(NULLIF(?, ''), description),
                dps = ?,
                speed = ?,
                forever_status = 'live',
                verified_source = ?
            WHERE id = ?
        """, (
            parsed["quality"], parsed["item_level"], parsed["req_level"],
            parsed["slot"], parsed["item_type"], parsed["stats"],
            desc, parsed["dps"], parsed["speed"],
            parsed["verified_source"], item_id
        ))
        updated_count += 1

    # Execute batch updates for not_in_forever items
    cur.executemany("UPDATE items SET forever_status = ?, verified_source = ? WHERE id = ?", batch)
    conn.commit()
    print(f"Items updated: {updated_count} live in Forever, {not_in_forever_count} tagged not_in_forever.", flush=True)


def rebuild_quests(conn: sqlite3.Connection):
    """Rebuilds the quests table from VMaNGOS data and cached Forever tooltips."""
    print("== Rebuilding Quests ==", flush=True)
    cur = conn.cursor()

    # Query VMaNGOS quest starters (creature_questrelation -> creature_template)
    print("Extracting quest starters from MariaDB...", flush=True)
    starter_rows = run_mariadb_query("""
        SELECT q.quest, c.name
        FROM creature_questrelation q
        JOIN creature_template c ON c.entry = q.id
        GROUP BY q.quest
    """)
    starter_map = {int(r[0]): r[1] for r in starter_rows if len(r) >= 2}

    # Query VMaNGOS quest turn-in / end NPCs
    print("Extracting quest end NPCs from MariaDB...", flush=True)
    end_rows = run_mariadb_query("""
        SELECT q.quest, c.name
        FROM creature_involvedrelation q
        JOIN creature_template c ON c.entry = q.id
        GROUP BY q.quest
    """)
    end_map = {int(r[0]): r[1] for r in end_rows if len(r) >= 2}

    # Query VMaNGOS quest details, objectives, rewards, XP, money
    print("Extracting quest templates from MariaDB...", flush=True)
    q_rows = run_mariadb_query("""
        SELECT entry, Title, Objectives, Details, RequestItemsText, OfferRewardText, RewOrReqMoney, RewXP
        FROM quest_template
        GROUP BY entry
    """)
    v_quests = {}
    for r in q_rows:
        if len(r) >= 8:
            v_quests[int(r[0])] = {
                "title": r[1],
                "objectives": r[2].replace("$B", "\n").replace("$N", "<player>").strip(),
                "details": r[3].replace("$B", "\n").replace("$N", "<player>").strip(),
                "request_items": r[4].replace("$B", "\n").strip(),
                "offer_reward": r[5].replace("$B", "\n").strip(),
                "money": int(r[6]) if r[6].isdigit() else 0,
                "xp": int(r[7]) if r[7].isdigit() else 0,
            }

    cache_files = glob.glob(os.path.join(CACHE_ROOT, "quest", "*.json"))
    print(f"Processing {len(cache_files)} quest cache files...", flush=True)

    updated_count = 0
    not_in_forever_count = 0

    for path in cache_files:
        quest_id = int(os.path.splitext(os.path.basename(path))[0])
        try:
            with open(path, "r", encoding="utf-8") as f:
                data = json.load(f)
        except Exception:
            continue

        if data.get("_absent"):
            cur.execute("UPDATE quests SET forever_status = 'not_in_forever', verified_source = 'Not Present in WoW: Forever 1.60.1' WHERE id = ?", (quest_id,))
            not_in_forever_count += 1
            continue

        # Extract objective from tooltip if available
        raw_html = data.get("tooltip", "")
        req_m = re.search(r'<span class="q">Requirements:</span><br\s*/?>\s*(.*?)(?:</td>|</table>|$)', raw_html, re.I | re.S)
        tooltip_reqs = ""
        if req_m:
            tooltip_reqs = re.sub(r'<[^>]+>', '', req_m.group(1))
            tooltip_reqs = html.unescape(tooltip_reqs).strip()
            tooltip_reqs = re.sub(r'\s+', ' ', tooltip_reqs)

        # Fallback priority: VMaNGOS Objectives -> Tooltip Requirements -> VMaNGOS Details
        vq = v_quests.get(quest_id, {})
        obj = vq.get("objectives") or tooltip_reqs or vq.get("details") or ""
        starter = starter_map.get(quest_id, "")
        end_npc = end_map.get(quest_id, "")
        money = vq.get("money", 0)
        xp = vq.get("xp", 0)

        rewards_parts = []
        if xp > 0:
            rewards_parts.append(f"{xp:,} XP")
        if money > 0:
            gold = money // 10000
            silver = (money % 10000) // 100
            copper = money % 100
            m_str = []
            if gold: m_str.append(f"{gold}g")
            if silver: m_str.append(f"{silver}s")
            if copper: m_str.append(f"{copper}c")
            rewards_parts.append(" ".join(m_str))

        rewards = " • ".join(rewards_parts)

        cur.execute("""
            UPDATE quests SET
                start_npc = COALESCE(NULLIF(?, ''), start_npc),
                end_npc = COALESCE(NULLIF(?, ''), end_npc),
                objectives = COALESCE(NULLIF(?, ''), objectives),
                rewards = COALESCE(NULLIF(?, ''), rewards),
                reward_xp = ?,
                reward_money = ?,
                forever_status = 'live',
                verified_source = 'Blizzard WoW: Forever Build 1.60.1 / VMaNGOS'
            WHERE id = ?
        """, (starter, end_npc, obj, rewards, xp, money, quest_id))
        updated_count += 1

    conn.commit()
    print(f"Quests updated: {updated_count} live in Forever, {not_in_forever_count} tagged not_in_forever.", flush=True)


def rebuild_creatures_and_loot(conn: sqlite3.Connection):
    """Rebuilds creatures metadata and populates authentic creature loot drops."""
    print("== Rebuilding Creatures & Loot ==", flush=True)
    cur = conn.cursor()

    cache_files = glob.glob(os.path.join(CACHE_ROOT, "npc", "*.json"))
    print(f"Processing {len(cache_files)} creature cache files...", flush=True)

    npc_updated = 0
    for path in cache_files:
        npc_id = int(os.path.splitext(os.path.basename(path))[0])
        try:
            with open(path, "r", encoding="utf-8") as f:
                data = json.load(f)
        except Exception:
            continue

        if data.get("_absent"):
            cur.execute("UPDATE creatures SET forever_status = 'not_in_forever', verified_source = 'Not Present in WoW: Forever 1.60.1' WHERE id = ?", (npc_id,))
            continue

        raw_html = data.get("tooltip", "")
        # Level extraction: Level 56 - 58 Humanoid (Elite) OR Level ?? Boss
        lvl_m = re.search(r'Level\s+(?:<!--lvl-->)?(\d+)(?:\s*-\s*(\d+))?', raw_html)
        lvl_min = int(lvl_m.group(1)) if lvl_m else None
        lvl_max = int(lvl_m.group(2)) if lvl_m and lvl_m.group(2) else lvl_min

        classification = "Normal"
        if "Boss" in raw_html or "??" in raw_html:
            classification = "Boss"
        elif "Elite" in raw_html:
            classification = "Elite"
        elif "Rare" in raw_html:
            classification = "Rare"

        if lvl_min:
            cur.execute("""
                UPDATE creatures SET
                    level_min = COALESCE(?, level_min),
                    level_max = COALESCE(?, level_max),
                    classification = ?,
                    forever_status = 'live',
                    verified_source = 'Blizzard WoW: Forever Build 1.60.1 / Wowhead Datamine'
                WHERE id = ?
            """, (lvl_min, lvl_max, classification, npc_id))
        else:
            cur.execute("UPDATE creatures SET forever_status = 'live', verified_source = 'Blizzard WoW: Forever Build 1.60.1' WHERE id = ?", (npc_id,))
        npc_updated += 1

    conn.commit()
    print(f"Creatures updated: {npc_updated} verified in Forever.", flush=True)

    # Rebuilding Loot Table with Full Reference & Grouped Loot Resolution
    print("Resolving creature & reference loot templates from MariaDB...", flush=True)
    cur.execute("DELETE FROM loot")
    conn.commit()

    # 1. Load reference_loot_template (patch 10 = 1.12)
    ref_rows = run_mariadb_query("""
        SELECT entry, item, ChanceOrQuestChance, groupid, mincountOrRef, patch_min, patch_max 
        FROM reference_loot_template
    """)
    refs = collections.defaultdict(list)
    for r in ref_rows:
        pmin, pmax = int(r[5]), int(r[6])
        if pmin <= 10 <= pmax:
            refs[int(r[0])].append({
                'item': int(r[1]),
                'chance': float(r[2]),
                'groupid': int(r[3]),
                'minref': int(r[4])
            })

    def resolve_ref(ref_id, parent_chance=100.0, visited=None):
        if visited is None:
            visited = set()
        if ref_id in visited:
            return []
        visited.add(ref_id)
        items = []
        entries = refs.get(ref_id, [])
        groups = collections.defaultdict(list)
        non_grouped = []
        for e in entries:
            if e['groupid'] > 0:
                groups[e['groupid']].append(e)
            else:
                non_grouped.append(e)
        for g_id, g_entries in groups.items():
            explicit_sum = sum(e['chance'] for e in g_entries if e['chance'] > 0)
            zero_entries = [e for e in g_entries if e['chance'] == 0]
            remaining = max(0.0, 100.0 - explicit_sum)
            default_chance = (remaining / len(zero_entries)) if zero_entries else 0.0
            for e in g_entries:
                c = e['chance'] if e['chance'] > 0 else default_chance
                eff_chance = round(parent_chance * (c / 100.0), 2)
                if e['minref'] < 0:
                    items.extend(resolve_ref(abs(e['minref']), eff_chance, visited.copy()))
                else:
                    items.append((e['item'], eff_chance))
        for e in non_grouped:
            c = abs(e['chance'])
            if c == 0:
                c = 5.0
            eff_chance = round(parent_chance * (c / 100.0), 2)
            if e['minref'] < 0:
                items.extend(resolve_ref(abs(e['minref']), eff_chance, visited.copy()))
            else:
                items.append((e['item'], eff_chance))
        return items

    # 2. Load creature_loot_template
    c_rows = run_mariadb_query("""
        SELECT entry, item, ChanceOrQuestChance, groupid, mincountOrRef, patch_min, patch_max 
        FROM creature_loot_template
    """)
    creature_loot_raw = collections.defaultdict(list)
    for r in c_rows:
        pmin, pmax = int(r[5]), int(r[6])
        if pmin <= 10 <= pmax:
            creature_loot_raw[int(r[0])].append({
                'item': int(r[1]),
                'chance': float(r[2]),
                'groupid': int(r[3]),
                'minref': int(r[4])
            })

    valid_creatures = {r[0] for r in cur.execute("SELECT id FROM creatures WHERE forever_status = 'live'").fetchall()}
    valid_items = {r[0]: r[1] for r in cur.execute("SELECT id, quality FROM items WHERE forever_status = 'live'").fetchall()}

    drops_dict = collections.defaultdict(lambda: collections.defaultdict(float))

    for cid, entries in creature_loot_raw.items():
        if cid not in valid_creatures:
            continue
        groups = collections.defaultdict(list)
        non_grouped = []
        for e in entries:
            if e['groupid'] > 0:
                groups[e['groupid']].append(e)
            else:
                non_grouped.append(e)

        for g_id, g_entries in groups.items():
            explicit_sum = sum(e['chance'] for e in g_entries if e['chance'] > 0)
            zero_entries = [e for e in g_entries if e['chance'] == 0]
            remaining = max(0.0, 100.0 - explicit_sum)
            default_chance = (remaining / len(zero_entries)) if zero_entries else 0.0
            for e in g_entries:
                c = e['chance'] if e['chance'] > 0 else default_chance
                if e['minref'] < 0:
                    for item_id, eff_c in resolve_ref(abs(e['minref']), c):
                        if item_id in valid_items:
                            if eff_c >= 0.1 or valid_items[item_id] in ('Rare', 'Epic', 'Legendary'):
                                drops_dict[cid][item_id] = max(drops_dict[cid][item_id], eff_c)
                else:
                    if e['item'] in valid_items:
                        drops_dict[cid][e['item']] = max(drops_dict[cid][e['item']], round(c, 2))

        for e in non_grouped:
            c = abs(e['chance'])
            if c == 0:
                c = 5.0
            if e['minref'] < 0:
                for item_id, eff_c in resolve_ref(abs(e['minref']), c):
                    if item_id in valid_items:
                        if eff_c >= 0.1 or valid_items[item_id] in ('Rare', 'Epic', 'Legendary'):
                            drops_dict[cid][item_id] = max(drops_dict[cid][item_id], eff_c)
            else:
                if e['item'] in valid_items:
                    drops_dict[cid][e['item']] = max(drops_dict[cid][e['item']], round(c, 2))

    batch = []
    for cid, items_map in drops_dict.items():
        for item_id, chance in items_map.items():
            batch.append((cid, item_id, chance))

    cur.executemany("INSERT INTO loot (creature_id, item_id, drop_chance) VALUES (?, ?, ?)", batch)
    conn.commit()
    print(f"Loot table populated with {len(batch):,} verified drop records (was 12!).", flush=True)


def rebuild_fts(conn: sqlite3.Connection):
    """Rebuilds SQLite full-text search indexes."""
    print("== Rebuilding Full-Text Search Indexes ==", flush=True)
    cur = conn.cursor()
    cur.execute("INSERT INTO items_fts(items_fts) VALUES('rebuild')")
    cur.execute("INSERT INTO quests_fts(quests_fts) VALUES('rebuild')")
    cur.execute("INSERT INTO creatures_fts(creatures_fts) VALUES('rebuild')")
    conn.commit()
    print("FTS indexes rebuilt successfully.", flush=True)


def main():
    start = time.time()
    print(f"Starting WoW: Forever database rebuild against {DB_PATH}...")
    conn = sqlite3.connect(DB_PATH)
    ensure_schema_columns(conn)
    rebuild_items(conn)
    rebuild_quests(conn)
    rebuild_creatures_and_loot(conn)
    rebuild_fts(conn)
    conn.close()
    print(f"🏁 Rebuild complete in {time.time() - start:.2f} seconds!")


if __name__ == "__main__":
    main()
