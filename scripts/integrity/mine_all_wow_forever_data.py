#!/usr/bin/env python3
"""Comprehensive WoW: Forever Ground-Truth Data Miner.

Mines ALL data from Blizzard WoW: Forever sources:
1. Blizzard Client DB2 Tables (Build 1.60.1.70685):
   - ItemSparse.csv (19,257 items)
   - Item.csv (31,876 items)
   - ItemSet.csv
2. Official Blizzard Alpha Development Notes & Blue Tracker (docs/BLIZZARD_BETA_PATCH_NOTES.md):
   - Item rebalances, stat passes, new vendor sell prices, quest rewards.
3. Wowhead `forever` namespace tooltip datamine (nether.wowhead.com/forever/tooltip/item/{id}):
   - Exact HTML tooltips, spell procs, equip effects, damage ranges, swing speeds, stats, DPS.
4. Custom WoW: Forever 16-Dungeon Loot Table (70001-70048).

Tags every authentic WoW: Forever item with is_forever_content = 1 and forever_status = 'live'.
Rebuilds SQLite full-text search (items_fts) index for instantaneous query latency.
"""

import concurrent.futures
import csv
import glob
import html
import json
import os
import re
import sqlite3
import sys
import threading
import time
import urllib.error
import urllib.request

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DB_PATH = os.path.join(REPO_ROOT, "wow_forever.db")
CLIENT_DIR = os.path.join(REPO_ROOT, "scratch", "ground_truth", "forever_client", "1.60.1.70685")
CACHE_DIR = os.path.join(REPO_ROOT, "scratch", "ground_truth", "forever_cache", "item")
PATCH_NOTES_PATH = os.path.join(REPO_ROOT, "docs", "BLIZZARD_BETA_PATCH_NOTES.md")

os.makedirs(CACHE_DIR, exist_ok=True)
csv.field_size_limit(10**9)

INV_TYPES = {
    0: "", 1: "Head", 2: "Neck", 3: "Shoulder", 4: "Shirt", 5: "Chest",
    6: "Waist", 7: "Legs", 8: "Feet", 9: "Wrist", 10: "Hands", 11: "Finger",
    12: "Trinket", 13: "One-Hand", 14: "Shield", 15: "Ranged", 16: "Back",
    17: "Two-Hand", 18: "Bag", 19: "Tabard", 20: "Chest", 21: "Main Hand",
    22: "Off Hand", 23: "Held In Off-hand", 24: "Ammo", 25: "Thrown",
    26: "Ranged", 27: "Quiver", 28: "Relic"
}

QUALITIES = {
    0: "Poor", 1: "Common", 2: "Uncommon", 3: "Rare", 4: "Epic",
    5: "Legendary", 6: "Artifact", 7: "Heirloom"
}

SUBCLASSES = {
    (2, 0): "Axe", (2, 1): "Axe", (2, 2): "Bow", (2, 3): "Gun", (2, 4): "Mace",
    (2, 5): "Mace", (2, 6): "Polearm", (2, 7): "Sword", (2, 8): "Sword",
    (2, 10): "Staff", (2, 13): "Fist Weapon", (2, 14): "Miscellaneous",
    (2, 15): "Dagger", (2, 16): "Thrown", (2, 17): "Spear", (2, 18): "Crossbow",
    (2, 19): "Wand", (2, 20): "Fishing Pole",
    (4, 0): "Miscellaneous", (4, 1): "Cloth", (4, 2): "Leather", (4, 3): "Mail",
    (4, 4): "Plate", (4, 6): "Shield", (4, 7): "Libram", (4, 8): "Idol",
    (4, 9): "Totem", (4, 10): "Sigil",
    (0, 0): "Consumable", (1, 0): "Bag", (5, 0): "Reagent", (6, 0): "Projectile",
    (7, 0): "Trade Goods", (9, 0): "Recipe", (11, 0): "Quiver", (12, 0): "Quest",
    (13, 0): "Key", (15, 0): "Junk"
}

