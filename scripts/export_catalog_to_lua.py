#!/usr/bin/env python3
"""
scripts/export_catalog_to_lua.py

Compiles static game data from wow_forever.db and bot.py knowledge modules
into an optimized Lua data file for the in-game World of Warcraft Addon:
ForeverGuide ("The Blue Spark").
"""

import os
import sys
import sqlite3

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, BASE_DIR)
import knowledge_engine as ke

DB_PATH = os.path.join(BASE_DIR, "wow_forever.db")
OUTPUT_DIR = os.path.join(BASE_DIR, "addon", "ForeverGuide")
OUTPUT_FILE = os.path.join(OUTPUT_DIR, "ForeverGuide_Data.lua")


def escape_lua_str(val) -> str:
    if val is None:
        return '""'
    val_str = str(val)
    val_str = val_str.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n').replace('\r', '')
    return f'"{val_str}"'


def py_to_lua(val, indent=0):
    spaces = "  " * indent
    if val is None:
        return "nil"
    elif isinstance(val, bool):
        return "true" if val else "false"
    elif isinstance(val, (int, float)):
        return str(val)
    elif isinstance(val, str):
        return escape_lua_str(val)
    elif isinstance(val, list):
        items = [f"{spaces}  {py_to_lua(x, indent + 1)}," for x in val]
        return "{\n" + "\n".join(items) + "\n" + spaces + "}"
    elif isinstance(val, dict):
        items = []
        for k, v in val.items():
            key_repr = f'["{k}"]' if isinstance(k, str) else f"[{k}]"
            items.append(f"{spaces}  {key_repr} = {py_to_lua(v, indent + 1)},")
        return "{\n" + "\n".join(items) + "\n" + spaces + "}"
    return '""'


def export_dungeons(cursor) -> str:
    cursor.execute("""
        SELECT id, name, level_min, level_max, recommended_level, zone, faction,
               key_bosses, notable_loot, entrance_coords, pro_tip, is_forever_content
        FROM dungeons
        ORDER BY level_min ASC, name ASC
    """)
    rows = cursor.fetchall()
    lua = ["ForeverGuide_Data.Dungeons = {"]
    for r in rows:
        d_id, name, l_min, l_max, rec_lvl, zone, faction, bosses, loot, coords, tip, is_forever = r
        lua.append(f"  [{d_id}] = {{")
        lua.append(f"    id = {d_id},")
        lua.append(f"    name = {escape_lua_str(name)},")
        lua.append(f"    minLevel = {l_min or 0},")
        lua.append(f"    maxLevel = {l_max or 60},")
        lua.append(f"    recLevel = {escape_lua_str(rec_lvl or '')},")
        lua.append(f"    zone = {escape_lua_str(zone or '')},")
        lua.append(f"    faction = {escape_lua_str(faction or 'Both')},")
        lua.append(f"    bosses = {escape_lua_str(bosses or '')},")
        lua.append(f"    notableLoot = {escape_lua_str(loot or '')},")
        lua.append(f"    coords = {escape_lua_str(coords or '')},")
        lua.append(f"    strategy = {escape_lua_str(tip or '')},")
        lua.append(f"    isForever = {'true' if is_forever else 'false'},")
        lua.append("  },")
    lua.append("}\n")
    return "\n".join(lua)


def export_flightpaths(cursor) -> str:
    cursor.execute("""
        SELECT id, name, zone, faction, coordinates, connections, notes, is_forever_content
        FROM flightpaths
        ORDER BY zone ASC, name ASC
    """)
    rows = cursor.fetchall()
    lua = ["ForeverGuide_Data.Flightpaths = {"]
    for r in rows:
        f_id, name, zone, faction, coords, conns, notes, is_forever = r
        lua.append(f"  [{f_id}] = {{")
        lua.append(f"    id = {f_id},")
        lua.append(f"    name = {escape_lua_str(name)},")
        lua.append(f"    zone = {escape_lua_str(zone or '')},")
        lua.append(f"    faction = {escape_lua_str(faction or 'Neutral')},")
        lua.append(f"    coords = {escape_lua_str(coords or '')},")
        lua.append(f"    connections = {escape_lua_str(conns or '')},")
        lua.append(f"    notes = {escape_lua_str(notes or '')},")
        lua.append(f"    isForever = {'true' if is_forever else 'false'},")
        lua.append("  },")
    lua.append("}\n")
    return "\n".join(lua)


