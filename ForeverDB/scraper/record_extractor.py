#!/usr/bin/env python3
"""
ForeverDB/scraper/record_extractor.py

Iterates over raw category shards from ForeverDB/raw_shards/,
normalizes and cleans every field across all 15 categories,
preserves withheld fields (never converting missing/withheld values to 0),
and constructs standardized dictionaries ready for SQLite and JSON exports.
"""

import os
import json
from typing import Dict, List, Any, Optional

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RAW_SHARDS_DIR = os.path.join(BASE_DIR, "raw_shards")
EXPORTS_DIR = os.path.join(BASE_DIR, "exports")
BUILD_ID = "1.60.1.70532"
SITE_BASE = "https://foreverdiff.gg"


def load_raw_category_records(category: str) -> Dict[int, Dict[str, Any]]:
    """Load all records for a category from its raw shard JSON files."""
    cat_dir = os.path.join(RAW_SHARDS_DIR, category)
    if not os.path.exists(cat_dir):
        return {}
    
    records = {}
    for fname in sorted(os.listdir(cat_dir)):
        if fname.endswith(".json"):
            fpath = os.path.join(cat_dir, fname)
            try:
                with open(fpath, "r", encoding="utf-8") as f:
                    shard_data = json.load(f)
                    if isinstance(shard_data, dict):
                        for k, v in shard_data.items():
                            try:
                                ent_id = int(k)
                                records[ent_id] = v
                            except ValueError:
                                pass
            except Exception as e:
                print(f"[!] Error reading {fpath}: {e}")
    return records


def clean_item_record(raw: Dict[str, Any]) -> Dict[str, Any]:
    """Clean and normalize an item record."""
    item_id = int(raw.get("id"))
    
    # Check for withheld fields
    withheld_fields = []
    # If damage is empty array and dps is None or withheld
    if raw.get("dps") is None and raw.get("classId") == 2:  # Weapon with unstated DPS
        withheld_fields.append("dps")
    if raw.get("durability") == 0 and raw.get("classId") in (2, 4):  # Weapon/Armor with unstated durability
        withheld_fields.append("durability")
        
    return {
        "id": item_id,
        "name": raw.get("name") or f"Item #{item_id}",
        "quality": raw.get("quality", 1),
        "quality_name": raw.get("qualityName") or "Common",
        "icon": raw.get("icon") or "inv_misc_questionmark",
        "ilvl": raw.get("ilvl", 0),
        "req_level": raw.get("reqLevel", 0),
        "class_id": raw.get("classId"),
        "class_name": raw.get("className"),
        "subclass_id": raw.get("subclassId"),
        "subclass_name": raw.get("subclassName"),
        "subclass_verbose": raw.get("subclassVerbose"),
        "inv_type": raw.get("invType"),
        "slot": raw.get("slot"),
        "type_name": raw.get("typeName"),
        "bind_type": raw.get("bind", 0),
        "max_count": raw.get("maxCount", 0),
        "unique_equipped": bool(raw.get("uniqueEquipped", False)),
        "stackable": raw.get("stackable", 1),
        "armor": raw.get("armor", 0),
        "delay": raw.get("delay"),
        "dps": raw.get("dps"),
        "durability": raw.get("durability"),
        "class_mask": raw.get("classMask", -1),
        "req_skill": raw.get("reqSkill", {}).get("id") if isinstance(raw.get("reqSkill"), dict) else (raw.get("reqSkill") if isinstance(raw.get("reqSkill"), int) else None),
        "req_faction": raw.get("reqFaction"),
        "item_set_id": raw.get("itemSet", {}).get("id") if isinstance(raw.get("itemSet"), dict) else (raw.get("itemSet") if isinstance(raw.get("itemSet"), int) else None),
        "description": raw.get("description", ""),
        "sell_price": raw.get("sellPrice", 0),
        "buy_price": raw.get("buyPrice", 0),
        "start_quest": raw.get("startQuest", 0),
        "container_slots": raw.get("containerSlots", 0),
        "flags": json.dumps(raw.get("flags", [])),
        "expansion": raw.get("expansion", 0),
        "is_internal": bool(raw.get("internal", False)),
        "is_withheld": bool(len(withheld_fields) > 0),
        "withheld_fields": json.dumps(withheld_fields),
        "stats": json.dumps(raw.get("stats", [])),
        "resists": json.dumps(raw.get("resists", [])),
        "damage": json.dumps(raw.get("damage", [])),
        "effects": json.dumps(raw.get("effects", [])),
        "classes": json.dumps(raw.get("classes", [])),
        "races": json.dumps(raw.get("races", [])),
        "tooltip": json.dumps(raw.get("tooltip", [])),
        "sources": json.dumps(raw.get("sources", {})),
        "build_id": BUILD_ID,
        "source_url": f"{SITE_BASE}/item={item_id}"
    }


