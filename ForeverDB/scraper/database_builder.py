#!/usr/bin/env python3
"""
ForeverDB/scraper/database_builder.py

Populates the production SQLite database at ForeverDB/database/forever_master.sqlite
with fully normalized tables, primary keys, foreign keys, and indexes across all 15 categories
and 11 relationship tables.

Also exports category-specific JSON files to ForeverDB/exports/.
"""

import os
import sys
import json
import sqlite3
import time
from typing import Dict, List, Any

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATABASE_DIR = os.path.join(BASE_DIR, "database")
EXPORTS_DIR = os.path.join(BASE_DIR, "exports")
METADATA_DIR = os.path.join(BASE_DIR, "metadata")
DB_PATH = os.path.join(DATABASE_DIR, "forever_master.sqlite")

from record_extractor import extract_all_categories
from relationship_extractor import extract_all_relationships


def init_database(db_path: str = DB_PATH) -> sqlite3.Connection:
    """Initialize SQLite database with comprehensive schema and indexes."""
    os.makedirs(os.path.dirname(db_path), exist_ok=True)
    if os.path.exists(db_path):
        os.remove(db_path)

    conn = sqlite3.connect(db_path)
    cur = conn.cursor()
    cur.execute("PRAGMA journal_mode = WAL;")
    cur.execute("PRAGMA synchronous = NORMAL;")
    cur.execute("PRAGMA foreign_keys = ON;")

    # 1. Metadata table
    cur.execute("""
    CREATE TABLE build_info (
        key TEXT PRIMARY KEY,
        product TEXT NOT NULL,
        version TEXT NOT NULL,
        build_id INTEGER NOT NULL,
        build_name TEXT,
        build_config TEXT,
        cdn_config TEXT,
        extracted_at TEXT,
        built_at TEXT,
        world_source TEXT,
        world_commit TEXT,
        world_licence TEXT,
        meta_json TEXT
    );
    """)

    # 2. Items
    cur.execute("""
    CREATE TABLE items (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        quality INTEGER NOT NULL,
        quality_name TEXT NOT NULL,
        icon TEXT NOT NULL,
        ilvl INTEGER NOT NULL,
        req_level INTEGER NOT NULL,
        class_id INTEGER,
        class_name TEXT,
        subclass_id INTEGER,
        subclass_name TEXT,
        subclass_verbose TEXT,
        inv_type INTEGER,
        slot TEXT,
        type_name TEXT,
        bind_type INTEGER,
        max_count INTEGER,
        unique_equipped BOOLEAN,
        stackable INTEGER,
        armor INTEGER,
        delay INTEGER,
        dps REAL,
        durability INTEGER,
        class_mask INTEGER,
        req_skill INTEGER,
        req_faction INTEGER,
        item_set_id INTEGER,
        description TEXT,
        sell_price INTEGER,
        buy_price INTEGER,
        start_quest INTEGER,
        container_slots INTEGER,
        flags TEXT,
        expansion INTEGER,
        is_internal BOOLEAN,
        is_withheld BOOLEAN,
        withheld_fields TEXT,
        stats TEXT,
        resists TEXT,
        damage TEXT,
        effects TEXT,
        classes TEXT,
        races TEXT,
        tooltip TEXT,
        build_id TEXT NOT NULL,
        source_url TEXT NOT NULL
    );
    """)
    cur.execute("CREATE INDEX idx_items_name ON items(name);")
    cur.execute("CREATE INDEX idx_items_ilvl ON items(ilvl);")
    cur.execute("CREATE INDEX idx_items_req_level ON items(req_level);")
    cur.execute("CREATE INDEX idx_items_quality ON items(quality);")
    cur.execute("CREATE INDEX idx_items_class_subclass ON items(class_id, subclass_id);")
    cur.execute("CREATE INDEX idx_items_slot ON items(slot);")
    cur.execute("CREATE INDEX idx_items_internal ON items(is_internal);")

    # 3. Spells
    cur.execute("""
    CREATE TABLE spells (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        rank TEXT,
        icon TEXT NOT NULL,
        school TEXT NOT NULL,
        class_id INTEGER,
        class_name TEXT,
        kind TEXT,
        skill_line INTEGER,
        skill_name TEXT,
        level INTEGER,
        max_level INTEGER,
        spell_level INTEGER,
        cost TEXT,
        range TEXT,
        cast_time TEXT,
        cooldown TEXT,
        duration TEXT,
        duration_ms INTEGER,
        dispel TEXT,
        mechanic TEXT,
        passive BOOLEAN,
        hidden BOOLEAN,
        description TEXT,
        aura_description TEXT,
        effects TEXT,
        reagents TEXT,
        tooltip TEXT,
        is_internal BOOLEAN,
        build_id TEXT NOT NULL,
        source_url TEXT NOT NULL
    );
    """)
    cur.execute("CREATE INDEX idx_spells_name ON spells(name);")
    cur.execute("CREATE INDEX idx_spells_school ON spells(school);")
    cur.execute("CREATE INDEX idx_spells_class_id ON spells(class_id);")
    cur.execute("CREATE INDEX idx_spells_level ON spells(level);")

    # 4. Talents
    cur.execute("""
    CREATE TABLE talents (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        class_id INTEGER,
        class_name TEXT,
        tab_id INTEGER,
        tab_name TEXT,
        tier INTEGER,
        col INTEGER,
        max_rank INTEGER,
        prereqs TEXT,
        ranks TEXT,
        is_internal BOOLEAN,
        build_id TEXT NOT NULL,
        source_url TEXT NOT NULL
    );
    """)
    cur.execute("CREATE INDEX idx_talents_name ON talents(name);")
    cur.execute("CREATE INDEX idx_talents_class_tab ON talents(class_id, tab_id);")

    # 5. Item Sets
    cur.execute("""
    CREATE TABLE item_sets (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        pieces_count INTEGER,
        bonuses_count INTEGER,
        pieces TEXT,
        bonuses TEXT,
        is_internal BOOLEAN,
        build_id TEXT NOT NULL,
        source_url TEXT NOT NULL
    );
    """)
    cur.execute("CREATE INDEX idx_itemsets_name ON item_sets(name);")

    # 6. Enchantments
    cur.execute("""
    CREATE TABLE enchantments (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        charges INTEGER,
        min_level INTEGER,
        req_skill INTEGER,
        req_skill_rank INTEGER,
        effects TEXT,
        tooltip TEXT,
        is_internal BOOLEAN,
        build_id TEXT NOT NULL,
        source_url TEXT NOT NULL
    );
    """)
    cur.execute("CREATE INDEX idx_enchantments_name ON enchantments(name);")

    # 7. Quests
    cur.execute("""
    CREATE TABLE quests (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        level INTEGER,
        min_level INTEGER,
        side TEXT,
        races TEXT,
        classes TEXT,
        zone_id INTEGER,
        zone_name TEXT,
        description TEXT,
        objectives_text TEXT,
        start TEXT,
        end TEXT,
        objectives TEXT,
        rewards TEXT,
        prerequisites TEXT,
        leads_to TEXT,
        exclusive_with TEXT,
        series TEXT,
        map_pins TEXT,
        tooltip TEXT,
        source TEXT,
        inherited BOOLEAN,
        is_internal BOOLEAN,
        build_id TEXT NOT NULL,
        source_url TEXT NOT NULL
    );
    """)
    cur.execute("CREATE INDEX idx_quests_name ON quests(name);")
    cur.execute("CREATE INDEX idx_quests_level ON quests(level);")
    cur.execute("CREATE INDEX idx_quests_min_level ON quests(min_level);")
    cur.execute("CREATE INDEX idx_quests_zone_id ON quests(zone_id);")
    cur.execute("CREATE INDEX idx_quests_side ON quests(side);")

    # 8. NPCs / Creatures
    cur.execute("""
    CREATE TABLE npcs (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        title TEXT,
        min_level INTEGER,
        max_level INTEGER,
        rank INTEGER,
        rank_name TEXT,
        reaction TEXT,
        type TEXT,
        family TEXT,
        classification TEXT,
        zones TEXT,
        spawns TEXT,
        drops TEXT,
        sells TEXT,
        starts_quests TEXT,
        ends_quests TEXT,
        roles TEXT,
        source TEXT,
        inherited BOOLEAN,
        tooltip TEXT,
        is_internal BOOLEAN,
        build_id TEXT NOT NULL,
        source_url TEXT NOT NULL
    );
    """)
    cur.execute("CREATE INDEX idx_npcs_name ON npcs(name);")
    cur.execute("CREATE INDEX idx_npcs_min_level ON npcs(min_level);")
    cur.execute("CREATE INDEX idx_npcs_classification ON npcs(classification);")
    cur.execute("CREATE INDEX idx_npcs_family ON npcs(family);")

    # 9. Objects / GameObjects
    cur.execute("""
    CREATE TABLE objects (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        type INTEGER,
        kind TEXT,
        reaction TEXT,
        map_id INTEGER,
        map_name TEXT,
        display_id INTEGER,
        zones TEXT,
        spawns TEXT,
        contains TEXT,
        starts_quests TEXT,
        ends_quests TEXT,
        roles TEXT,
        source TEXT,
        inherited BOOLEAN,
        tooltip TEXT,
        is_internal BOOLEAN,
        build_id TEXT NOT NULL,
        source_url TEXT NOT NULL
    );
    """)
    cur.execute("CREATE INDEX idx_objects_name ON objects(name);")
    cur.execute("CREATE INDEX idx_objects_type ON objects(type);")

    # 10. Zones
    cur.execute("""
    CREATE TABLE zones (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        key TEXT,
        map_id INTEGER,
        map_name TEXT,
        instance_type INTEGER,
        parent_id INTEGER,
        parent_name TEXT,
        level INTEGER,
        level_min INTEGER,
        level_max INTEGER,
        faction TEXT,
        is_zone BOOLEAN,
        subzones TEXT,
        flight_masters TEXT,
        dungeons TEXT,
        pois TEXT,
        entrances TEXT,
        counts TEXT,
        map_info TEXT,
        tooltip TEXT,
        is_internal BOOLEAN,
        build_id TEXT NOT NULL,
        source_url TEXT NOT NULL
    );
    """)
    cur.execute("CREATE INDEX idx_zones_name ON zones(name);")
    cur.execute("CREATE INDEX idx_zones_map_id ON zones(map_id);")

    # 11. Dungeons
    cur.execute("""
    CREATE TABLE dungeons (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        kind TEXT,
        min_level INTEGER,
        max_level INTEGER,
        map_id INTEGER,
        zone_id INTEGER,
        zone_name TEXT,
        area_id INTEGER,
        area_name TEXT,
        bosses TEXT,
        loot TEXT,
        difficulties TEXT,
        maps TEXT,
        entrance TEXT,
        entrance_zone TEXT,
        tooltip TEXT,
        is_internal BOOLEAN,
        build_id TEXT NOT NULL,
        source_url TEXT NOT NULL
    );
    """)
    cur.execute("CREATE INDEX idx_dungeons_name ON dungeons(name);")

    # 12. Factions
    cur.execute("""
    CREATE TABLE factions (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        parent_id INTEGER,
        parent_name TEXT,
        rep_index INTEGER,
        has_reputation BOOLEAN,
        expansion INTEGER,
        tooltip TEXT,
        is_internal BOOLEAN,
        build_id TEXT NOT NULL,
        source_url TEXT NOT NULL
    );
    """)
    cur.execute("CREATE INDEX idx_factions_name ON factions(name);")

    # 13. Achievements
    cur.execute("""
    CREATE TABLE achievements (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        reward TEXT,
        points INTEGER,
        category_id INTEGER,
        category_name TEXT,
        icon TEXT,
        faction TEXT,
        tooltip TEXT,
        is_internal BOOLEAN,
        build_id TEXT NOT NULL,
        source_url TEXT NOT NULL
    );
    """)
    cur.execute("CREATE INDEX idx_achievements_name ON achievements(name);")

    # 14. Classes
    cur.execute("""
    CREATE TABLE classes (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        file TEXT,
        icon TEXT,
        color TEXT,
        power_type TEXT,
        spell_class_set INTEGER,
        mask INTEGER,
        tabs TEXT,
        races TEXT,
        tooltip TEXT,
        is_internal BOOLEAN,
        build_id TEXT NOT NULL,
        source_url TEXT NOT NULL
    );
    """)

    # 15. Races
    cur.execute("""
    CREATE TABLE races (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        faction TEXT,
        bit INTEGER,
        mask INTEGER,
        tooltip TEXT,
        is_internal BOOLEAN,
        build_id TEXT NOT NULL,
        source_url TEXT NOT NULL
    );
    """)

    # 16. Skills
    cur.execute("""
    CREATE TABLE skills (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        category_id INTEGER,
        category_name TEXT,
        icon TEXT,
        parent_id INTEGER,
        spells TEXT,
        spell_count INTEGER,
        tooltip TEXT,
        is_internal BOOLEAN,
        build_id TEXT NOT NULL,
        source_url TEXT NOT NULL
    );
    """)
    cur.execute("CREATE INDEX idx_skills_name ON skills(name);")

    # -------------------------------------------------------------------------
    # Relationship Tables
    # -------------------------------------------------------------------------
    cur.execute("""
    CREATE TABLE rel_npc_drops (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        npc_id INTEGER NOT NULL,
        npc_name TEXT,
        item_id INTEGER NOT NULL,
        item_name TEXT,
        chance REAL,
        drop_type TEXT,
        zone TEXT
    );
    """)
    cur.execute("CREATE INDEX idx_reldrop_npc ON rel_npc_drops(npc_id);")
    cur.execute("CREATE INDEX idx_reldrop_item ON rel_npc_drops(item_id);")

    cur.execute("""
    CREATE TABLE rel_vendor_sells (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        npc_id INTEGER NOT NULL,
        npc_name TEXT,
        item_id INTEGER NOT NULL,
        item_name TEXT,
        cost INTEGER,
        zone TEXT
    );
    """)
    cur.execute("CREATE INDEX idx_relsell_npc ON rel_vendor_sells(npc_id);")
    cur.execute("CREATE INDEX idx_relsell_item ON rel_vendor_sells(item_id);")

    cur.execute("""
    CREATE TABLE rel_quest_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        quest_id INTEGER NOT NULL,
        quest_name TEXT,
        item_id INTEGER NOT NULL,
        item_name TEXT,
        relation TEXT NOT NULL,
        count INTEGER,
        is_choice BOOLEAN
    );
    """)
    cur.execute("CREATE INDEX idx_relqitem_quest ON rel_quest_items(quest_id);")
    cur.execute("CREATE INDEX idx_relqitem_item ON rel_quest_items(item_id);")

    cur.execute("""
    CREATE TABLE rel_quest_npcs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        quest_id INTEGER NOT NULL,
        npc_id INTEGER NOT NULL,
        npc_name TEXT,
        relation TEXT NOT NULL
    );
    """)
    cur.execute("CREATE INDEX idx_relqnpc_quest ON rel_quest_npcs(quest_id);")
    cur.execute("CREATE INDEX idx_relqnpc_npc ON rel_quest_npcs(npc_id);")

    cur.execute("""
    CREATE TABLE rel_quest_objects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        quest_id INTEGER NOT NULL,
        object_id INTEGER NOT NULL,
        object_name TEXT,
        relation TEXT NOT NULL
    );
    """)
    cur.execute("CREATE INDEX idx_relqobj_quest ON rel_quest_objects(quest_id);")
    cur.execute("CREATE INDEX idx_relqobj_object ON rel_quest_objects(object_id);")

    cur.execute("""
    CREATE TABLE rel_object_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        object_id INTEGER NOT NULL,
        object_name TEXT,
        item_id INTEGER NOT NULL,
        item_name TEXT,
        chance REAL
    );
    """)
    cur.execute("CREATE INDEX idx_relobjitem_obj ON rel_object_items(object_id);")
    cur.execute("CREATE INDEX idx_relobjitem_item ON rel_object_items(item_id);")

    cur.execute("""
    CREATE TABLE rel_quest_chains (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        quest_id INTEGER NOT NULL,
        target_quest_id INTEGER NOT NULL,
        relation TEXT NOT NULL
    );
    """)
    cur.execute("CREATE INDEX idx_relchain_q ON rel_quest_chains(quest_id);")
    cur.execute("CREATE INDEX idx_relchain_t ON rel_quest_chains(target_quest_id);")

    cur.execute("""
    CREATE TABLE rel_dungeon_bosses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dungeon_id INTEGER NOT NULL,
        dungeon_name TEXT,
        boss_id INTEGER,
        boss_name TEXT,
        npc_id INTEGER,
        encounter_order INTEGER
    );
    """)
    cur.execute("CREATE INDEX idx_reldungboss_d ON rel_dungeon_bosses(dungeon_id);")

    cur.execute("""
    CREATE TABLE rel_dungeon_loot (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dungeon_id INTEGER NOT NULL,
        dungeon_name TEXT,
        item_id INTEGER NOT NULL,
        item_name TEXT,
        boss_name TEXT
    );
    """)
    cur.execute("CREATE INDEX idx_reldungloot_d ON rel_dungeon_loot(dungeon_id);")
    cur.execute("CREATE INDEX idx_reldungloot_i ON rel_dungeon_loot(item_id);")

    cur.execute("""
    CREATE TABLE rel_item_set_pieces (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        set_id INTEGER NOT NULL,
        set_name TEXT,
        item_id INTEGER NOT NULL,
        item_name TEXT
    );
    """)
    cur.execute("CREATE INDEX idx_relset_s ON rel_item_set_pieces(set_id);")
    cur.execute("CREATE INDEX idx_relset_i ON rel_item_set_pieces(item_id);")

    cur.execute("""
    CREATE TABLE rel_zone_spawns (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_type TEXT NOT NULL,
        entity_id INTEGER NOT NULL,
        entity_name TEXT,
        area_id INTEGER,
        ui_map_id INTEGER,
        x REAL,
        y REAL,
        radius REAL
    );
    """)
    cur.execute("CREATE INDEX idx_relspawn_ent ON rel_zone_spawns(entity_type, entity_id);")
    cur.execute("CREATE INDEX idx_relspawn_map ON rel_zone_spawns(ui_map_id);")

    conn.commit()
    print(f"[+] Initialized SQLite database schema at {db_path}")
    return conn