def export_vendors(cursor) -> str:
    cursor.execute("""
        SELECT id, npc_name, zone, coordinates, item_name, cost_copper, limited_stock, pro_tip, is_forever_content
        FROM vendors
    """)
    rows = cursor.fetchall()
    lua = ["ForeverGuide_Data.Vendors = {"]
    for r in rows:
        v_id, name, zone, coords, item, cost, stock, tip, is_forever = r
        lua.append(f"  [{v_id}] = {{")
        lua.append(f"    name = {escape_lua_str(name)},")
        lua.append(f"    zone = {escape_lua_str(zone or '')},")
        lua.append(f"    coords = {escape_lua_str(coords or '')},")
        lua.append(f"    item = {escape_lua_str(item or '')},")
        lua.append(f"    cost = {cost or 0},")
        lua.append(f"    limitedStock = {escape_lua_str(stock or '')},")
        lua.append(f"    tip = {escape_lua_str(tip or '')},")
        lua.append(f"    isForever = {'true' if is_forever else 'false'},")
        lua.append("  },")
    lua.append("}\n")
    return "\n".join(lua)


def export_items(cursor) -> str:
    cursor.execute("""
        SELECT id, name, quality, item_level, req_level, slot, item_type, stats, description, source, pro_tip, is_forever_content, bonding, sell_price, icon, effects, item_set
        FROM items
        WHERE name IS NOT NULL AND name != ''
          AND name NOT LIKE '%(test)%'
          AND name NOT LIKE '%(Test)%'
          AND name NOT LIKE 'Test %'
          AND name NOT LIKE '%Martin %'
          AND name NOT LIKE '[PH]%'
          AND name NOT LIKE '%(nyi)%'
          AND name NOT LIKE '%(NYI)%'
          AND name NOT LIKE 'Developer %'
        ORDER BY is_forever_content DESC, quality DESC, item_level DESC
    """)
    rows = cursor.fetchall()
    lua = ["ForeverGuide_Data.Items = ForeverGuide_Data.Items or {}"]
    CHUNK_SIZE = 1000
    for chunk_idx in range(0, len(rows), CHUNK_SIZE):
        chunk_rows = rows[chunk_idx:chunk_idx + CHUNK_SIZE]
        lua.append("(function(t)")
        for r in chunk_rows:
            i_id, name, quality, ilvl, req_lvl, slot, itype, stats, desc, source, tip, is_forever, bonding, sell_price, icon, effects, item_set = r
            clean_source = source or ""
            clean_tip = tip or ""
            clean_source = clean_source.replace("WoW: Forever Open Alpha (Blizzard Build 1.60.1 / Wowhead Datamine)", "World Drop: Creatures and encounters across Azeroth")
            clean_tip = clean_tip.replace("Official Blizzard WoW: Forever content • Documented in Alpha patch notes & client datamine.", f"Official WoW: Forever {quality} {slot or itype}.")
            lua.append(f"  t[{i_id}] = {{")
            lua.append(f"    id = {i_id},")
            lua.append(f"    name = {escape_lua_str(name)},")
            lua.append(f"    quality = {escape_lua_str(quality or 'Common')},")
            lua.append(f"    ilvl = {ilvl or 0},")
            lua.append(f"    reqLvl = {req_lvl or 0},")
            lua.append(f"    slot = {escape_lua_str(slot or '')},")
            lua.append(f"    itemType = {escape_lua_str(itype or '')},")
            lua.append(f"    icon = {escape_lua_str(icon or '')},")
            lua.append(f"    effects = {escape_lua_str(effects or '')},")
            lua.append(f"    itemSet = {escape_lua_str(item_set or '')},")
            lua.append(f"    source = {escape_lua_str(clean_source)},")
            lua.append(f"    stats = {escape_lua_str(stats or '')},")
            lua.append(f"    desc = {escape_lua_str(desc or '')},")
            lua.append(f"    bonding = {escape_lua_str(bonding or '')},")
            lua.append(f"    sellPrice = {escape_lua_str(sell_price or '')},")
            lua.append(f"    tip = {escape_lua_str(clean_tip)},")
            lua.append(f"    isForever = {'true' if is_forever else 'false'},")
            lua.append("  }")
        lua.append("end)(ForeverGuide_Data.Items);\n")
    return "\n".join(lua)