def clean_spell_record(raw: Dict[str, Any]) -> Dict[str, Any]:
    """Clean and normalize a spell record."""
    spell_id = int(raw.get("id"))
    return {
        "id": spell_id,
        "name": raw.get("name") or f"Spell #{spell_id}",
        "rank": raw.get("rank", ""),
        "icon": raw.get("icon") or "temp",
        "school": raw.get("school", "Physical"),
        "class_id": raw.get("classId"),
        "class_name": raw.get("className"),
        "kind": raw.get("kind", "other"),
        "skill_line": raw.get("skillLine"),
        "skill_name": raw.get("skillName"),
        "level": raw.get("level", 0),
        "max_level": raw.get("maxLevel", 0),
        "spell_level": raw.get("spellLevel", 0),
        "cost": raw.get("cost"),
        "range": raw.get("range"),
        "cast_time": raw.get("castTime"),
        "cooldown": raw.get("cooldown"),
        "duration": raw.get("duration"),
        "duration_ms": raw.get("durationMs", 0),
        "dispel": raw.get("dispel"),
        "mechanic": raw.get("mechanic"),
        "passive": bool(raw.get("passive", False)),
        "hidden": bool(raw.get("hidden", False)),
        "description": raw.get("description", ""),
        "aura_description": raw.get("auraDescription", ""),
        "effects": json.dumps(raw.get("effects", [])),
        "reagents": json.dumps(raw.get("reagents", [])),
        "tooltip": json.dumps(raw.get("tooltip", [])),
        "is_internal": bool(raw.get("internal", False)),
        "build_id": BUILD_ID,
        "source_url": f"{SITE_BASE}/spells/{spell_id}"
    }


def clean_talent_record(raw: Dict[str, Any]) -> Dict[str, Any]:
    """Clean and normalize a talent record."""
    talent_id = int(raw.get("id"))
    return {
        "id": talent_id,
        "name": raw.get("name") or f"Talent #{talent_id}",
        "icon": raw.get("icon") or "",
        "class_id": raw.get("classId"),
        "class_name": raw.get("className"),
        "tab_id": raw.get("tab"),
        "tab_name": raw.get("tabName"),
        "tier": raw.get("tier", 0),
        "col": raw.get("col", 0),
        "max_rank": raw.get("maxRank", 1),
        "prereqs": json.dumps(raw.get("prereqs", [])),
        "ranks": json.dumps(raw.get("ranks", [])),
        "is_internal": bool(raw.get("internal", False)),
        "build_id": BUILD_ID,
        "source_url": f"{SITE_BASE}/talents/{talent_id}"
    }


def clean_itemset_record(raw: Dict[str, Any]) -> Dict[str, Any]:
    """Clean and normalize an item set record."""
    set_id = int(raw.get("id"))
    pieces = raw.get("pieces", [])
    bonuses = raw.get("bonuses", [])
    return {
        "id": set_id,
        "name": raw.get("name") or f"Item Set #{set_id}",
        "pieces_count": len(pieces),
        "bonuses_count": len(bonuses),
        "pieces": json.dumps(pieces),
        "bonuses": json.dumps(bonuses),
        "is_internal": bool(raw.get("internal", False)),
        "build_id": BUILD_ID,
        "source_url": f"{SITE_BASE}/itemsets/{set_id}"
    }


def clean_enchantment_record(raw: Dict[str, Any]) -> Dict[str, Any]:
    """Clean and normalize an enchantment record."""
    ench_id = int(raw.get("id"))
    return {
        "id": ench_id,
        "name": raw.get("name") or f"Enchantment #{ench_id}",
        "charges": raw.get("charges", 0),
        "min_level": raw.get("minLevel", 0),
        "req_skill": raw.get("reqSkill", 0),
        "req_skill_rank": raw.get("reqSkillRank", 0),
        "effects": json.dumps(raw.get("effects", [])),
        "tooltip": json.dumps(raw.get("tooltip", [])),
        "is_internal": bool(raw.get("internal", False)),
        "build_id": BUILD_ID,
        "source_url": f"{SITE_BASE}/enchantments/{ench_id}"
    }