def build_database_and_exports():
    """Extract records, populate database, extract relationships, and write JSON exports."""
    start_time = time.time()
    print("================================================================================")
    print("FOREVERDIFF DATABASE BUILDER & JSON EXPORTER")
    print("================================================================================")
    
    conn = init_database(DB_PATH)
    cur = conn.cursor()

    # Load build info
    meta_path = os.path.join(METADATA_DIR, "build_info.json")
    if os.path.exists(meta_path):
        with open(meta_path, "r", encoding="utf-8") as f:
            meta = json.load(f)
            world = meta.get("world", {})
            cur.execute("""
            INSERT OR REPLACE INTO build_info (
                key, product, version, build_id, build_name, build_config, cdn_config,
                extracted_at, built_at, world_source, world_commit, world_licence, meta_json
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                meta.get("key"), meta.get("product"), meta.get("version"), meta.get("buildId"),
                meta.get("buildName"), meta.get("buildConfig"), meta.get("cdnConfig"),
                meta.get("extractedAt"), meta.get("builtAt"), world.get("source"),
                world.get("commit"), world.get("licence"), json.dumps(meta)
            ))
            conn.commit()

    # Extract all categories
    records = extract_all_categories()
    
    # Insert items
    print("[SQL] Inserting items...")
    cur.executemany("""
    INSERT INTO items VALUES (
        :id, :name, :quality, :quality_name, :icon, :ilvl, :req_level, :class_id, :class_name,
        :subclass_id, :subclass_name, :subclass_verbose, :inv_type, :slot, :type_name,
        :bind_type, :max_count, :unique_equipped, :stackable, :armor, :delay, :dps,
        :durability, :class_mask, :req_skill, :req_faction, :item_set_id, :description,
        :sell_price, :buy_price, :start_quest, :container_slots, :flags, :expansion,
        :is_internal, :is_withheld, :withheld_fields, :stats, :resists, :damage,
        :effects, :classes, :races, :tooltip, :build_id, :source_url
    )
    """, records["items"])
    conn.commit()

    # Insert spells
    print("[SQL] Inserting spells...")
    cur.executemany("""
    INSERT INTO spells VALUES (
        :id, :name, :rank, :icon, :school, :class_id, :class_name, :kind, :skill_line,
        :skill_name, :level, :max_level, :spell_level, :cost, :range, :cast_time,
        :cooldown, :duration, :duration_ms, :dispel, :mechanic, :passive, :hidden,
        :description, :aura_description, :effects, :reagents, :tooltip, :is_internal,
        :build_id, :source_url
    )
    """, records["spells"])
    conn.commit()

    # Insert talents
    print("[SQL] Inserting talents...")
    cur.executemany("""
    INSERT INTO talents VALUES (
        :id, :name, :icon, :class_id, :class_name, :tab_id, :tab_name, :tier, :col,
        :max_rank, :prereqs, :ranks, :is_internal, :build_id, :source_url
    )
    """, records["talents"])
    conn.commit()

    # Insert itemsets
    print("[SQL] Inserting item sets...")
    cur.executemany("""
    INSERT INTO item_sets VALUES (
        :id, :name, :pieces_count, :bonuses_count, :pieces, :bonuses, :is_internal,
        :build_id, :source_url
    )
    """, records["itemsets"])
    conn.commit()

    # Insert enchantments
    print("[SQL] Inserting enchantments...")
    cur.executemany("""
    INSERT INTO enchantments VALUES (
        :id, :name, :charges, :min_level, :req_skill, :req_skill_rank, :effects,
        :tooltip, :is_internal, :build_id, :source_url
    )
    """, records["enchantments"])
    conn.commit()

    # Insert quests
    print("[SQL] Inserting quests...")
    cur.executemany("""
    INSERT INTO quests VALUES (
        :id, :name, :level, :min_level, :side, :races, :classes, :zone_id, :zone_name,
        :description, :objectives_text, :start, :end, :objectives, :rewards,
        :prerequisites, :leads_to, :exclusive_with, :series, :map_pins, :tooltip,
        :source, :inherited, :is_internal, :build_id, :source_url
    )
    """, records["quests"])
    conn.commit()

    # Insert npcs
    print("[SQL] Inserting npcs...")
    cur.executemany("""
    INSERT INTO npcs VALUES (
        :id, :name, :title, :min_level, :max_level, :rank, :rank_name, :reaction,
        :type, :family, :classification, :zones, :spawns, :drops, :sells, :starts_quests,
        :ends_quests, :roles, :source, :inherited, :tooltip, :is_internal,
        :build_id, :source_url
    )
    """, records["npcs"])
    conn.commit()

    # Insert objects
    print("[SQL] Inserting objects...")
    cur.executemany("""
    INSERT INTO objects VALUES (
        :id, :name, :type, :kind, :reaction, :map_id, :map_name, :display_id, :zones,
        :spawns, :contains, :starts_quests, :ends_quests, :roles, :source, :inherited,
        :tooltip, :is_internal, :build_id, :source_url
    )
    """, records["objects"])
    conn.commit()

    # Insert zones
    print("[SQL] Inserting zones...")
    cur.executemany("""
    INSERT INTO zones VALUES (
        :id, :name, :key, :map_id, :map_name, :instance_type, :parent_id, :parent_name,
        :level, :level_min, :level_max, :faction, :is_zone, :subzones, :flight_masters,
        :dungeons, :pois, :entrances, :counts, :map_info, :tooltip, :is_internal,
        :build_id, :source_url
    )
    """, records["zones"])
    conn.commit()

    # Insert dungeons
    print("[SQL] Inserting dungeons...")
    cur.executemany("""
    INSERT INTO dungeons VALUES (
        :id, :name, :kind, :min_level, :max_level, :map_id, :zone_id, :zone_name,
        :area_id, :area_name, :bosses, :loot, :difficulties, :maps, :entrance,
        :entrance_zone, :tooltip, :is_internal, :build_id, :source_url
    )
    """, records["dungeons"])
    conn.commit()

    # Insert factions
    print("[SQL] Inserting factions...")
    cur.executemany("""
    INSERT INTO factions VALUES (
        :id, :name, :description, :parent_id, :parent_name, :rep_index, :has_reputation,
        :expansion, :tooltip, :is_internal, :build_id, :source_url
    )
    """, records["factions"])
    conn.commit()

    # Insert achievements
    print("[SQL] Inserting achievements...")
    cur.executemany("""
    INSERT INTO achievements VALUES (
        :id, :name, :description, :reward, :points, :category_id, :category_name,
        :icon, :faction, :tooltip, :is_internal, :build_id, :source_url
    )
    """, records["achievements"])
    conn.commit()

    # Insert classes
    print("[SQL] Inserting classes...")
    cur.executemany("""
    INSERT INTO classes VALUES (
        :id, :name, :file, :icon, :color, :power_type, :spell_class_set, :mask,
        :tabs, :races, :tooltip, :is_internal, :build_id, :source_url
    )
    """, records["classes"])
    conn.commit()

    # Insert races
    print("[SQL] Inserting races...")
    cur.executemany("""
    INSERT INTO races VALUES (
        :id, :name, :faction, :bit, :mask, :tooltip, :is_internal, :build_id, :source_url
    )
    """, records["races"])
    conn.commit()

    # Insert skills
    print("[SQL] Inserting skills...")
    cur.executemany("""
    INSERT INTO skills VALUES (
        :id, :name, :description, :category_id, :category_name, :icon, :parent_id,
        :spells, :spell_count, :tooltip, :is_internal, :build_id, :source_url
    )
    """, records["skills"])
    conn.commit()

    # -------------------------------------------------------------------------
    # Extract & Insert Relationships
    # -------------------------------------------------------------------------
    print("[REL] Extracting relationships...")
    rels = extract_all_relationships(
        items=records["items"],
        spells=records["spells"],
        talents=records["talents"],
        itemsets=records["itemsets"],
        enchantments=records["enchantments"],
        quests=records["quests"],
        npcs=records["npcs"],
        objects=records["objects"],
        zones=records["zones"],
        dungeons=records["dungeons"]
    )

    print("[SQL] Inserting rel_npc_drops...")
    cur.executemany("""
    INSERT INTO rel_npc_drops (npc_id, npc_name, item_id, item_name, chance, drop_type, zone)
    VALUES (:npc_id, :npc_name, :item_id, :item_name, :chance, :drop_type, :zone)
    """, rels["npc_drops"])

    print("[SQL] Inserting rel_vendor_sells...")
    cur.executemany("""
    INSERT INTO rel_vendor_sells (npc_id, npc_name, item_id, item_name, cost, zone)
    VALUES (:npc_id, :npc_name, :item_id, :item_name, :cost, :zone)
    """, rels["vendor_sells"])

    print("[SQL] Inserting rel_quest_items...")
    cur.executemany("""
    INSERT INTO rel_quest_items (quest_id, quest_name, item_id, item_name, relation, count, is_choice)
    VALUES (:quest_id, :quest_name, :item_id, :item_name, :relation, :count, :is_choice)
    """, rels["quest_items"])

    print("[SQL] Inserting rel_quest_npcs...")
    cur.executemany("""
    INSERT INTO rel_quest_npcs (quest_id, npc_id, npc_name, relation)
    VALUES (:quest_id, :npc_id, :npc_name, :relation)
    """, rels["quest_npcs"])

    print("[SQL] Inserting rel_quest_objects...")
    cur.executemany("""
    INSERT INTO rel_quest_objects (quest_id, object_id, object_name, relation)
    VALUES (:quest_id, :object_id, :object_name, :relation)
    """, rels["quest_objects"])

    print("[SQL] Inserting rel_object_items...")
    cur.executemany("""
    INSERT INTO rel_object_items (object_id, object_name, item_id, item_name, chance)
    VALUES (:object_id, :object_name, :item_id, :item_name, :chance)
    """, rels["object_items"])

    print("[SQL] Inserting rel_quest_chains...")
    cur.executemany("""
    INSERT INTO rel_quest_chains (quest_id, target_quest_id, relation)
    VALUES (:quest_id, :target_quest_id, :relation)
    """, rels["quest_chains"])

    print("[SQL] Inserting rel_dungeon_bosses...")
    cur.executemany("""
    INSERT INTO rel_dungeon_bosses (dungeon_id, dungeon_name, boss_id, boss_name, npc_id, encounter_order)
    VALUES (:dungeon_id, :dungeon_name, :boss_id, :boss_name, :npc_id, :encounter_order)
    """, rels["dungeon_bosses"])

    print("[SQL] Inserting rel_dungeon_loot...")
    cur.executemany("""
    INSERT INTO rel_dungeon_loot (dungeon_id, dungeon_name, item_id, item_name, boss_name)
    VALUES (:dungeon_id, :dungeon_name, :item_id, :item_name, :boss_name)
    """, rels["dungeon_loot"])

    print("[SQL] Inserting rel_item_set_pieces...")
    cur.executemany("""
    INSERT INTO rel_item_set_pieces (set_id, set_name, item_id, item_name)
    VALUES (:set_id, :set_name, :item_id, :item_name)
    """, rels["item_set_pieces"])

    print("[SQL] Inserting rel_zone_spawns...")
    cur.executemany("""
    INSERT INTO rel_zone_spawns (entity_type, entity_id, entity_name, area_id, ui_map_id, x, y, radius)
    VALUES (:entity_type, :entity_id, :entity_name, :area_id, :ui_map_id, :x, :y, :radius)
    """, rels["zone_spawns"])

    conn.commit()
    conn.close()
    print(f"[+] SQLite database populated successfully at {DB_PATH}")

    # -------------------------------------------------------------------------
    # JSON Exports
    # -------------------------------------------------------------------------
    os.makedirs(EXPORTS_DIR, exist_ok=True)
    export_map = {
        "items": "items.json",
        "spells": "spells.json",
        "talents": "talents.json",
        "itemsets": "item_sets.json",
        "enchantments": "enchantments.json",
        "quests": "quests.json",
        "npcs": "npcs.json",
        "objects": "objects.json",
        "zones": "zones.json",
        "dungeons": "dungeons.json",
        "factions": "factions.json",
        "achievements": "achievements.json",
        "classes": "classes.json",
        "races": "races.json",
        "skills": "skills.json"
    }

    for cat_key, fname in export_map.items():
        out_path = os.path.join(EXPORTS_DIR, fname)
        with open(out_path, "w", encoding="utf-8") as f:
            json.dump(records[cat_key], f, indent=2)
        print(f"[JSON] Exported {len(records[cat_key]):6} records -> {out_path}")

    rel_out_path = os.path.join(EXPORTS_DIR, "relationships.json")
    with open(rel_out_path, "w", encoding="utf-8") as f:
        json.dump(rels, f, indent=2)
    print(f"[JSON] Exported comprehensive relationships -> {rel_out_path}")

    elapsed = time.time() - start_time
    print(f"\n[+] DATABASE BUILDER & JSON EXPORTS COMPLETE IN {elapsed:.2f}s")
    print("================================================================================\n")


if __name__ == "__main__":
    build_database_and_exports()