def export_quests(cursor) -> str:
    cursor.execute("""
        SELECT id, title, req_level, quest_level, faction, zone, start_npc, objectives, rewards, pro_tip, is_forever_content, details, completion_text
        FROM quests
        ORDER BY title ASC
    """)
    rows = cursor.fetchall()
    lua = ["ForeverGuide_Data.Quests = ForeverGuide_Data.Quests or {}"]
    CHUNK_SIZE = 1000
    for chunk_idx in range(0, len(rows), CHUNK_SIZE):
        chunk_rows = rows[chunk_idx:chunk_idx + CHUNK_SIZE]
        lua.append("(function(t)")
        for r in chunk_rows:
            q_id, title, req_lvl, q_lvl, faction, zone, npc, objs, rewards, tip, is_forever, details, completion = r
            lua.append(f"  t[{q_id}] = {{")
            lua.append(f"    id = {q_id},")
            lua.append(f"    title = {escape_lua_str(title)},")
            lua.append(f"    reqLevel = {req_lvl or 0},")
            lua.append(f"    questLevel = {q_lvl or 0},")
            lua.append(f"    faction = {escape_lua_str(faction or 'Both')},")
            lua.append(f"    zone = {escape_lua_str(zone or '')},")
            lua.append(f"    npc = {escape_lua_str(npc or '')},")
            lua.append(f"    details = {escape_lua_str(details or '')},")
            lua.append(f"    objectives = {escape_lua_str(objs or '')},")
            lua.append(f"    completion = {escape_lua_str(completion or '')},")
            lua.append(f"    rewards = {escape_lua_str(rewards or '')},")
            lua.append(f"    tip = {escape_lua_str(tip or '')},")
            lua.append(f"    isForever = {'true' if is_forever else 'false'},")
            lua.append("  }")
        lua.append("end)(ForeverGuide_Data.Quests);\n")
    return "\n".join(lua)