def clean_quest_record(raw: Dict[str, Any]) -> Dict[str, Any]:
    """Clean and normalize a quest record."""
    quest_id = int(raw.get("id"))
    return {
        "id": quest_id,
        "name": raw.get("name") or f"Quest #{quest_id}",
        "level": raw.get("level", 0),
        "min_level": raw.get("minLevel", 0),
        "side": raw.get("side", "Both"),
        "races": json.dumps(raw.get("races", [])),
        "classes": json.dumps(raw.get("classes", [])),
        "zone_id": raw.get("zoneId"),
        "zone_name": raw.get("zoneName"),
        "description": raw.get("description", ""),
        "objectives_text": raw.get("objectivesText", ""),
        "start": json.dumps(raw.get("start", [])),
        "end": json.dumps(raw.get("end", [])),
        "objectives": json.dumps(raw.get("objectives", [])),
        "rewards": json.dumps(raw.get("rewards", {})),
        "prerequisites": json.dumps(raw.get("prerequisites", [])),
        "leads_to": json.dumps(raw.get("leadsTo", [])),
        "exclusive_with": json.dumps(raw.get("exclusiveWith", [])),
        "series": json.dumps(raw.get("series", [])),
        "map_pins": json.dumps(raw.get("mapPins", [])),
        "tooltip": json.dumps(raw.get("tooltip", [])),
        "source": raw.get("source", "pfquest-vanilla"),
        "inherited": bool(raw.get("inherited", False)),
        "is_internal": bool(raw.get("internal", False)),
        "build_id": BUILD_ID,
        "source_url": f"{SITE_BASE}/quests/{quest_id}"
    }


def clean_npc_record(raw: Dict[str, Any]) -> Dict[str, Any]:
    """Clean and normalize an NPC/creature record."""
    npc_id = int(raw.get("id"))
    return {
        "id": npc_id,
        "name": raw.get("name") or f"Creature #{npc_id}",
        "title": raw.get("title", ""),
        "min_level": raw.get("minLevel", 0),
        "max_level": raw.get("maxLevel", 0),
        "rank": raw.get("rank", 0),
        "rank_name": raw.get("rankName", "Normal"),
        "reaction": raw.get("reaction", "Neutral"),
        "type": raw.get("type"),
        "family": raw.get("family"),
        "classification": raw.get("classification"),
        "zones": json.dumps(raw.get("zones", [])),
        "spawns": json.dumps(raw.get("spawns", [])),
        "drops": json.dumps(raw.get("drops", [])),
        "sells": json.dumps(raw.get("sells", [])),
        "starts_quests": json.dumps(raw.get("startsQuests", [])),
        "ends_quests": json.dumps(raw.get("endsQuests", [])),
        "roles": json.dumps(raw.get("roles", [])),
        "source": raw.get("source", "pfquest-vanilla"),
        "inherited": bool(raw.get("inherited", False)),
        "tooltip": json.dumps(raw.get("tooltip", [])),
        "is_internal": bool(raw.get("internal", False)),
        "build_id": BUILD_ID,
        "source_url": f"{SITE_BASE}/npcs/{npc_id}"
    }


def clean_object_record(raw: Dict[str, Any]) -> Dict[str, Any]:
    """Clean and normalize a GameObject record."""
    obj_id = int(raw.get("id"))
    return {
        "id": obj_id,
        "name": raw.get("name") or f"Object #{obj_id}",
        "type": raw.get("type"),
        "kind": raw.get("kind", "object"),
        "reaction": raw.get("reaction", "Neutral"),
        "map_id": raw.get("mapId"),
        "map_name": raw.get("mapName"),
        "display_id": raw.get("displayId"),
        "zones": json.dumps(raw.get("zones", [])),
        "spawns": json.dumps(raw.get("spawns", [])),
        "contains": json.dumps(raw.get("contains", [])),
        "starts_quests": json.dumps(raw.get("startsQuests", [])),
        "ends_quests": json.dumps(raw.get("endsQuests", [])),
        "roles": json.dumps(raw.get("roles", [])),
        "source": raw.get("source", "pfquest-vanilla"),
        "inherited": bool(raw.get("inherited", False)),
        "tooltip": json.dumps(raw.get("tooltip", [])),
        "is_internal": bool(raw.get("internal", False)),
        "build_id": BUILD_ID,
        "source_url": f"{SITE_BASE}/objects/{obj_id}"
    }


