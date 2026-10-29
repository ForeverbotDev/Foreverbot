"""Intelligent Slash Command Redirection Engine for Foreverbot.

Detects when a player passes a query meant for another slash command
(e.g., typing a conversational question or lost-player query into /map,
a creature name into /item, an item name into /mob, a dungeon into /map, etc.)
and provides instant text guidance pointing to the correct command and syntax,
along with helpful in-game hints where appropriate.
"""

import re
import sqlite3
from typing import Optional, Dict, Any
from knowledge_engine import (
    ZONES_DATA, PROFESSIONS_DATA, GATHERING_NODES,
    CONSUMABLES_DATA, ATTUNEMENTS, CLASS_BUILDS,
    REPUTATIONS_DATA, WORLD_BUFFS_DATA, RESIST_SCHOOLS
)
from database import DB_PATH, ZONE_ALIASES

# Question patterns indicating conversational inquiry or navigation requests
QUESTION_TRIGGERS = [
    "where am i", "where is", "where do", "where can", "how do i", "how can", "how to", "how does",
    "what is", "what are", "who is", "who sells", "why is", "can i", "is there", "im lost",
    "i'm lost", "trying to find", "trying to get", "lost in", "directions", "help me", "tell me",
    "which is better", "should i", "which one", "can you tell me"
]

def _a_an(word: str) -> str:
    """Returns 'an' if word starts with a vowel, else 'a'."""
    return "an" if word and word[0].lower() in "aeiou" else "a"