def export_creatures(cursor) -> str:
    # Pre-aggregate top notable drops per creature
    cursor.execute("""
        SELECT l.creature_id, i.id, i.name, i.quality, l.drop_chance, i.slot, i.req_level
        FROM loot l
        JOIN items i ON l.item_id = i.id
        ORDER BY l.creature_id,
            CASE i.quality
                WHEN 'Legendary' THEN 1
                WHEN 'Epic' THEN 2
                WHEN 'Rare' THEN 3
                WHEN 'Uncommon' THEN 4
                ELSE 5
            END ASC,
            l.drop_chance DESC
    """)
    loot_by_creature = {}
    for r in cursor.fetchall():
        cid, i_id, i_name, i_qual, drop_chance, slot, req_lvl = r
        if cid not in loot_by_creature:
            loot_by_creature[cid] = []
        if len(loot_by_creature[cid]) < 8:
            pct_str = f"{drop_chance:.2f}%" if drop_chance < 1 else f"{drop_chance:.1f}%"
            loot_by_creature[cid].append({
                "id": i_id,
                "name": i_name,
                "quality": i_qual or "Common",
                "pct": pct_str,
                "slot": slot or "",
                "reqLvl": req_lvl or 0
            })

    cursor.execute("""
        SELECT id, name, level_min, level_max, classification, family, zone, location_details, health, strategy_notes, is_forever_content, coords
        FROM creatures
        WHERE forever_status = 'live'
          AND family != 'Internal'
        ORDER BY level_max DESC, name ASC
    """)
    rows = cursor.fetchall()
    lua = ["ForeverGuide_Data.Creatures = ForeverGuide_Data.Creatures or {}"]
    valid_rows = []
    for r in rows:
        name = r[1]
        n_lower = name.lower()
        if any(k in n_lower for k in [" form (", "druid - ", "ruul snowhoof bear form", "serpent form", "owl form", "combat dummy", "target dummy", "trigger", "credit marker", "camera", "controller", "spawner", "test mob", "test dude", "[ph]"]):
            continue
        valid_rows.append(r)

    CHUNK_SIZE = 1000
    for chunk_idx in range(0, len(valid_rows), CHUNK_SIZE):
        chunk_rows = valid_rows[chunk_idx:chunk_idx + CHUNK_SIZE]
        lua.append("(function(t)")
        for r in chunk_rows:
            c_id, name, l_min, l_max, classification, family, zone, loc, hp, strat, is_forever, coords = r
            lua.append(f"  t[{c_id}] = {{")
            lua.append(f"    id = {c_id},")
            lua.append(f"    name = {escape_lua_str(name)},")
            lua.append(f"    minLevel = {l_min or 0},")
            lua.append(f"    maxLevel = {l_max or 0},")
            lua.append(f"    classification = {escape_lua_str(classification or 'Normal')},")
            lua.append(f"    family = {escape_lua_str(family or 'Humanoid')},")
            lua.append(f"    zone = {escape_lua_str(zone or '')},")
            lua.append(f"    location = {escape_lua_str(loc or '')},")
            lua.append(f"    coords = {escape_lua_str(coords or '')},")
            lua.append(f"    health = {hp or 0},")
            lua.append(f"    strategy = {escape_lua_str(strat or '')},")
            lua.append(f"    isForever = {'true' if is_forever else 'false'},")
            if c_id in loot_by_creature and len(loot_by_creature[c_id]) > 0:
                lua.append("    loot = {")
                for item in loot_by_creature[c_id]:
                    lua.append(f"      {{ id = {item['id']}, name = {escape_lua_str(item['name'])}, quality = {escape_lua_str(item['quality'])}, pct = {escape_lua_str(item['pct'])}, slot = {escape_lua_str(item['slot'])}, reqLvl = {item['reqLvl']} }},")
                lua.append("    },")
            lua.append("  }")
        lua.append("end)(ForeverGuide_Data.Creatures);\n")
    return "\n".join(lua)


