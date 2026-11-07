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
import re
import json

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
        if name and "ruins of lordaeron" in name.lower():
            l_min = 15
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

    # Enrich with RXPGuides dangerous mobs notes and rares classifications
    rxp_dir = "/home/s1l3nt/Faugus/battlenet/drive_c/Program Files (x86)/World of Warcraft/_forever_/Interface/AddOns/RXPGuides/DB/forever"
    dangerous_notes = {}
    dang_file = os.path.join(rxp_dir, "dangerousMobs.lua")
    if os.path.exists(dang_file):
        try:
            with open(dang_file, "r", encoding="utf-8") as f:
                dtext = f.read()
            for m in re.finditer(r'\[\"([^\"]+)\"\]\s*=\s*\{\s*\{.*?Notes\s*=\s*\"([^\"]+)\"', dtext, re.S):
                dangerous_notes[m.group(1).strip().lower()] = m.group(2).strip()
        except Exception:
            pass

    rare_names = set()
    rare_file = os.path.join(rxp_dir, "rares.lua")
    if os.path.exists(rare_file):
        try:
            with open(rare_file, "r", encoding="utf-8") as f:
                rtext = f.read()
            for rmatch in re.findall(r'\"([^\"]+)\"', rtext):
                rare_names.add(rmatch.strip().lower())
        except Exception:
            pass

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
            n_lower = name.lower()
            final_strat = strat or ""
            if n_lower in dangerous_notes:
                dnote = dangerous_notes[n_lower]
                if dnote and dnote not in final_strat:
                    final_strat = f"Combat Notes: {dnote}. {final_strat}".strip() if final_strat else f"Combat Notes: {dnote}."
            final_class = classification or "Normal"
            if n_lower in rare_names:
                if "elite" in final_class.lower():
                    final_class = "Rare Elite"
                else:
                    final_class = "Rare"

            lua.append(f"  t[{c_id}] = {{")
            lua.append(f"    id = {c_id},")
            lua.append(f"    name = {escape_lua_str(name)},")
            lua.append(f"    minLevel = {l_min or 0},")
            lua.append(f"    maxLevel = {l_max or 0},")
            lua.append(f"    classification = {escape_lua_str(final_class)},")
            lua.append(f"    family = {escape_lua_str(family or 'Humanoid')},")
            lua.append(f"    zone = {escape_lua_str(zone or '')},")
            lua.append(f"    location = {escape_lua_str(loc or '')},")
            lua.append(f"    coords = {escape_lua_str(coords or '')},")
            lua.append(f"    health = {hp or 0},")
            lua.append(f"    strategy = {escape_lua_str(final_strat)},")
            lua.append(f"    isForever = {'true' if is_forever else 'false'},")
            if c_id in loot_by_creature and len(loot_by_creature[c_id]) > 0:
                lua.append("    loot = {")
                for item in loot_by_creature[c_id]:
                    lua.append(f"      {{ id = {item['id']}, name = {escape_lua_str(item['name'])}, quality = {escape_lua_str(item['quality'])}, pct = {escape_lua_str(item['pct'])}, slot = {escape_lua_str(item['slot'])}, reqLvl = {item['reqLvl']} }},")
                lua.append("    },")
            lua.append("  }")
        lua.append("end)(ForeverGuide_Data.Creatures);\n")
    return "\n".join(lua)


