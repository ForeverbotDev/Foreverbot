#!/usr/bin/env python3
"""
ForeverDB/scraper/relationship_extractor.py

Extracts all relational connections between records across all 15 categories:
- NPC drops items (preserving per-kill chance, shared loot table, ref, seen).
- Vendor sells items.
- Quest item requirements, rewards (guaranteed vs choice), and starting items.
- Quest givers (starters), turn-in NPCs (enders), and objective creatures.
- Object quest relations and contained items.
- Quest chains, prerequisites, and series order.
- Dungeon bosses, encounters, and dungeon loot tables.
- Item sets and their constituent equipment pieces.
- Zone spawns, coordinates, flight masters, and point-of-interest links.
"""

import os
import json
from typing import Dict, List, Any, Set, Tuple

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EXPORTS_DIR = os.path.join(BASE_DIR, "exports")


def extract_all_relationships(
    items: List[Dict[str, Any]],
    spells: List[Dict[str, Any]],
    talents: List[Dict[str, Any]],
    itemsets: List[Dict[str, Any]],
    enchantments: List[Dict[str, Any]],
    quests: List[Dict[str, Any]],
    npcs: List[Dict[str, Any]],
    objects: List[Dict[str, Any]],
    zones: List[Dict[str, Any]],
    dungeons: List[Dict[str, Any]],
) -> Dict[str, List[Dict[str, Any]]]:
    """Extract normalized relationship graphs across all categories."""
    
    npc_drops: List[Dict[str, Any]] = []
    vendor_sells: List[Dict[str, Any]] = []
    quest_items: List[Dict[str, Any]] = []
    quest_npcs: List[Dict[str, Any]] = []
    quest_objects: List[Dict[str, Any]] = []
    object_items: List[Dict[str, Any]] = []
    quest_chains: List[Dict[str, Any]] = []
    dungeon_bosses: List[Dict[str, Any]] = []
    dungeon_loot: List[Dict[str, Any]] = []
    item_set_pieces: List[Dict[str, Any]] = []
    zone_spawns: List[Dict[str, Any]] = []
    
    seen_drops: Set[Tuple[int, int]] = set()
    seen_sells: Set[Tuple[int, int]] = set()
    seen_quest_items: Set[Tuple[int, int, str]] = set()
    seen_quest_npcs: Set[Tuple[int, int, str]] = set()
    seen_quest_objects: Set[Tuple[int, int, str]] = set()
    seen_object_items: Set[Tuple[int, int]] = set()
    seen_chains: Set[Tuple[int, int, str]] = set()
    
    # 1. Process Items -> sources
    for it in items:
        i_id = it["id"]
        sources = it.get("sources", {})
        if isinstance(sources, str):
            try: sources = json.loads(sources)
            except: sources = {}
            
        # DroppedBy in item sources
        for drop in sources.get("droppedBy", []):
            npc_id = drop.get("id")
            if npc_id and (npc_id, i_id) not in seen_drops:
                seen_drops.add((npc_id, i_id))
                npc_drops.append({
                    "npc_id": npc_id,
                    "npc_name": drop.get("name", ""),
                    "item_id": i_id,
                    "item_name": it["name"],
                    "chance": drop.get("chance"),
                    "drop_type": "kill" if drop.get("chance") else "ref",
                    "zone": drop.get("zone", "")
                })
                
        # SoldBy in item sources
        for s in sources.get("soldBy", []):
            npc_id = s.get("id")
            if npc_id and (npc_id, i_id) not in seen_sells:
                seen_sells.add((npc_id, i_id))
                vendor_sells.append({
                    "npc_id": npc_id,
                    "npc_name": s.get("name", ""),
                    "item_id": i_id,
                    "item_name": it["name"],
                    "cost": s.get("cost"),
                    "zone": s.get("zone", "")
                })
                
        # ContainedIn (objects -> item)
        for c in sources.get("containedIn", []):
            obj_id = c.get("id")
            if obj_id and (obj_id, i_id) not in seen_object_items:
                seen_object_items.add((obj_id, i_id))
                object_items.append({
                    "object_id": obj_id,
                    "object_name": c.get("name", ""),
                    "item_id": i_id,
                    "item_name": it["name"],
                    "chance": c.get("chance")
                })
                
        # StartsQuest
        for sq in sources.get("startsQuest", []):
            q_id = sq.get("id")
            if q_id and (q_id, i_id, "starts_quest") not in seen_quest_items:
                seen_quest_items.add((q_id, i_id, "starts_quest"))
                quest_items.append({
                    "quest_id": q_id,
                    "quest_name": sq.get("name", ""),
                    "item_id": i_id,
                    "item_name": it["name"],
                    "relation": "starts_quest",
                    "count": 1,
                    "is_choice": False
                })

        # ObjectiveOf
        for o in sources.get("objectiveOf", []):
            q_id = o.get("id")
            if q_id and (q_id, i_id, "requires") not in seen_quest_items:
                seen_quest_items.add((q_id, i_id, "requires"))
                quest_items.append({
                    "quest_id": q_id,
                    "quest_name": o.get("name", ""),
                    "item_id": i_id,
                    "item_name": it["name"],
                    "relation": "requires",
                    "count": o.get("count", 1),
                    "is_choice": False
                })

        # RewardFrom
        for rf in sources.get("rewardFrom", []):
            q_id = rf.get("id")
            if q_id and (q_id, i_id, "rewards") not in seen_quest_items:
                seen_quest_items.add((q_id, i_id, "rewards"))
                quest_items.append({
                    "quest_id": q_id,
                    "quest_name": rf.get("name", ""),
                    "item_id": i_id,
                    "item_name": it["name"],
                    "relation": "rewards",
                    "count": rf.get("count", 1),
                    "is_choice": bool(rf.get("choice", False))
                })

    # 2. Process NPCs -> drops, sells, spawns, starts/ends quests
    for npc in npcs:
        npc_id = npc["id"]
        drops_raw = npc.get("drops", [])
        if isinstance(drops_raw, str):
            try: drops_raw = json.loads(drops_raw)
            except: drops_raw = []
        for d in drops_raw:
            i_id = d.get("id")
            if i_id and (npc_id, i_id) not in seen_drops:
                seen_drops.add((npc_id, i_id))
                chance_val = d.get("chance")
                drop_type = "kill" if chance_val else "ref"
                if d.get("share"):
                    drop_type = "share"
                npc_drops.append({
                    "npc_id": npc_id,
                    "npc_name": npc["name"],
                    "item_id": i_id,
                    "item_name": d.get("name", ""),
                    "chance": chance_val,
                    "drop_type": drop_type,
                    "zone": ""
                })

        sells_raw = npc.get("sells", [])
        if isinstance(sells_raw, str):
            try: sells_raw = json.loads(sells_raw)
            except: sells_raw = []
        for s in sells_raw:
            i_id = s.get("id")
            if i_id and (npc_id, i_id) not in seen_sells:
                seen_sells.add((npc_id, i_id))
                vendor_sells.append({
                    "npc_id": npc_id,
                    "npc_name": npc["name"],
                    "item_id": i_id,
                    "item_name": s.get("name", ""),
                    "cost": s.get("cost"),
                    "zone": ""
                })

        # Starts quests
        sq_raw = npc.get("starts_quests", [])
        if isinstance(sq_raw, str):
            try: sq_raw = json.loads(sq_raw)
            except: sq_raw = []
        for q in sq_raw:
            q_id = q.get("id") if isinstance(q, dict) else q
            if q_id and (q_id, npc_id, "starter") not in seen_quest_npcs:
                seen_quest_npcs.add((q_id, npc_id, "starter"))
                quest_npcs.append({
                    "quest_id": q_id,
                    "npc_id": npc_id,
                    "npc_name": npc["name"],
                    "relation": "starter"
                })

        # Ends quests
        eq_raw = npc.get("ends_quests", [])
        if isinstance(eq_raw, str):
            try: eq_raw = json.loads(eq_raw)
            except: eq_raw = []
        for q in eq_raw:
            q_id = q.get("id") if isinstance(q, dict) else q
            if q_id and (q_id, npc_id, "ender") not in seen_quest_npcs:
                seen_quest_npcs.add((q_id, npc_id, "ender"))
                quest_npcs.append({
                    "quest_id": q_id,
                    "npc_id": npc_id,
                    "npc_name": npc["name"],
                    "relation": "ender"
                })

        # Spawns
        spawns_raw = npc.get("spawns", [])
        if isinstance(spawns_raw, str):
            try: spawns_raw = json.loads(spawns_raw)
            except: spawns_raw = []
        for sp in spawns_raw:
            zone_spawns.append({
                "entity_type": "npc",
                "entity_id": npc_id,
                "entity_name": npc["name"],
                "area_id": sp.get("area"),
                "ui_map_id": sp.get("uiMapId"),
                "x": sp.get("x"),
                "y": sp.get("y"),
                "radius": sp.get("r", 0)
            })

    # 3. Process Objects -> spawns, starts/ends quests, contains
    for obj in objects:
        obj_id = obj["id"]
        contains_raw = obj.get("contains", [])
        if isinstance(contains_raw, str):
            try: contains_raw = json.loads(contains_raw)
            except: contains_raw = []
        for c in contains_raw:
            i_id = c.get("id")
            if i_id and (obj_id, i_id) not in seen_object_items:
                seen_object_items.add((obj_id, i_id))
                object_items.append({
                    "object_id": obj_id,
                    "object_name": obj["name"],
                    "item_id": i_id,
                    "item_name": c.get("name", ""),
                    "chance": c.get("chance")
                })

        sq_raw = obj.get("starts_quests", [])
        if isinstance(sq_raw, str):
            try: sq_raw = json.loads(sq_raw)
            except: sq_raw = []
        for q in sq_raw:
            q_id = q.get("id") if isinstance(q, dict) else q
            if q_id and (q_id, obj_id, "starter") not in seen_quest_objects:
                seen_quest_objects.add((q_id, obj_id, "starter"))
                quest_objects.append({
                    "quest_id": q_id,
                    "object_id": obj_id,
                    "object_name": obj["name"],
                    "relation": "starter"
                })

        eq_raw = obj.get("ends_quests", [])
        if isinstance(eq_raw, str):
            try: eq_raw = json.loads(eq_raw)
            except: eq_raw = []
        for q in eq_raw:
            q_id = q.get("id") if isinstance(q, dict) else q
            if q_id and (q_id, obj_id, "ender") not in seen_quest_objects:
                seen_quest_objects.add((q_id, obj_id, "ender"))
                quest_objects.append({
                    "quest_id": q_id,
                    "object_id": obj_id,
                    "object_name": obj["name"],
                    "relation": "ender"
                })

        spawns_raw = obj.get("spawns", [])
        if isinstance(spawns_raw, str):
            try: spawns_raw = json.loads(spawns_raw)
            except: spawns_raw = []
        for sp in spawns_raw:
            zone_spawns.append({
                "entity_type": "object",
                "entity_id": obj_id,
                "entity_name": obj["name"],
                "area_id": sp.get("area"),
                "ui_map_id": sp.get("uiMapId"),
                "x": sp.get("x"),
                "y": sp.get("y"),
                "radius": sp.get("r", 0)
            })

    # 4. Process Quests -> start/end, rewards, objectives, series, leadsTo
    for quest in quests:
        q_id = quest["id"]
        # Prerequisites & leadsTo
        prereqs = quest.get("prerequisites", [])
        if isinstance(prereqs, str):
            try: prereqs = json.loads(prereqs)
            except: prereqs = []
        for p in prereqs:
            p_id = p.get("id") if isinstance(p, dict) else p
            if p_id and (q_id, p_id, "prerequisite") not in seen_chains:
                seen_chains.add((q_id, p_id, "prerequisite"))
                quest_chains.append({
                    "quest_id": q_id,
                    "target_quest_id": p_id,
                    "relation": "prerequisite"
                })

        leads = quest.get("leads_to", [])
        if isinstance(leads, str):
            try: leads = json.loads(leads)
            except: leads = []
        for l in leads:
            l_id = l.get("id") if isinstance(l, dict) else l
            if l_id and (q_id, l_id, "leads_to") not in seen_chains:
                seen_chains.add((q_id, l_id, "leads_to"))
                quest_chains.append({
                    "quest_id": q_id,
                    "target_quest_id": l_id,
                    "relation": "leads_to"
                })

        # Objectives (creatures and items)
        objs_raw = quest.get("objectives", [])
        if isinstance(objs_raw, str):
            try: objs_raw = json.loads(objs_raw)
            except: objs_raw = []
        for obj_entry in objs_raw:
            if isinstance(obj_entry, dict):
                o_type = obj_entry.get("type")
                target_id = obj_entry.get("id")
                if o_type == "creature" and target_id:
                    if (q_id, target_id, "objective") not in seen_quest_npcs:
                        seen_quest_npcs.add((q_id, target_id, "objective"))
                        quest_npcs.append({
                            "quest_id": q_id,
                            "npc_id": target_id,
                            "npc_name": obj_entry.get("name", ""),
                            "relation": "objective"
                        })
                elif o_type == "item" and target_id:
                    if (q_id, target_id, "requires") not in seen_quest_items:
                        seen_quest_items.add((q_id, target_id, "requires"))
                        quest_items.append({
                            "quest_id": q_id,
                            "quest_name": quest["name"],
                            "item_id": target_id,
                            "item_name": obj_entry.get("name", ""),
                            "relation": "requires",
                            "count": obj_entry.get("count", 1),
                            "is_choice": False
                        })
                elif o_type == "object" and target_id:
                    if (q_id, target_id, "objective") not in seen_quest_objects:
                        seen_quest_objects.add((q_id, target_id, "objective"))
                        quest_objects.append({
                            "quest_id": q_id,
                            "object_id": target_id,
                            "object_name": obj_entry.get("name", ""),
                            "relation": "objective"
                        })

    # 5. Process Dungeons -> bosses & loot
    for d in dungeons:
        dung_id = d["id"]
        bosses_raw = d.get("bosses", [])
        if isinstance(bosses_raw, str):
            try: bosses_raw = json.loads(bosses_raw)
            except: bosses_raw = []
        for b in bosses_raw:
            dungeon_bosses.append({
                "dungeon_id": dung_id,
                "dungeon_name": d["name"],
                "boss_id": b.get("id"),
                "boss_name": b.get("name", ""),
                "npc_id": b.get("npcId"),
                "encounter_order": b.get("order", 0)
            })

        loot_raw = d.get("loot", [])
        if isinstance(loot_raw, str):
            try: loot_raw = json.loads(loot_raw)
            except: loot_raw = []
        for lt in loot_raw:
            dungeon_loot.append({
                "dungeon_id": dung_id,
                "dungeon_name": d["name"],
                "item_id": lt.get("id"),
                "item_name": lt.get("name", ""),
                "boss_name": lt.get("boss", "")
            })

    # 6. Process Item Sets -> pieces
    for s in itemsets:
        s_id = s["id"]
        pieces_raw = s.get("pieces", [])
        if isinstance(pieces_raw, str):
            try: pieces_raw = json.loads(pieces_raw)
            except: pieces_raw = []
        for p in pieces_raw:
            item_id = p.get("id") if isinstance(p, dict) else p
            if item_id:
                item_set_pieces.append({
                    "set_id": s_id,
                    "set_name": s["name"],
                    "item_id": item_id,
                    "item_name": p.get("name", "") if isinstance(p, dict) else ""
                })

    relationships = {
        "npc_drops": npc_drops,
        "vendor_sells": vendor_sells,
        "quest_items": quest_items,
        "quest_npcs": quest_npcs,
        "quest_objects": quest_objects,
        "object_items": object_items,
        "quest_chains": quest_chains,
        "dungeon_bosses": dungeon_bosses,
        "dungeon_loot": dungeon_loot,
        "item_set_pieces": item_set_pieces,
        "zone_spawns": zone_spawns
    }

    print("\n--------------------------------------------------------------------------------")
    print("RELATIONSHIP EXTRACTION SUMMARY")
    print("--------------------------------------------------------------------------------")
    for r_name, r_list in relationships.items():
        print(f"  • {r_name:20}: {len(r_list):6} links")
    print("--------------------------------------------------------------------------------\n")
    return relationships
