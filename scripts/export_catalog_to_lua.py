#!/usr/bin/env python3
"""
scripts/export_catalog_to_lua.py

Compiles static game data from wow_forever.db into an optimized Lua data file
for the in-game World of Warcraft Addon: ForeverGuide ("The Blue Spark").
"""

import os
import json
import sqlite3

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DB_PATH = os.path.join(BASE_DIR, "wow_forever.db")
OUTPUT_DIR = os.path.join(BASE_DIR, "addon", "ForeverGuide")
OUTPUT_FILE = os.path.join(OUTPUT_DIR, "ForeverGuide_Data.lua")


def escape_lua_str(val) -> str:
    if val is None:
        return '""'
    val_str = str(val)
    val_str = val_str.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n').replace('\r', '')
    return f'"{val_str}"'


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
    # Export items: all forever items + all rare/epic/legendary items + key quest items
    cursor.execute("""
        SELECT id, name, quality, item_level, req_level, slot, item_type, stats, description, source, pro_tip, is_forever_content
        FROM items
        WHERE is_forever_content = 1 OR quality IN ('Rare', 'Epic', 'Legendary', 'Artifact')
        ORDER BY is_forever_content DESC, quality DESC, item_level DESC
    """)
    rows = cursor.fetchall()
    lua = ["ForeverGuide_Data.Items = {"]
    for r in rows:
        i_id, name, quality, ilvl, req_lvl, slot, itype, stats, desc, source, tip, is_forever = r
        lua.append(f"  [{i_id}] = {{")
        lua.append(f"    id = {i_id},")
        lua.append(f"    name = {escape_lua_str(name)},")
        lua.append(f"    quality = {escape_lua_str(quality or 'Common')},")
        lua.append(f"    ilvl = {ilvl or 0},")
        lua.append(f"    reqLvl = {req_lvl or 0},")
        lua.append(f"    slot = {escape_lua_str(slot or '')},")
        lua.append(f"    itemType = {escape_lua_str(itype or '')},")
        lua.append(f"    source = {escape_lua_str(source or '')},")
        lua.append(f"    stats = {escape_lua_str(stats or '')},")
        lua.append(f"    tip = {escape_lua_str(tip or '')},")
        lua.append(f"    isForever = {'true' if is_forever else 'false'},")
        lua.append("  },")
    lua.append("}\n")
    return "\n".join(lua)


def export_zone_guide() -> str:
    # Standard Vanilla / Forever zone progression guide
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


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    header = """--[[
  ForeverGuide_Data.lua
  Warcraft Forever Addon Data Compilation
  Auto-generated from wow_forever.db for ForeverGuide ("The Blue Spark").
  Contains pre-compiled static lookup data for fast in-game retrieval.
--]]

ForeverGuide_Data = ForeverGuide_Data or {}
"""

    print("Exporting dungeons...")
    dungeons_lua = export_dungeons(cursor)

    print("Exporting flight paths...")
    fp_lua = export_flightpaths(cursor)

    print("Exporting vendors...")
    vendors_lua = export_vendors(cursor)

    print("Exporting items (Forever + High Quality)...")
    items_lua = export_items(cursor)

    print("Exporting zone guides...")
    zones_lua = export_zone_guide()

    conn.close()

    full_content = "\n".join([header, zones_lua, dungeons_lua, fp_lua, vendors_lua, items_lua])

    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        f.write(full_content)

    file_size_mb = os.path.getsize(OUTPUT_FILE) / (1024 * 1024)
    print(f"Export completed: {OUTPUT_FILE} ({file_size_mb:.2f} MB)")


if __name__ == "__main__":
    main()