def export_spells() -> str:
    spells_file = "/home/s1l3nt/Faugus/battlenet/drive_c/Program Files (x86)/World of Warcraft/_forever_/Interface/AddOns/RXPGuides/DB/forever/spells.lua"
    spells_json_path = os.path.join(BASE_DIR, "ForeverDB", "exports", "spells.json")

    fdb_spells = []
    if os.path.exists(spells_json_path):
        try:
            with open(spells_json_path, "r", encoding="utf-8") as f:
                fdb_spells = json.load(f)
        except Exception as e:
            print(f"Warning loading spells.json: {e}")

    def norm(text):
        if not text:
            return ""
        t = str(text).lower().replace("'", "").replace('"', "")
        t = re.sub(r"\(.*?\)", "", t)
        t = re.sub(r"[^a-z0-9]", "", t)
        return t

    by_id = {}
    by_norm_name_rank = {}
    by_norm_name = {}

    for s in fdb_spells:
        sid = s.get("id")
        if sid:
            by_id[sid] = s
        n = norm(s.get("name", ""))
        r = norm(s.get("rank", ""))
        if n:
            by_norm_name_rank[(n, r)] = s
            if n not in by_norm_name:
                by_norm_name[n] = s

    def title_case(s):
        words = s.split()
        return " ".join(w.capitalize() for w in words)

    def clean_icon_path(raw_icon, cls):
        icons = {
            "Druid": "Interface\\Icons\\Ability_Druid_Maul",
            "Hunter": "Interface\\Icons\\Ability_Hunter_AimedShot",
            "Mage": "Interface\\Icons\\Spell_Fire_Fireball02",
            "Paladin": "Interface\\Icons\\Spell_Holy_HolyBolt",
            "Priest": "Interface\\Icons\\Spell_Holy_PowerWordShield",
            "Rogue": "Interface\\Icons\\Ability_BackStab",
            "Shaman": "Interface\\Icons\\Spell_Nature_Lightning",
            "Warlock": "Interface\\Icons\\Spell_Shadow_ShadowBolt",
            "Warrior": "Interface\\Icons\\Ability_Warrior_Charge",
            "Racial": "Interface\\Icons\\Spell_Holy_MagicalSentry"
        }
        fallback = icons.get(cls, "Interface\\Icons\\Spell_Holy_MagicalSentry")
        if not raw_icon or raw_icon == "temp":
            return fallback
        raw_icon = str(raw_icon).replace("\\\\", "\\").replace("\\", "/")
        if raw_icon.lower().startswith("interface/icons/"):
            raw_icon = raw_icon[len("interface/icons/"):]
        elif raw_icon.lower().startswith("interface/"):
            raw_icon = raw_icon[len("interface/"):]
        return f"Interface\\Icons\\{raw_icon}"

    def clean_desc(match, fallback_name, fallback_cls, req_lvl):
        if match:
            d = match.get("description") or match.get("aura_description")
            if d and d.strip():
                return d.strip()
            tt_raw = match.get("tooltip")
            if tt_raw:
                try:
                    tt = json.loads(tt_raw) if isinstance(tt_raw, str) else tt_raw
                    for entry in tt:
                        if entry.get("k") == "desc" and entry.get("t"):
                            return entry["t"].strip()
                except Exception:
                    pass
        return f"{fallback_cls} ability learned at level {req_lvl}."

    spells = []
    seen_ids = set()

    CLASS_MAP = {
        "DRUID": "Druid", "HUNTER": "Hunter", "MAGE": "Mage",
        "PALADIN": "Paladin", "PRIEST": "Priest", "ROGUE": "Rogue",
        "SHAMAN": "Shaman", "WARLOCK": "Warlock", "WARRIOR": "Warrior"
    }

    if os.path.exists(spells_file):
        try:
            with open(spells_file, "r", encoding="utf-8") as f:
                text = f.read()
            curr_section = None
            curr_lvl = 1
            for line in text.splitlines():
                line_clean = line.strip()
                m_sec = re.match(r's\[\"([A-Za-z]+)\"\]\s*=\s*\{', line_clean)
                if m_sec:
                    curr_section = m_sec.group(1)
                    continue
                m_lvl = re.match(r'\[(\d+)\]\s*=\s*\{', line_clean)
                if m_lvl:
                    curr_lvl = int(m_lvl.group(1))
                
                m_spell = re.search(r'(\d+)\s*,?\s*--\s*(.*)', line_clean)
                if m_spell and curr_section in CLASS_MAP:
                    sid = int(m_spell.group(1))
                    if sid in seen_ids:
                        continue
                    seen_ids.add(sid)
                    raw_name = m_spell.group(2).strip()
                    rank_m = re.search(r'\b(?:r|rank)\s*(\d+)\b', raw_name, re.I)
                    rank_str = f"Rank {rank_m.group(1)}" if rank_m else ""
                    clean_name = re.sub(r'\b(?:r|rank)\s*\d+\b', '', raw_name, flags=re.I).strip()
                    clean_name = title_case(clean_name)
                    cls_name = CLASS_MAP[curr_section]

                    n_clean = norm(clean_name)
                    n_rank = norm(rank_str)
                    match = by_id.get(sid) or by_norm_name_rank.get((n_clean, n_rank)) or by_norm_name.get(n_clean)

                    spell_name = match.get("name") if match and match.get("name") else clean_name
                    spell_rank = match.get("rank") if match and match.get("rank") else rank_str
                    spell_cost = match.get("cost") if match and match.get("cost") else ""
                    spell_cast = match.get("cast_time") if match and match.get("cast_time") else ""
                    spell_range = match.get("range") if match and match.get("range") else ""
                    spell_cd = match.get("cooldown") if match and match.get("cooldown") else ""
                    spell_icon = clean_icon_path(match.get("icon") if match else None, cls_name)
                    spell_desc = clean_desc(match, clean_name, cls_name, curr_lvl)

                    spells.append({
                        "id": sid,
                        "name": spell_name,
                        "rank": spell_rank,
                        "class": cls_name,
                        "reqLevel": curr_lvl,
                        "cost": spell_cost,
                        "castTime": spell_cast,
                        "range": spell_range,
                        "cooldown": spell_cd,
                        "icon": spell_icon,
                        "desc": spell_desc,
                        "isForever": bool(sid == 437138 or (match and match.get("is_forever", False)))
                    })
        except Exception as e:
            print(f"Warning parsing spells.lua: {e}")

    # Official WoW: Forever Custom & Reworked Spells from Alpha Notes
    custom_forever_spells = [
        {"id": 71001, "name": "Shank", "rank": "Rank 1", "class": "Rogue", "reqLevel": 24, "cost": "5 Energy", "castTime": "Instant", "range": "Melee", "cooldown": "10 sec cooldown", "icon": "Interface\\Icons\\INV_Weapon_ShortBlade_01", "desc": "Instantly strike with your off-hand weapon, dealing 50% weapon damage and generating 15 Energy. Shank cannot Miss.", "isForever": True},
        {"id": 71002, "name": "Shank", "rank": "Rank 2", "class": "Rogue", "reqLevel": 44, "cost": "5 Energy", "castTime": "Instant", "range": "Melee", "cooldown": "10 sec cooldown", "icon": "Interface\\Icons\\INV_Weapon_ShortBlade_01", "desc": "Instantly strike with your off-hand weapon, dealing 50% weapon damage and generating 25 Energy. Shank cannot Miss.", "isForever": True},
        {"id": 71003, "name": "Poised", "rank": "", "class": "Rogue", "reqLevel": 18, "cost": "Passive", "castTime": "Passive", "range": "Self", "cooldown": "", "icon": "Interface\\Icons\\Ability_Rogue_StayofExecution", "desc": "When you are not in combat and have your maximum Energy, you gain Poised. Poised reduces the Energy cost of your next Energy ability by 10.", "isForever": True},
        {"id": 71004, "name": "Poised", "rank": "", "class": "Druid", "reqLevel": 32, "cost": "Passive", "castTime": "Passive", "range": "Self", "cooldown": "", "icon": "Interface\\Icons\\Ability_Druid_PrimalPrecision", "desc": "When you are not in combat and have your maximum Energy, you gain Poised. Poised reduces the Energy cost of your next Energy ability by 10.", "isForever": True},
        {"id": 71005, "name": "Death Mark", "rank": "", "class": "Rogue", "reqLevel": 40, "cost": "25 Energy", "castTime": "Instant", "range": "20 yd range", "cooldown": "10 sec cooldown", "icon": "Interface\\Icons\\Ability_Rogue_DeathMark", "desc": "31-point Subtlety talent. Curse finishing move that marks the target, storing a portion of the damage dealt by your attacks per Combo Point. Garrote and Rupture damage is stored at twice the rate. After 6 sec, the stored damage is dealt up to a maximum increased by Attack Power and Critical Strike chance.", "isForever": True},
        {"id": 71006, "name": "Boot Knife", "rank": "", "class": "Rogue", "reqLevel": 35, "cost": "Passive", "castTime": "Passive", "range": "Self", "cooldown": "", "icon": "Interface\\Icons\\INV_ThrowingKnife_04", "desc": "Subtlety Row 6. Gives your Shank ability a 20/40/60/80/100% chance to add 2 Combo Points to the target.", "isForever": True},
        {"id": 71007, "name": "Flash of Steel", "rank": "", "class": "Rogue", "reqLevel": 35, "cost": "Passive", "castTime": "Passive", "range": "Self", "cooldown": "", "icon": "Interface\\Icons\\Ability_Rogue_PreyontheWeak", "desc": "Combat Row 6. Increases the energy generated by your Shank ability by 3/6/9/12/15 and reduces its cooldown by 0.4/0.8/1.2/1.6/2.0 seconds.", "isForever": True},
        {"id": 71008, "name": "Composure", "rank": "", "class": "Rogue", "reqLevel": 20, "cost": "Passive", "castTime": "Passive", "range": "Self", "cooldown": "", "icon": "Interface\\Icons\\Spell_Shadow_MindSteal", "desc": "Combat Row 3. Increases the Energy cost reduction of your Poised ability by 5/10.", "isForever": True},
        {"id": 71009, "name": "Coup de Grace", "rank": "", "class": "Rogue", "reqLevel": 10, "cost": "Passive", "castTime": "Passive", "range": "Self", "cooldown": "", "icon": "Interface\\Icons\\Ability_Rogue_Eviscerate", "desc": "Combat Row 1. Increases the damage done by your Eviscerate ability by 7/13/20%, and the damage and storage rate of your Death Mark ability by 7/13/20%.", "isForever": True},
        {"id": 71010, "name": "Efficient Strikes", "rank": "", "class": "Rogue", "reqLevel": 10, "cost": "Passive", "castTime": "Passive", "range": "Self", "cooldown": "", "icon": "Interface\\Icons\\Spell_Shadow_RitualOfSacrifice", "desc": "Combat Row 1. Reduces the Energy costs of Sinister Strike and Hemorrhage by 3/5.", "isForever": True},
        {"id": 71011, "name": "Blood Splatter", "rank": "", "class": "Rogue", "reqLevel": 20, "cost": "Passive", "castTime": "Passive", "range": "Self", "cooldown": "", "icon": "Interface\\Icons\\Ability_Rogue_BloodSplatter", "desc": "Assassination Row 3. Increases the duration of your Rupture ability by 6 seconds and your Garrote ability by 9 seconds.", "isForever": True},
        {"id": 71012, "name": "Venom", "rank": "", "class": "Rogue", "reqLevel": 30, "cost": "Passive", "castTime": "Passive", "range": "Self", "cooldown": "", "icon": "Interface\\Icons\\Ability_PoisonSting", "desc": "Assassination Row 5. Causes your Shank ability to increase your Poison damage by 30% and your chance to apply Poisons by 20% for 6 seconds.", "isForever": True},
        {"id": 71013, "name": "Bloom", "rank": "", "class": "Druid", "reqLevel": 20, "cost": "Passive", "castTime": "Passive", "range": "Self", "cooldown": "", "icon": "Interface\\Icons\\Spell_Nature_HealingTouch", "desc": "Restoration Row 3. When your Rejuvenation or Regrowth spell expires due to its duration, the target is instantly healed for an amount equal to 100% of your Spirit. If either spell expires due to being dispelled, the target is healed for 50% of your Spirit instead.", "isForever": True},
        {"id": 71014, "name": "Predatory Discipline", "rank": "", "class": "Druid", "reqLevel": 25, "cost": "Passive", "castTime": "Passive", "range": "Self", "cooldown": "", "icon": "Interface\\Icons\\Ability_Druid_FerociousBite", "desc": "Feral Row 4. Your Ferocious Bite ability no longer converts extra Energy into damage but still deals extra damage based on your excess Energy.", "isForever": True},
        {"id": 71015, "name": "Lacerate", "rank": "", "class": "Druid", "reqLevel": 25, "cost": "15 Rage", "castTime": "Instant", "range": "Melee", "cooldown": "", "icon": "Interface\\Icons\\Ability_Druid_Lacerate", "desc": "Feral Row 4. Lacerates the enemy target in Bear form, causing immediate bleed damage and bleed damage over 15 sec, stacking up to 5 times. High threat.", "isForever": True},
        {"id": 71016, "name": "Shifting Power", "rank": "", "class": "Druid", "reqLevel": 40, "cost": "Passive", "castTime": "Passive", "range": "Self", "cooldown": "", "icon": "Interface\\Icons\\Ability_Druid_Enrage", "desc": "31-point Feral talent focused on Bear gameplay, maximizing threat generation, health pooling, and physical resilience.", "isForever": True},
        {"id": 71017, "name": "Primal Bite", "rank": "", "class": "Druid", "reqLevel": 40, "cost": "Passive", "castTime": "Passive", "range": "Self", "cooldown": "", "icon": "Interface\\Icons\\Ability_Druid_Ravage", "desc": "31-point Feral talent focused on Cat gameplay, maximizing critical strike output and finisher efficiency.", "isForever": True},
        {"id": 71018, "name": "Wild Growth", "rank": "", "class": "Druid", "reqLevel": 40, "cost": "Base Mana", "castTime": "3.0 sec cast", "range": "40 yd range", "cooldown": "6 sec cooldown", "icon": "Interface\\Icons\\Ability_Druid_Flourish", "desc": "Heals up to 5 friendly party or raid members within 15 yards of the target over 7 sec. The amount healed starts high and decreases over the duration.", "isForever": True},
        {"id": 71019, "name": "Shieldsworn", "rank": "", "class": "Paladin", "reqLevel": 40, "cost": "Passive", "castTime": "Passive", "range": "Self", "cooldown": "", "icon": "Interface\\Icons\\Ability_Paladin_ShieldoftheTemplar", "desc": "31-point Protection talent. Reduces Holy Strike cooldown by 4 sec. Additionally, Holy Strike strikes with your shield, triggering block talents without consuming charges or triggering cooldowns, and allows you to Block spells for 6 seconds.", "isForever": True},
        {"id": 71020, "name": "Turn Evil", "rank": "", "class": "Paladin", "reqLevel": 30, "cost": "Passive", "castTime": "Passive", "range": "Self", "cooldown": "", "icon": "Interface\\Icons\\Spell_Holy_TurnUndead", "desc": "Retribution Row 5. Reduces the cast time of your Turn Undead spell by 0.5/1.0 sec, its cooldown by 5/10 sec, and allows it to affect Demons.", "isForever": True},
        {"id": 71021, "name": "Unsealed Wrath", "rank": "", "class": "Paladin", "reqLevel": 40, "cost": "Passive", "castTime": "Passive", "range": "Self", "cooldown": "", "icon": "Interface\\Icons\\Spell_Holy_SealOfWrath", "desc": "31-point Retribution talent. Your melee attacks store a copy of your active Seal for 15 sec, stacking up to 3 times. Landing an attack with a different Seal consumes all stacks, giving the stored Seal its normal chance to activate once per stack.", "isForever": True},
        {"id": 71022, "name": "Oath of Light", "rank": "", "class": "Paladin", "reqLevel": 25, "cost": "8% Base Mana", "castTime": "Instant", "range": "40 yd range", "cooldown": "", "icon": "Interface\\Icons\\Spell_Holy_GreaterBlessingofLight", "desc": "Holy Row 4. Swear an Oath to protect target ally for 5 min, increasing the healing of your Holy Light, Flash of Light, and Holy Shock spells. Only one Oath of Light may be active at any one time.", "isForever": True},
        {"id": 71023, "name": "Boundless Light", "rank": "", "class": "Paladin", "reqLevel": 30, "cost": "Passive", "castTime": "Passive", "range": "Self", "cooldown": "", "icon": "Interface\\Icons\\Spell_Holy_HolyShock", "desc": "Holy Row 5. Increases the critical strike chance of your Holy Shock spell by 15/30% when cast on allies not affected by your Oath of Light.", "isForever": True},
        {"id": 71024, "name": "Holy Binding", "rank": "", "class": "Priest", "reqLevel": 20, "cost": "Passive", "castTime": "Passive", "range": "Self", "cooldown": "", "icon": "Interface\\Icons\\Spell_Holy_FlashHeal", "desc": "Holy Row 3. When the Priest heals a target other than themselves with Flash Heal, 50% of the healing done is also done to the Priest with zero threat.", "isForever": True},
        {"id": 71025, "name": "Totemic Call", "rank": "", "class": "Shaman", "reqLevel": 30, "cost": "Base Mana", "castTime": "Instant", "range": "Self", "cooldown": "30 sec cooldown", "icon": "Interface\\Icons\\Spell_Shaman_TotemRecall", "desc": "Teleports all of the Shaman's active totems directly to the Shaman's current location.", "isForever": True},
        {"id": 71026, "name": "Call of Thunder", "rank": "", "class": "Shaman", "reqLevel": 20, "cost": "Passive", "castTime": "Passive", "range": "Self", "cooldown": "", "icon": "Interface\\Icons\\Spell_Nature_CallStorm", "desc": "Elemental talent. Increases the critical strike chance of your Lightning Bolt and Chain Lightning spells by 5%.", "isForever": True},
        {"id": 71027, "name": "Reckless Swings", "rank": "", "class": "Warrior", "reqLevel": 25, "cost": "25% Base Health", "castTime": "Instant", "range": "Self", "cooldown": "15 sec cooldown", "icon": "Interface\\Icons\\Ability_Warrior_RecklessAbandon", "desc": "Fury Row 4. Your next 4 melee attacks generate 5 additional Rage. Lasts 8 seconds.", "isForever": True},
        {"id": 71028, "name": "Improved Whirlwind", "rank": "", "class": "Warrior", "reqLevel": 35, "cost": "Passive", "castTime": "Passive", "range": "Self", "cooldown": "", "icon": "Interface\\Icons\\Ability_Whirlwind", "desc": "Fury Row 6. Reduces the cooldown of your Whirlwind ability by 1/2 seconds and increases the damage it deals to the closest enemy by 15/30%.", "isForever": True},
        {"id": 71029, "name": "Bloodthrill", "rank": "", "class": "Warrior", "reqLevel": 20, "cost": "Passive", "castTime": "Passive", "range": "Self", "cooldown": "", "icon": "Interface\\Icons\\Ability_Racial_BloodRage", "desc": "Arms Row 3. Gives your Main Hand melee attacks against enemies afflicted by Rend a 10/20% chance to allow an activation of Overpower.", "isForever": True},
        {"id": 71030, "name": "Wrack", "rank": "", "class": "Warlock", "reqLevel": 20, "cost": "Base Mana", "castTime": "Instant", "range": "30 yd range", "cooldown": "", "icon": "Interface\\Icons\\Spell_Shadow_CurseOfTounges", "desc": "Affliction spell. Wracks the target with searing damage over time, scaling directly with spell damage coefficient up to 86 DPS at level 60.", "isForever": True},
        {"id": 71031, "name": "Arcane Wrath", "rank": "", "class": "Mage", "reqLevel": 25, "cost": "Passive", "castTime": "Passive", "range": "Self", "cooldown": "", "icon": "Interface\\Icons\\Spell_Arcane_ArcaneTorrent", "desc": "Arcane talent. Converts 5% of your maximum Mana directly into bonus Spell Power in WoW: Forever Alpha, making Intellect an extraordinary DPS stat.", "isForever": True},
        {"id": 71032, "name": "Arcane Blast", "rank": "", "class": "Mage", "reqLevel": 20, "cost": "Base Mana", "castTime": "1.5 sec cast", "range": "30 yd range", "cooldown": "", "icon": "Interface\\Icons\\Spell_Arcane_Blast", "desc": "Blasts the target with arcane energy. Each cast increases your Spell Damage from Intellect by 12% per stack, but increases mana cost of subsequent Arcane Blasts. Lasts 18 seconds.", "isForever": True},
        {"id": 71033, "name": "Ice Barrier", "rank": "", "class": "Mage", "reqLevel": 40, "cost": "Base Mana", "castTime": "Instant", "range": "Self", "cooldown": "30 sec cooldown", "icon": "Interface\\Icons\\Spell_Ice_Lament", "desc": "31-point Frost talent. Absorbs damage. In WoW: Forever Alpha, activating Ice Barrier increases Frost Damage dealt by 15% for 1 minute, plus an additional 5% Frost Damage while the barrier holds.", "isForever": True},
        {"id": 71034, "name": "Precision", "rank": "", "class": "Mage", "reqLevel": 15, "cost": "Passive", "castTime": "Passive", "range": "Self", "cooldown": "", "icon": "Interface\\Icons\\Spell_Ice_MagicDamage", "desc": "Frost talent. Grants 2/4/6% increased chance to hit with ALL spells (Arcane, Fire, and Frost).", "isForever": True},
        {"id": 71035, "name": "Accelerant", "rank": "", "class": "Mage", "reqLevel": 10, "cost": "Passive", "castTime": "Passive", "range": "Self", "cooldown": "", "icon": "Interface\\Icons\\Spell_Fire_Fireball", "desc": "Fire talent. Reduces the cast time of Fireball and Arcane Wrath by up to 0.5 seconds.", "isForever": True},
        {"id": 437138, "name": "Revive", "rank": "Rank 1", "class": "Druid", "reqLevel": 14, "cost": "Base Mana", "castTime": "10.0 sec cast", "range": "30 yd range", "cooldown": "", "icon": "Interface\\Icons\\Spell_Holy_Resurrection", "desc": "Returns the spirit to the body, restoring a dead target to life with 20% health and mana. Out of combat resurrection.", "isForever": True},
        {"id": 71036, "name": "Wind-Blessed", "rank": "", "class": "Racial", "reqLevel": 1, "cost": "Passive", "castTime": "Passive", "range": "Self", "cooldown": "", "icon": "Interface\\Icons\\Spell_Nature_Windfury", "desc": "Skyborne Racial. Increases attack, ranged, and spell casting Haste by 2%.", "isForever": True},
        {"id": 71037, "name": "Read Leyline", "rank": "", "class": "Racial", "reqLevel": 1, "cost": "Instant", "castTime": "Instant", "range": "Self", "cooldown": "2 min cooldown", "icon": "Interface\\Icons\\Spell_Arcane_Arcane01", "desc": "Skyborne Racial. Increases Mana and Health regeneration by 50% for 15 sec. When used at a Ley Line, grants 'Attuned' for 1 hour, doubling the benefit to +100% regeneration (persists through death, removed upon entering a raid).", "isForever": True},
        {"id": 71038, "name": "Skysight", "rank": "", "class": "Racial", "reqLevel": 1, "cost": "Instant", "castTime": "Instant", "range": "Self", "cooldown": "2 min cooldown", "icon": "Interface\\Icons\\Ability_Hunter_EagleEye", "desc": "Skyborne Racial. Increases movement speed by 15% for 15 sec. When used at an Elemental Convergence, grants 'Charged' for 1 hour, increasing speed bonus to +30% (persists through death, removed upon entering a raid).", "isForever": True},
        {"id": 71039, "name": "Artisan's Precision", "rank": "", "class": "Racial", "reqLevel": 1, "cost": "Passive", "castTime": "Passive", "range": "Self", "cooldown": "", "icon": "Interface\\Icons\\Trade_BlackSmithing", "desc": "Dwarf Racial. Increases hit chance with spells and attacks by 1%.", "isForever": True},
        {"id": 71040, "name": "Ruthless", "rank": "", "class": "Racial", "reqLevel": 1, "cost": "Passive", "castTime": "Passive", "range": "Self", "cooldown": "", "icon": "Interface\\Icons\\Ability_CriticalStrike", "desc": "Human Racial. Increases critical strike chance by 1%.", "isForever": True},
        {"id": 71041, "name": "The Human Spirit", "rank": "", "class": "Racial", "reqLevel": 1, "cost": "Passive", "castTime": "Passive", "range": "Self", "cooldown": "", "icon": "Interface\\Icons\\Spell_Holy_DivineSpirit", "desc": "Human Racial. Increases Spirit by 10%.", "isForever": True},
        {"id": 71042, "name": "Command", "rank": "", "class": "Racial", "reqLevel": 1, "cost": "Passive", "castTime": "Passive", "range": "Self", "cooldown": "", "icon": "Interface\\Icons\\Ability_Hunter_Pet_Wolf", "desc": "Orc Racial. Increases Warlock and Hunter pet damage by 5%.", "isForever": True},
        {"id": 71043, "name": "Plainsrunning", "rank": "", "class": "Racial", "reqLevel": 1, "cost": "Passive", "castTime": "Passive", "range": "Self", "cooldown": "", "icon": "Interface\\Icons\\Ability_Mount_Kodo_01", "desc": "Tauren Racial. Moving forward continuously builds speed stacks up to +60% max movement speed.", "isForever": True},
        {"id": 71044, "name": "Touch of the Grave", "rank": "", "class": "Racial", "reqLevel": 1, "cost": "Passive", "castTime": "Passive", "range": "Self", "cooldown": "15 sec internal cooldown", "icon": "Interface\\Icons\\Spell_Shadow_Haunting", "desc": "Undead Racial. Attacks and spells have a chance to drain life from the target, dealing Shadow damage and healing you. 15 sec internal cooldown.", "isForever": True},
        {"id": 71045, "name": "Eureka!", "rank": "", "class": "Racial", "reqLevel": 1, "cost": "Instant", "castTime": "Instant", "range": "Self", "cooldown": "2 min cooldown", "icon": "Interface\\Icons\\INV_Gizmo_01", "desc": "Gnome Racial. Eureka! Grants a 10% Mana, Rage, or Energy discount on all abilities for 8 seconds.", "isForever": True},
        {"id": 71046, "name": "Berserking", "rank": "", "class": "Racial", "reqLevel": 1, "cost": "Instant", "castTime": "Instant", "range": "Self", "cooldown": "3 min cooldown", "icon": "Interface\\Icons\\Racial_Troll_Berserk", "desc": "Troll Racial. Increases attack and casting speed by 10% to 30% for 15 seconds (up from 10s in Forever Alpha).", "isForever": True},
    ]

    for cs in custom_forever_spells:
        if cs["id"] not in seen_ids:
            seen_ids.add(cs["id"])
            spells.append(cs)

    # Official standard racials
    RACIAL_IDS = [
        20594, # Stoneform
        20580, # Shadowmeld
        20600, # Perception
        20572, # Blood Fury
        7744,  # Will of the Forsaken
        20549, # War Stomp
        20589, # Escape Artist
        20554, # Berserking
        20577, # Cannibalize
        2481,  # Find Treasure
        5227,  # Underwater Breathing
        20552, # Cultivation
        20550, # Endurance
        20551, # Nature Resistance
        20596, # Frost Resistance
        20579, # Shadow Resistance
        20592, # Arcane Resistance
        20595, # Gun Specialization
        20574, # Axe Specialization
        20558, # Bow Specialization
        20557, # Throwing Specialization
        20597, # Sword Specialization
        20598, # Mace Specialization
        20593, # Engineering Specialization
    ]
    for rid in RACIAL_IDS:
        if rid in by_id and rid not in seen_ids:
            seen_ids.add(rid)
            rs = by_id[rid]
            spells.append({
                "id": rid,
                "name": rs.get("name", "Racial Trait"),
                "rank": rs.get("rank") or "",
                "class": "Racial",
                "reqLevel": 1,
                "cost": rs.get("cost") or "Passive",
                "castTime": rs.get("cast_time") or "Instant",
                "range": rs.get("range") or "Self",
                "cooldown": rs.get("cooldown") or "",
                "icon": clean_icon_path(rs.get("icon"), "Racial"),
                "desc": clean_desc(rs, rs.get("name", ""), "Racial", 1),
                "isForever": False
            })

    # Also add key player class talents from ForeverDB that have descriptions
    for s in fdb_spells:
        sid = s.get("id")
        cname = s.get("class_name")
        if sid and cname in CLASS_MAP.values() and sid not in seen_ids:
            desc = s.get("description")
            if desc and desc.strip() and not s.get("is_internal") and not s.get("hidden"):
                kind = s.get("kind")
                if kind in ("class", "talent"):
                    seen_ids.add(sid)
                    spells.append({
                        "id": sid,
                        "name": s.get("name", "Ability"),
                        "rank": s.get("rank") or "",
                        "class": cname,
                        "reqLevel": s.get("spell_level") or s.get("level") or 1,
                        "cost": s.get("cost") or "",
                        "castTime": s.get("cast_time") or "",
                        "range": s.get("range") or "",
                        "cooldown": s.get("cooldown") or "",
                        "icon": clean_icon_path(s.get("icon"), cname),
                        "desc": clean_desc(s, s.get("name", ""), cname, s.get("spell_level") or 1),
                        "isForever": bool(s.get("is_forever", False))
                    })

    lua = ["ForeverGuide_Data.Spells = ForeverGuide_Data.Spells or {}"]
    CHUNK_SIZE = 1000
    for chunk_idx in range(0, len(spells), CHUNK_SIZE):
        chunk_spells = spells[chunk_idx:chunk_idx + CHUNK_SIZE]
        lua.append("(function(t)")
        for s in chunk_spells:
            lua.append(f"  t[{s['id']}] = {{")
            lua.append(f"    id = {s['id']},")
            lua.append(f"    name = {escape_lua_str(s['name'])},")
            lua.append(f"    rank = {escape_lua_str(s['rank'])},")
            lua.append(f"    class = {escape_lua_str(s['class'])},")
            lua.append(f"    reqLevel = {s['reqLevel']},")
            lua.append(f"    cost = {escape_lua_str(s.get('cost', ''))},")
            lua.append(f"    castTime = {escape_lua_str(s.get('castTime', ''))},")
            lua.append(f"    range = {escape_lua_str(s.get('range', ''))},")
            lua.append(f"    cooldown = {escape_lua_str(s.get('cooldown', ''))},")
            lua.append(f"    icon = {escape_lua_str(s.get('icon', ''))},")
            lua.append(f"    desc = {escape_lua_str(s.get('desc', ''))},")
            lua.append(f"    isForever = {'true' if s.get('isForever') else 'false'},")
            lua.append("  }")
        lua.append("end)(ForeverGuide_Data.Spells);\n")
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

    print("Exporting spells (Class Abilities & Forever Talents)...")
    spells_lua = export_spells()

    print("Exporting bot knowledge encyclopedia (Attunements, BiS, Builds, Buffs, etc.)...")
    knowledge_lua = export_bot_knowledge()

    conn.close()

    full_content = "\n".join([
        header, zones_lua, subzones_lua, dungeons_lua, fp_lua, vendors_lua,
        items_lua, quests_lua, creatures_lua, spells_lua, knowledge_lua
    ])

    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        f.write(full_content)

    file_size_mb = os.path.getsize(OUTPUT_FILE) / (1024 * 1024)
    print(f"Export completed: {OUTPUT_FILE} ({file_size_mb:.2f} MB)")


if __name__ == "__main__":
    main()
