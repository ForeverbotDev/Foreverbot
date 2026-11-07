# World of Warcraft: Forever — Master Relational Game Database

[![Build Status](https://img.shields.io/badge/Build-1.60.1.70532-blue.svg)](https://foreverdiff.gg/)
[![Extraction Match](https://img.shields.io/badge/Entity%20Coverage-100.00%25-brightgreen.svg)]()
[![License: pfQuest Layer](https://img.shields.io/badge/World%20Layer-MIT-green.svg)](https://github.com/shagu/pfQuest)
[![Database Size](https://img.shields.io/badge/SQLite-161%20MB-blueviolet.svg)]()

A comprehensive, production-grade relational database and structured JSON export suite covering **all publicly accessible game data** for **World of Warcraft: Forever (Beta 1.60.1.70532)**, extracted from [foreverdiff.gg](https://foreverdiff.gg/).

This database powers WoW: Forever addons, Discord bots, AI gameplay assistants, interactive web databases, quest/NPC locators, drop planners, and crafting tools.

---

## 1. Executive Summary & Verified Build Identity

- **Target Build**: World of Warcraft: Forever Beta `1.60.1.70532`
- **Product Code**: `wow_classic_beta`
- **Build ID**: `70532`
- **Build Config**: `b6a188be28cb5274ec8c9ba53ec02ba6`
- **CDN Config**: `8a2bc9166f21a4291fa27ea6bf4664a3`
- **Total Authoritative Entities**: Exactly **84,447** records across 15 categories (**100.00% target match**).
- **Total Indexed Relationships**: **558,053** relational links across 11 tables.
- **Isolated Community Preview Talents**: **470** talents across 9 class trees (curated from BlizzCon footage, segregated from authoritative client database tables).

---

## 2. Directory Structure

```
ForeverDB/
├── README.md                            # Complete architecture and usage documentation
├── database/
│   └── forever_master.sqlite            # Master relational database (WAL mode, 161 MB, 28 indexes)
├── exports/                             # Standalone JSON exports for all categories
│   ├── items.json                       # 19,257 items (49 MB)
│   ├── spells.json                      # 31,962 spells (43 MB)
│   ├── talents.json                     # 432 client talents (409 KB)
│   ├── item_sets.json                   # 536 item sets (632 KB)
│   ├── enchantments.json                # 2,217 enchantments (1.6 MB)
│   ├── quests.json                      # 7,387 quests (14 MB)
│   ├── npcs.json                        # 10,483 NPCs / creatures (56 MB)
│   ├── objects.json                     # 9,869 GameObjects (12 MB)
│   ├── zones.json                       # 1,375 zones (1.1 MB)
│   ├── dungeons.json                    # 40 dungeons / raids (417 KB)
│   ├── factions.json                    # 253 factions (115 KB)
│   ├── achievements.json                # 441 achievements (235 KB)
│   ├── classes.json                     # 9 player classes (6.1 KB)
│   ├── races.json                       # 32 races (9.9 KB)
│   ├── skills.json                      # 154 skills / professions (123 KB)
│   └── relationships.json               # Comprehensive graph export (109 MB)
├── metadata/
│   ├── build_info.json                  # Master build metadata, CDN endpoints, and target counts
│   ├── extraction_manifest.json         # SHA-256 checksums, byte sizes, and record audit
│   ├── completeness_report.json         # Detailed category coverage & withheld metrics
│   ├── source_provenance.json           # Data layer provenance, pfQuest commit, and licensing
│   ├── comparison_summary.json          # Segregated Classic Era comparison deltas
│   └── community_preview/
│       └── talents_community_preview.json # 470 unverified preview talents (Milenkas / BlizzCon)
├── raw_shards/                          # Disk-cached immutable raw JSON shards (2,118 files)
└── scraper/
    ├── source_crawler.py                # Multi-threaded shard downloader & gap prober
    ├── record_extractor.py              # Schema normalizer and cleaner
    ├── relationship_extractor.py        # Relational graph builder
    ├── database_builder.py              # SQLite DDL, indexing, and JSON export pipeline
    ├── extract_community_talents.py     # Segregated community preview extractor
    └── validation.py                    # Verification suite & manifest generator
```

---

## 3. Authoritative Record Counts

Every category matches the client database metadata with **100.00% precision**:

| Category | Table Name | SQLite Records | Expected Target | Public Shards | Internal Shards | Match % |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: |
| **Items** | `items` | 19,257 | 19,257 | 18,949 | 308 | **100.00%** |
| **Spells** | `spells` | 31,962 | 31,962 | 29,358 | 2,604 | **100.00%** |
| **Talents** | `talents` | 432 | 432 | 432 | 0 | **100.00%** |
| **Item Sets** | `item_sets` | 536 | 536 | 536 | 0 | **100.00%** |
| **Enchantments** | `enchantments` | 2,217 | 2,217 | 2,217 | 0 | **100.00%** |
| **Quests** | `quests` | 7,387 | 7,387 | 7,208 | 179 | **100.00%** |
| **NPCs / Creatures** | `npcs` | 10,483 | 10,483 | 10,131 | 352 | **100.00%** |
| **Objects / GameObjects** | `objects` | 9,869 | 9,869 | 9,824 | 45 | **100.00%** |
| **Zones** | `zones` | 1,375 | 1,375 | 1,365 | 10 | **100.00%** |
| **Dungeons** | `dungeons` | 40 | 40 | 40 | 0 | **100.00%** |
| **Factions** | `factions` | 253 | 253 | 247 | 6 | **100.00%** |
| **Achievements** | `achievements` | 441 | 441 | 441 | 0 | **100.00%** |
| **Classes** | `classes` | 9 | 9 | 9 | 0 | **100.00%** |
| **Races** | `races` | 32 | 32 | 32 | 0 | **100.00%** |
| **Skills** | `skills` | 154 | 154 | 153 | 1 | **100.00%** |
| **TOTALS** | | **84,447** | **84,447** | **80,942** | **3,505** | **100.00%** |

---

## 4. Relational Graph Structure

The SQLite database contains 11 indexed relationship tables capturing all cross-entity connections:

```
                  ┌──────────────────────┐
                  │       dungeons       │
                  └──────────┬───────────┘
                             │
            ┌────────────────┴────────────────┐
            ▼                                 ▼
┌──────────────────────┐            ┌──────────────────────┐
│  rel_dungeon_bosses  │            │   rel_dungeon_loot   │
└──────────┬───────────┘            └─────────┬────────────┘
           │                                  │
           ▼                                  ▼
┌──────────────────────┐  rel_npc_drops  ┌──────────────────────┐
│         npcs         ├────────────────►│        items         │
└──────────┬───────────┘                 └──────────┬───────────┘
           │                                        │
           │ rel_quest_npcs       rel_quest_items   │
           ▼                                        ▼
┌──────────────────────┐            ┌──────────────────────┐
│        quests        │◄───────────┤   rel_item_set_pieces│
└──────────┬───────────┘            └──────────────────────┘
           │
           │ rel_quest_chains
           ▼
┌──────────────────────┐
│  rel_quest_objects   ├────────────► objects
└──────────────────────┘
```

### Relationship Row Counts

| Relationship Table | Rows Indexed | Foreign Keys / Indexed Columns | Description |
| :--- | :---: | :--- | :--- |
| `rel_npc_drops` | **389,747** | `npc_id`, `item_id`, `drop_type` | Loot drops: 237,825 direct per-kill + 151,922 shared-table shares |
| `rel_zone_spawns` | **124,764** | `entity_type`, `entity_id`, `area_id` | World map coordinates (x, y, radius, ui_map_id) for NPCs & objects |
| `rel_vendor_sells` | **13,839** | `npc_id`, `item_id` | Vendor inventories with purchase costs and locations |
| `rel_quest_npcs` | **7,975** | `quest_id`, `npc_id`, `relation` | Quest starters (`starter`) and enders (`ender`) |
| `rel_object_items` | **5,954** | `object_id`, `item_id` | Containers and nodes yielding specific items |
| `rel_quest_chains` | **5,170** | `quest_id`, `target_quest_id` | Quest prerequisites, chains, and follow-ups |
| `rel_quest_items` | **3,896** | `quest_id`, `item_id`, `relation` | Required quest items (`objective`) vs rewards (`reward`) |
| `rel_item_set_pieces`| **3,069** | `set_id`, `item_id` | Set piece item memberships |
| `rel_dungeon_loot` | **2,744** | `dungeon_id`, `item_id` | Dungeon and raid encounter loot tables |
| `rel_quest_objects` | **556** | `quest_id`, `object_id` | Quest interactable GameObjects |
| `rel_dungeon_bosses` | **339** | `dungeon_id`, `boss_id`, `npc_id`| Boss encounters and ordering within instances |
| **TOTAL** | **558,053** | | |

---

## 5. Strict Data Policies & Quality Guarantees

### Zero-Substitution for Withheld Client Data
In the WoW: Forever client database tables, certain values are deliberately withheld by Blizzard:
- **Weapon DPS & Base Damage**: In the client tables, weapon DPS is omitted (`NULL`). We **never convert withheld values to 0**. Durability and weapon DPS remain explicitly `NULL`, with `is_withheld = 1` and `withheld_fields` listing the omitted keys.
- **Audited Metric**: 7,834 items have explicitly recorded withheld fields; 1,777 weapons have `dps = NULL` (strictly adhering to data truth).

### Drop Rate Semantics Preservation
Loot drop chances from the world layer (`pfQuest`) are preserved with exact semantics:
- `kill` (237,825 rows): Observed per-kill percentage chance.
- `share` (151,922 rows): Percentage share of a shared loot group.
- `ref` & `seen`: Reference database items and contributed sightings (<5 kills observed).

### Strict Segregation of Comparison & Community Data
- **Classic Era Comparison Data**: Classic Era deltas are stored separately in `ForeverDB/metadata/comparison_summary.json` and are never mixed into primary Forever tables.
- **Community Preview Talents**: 470 talent records reconstructed by Milenkas from BlizzCon 2026 show-floor footage are isolated in `ForeverDB/metadata/community_preview/talents_community_preview.json`. The primary `talents` table contains strictly the 432 authoritative client table records.

---

## 6. Source Provenance & Licensing

1. **Blizzard Client Database Tables** (`wow_classic_beta-1.60.1.70532`):
   - Scope: All primary stats, spell attributes, talent trees, item sets, enchantments, and achievements.
   - Endpoint: `https://kabltd6cwecga8ve.public.blob.vercel-storage.com/builds/wow_classic_beta/1.60.1.70532/`
2. **World Data Layer** (NPC spawns, vendor inventories, quest coordinates):
   - Source: [pfQuest](https://github.com/shagu/pfQuest) (Eric Mauser / Shagu)
   - Commit: `104f35678ca39ab1fb78b655f815cc7016f5e0c8`
   - License: MIT License

---

## 7. Example SQL Queries

### Query 1: Find Which Bosses Drop a Specific Item
```sql
SELECT
    d.name AS dungeon_name,
    l.boss_name,
    i.id AS item_id,
    i.name AS item_name,
    i.quality_name,
    i.slot
FROM rel_dungeon_loot l
JOIN dungeons d ON d.id = l.dungeon_id
JOIN items i ON i.id = l.item_id
WHERE i.name LIKE '%Ironfoe%' OR i.name LIKE '%Sulfuras%';
```

### Query 2: Find Quest Chain Prerequisites and Givers
```sql
SELECT
    q.id AS quest_id,
    q.name AS quest_name,
    q.req_level,
    n.name AS quest_giver,
    pq.name AS prerequisite_quest
FROM quests q
LEFT JOIN rel_quest_npcs rn ON rn.quest_id = q.id AND rn.relation = 'starter'
LEFT JOIN npcs n ON n.id = rn.npc_id
LEFT JOIN rel_quest_chains rc ON rc.quest_id = q.id AND rc.relation = 'prerequisite'
LEFT JOIN quests pq ON pq.id = rc.target_quest_id
WHERE q.name LIKE '%Onyxia%' OR q.name LIKE '%Attunement%'
LIMIT 20;
```

### Query 3: Find Vendors Selling Specific Crafting Recipes
```sql
SELECT
    n.name AS vendor_name,
    n.subname,
    vs.zone,
    i.name AS recipe_name,
    vs.cost AS buy_cost_copper
FROM rel_vendor_sells vs
JOIN npcs n ON n.id = vs.npc_id
JOIN items i ON i.id = vs.item_id
WHERE i.class_id = 9 -- Recipes / Books
ORDER BY vs.zone, n.name;
```

### Query 4: Find NPC Coordinates in a Zone
```sql
SELECT
    zs.entity_name,
    zs.ui_map_id,
    zs.x,
    zs.y,
    zs.radius
FROM rel_zone_spawns zs
WHERE zs.entity_type = 'npc' AND zs.entity_name = 'Hogger';
```

---

## 8. Verification & Re-Running the Pipeline

To re-verify or re-run the pipeline from raw shards:

```bash
# 1. Rebuild SQLite database & JSON exports
python3 ForeverDB/scraper/database_builder.py

# 2. Run verification & regenerate manifests
python3 ForeverDB/scraper/validation.py

# 3. Re-extract community preview talents (optional)
python3 ForeverDB/scraper/extract_community_talents.py
```