def get_command_redirection_advice(
    query: str,
    current_command: str,
    db_path: str = DB_PATH
) -> Optional[Dict[str, Any]]:
    """Analyzes a failed command query and suggests the correct command and syntax.

    Returns a dict with 'suggested_command', 'title', 'description', and 'full_text',
    or None if no specific redirection is identified.
    """
    if not query or not query.strip():
        return None

    q = query.strip()
    ql = q.lower()

    # -------------------------------------------------------------
    # 1. Natural language questions / lost player inquiries
    # -------------------------------------------------------------
    has_question_phrase = any(t in ql for t in QUESTION_TRIGGERS)
    has_question_mark = "?" in q
    is_multi_word_sentence = len(ql.split()) >= 5 and current_command not in ("flightpath", "signup", "intel")

    if (has_question_phrase or has_question_mark or is_multi_word_sentence) and current_command != "ask":
        hint = ""
        # Context-aware lost player navigation hints
        if ("dark forest" in ql or ("forest" in ql and ("wolf" in ql or "wolves" in ql or "wovles" in ql or "skeleton" in ql or "undead" in ql))) or "duskwood" in ql:
            hint = (
                "\n\n🧭 **Lost Adventurer Navigation Hint:**\n"
                "Based on the dark forest with wolves and skeletons near Stormwind, you are in **Duskwood** (Level 20–30)!\n"
                "• **Directions to Stormwind City:** Head **North** along the main cobblestone road, cross the stone bridge over the river into **Elwynn Forest**, and follow the paved road northwest directly to the gates of Stormwind."
            )
        elif "redridge" in ql or ("lake" in ql and "gnoll" in ql) or "lakeshire" in ql:
            hint = (
                "\n\n🧭 **Lost Adventurer Navigation Hint:**\n"
                "You appear to be in **Redridge Mountains** (Level 15–25)!\n"
                "• **Directions to Stormwind City:** Follow the main road West across the bridge into Elwynn Forest and head West to Stormwind."
            )
        elif "westfall" in ql or "defias" in ql or "harvest" in ql or "sentinel hill" in ql:
            hint = (
                "\n\n🧭 **Lost Adventurer Navigation Hint:**\n"
                "You appear to be in **Westfall** (Level 10–20)!\n"
                "• **Directions to Stormwind City:** Follow the road East across the river bridge into Elwynn Forest and head North/Northwest to Stormwind."
            )
        elif "barrens" in ql or "crossroads" in ql or "oasis" in ql:
            hint = (
                "\n\n🧭 **Lost Adventurer Navigation Hint:**\n"
                "You appear to be in **The Barrens** (Level 10–25) in central Kalimdor! The Crossroads is the primary travel hub connecting Durotar, Ashenvale, and Mulgore."
            )
        elif "tanaris" in ql or "gadgetzan" in ql or ("desert" in ql and "pirate" in ql):
            hint = (
                "\n\n🧭 **Lost Adventurer Navigation Hint:**\n"
                "You appear to be in **Tanaris** (Level 40–50) in southern Kalimdor! Gadgetzan is the central goblin neutral hub."
            )

        full_text = (
            f"The `/{current_command}` command expects a specific entity name, but `/ask` handles open questions, lore, mechanics, and navigation advice!\n\n"
            f"👉 **Try:** `/ask query:{q}`{hint}"
        )
        return {
            "suggested_command": "ask",
            "title": "💡 Did you mean to use `/ask`?",
            "description": full_text,
            "full_text": full_text
        }

    # -------------------------------------------------------------
    # 2. Flight path transit intent sent to other commands
    # -------------------------------------------------------------
    is_flight = (
        (" to " in ql and not any(w in ql for w in ["attunement to", "key to", "path to"]))
        or ql.startswith("from ")
        or any(w in ql for w in ["flight", "fly to", "fp to", "flightpath"])
    )
    if is_flight and current_command in ("map", "zones", "item", "mob", "dungeons"):
        full_text = (
            "To calculate flight routes, connection times, and flight master coordinates:\n\n"
            f"👉 **Try:** `/flightpath query:{q}`"
        )
        return {
            "suggested_command": "flightpath",
            "title": "💡 Did you mean to use `/flightpath`?",
            "description": full_text,
            "full_text": full_text
        }

    # -------------------------------------------------------------
    # 3. Weapon comparison intent sent to /item, /bis, or /mob
    # -------------------------------------------------------------
    if (" vs " in ql or " compare " in ql or " better than " in ql) and current_command in ("item", "bis", "mob"):
        parts = re.split(r"\s+vs\.?\s+|\s+compare\s+|\s+better than\s+", q, flags=re.IGNORECASE)
        w1 = parts[0].strip() if len(parts) > 0 else "Ironfoe"
        w2 = parts[1].strip() if len(parts) > 1 else "Brutality Blade"
        full_text = (
            "To compare weapon damage, swing speed, DPS, and glancing blow mitigation math:\n\n"
            f"👉 **Try:** `/compare query:{w1} weapon2:{w2}`"
        )
        return {
            "suggested_command": "compare",
            "title": "💡 Did you mean to use `/compare`?",
            "description": full_text,
            "full_text": full_text
        }

    # -------------------------------------------------------------
    # 4. Best in Slot (BiS) intent sent to /item or /mob
    # -------------------------------------------------------------
    if any(k in ql for k in ["bis", "best in slot", "pre-raid", "preraid"]) and current_command in ("item", "mob", "ask"):
        classes = ["warrior", "rogue", "mage", "priest", "warlock", "hunter", "druid", "paladin", "shaman"]
        found_class = next((c.capitalize() for c in classes if c in ql), "Warrior")
        full_text = (
            "To view comprehensive pre-raid and raid Best in Slot gear lists by class and spec:\n\n"
            f"👉 **Try:** `/bis query:{found_class}` (e.g. `/bis query:{found_class} spec:DPS`)"
        )
        return {
            "suggested_command": "bis",
            "title": "💡 Did you mean to use `/bis`?",
            "description": full_text,
            "full_text": full_text
        }

    # -------------------------------------------------------------
    # 5. Class builds and talents intent sent to /item or /mob
    # -------------------------------------------------------------
    if any(k in ql for k in ["talent", "talents", "build", "tree", "spec "]) and current_command in ("item", "mob", "dungeons"):
        classes = ["warrior", "rogue", "mage", "priest", "warlock", "hunter", "druid", "paladin", "shaman"]
        found_class = next((c.capitalize() for c in classes if c in ql), "Warrior")
        full_text = (
            "To inspect talent point distributions, stat priorities, and rotations:\n\n"
            f"👉 **Try:** `/build query:{found_class}` or `/talents query:{found_class}`"
        )
        return {
            "suggested_command": "build",
            "title": "💡 Did you mean to use `/build` or `/talents`?",
            "description": full_text,
            "full_text": full_text
        }

    # -------------------------------------------------------------
    # 6. Attunement or Key intent sent to /item or /dungeons
    # -------------------------------------------------------------
    if any(k in ql for k in ["attunement", "attune", "attuned"]) and current_command in ("item", "dungeons", "map", "quest"):
        raids = ["onyxia", "mc", "molten core", "bwl", "blackwing lair", "naxx", "naxxramas"]
        found_raid = next((r.title() for r in raids if r in ql), "Onyxia")
        full_text = (
            "To view raid attunement quest chains and prerequisite steps:\n\n"
            f"👉 **Try:** `/attunement query:{found_raid}`"
        )
        return {
            "suggested_command": "attunement",
            "title": "💡 Did you mean to use `/attunement`?",
            "description": full_text,
            "full_text": full_text
        }

    # -------------------------------------------------------------
    # 7. GDKP / Gold calculation intent sent to other commands
    # -------------------------------------------------------------
    if "gdkp" in ql and current_command != "gdkp":
        numbers = re.findall(r"\b\d+\b", q)
        pot = numbers[0] if numbers else "10000"
        full_text = (
            "To calculate GDKP pot shares, host cuts, tank bonuses, and per-raider payouts:\n\n"
            f"👉 **Try:** `/gdkp query:{pot}`"
        )
        return {
            "suggested_command": "gdkp",
            "title": "💡 Did you mean to use `/gdkp`?",
            "description": full_text,
            "full_text": full_text
        }

    # -------------------------------------------------------------
    # 8. World Buffs & Reputations
    # -------------------------------------------------------------
    if any(k in ql for k in ["world buff", "rallying cry", "songflower", "wcb", "warchief's blessing", "dmf buff"]) and current_command != "buffs":
        full_text = (
            "To view World Buff timers, effects, cooldowns, and drop locations:\n\n"
            f"👉 **Try:** `/buffs query:{q}`"
        )
        return {
            "suggested_command": "buffs",
            "title": "💡 Did you mean to use `/buffs`?",
            "description": full_text,
            "full_text": full_text
        }

    for rep_key, rep_data in REPUTATIONS_DATA.items():
        if rep_key in ql or ql in rep_key or rep_data["name"].lower() in ql:
            if current_command != "rep":
                rep_name = rep_data["name"]
                full_text = (
                    f"**{rep_name}** is a faction reputation!\n\n"
                    f"👉 **Try:** `/rep query:{rep_name}`"
                )
                return {
                    "suggested_command": "rep",
                    "title": "💡 Did you mean to use `/rep`?",
                    "description": full_text,
                    "full_text": full_text
                }

    # -------------------------------------------------------------
    # 9. Gathering Nodes & Professions
    # -------------------------------------------------------------
    for prof_name in PROFESSIONS_DATA.keys():
        if prof_name.lower() in ql and current_command != "profession":
            full_text = (
                f"`{prof_name}` is a crafting or gathering profession!\n\n"
                f"👉 **Try:** `/profession query:{prof_name}`"
            )
            return {
                "suggested_command": "profession",
                "title": "💡 Did you mean to use `/profession`?",
                "description": full_text,
                "full_text": full_text
            }

    for node_name in GATHERING_NODES.keys():
        if node_name.lower() in ql or (len(ql) >= 4 and ql in node_name.lower()):
            if current_command != "gather":
                full_text = (
                    f"`{node_name.title()}` is a resource gathering node!\n\n"
                    f"👉 **Try:** `/gather query:{node_name.title()}`"
                )
                return {
                    "suggested_command": "gather",
                    "title": "💡 Did you mean to use `/gather`?",
                    "description": full_text,
                    "full_text": full_text
                }

    # -------------------------------------------------------------
    # 10. Elemental Resistance Calculations
    # -------------------------------------------------------------
    for school in RESIST_SCHOOLS.keys():
        if f"{school} resist" in ql and current_command != "resist":
            full_text = (
                f"To calculate {school.capitalize()} Resistance damage reduction and average mitigation:\n\n"
                f"👉 **Try:** `/resist query:{school.capitalize()}`"
            )
            return {
                "suggested_command": "resist",
                "title": "💡 Did you mean to use `/resist`?",
                "description": full_text,
                "full_text": full_text
            }

    # -------------------------------------------------------------
    # 11. Zones verification when typed into non-zone commands
    # -------------------------------------------------------------
    if current_command not in ("map", "zones"):
        for zone_name in ZONES_DATA.keys():
            if zone_name.lower() == ql or (len(ql) >= 4 and ql in zone_name.lower()):
                art = _a_an(current_command)
                full_text = (
                    f"**{zone_name}** is a world zone/region, not {art} {current_command}!\n\n"
                    f"👉 **Try:** `/map query:{zone_name}` or `/zones query:{zone_name}`"
                )
                return {
                    "suggested_command": "map",
                    "title": "💡 Did you mean to use `/map`?",
                    "description": full_text,
                    "full_text": full_text
                }
        for alias, zone_target in ZONE_ALIASES.items():
            if alias.lower() == ql:
                art = _a_an(current_command)
                full_text = (
                    f"**{zone_target}** is a world zone/region, not {art} {current_command}!\n\n"
                    f"👉 **Try:** `/map query:{zone_target}` or `/zones query:{zone_target}`"
                )
                return {
                    "suggested_command": "map",
                    "title": "💡 Did you mean to use `/map`?",
                    "description": full_text,
                    "full_text": full_text
                }

    # -------------------------------------------------------------
    # 12. Database Cross-Entity Verification (Fast indexed SQL check)
    # -------------------------------------------------------------
    pattern = f"%{ql}%"
    try:
        conn = sqlite3.connect(db_path)
        cur = conn.cursor()

        # Check Dungeons / Raids
        if current_command not in ("dungeons", "raid"):
            cur.execute("SELECT name, is_forever_content, zone FROM dungeons WHERE LOWER(name) LIKE ? LIMIT 1", (pattern,))
            row = cur.fetchone()
            if row:
                conn.close()
                d_name, is_fc, d_zone = row[0], row[1], row[2]
                badge = " (WoW: Forever Custom Dungeon)" if is_fc else ""
                full_text = (
                    f"**{d_name}** is a dungeon instance located in **{d_zone}**{badge}!\n\n"
                    f"👉 **Try:** `/dungeons query:{d_name}`"
                )
                return {
                    "suggested_command": "dungeons",
                    "title": "💡 Did you mean to use `/dungeons`?",
                    "description": full_text,
                    "full_text": full_text
                }

        # Check Bosses / Creatures
        if current_command not in ("mob", "raid"):
            cur.execute("SELECT name, classification, zone FROM creatures WHERE LOWER(name) LIKE ? LIMIT 1", (pattern,))
            row = cur.fetchone()
            if row:
                conn.close()
                c_name, cls, c_zone = row[0], row[1] or "Creature", row[2] or "Azeroth"
                is_raid_boss = "boss" in cls.lower() or "world boss" in cls.lower()
                cmd = "/raid" if is_raid_boss else "/mob"
                art = _a_an(current_command)
                full_text = (
                    f"**{c_name}** is a {cls.lower()} in **{c_zone}**, not {art} {current_command}!\n\n"
                    f"👉 **Try:** `{cmd} query:{c_name}`"
                )
                return {
                    "suggested_command": "mob" if not is_raid_boss else "raid",
                    "title": f"💡 Did you mean to use `{cmd}`?",
                    "description": full_text,
                    "full_text": full_text
                }

        # Check Items
        if current_command != "item":
            cur.execute("SELECT name, quality, slot FROM items WHERE LOWER(name) LIKE ? LIMIT 1", (pattern,))
            row = cur.fetchone()
            if row:
                conn.close()
                i_name, qual, slot = row[0], row[1] or "Common", row[2] or "Item"
                art = _a_an(current_command)
                full_text = (
                    f"**{i_name}** is an item ({qual} {slot}), not {art} {current_command}!\n\n"
                    f"👉 **Try:** `/item query:{i_name}`"
                )
                return {
                    "suggested_command": "item",
                    "title": "💡 Did you mean to use `/item`?",
                    "description": full_text,
                    "full_text": full_text
                }

        # Check Quests
        if current_command != "quest":
            cur.execute("SELECT title, zone FROM quests WHERE LOWER(title) LIKE ? LIMIT 1", (pattern,))
            row = cur.fetchone()
            if row:
                conn.close()
                q_title, q_zone = row[0], row[1] or "Azeroth"
                art = _a_an(current_command)
                full_text = (
                    f"**{q_title}** is a quest in **{q_zone}**, not {art} {current_command}!\n\n"
                    f"👉 **Try:** `/quest query:{q_title}`"
                )
                return {
                    "suggested_command": "quest",
                    "title": "💡 Did you mean to use `/quest`?",
                    "description": full_text,
                    "full_text": full_text
                }

        conn.close()
    except Exception:
        pass

    return None