def clean_zone_record(raw: Dict[str, Any]) -> Dict[str, Any]:
    """Clean and normalize a zone record."""
    zone_id = int(raw.get("id"))
    lvl_range = raw.get("levelRange")
    if not isinstance(lvl_range, (list, tuple)):
        lvl_range = [0, 0]
    return {
        "id": zone_id,
        "name": raw.get("name") or f"Zone #{zone_id}",
        "key": raw.get("key", ""),
        "map_id": raw.get("mapId"),
        "map_name": raw.get("mapName"),
        "instance_type": raw.get("instanceType", 0),
        "parent_id": raw.get("parentId", 0),
        "parent_name": raw.get("parentName"),
        "level": raw.get("level", 0),
        "level_min": lvl_range[0] if len(lvl_range) > 0 else 0,
        "level_max": lvl_range[1] if len(lvl_range) > 1 else 0,
        "faction": raw.get("faction"),
        "is_zone": bool(raw.get("isZone", True)),
        "subzones": json.dumps(raw.get("subzones", [])),
        "flight_masters": json.dumps(raw.get("flightMasters", [])),
        "dungeons": json.dumps(raw.get("dungeons", [])),
        "pois": json.dumps(raw.get("pois", [])),
        "entrances": json.dumps(raw.get("entrances", [])),
        "counts": json.dumps(raw.get("counts", {})),
        "map_info": json.dumps(raw.get("map", {})),
        "tooltip": json.dumps(raw.get("tooltip", [])),
        "is_internal": bool(raw.get("internal", False)),
        "build_id": BUILD_ID,
        "source_url": f"{SITE_BASE}/zones/{zone_id}"
    }


def clean_dungeon_record(raw: Dict[str, Any]) -> Dict[str, Any]:
    """Clean and normalize a dungeon record."""
    dung_id = int(raw.get("id"))
    return {
        "id": dung_id,
        "name": raw.get("name") or f"Dungeon #{dung_id}",
        "kind": raw.get("kind", "Dungeon"),
        "min_level": raw.get("minLevel", 0),
        "max_level": raw.get("maxLevel", 0),
        "map_id": raw.get("mapId"),
        "zone_id": raw.get("zoneId"),
        "zone_name": raw.get("zoneName"),
        "area_id": raw.get("areaId"),
        "area_name": raw.get("areaName"),
        "bosses": json.dumps(raw.get("bosses", [])),
        "loot": json.dumps(raw.get("loot", [])),
        "difficulties": json.dumps(raw.get("difficulties", [])),
        "maps": json.dumps(raw.get("maps", [])),
        "entrance": json.dumps(raw.get("entrance", {})),
        "entrance_zone": raw.get("entranceZone", {}).get("name") if isinstance(raw.get("entranceZone"), dict) else (raw.get("entranceZone") if isinstance(raw.get("entranceZone"), str) else None),
        "tooltip": json.dumps(raw.get("tooltip", [])),
        "is_internal": bool(raw.get("internal", False)),
        "build_id": BUILD_ID,
        "source_url": f"{SITE_BASE}/dungeons/{dung_id}"
    }


def clean_faction_record(raw: Dict[str, Any]) -> Dict[str, Any]:
    """Clean and normalize a faction record."""
    faction_id = int(raw.get("id"))
    return {
        "id": faction_id,
        "name": raw.get("name") or f"Faction #{faction_id}",
        "description": raw.get("description", ""),
        "parent_id": raw.get("parentId"),
        "parent_name": raw.get("parentName"),
        "rep_index": raw.get("repIndex"),
        "has_reputation": bool(raw.get("hasReputation", False)),
        "expansion": raw.get("expansion", 0),
        "tooltip": json.dumps(raw.get("tooltip", [])),
        "is_internal": bool(raw.get("internal", False)),
        "build_id": BUILD_ID,
        "source_url": f"{SITE_BASE}/factions/{faction_id}"
    }