def export_zone_guide() -> str:
    zones = [
        {"name": "Dun Morogh", "level": "1-10", "faction": "Alliance", "continent": "Eastern Kingdoms"},
        {"name": "Elwynn Forest", "level": "1-10", "faction": "Alliance", "continent": "Eastern Kingdoms"},
        {"name": "Teldrassil", "level": "1-10", "faction": "Alliance", "continent": "Kalimdor"},
        {"name": "Durotar", "level": "1-10", "faction": "Horde", "continent": "Kalimdor"},
        {"name": "Mulgore", "level": "1-10", "faction": "Horde", "continent": "Kalimdor"},
        {"name": "Tirisfal Glades", "level": "1-10", "faction": "Horde", "continent": "Eastern Kingdoms"},
        {"name": "Westfall", "level": "10-20", "faction": "Alliance", "continent": "Eastern Kingdoms"},
        {"name": "Loch Modan", "level": "10-20", "faction": "Alliance", "continent": "Eastern Kingdoms"},
        {"name": "Darkshore", "level": "10-20", "faction": "Alliance", "continent": "Kalimdor"},
        {"name": "Silverpine Forest", "level": "10-20", "faction": "Horde", "continent": "Eastern Kingdoms"},
        {"name": "The Barrens", "level": "10-33", "faction": "Horde", "continent": "Kalimdor"},
        {"name": "Redridge Mountains", "level": "15-25", "faction": "Alliance", "continent": "Eastern Kingdoms"},
        {"name": "Stonetalon Mountains", "level": "15-25", "faction": "Contested", "continent": "Kalimdor"},
        {"name": "Ashenvale", "level": "18-30", "faction": "Contested", "continent": "Kalimdor"},
        {"name": "Duskwood", "level": "18-30", "faction": "Alliance", "continent": "Eastern Kingdoms"},
        {"name": "Hillsbrad Foothills", "level": "20-30", "faction": "Contested", "continent": "Eastern Kingdoms"},
        {"name": "Wetlands", "level": "20-30", "faction": "Alliance", "continent": "Eastern Kingdoms"},
        {"name": "Thousand Needles", "level": "25-35", "faction": "Contested", "continent": "Kalimdor"},
        {"name": "Alterac Mountains", "level": "30-40", "faction": "Contested", "continent": "Eastern Kingdoms"},
        {"name": "Arathi Highlands", "level": "30-40", "faction": "Contested", "continent": "Eastern Kingdoms"},
        {"name": "Desolace", "level": "30-40", "faction": "Contested", "continent": "Kalimdor"},
        {"name": "Stranglethorn Vale", "level": "30-45", "faction": "Contested", "continent": "Eastern Kingdoms"},
        {"name": "Badlands", "level": "35-45", "faction": "Contested", "continent": "Eastern Kingdoms"},
        {"name": "Swamp of Sorrows", "level": "35-45", "faction": "Contested", "continent": "Eastern Kingdoms"},
        {"name": "Dustwallow Marsh", "level": "35-45", "faction": "Contested", "continent": "Kalimdor"},
        {"name": "Feralas", "level": "40-50", "faction": "Contested", "continent": "Kalimdor"},
        {"name": "Tanaris", "level": "40-50", "faction": "Contested", "continent": "Kalimdor"},
        {"name": "The Hinterlands", "level": "40-50", "faction": "Contested", "continent": "Eastern Kingdoms"},
        {"name": "Searing Gorge", "level": "43-50", "faction": "Contested", "continent": "Eastern Kingdoms"},
        {"name": "Blasted Lands", "level": "45-55", "faction": "Contested", "continent": "Eastern Kingdoms"},
        {"name": "Un'Goro Crater", "level": "48-55", "faction": "Contested", "continent": "Kalimdor"},
        {"name": "Felwood", "level": "48-55", "faction": "Contested", "continent": "Kalimdor"},
        {"name": "Burning Steppes", "level": "50-58", "faction": "Contested", "continent": "Eastern Kingdoms"},
        {"name": "Western Plaguelands", "level": "51-58", "faction": "Contested", "continent": "Eastern Kingdoms"},
        {"name": "Eastern Plaguelands", "level": "53-60", "faction": "Contested", "continent": "Eastern Kingdoms"},
        {"name": "Winterspring", "level": "53-60", "faction": "Contested", "continent": "Kalimdor"},
        {"name": "Silithus", "level": "55-60", "faction": "Contested", "continent": "Kalimdor"},
    ]
    lua = ["ForeverGuide_Data.Zones = {"]
    for z in zones:
        lua.append(f"  {{ name = {escape_lua_str(z['name'])}, level = {escape_lua_str(z['level'])}, faction = {escape_lua_str(z['faction'])}, continent = {escape_lua_str(z['continent'])} }},")
    lua.append("}\n")
    return "\n".join(lua)


def export_bot_knowledge() -> str:
    modules = [
        ("Attunements", getattr(ke, "ATTUNEMENTS", {})),
        ("ClassBuilds", getattr(ke, "CLASS_BUILDS", {})),
        ("Consumables", getattr(ke, "CONSUMABLES_DATA", {})),
        ("DungeonKeys", getattr(ke, "DUNGEON_KEYS", {})),
        ("Gathering", getattr(ke, "GATHERING_NODES", {})),
        ("Professions", getattr(ke, "PROFESSIONS_DATA", {})),
        ("PvP", getattr(ke, "PVP_SYSTEM_DATA", {})),
        ("Racials", getattr(ke, "RACIAL_TRAITS", {})),
        ("RaidBosses", getattr(ke, "RAID_BOSSES_DATA", {})),
        ("Reputations", getattr(ke, "REPUTATIONS_DATA", {})),
        ("Resistance", getattr(ke, "RESIST_SCHOOLS", {})),
        ("Talents", getattr(ke, "TALENTS_DATA", {})),
        ("Twinks", getattr(ke, "TWINK_DATA", {})),
        ("WorldBuffs", getattr(ke, "WORLD_BUFFS_DATA", {})),
    ]

    parts = []
    for name, val in modules:
        parts.append(f"ForeverGuide_Data.{name} = {py_to_lua(val, 0)}\n")
    return "\n".join(parts)