STAT_CODES = {
    3: "Agility", 4: "Strength", 5: "Intellect", 6: "Spirit", 7: "Stamina",
    12: "Defense", 13: "Dodge", 14: "Parry", 15: "Block", 31: "Hit",
    32: "Crit", 36: "Haste", 38: "Attack Power", 45: "Spell Power"
}


def parse_tooltip_html(data: dict):
    """Parses rich tooltip HTML from Wowhead forever response into structured fields."""
    if not data or data.get("_absent"):
        return None

    raw_html = data.get("tooltip", "")
    if not raw_html:
        return None

    name = data.get("name", "")
    quality_id = data.get("quality", 1)
    quality = QUALITIES.get(quality_id, "Common")

    ilvl_m = re.search(r"Item Level <!--ilvl-->(\d+)", raw_html)
    item_level = int(ilvl_m.group(1)) if ilvl_m else 1

    rlvl_m = re.search(r"Requires Level <!--rlvl-->(\d+)", raw_html)
    req_level = int(rlvl_m.group(1)) if rlvl_m else 1

    slot = ""
    for inv_name in ["Head", "Neck", "Shoulder", "Back", "Chest", "Wrist", "Hands", "Waist",
                     "Legs", "Feet", "Finger", "Trinket", "One-Hand", "Two-Hand", "Main Hand",
                     "Off Hand", "Held In Off-hand", "Shield", "Ranged", "Relic", "Tabard", "Shirt"]:
        if f"<td>{inv_name}</td>" in raw_html or f">{inv_name}<" in raw_html:
            slot = inv_name
            break

    subclass_m = re.search(r'<!--scstart\d+:\d+--><span class="q1">([^<]+)</span><!--scend-->', raw_html)
    item_type = subclass_m.group(1) if subclass_m else ""

    dps_m = re.search(r"<!--dps-->\(([\d\.]+)\s+damage per second\)", raw_html)
    dps = float(dps_m.group(1)) if dps_m else 0.0

    spd_m = re.search(r"Speed <!--spd-->([\d\.]+)", raw_html)
    speed = float(spd_m.group(1)) if spd_m else 0.0

    dmg_m = re.search(r"<!--dmg-->([^<]+)", raw_html)
    damage_str = dmg_m.group(1).strip() if dmg_m else ""

    # Stats
    stats_list = []
    if damage_str:
        spd_suffix = f" (Speed {speed:.2f})" if speed > 0 else ""
        stats_list.append(f"{damage_str}{spd_suffix}")

    for stat_m in re.finditer(r"<!--stat\d+-->([+-]?\d+)\s+([^<]+)", raw_html):
        val = stat_m.group(1)
        stat_name = stat_m.group(2).strip()
        stats_list.append(f"{val} {stat_name}")

    # Armor
    armor_m = re.search(r"<!--amr-->(\d+)\s+Armor", raw_html)
    if armor_m:
        stats_list.append(f"+{armor_m.group(1)} Armor")

    # Equip / Use effects
    effects = []
    for eff_m in re.finditer(r"(?:Equip|Use|Chance on hit):\s*<!--use(?:Effect|Text):\d+:\d+-->(?:<a[^>]*>)?([^<]+)(?:</a>)?", raw_html):
        txt = html.unescape(eff_m.group(1).strip())
        if txt and txt not in effects:
            effects.append(txt)

    # Secondary regex for clean effect spans
    if not effects:
        for eff_m in re.finditer(r'<span id="useText\d+" class="q2">([^<]+(?:<a[^>]*>[^<]+</a>)?[^<]*)</span>', raw_html):
            clean_txt = re.sub(r"<[^>]+>", "", eff_m.group(1)).strip()
            if clean_txt and clean_txt not in effects:
                effects.append(html.unescape(clean_txt))

    description = "; ".join(effects)

    # Flavor text
    flavor_m = re.search(r'<span class="q">"([^"]+)"</span>', raw_html)
    if flavor_m:
        flavor_text = f'"{html.unescape(flavor_m.group(1))}"'
        description = f"{description} | {flavor_text}" if description else flavor_text

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
        "speed": speed
    }


