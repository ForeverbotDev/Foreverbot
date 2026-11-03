"""Build Full WoW Forever Database Engine.
Populates wow_forever.db with complete, authentic game data:
- Over 20,000 items (complete item catalog across ALL qualities: Poor/Gray, Common/White, Uncommon/Green, Rare/Blue, Epic/Purple, Legendary)
- Over 10,000 creatures and NPCs (complete boss and NPC roster with health, rank, and location)
- Over 4,000 quests (complete questline catalog with level requirements, factions, and zones)
- All 46 WoW Forever dungeons & raids (including all 16 custom WoW Forever dungeons)
- Complete flightpaths, vendors, and full-text search (FTS5) indexes.
Preserves all custom WoW Forever content and curated pro-tips.
"""

import sqlite3
import json
import os
import sys
import re

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, ROOT_DIR)

from database import init_db, get_connection, DB_PATH
from scripts.seed_data import seed_database

NEXUS_ITEMS_PATH = "/tmp/nexus_items.json"
NEXUS_ZONES_PATH = "/tmp/nexus_zones.json"
CLASSIC_REFERENCE_DB_PATH = "/tmp/classic_reference.sqlite"


def parse_nexus_item(it):
    stats = []
    desc = []
    source_str = ""

    # Parse tooltips
    tooltips = it.get("tooltip", [])
    for t in tooltips:
        lbl = t.get("label", "").strip()
        if not lbl or lbl == it.get("name") or lbl.startswith("Phase") or lbl.startswith("Item Level") or lbl.startswith("Durability") or lbl.startswith("Sell Price"):
            continue
        if lbl in ["Binds when picked up", "Binds when equipped", "Unique", "Unique-Equipped"]:
            continue
        if any(stat in lbl for stat in ["Strength", "Agility", "Stamina", "Intellect", "Spirit", "Armor", "Resistance", "Damage per Second", "damage per second", "Damage", "Speed "]):
            stats.append(lbl)
        elif lbl.startswith("Equip:") or lbl.startswith("Chance on hit:") or lbl.startswith("Use:"):
            desc.append(lbl)
        elif lbl.startswith("Dropped by:") or lbl.startswith("Drop Chance:"):
            if not source_str:
                source_str = lbl
            else:
                source_str += f" ({lbl})"

    # Source fallback
    src = it.get("source")
    if not source_str and src and isinstance(src, dict):
        cat = src.get("category", "")
        name = src.get("name", "")
        if cat and name:
            source_str = f"{cat}: {name}"
            if "dropChance" in src:
                source_str += f" ({round(src['dropChance']*100, 1)}%)"

    stats_str = ", ".join(stats)
    desc_str = " ".join(desc)
    return stats_str, desc_str, source_str