def export_subzones() -> str:
    csv_path = os.path.join(BASE_DIR, "scratch", "ground_truth", "forever_client", "1.60.1.70685", "AreaTable.csv")
    lua = ["ForeverGuide_Data.Subzones = {"]
    if os.path.exists(csv_path):
        import csv
        with open(csv_path, mode="r", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            areas = {}
            for row in reader:
                areas[int(row["ID"])] = row

        for aid, row in areas.items():
            pid = int(row["ParentAreaID"])
            if pid != 0 and pid in areas:
                parent_name = areas[pid]["AreaName_lang"]
                sub_name = row["AreaName_lang"].lower()
                lua.append(f"  [{escape_lua_str(sub_name)}] = {escape_lua_str(parent_name)},")

    # Common quest POIs and towns
    manual_pois = {
        "crossroads": "The Barrens", "camp taurajo": "The Barrens", "bloodhoof village": "Mulgore",
        "camp narache": "Mulgore", "goldshire": "Elwynn Forest", "northshire": "Elwynn Forest",
        "northshire valley": "Elwynn Forest", "kharanos": "Dun Morogh", "coldridge valley": "Dun Morogh",
        "brill": "Tirisfal Glades", "deathknell": "Tirisfal Glades", "razor hill": "Durotar",
        "valley of trials": "Durotar", "sen'jin village": "Durotar", "dolanaar": "Teldrassil",
        "shadowglen": "Teldrassil", "sentinel hill": "Westfall", "moonbrook": "Westfall",
        "thelsamar": "Loch Modan", "lakeshire": "Redridge Mountains", "darkshire": "Duskwood",
        "southshore": "Hillsbrad Foothills", "tarren mill": "Hillsbrad Foothills", "menethil harbor": "Wetlands",
        "booty bay": "Stranglethorn Vale", "gadgetzan": "Tanaris", "ratchet": "The Barrens",
        "astranaar": "Ashenvale", "splintertree post": "Ashenvale", "auberdine": "Darkshore",
        "freewind post": "Thousand Needles", "everlook": "Winterspring", "light's hope chapel": "Eastern Plaguelands",
    }
    for sub, parent in manual_pois.items():
        lua.append(f"  [{escape_lua_str(sub)}] = {escape_lua_str(parent)},")
    lua.append("}\n")
    return "\n".join(lua)


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    header = """--[[
  ForeverGuide_Data.lua
  Warcraft Forever Addon Data Compilation
  Auto-generated from wow_forever.db and bot.py knowledge modules.
  Complete offline encyclopedia for the Blue Spark companion.
--]]

ForeverGuide_Data = ForeverGuide_Data or {}
"""

    print("Exporting zone guides...")
    zones_lua = export_zone_guide()

    print("Exporting subzone dictionary...")
    subzones_lua = export_subzones()

    print("Exporting dungeons...")
    dungeons_lua = export_dungeons(cursor)

    print("Exporting flight paths...")
    fp_lua = export_flightpaths(cursor)

    print("Exporting vendors (900+ authentic Blizzard merchants)...")
    vendors_lua = export_vendors(cursor)

    print("Exporting items (Forever + High Quality)...")
    items_lua = export_items(cursor)

    print("Exporting quests...")
    quests_lua = export_quests(cursor)

    print("Exporting creatures (Bosses + Elites)...")
    creatures_lua = export_creatures(cursor)

    print("Exporting bot knowledge encyclopedia (Attunements, BiS, Builds, Buffs, etc.)...")
    knowledge_lua = export_bot_knowledge()

    conn.close()

    full_content = "\n".join([
        header, zones_lua, subzones_lua, dungeons_lua, fp_lua, vendors_lua,
        items_lua, quests_lua, creatures_lua, knowledge_lua
    ])

    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        f.write(full_content)

    file_size_mb = os.path.getsize(OUTPUT_FILE) / (1024 * 1024)
    print(f"Export completed: {OUTPUT_FILE} ({file_size_mb:.2f} MB)")


if __name__ == "__main__":
    main()