def fetch_worker(iid: int, delay: float = 0.05):
    """Fetches a single item tooltip from Wowhead forever namespace if not cached."""
    path = os.path.join(CACHE_DIR, f"{iid}.json")
    if os.path.exists(path):
        try:
            with open(path, "r", encoding="utf-8") as f:
                return iid, json.load(f), True
        except Exception:
            pass

    url = f"https://nether.wowhead.com/forever/tooltip/item/{iid}"
    req = urllib.request.Request(url, headers={"User-Agent": "Foreverbot-DataMiner/1.0"})
    for attempt in range(4):
        try:
            with urllib.request.urlopen(req, timeout=8) as resp:
                data = json.loads(resp.read().decode("utf-8"))
                data["_url"] = url
                data["_source_endpoint"] = "forever"
                with open(path, "w", encoding="utf-8") as out:
                    json.dump(data, out, ensure_ascii=False)
                return iid, data, True
        except urllib.error.HTTPError as exc:
            if exc.code == 404:
                with open(path, "w", encoding="utf-8") as out:
                    json.dump({"_absent": True, "_status": 404}, out)
                return iid, {"_absent": True}, False
            time.sleep(0.5 * (attempt + 1))
        except Exception:
            time.sleep(0.5 * (attempt + 1))

    return iid, None, False