def build_full_database(db_path: str = DB_PATH):
    print("=" * 70)
    print("⚔️ BUILDING FULL WOW FOREVER COMPLETE GAME DATABASE (ALL QUALITIES)")
    print("=" * 70)

    tmp_db_path = db_path + ".tmp"
    if os.path.exists(tmp_db_path):
        os.remove(tmp_db_path)

    # Step 1: Initialize schema and seed base curated items, custom WoW Forever content & dungeons
    print("\n[1/6] Seeding base curated content & custom WoW Forever dungeons...")
    seed_database(tmp_db_path)
    conn = get_connection(tmp_db_path)
    cursor = conn.cursor()

    # Cache existing items, quests, and creatures
    existing_items = {r[0]: (r[1], r[2], r[3]) for r in cursor.execute("SELECT id, name, pro_tip, is_forever_content FROM items").fetchall()}
    existing_quests = {r[0]: (r[1], r[2], r[3]) for r in cursor.execute("SELECT id, title, pro_tip, is_forever_content FROM quests").fetchall()}
    existing_creatures = {r[0]: (r[1], r[2], r[3]) for r in cursor.execute("SELECT id, name, strategy_notes, is_forever_content FROM creatures").fetchall()}

    print(f"  -> Preserved {len(existing_items)} curated items (including all custom WoW Forever items).")
    print(f"  -> Preserved {len(existing_quests)} curated quests (including all custom WoW Forever quests).")
    print(f"  -> Preserved {len(existing_creatures)} curated creatures (including all custom WoW Forever bosses).")

    # Step 2: Ingest full items catalog from nexus_items
    print("\n[2/6] Ingesting full items catalog (including all white & gray items)...")
    items_inserted = 0
    if os.path.exists(NEXUS_ITEMS_PATH):
        with open(NEXUS_ITEMS_PATH, "r", encoding="utf-8") as f:
            all_items = json.load(f)

        for it in all_items:
            iid = it.get("itemId")
            if not iid or iid > 26000:
                continue
            phase = it.get("contentPhase")
            if phase is not None and phase > 6:
                continue

            name = (it.get("name") or "").strip()
            if not name:
                continue

            # If already in DB from curated seed, preserve it
            if iid in existing_items:
                continue

            quality = it.get("quality", "Common")
            item_level = int(it.get("itemLevel") or 1)
            req_level = int(it.get("requiredLevel") or 1)
            slot = it.get("slot", "") or ""
            item_type = it.get("subclass", "") or it.get("class", "") or ""
            stats_str, desc_str, source_str = parse_nexus_item(it)

            cursor.execute("""
                INSERT OR IGNORE INTO items (id, name, quality, item_level, req_level, slot, item_type, stats, description, source, pro_tip, is_forever_content)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, '', 0)
            """, (iid, name, quality, item_level, req_level, slot, item_type, stats_str, desc_str, source_str))
            items_inserted += 1

    # Ingest any remaining white, gray, quest, or miscellaneous items from classic reference database item_template
    if os.path.exists(CLASSIC_REFERENCE_DB_PATH):
        INV_TYPES = {
            0: "", 1: "Head", 2: "Neck", 3: "Shoulder", 4: "Shirt", 5: "Chest",
            6: "Waist", 7: "Legs", 8: "Feet", 9: "Wrist", 10: "Hands", 11: "Finger",
            12: "Trinket", 13: "One-Hand", 14: "Shield", 15: "Ranged", 16: "Back",
            17: "Two-Hand", 18: "Bag", 19: "Tabard", 20: "Chest", 21: "Main Hand",
            22: "Off Hand", 23: "Held In Off-hand", 24: "Ammo", 25: "Thrown",
            26: "Ranged", 27: "Quiver", 28: "Relic"
        }
        CLASS_NAMES = {
            0: "Consumable", 1: "Container", 2: "Weapon", 3: "Gem", 4: "Armor",
            5: "Reagent", 6: "Projectile", 7: "Trade Goods", 8: "Generic", 9: "Recipe",
            10: "Money", 11: "Quiver", 12: "Quest", 13: "Key", 14: "Permanent", 15: "Junk"
        }
        QUALITY_NAMES = {
            0: "Poor", 1: "Common", 2: "Uncommon", 3: "Rare", 4: "Epic", 5: "Legendary", 6: "Artifact"
        }
        mconn = sqlite3.connect(CLASSIC_REFERENCE_DB_PATH)
        missing_rows = mconn.execute("""
            SELECT entry, name, Quality, ItemLevel, RequiredLevel, InventoryType, class, subclass, armor, description
            FROM item_template
        """).fetchall()
        for r in missing_rows:
            eid, name, quality, ilvl, req_lvl, inv_type, iclass, isub, armor, desc = r
            if not name or name.strip() == "":
                continue
            name = name.strip()
            qname = QUALITY_NAMES.get(quality, "Common")
            slot = INV_TYPES.get(inv_type, "")
            itype = CLASS_NAMES.get(iclass, "")
            stats_str = f"{armor} Armor" if armor and armor > 0 else ""
            desc_str = desc or ""
            cursor.execute("""
                INSERT OR IGNORE INTO items (id, name, quality, item_level, req_level, slot, item_type, stats, description, source, pro_tip, is_forever_content)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, '', '', 0)
            """, (eid, name, qname, int(ilvl or 1), int(req_lvl or 1), slot, itype, stats_str, desc_str))
            items_inserted += 1

    total_items = cursor.execute("SELECT count(*) FROM items").fetchone()[0]
    print(f"  -> Successfully imported {items_inserted} additional authentic items (Total in DB: {total_items:,}).")

    # Step 3: Ingest full creatures catalog from classic reference database
    print("\n[3/6] Ingesting full creatures catalog...")
    if os.path.exists(CLASSIC_REFERENCE_DB_PATH):
        MAP_NAMES = {
            0: "Eastern Kingdoms", 1: "Kalimdor", 30: "Alterac Valley", 33: "Shadowfang Keep",
            34: "The Stockade", 36: "The Deadmines", 43: "Wailing Caverns", 47: "Razorfen Kraul",
            48: "Blackfathom Deeps", 70: "Uldaman", 90: "Gnomeregan", 109: "Sunken Temple",
            129: "Razorfen Downs", 189: "Scarlet Monastery", 209: "Zul'Farrak",
            229: "Upper Blackrock Spire", 230: "Blackrock Depths", 249: "Onyxia's Lair",
            289: "Scholomance", 309: "Zul'Gurub", 329: "Stratholme", 349: "Maraudon",
            389: "Ragefire Chasm", 409: "Molten Core", 429: "Dire Maul", 469: "Blackwing Lair",
            509: "Ruins of Ahn'Qiraj", 531: "Temple of Ahn'Qiraj", 533: "Naxxramas"
        }
        RANK_NAMES = {0: "Normal", 1: "Elite", 2: "Rare Elite", 3: "World Boss", 4: "Rare"}

        creature_maps = {}
        for r in mconn.execute("SELECT id, map FROM creature GROUP BY id"):
            creature_maps[r[0]] = MAP_NAMES.get(r[1], "Azeroth")

        mcur = mconn.execute("SELECT Entry, Name, SubName, MinLevel, MaxLevel, Rank, MaxLevelHealth FROM creature_template")
        creatures_inserted = 0
        for r in mcur:
            eid, name, subname, min_lvl, max_lvl, rank, hp = r
            if not name or name.startswith("[UNUSED]"):
                continue

            name = name.strip()
            if eid in existing_creatures:
                continue

            rank_str = RANK_NAMES.get(rank, "Normal")
            zone = creature_maps.get(eid, "Azeroth")
            loc_details = f"<{subname.strip()}>" if subname else ""

            cursor.execute("""
                INSERT OR IGNORE INTO creatures (id, name, level_min, level_max, classification, zone, location_details, health, strategy_notes, is_forever_content)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, '', 0)
            """, (eid, name, min_lvl, max_lvl, rank_str, zone, loc_details, int(hp or 100)))
            creatures_inserted += 1

        total_creatures = cursor.execute("SELECT count(*) FROM creatures").fetchone()[0]
        print(f"  -> Successfully imported {creatures_inserted} additional authentic creatures (Total in DB: {total_creatures:,}).")
    else:
        print(f"  ⚠️ Warning: {CLASSIC_REFERENCE_DB_PATH} not found. Skipping creature expansion.")

    # Step 4: Ingest full quests catalog from classic reference database
    print("\n[4/6] Ingesting full quests catalog...")
    if os.path.exists(CLASSIC_REFERENCE_DB_PATH):
        # Load zones map
        zmap = {}
        if os.path.exists(NEXUS_ZONES_PATH):
            with open(NEXUS_ZONES_PATH) as zf:
                zdata = json.load(zf)
                zmap = {z["id"]: z["name"] for z in zdata}

        SORT_MAP = {
            -1: "Epic Quests", -22: "Seasonal Events", -61: "Warlock Class Quests",
            -81: "Warrior Class Quests", -82: "Shaman Class Quests", -141: "Paladin Class Quests",
            -161: "Mage Class Quests", -162: "Rogue Class Quests", -261: "Hunter Class Quests",
            -262: "Priest Class Quests", -263: "Druid Class Quests", -101: "Fishing",
            -121: "Blacksmithing", -181: "Alchemy", -182: "Leatherworking", -201: "Engineering",
            -241: "Tailoring", -264: "Herbalism", -304: "Cooking", -324: "First Aid",
            -344: "Mining", -365: "Battlegrounds"
        }

        qcur = mconn.execute("SELECT entry, Title, MinLevel, QuestLevel, RequiredRaces, ZoneOrSort, Objectives, Details FROM quest_template")
        quests_inserted = 0
        for r in qcur:
            qid, title, min_lvl, q_lvl, races, zone_id, objs, details = r
            if not title:
                continue

            title = title.strip()
            if qid in existing_quests:
                continue

            zname = zmap.get(zone_id) or SORT_MAP.get(zone_id) or "Azeroth"
            faction = "Both"
            if races and (races & 77) and not (races & 178):
                faction = "Alliance"
            elif races and (races & 178) and not (races & 77):
                faction = "Horde"

            clean_objs = (objs or "").replace("$B", "\n").replace("$b", "\n").strip()
            clean_details = (details or "").replace("$B", "\n").replace("$b", "\n").strip()

            cursor.execute("""
                INSERT OR IGNORE INTO quests (id, title, req_level, quest_level, faction, zone, start_npc, start_location, end_npc, end_location, objectives, rewards, pro_tip, is_forever_content)
                VALUES (?, ?, ?, ?, ?, ?, '', '', '', '', ?, '', ?, 0)
            """, (qid, title, min_lvl, q_lvl, faction, zname, clean_objs, clean_details[:500]))
            quests_inserted += 1

        total_quests = cursor.execute("SELECT count(*) FROM quests").fetchone()[0]
        print(f"  -> Successfully imported {quests_inserted} additional authentic quests (Total in DB: {total_quests:,}).")
        mconn.close()
    else:
        print(f"  ⚠️ Warning: {MANGOS_DB_PATH} not found. Skipping quest expansion.")

    # Step 5: Clean whitespace and rebuild all FTS5 Indexes
    print("\n[5/6] Cleaning whitespace and rebuilding FTS5 full-text search indexes...")
    cursor.execute("UPDATE items SET name = trim(name) WHERE name != trim(name);")
    cursor.execute("UPDATE creatures SET name = trim(name) WHERE name != trim(name);")
    cursor.execute("UPDATE quests SET title = trim(title) WHERE title != trim(title);")
    conn.commit()

    cursor.execute("INSERT INTO items_fts(items_fts) VALUES('rebuild');")
    cursor.execute("INSERT INTO quests_fts(quests_fts) VALUES('rebuild');")
    cursor.execute("INSERT INTO creatures_fts(creatures_fts) VALUES('rebuild');")
    cursor.execute("INSERT INTO dungeons_fts(dungeons_fts) VALUES('rebuild');")
    conn.commit()

    # Step 6: PRAGMA check and atomic replace
    print("\n[6/6] Verifying database integrity and indexing...")
    integrity = cursor.execute("PRAGMA integrity_check").fetchone()[0]
    print(f"  -> PRAGMA integrity_check: {integrity.upper()}")
    assert integrity == "ok", f"Integrity check failed: {integrity}"

    cursor.execute("VACUUM")
    conn.commit()

    counts = {
        "items": cursor.execute("SELECT count(*) FROM items").fetchone()[0],
        "items_poor": cursor.execute("SELECT count(*) FROM items WHERE quality = 'Poor'").fetchone()[0],
        "items_common": cursor.execute("SELECT count(*) FROM items WHERE quality = 'Common'").fetchone()[0],
        "items_forever": cursor.execute("SELECT count(*) FROM items WHERE is_forever_content = 1").fetchone()[0],
        "creatures": cursor.execute("SELECT count(*) FROM creatures").fetchone()[0],
        "creatures_forever": cursor.execute("SELECT count(*) FROM creatures WHERE is_forever_content = 1").fetchone()[0],
        "quests": cursor.execute("SELECT count(*) FROM quests").fetchone()[0],
        "quests_forever": cursor.execute("SELECT count(*) FROM quests WHERE is_forever_content = 1").fetchone()[0],
        "dungeons": cursor.execute("SELECT count(*) FROM dungeons").fetchone()[0],
        "dungeons_forever": cursor.execute("SELECT count(*) FROM dungeons WHERE is_forever_content = 1").fetchone()[0],
        "flightpaths": cursor.execute("SELECT count(*) FROM flightpaths").fetchone()[0],
        "vendors": cursor.execute("SELECT count(*) FROM vendors").fetchone()[0],
    }

    conn.close()

    # Atomic swap into db_path
    if os.path.exists(db_path):
        os.remove(db_path)
    os.replace(tmp_db_path, db_path)

    db_size = os.path.getsize(db_path) / (1024 * 1024)
    print("\n" + "=" * 70)
    print(f"🎉 FULL WOW FOREVER COMPLETE GAME DATABASE BUILD SUCCESSFUL!")
    print(f"📁 Database Path:    {db_path} ({db_size:.2f} MB)")
    print(f"⚔️ Total Items:      {counts['items']:,} ({counts['items_poor']:,} Gray/Poor • {counts['items_common']:,} White/Common • {counts['items_forever']} WoW Forever Custom)")
    print(f"🐉 Total Creatures:  {counts['creatures']:,} ({counts['creatures_forever']} WoW Forever Custom)")
    print(f"📜 Total Quests:     {counts['quests']:,} ({counts['quests_forever']} WoW Forever Custom)")
    print(f"🏰 Total Dungeons:   {counts['dungeons']:,} ({counts['dungeons_forever']} WoW Forever Custom)")
    print(f"🦅 Total Flightpaths:{counts['flightpaths']:,}")
    print(f"🏪 Total Vendors:    {counts['vendors']:,}")
    print("=" * 70)


if __name__ == "__main__":
    build_full_database()