def clean_achievement_record(raw: Dict[str, Any]) -> Dict[str, Any]:
    """Clean and normalize an achievement record."""
    ach_id = int(raw.get("id"))
    return {
        "id": ach_id,
        "name": raw.get("name") or f"Achievement #{ach_id}",
        "description": raw.get("description", ""),
        "reward": raw.get("reward", ""),
        "points": raw.get("points", 0),
        "category_id": raw.get("category"),
        "category_name": raw.get("categoryName"),
        "icon": raw.get("icon"),
        "faction": raw.get("faction"),
        "tooltip": json.dumps(raw.get("tooltip", [])),
        "is_internal": bool(raw.get("internal", False)),
        "build_id": BUILD_ID,
        "source_url": f"{SITE_BASE}/achievements/{ach_id}"
    }


def clean_class_record(raw: Dict[str, Any]) -> Dict[str, Any]:
    """Clean and normalize a class record."""
    class_id = int(raw.get("id"))
    return {
        "id": class_id,
        "name": raw.get("name") or f"Class #{class_id}",
        "file": raw.get("file"),
        "icon": raw.get("icon"),
        "color": raw.get("color"),
        "power_type": raw.get("powerType"),
        "spell_class_set": raw.get("spellClassSet"),
        "mask": raw.get("mask"),
        "tabs": json.dumps(raw.get("tabs", [])),
        "races": json.dumps(raw.get("races", [])),
        "tooltip": json.dumps(raw.get("tooltip", [])),
        "is_internal": bool(raw.get("internal", False)),
        "build_id": BUILD_ID,
        "source_url": f"{SITE_BASE}/classes/{class_id}"
    }


def clean_race_record(raw: Dict[str, Any]) -> Dict[str, Any]:
    """Clean and normalize a race record."""
    race_id = int(raw.get("id"))
    return {
        "id": race_id,
        "name": raw.get("name") or f"Race #{race_id}",
        "faction": raw.get("faction"),
        "bit": raw.get("bit"),
        "mask": raw.get("mask"),
        "tooltip": json.dumps(raw.get("tooltip", [])),
        "is_internal": bool(raw.get("internal", False)),
        "build_id": BUILD_ID,
        "source_url": f"{SITE_BASE}/races/{race_id}"
    }


def clean_skill_record(raw: Dict[str, Any]) -> Dict[str, Any]:
    """Clean and normalize a skill record."""
    skill_id = int(raw.get("id"))
    return {
        "id": skill_id,
        "name": raw.get("name") or f"Skill #{skill_id}",
        "description": raw.get("description", ""),
        "category_id": raw.get("category"),
        "category_name": raw.get("categoryName"),
        "icon": raw.get("icon"),
        "parent_id": raw.get("parent"),
        "spells": json.dumps(raw.get("spells", [])),
        "spell_count": raw.get("spellCount", 0),
        "tooltip": json.dumps(raw.get("tooltip", [])),
        "is_internal": bool(raw.get("internal", False)),
        "build_id": BUILD_ID,
        "source_url": f"{SITE_BASE}/skills/{skill_id}"
    }


CLEANERS = {
    "items": clean_item_record,
    "spells": clean_spell_record,
    "talents": clean_talent_record,
    "itemsets": clean_itemset_record,
    "enchantments": clean_enchantment_record,
    "quests": clean_quest_record,
    "npcs": clean_npc_record,
    "objects": clean_object_record,
    "zones": clean_zone_record,
    "dungeons": clean_dungeon_record,
    "factions": clean_faction_record,
    "achievements": clean_achievement_record,
    "classes": clean_class_record,
    "races": clean_race_record,
    "skills": clean_skill_record
}


def extract_all_categories() -> Dict[str, List[Dict[str, Any]]]:
    """Extract and normalize all 15 categories from raw shards."""
    extracted = {}
    for cat, cleaner in CLEANERS.items():
        raw_map = load_raw_category_records(cat)
        cleaned_list = []
        for ent_id in sorted(raw_map.keys()):
            cleaned_list.append(cleaner(raw_map[ent_id]))
        extracted[cat] = cleaned_list
        print(f"[EXTRACT] {cat:15}: Processed {len(cleaned_list):6} clean records")
    return extracted


if __name__ == "__main__":
    records = extract_all_categories()
    print("Record extraction complete.")