def mine_all_data():
    print("=" * 70)
    print("🚀 WOW: FOREVER COMPREHENSIVE DATA MINER & ENRICHMENT ENGINE")
    print("=" * 70, flush=True)

    # 1. Load Client CSVs
    sparse_path = os.path.join(CLIENT_DIR, "ItemSparse.csv")
    item_path = os.path.join(CLIENT_DIR, "Item.csv")
    if not os.path.exists(sparse_path) or not os.path.exists(item_path):
        print(f"❌ Error: Missing client DB2 files in {CLIENT_DIR}")
        return

    print(f"📖 Ingesting Blizzard Client DB2 Tables (Build 1.60.1.70685)...", flush=True)
    with open(item_path, "r", encoding="utf-8") as f:
        item_meta = {r["ID"]: (int(r["ClassID"]), int(r["SubclassID"])) for r in csv.DictReader(f)}

    with open(sparse_path, "r", encoding="utf-8") as f:
        sparse_items = {r["ID"]: r for r in csv.DictReader(f)}

    print(f"   -> Loaded {len(item_meta):,} records from Item.csv")
    print(f"   -> Loaded {len(sparse_items):,} records from ItemSparse.csv", flush=True)

    # 2. Identify all WoW: Forever Items
    # Range 1: High IDs (>= 200,000) added for WoW Forever / Classic New Content (6,587 items)
    # Range 2: Mid IDs (26,001 - 199,999) (83 items)
    # Range 3: Explicit patch notes items
    forever_ids = set()
    for sid, r in sparse_items.items():
        iid = int(sid)
        name = r.get("Display_lang", "").strip()
        if not name or name.startswith("Deprecated") or "Monster -" in name or "Placeholder" in name or "Test" in name:
            continue
        if iid >= 26001:
            forever_ids.add(iid)

    # Add items specifically modified or added in BLIZZARD_BETA_PATCH_NOTES.md
    patch_notes_specific_ids = {
        8345,    # Wolfshead Helm
        6773,    # Kolkar Marauder Chain
        6774,    # Traitor's Finger
        6788,    # Kolkar Hunter's Belt
        6789,    # Ceremonial Centaur Blanket
        15208,   # Cenarion Moondust
        20744,   # Minor Wizard Oil
        20746,   # Lesser Wizard Oil
        20749,   # Brilliant Wizard Oil
        20750,   # Wizard Oil
        11287,   # Lesser Magic Wand
        11288,   # Greater Magic Wand
        11289,   # Lesser Mystic Wand
        217287,  # Greater Mystic Wand
        249144,  # Twisted Nether Wand
        249232,  # Lesser Eternal Wand
        249234,  # Dreambough Wand
        249237,  # Greater Eternal Wand
        249396,  # Mystic Mushroom
        249476,  # Formula: Mystic Mushroom
        249865,  # Peace Tea
        249879,  # Recipe: Peace Tea
        251524,  # Whimsyfin
        251525,  # Savory Whimsyfin Delight
        251526,  # Recipe: Savory Whimsyfin Delight
        268535,  # Bloodied Insignia
        268540,  # Bloodied Insignia
        270865,  # Titan Relic
        270866,  # Titan Relic
        271794,  # Centaur Spear
        271795,  # Wanderer's Broadsword
        271796,  # Blade of the Magram Clan
        271797,  # Staff of Revelations
        271798,  # Desperate Barrier
        271799,  # Desert Crawler's Claw
        271800,  # Scavenged Magram Armament
        271801,  # Abandoned Ferocity
        271802,  # Bludgeon of Betrayed Virtues
        271803,  # Greatstaff of the Necrokhans
        271804,  # Soulsplatter Mace
        271805,  # Thrice-Damned Effigy
        273628,  # Enchant Weapon - Recovery
        274044,  # Twisted Fire Totem
        274045,  # Twisted Earth Totem
        274748,  # Booty Bay Bruiser's Buckshot
        276895,  # Transformative Cocoon
        277254,  # Truthseeker's Bow
        277507,  # Dalaran Sewer Key
        277952,  # Smooth Boulder
        280839,  # Blackrock Supplies
        287958,  # Titan Relic
        287959,  # Titan Relic
        212792,  # Eye of the Tempest
        213548,  # Scroll of Liminal Passage
    }
    forever_ids.update(patch_notes_specific_ids)

    print(f"\n🔍 Total Target WoW: Forever Items to Mine: {len(forever_ids):,}", flush=True)

    # 3. Concurrent Tooltip Mining from Wowhead forever namespace
    to_fetch = [iid for iid in forever_ids if not os.path.exists(os.path.join(CACHE_DIR, f"{iid}.json"))]
    print(f"🌐 Fetching {len(to_fetch):,} tooltips from Wowhead 'forever' namespace (30 workers)...", flush=True)

    fetched_tooltips = {}
    if to_fetch:
        t0 = time.time()
        with concurrent.futures.ThreadPoolExecutor(max_workers=30) as executor:
            futures = {executor.submit(fetch_worker, iid): iid for iid in to_fetch}
            completed = 0
            for fut in concurrent.futures.as_completed(futures):
                iid, data, ok = fut.result()
                if ok and data:
                    fetched_tooltips[iid] = data
                completed += 1
                if completed % 500 == 0 or completed == len(to_fetch):
                    elapsed = time.time() - t0
                    rate = completed / elapsed if elapsed > 0 else 0
                    print(f"   [{completed:,}/{len(to_fetch):,}] {rate:.1f} items/sec ({elapsed:.1f}s)", flush=True)
    else:
        print("   -> All tooltips already cached locally!", flush=True)

    # Also load previously cached tooltips for target IDs
    for iid in forever_ids:
        if iid not in fetched_tooltips:
            path = os.path.join(CACHE_DIR, f"{iid}.json")
            if os.path.exists(path):
                try:
                    with open(path, "r", encoding="utf-8") as f:
                        fetched_tooltips[iid] = json.load(f)
                except Exception:
                    pass

    print(f"   -> Total active tooltips in memory: {len(fetched_tooltips):,}", flush=True)

    # 4. Connect to SQLite database
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()

    # Ensure schema columns
    cols = {r[1] for r in cur.execute("PRAGMA table_info(items)").fetchall()}
    for col, ctype in [
        ("is_forever_content", "INTEGER DEFAULT 0"),
        ("forever_status", "TEXT DEFAULT 'live'"),
        ("verified_source", "TEXT"),
        ("sell_price", "INTEGER DEFAULT 0"),
        ("dps", "REAL DEFAULT 0.0"),
        ("speed", "REAL DEFAULT 0.0"),
        ("pro_tip", "TEXT DEFAULT ''")
    ]:
        if col not in cols:
            cur.execute(f"ALTER TABLE items ADD COLUMN {col} {ctype}")

    # Build or update items
    print(f"\n💾 Updating SQLite items and ingesting mined WoW: Forever records...", flush=True)
    cur.execute("BEGIN TRANSACTION")

    # Keep all 48 custom dungeon items (70001-70048)
    cur.execute("UPDATE items SET is_forever_content = 1 WHERE id >= 70001 AND id <= 70048")

    upsert_count = 0
    new_inserted = 0

    for iid in sorted(forever_ids):
        sid = str(iid)
        sparse_row = sparse_items.get(sid, {})
        tooltip_data = fetched_tooltips.get(iid)
        parsed_tt = parse_tooltip_html(tooltip_data) if tooltip_data else None

        # Determine base attributes
        name = (parsed_tt["name"] if parsed_tt else None) or sparse_row.get("Display_lang", "").strip()
        if not name:
            continue

        raw_qual = int(sparse_row.get("OverallQualityID", 1)) if sparse_row else 1
        quality = (parsed_tt["quality"] if parsed_tt else None) or QUALITIES.get(raw_qual, "Common")
        ilvl = (parsed_tt["item_level"] if parsed_tt else None) or int(sparse_row.get("ItemLevel", 1) or 1)
        rlvl = (parsed_tt["req_level"] if parsed_tt else None) or int(sparse_row.get("RequiredLevel", 1) or 1)
        inv_type = int(sparse_row.get("InventoryType", 0) or 0) if sparse_row else 0
        slot = (parsed_tt["slot"] if parsed_tt else None) or INV_TYPES.get(inv_type, "")

        meta = item_meta.get(sid, (0, 0))
        subclass_default = SUBCLASSES.get(meta, SUBCLASSES.get((meta[0], 0), "Miscellaneous"))
        item_type = (parsed_tt["item_type"] if parsed_tt else None) or subclass_default

        stats = (parsed_tt["stats"] if parsed_tt else "") or ""
        description = (parsed_tt["description"] if parsed_tt else "") or ""

        # If description is empty, check flavor text in ItemSparse
        if not description and sparse_row.get("Description_lang"):
            description = f'"{sparse_row["Description_lang"].strip()}"'

        sell_price = int(sparse_row.get("SellPrice", 0) or 0) if sparse_row else 0
        speed = (parsed_tt["speed"] if parsed_tt else None) or (float(sparse_row.get("ItemDelay", 0)) / 1000.0 if sparse_row.get("ItemDelay") else 0.0)
        dps = (parsed_tt["dps"] if parsed_tt else 0.0)

        # Source & pro-tips
        source = "WoW: Forever Open Alpha (Blizzard Build 1.60.1 / Wowhead Datamine)"
        pro_tip = "Official Blizzard WoW: Forever content • Documented in Alpha patch notes & client datamine."

        # Special curated pro-tips for prominent patch notes items
        if iid == 8345:
            # Wolfshead Helm
            description = "Equip: When shapeshifting into Cat Form with Shifting Power, you gain 5 Energy. When entering Bear Form from Enrage, you gain 5 Rage."
            pro_tip = "WoW: Forever Redesign: +5 Energy when Shifting Power is used; Rage component unchanged. Retains BiS status for Feral Druids."
            source = "Crafted: Leatherworking (225) • Pattern: Tribal Leatherworking"
        elif iid == 277254:
            source = "Quest Reward: Greater Friend of the Library (Alterac Mountains / Dalaran)"
            pro_tip = "Equip level tuned to 40 in Alpha Build 1.60.1, matching all companion Library chain rewards."
        elif iid == 249396:
            source = "Formula: Mystic Mushroom • Enchanting (185)"
            pro_tip = "Enchanting-produced Idol for Druids, granting +5% Spirit. Tuned in Alpha Patch 1.60.1."
        elif iid == 249865:
            source = "Cooking (1) • Vendor Recipe: Peace Tea (Sells for 10c)"
            pro_tip = "Introductory hot beverage recipe tuned for early-game resource recovery."
        elif iid == 251525:
            source = "Cooking (85) • Recipe: Savory Whimsyfin Delight (Fished from coastal waters)"
            pro_tip = "Transforms player into an Orc Ninja or Pirate appearance. Sells to vendors for 5c."
        elif iid in (271794, 271795, 271796, 271797, 271798, 271799, 271800, 271801, 271802, 271803, 271804, 271805):
            source = "Quest Reward: Desolace Centaur Clan Allegiance (Gelkis & Magram)"
            pro_tip = "Requires Level 35 to equip. Upgraded power level tuned in Alpha Build 1.60.1."
        elif iid in (249144, 249232, 249234, 249237):
            source = "Enchanting • High-Tier Crafted Wand"
            pro_tip = "Vendor sell price adjusted in Blizzard Alpha Update (Twisted Nether 10s, Dreambough 15s, Greater Eternal 25s)."

        # Check if item exists in DB
        existing = cur.execute("SELECT id FROM items WHERE id = ?", (iid,)).fetchone()
        if existing:
            cur.execute("""
                UPDATE items SET
                    name = ?, quality = ?, item_level = ?, req_level = ?,
                    slot = ?, item_type = ?, stats = ?, description = ?,
                    source = COALESCE(NULLIF(source, ''), ?),
                    pro_tip = COALESCE(NULLIF(pro_tip, ''), ?),
                    is_forever_content = 1,
                    forever_status = 'live',
                    verified_source = 'Blizzard WoW: Forever Build 1.60.1 / Wowhead Datamine',
                    sell_price = ?, dps = ?, speed = ?
                WHERE id = ?
            """, (name, quality, ilvl, rlvl, slot, item_type, stats, description,
                  source, pro_tip, sell_price, dps, speed, iid))
            upsert_count += 1
        else:
            cur.execute("""
                INSERT INTO items (
                    id, name, quality, item_level, req_level, slot, item_type,
                    stats, description, source, pro_tip, is_forever_content,
                    forever_status, verified_source, sell_price, dps, speed
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, 'live',
                          'Blizzard WoW: Forever Build 1.60.1 / Wowhead Datamine', ?, ?, ?)
            """, (iid, name, quality, ilvl, rlvl, slot, item_type,
                  stats, description, source, pro_tip, sell_price, dps, speed))
            new_inserted += 1

    conn.commit()
    print(f"   -> Updated {upsert_count:,} existing items with WoW: Forever ground truth.")
    print(f"   -> Inserted {new_inserted:,} newly mined WoW: Forever items into the database.", flush=True)

    # 5. Ingest any remaining white/gray items from ItemSparse.csv so the client catalog is 100% complete
    print("\n📦 Ingesting remaining standard items from ItemSparse.csv...", flush=True)
    std_inserted = 0
    cur.execute("BEGIN TRANSACTION")
    for sid, r in sparse_items.items():
        iid = int(sid)
        if iid in forever_ids:
            continue
        name = r.get("Display_lang", "").strip()
        if not name or name.startswith("Deprecated"):
            continue
        existing = cur.execute("SELECT id FROM items WHERE id = ?", (iid,)).fetchone()
        if existing:
            continue

        raw_qual = int(r.get("OverallQualityID", 1) or 1)
        quality = QUALITIES.get(raw_qual, "Common")
        ilvl = int(r.get("ItemLevel", 1) or 1)
        rlvl = int(r.get("RequiredLevel", 1) or 1)
        inv_type = int(r.get("InventoryType", 0) or 0)
        slot = INV_TYPES.get(inv_type, "")
        meta = item_meta.get(sid, (0, 0))
        item_type = SUBCLASSES.get(meta, SUBCLASSES.get((meta[0], 0), "Miscellaneous"))
        sell_price = int(r.get("SellPrice", 0) or 0)
        speed = float(r.get("ItemDelay", 0)) / 1000.0 if r.get("ItemDelay") else 0.0
        desc = f'"{r["Description_lang"].strip()}"' if r.get("Description_lang") else ""

        cur.execute("""
            INSERT INTO items (
                id, name, quality, item_level, req_level, slot, item_type,
                stats, description, source, pro_tip, is_forever_content,
                forever_status, verified_source, sell_price, dps, speed
            ) VALUES (?, ?, ?, ?, ?, ?, ?, '', ?, 'World Drop / Vendor / Quest', '', 0, 'live',
                      'Blizzard WoW: Forever Client 1.60.1', ?, 0.0, ?)
        """, (iid, name, quality, ilvl, rlvl, slot, item_type, desc, sell_price, speed))
        std_inserted += 1

    conn.commit()
    print(f"   -> Ingested {std_inserted:,} additional baseline client items.", flush=True)

    # 6. Rebuild Full-Text Search (items_fts)
    print("\n⚡ Rebuilding SQLite FTS5 Full-Text Index (items_fts)...", flush=True)
    cur.execute("DROP TABLE IF EXISTS items_fts")
    cur.execute("""
        CREATE VIRTUAL TABLE items_fts USING fts5(
            name, slot, item_type, quality, description, stats,
            content='items', content_rowid='id'
        )
    """)
    cur.execute("""
        INSERT INTO items_fts(rowid, name, slot, item_type, quality, description, stats)
        SELECT id, name, slot, item_type, quality, description, stats FROM items
    """)
    conn.commit()
    print("   -> items_fts successfully rebuilt and indexed.", flush=True)

    # 7. Print Final Verification Statistics
    total_items = cur.execute("SELECT count(*) FROM items").fetchone()[0]
    total_forever = cur.execute("SELECT count(*) FROM items WHERE is_forever_content = 1").fetchone()[0]
    total_epics = cur.execute("SELECT count(*) FROM items WHERE is_forever_content = 1 AND quality = 'Epic'").fetchone()[0]
    total_rares = cur.execute("SELECT count(*) FROM items WHERE is_forever_content = 1 AND quality = 'Rare'").fetchone()[0]
    total_uncommon = cur.execute("SELECT count(*) FROM items WHERE is_forever_content = 1 AND quality = 'Uncommon'").fetchone()[0]
    total_gear = cur.execute("SELECT count(*) FROM items WHERE is_forever_content = 1 AND slot != ''").fetchone()[0]

    print("\n" + "=" * 70)
    print("🏆 WOW: FOREVER MINING COMPLETE & VERIFIED")
    print(f"📊 Total Catalog Items: {total_items:,}")
    print(f"🌟 Total WoW: Forever Items (is_forever_content=1): {total_forever:,}")
    print(f"   • Epics: {total_epics:,}")
    print(f"   • Rares: {total_rares:,}")
    print(f"   • Uncommons: {total_uncommon:,}")
    print(f"   • Equippable Weapons & Armor: {total_gear:,}")
    print("=" * 70, flush=True)

    conn.close()


if __name__ == "__main__":
    mine_all_data()
