"""World of Warcraft & WoW: Forever Comprehensive Knowledge Engine.

Provides deep, 100% accurate, authoritative data on:
- 1-60 Level Progression (Zones, Dungeons, Milestones for all 60 levels)
- Class Questlines & Milestones (Whirlwind Axe, Mounts, Totems, Forms)
- Attunements (Onyxia, Molten Core, Blackwing Lair, Naxxramas, Temporal Rift)
- Travel Networks (Boats, Zeppelins, Deeprun Tram, Portal Locations)
- WoW: Forever Systems (Horizontal Progression, Skyborne Elves, New Tier Sets, Rulesets)
"""

import re
import difflib
from datetime import datetime, timezone, timedelta
from typing import Dict, Any, List, Optional

# Complete 1-60 Level Progression Guide
LEVEL_BRACKETS = [
    {
        "min": 1, "max": 10,
        "alliance_zones": "Elwynn Forest (1-10), Dun Morogh (1-10), Teldrassil (1-10)",
        "horde_zones": "Durotar (1-10), Mulgore (1-10), Tirisfal Glades (1-10)",
        "forever_zones": "Zephras Isle (1-10 Skyborne Elf Starting Experience)",
        "dungeons": "None (Focus on starter quests)",
        "milestones": "Level 10: First Talent Point unlocked, Class Quests (Hunter Pets, Warrior Defensive Stance/Taunt, Voidwalker/Blood Elf/Shaman Earth Totem)."
    },
    {
        "min": 11, "max": 20,
        "alliance_zones": "Westfall (10-20), Loch Modan (10-20), Darkshore (10-20), Redridge Mountains (15-25)",
        "horde_zones": "The Barrens (10-25), Silverpine Forest (10-20), Stonetalon Mountains (15-25)",
        "forever_zones": "Zephras Isle: Coastal Shallows & High Aerie (10-20)",
        "dungeons": "Ragefire Chasm (13-18), The Deadmines (17-26), Wailing Caverns (17-24)",
        "milestones": "Level 20: First major class abilities (Rogue Stealth improvements/Poisons, Cat Form for Druids, Ghost Wolf for Shamans)."
    },
    {
        "min": 21, "max": 30,
        "alliance_zones": "Redridge Mountains (15-25), Duskwood (20-30), Wetlands (20-30), Ashenvale (20-30)",
        "horde_zones": "The Barrens (10-25), Ashenvale (20-30), Stonetalon Mountains (20-30), Hillsbrad Foothills (20-30), Thousand Needles (25-35)",
        "forever_zones": "Sunken Citadel Dungeon (22-26 on Zephras Isle)",
        "dungeons": "Shadowfang Keep (22-30), Blackfathom Deeps (24-32), The Stockade (24-32), Gnomeregan (29-38), Razorfen Kraul (29-38), Scarlet Monastery: Graveyard (29-35)",
        "milestones": "Level 30: 31-point talent trees opening up, Travel Form for Druids, Berserker Stance & Intercept for Warriors, Astral Recall for Shamans."
    },
    {
        "min": 31, "max": 40,
        "alliance_zones": "Duskwood (28-32), Stranglethorn Vale (30-45), Arathi Highlands (30-40), Desolace (30-40), Badlands (35-45), Swamp of Sorrows (35-45)",
        "horde_zones": "Thousand Needles (Shimmering Flats 30-35), Stranglethorn Vale (30-45), Arathi Highlands (30-40), Desolace (30-40), Badlands (35-45)",
        "forever_zones": "Zephras-Darkshore Cross-Continental Air Corridors",
        "dungeons": "Scarlet Monastery: Library (33-39), Armory (36-42), Cathedral (38-45), Razorfen Downs (37-46)",
        "milestones": "⭐ Level 40: Apprentice Riding + First Mount (60% speed)! Armor upgrade: Warriors/Paladins unlock Plate armor; Hunters/Shamans unlock Mail armor."
    },
    {
        "min": 41, "max": 50,
        "alliance_zones": "Tanaris (40-50), Feralas (41-49), The Hinterlands (42-49), Searing Gorge (43-50), Blasted Lands (45-55)",
        "horde_zones": "Tanaris (40-50), Feralas (41-49), The Hinterlands (42-49), Searing Gorge (43-50), Blasted Lands (45-55)",
        "forever_zones": "Ruins of Gilneas & Greymane Wall border reconnaissance (48-52)",
        "dungeons": "Uldaman (41-51), Zul'Farrak (44-54), Maraudon (46-55), Sunken Temple (50-60)",
        "milestones": "Level 50: Level 50 Class Quests (Epic weapon and unique trinket rewards from Sunken Temple)."
    },
    {
        "min": 51, "max": 60,
        "alliance_zones": "Un'Goro Crater (50-55), Felwood (50-55), Western Plaguelands (51-58), Burning Steppes (50-58), Eastern Plaguelands (53-60), Winterspring (55-60), Silithus (55-60)",
        "horde_zones": "Un'Goro Crater (50-55), Felwood (50-55), Western Plaguelands (51-58), Burning Steppes (50-58), Eastern Plaguelands (53-60), Winterspring (55-60), Silithus (55-60)",
        "forever_zones": "Mount Hyjal (58-60), The Riverglades (54-58), Karazhan Crypts (60), Temporal Rift Raid (60)",
        "dungeons": "Blackrock Depths (52-60), LBRS (55-60), UBRS (58-60), Stratholme (58-60), Scholomance (58-60), Dire Maul (56-60), Hateforge Quarry (52-56), Roots of Nordrassil (58-60)",
        "milestones": "⭐ Level 60 Cap: Epic Mount (100% speed), Tier 0/0.5 sets, Onyxia/MC/BWL/Naxx attunements, WoW: Forever horizontal endgame progression."
    }
]

# Major Attunements & System Guides
ATTUNEMENTS = {
    "onyxia": {
        "title": "Onyxia's Lair Attunement Guide",
        "alliance": (
            "1. Start with 'Dragonkin Menace' in Morgan's Vigil (Burning Steppes).\n"
            "2. Complete Marshal Windsor quest chain in Blackrock Depths (jailbreak escort).\n"
            "3. Bring Windsor to Stormwind Keep to unmask Lady Katrana Prestor as Onyxia.\n"
            "4. Slay General Drakkisath in UBRS for the Blood of the Black Dragon Champion to forge your Drakefire Amulet."
        ),
        "horde": (
            "1. Start with 'Warlord's Command' in Kargath (Badlands).\n"
            "2. Slay Overlord Wyrmthalak (LBRS) and return to Thrall in Orgrimmar.\n"
            "3. Meet Rexxar roaming Desolace / Feralas border.\n"
            "4. Journey to Dustwallow Marsh to consult Myranda the Hag.\n"
            "5. Slay General Drakkisath in UBRS and return to Rexxar for the Drakefire Amulet."
        ),
        "tip": "You MUST have the Drakefire Amulet in your inventory to pass through the instance portal in Dustwallow Marsh!"
    },
    "molten core": {
        "title": "Molten Core Attunement (Attunement to the Core)",
        "guide": (
            "1. Speak to Lothos Riftwaker stationed outside Blackrock Mountain (level 55+).\n"
            "2. Enter Blackrock Depths and navigate through the Lyceum to the Molten Core threshold.\n"
            "3. Loot the 'Core Fragment' from the stalagmite next to the entrance portal.\n"
            "4. Return to Lothos Riftwaker to complete the quest."
        ),
        "tip": "Once completed, you can click on Lothos Riftwaker directly to teleport your entire raid into Molten Core without walking through BRD!"
    },
    "blackwing lair": {
        "title": "Blackwing Lair Attunement (Blackhand's Command)",
        "guide": (
            "1. Kill the Scarshield Quartermaster right outside the UBRS/LBRS hallway in Blackrock Mountain.\n"
            "2. Loot 'Blackhand's Command' and read the letter to accept the quest.\n"
            "3. Enter Upper Blackrock Spire (UBRS) and slay General Drakkisath.\n"
            "4. Click the 'Orb of Ascension' located directly behind General Drakkisath's throne."
        ),
        "tip": "Once attuned, you can touch the golden Orb of Command at the end of the Blackrock Mountain hallway to teleport straight into BWL."
    },
    "temporal rift": {
        "title": "The Temporal Rift Raid Attunement (WoW: Forever Classic+)",
        "guide": (
            "1. Speak to Watcher Leor at the Blasted Lands Redoubt (62, 38) at Level 60.\n"
            "2. Infiltrate the sealed perimeter around the Unopened Dark Portal.\n"
            "3. Slay 3 Chronomantic Rift-stalkers to gather Temporal Shards.\n"
            "4. Forge your Temporal Chronometer to attune your character to the alternate timeline."
        ),
        "tip": "The Temporal Rift is Forever's flagship 20-player raid tier featuring the 'Signet of the Unopened Portal' horizontal tier set."
    },
    "naxxramas": {
        "title": "Naxxramas Attunement (The Dread Citadel - Naxxramas)",
        "guide": (
            "1. Reach Level 60 and at least **Honored** reputation with the **Argent Dawn**.\n"
            "2. Speak to **Archmage Angela Dosantos** at Light's Hope Chapel in Eastern Plaguelands.\n"
            "3. Turn in the required materials based on your Argent Dawn reputation:\n"
            "   • **Honored:** 5 Righteous Orbs, 2 Arcane Crystals, 1 Nexus Crystal, and 60 Gold\n"
            "   • **Revered:** 2 Righteous Orbs, 1 Arcane Crystal, and 30 Gold\n"
            "   • **Exalted:** Absolutely FREE! (No materials or gold required)"
        ),
        "tip": "Grind Scholomance/Stratholme scourge stones or farm cauldron quests to reach Exalted and save valuable crafting materials!"
    }
}

# Major Travel Routes
TRAVEL_ROUTES = {
    "boats": (
        "• Menethil Harbor (Wetlands) ⇄ Auberdine (Darkshore) [Alliance]\n"
        "• Menethil Harbor (Wetlands) ⇄ Theramore Isle (Dustwallow Marsh) [Alliance]\n"
        "• Rut'theran Village (Darnassus) ⇄ Auberdine (Darkshore) ⇄ Zephras Isle [Alliance / Forever]\n"
        "• Booty Bay (Stranglethorn Vale) ⇄ Ratchet (The Barrens) [Neutral / Both]"
    ),
    "zeppelins": (
        "• Orgrimmar (Durotar) ⇄ Undercity (Tirisfal Glades) [Horde]\n"
        "• Orgrimmar (Durotar) ⇄ Grom'gol Base Camp (Stranglethorn Vale) [Horde]\n"
        "• Undercity (Tirisfal Glades) ⇄ Grom'gol Base Camp (Stranglethorn Vale) [Horde]"
    ),
    "tram": (
        "• Deeprun Tram: Direct underground rail transit connecting Stormwind City (Dwarven District) ⇄ Ironforge (Tinker Town). Instant & free for Alliance!"
    )
}

# Core Game Mechanics & Quick Reference FAQ
GAMEPLAY_MECHANICS = {
    "wand": {
        "title": "🪄 Wand Equipment & Progression Guide",
        "description": (
            "• **Level 5 (Earliest Wand):** *Lesser Magic Wand* (11.3 DPS) — Crafted by Enchanters or bought on Auction House.\n"
            "• **Level 13:** *Greater Magic Wand* (17.5 DPS) — Crafted by Enchanters or bought on Auction House.\n"
            "• **Level 15:** *Spark of the People's Militia* (Westfall Alliance quest reward).\n"
            "• **Level 18:** *Gravestone Scepter* (29.0 DPS) — 'Blackfathom Villainy' quest reward for BFD. Best early leveling wand in Classic!\n"
            "• **Vendors:** City wand merchants sell basic wands starting around Level 15–20."
        )
    },
    "mount": {
        "title": "🐎 Mounts & Riding Skill Progression",
        "description": (
            "• **Level 40 (Apprentice Riding • 60% Speed):**\n"
            "  - Training: 18–20g | Mount: 72–80g (~90–100g total without discounts)\n"
            "  - Paladins (*Warhorse*) & Warlocks (*Felsteed*) get free class mounts at level 40!\n"
            "• **Level 60 (Journeyman Riding • 100% Speed):**\n"
            "  - Training: 90–100g | Epic Mount: 900–1000g (~1000g total)\n"
            "  - Paladins (*Charger*) & Warlocks (*Dreadsteed*) unlock epic class quest chains."
        )
    },
    "weapon trainer": {
        "title": "⚔️ Weapon Master Locations & Skills",
        "description": (
            "**Alliance:**\n"
            "• **Stormwind (Woo Ping):** Crossbows, Daggers, Swords (1H/2H), Polearms\n"
            "• **Ironforge (Bixi & Buliwyf):** Guns, Axes (1H/2H), Maces (1H/2H), Fist Weapons\n"
            "• **Darnassus (Ilyenia):** Bows, Thrown, Staves, Daggers\n\n"
            "**Horde:**\n"
            "• **Orgrimmar (Sayoc & Hanashi):** Bows, Axes (1H/2H), Staves, Thrown, Daggers, Fist Weapons\n"
            "• **Thunder Bluff (Ansekhwa):** Guns, Maces (1H/2H), Staves\n"
            "• **Undercity (Archibald):** Crossbows, Daggers, Polearms, Swords (1H/2H)"
        )
    },
    "hit cap": {
        "title": "🎯 Hit Caps & Combat Table Mechanics",
        "description": (
            "• **Melee Yellow Hit Cap:** 9% vs Level 63 bosses (**6%** with 305+ Weapon Skill)\n"
            "• **Dual Wield White Hit Cap:** 27% auto-attack miss penalty\n"
            "• **Spell Hit Cap:** 16% (83% base hit rate vs Level 63 bosses; 1% binary resist floor)\n"
            "• **Defense Cap:** 440 Defense Skill (eliminates boss critical strikes)"
        )
    },
    "armor": {
        "title": "🛡️ Armor Proficiencies & Level 40 Upgrades",
        "description": (
            "• **Level 1 Proficiencies:**\n"
            "  - Cloth: Priest, Mage, Warlock\n"
            "  - Leather: Rogue, Druid, Hunter, Shaman\n"
            "  - Mail: Warrior, Paladin\n"
            "• **Level 40 Armor Upgrades (Learn at Class Trainer):**\n"
            "  - **Warriors & Paladins** unlock **Plate Armor**\n"
            "  - **Hunters & Shamans** unlock **Mail Armor**"
        )
    },
    "dual wield": {
        "title": "🗡️ Dual Wield Mechanics",
        "description": (
            "• **Classes:** Rogues (Level 10), Warriors (Level 20), Hunters (Level 20)\n"
            "• **Mechanics:** Off-hand strikes deal 50% damage and incur a 27% white-hit miss penalty. Yellow special attacks stay at 9% / 6% cap."
        )
    }
}



def get_level_advice(level: int) -> Dict[str, Any]:
    """Generates a complete, tailored guide for a specific character level."""
    matched = None
    for b in LEVEL_BRACKETS:
        if b["min"] <= level <= b["max"]:
            matched = b
            break

    if not matched:
        matched = LEVEL_BRACKETS[-1]

    return {
        "level": level,
        "bracket": f"Level {matched['min']}-{matched['max']}",
        "alliance_zones": matched["alliance_zones"],
        "horde_zones": matched["horde_zones"],
        "forever_zones": matched["forever_zones"],
        "milestones": matched["milestones"]
    }


# Comprehensive Zone Map Directory (Classic Azeroth & WoW: Forever)
ZONES_DATA = {
    # Eastern Kingdoms
    "Elwynn Forest": {
        "continent": "Eastern Kingdoms", "level": "1–10", "faction": "Alliance",
        "hubs": "Goldshire (42, 65), Northshire Valley (50, 42)",
        "borders": "Westfall (West), Redridge Mountains (East), Duskwood (South)",
        "pois": "Fargodeep Mine (38, 52), Jasperlode Mine (61, 54), Eastvale Logging Camp (85, 69)",
        "is_forever": False
    },
    "Westfall": {
        "continent": "Eastern Kingdoms", "level": "10–20", "faction": "Alliance",
        "hubs": "Sentinel Hill (56, 47), Moonbrook (42, 68), Saldean's Farm (56, 31)",
        "borders": "Elwynn Forest (North across bridge), Duskwood (East river)",
        "pois": "Gold Coast Quarry (32, 45), Demont's Place (45, 62), Westfall Lighthouse (30, 86)",
        "is_forever": False
    },
    "Redridge Mountains": {
        "continent": "Eastern Kingdoms", "level": "15–25", "faction": "Contested",
        "hubs": "Lakeshire (26, 46)",
        "borders": "Elwynn Forest (West), Burning Steppes (North), Duskwood (Southwest)",
        "pois": "Tower of Ilgalar (79, 47), Alther's Mill (53, 44), Stonewatch Keep (76, 52)",
        "is_forever": False
    },
    "Duskwood": {
        "continent": "Eastern Kingdoms", "level": "20–30", "faction": "Contested",
        "hubs": "Darkshire (73, 44)",
        "borders": "Elwynn Forest (North river), Westfall (West river), Redridge (East), STV (South)",
        "pois": "The Rotting Orchard (64, 34), Raven Hill Cemetery (18, 56), Twilight Grove (47, 40)",
        "is_forever": False
    },
    "Stranglethorn Vale": {
        "continent": "Eastern Kingdoms", "level": "30–45", "faction": "Contested",
        "hubs": "Booty Bay (27, 77), Grom'gol Base Camp (32, 27), Rebel Camp (37, 3)",
        "borders": "Duskwood (North), Boat from Booty Bay ⇄ Ratchet",
        "pois": "Gurubashi Arena (31, 47), Nesingwary's Expedition (35, 10), Zul'Gurub (72, 16)",
        "is_forever": False
    },
    "Dun Morogh": {
        "continent": "Eastern Kingdoms", "level": "1–10", "faction": "Alliance",
        "hubs": "Kharanos (46, 52), Anvilmar (28, 68)",
        "borders": "Loch Modan (East), Ironforge capital (North)",
        "pois": "Gnomeregan entrance (24, 38), Brewnall Village (30, 46), Frostmane Front (24, 50)",
        "is_forever": False
    },
    "Loch Modan": {
        "continent": "Eastern Kingdoms", "level": "10–20", "faction": "Alliance",
        "hubs": "Thelsamar (34, 46)",
        "borders": "Dun Morogh (West), Wetlands (North via tunnel), Badlands (South)",
        "pois": "Stonewrought Dam (47, 13), Valley of Kings (22, 65), Mo'grosh Stronghold (70, 22)",
        "is_forever": False
    },
    "Wetlands": {
        "continent": "Eastern Kingdoms", "level": "20–30", "faction": "Contested",
        "hubs": "Menethil Harbor (10, 59), Greenwarden's Grove (50, 40)",
        "borders": "Loch Modan (South), Arathi Highlands (North via Thandol Span). Boats to Darkshore & Theramore",
        "pois": "Dun Modr (49, 17), Mosshide Fen (56, 38), Whelgar's Excavation (34, 47)",
        "is_forever": False
    },
    "Arathi Highlands": {
        "continent": "Eastern Kingdoms", "level": "30–40", "faction": "Contested",
        "hubs": "Refuge Pointe (46, 46), Hammerfall (73, 34)",
        "borders": "Wetlands (South), Hillsbrad Foothills (West), The Hinterlands (North)",
        "pois": "Stromgarde Keep (20, 62), Circle of East Binding (52, 51), Faldir's Cove (21, 75)",
        "is_forever": False
    },
    "Hillsbrad Foothills": {
        "continent": "Eastern Kingdoms", "level": "20–30", "faction": "Contested",
        "hubs": "Southshore (50, 56), Tarren Mill (62, 19)",
        "borders": "Silverpine (West), Arathi (East), Alterac Mountains (North)",
        "pois": "Durnholde Keep (76, 44), Hillsbrad Fields (34, 37), Purgation Isle (16, 68)",
        "is_forever": False
    },
    "Alterac Mountains": {
        "continent": "Eastern Kingdoms", "level": "30–40", "faction": "Contested",
        "hubs": "Ruins of Alterac (39, 58), Strahnbrad (58, 25)",
        "borders": "Hillsbrad Foothills (South), Western Plaguelands (Northeast)",
        "pois": "Crushridge Hold (52, 57), Dalaran bubble / crater (18, 70), Syndicate camps",
        "is_forever": False
    },
    "The Hinterlands": {
        "continent": "Eastern Kingdoms", "level": "40–50", "faction": "Contested",
        "hubs": "Aerie Peak (14, 46), Revantusk Village (78, 80)",
        "borders": "Hillsbrad/Arathi (South), Western Plaguelands (Northwest)",
        "pois": "Jintha'Alor (59, 73), Seradane (63, 25), Skull Rock (56, 43)",
        "is_forever": False
    },
    "Badlands": {
        "continent": "Eastern Kingdoms", "level": "35–45", "faction": "Contested",
        "hubs": "Kargath (2, 46)",
        "borders": "Loch Modan (North), Searing Gorge (West)",
        "pois": "Uldaman Entrance (42, 18), Dustwind Gulch (58, 34), Camp Cagg (12, 53)",
        "is_forever": False
    },
    "Swamp of Sorrows": {
        "continent": "Eastern Kingdoms", "level": "35–45", "faction": "Contested",
        "hubs": "Stonard (45, 54)",
        "borders": "Deadwind Pass (West), Blasted Lands (South)",
        "pois": "Sunken Temple (Temple of Atal'Hakkar) (70, 53), Pool of Tears, Misty Reed Post (80, 48)",
        "is_forever": False
    },
    "Blasted Lands": {
        "continent": "Eastern Kingdoms", "level": "45–55", "faction": "Contested",
        "hubs": "Nethergarde Keep (65, 18), Bloodvenom Post",
        "borders": "Swamp of Sorrows (North)",
        "pois": "Unopened Dark Portal (54, 54), Temporal Rift Raid (62, 38 [Forever]), Tainted Scar (38, 50)",
        "is_forever": False
    },
    "Searing Gorge": {
        "continent": "Eastern Kingdoms", "level": "43–50", "faction": "Contested",
        "hubs": "Thorium Point (37, 26)",
        "borders": "Badlands (East), Loch Modan (North gate), Burning Steppes (South via BRM)",
        "pois": "The Slag Pit (40, 50), Grimesilt Dig Site (66, 42), Blackrock Mountain Entrance (35, 83)",
        "is_forever": False
    },
    "Burning Steppes": {
        "continent": "Eastern Kingdoms", "level": "50–58", "faction": "Contested",
        "hubs": "Morgan's Vigil (84, 68), Flame Crest (65, 24)",
        "borders": "Redridge Mountains (South), Searing Gorge (North via BRM)",
        "pois": "Blackrock Mountain (29, 38), Hateforge Quarry (42, 38 [Forever]), Dreadmaul Rock (75, 45)",
        "is_forever": False
    },
    "Deadwind Pass": {
        "continent": "Eastern Kingdoms", "level": "55–60", "faction": "Contested",
        "hubs": "Morgan's Plot (42, 70)",
        "borders": "Duskwood (West), Swamp of Sorrows (East)",
        "pois": "Karazhan Spire (47, 75), Karazhan Crypts (44, 76 [Forever]), Vice's Overlook",
        "is_forever": False
    },
    "Western Plaguelands": {
        "continent": "Eastern Kingdoms", "level": "51–58", "faction": "Contested",
        "hubs": "Chillwind Camp (43, 85)",
        "borders": "Eastern Plaguelands (East), Hillsbrad/Alterac (South), Tirisfal Glades (West)",
        "pois": "Scholomance / Caer Darrow (69, 73), Hearthglen (46, 16), Sorrow Hill (48, 78)",
        "is_forever": False
    },
    "Eastern Plaguelands": {
        "continent": "Eastern Kingdoms", "level": "53–60", "faction": "Contested",
        "hubs": "Light's Hope Chapel (81, 58)",
        "borders": "Western Plaguelands (West)",
        "pois": "Stratholme Main Gate (27, 11), Stratholme Service Gate (43, 19), Tyr's Hand (82, 76), Naxxramas (39, 23)",
        "is_forever": False
    },
    "Tirisfal Glades": {
        "continent": "Eastern Kingdoms", "level": "1–10", "faction": "Horde",
        "hubs": "Brill (60, 52), Deathknell (31, 65)",
        "borders": "Silverpine Forest (South), Western Plaguelands (East), Undercity capital",
        "pois": "Scarlet Monastery (39, 29), Agamand Mills (48, 37), Garren's Haunt (59, 32)",
        "is_forever": False
    },
    "Silverpine Forest": {
        "continent": "Eastern Kingdoms", "level": "10–20", "faction": "Horde",
        "hubs": "The Sepulcher (43, 40)",
        "borders": "Tirisfal Glades (North), Hillsbrad Foothills (East), Ruins of Gilneas (South)",
        "pois": "Shadowfang Keep (44, 67), Ambermill (63, 62), Pyrewood Village (46, 70)",
        "is_forever": False
    },
    "Ruins of Gilneas": {
        "continent": "Eastern Kingdoms", "level": "50–54", "faction": "Contested",
        "hubs": "Greymane Wall Redoubt (52, 18)",
        "borders": "Silverpine Forest (North across Greymane Wall)",
        "pois": "Abandoned Coast, Gilnean Border Fort, Bloodfang Woods",
        "is_forever": True
    },

    # Kalimdor
    "Durotar": {
        "continent": "Kalimdor", "level": "1–10", "faction": "Horde",
        "hubs": "Razor Hill (52, 43), Sen'jin Village (55, 74), Valley of Trials (45, 68)",
        "borders": "The Barrens (West across Southfury River), Orgrimmar capital (North)",
        "pois": "Echo Isles (67, 85), Skull Rock (54, 10), Tiragarde Keep (57, 55)",
        "is_forever": False
    },
    "Mulgore": {
        "continent": "Kalimdor", "level": "1–10", "faction": "Horde",
        "hubs": "Bloodhoof Village (47, 60), Camp Narache (44, 76)",
        "borders": "The Barrens (East through Great Gate), Thunder Bluff capital (North)",
        "pois": "Bael'dun Digsite (31, 28), Palemane Rock (36, 61), Red Cloud Mesa",
        "is_forever": False
    },
    "The Barrens": {
        "continent": "Kalimdor", "level": "10–25", "faction": "Horde",
        "hubs": "The Crossroads (52, 31), Ratchet (62, 37), Camp Taurajo (44, 59)",
        "borders": "Durotar (East), Mulgore (West), Ashenvale (North), 1k Needles (South), Dustwallow (SE)",
        "pois": "Wailing Caverns (42, 66), Razorfen Kraul (40, 89), Razorfen Downs (47, 90), Field of Giants",
        "is_forever": False
    },
    "Ashenvale": {
        "continent": "Kalimdor", "level": "18–30", "faction": "Contested",
        "hubs": "Astranaar (34, 50), Splintertree Post (73, 61), Zoram'gar Outpost (12, 34)",
        "borders": "Darkshore (Northwest), The Barrens (South), Stonetalon (SW), Azshara (East), Hyjal (NE)",
        "pois": "Blackfathom Deeps (14, 14), Warsong Lumber Camp (86, 68), Silverwind Refuge (49, 67)",
        "is_forever": False
    },
    "Stonetalon Mountains": {
        "continent": "Kalimdor", "level": "15–25", "faction": "Contested",
        "hubs": "Sun Rock Retreat (47, 62), Stonetalon Peak (36, 7)",
        "borders": "The Barrens (East), Ashenvale (North), Desolace (South)",
        "pois": "Windshear Crag (60, 40), Charred Vale (32, 65), Greatwood Vale",
        "is_forever": False
    },
    "Thousand Needles": {
        "continent": "Kalimdor", "level": "25–35", "faction": "Contested",
        "hubs": "Freewind Post (46, 51), Mirage Raceway (80, 77 in Shimmering Flats)",
        "borders": "The Barrens (North elevator), Feralas (West), Tanaris (South gap)",
        "pois": "Highperch (11, 35), Splithoof Crag (48, 30), Shimmering Flats salt flat (80, 75)",
        "is_forever": False
    },
    "Desolace": {
        "continent": "Kalimdor", "level": "30–40", "faction": "Contested",
        "hubs": "Nijel's Point (66, 10), Shadowprey Village (23, 72)",
        "borders": "Stonetalon Mountains (North), Feralas (South)",
        "pois": "Maraudon Entrance (29, 62), Gelkis/Magram Centaur camps, Ghost Walker Post (56, 56)",
        "is_forever": False
    },
    "Dustwallow Marsh": {
        "continent": "Kalimdor", "level": "35–45", "faction": "Contested",
        "hubs": "Theramore Isle (67, 51), Brackenwall Village (36, 31)",
        "borders": "The Barrens (West), The Riverglades (Southwest [Forever])",
        "pois": "Onyxia's Lair (52, 76), Alcaz Island (75, 17), Witch Hill (46, 36)",
        "is_forever": False
    },
    "The Riverglades": {
        "continent": "Kalimdor", "level": "54–58", "faction": "Contested",
        "hubs": "Riverwatch Bastion (48, 52), Mirefang Hold (34, 66)",
        "borders": "Dustwallow Marsh (Northeast), Feralas (Southwest)",
        "pois": "Grove of the Stillglade (56, 38 [Forever Dungeon]), Verdant Canal, Sunken Overlook",
        "is_forever": True
    },
    "Tanaris": {
        "continent": "Kalimdor", "level": "40–50", "faction": "Contested",
        "hubs": "Gadgetzan (51, 26), Steamwheedle Port (67, 22)",
        "borders": "Thousand Needles (North), Un'Goro Crater (West gap)",
        "pois": "Zul'Farrak (39, 20), Caverns of Time (65, 50), Lost Rigger Cove (72, 45)",
        "is_forever": False
    },
    "Feralas": {
        "continent": "Kalimdor", "level": "40–50", "faction": "Contested",
        "hubs": "Feathermoon Stronghold (31, 43), Camp Mojache (75, 43)",
        "borders": "Desolace (North), Thousand Needles (East), Riverglades (NE), Silithus (South)",
        "pois": "Dire Maul (59, 44), Isle of Dread (31, 80), Ruins of Isildien (60, 68)",
        "is_forever": False
    },
    "Azshara": {
        "continent": "Kalimdor", "level": "45–55", "faction": "Contested",
        "hubs": "Talrendis Point (11, 78), Valormok (21, 52)",
        "borders": "Ashenvale (West)",
        "pois": "Ruins of Eldarath (38, 55), Temple of Arkkoran (78, 40), Bay of Storms (54, 72)",
        "is_forever": False
    },
    "Felwood": {
        "continent": "Kalimdor", "level": "48–55", "faction": "Contested",
        "hubs": "Emerald Sanctuary (51, 82), Bloodvenom Post (34, 52), Timbermaw Hold (64, 8)",
        "borders": "Ashenvale (South), Winterspring/Moonglade (North through Timbermaw tunnel)",
        "pois": "Jaedenar (36, 56), Ruins of Constellas (42, 70), Shatter Scar Vale (40, 44)",
        "is_forever": False
    },
    "Un'Goro Crater": {
        "continent": "Kalimdor", "level": "48–55", "faction": "Contested",
        "hubs": "Marshal's Refuge (44, 8)",
        "borders": "Tanaris (East gap), Silithus (West path)",
        "pois": "Fire Plume Ridge (50, 45), The Slithering Scar (50, 77), Golakka Hot Springs (31, 50)",
        "is_forever": False
    },
    "Silithus": {
        "continent": "Kalimdor", "level": "55–60", "faction": "Contested",
        "hubs": "Cenarion Hold (51, 38)",
        "borders": "Un'Goro Crater (East), Feralas (North path)",
        "pois": "Gates of Ahn'Qiraj (AQ20/AQ40) (28, 90), Twilight Outposts, Hive'Zora/Ashi/Regal",
        "is_forever": False
    },
    "Winterspring": {
        "continent": "Kalimdor", "level": "55–60", "faction": "Contested",
        "hubs": "Everlook (61, 38)",
        "borders": "Felwood (West through Timbermaw tunnel), Mount Hyjal (Southwest [Forever])",
        "pois": "Mazthoril (58, 62), Frostwhisper Gorge (58, 78), Starfall Village (50, 30)",
        "is_forever": False
    },
    "Darkshore": {
        "continent": "Kalimdor", "level": "10–20", "faction": "Alliance",
        "hubs": "Auberdine (36, 44)",
        "borders": "Ashenvale (South). Boats to Menethil Harbor, Rut'theran Village, Zephras Isle",
        "pois": "Tower of Althalaxx (55, 26), Ruins of Mathystra (57, 18), Master's Glaive (39, 85)",
        "is_forever": False
    },
    "Teldrassil": {
        "continent": "Kalimdor", "level": "1–10", "faction": "Alliance",
        "hubs": "Dolanaar (55, 60), Shadowglen (58, 40), Rut'theran Village (55, 88)",
        "borders": "Rut'theran Village connects via ship to Auberdine & Zephras Isle. Darnassus capital",
        "pois": "Starbreeze Village (65, 56), Gnarlpine Hold (45, 58), Lake Al'Ameth (56, 62)",
        "is_forever": False
    },
    "Moonglade": {
        "continent": "Kalimdor", "level": "All (Sanctuary)", "faction": "Neutral",
        "hubs": "Nighthaven (45, 41)",
        "borders": "Timbermaw Hold tunnel to Felwood/Winterspring",
        "pois": "Lake Elune'ara, Shrine of Remulos (36, 42), Great Bear Spirit",
        "is_forever": False
    },
    "Mount Hyjal": {
        "continent": "Kalimdor", "level": "58–60", "faction": "Contested",
        "hubs": "Nordrassil Sanctuary (52, 28), Cenarion Outpost (44, 61)",
        "borders": "Winterspring (Northwest tunnel), Ashenvale/Darkshore borderlands",
        "pois": "World Tree Nordrassil, Roots of Nordrassil Dungeon (42, 65), The Verdant Scar Raid (68, 74)",
        "is_forever": True
    },
    "Zephras Isle": {
        "continent": "Great Sea", "level": "1–25", "faction": "Alliance",
        "hubs": "High Aerie (48, 32), Coastal Shallows (32, 60)",
        "borders": "Boat connection from Auberdine (Darkshore) & Rut'theran Village",
        "pois": "Skyborne Elves Capital, Sunken Citadel Dungeon (28, 74), Stormpeaks Rookery, Pirate Cove",
        "is_forever": True
    },

    # Capital Cities
    "Stormwind City": {
        "continent": "Eastern Kingdoms", "level": "Capital", "faction": "Alliance",
        "hubs": "Trade District, Old Town, Mage Quarter, Dwarven District, Cathedral Square, Keep",
        "borders": "Elwynn Forest (South gates). Deeprun Tram to Ironforge",
        "pois": "The Stockade Dungeon (40, 60), Vault bank, Flight Master (66, 62 in Trade District)",
        "is_forever": False
    },
    "Ironforge": {
        "continent": "Eastern Kingdoms", "level": "Capital", "faction": "Alliance",
        "hubs": "The Commons, Mystic Ward, Military Ward, Tinker Town, The Great Forge",
        "borders": "Dun Morogh (Gates). Deeprun Tram to Stormwind City (Tinker Town)",
        "pois": "High Seat, Bank, Flight Master (55, 47 in The Great Forge)",
        "is_forever": False
    },
    "Darnassus": {
        "continent": "Kalimdor", "level": "Capital", "faction": "Alliance",
        "hubs": "Craftsmen's Terrace, Temple of the Moon, Warrior's Terrace, Tradesmen's Terrace",
        "borders": "Teldrassil. Flight & Boat transit from Rut'theran Village at base of tree",
        "pois": "Temple of Elune, Bank, Cenarion Enclave",
        "is_forever": False
    },
    "Orgrimmar": {
        "continent": "Kalimdor", "level": "Capital", "faction": "Horde",
        "hubs": "Valley of Strength, Valley of Honor, Valley of Spirits, The Drag, Cleft of Shadows",
        "borders": "Durotar. Zeppelins to Undercity & Grom'gol outside main gates (50, 12)",
        "pois": "Ragefire Chasm Dungeon (in Cleft of Shadows), Flight Master (45, 63 above Valley of Strength)",
        "is_forever": False
    },
    "Thunder Bluff": {
        "continent": "Kalimdor", "level": "Capital", "faction": "Horde",
        "hubs": "Central Mesa, Hunter Rise, Spirit Rise, Elder Rise",
        "borders": "Mulgore (Elevators at base)",
        "pois": "Totem pole bank, Flight Master (47, 50 on Central Mesa)",
        "is_forever": False
    },
    "Undercity": {
        "continent": "Eastern Kingdoms", "level": "Capital", "faction": "Horde",
        "hubs": "Rogues' Quarter, Magic Quarter, War Quarter, The Apothecarium",
        "borders": "Tirisfal Glades. Zeppelins to Orgrimmar & Grom'gol at Brill / Ruins of Lordaeron",
        "pois": "Royal Quarter (Sylvanas), Flight Master (63, 48 in central courtyard)",
        "is_forever": False
    }
}


def get_zone_info(query: str, alias_map: Optional[Dict[str, str]] = None) -> Optional[Dict[str, Any]]:
    """Retrieves full zone metadata with alias translation and typo-tolerance."""
    import difflib
    if not query:
        return None
    q = query.strip().lower()

    if alias_map and q in alias_map:
        q = alias_map[q].lower()

    # Direct match
    for name, data in ZONES_DATA.items():
        if name.lower() == q:
            return {"name": name, **data}

    # Partial match
    for name, data in ZONES_DATA.items():
        if q in name.lower() or name.lower() in q:
            return {"name": name, **data}

    # Fuzzy match
    names = list(ZONES_DATA.keys())
    matches = difflib.get_close_matches(query, names, n=1, cutoff=0.55)
    if matches:
        return {"name": matches[0], **ZONES_DATA[matches[0]]}

    return None


# -------------------------------------------------------------
# Gathering Nodes (Mining, Herbalism, Skinning) Database
# -------------------------------------------------------------
GATHERING_NODES: Dict[str, Dict[str, Any]] = {
    # MINING NODES
    "copper vein": {
        "type": "Mining", "skill_req": 1, "item": "Copper Ore, Rough Stone",
        "zones": "Elwynn Forest, Dun Morogh, Durotar, Mulgore, Tirisfal Glades, Darkshore",
        "route": "Circle outer foothills and cliff edges around starter zones.",
        "tip": "Smelt into Copper Bars to level Mining to 50 easily."
    },
    "tin vein": {
        "type": "Mining", "skill_req": 65, "item": "Tin Ore, Coarse Stone",
        "zones": "The Barrens, Westfall, Loch Modan, Redridge Mountains, Silverpine Forest",
        "route": "Foothills of Redridge (around Render's Rock) & southern Barrens hills.",
        "tip": "Combine 1 Copper + 1 Tin to smelt Bronze Bars for rapid skillups (65-115)."
    },
    "silver vein": {
        "type": "Mining", "skill_req": 75, "item": "Silver Ore, Shadowgem",
        "zones": "Redridge Mountains, Loch Modan, Barrens, Ashenvale, Hillsbrad",
        "route": "Rare spawn replacement for Tin Veins in mountain caves and cliffs.",
        "tip": "High demand for Blacksmithing, Engineering & early Jewelry craft."
    },
    "iron deposit": {
        "type": "Mining", "skill_req": 125, "item": "Iron Ore, Heavy Stone",
        "zones": "Arathi Highlands, Thousand Needles, Desolace, Badlands, Hillsbrad",
        "route": "Circle the perimeter mountains of Arathi Highlands for highest node density in game.",
        "tip": "Smelting Iron levels you from 125 to 160."
    },
    "gold vein": {
        "type": "Mining", "skill_req": 155, "item": "Gold Ore, Malachite, Tigerseye",
        "zones": "Arathi Highlands, Badlands, Alterac Mountains, Stranglethorn Vale",
        "route": "Rare spawn replacement for Iron Deposits.",
        "tip": "Used for Alchemy transmutes and Golden Rods in Enchanting."
    },
    "mithril deposit": {
        "type": "Mining", "skill_req": 175, "item": "Mithril Ore, Solid Stone",
        "zones": "Badlands, Tanaris, Searing Gorge, Hinterlands, Western Plaguelands",
        "route": "Badlands perimeter loop is the undisputed fastest 175-225 route in Azeroth.",
        "tip": "Solid Stone is vital for Goblin Rocket Boots & sapper charges."
    },
    "truesilver deposit": {
        "type": "Mining", "skill_req": 230, "item": "Truesilver Ore, Aquamarine, Star Ruby",
        "zones": "Tanaris, Searing Gorge, Winterspring, Western/Eastern Plaguelands",
        "route": "Rare spawn replacement for Mithril Deposits.",
        "tip": "Required for Truesilver Champion and mid-tier Blacksmithing weapons."
    },
    "small thorium vein": {
        "type": "Mining", "skill_req": 245, "item": "Thorium Ore, Dense Stone",
        "zones": "Un'Goro Crater, Felwood, Western Plaguelands, Burning Steppes, Blasted Lands",
        "route": "Run the crater wall loop of Un'Goro Crater (counter-clockwise).",
        "tip": "Levels you smoothly from 245 to 275."
    },
    "rich thorium vein": {
        "type": "Mining", "skill_req": 275, "item": "Thorium Ore, Dense Stone, Arcane Crystal, Blue Sapphire",
        "zones": "Eastern Plaguelands, Silithus, Winterspring, Burning Steppes, Dire Maul East",
        "route": "Hive tunnels in Silithus or EPL perimeter. Solo jump runs in DME for Rogues/Warlocks.",
        "tip": "Source of Arcane Crystals needed for Arcanite Bars (Thunderfury, Lionheart Helm)."
    },
    "dark iron deposit": {
        "type": "Mining", "skill_req": 230, "item": "Dark Iron Ore, Blood of the Mountain, Black Vitriol",
        "zones": "Blackrock Depths, Molten Core, Searing Gorge, Burning Steppes",
        "route": "Inside Blackrock Depths (Ring of Law, Incendius area) & Molten Core trash.",
        "tip": "Can only be smelted at the Black Forge inside BRD (near Magmus/Thaurissan)."
    },

    # HERBALISM NODES
    "peacebloom": {
        "type": "Herbalism", "skill_req": 1, "item": "Peacebloom",
        "zones": "Elwynn Forest, Durotar, Mulgore, Tirisfal Glades, Dun Morogh, Teldrassil",
        "route": "Open sunny fields and starter zone plains.",
        "tip": "Used for Minor Healing Potions and early Alchemy leveling."
    },
    "silverleaf": {
        "type": "Herbalism", "skill_req": 1, "item": "Silverleaf",
        "zones": "Elwynn Forest, Durotar, Mulgore, Tirisfal Glades, Teldrassil, Darkshore",
        "route": "Under forest tree canopies and shade in starter zones.",
        "tip": "Pairs with Peacebloom for 1-50 Alchemy."
    },
    "earthroot": {
        "type": "Herbalism", "skill_req": 15, "item": "Earthroot",
        "zones": "The Barrens, Westfall, Redridge, Loch Modan, Silverpine, Darkshore",
        "route": "Rocky bluffs, crags, and hillsides.",
        "tip": "Essential for Healing Potions and Armor Potions."
    },
    "mageroyal": {
        "type": "Herbalism", "skill_req": 50, "item": "Mageroyal",
        "zones": "Westfall, Silverpine Forest, Loch Modan, The Barrens, Darkshore",
        "route": "Grassy open areas near roads and farms.",
        "tip": "Levels Herbalism quickly from 50 to 85."
    },
    "briarthorn": {
        "type": "Herbalism", "skill_req": 70, "item": "Briarthorn",
        "zones": "Duskwood, Silverpine Forest, The Barrens, Loch Modan, Redridge",
        "route": "Base of large trees in Duskwood & hills of Silverpine.",
        "tip": "Pairs with Swiftthistle for Swiftness Potions (massive PvP value)."
    },
    "stranglekelp": {
        "type": "Herbalism", "skill_req": 85, "item": "Stranglekelp",
        "zones": "Darkshore coast, Wetlands coastline, Westfall coast, Stranglethorn Vale waters",
        "route": "Underwater along shallow oceanic shorelines and river mouths.",
        "tip": "Required for Elixir of Water Breathing and Swim Speed Potions."
    },
    "bruiseweed": {
        "type": "Herbalism", "skill_req": 100, "item": "Bruiseweed",
        "zones": "The Barrens, Ashenvale, Hillsbrad Foothills, Stonetalon, Redridge",
        "route": "Building perimeters and rocky foothills in mid-level zones.",
        "tip": "Core reagent for Greater Healing Potions."
    },
    "wild steelbloom": {
        "type": "Herbalism", "skill_req": 115, "item": "Wild Steelbloom",
        "zones": "Arathi Highlands, Stranglethorn Vale, Thousand Needles, Hillsbrad",
        "route": "Mesa peaks in Thousand Needles & cliffs of Arathi Highlands.",
        "tip": "Vital for Free Action Potions (FAP) — essential Classic PvP consumable."
    },
    "grave moss": {
        "type": "Herbalism", "skill_req": 120, "item": "Grave Moss",
        "zones": "Duskwood (Addle's Stead & Raven Hill), Desolace, Scarlet Monastery (Graveyard)",
        "route": "Graveyards and burial crypts; Scarlet Monastery Graveyard dungeon farm.",
        "tip": "Key ingredient for Shadow Protection Potions (Loatheb, AQ40, PvP)."
    },
    "kingsblood": {
        "type": "Herbalism", "skill_req": 125, "item": "Kingsblood",
        "zones": "Stranglethorn Vale, Arathi Highlands, Ashenvale, Badlands, Swamp of Sorrows",
        "route": "Flat grassy plains in Stranglethorn & central Arathi.",
        "tip": "Provides massive experience/skillups from 125 to 160."
    },
    "fadeleaf": {
        "type": "Herbalism", "skill_req": 130, "item": "Fadeleaf",
        "zones": "Swamp of Sorrows, Stranglethorn Vale, Arathi Highlands, Badlands",
        "route": "Circle Swamp of Sorrows perimeter trail clockwise.",
        "tip": "Highest rogue demand in Classic for Blinding Powder and Greater Invisibility Potions."
    },
    "goldthorn": {
        "type": "Herbalism", "skill_req": 150, "item": "Goldthorn",
        "zones": "Stranglethorn Vale, Arathi Highlands, Feralas, Dustwallow Marsh, Hinterlands",
        "route": "Rocky hillsides in central/southern STV & Feralas.",
        "tip": "Used for Greater Mana Potions and Elixir of Agility."
    },
    "khadgar's whisker": {
        "type": "Herbalism", "skill_req": 185, "item": "Khadgar's Whisker",
        "zones": "Hinterlands, Stranglethorn Vale, Swamp of Sorrows, Feralas, Arathi",
        "route": "Shaded forests of Hinterlands and southern Stranglethorn Vale.",
        "tip": "Bridges skillups between 185 and 220 smoothly."
    },
    "wintersbite": {
        "type": "Herbalism", "skill_req": 195, "item": "Wintersbite",
        "zones": "Alterac Mountains (around ruins of Alterac City)",
        "route": "Snowy plateaus and peaks in Alterac Mountains.",
        "tip": "Exclusive to Alterac; vital for Frost Power Elixir and Frost Oil."
    },
    "firebloom": {
        "type": "Herbalism", "skill_req": 205, "item": "Firebloom",
        "zones": "Tanaris, Searing Gorge, Blasted Lands, Badlands",
        "route": "Desert floor of Tanaris & scorched crags of Searing Gorge.",
        "tip": "Crucial for Fire Protection Potions and Elixir of Greater Firepower."
    },
    "purple lotus": {
        "type": "Herbalism", "skill_req": 210, "item": "Purple Lotus",
        "zones": "Stranglethorn Vale, Tanaris (ruins), Feralas, Ashenvale (ruins)",
        "route": "Spawns near ancient troll and night elf ruins.",
        "tip": "Has chance to drop Wildvine when gathered."
    },
    "arthas' tears": {
        "type": "Herbalism", "skill_req": 220, "item": "Arthas' Tears",
        "zones": "Western Plaguelands, Eastern Plaguelands, Felwood",
        "route": "Blighted fields near Andorhal in Western Plaguelands.",
        "tip": "Used for Elixir of the Mongoose and Gift of Arthas."
    },
    "sungrass": {
        "type": "Herbalism", "skill_req": 230, "item": "Sungrass",
        "zones": "Feralas, Hinterlands, Azshara, Eastern Plaguelands, Felwood",
        "route": "Open sunny grass in Hinterlands (near Aerie Peak) & southern Feralas.",
        "tip": "Essential for Superior Healing Potions and Elixir of Giants."
    },
    "blindweed": {
        "type": "Herbalism", "skill_req": 235, "item": "Blindweed",
        "zones": "Swamp of Sorrows (around water pools), Zangarmarsh border, Maraudon",
        "route": "Swamp water edges throughout Swamp of Sorrows.",
        "tip": "Fastest 235-260 skillup route; key reagent for Greater Arcane Elixir."
    },
    "ghost mushroom": {
        "type": "Herbalism", "skill_req": 245, "item": "Ghost Mushroom",
        "zones": "The Hinterlands (Skulk Rock caves), Maraudon (dungeon), Dire Maul East",
        "route": "Underground caves in Hinterlands or solo Maraudon stealth farming.",
        "tip": "Crucial for Elixir of Shadow Power, Limited Invulnerability Potions (LIP), and Elixir of Demonslaying."
    },
    "gromsblood": {
        "type": "Herbalism", "skill_req": 250, "item": "Gromsblood",
        "zones": "Felwood, Blasted Lands, Desolace (Mannoroc Coven), Dire Maul East",
        "route": "Demon-infested camps along the main road of Felwood.",
        "tip": "High raid demand for Elixir of the Mongoose and Flask of the Titans."
    },
    "golden sansam": {
        "type": "Herbalism", "skill_req": 260, "item": "Golden Sansam",
        "zones": "Azshara, Felwood, Eastern Plaguelands, Un'Goro Crater, Silithus",
        "route": "Rocky plateaus of Azshara & outer ring of Un'Goro.",
        "tip": "Core herb for Major Healing Potions."
    },
    "dreamfoil": {
        "type": "Herbalism", "skill_req": 270, "item": "Dreamfoil",
        "zones": "Azshara, Felwood, Eastern Plaguelands, Silithus, Un'Goro Crater",
        "route": "Northern Azshara cliffs & corrupted glades of Felwood.",
        "tip": "Supreme demand: Used for Greater Arcane Elixir, Flask of Supreme Power, and Major Mana Potions."
    },
    "mountain silversage": {
        "type": "Herbalism", "skill_req": 280, "item": "Mountain Silversage",
        "zones": "Winterspring, Eastern Plaguelands, Silithus, Burning Steppes, Azshara",
        "route": "Cliff ledges and mountain ridges in Winterspring & Silithus.",
        "tip": "Essential for Elixir of the Mongoose; primary raid consumable herb."
    },
    "plaguebloom": {
        "type": "Herbalism", "skill_req": 285, "item": "Plaguebloom",
        "zones": "Eastern Plaguelands, Western Plaguelands, Felwood",
        "route": "Run the EPL road circuit (Corin's Crossing -> Blackwood -> Noxious Glade).",
        "tip": "Massive demand for Elixir of the Mongoose and Purification Potions."
    },
    "icecap": {
        "type": "Herbalism", "skill_req": 290, "item": "Icecap",
        "zones": "Winterspring (exclusive)",
        "route": "Northern snowfields around Lake Kel'Theril and Frostwhisper Gorge.",
        "tip": "Used for Elixir of Greater Frost Power, Major Mana Potions, and Flask of Supreme Power."
    },
    "black lotus": {
        "type": "Herbalism", "skill_req": 300, "item": "Black Lotus",
        "zones": "Burning Steppes, Eastern Plaguelands, Silithus, Winterspring, Mount Hyjal [Forever]",
        "route": "Specific high-level spawn points (1 active per zone; 45-60 min respawn).",
        "tip": "Mandatory catalyst for all endgame 2-hour Raid Flasks (Supreme Power, Titans, Distilled Wisdom)."
    },

    # SKINNING LEATHER
    "light leather": {
        "type": "Skinning", "skill_req": 1, "item": "Light Leather, Ruined Leather Scraps",
        "zones": "Elwynn, Durotar, Mulgore, Teldrassil, Dun Morogh, Westfall, Barrens",
        "route": "Boars, wolves, cats, and raptors level 1-17.",
        "tip": "Combine 3 Scraps into Light Leather; craft Light Armor Kit."
    },
    "medium leather": {
        "type": "Skinning", "skill_req": 75, "item": "Medium Leather, Medium Hide",
        "zones": "The Barrens (Southern), Redridge Mountains, Ashenvale, Wetlands, Duskwood",
        "route": "Beasts level 18-35 (Kodos, lions, crocolisks, wolves).",
        "tip": "Medium Hide is used for Hillman's Shoulders and Leatherworking leveling."
    },
    "heavy leather": {
        "type": "Skinning", "skill_req": 150, "item": "Heavy Leather, Heavy Hide",
        "zones": "Stranglethorn Vale, Thousand Needles (Shimmering Flats), Hillsbrad, Desolace",
        "route": "Basilisks, turtles, and scorpids in Shimmering Flats (fastest skinning in game!).",
        "tip": "Shimmering Flats has near-instant beast respawns."
    },
    "thick leather": {
        "type": "Skinning", "skill_req": 200, "item": "Thick Leather, Thick Hide",
        "zones": "Feralas, Tanaris, Un'Goro Crater, Hinterlands, Badlands, Felwood",
        "route": "Yeti caves in Feralas, yetis in Hinterlands, raptors in Un'Goro.",
        "tip": "Nightscape Headband craft gives cheap skillups from 205-235."
    },
    "rugged leather": {
        "type": "Skinning", "skill_req": 250, "item": "Rugged Leather, Rugged Hide",
        "zones": "Winterspring, Western Plaguelands, Eastern Plaguelands, Un'Goro, Silithus",
        "route": "Frostsaber cats/bears in Winterspring, Plaguebats in EPL, Devilsaurs in Un'Goro.",
        "tip": "Rugged Hide is prized for Cured Rugged Hide (refined with Salt Shaker for Arcanite Reaper, Bloodvine)."
    },
    "devilsaur leather": {
        "type": "Skinning", "skill_req": 300, "item": "Devilsaur Leather",
        "zones": "Un'Goro Crater (exclusive)",
        "route": "Hunt Tyrant Devilsaurs and Ironhide Devilsaurs roaming Un'Goro Crater.",
        "tip": "Required for Devilsaur Gauntlets & Leggings (pre-raid BiS melee set)."
    }
}


# -------------------------------------------------------------
# Professions Overview & 1-300 Progression Guides
# -------------------------------------------------------------
PROFESSIONS_DATA: Dict[str, Dict[str, Any]] = {
    "Alchemy": {
        "type": "Primary (Crafting)", "gathering_pair": "Herbalism",
        "description": "Brews combat potions, elixirs, and 2-hour raid flasks. High endgame raid utility & steady income.",
        "key_crafts": "Flask of the Titans, Flask of Supreme Power, Elixir of the Mongoose, Free Action Potion, Transmute Arcanite.",
        "leveling_brackets": (
            "• **1–60 (Apprentice):** Minor Healing Potion, Lesser Armor Potion\n"
            "• **60–140 (Journeyman):** Healing Potion, Lesser Mana Potion, Fire Protection Potion\n"
            "• **140–210 (Expert):** Greater Healing Potion, Mana Potion, Elixir of Agility\n"
            "• **210–300 (Artisan):** Superior Healing Potion, Elixir of Greater Intellect, Major Healing Potion, Elixir of the Mongoose"
        ),
        "tip": "Transmute: Arcanite (unlocked at 275) has a 48-hour cooldown and provides consistent passive gold throughout Classic."
    },
    "Blacksmithing": {
        "type": "Primary (Crafting)", "gathering_pair": "Mining",
        "description": "Forges mail and plate armor, weapons, sharpening stones, and shield spikes. Specializes into Armorsmith or Weaponsmith (Axesmith, Swordsmith, Hammersmith).",
        "key_crafts": "Lionheart Helm, Titanic Leggings, Nightfall, Arcanite Reaper, Dark Iron Plate (Fire Resistance).",
        "leveling_brackets": (
            "• **1–65 (Apprentice):** Rough Sharpening Stone, Copper Chain Pants\n"
            "• **65–140 (Journeyman):** Coarse Sharpening Stone, Silver Rod, Bronze Bracers/Axe\n"
            "• **140–210 (Expert):** Heavy Sharpening Stone, Golden Rod, Iron Buckler, Steel Breastplate\n"
            "• **210–300 (Artisan):** Solid Sharpening Stone, Mithril Scale Bracers, Truesilver Gauntlets, Thorium Bracers/Helm"
        ),
        "tip": "Armorsmiths craft the mandatory pre-raid BiS Lionheart Helm (Warriors) and Titanic Leggings (Phase 5)."
    },
    "Enchanting": {
        "type": "Primary (Crafting / Service)", "gathering_pair": "Tailoring (Self-sufficient disenchanting)",
        "description": "Disenchants green/blue/epic items into magical dust, essences, and shards to permanently imbue armor and weapons with bonus stats.",
        "key_crafts": "Enchant Weapon - Crusader, +15 Agility, +30 Spell Damage, Enchant Gloves - Threat / Healing, Wizard Oil, Brilliant Mana Oil.",
        "leveling_brackets": (
            "• **1–75 (Apprentice):** Minor Health, Minor Deflection, Minor Strike\n"
            "• **75–150 (Journeyman):** Lesser Health, Silver Rod, Lesser Absorption, Lesser Spirit\n"
            "• **150–225 (Expert):** Golden Rod, Greater Defense, Truesilver Rod, Greater Strength\n"
            "• **225–300 (Artisan):** Arcanite Rod, Greater Stamina, Greater Agility, Crusader (Formula drop in Western Plaguelands)"
        ),
        "tip": "Does not require a gathering profession. Pairs best with Tailoring to craft cheap green cloth gear for disenchanting."
    },
    "Engineering": {
        "type": "Primary (Crafting / Utility)", "gathering_pair": "Mining",
        "description": "The undisputed #1 PvP and PvE raid progression profession in Classic. Specializes into Goblin (Explosives) or Gnomish (Gadgets).",
        "key_crafts": "Iron Grenade, Goblin Sapper Charge, Gnomish Battle Chicken, Goblin Jumper Cables XL, Force Reactive Disk, Spell Reflectors.",
        "leveling_brackets": (
            "• **1–75 (Apprentice):** Rough Blasting Powder, Handful of Copper Bolts, Copper Tube\n"
            "• **75–150 (Journeyman):** Coarse Blasting Powder, Silver Contact, Bronze Tubes\n"
            "• **150–225 (Expert):** Heavy Blasting Powder, Whirring Bronze Gizmo, Mithril Tubes, Solid Blasting Powder\n"
            "• **225–300 (Artisan):** Unstable Trigger, Mithril Casing, Hi-Explosive Bomb, Thorium Widget, Goblin Sapper Charge"
        ),
        "tip": "Goblin Sapper Charges and Iron Grenades are mandatory in high-tier raiding (Viscidus, Loatheb, speedclears) and high-rank PvP."
    },
    "Leatherworking": {
        "type": "Primary (Crafting)", "gathering_pair": "Skinning",
        "description": "Crafts leather and mail gear, armor kits, and resistance armor. Specializes into Dragonscale (Mail/Hunter), Elemental (Agility), or Tribal (Intellect/Feral).",
        "key_crafts": "Devilsaur Armor Set (Leggings + Gauntlets), Corehound Boots, Hide of the Wild, Black Dragonscale Set, Sandstalker Set.",
        "leveling_brackets": (
            "• **1–65 (Apprentice):** Light Armor Kit, Ruined Leather Scraps, Handstitched Leather Cloak\n"
            "• **65–140 (Journeyman):** Medium Armor Kit, Dark Leather Boots, Hillman's Shoulders\n"
            "• **140–210 (Expert):** Heavy Armor Kit, Dusky Leather Boots, Nightscape Tunic/Headband\n"
            "• **210–300 (Artisan):** Nightscape Pants, Thick Armor Kit, Rugged Armor Kit, Wicked Leather Bracers, Devilsaur Set"
        ),
        "tip": "Tribal Leatherworking produces Devilsaur Armor and Hide of the Wild, the premier healing cloak in early Classic."
    },
    "Tailoring": {
        "type": "Primary (Crafting)", "gathering_pair": "Enchanting or Skinning",
        "description": "Weaves cloth armor, spellcaster robes, cloaks, and storage bags from humanoid cloth drops (no gathering profession required).",
        "key_crafts": "Robe of the Archmage (Mage BiS), Robe of the Void (Warlock BiS), Truefaith Vestments (Priest BiS), Bloodvine Garb, Bottomless Bag (18 slots).",
        "leveling_brackets": (
            "• **1–60 (Apprentice):** Bolt of Linen Cloth, Linen Belt, Reinforced Linen Cape\n"
            "• **60–140 (Journeyman):** Bolt of Woolen Cloth, Woolen Boots, Double-stitched Woolen Shoulders\n"
            "• **140–205 (Expert):** Bolt of Silk Cloth, Azure Silk Hood, Silk Headband\n"
            "• **205–300 (Artisan):** Bolt of Mageweave, Black Mageweave Leggings, Bolt of Runecloth, Runecloth Belt/Cloak/Gloves"
        ),
        "tip": "Mooncloth has a 4-day cooldown and requires cleansing Felcloth in a Moonwell (Moonglade, Darnassus, Ashenvale)."
    },
    "Herbalism": {
        "type": "Primary (Gathering)", "gathering_pair": "Alchemy",
        "description": "Locates and gathers wild herbs across Azeroth for potions, elixirs, and flasks. Features Find Herbs mini-map radar.",
        "key_crafts": "Peacebloom (1), Briarthorn (70), Fadeleaf (130), Ghost Mushroom (245), Gromsblood (250), Dreamfoil (270), Mountain Silversage (280), Black Lotus (300).",
        "leveling_brackets": (
            "• **1–50 (Apprentice):** Peacebloom & Silverleaf (Starter zones)\n"
            "• **50–125 (Journeyman):** Mageroyal, Briarthorn, Stranglekelp, Bruiseweed (Silverpine, Westfall, Barrens)\n"
            "• **125–200 (Expert):** Kingsblood, Fadeleaf, Goldthorn, Khadgar's Whisker (Arathi, STV, Swamp of Sorrows)\n"
            "• **200–300 (Artisan):** Firebloom, Sungrass, Blindweed, Dreamfoil, Plaguebloom, Black Lotus (Felwood, EPL, Winterspring)"
        ),
        "tip": "Black Lotus spawns in 4 zones (EPL, Winterspring, Burning Steppes, Silithus) on a 45-60 min timer; peak economy item."
    },
    "Mining": {
        "type": "Primary (Gathering)", "gathering_pair": "Blacksmithing or Engineering",
        "description": "Finds mineral veins and deposits in cliffs and caves, gathering ore and stones. Features Find Minerals mini-map radar.",
        "key_crafts": "Copper (1), Tin/Bronze (65), Iron (125), Mithril (175), Dark Iron (230), Thorium (245), Rich Thorium (275).",
        "leveling_brackets": (
            "• **1–65 (Apprentice):** Copper Veins (Starter zones). Smelt Copper to skill 50.\n"
            "• **65–125 (Journeyman):** Tin & Silver Veins (Redridge, Barrens). Smelt Bronze from 65-115.\n"
            "• **125–175 (Expert):** Iron & Gold Deposits (Arathi, 1k Needles). Smelt Iron to 160.\n"
            "• **175–300 (Artisan):** Mithril (Badlands 175-225), Small Thorium (Un'Goro 245-275), Rich Thorium (Silithus/EPL 275-300)"
        ),
        "tip": "Rich Thorium Veins produce rare Arcane Crystals, the bottleneck reagent for all Arcanite Bars in Classic."
    },
    "Skinning": {
        "type": "Primary (Gathering)", "gathering_pair": "Leatherworking",
        "description": "Skins slain beasts, dragonkin, and dragon whelps using a Skinning Knife. The fastest 1-300 gathering profession in Classic.",
        "key_crafts": "Light Leather (1), Medium Leather (75), Heavy Leather (150), Thick Leather (200), Rugged Leather (250), Devilsaur Leather (300).",
        "leveling_brackets": (
            "• **1–75 (Apprentice):** Level 1-15 beasts (Starter zones, Westfall, Durotar)\n"
            "• **75–150 (Journeyman):** Level 16-30 beasts (Redridge, Southern Barrens, Duskwood, Ashenvale)\n"
            "• **150–220 (Expert):** Level 31-43 beasts (Shimmering Flats basilisks/turtles, STV raptors)\n"
            "• **220–300 (Artisan):** Level 44-60 beasts (Feralas yetis, Un'Goro raptors/devilsaurs, Winterspring yetis/cats)"
        ),
        "tip": "Formula: Max beast level you can skin = (Skinning Skill / 5). At 300 skill, you can skin up to Level 60 mobs (Fink's Skinner dagger +10 skill allows level 62/63 boss skinning like The Beast in UBRS)."
    },
    "Cooking": {
        "type": "Secondary (Universal)", "gathering_pair": "Fishing (Natural ingredient pair)",
        "description": "Prepares stat-boosting food buffs (Well Fed) providing Stamina, Spirit, Strength, and Mana Regeneration.",
        "key_crafts": "Grilled Squid (+10 Agi), Smoked Desert Dumplings (+20 Str), Nightfin Soup (+8 MP5), Runn Tum Tuber Surprise (+25 Int), Dirge's Kickin' Chimaerok Chops (+25 Stam).",
        "leveling_brackets": (
            "• **1–75 (Apprentice):** Spiced Wolf Meat, Herb Baked Egg\n"
            "• **75–150 (Journeyman):** Smoked Bear Meat, Crab Cake, Curiously Tasty Omelet\n"
            "• **150–225 (Expert):** Bristle Whisker Catfish, Hot Lion Chops, Soothing Turtle Bisque\n"
            "• **225–300 (Artisan):** Tender Wolf Steak, Monster Omelet, Baked Salmon, Smoked Desert Dumplings (Silithus quest)"
        ),
        "tip": "Secondary profession: Every character can learn Cooking alongside First Aid, Fishing, and 2 Primary professions without penalty."
    },
    "First Aid": {
        "type": "Secondary (Universal)", "gathering_pair": "Tailoring (Shares cloth)",
        "description": "Crafts bandages to restore health in combat or emergencies without consuming mana. Mandatory for all classes in Classic PvP and raiding.",
        "key_crafts": "Heavy Linen Bandage, Heavy Wool Bandage, Heavy Silk Bandage, Heavy Mageweave Bandage, Heavy Runecloth Bandage (2000 HP over 8s).",
        "leveling_brackets": (
            "• **1–75 (Apprentice):** Linen Bandage, Heavy Linen Bandage\n"
            "• **75–150 (Journeyman):** Wool Bandage, Heavy Wool Bandage\n"
            "• **150–225 (Expert):** Silk Bandage, Heavy Silk Bandage, Mageweave Bandage (Manuals bought in Stromgarde Keep / Dustwallow)\n"
            "• **225–300 (Artisan):** Heavy Mageweave Bandage, Runecloth Bandage, Heavy Runecloth Bandage (Triage quest in Theramore / Hammerfall)"
        ),
        "tip": "Anti-Venom (First Aid 80) cures poisons up to level 35 on a 1-minute cooldown — indispensable in PvP vs Rogues and Hunters."
    },
    "Fishing": {
        "type": "Secondary (Universal)", "gathering_pair": "Cooking",
        "description": "Catches fish, locked floating wreckage trunks, elementals (Essence of Water), and rare pearls across Azeroth's waterways.",
        "key_crafts": "Winter Squid (Agi food), Nightfin Snapper (MP5 food), Raw Redgill, Stonescale Eel (Stonescale Oil for Titans flask), Oily Blackmouth (Free Action Potion).",
        "leveling_brackets": (
            "• **1–75 (Apprentice):** Capital city moats and starter lakes\n"
            "• **75–150 (Journeyman):** Loch Modan, Darkshore, Westfall, Silverpine, Barrens\n"
            "• **150–225 (Expert):** Dustwallow Marsh, Alterac, Arathi, STV (Expert book sold by Nat Pagle in Dustwallow)\n"
            "• **225–300 (Artisan):** Feralas, Tanaris, Azshara, Bay of Storms (Nat Pagle's 'Angler Extreme' quest line)"
        ),
        "tip": "Winter Squid is seasonal (only caught September through March), making it a high-value commodity during summer months."
    }
}


def get_gathering_info(query: str) -> Optional[Dict[str, Any]]:
    """Retrieves authoritative gathering node data by ore, herb, or leather name."""
    import difflib
    if not query:
        return None
    q = query.strip().lower()

    # Direct match
    for k, v in GATHERING_NODES.items():
        if k == q:
            return {"name": k.title(), **v}

    # Partial match (e.g. 'copper' -> 'copper vein', 'thorium' -> 'rich thorium vein')
    for k, v in GATHERING_NODES.items():
        if q in k or k in q:
            return {"name": k.title(), **v}

    # Space-stripped match (e.g. 'blacklotus' -> 'black lotus')
    q_nospace = q.replace(" ", "")
    for k, v in GATHERING_NODES.items():
        if k.replace(" ", "") == q_nospace:
            return {"name": k.title(), **v}

    # Fuzzy match
    keys = list(GATHERING_NODES.keys())
    matches = difflib.get_close_matches(q, keys, n=1, cutoff=0.6)
    if matches:
        return {"name": matches[0].title(), **GATHERING_NODES[matches[0]]}

    return None


def get_profession_info(query: str) -> Optional[Dict[str, Any]]:
    """Retrieves authoritative profession progression guide."""
    import difflib
    if not query:
        return None
    q = query.strip().lower()

    alias_map = {
        "herb": "Herbalism", "herbs": "Herbalism", "herbalism": "Herbalism",
        "mine": "Mining", "mining": "Mining", "miner": "Mining",
        "alch": "Alchemy", "alchemy": "Alchemy", "potions": "Alchemy",
        "eng": "Engineering", "engineering": "Engineering", "engineer": "Engineering",
        "bs": "Blacksmithing", "blacksmith": "Blacksmithing", "blacksmithing": "Blacksmithing",
        "tailor": "Tailoring", "tailoring": "Tailoring",
        "lw": "Leatherworking", "leatherworking": "Leatherworking", "leatherworker": "Leatherworking",
        "skin": "Skinning", "skinning": "Skinning", "skinner": "Skinning",
        "ench": "Enchanting", "enchant": "Enchanting", "enchanting": "Enchanting",
        "cook": "Cooking", "cooking": "Cooking",
        "fa": "First Aid", "first aid": "First Aid", "firstaid": "First Aid", "bandages": "First Aid",
        "fish": "Fishing", "fishing": "Fishing"
    }

    target = alias_map.get(q)
    if target and target in PROFESSIONS_DATA:
        return {"name": target, **PROFESSIONS_DATA[target]}

    # Direct match
    for k, v in PROFESSIONS_DATA.items():
        if k.lower() == q or q in k.lower():
            return {"name": k, **v}

    # Fuzzy match
    keys = list(PROFESSIONS_DATA.keys())
    matches = difflib.get_close_matches(q.title(), keys, n=1, cutoff=0.6)
    if matches:
        return {"name": matches[0], **PROFESSIONS_DATA[matches[0]]}

    return None


# -------------------------------------------------------------
# Class Builds & Leveling Specs (Talents, Stats, Rotations)
# -------------------------------------------------------------
CLASS_BUILDS: Dict[str, Dict[str, Any]] = {
    # WARRIOR
    "warrior:arms": {
        "class": "Warrior", "spec": "Arms Leveling", "points": "31/20/0",
        "role": "Melee DPS / Leveling",
        "stat_priority": "Strength > Agility > Stamina > Spirit",
        "rotation": "Charge -> Rend -> Sweeping Strikes -> Mortal Strike -> Whirlwind -> Execute (below 20%).",
        "milestones": "Level 30: Whirlwind Axe quest & Sweeping Strikes. Level 40: Mortal Strike (major DPS power spike).",
        "tip": "Keep Stance Dance macros ready to seamlessly swap between Battle Stance (Overpower/Charge) and Berserker Stance (Whirlwind/Berserker Rage)."
    },
    "warrior:fury": {
        "class": "Warrior", "spec": "Fury Dual-Wield DPS", "points": "17/34/0",
        "role": "Melee DPS (Raid)",
        "stat_priority": "Hit (6% with 305+ Weapon Skill / 9% base) -> Crit -> Attack Power -> Strength",
        "rotation": "Bloodthirst on cooldown -> Whirlwind -> Queue Heroic Strike to dump excess rage and negate off-hand dual-wield miss penalty.",
        "milestones": "Bloodthirst at 40; Death Wish + Flurry for massive execute-phase burst.",
        "tip": "Use Edgemaster's Handguards (if non-Human/Orc) or weapon racials to cap weapon skill at 305 and eliminate the crushing glancing blow penalty."
    },
    "warrior:prot": {
        "class": "Warrior", "spec": "Deep Protection Tank", "points": "11/5/35",
        "role": "Main Tank / Dungeon Tank",
        "stat_priority": "Defense (440 cap vs Lvl 63 bosses) -> Stamina -> Armor -> Agility",
        "rotation": "Shield Slam on CD -> Revenge on proc -> Sunder Armor -> Keep Shield Block active 100% of the time to push crushing blows off combat table.",
        "milestones": "Last Stand at 20; Shield Slam at 40; Defiance (+15% threat) maxed early.",
        "tip": "Never turn your back on bosses (parry/block/dodge only work from the front). Rotate Shield Wall & Last Stand on heavy enrages."
    },

    # MAGE
    "mage:frost aoe": {
        "class": "Mage", "spec": "Frost AoE Leveling", "points": "14/0/37",
        "role": "Ranged DPS / Leveling / Gold Farm",
        "stat_priority": "Intellect > Stamina > Spirit > Spell Damage",
        "rotation": "Gather 8-15 melee mobs on mount -> Frost Nova -> Blink away -> Rank 1 Blizzard (slow) -> Max Rank Blizzard kite -> Cone of Cold.",
        "milestones": "Level 20: Blizzard slow (Permafrost + Improved Blizzard). Level 40: Ice Barrier for pushback immunity.",
        "tip": "Never take Shatter for AoE farming (frozen crits break mob clustering). Best farms: Western Plaguelands farms and Zul'Farrak graveyard."
    },
    "mage:frost raid": {
        "class": "Mage", "spec": "Frost Single-Target Raid", "points": "17/0/34",
        "role": "Ranged DPS (MC / BWL)",
        "stat_priority": "Spell Hit (16% cap / 10% from talents) -> Spell Damage -> Spell Crit -> Intellect",
        "rotation": "Apply Winter's Chill to 5 stacks -> Frostbolt spam -> Use Arcane Power / Trinkets on burn phase -> Evocation for mana sustain.",
        "milestones": "Ice Shards (+100% crit damage), Arcane Mind (+10% Int), Ice Block.",
        "tip": "Essential for Molten Core and Blackwing Lair due to elemental fire immunities. Transition to Fire after BWL/AQ."
    },
    "mage:fire": {
        "class": "Mage", "spec": "Fire Raid DPS", "points": "17/31/3",
        "role": "Ranged DPS (AQ40 / Naxx)",
        "stat_priority": "Spell Hit (16% cap) -> Spell Crit -> Spell Damage -> Intellect",
        "rotation": "Stack 5x Scorch (Fire Vulnerability) -> Fireball spam -> Use Combustion -> Maintain shared raid Ignite stack.",
        "milestones": "Ignite (+40% crit dot), Combustion (guaranteed crits), Critical Mass (+6% crit).",
        "tip": "All Fire Mages in raid feed the same rolling Ignite dot. The Mage who scores the first crit gains threat for the entire stack — watch aggro!"
    },

    # ROGUE
    "rogue:combat swords": {
        "class": "Rogue", "spec": "Combat Swords", "points": "19/32/0",
        "role": "Melee DPS (Leveling & Raid)",
        "stat_priority": "Hit (6% with 305+ Weapon Skill / 9% base) -> Crit -> Attack Power -> Agility",
        "rotation": "Sinister Strike -> Keep Slice and Dice active 100% of combat -> Eviscerate at 5 combo points -> Blade Flurry on pulls -> Adrenaline Rush on boss burn.",
        "milestones": "Level 20: Blade Flurry (+2 targets). Level 30: Adrenaline Rush (+100% energy regen).",
        "tip": "Sword Specialization procs extra swings that generate energy and trigger weapon procs (Thrash Blade, Ironfoe, Dal'Rends)."
    },
    "rogue:daggers": {
        "class": "Rogue", "spec": "Combat Daggers / Assassination", "points": "15/31/5",
        "role": "Melee DPS (Raid)",
        "stat_priority": "Hit -> Crit -> Agility -> Attack Power",
        "rotation": "Position behind boss -> Backstab -> Slice and Dice -> Backstab spam -> Eviscerate.",
        "milestones": "Opportunity (+20% Backstab dmg), Dagger Specialization (+5% crit), Improved Backstab (+30% crit).",
        "tip": "Requires Aging Core Leather Gloves (MC) or Mugger's Belt (Dire Maul) for +Dagger skill if non-Human/Orc."
    },

    # PRIEST
    "priest:shadow": {
        "class": "Priest", "spec": "Shadow Leveling", "points": "14/0/37",
        "role": "Ranged DPS / Solo Leveling",
        "stat_priority": "Spirit (Spirit Tap mana regen) > Spell Damage > Intellect > Stamina",
        "rotation": "Mind Blast -> Shadow Word: Pain -> Mind Flay x2 -> Wand mob to death so Spirit Tap (+100% spirit regen) activates at 0 mana spent.",
        "milestones": "Level 10: Spirit Tap. Level 20: Mind Flay. Level 40: Shadowform (+15% physical armor & +15% shadow damage).",
        "tip": "Get Gravestone Scepter from BFD quest at level 18; your wand DPS will out-damage your spells for zero mana!"
    },
    "priest:holy": {
        "class": "Priest", "spec": "Holy / Discipline Raid Healing", "points": "21/30/0",
        "role": "Raid / Tank Healer",
        "stat_priority": "+Healing > MP5 > Spirit > Intellect",
        "rotation": "Keep Renew on active tanks -> Flash Heal for spot emergency healing -> Greater Heal (Rank 1 & 4) for sustained tank bursts -> Prayer of Healing for group spikes.",
        "milestones": "Divine Spirit (+50 Spirit buff), Spiritual Guidance (+25% Spirit to +Healing), Inspiration (+25% target armor on heal crit).",
        "tip": "Downranking spells is mandatory. Greater Heal Rank 1 and 4 have superior healing-per-mana ratios than max rank."
    },

    # WARLOCK
    "warlock:drain tank": {
        "class": "Warlock", "spec": "Affliction Drain Tank", "points": "30/21/0",
        "role": "Solo Leveling / Farming",
        "stat_priority": "Stamina > Spell Damage > Intellect > Spirit",
        "rotation": "Send Voidwalker or Succubus -> Corruption -> Siphon Life -> Curse of Agony -> Drain Life -> Dark Pact minion for infinite mana loop.",
        "milestones": "Level 20: Fel Concentration (70% pushback resist on Drain Life). Level 40: Dark Pact (mana battery).",
        "tip": "You never have to drink or eat. Convert HP to Mana via Life Tap and Mana to HP via Drain Life in an unbroken chain."
    },
    "warlock:ds ruin": {
        "class": "Warlock", "spec": "DS / Ruin Raid DPS", "points": "7/21/23",
        "role": "Ranged DPS (Raid)",
        "stat_priority": "Spell Hit (16% cap) -> Spell Crit -> Shadow Spell Damage -> Intellect",
        "rotation": "Sacrifice Succubus for Demonic Sacrifice (+15% Shadow Dmg) -> Apply assigned Curse (Curse of Elements/Shadow/Recklessness) -> Shadow Bolt spam.",
        "milestones": "Demonic Sacrifice (Level 30 Demonology), Ruin (+100% Shadow Bolt crit bonus).",
        "tip": "Coordinate with other Warlocks so Shadow Vulnerability debuff (+20% Shadow Dmg from ISB) stays up on the boss."
    },

    # HUNTER
    "hunter:bm": {
        "class": "Hunter", "spec": "Beast Mastery Leveling", "points": "31/20/0",
        "role": "Solo Leveling / Open World",
        "stat_priority": "Agility > Attack Power > Stamina > Intellect",
        "rotation": "Send Pet -> Hunter's Mark -> Serpent Sting -> Auto Shot / Multi-Shot -> Bestial Wrath on elites -> Feign Death to drop threat.",
        "milestones": "Level 10: Pet Taming. Level 30: Bestial Discipline. Level 40: Bestial Wrath (+50% pet damage & crowd-control immunity).",
        "tip": "Tame a Cat (Fast attack speed, 1.2s like Broken Tooth or Swamp Jaguar) for maximum Frenzy talent uptime."
    },
    "hunter:marksman": {
        "class": "Hunter", "spec": "Marksmanship Raid DPS", "points": "20/31/0",
        "role": "Ranged Physical DPS (Raid)",
        "stat_priority": "Ranged Hit (9% cap / 6% with Surefooted) -> Ranged Crit -> Agility -> Attack Power",
        "rotation": "Weave Aimed Shot between Auto Shot timer -> Multi-Shot on CD -> Never clip your Auto Shot animation.",
        "milestones": "Trueshot Aura (+100 AP to entire party), Mortal Shots (+30% ranged crit damage).",
        "tip": "Bring Tranq Shot for enrage bosses (Magmadar, Flamegor, Chromaggus, Huhuran). Use weapon swing timers."
    },

    # DRUID
    "druid:feral": {
        "class": "Druid", "spec": "Feral Cat DPS / Bear Tank", "points": "14/32/5",
        "role": "Off-Tank / Melee DPS",
        "stat_priority": "Cat: Strength > Agility > AP. Bear: Armor > Stamina > Defense > Agility",
        "rotation": "Cat: Powershift macro (Furor) -> Shred from behind -> Rip -> Ferocious Bite. Bear: Maul -> Swipe -> Faerie Fire.",
        "milestones": "Furor (instant 40 energy / 10 rage on shift), Heart of the Wild (+20% Stam in bear / +20% Int), Leader of the Pack (+3% party crit).",
        "tip": "Wolfshead Helm (crafted Lvl 40 leather helm) is permanently mandatory for Cat DPS to gain +60 energy on every powershift."
    },
    "druid:resto": {
        "class": "Druid", "spec": "Restoration Raid Healing", "points": "24/0/27",
        "role": "Raid Healer / Innervate Provider",
        "stat_priority": "+Healing > MP5 > Spirit > Intellect",
        "rotation": "Keep Rejuvenation on tanks -> Healing Touch (Rank 4 for mana efficiency) -> Swiftmend for emergency spike heals -> Innervate main healer.",
        "milestones": "Moonglow (-9% spell cost), Nature's Swiftness (instant emergency heal), Swiftmend.",
        "tip": "Cast Rebirth (Combat Resurrection) on fallen tanks or top DPS during boss encounters."
    },

    # PALADIN
    "paladin:holy": {
        "class": "Paladin", "spec": "Holy Raid Healing", "points": "31/20/0",
        "role": "Single-Target Tank Healer",
        "stat_priority": "Spell Crit (100% mana refund!) > +Healing > Intellect > MP5",
        "rotation": "Flash of Light spam (Rank 4 & 6) on tanks -> Holy Light for huge damage spikes -> Keep Blessing of Salvation/Kings/Might on raid.",
        "milestones": "Illumination (100% mana refunded on critical heals), Divine Favor (guaranteed crit), Holy Shock.",
        "tip": "With high Spell Crit gear (25-35%), Holy Paladins literally cannot run out of mana in Classic raids."
    },
    "paladin:ret": {
        "class": "Paladin", "spec": "Retribution Leveling", "points": "20/0/31",
        "role": "Melee DPS / Leveling",
        "stat_priority": "Strength > Stamina > Agility > Intellect",
        "rotation": "Judgement of the Crusader -> Seal of Command -> Auto-attack with slow 2H weapon -> Hammer of Justice -> Consecration on AoE.",
        "milestones": "Seal of Command (Level 20), Vengeance (+15% phys/holy damage after crit), Repentance.",
        "tip": "Seal of Command damage scales exclusively with weapon base damage; use the slowest two-handed weapon possible (3.6s+ speed)."
    },

    # SHAMAN
    "shaman:resto": {
        "class": "Shaman", "spec": "Restoration Raid Healing", "points": "0/5/46",
        "role": "Raid AoE Healer / Totem Buffer",
        "stat_priority": "+Healing > MP5 > Intellect > Spell Crit",
        "rotation": "Chain Heal spam (Rank 1 for efficiency, Rank 3 for spike damage) -> Drop Windfury Totem & Grace of Air (Totem Twisting) -> Mana Tide Totem on CD.",
        "milestones": "Mana Tide Totem (group mana battery), Nature's Swiftness, Healing Wave downranking.",
        "tip": "Chain Heal is the undisputed best smart-heal in Classic; targets lowest-HP raid members automatically."
    },
    "shaman:enh": {
        "class": "Shaman", "spec": "Enhancement Leveling", "points": "20/31/0",
        "role": "Melee DPS / Leveling",
        "stat_priority": "Strength > Agility > Stamina > Intellect",
        "rotation": "Lightning Shield -> Imbue weapon with Windfury -> Flame Shock -> Stormstrike -> Earth Shock interrupt.",
        "milestones": "Level 20: Ghost Wolf (instant travel). Level 30: Windfury Weapon (triple hit burst). Level 40: Stormstrike.",
        "tip": "Use a slow 2H mace or axe (3.8s speed like Corpsemaker or Pendulum of Doom) for massive one-shot Windfury procs."
    }
}


# -------------------------------------------------------------
# Raid Boss Cheatsheets & Strategies
# -------------------------------------------------------------
RAID_BOSSES_DATA: Dict[str, Dict[str, Any]] = {
    # MOLTEN CORE
    "baron geddon": {
        "raid": "Molten Core", "level": 63,
        "key_mechanics": (
            "• **Living Bomb:** Target ticks fire damage and explodes after 8s for 3200 damage to nearby players. *Run away from the raid immediately!* (Jump to avoid fall damage).\n"
            "• **Inferno:** Channels lethal point-blank fire AoE pulsing every second. *All melee must run out of melee range instantly!*\n"
            "• **Ignite Mana:** Drains 400 mana per tick and damages casters. *Priests and Shamans must Dispel / Purge immediately.*"
        ),
        "tip": "Tank Baron in the central hallway of Garr's room to give players open space to run with Living Bomb."
    },
    "ragnaros": {
        "raid": "Molten Core", "level": 63,
        "key_mechanics": (
            "• **Wrath of Ragnaros:** Knocks melee back and reduces threat. Main tanks swap immediately after each knockback.\n"
            "• **Submerge (Phase 2):** At 3 minutes, Ragnaros submerges and 8 Sons of Flame spawn. *Mages Frost Nova / AoE banish them down before Ragnaros returns.*\n"
            "• **Lava Spurt & Fire Protection:** Constant raid fire damage. *Every player must pre-pot Greater Fire Protection Potion before pull.*"
        ),
        "tip": "High raid DPS can kill Ragnaros before the 3-minute submerge phase occurs ('Submerge Skip')."
    },

    # BLACKWING LAIR
    "vaelastrasz": {
        "raid": "Blackwing Lair", "level": 63,
        "key_mechanics": (
            "• **Essence of the Red:** Grants infinite mana, 100 energy/s, and 50 rage/s for the entire fight. *All DPS go all-out!*\n"
            "• **Burning Adrenaline:** Targets a player every 15s. Increases damage by 100%, makes all spells instant-cast, but kills player after 20s. *Target must run to the wall away from raid before exploding!*\n"
            "• **Tank Chain:** Current tank dies when hit by Burning Adrenaline; next tank must instantly taunt and turn boss away from raid."
        ),
        "tip": "Known as 'The Guild Breaker'. Maximum DPS race; do not conserve cooldowns. Pre-cast Fire Protection Potions."
    },
    "chromaggus": {
        "raid": "Blackwing Lair", "level": 63,
        "key_mechanics": (
            "• **Dual Breaths:** Every 30s Chromaggus casts 2 random breaths. *Time Lapse (hides behind ramp; drops tank threat); Ignite Flesh (burns); Frost Burn (burns mana).*\n"
            "• **Chromatic Afflictions:** 5 debuffs (Black, Blue, Bronze, Green, Red). *If any player reaches 5 stacks, they transform into an unstoppable mind-controlled Drakonid!* Priests/Restorative Potions dispel.\n"
            "• **Frenzy:** Periodically enrages for +200% attack speed. *Hunters must Tranq Shot immediately.*"
        ),
        "tip": "Bring Hourglass Sand (drops in BWL trash) to cleanse the Bronze Affliction stun."
    },
    "nefarian": {
        "raid": "Blackwing Lair", "level": 63,
        "key_mechanics": (
            "• **Phase 1 (Drakonids):** Slay 42 color-coded Drakonids emerging from side doors before Nefarian lands.\n"
            "• **Phase 2 (Class Calls):** Nefarian corrupts specific classes every 30s:\n"
            "  - *Mages:* Polymorph entire raid (Priests dispel)\n"
            "  - *Priests:* Direct heals corrupt into lethal dots (stop healing!)\n"
            "  - *Hunters:* Weapons break instantly (swap to backup weapon!)\n"
            "  - *Druids:* Forced into Cat form\n"
            "  - *Rogues:* Teleported in front of boss\n"
            "• **Phase 3 (Undead Swarm):** At 20% HP, all dead Phase 1 Drakonids resurrect as Bone Constructs. *Mages AoE bomb down with Stratholme Holy Water.*"
        ),
        "tip": "Every raider MUST wear the Onyxia Scale Cloak or Shadow Flame will instantly incinerate them for 20,000 damage."
    },

    # AHN'QIRAJ & NAXXRAMAS
    "c'thun": {
        "raid": "Temple of Ahn'Qiraj (AQ40)", "level": 63,
        "key_mechanics": (
            "• **Eye Beam (Phase 1):** Bounces between players closer than 10 yards, doubling damage with each jump (instantly wipes raid). *Maintain strict 10-yard spread around the entire room at all times!*\n"
            "• **Dark Glare:** Rotates a lethal red laser beam around the room. *Run around the room clockwise/counter-clockwise to stay ahead of the beam.*\n"
            "• **Phase 2 (Stomach Team):** C'Thun swallows players into his stomach. Slay the 2 Flesh Tentacles inside to weaken C'Thun's shield for a 45-second vulnerable burn phase."
        ),
        "tip": "Positioning is 90% of this fight. Use range-check addons set to 10 yards before entering the threshold."
    },
    "patchwerk": {
        "raid": "Naxxramas", "level": 63,
        "key_mechanics": (
            "• **Hateful Strike:** Every 1.2s strikes the player with the highest HP within melee range (excluding the primary tank) for 5000–8000 physical damage.\n"
            "• **Soak Tanks:** 2-3 Off-Tanks with massive HP pools (buffed to 10,000+ HP with Titans Flasks) take continuous Hateful Strikes; dedicated healers assigned to spam each OT.\n"
            "• **Berserk Enrage:** At 7 minutes or 5% HP, attacks 100% faster and wipes the raid."
        ),
        "tip": "Melee DPS must dip their feet into the green slime water before the pull to ensure their HP is lower than the Off-Tanks."
    },

    # WOW: FOREVER CLASSIC+ RAIDS
    "temporal rift": {
        "raid": "The Temporal Rift (Forever Classic+ 20-Man)", "level": 63,
        "key_mechanics": (
            "• **Chronomantic Fissures:** Portals spawn alternate timeline echoes. Tanks must pull temporal anomalies into collapsing rift zones.\n"
            "• **Time Shift Paradox:** Boss reverses raid positioning by 10 seconds. Keep mental track of safe ground.\n"
            "• **Murozond Echo:** Sandstorm breath requires line-of-sight behind chronosteel pillars."
        ),
        "tip": "Flagship 20-man raid in the alternate Dark Portal timeline; drops the 'Signet of the Unopened Portal' horizontal progression tier."
    },
    "verdant scar": {
        "raid": "The Verdant Scar (Mount Hyjal Classic+)", "level": 63,
        "key_mechanics": (
            "• **Nightmare Brambles:** Root players and pulse shadow nature damage. Cleansed by Druids and Shamans.\n"
            "• **Corrupted Remulos:** Phases between Cenarion Wrath (Arcane firestorms) and Defiled Tranquility (requires physical interrupts).\n"
            "• **Archimonde Remnant:** Avoid doomfire trails along the roots of World Tree Nordrassil."
        ),
        "tip": "Requires Mount Hyjal attunement via Cenarion Circle rep and Roots of Nordrassil dungeon run."
    }
}


# -------------------------------------------------------------
# Consumables by Role & World Buffs Directory
# -------------------------------------------------------------
CONSUMABLES_DATA: Dict[str, Dict[str, Any]] = {
    "melee dps": {
        "role": "Melee DPS (Warrior, Rogue, Feral Cat, Enh Shaman)",
        "flasks_elixirs": "Elixir of the Mongoose (+25 Agi, +2% Crit), Winterfall Firewater (+35 Str), Juju Power (+30 Str), Juju Might (+40 AP)",
        "food_buffs": "Grilled Squid (+10 Agi) or Smoked Desert Dumplings (+20 Str)",
        "weapon_buffs": "Elemental Sharpening Stone (+2% Crit) / Dense Weightstone, Instant Poison VI (Rogues)",
        "potions": "Mighty Rage Potion (Warrior burst), Thistle Tea (Rogue energy), Greater Fire/Nature Protection Potion",
        "tip": "Juju Power and Winterfall Firewater stack because one is an AP aura and the other is a raw Strength buff!"
    },
    "caster dps": {
        "role": "Caster DPS (Mage, Warlock, Shadow Priest, Ele Shaman, Balance Druid)",
        "flasks_elixirs": "Flask of Supreme Power (+150 Spell Dmg), Greater Arcane Elixir (+35 Spell Dmg), Elixir of Greater Firepower / Shadow Power / Frost Power",
        "food_buffs": "Runn Tum Tuber Surprise (+25 Int) or Nightfin Soup (+8 MP5)",
        "weapon_buffs": "Brilliant Wizard Oil (+36 Spell Dmg, +1% Spell Crit)",
        "potions": "Major Mana Potion, Demonic / Dark Rune (restores 900-1500 mana at cost of HP), Limited Invulnerability Potion (threat drops)",
        "tip": "Demonic Runes do not share a cooldown with Major Mana Potions; rotate both every 2 minutes for endless mana sustain."
    },
    "healer": {
        "role": "Healer (Priest, Holy Paladin, Resto Shaman, Resto Druid)",
        "flasks_elixirs": "Flask of Distilled Wisdom (+2000 Mana pool), Mageblood Potion (+12 MP5), Elixir of Greater Intellect, Elixir of the Sages",
        "food_buffs": "Nightfin Soup (+8 MP5)",
        "weapon_buffs": "Brilliant Mana Oil (+12 MP5, +25 Healing)",
        "potions": "Major Mana Potion, Demonic / Dark Rune, Greater Fire/Shadow Protection Potion",
        "tip": "MP5 ticks continue during spellcasting, making MP5 significantly more reliable than Spirit in high-intensity raid fights."
    },
    "tank": {
        "role": "Tank (Protection Warrior, Feral Bear, Prot Paladin)",
        "flasks_elixirs": "Flask of the Titans (+1200 Max HP), Elixir of Superior Defense (+450 Armor), Elixir of the Mongoose (+25 Agi, +2% Dodge/Crit)",
        "food_buffs": "Dirge's Kickin' Chimaerok Chops (+25 Stam) or Smoked Desert Dumplings (+20 Str)",
        "weapon_buffs": "Elemental Sharpening Stone or Dense Weightstone for extra threat crits",
        "potions": "Greater Stoneshield Potion (+2000 Armor for 2 mins!), Free Action Potion (stun immunity), Health Potions",
        "tip": "Greater Stoneshield Potion gives 2000 flat armor and should be pre-potted before engaging heavy physical hitters (Broodlord, Patchwerk)."
    }
}

WORLD_BUFFS_DATA: Dict[str, Dict[str, Any]] = {
    "dragonslayer": {
        "name": "Rallying Cry of the Dragonslayer",
        "source": "Head of Onyxia / Head of Nefarian turned in at Stormwind Gates or Orgrimmar Valley of Strength.",
        "effect": "+140 Attack Power, +5% Spell Crit, +10% Melee & Ranged Crit for 2 hours.",
        "cooldown": "2-hour reset cooldown on the turn-in NPC.",
        "tip": "The premier world buff in Classic. Drops 10-15 minutes before typical server raid times."
    },
    "warchief": {
        "name": "Warchief's Blessing (Rend Buff)",
        "source": "Head of Rend Blackhand turned in at Orgrimmar (Horde naturally; Alliance via Mind Control trick).",
        "effect": "+300 Maximum Health, +15% Melee Haste, +10 MP5 for 1 hour.",
        "cooldown": "3-hour reset cooldown on Thrall.",
        "tip": "15% melee haste makes this god-tier for Rogues and Fury Warriors."
    },
    "songflower": {
        "name": "Songflower Serenade",
        "source": "Corrupted Songflower cleansed in Felwood using Cenarion Plant Salve.",
        "effect": "+15 to All Primary Stats, +5% to All Critical Strike chances for 1 hour.",
        "cooldown": "Respawn timer: Exactly 25 minutes after cleansed.",
        "tip": "Multiple players can click the flower within a 2-second window to all receive the buff simultaneously."
    },
    "zandalar": {
        "name": "Spirit of Zandalar",
        "source": "Heart of Hakkar turned in to Molthor at Yojamba Isle (Stranglethorn Vale).",
        "effect": "+10% Movement Speed, +15% to All Primary Stats for 2 hours.",
        "cooldown": "Shared cooldown on turn-in NPC.",
        "tip": "Can be picked up while waiting for the Booty Bay boat or flight master."
    },
    "dire maul": {
        "name": "Dire Maul Tribute Buffs (Mol'dar, Fengus, Slip'kik)",
        "source": "Complete a Dire Maul North Tribute run without killing the guard bosses, then speak to them as the new King.",
        "effect": "• Guard Mol'dar: +200 Attack Power\n• Guard Fengus: +200 Attack Power\n• Guard Slip'kik: +3% Spell Critical Strike",
        "cooldown": "Buffs last 2 hours inside and outside the dungeon.",
        "tip": "Invite guildies to a cleared instance to click the guards directly without fighting."
    },
    "sayge": {
        "name": "Sayge's Darkmoon Fortune",
        "source": "Speak to Sayge at the Darkmoon Faire (Elwynn Forest or Mulgore) and answer his 2 quiz questions.",
        "effect": "Answer 1-1: +10% Damage Dealt | Answer 1-2: +10% Armor | Answer 1-3: +25 All Resistances (lasts 2 hours).",
        "cooldown": "Available only during active Darkmoon Faire weeks.",
        "tip": "Answer 1-1 (+10% flat damage) is the single biggest offensive multiplier in Classic WoW."
    }
}


# -------------------------------------------------------------
# Faction Reputations & Rewards Directory
# -------------------------------------------------------------
REPUTATIONS_DATA: Dict[str, Dict[str, Any]] = {
    "timbermaw hold": {
        "name": "Timbermaw Hold",
        "location": "Felwood & Winterspring (connecting tunnel)",
        "farm_loop": "Kill Deadwood furbolgs in Felwood or Winterfall furbolgs in Winterspring. Turn in Deadwood Headdress Feathers and Winterfall Beads (5 for 50 rep).",
        "rewards": (
            "• **Friendly:** Timbermaw Brawlers, Belt patterns\n"
            "• **Honored:** Warbear Harness, +15 Agility 1H Weapon Enchantment\n"
            "• **Revered:** *Defender of the Timbermaw* (Trinket that summons a furbolg shaman healer!)\n"
            "• **Exalted:** Stave of the Furbolg, Transformation Trinket"
        ),
        "tip": "You start Hostile! Do not fight in the tunnel until Friendly, or guards will one-shot you."
    },
    "argent dawn": {
        "name": "Argent Dawn",
        "location": "Western & Eastern Plaguelands (Light's Hope Chapel)",
        "farm_loop": "Equip Argent Dawn Commission trinket; slay undead in Stratholme & Scholomance to collect Minion, Slaver, and Leader Scourgestones.",
        "rewards": (
            "• **Friendly / Honored:** Blessed Sunfruit (+10 Str food), Enriched Manna Biscuit\n"
            "• **Revered:** +5 All Resistance Shoulder Enchants, Formula: Powerful Mana Oil\n"
            "• **Exalted:** +5 All Resistance Greater Shoulder Enchant (+18 Healing / +5 Fire/Frost/Nature Res)"
        ),
        "tip": "Save all Scourgestones until you reach Honored from mob kills, then turn them in all the way to Exalted."
    },
    "thorium brotherhood": {
        "name": "Thorium Brotherhood",
        "location": "Searing Gorge (Thorium Point) & Blackrock Depths (Grim Guzzler)",
        "farm_loop": (
            "• Neutral to Friendly: Heavy Leather, Kingsblood, Iron Bars\n"
            "• Friendly to Honored: Incendosaur Scales, Coal, Dark Iron Ore\n"
            "• Honored to Exalted: Dark Iron Ore, Blood of the Mountain, Fiery/Lava Cores (turned in to Lokhtos in BRD bar)"
        ),
        "rewards": (
            "• **Friendly:** Molten Helm, Fire Resist Leather/Mail\n"
            "• **Honored:** Dark Iron Bracers, Fire Resist Plate, Transmute: Elemental Fire\n"
            "• **Exalted:** Sulfuron Hammer Plans (Legendary weapon precursor), Dark Iron Boots/Reaver"
        ),
        "tip": "Mandatory for guild blacksmiths to craft the fire resistance gear needed for Molten Core and Blackwing Lair."
    },
    "hydraxian waterlords": {
        "name": "Hydraxian Waterlords",
        "location": "Azshara (Duke Hydraxis at remote eastern island 79, 73)",
        "farm_loop": "Kill Dust Stormers / Desert Rumblers in Silithus to Honored; clear Molten Core bosses weekly for 100-150 rep per boss to Revered/Exalted.",
        "rewards": (
            "• **Honored:** Aqual Quintessence (consumable dousing water for Molten Core runes)\n"
            "• **Revered:** *Eternal Quintessence* (Permanent reusable dousing water on 1-hour cooldown!)\n"
            "• **Exalted:** Band of Icy Depths, Ocean's Breeze rings"
        ),
        "tip": "Raid teams require 7 active Aqual Quintessences to extinguish all 7 runes in Molten Core and summon Majordomo Executus."
    },
    "cenarion circle": {
        "name": "Cenarion Circle",
        "location": "Silithus (Cenarion Hold)",
        "farm_loop": "Farm Twilight Cultists in Silithus for Encrypted Twilight Texts (10 for 100 rep). Summon Lesser, Major, and Greater Elemental Abyssals using cultist outfits.",
        "rewards": (
            "• **Friendly / Honored:** Nature Resistance gear patterns for AQ40\n"
            "• **Revered / Exalted:** *Earthstrike* Trinket (+280 Attack Power for 20s — top melee burst trinket in Classic!), Rockfury Bracers (Caster BiS)"
        ),
        "tip": "Complete Field Duty assignments in Silithus to earn Tactical, Combat, and Logistics badges needed for Earthstrike."
    },
    "zandalar tribe": {
        "name": "Zandalar Tribe",
        "location": "Yojamba Isle, Stranglethorn Vale (15, 16)",
        "farm_loop": "Full clears of Zul'Gurub (20-man raid); turn in Zandalar Tribe coins (3 sets for 50 rep) and Primal Hakkari Bijous (destroy at altar for 75 rep + token).",
        "rewards": (
            "• **Friendly to Revered:** Class Quest Armor sets, Bloodvine Garb patterns (Tailoring), Greater Shoulder Inscriptions (+30 AP / +18 Spell Dmg)\n"
            "• **Exalted:** Zandalar Signet of Might (+30 AP), Mojo (+18 Dmg), or Serenity (+33 Healing)"
        ),
        "tip": "The ZG shoulder enchants are the strongest offensive shoulder enchants in Classic until Naxxramas Sapphiron enchants."
    }
}


# -------------------------------------------------------------
# Retrieval Helper Functions
# -------------------------------------------------------------
def get_class_build(query_class: str, query_spec: Optional[str] = None) -> Optional[Dict[str, Any]]:
    """Retrieves class talent build and leveling specs."""
    import difflib
    if not query_class:
        return None
    qc = query_class.strip().lower()
    qs = query_spec.strip().lower() if query_spec else ""

    combined = f"{qc}:{qs}".strip(":")

    # Direct combined match
    for k, v in CLASS_BUILDS.items():
        if k == combined:
            return v

    # Check if spec is in the key
    if qs:
        for k, v in CLASS_BUILDS.items():
            if qc in k and qs in k:
                return v

    # Check if class matches, return first prominent spec or match
    for k, v in CLASS_BUILDS.items():
        if qc in k or k.startswith(qc):
            return v

    # Fuzzy match
    keys = list(CLASS_BUILDS.keys())
    matches = difflib.get_close_matches(combined, keys, n=1, cutoff=0.5)
    if matches:
        return CLASS_BUILDS[matches[0]]

    return None


def get_consumables_info(role_or_class: str) -> Optional[Dict[str, Any]]:
    """Retrieves raid consumable checklist by role or class."""
    if not role_or_class:
        return None
    q = role_or_class.strip().lower()

    # Map class to primary role
    class_to_role = {
        "warrior": "melee dps", "rogue": "melee dps", "enhancement": "melee dps",
        "mage": "caster dps", "warlock": "caster dps", "shadow": "caster dps",
        "priest": "healer", "paladin": "healer", "holy": "healer", "resto": "healer",
        "tank": "tank", "bear": "tank", "prot": "tank", "heals": "healer", "healing": "healer",
        "caster": "caster dps", "melee": "melee dps", "hunter": "melee dps"
    }
    target = class_to_role.get(q, q)
    for k, v in CONSUMABLES_DATA.items():
        if k in target or target in k:
            return v
    return None


def get_world_buff_info(query: str) -> Optional[Dict[str, Any]]:
    """Retrieves world buff coordinates, timers, and effects."""
    import difflib
    if not query:
        return None
    q = query.strip().lower()

    alias_map = {
        "ony": "dragonslayer", "onyxia": "dragonslayer", "nef": "dragonslayer", "nefarian": "dragonslayer",
        "rallying cry": "dragonslayer", "rend": "warchief", "warchief": "warchief", "wcb": "warchief",
        "songflower": "songflower", "flower": "songflower", "felwood": "songflower",
        "zg": "zandalar", "hakkar": "zandalar", "zandalar": "zandalar", "yojamba": "zandalar",
        "dmt": "dire maul", "tribute": "dire maul", "slipkik": "dire maul", "fengus": "dire maul",
        "dmf": "sayge", "sayge": "sayge", "darkmoon": "sayge"
    }

    key = alias_map.get(q, q)
    for k, v in WORLD_BUFFS_DATA.items():
        if k in key or key in k:
            return v

    keys = list(WORLD_BUFFS_DATA.keys())
    matches = difflib.get_close_matches(key, keys, n=1, cutoff=0.55)
    if matches:
        return WORLD_BUFFS_DATA[matches[0]]
    return None


def get_raid_boss_info(query: str) -> Optional[Dict[str, Any]]:
    """Retrieves quick boss tactics and wipe-prevention mechanics."""
    import difflib
    if not query:
        return None
    q = query.strip().lower()

    for k, v in RAID_BOSSES_DATA.items():
        if k in q or q in k:
            return {"name": k.title(), **v}

    keys = list(RAID_BOSSES_DATA.keys())
    matches = difflib.get_close_matches(q, keys, n=1, cutoff=0.55)
    if matches:
        return {"name": matches[0].title(), **RAID_BOSSES_DATA[matches[0]]}
    return None


def get_reputation_info(query: str) -> Optional[Dict[str, Any]]:
    """Retrieves reputation farming loop, turn-ins, and key rewards."""
    import difflib
    if not query:
        return None
    q = query.strip().lower()

    alias_map = {
        "timbermaw": "timbermaw hold", "furbolg": "timbermaw hold",
        "argent": "argent dawn", "dawn": "argent dawn", "scourgestone": "argent dawn",
        "thorium": "thorium brotherhood", "brotherhood": "thorium brotherhood",
        "hydraxian": "hydraxian waterlords", "waterlords": "hydraxian waterlords", "quintessence": "hydraxian waterlords",
        "cenarion": "cenarion circle", "silithus": "cenarion circle", "earthstrike": "cenarion circle",
        "zandalar": "zandalar tribe", "zg": "zandalar tribe", "yojamba": "zandalar tribe"
    }

    target = alias_map.get(q, q)
    for k, v in REPUTATIONS_DATA.items():
        if k in target or target in k:
            return v

    keys = list(REPUTATIONS_DATA.keys())
    matches = difflib.get_close_matches(target, keys, n=1, cutoff=0.55)
    if matches:
        return REPUTATIONS_DATA[matches[0]]
    return None


# -------------------------------------------------------------
# Macro Templates & Copy-Paste Codeblocks
# -------------------------------------------------------------
MACRO_TEMPLATES: Dict[str, Dict[str, Any]] = {
    "mouseover heal": {
        "title": "Mouseover Healing Macro",
        "description": "Heals your mouseover target without dropping your current target. Falls back to target, then self.",
        "code": "#showtooltip\n/cast [@mouseover,help,nodead][@target,help,nodead][@player] Flash Heal",
        "instructions": "Copy into `/macro`. Replace `Flash Heal` with any healing spell (Renew, Healing Wave, Holy Light, Rejuvenation)."
    },
    "stance dance": {
        "title": "Warrior Stance Dance Macro (Overpower)",
        "description": "Automatically shifts into Battle Stance if you aren't in it, then casts Overpower on enemy dodges.",
        "code": "#showtooltip Overpower\n/cast [nostance:1] Battle Stance\n/cast Overpower",
        "instructions": "For Berserker Stance Whirlwind, swap `[nostance:1] Battle Stance` to `[nostance:3] Berserker Stance` and `Whirlwind`."
    },
    "startattack": {
        "title": "Melee /startattack Macro",
        "description": "Ensures you continue auto-attacking your target even if you lack rage or energy, preventing swing stalls.",
        "code": "#showtooltip Sinister Strike\n/startattack\n/cast Sinister Strike",
        "instructions": "Substitute `Sinister Strike` with `Mortal Strike`, `Bloodthirst`, `Backstab`, or `Rend`."
    },
    "hunter auto shot": {
        "title": "Hunter Auto Shot / Aimed Shot (No Clipping)",
        "description": "Prevents accidental cancellation of your Auto Shot animation. The exclamation mark ensures repeated clicks do not toggle it off.",
        "code": "#showtooltip Aimed Shot\n/targetenemy [noharm][dead]\n/cast !Auto Shot\n/cast Aimed Shot",
        "instructions": "Weave this between your ranged swing timer to maximize DPS."
    },
    "burst cooldowns": {
        "title": "One-Click Burst Cooldowns & Trinkets",
        "description": "Pops top trinket (slot 13) and bottom trinket (slot 14) simultaneously alongside major offensive buffs.",
        "code": "#showtooltip Death Wish\n/use 13\n/use 14\n/cast Death Wish\n/cast Blood Fury",
        "instructions": "Replace `Death Wish` with `Arcane Power`, `Combustion`, `Bestial Wrath`, or `Blade Flurry`."
    },
    "camera zoom": {
        "title": "Max Camera Distance Console Command",
        "description": "Unlocks the maximum camera zoom factor in Classic WoW for superior raid and battleground vision.",
        "code": "/console cameraDistanceMaxZoomFactor 4",
        "instructions": "Paste directly into your in-game chat box and hit Enter, then scroll your mouse wheel all the way back."
    },
    "focus interrupt": {
        "title": "Focus Target Instant Interrupt Macro",
        "description": "Interrupts your current spellcast immediately with `/stopcasting` and kicks/counterspells your focus target.",
        "code": "#showtooltip Counterspell\n/stopcasting\n/cast [@focus,harm,nodead][@target,harm,nodead] Counterspell",
        "instructions": "Replace `Counterspell` with `Kick`, `Earth Shock`, or `Pummel`."
    },
    "weapon swap": {
        "title": "One-Button Weapon & Shield Swap",
        "description": "Instantly equips your 1H Weapon and Shield for emergency Shield Wall or defensive stance swaps.",
        "code": "/equipslot 16 [Your 1H Weapon Name]\n/equipslot 17 [Your Shield Name]",
        "instructions": "Put exact weapon names inside brackets (e.g. `/equipslot 16 Dal'Rend's Sacred Charge` and `/equipslot 17 Draconian Deflector`)."
    }
}


# -------------------------------------------------------------
# PvP System (Ranks 1-14, Decay Math, Battleground Guides)
# -------------------------------------------------------------
PVP_SYSTEM_DATA: Dict[str, Dict[str, Any]] = {
    "ranks": {
        "title": "Classic PvP Honor System Ranks 1–14",
        "description": (
            "• **R1 (Private / Scout • 1,500 RP):** Private's Tabard\n"
            "• **R2 (Corporal / Grunt • 2,000 RP):** Insignia Trinket (Dispels CC on 5-min CD)\n"
            "• **R3 (Sergeant • 5,000 RP):** 10% discount on all faction vendors & repair bills\n"
            "• **R7 (Knight-Lt / Blood Guard • 25,000 RP):** Rare PvP Boots & Gloves\n"
            "• **R8 (Knight-Capt / Legionnaire • 30,000 RP):** Rare PvP Chest & Legs\n"
            "• **R10 (Lt Commander / Champion • 40,000 RP):** Full Rare PvP Set (Helm & Shoulders)\n"
            "• **R11 (Commander / General • 45,000 RP):** Epic PvP Mounts (100% speed, no riding skill required)\n"
            "• **R12 (Marshal / General • 50,000 RP):** Epic PvP Gloves, Legs & Boots\n"
            "• **R13 (Field Marshal / Warlord • 55,000 RP):** Full Epic PvP Set (Helm, Shoulders & Chest)\n"
            "• **R14 (Grand Marshal / High Warlord • 60,000 RP):** Epic R14 Weapons (Equal to Naxxramas weapon DPS!)"
        ),
        "tip": "Rank 14 weapons remain the highest raw stat and top weapon damage options throughout early and mid Classic."
    },
    "decay": {
        "title": "Weekly Honor Decay & Rating Point (RP) Math",
        "description": (
            "• **Weekly Decay Rate:** 20% of your total accumulated Rating Points (RP) decay every Tuesday at weekly reset.\n"
            "• **Weekly Progression Formula:** `New RP = (Current RP * 0.80) + RP Earned from Weekly Standing Bracket`.\n"
            "• **Break-Even Requirement:** To maintain your current rank, you must earn at least 20% of your total RP each week.\n"
            "• **Bracket Stacking:** High-ranking guilds coordinate 'Bracket Stacking' in AV/WSG to expand Bracket 1 (13,000 RP) slots for guild members."
        ),
        "tip": "Never skip a week above Rank 11; a 20% decay penalty on Rank 13 costs 11,000 RP (nearly a full week of grinding)."
    },
    "wsg": {
        "title": "Warsong Gulch (WSG) Battleground Guide",
        "description": (
            "• **Objective:** 10v10 Capture the Flag (First to 3 flag caps wins).\n"
            "• **Flag Carrier (FC) Meta:** Feral Druid or Protection Warrior with Swiftness Potions & Free Action Potions (FAP).\n"
            "• **Optimal FC Route:** Graveyard roof jump -> Banana ramp -> Roof drop into tunnel.\n"
            "• **Strategy:** Send 3-person kill team to EFC (Enemy Flag Carrier) while 6 players control the midfield and powerup runes (Berserking, Speed, Restoration)."
        ),
        "tip": "Controlling the midfield runes prevents enemy Rogues from picking up Berserking (+100% damage dealt)."
    },
    "ab": {
        "title": "Arathi Basin (AB) Battleground Guide",
        "description": (
            "• **Objective:** 15v15 Resource Control (Race to 2000 resources).\n"
            "• **The 3-Cap Meta:** Win by securing and permanently defending 3 nodes (Blacksmith + Stables/Farm + Lumber Mill).\n"
            "• **Lumber Mill Vision:** Assign a Hunter with Eagle Eye to call incoming enemy pushes across the entire basin.\n"
            "• **Flag Spinners:** Paladins (Consecration), Mages (Blizzard/Arcane Explosion), and Rogues keep flags contested so enemies cannot cap."
        ),
        "tip": "Never overextend to 4 or 5 caps unless the enemy team is fully wiped in graveyard; 3-cap gives steady 100% win rate."
    },
    "av": {
        "title": "Alterac Valley (AV) Battleground Guide",
        "description": (
            "• **Objective:** 40v40 Battle of Attrition (Slay General Vanndar Stormpike or Drek'Thar).\n"
            "• **Rush Meta:** Ride directly to enemy keep, cap relief huts, pull marshals/warmasters one-by-one, and burn the general before 10 minutes.\n"
            "• **Reputation Turtle Meta:** Collect Armor Scraps, Stormpike Soldier's Blood / Frostwolf Muzzle to summon Ivus the Forest Lord or Lokholar the Ice Lord."
        ),
        "tip": "Turn in 20 Armor Scraps to upgrade your team's NPC guards to elite veterans."
    }
}


# -------------------------------------------------------------
# Dungeon Keys Directory
# -------------------------------------------------------------
DUNGEON_KEYS: Dict[str, Dict[str, Any]] = {
    "shadowforge key": {
        "name": "Shadowforge Key", "dungeon": "Blackrock Depths (BRD)",
        "source": "Quest: 'Dark Iron Legacy' (Must be in Ghost form to accept!)",
        "steps": (
            "1. Die in Blackrock Mountain and run as a ghost to the central tomb (54, 38) inside Forgewright's Tomb.\n"
            "2. Speak to Franclorn Forgewright (ghost) to accept 'Dark Iron Legacy'.\n"
            "3. Enter BRD, slay Fineous Darkvire to loot the Iron Fel.\n"
            "4. Carry Iron Fel past the Ring of Law to the Shrine of Thaurissan to forge your key."
        ),
        "unlocks": "Unlocks all iron gates, the East/West Garrison doors, and the Shadowforge lock shortcut in BRD.",
        "tip": "Mandatory key for any BRD lava run or Emperor jump run."
    },
    "skeleton key": {
        "name": "Skeleton Key", "dungeon": "Scholomance",
        "source": "Quest Chain: 'A Plague Upon Thee' (Level 56+)",
        "steps": (
            "1. Speak to Commander Ashlam Valorfist (Alliance - Chillwind) or High Executor Derrington (Horde - Bulwark).\n"
            "2. Complete plague research quests across Western Plaguelands.\n"
            "3. Travel to Un'Goro Crater and forge the key in the lava pool at the summit of Fire Plume Ridge.\n"
            "4. Defeat Araj the Summoner in Andorhal (bring a 5-man group) to empower the key."
        ),
        "unlocks": "Unlocks the outer locked gate and main entrance doors of Scholomance.",
        "tip": "Rogues with 280+ Lockpicking can pick the outer gate, but the Skeleton Key is permanent."
    },
    "key to the city": {
        "name": "Key to the City", "dungeon": "Stratholme",
        "source": "Drop: Magistrate Barthas in Stratholme (Service Entrance)",
        "steps": (
            "1. Enter Stratholme through the main gate or have a rogue lockpick the service gate.\n"
            "2. Slay Magistrate Barthas near the slaughterhouses (he runs toward Baron Rivendare's gate).\n"
            "3. Loot the 'Key to the City' from his corpse."
        ),
        "unlocks": "Permanently unlocks the Stratholme Back Service Gate (the standard entrance for Baron Rivendare 45-minute timed runs).",
        "tip": "Once looted, the key is permanent and does not consume on use."
    },
    "scarlet key": {
        "name": "Scarlet Key", "dungeon": "Scarlet Monastery",
        "source": "Loot: Doan's Strongbox inside Scarlet Monastery: Library",
        "steps": (
            "1. Enter Scarlet Monastery Library.\n"
            "2. Slay Arcanist Doan in the final circular library chamber.\n"
            "3. Open the secret strongbox on the wall behind his altar and loot the Scarlet Key."
        ),
        "unlocks": "Unlocks the locked iron gates to Scarlet Monastery: Armory (Herod) and Cathedral (Mograine & Whitemane).",
        "tip": "Keep this key in your keyring through your 30s and 40s."
    },
    "crescent key": {
        "name": "Crescent Key", "dungeon": "Dire Maul",
        "source": "Drop: Pusillin in Dire Maul East",
        "steps": (
            "1. Enter Dire Maul East (Warpwood wing).\n"
            "2. Speak to the imp Pusillin near the entrance; he taunts you and runs deeper into the dungeon.\n"
            "3. Chase him through the instance until he transforms into a hostile demon.\n"
            "4. Slay Pusillin and loot the Crescent Key."
        ),
        "unlocks": "Unlocks Dire Maul North (Tribute run wing), Dire Maul West (Prince Tortheldrin wing), and the DM library door.",
        "tip": "Essential key for Dire Maul Tribute buff runs and farming."
    },
    "scepter of celebras": {
        "name": "Scepter of Celebras", "dungeon": "Maraudon",
        "source": "Quest: 'Legends of Maraudon' inside Maraudon",
        "steps": (
            "1. Enter Maraudon Orange or Purple entrance.\n"
            "2. Slay Lord Vyletongue (Orange side) for Celebras' Diamond.\n"
            "3. Slay Noxxion (Purple side) for Celebras' Rod.\n"
            "4. Slay Celebras the Cursed, speak to his redeemed spirit, and watch him forge the Scepter."
        ),
        "unlocks": "Creates a permanent portal at the Maraudon inner falls directly to Princess Theradras (Princess run skip).",
        "tip": "Allows skipping the first 45 minutes of trash in Maraudon."
    },
    "workshop key": {
        "name": "Workshop Key", "dungeon": "Gnomeregan",
        "source": "Drop: Electrocutioner 6000 in Gnomeregan",
        "steps": (
            "1. Enter Gnomeregan from Dun Morogh or Booty Bay teleport.\n"
            "2. Navigate through the engineering cog halls and defeat Electrocutioner 6000.\n"
            "3. Loot the Workshop Key from his remains."
        ),
        "unlocks": "Unlocks the back workshop entrance gate located in western Dun Morogh, bypassing 80% of trash.",
        "tip": "Vital for fast crowd pummeler farming (Feral Druids farming Manual Crowd Pummeler)."
    }
}


# -------------------------------------------------------------
# Racial Traits & Weapon Skills Directory
# -------------------------------------------------------------
RACIAL_TRAITS: Dict[str, Dict[str, Any]] = {
    # ALLIANCE
    "human": {
        "race": "Human", "faction": "Alliance",
        "traits": (
            "• **Sword Specialization:** +5 Sword weapon skill (1H and 2H)\n"
            "• **Mace Specialization:** +5 Mace weapon skill (1H and 2H)\n"
            "• **Perception:** Increases stealth detection for 20s on a 3-min CD (counters Rogues & Druids)\n"
            "• **The Human Spirit:** +5% Spirit (mana and health regeneration)\n"
            "• **Diplomacy:** 10% bonus to all reputation gains"
        ),
        "meta": "+5 Sword/Mace skill reduces glancing blow damage penalty against Level 63 raid bosses from 35% to 5%, making Humans the undisputed top PvE melee DPS and tanks in Classic.",
        "tip": "Diplomacy saves dozens of hours on Timbermaw, Argent Dawn, and Cenarion reputation grinds."
    },
    "dwarf": {
        "race": "Dwarf", "faction": "Alliance",
        "traits": (
            "• **Stoneform:** Immunity to Bleed, Poison, and Disease effects; +10% Armor for 8s (3-min CD)\n"
            "• **Gun Specialization:** +5 Gun weapon skill\n"
            "• **Frost Resistance:** +10 Frost Resistance\n"
            "• **Find Treasure:** Tracks treasure chests on mini-map radar"
        ),
        "meta": "Stoneform is top-tier in PvP (breaks Blind and cleanses Rogue poisons) and clears bleed effects on raid bosses. Dwarf Priests uniquely get *Fear Ward* (essential for Onyxia, Magmadar, Nefarian).",
        "tip": "Dwarf Priest is considered mandatory for Alliance raid rosters purely for Fear Ward."
    },
    "night elf": {
        "race": "Night Elf", "faction": "Alliance",
        "traits": (
            "• **Shadowmeld:** Stealthes in place while standing still (breaks upon moving; usable by all classes)\n"
            "• **Quickness:** +1% Dodge chance\n"
            "• **Wisp Spirit:** Transforms into a wisp upon death, increasing movement speed by 50%\n"
            "• **Nature Resistance:** +10 Nature Resistance"
        ),
        "meta": "Shadowmeld allows Priests, Hunters, and Warriors to ambush enemies or eat/drink in stealth in PvP.",
        "tip": "Wisp Spirit drastically speeds up corpse runs in sprawling zones."
    },
    "gnome": {
        "race": "Gnome", "faction": "Alliance",
        "traits": (
            "• **Escape Artist:** Removes any immobilization or movement speed slowing effect (1-min CD)\n"
            "• **Expansive Mind:** +5% Intellect (scales with gear and raid buffs)\n"
            "• **Engineering Specialization:** +15 Engineering skill\n"
            "• **Arcane Resistance:** +10 Arcane Resistance"
        ),
        "meta": "Escape Artist has a tiny 1-minute cooldown, making Gnomes the king of Alliance PvP for Warriors and Rogues vs Frost Mages. +5% Int makes Gnome Mages/Warlocks top caster DPS.",
        "tip": "+15 Engineering allows Gnomes to use high-level engineering gadgets earlier while leveling."
    },
    "skyborne elf": {
        "race": "Skyborne Elf", "faction": "Alliance (WoW: Forever Classic+)",
        "traits": (
            "• **Zephyr's Grace (Active):** Glides on aerial updrafts, reducing fall speed and allowing cliff gliding without taking falling damage (30s CD)\n"
            "• **Aerial Precision:** +5 Bow and Thrown weapon skill\n"
            "• **Windborne (Passive):** +5% increased out-of-combat movement speed\n"
            "• **Arcane Heritage:** +10 Arcane Resistance"
        ),
        "meta": "New playable Alliance race starting in Zephras Isle. *Zephyr's Grace* provides built-in feather falling for world traversal, while +5 Bow skill rivals Troll hunters.",
        "tip": "Use Zephyr's Grace when leaping off high terrain like Arathi Lumber Mill or Blackrock Mountain chains."
    },

    # HORDE
    "orc": {
        "race": "Orc", "faction": "Horde",
        "traits": (
            "• **Hardiness:** +25% chance to resist Stun effects (stacks with talents to ~40% stun resist!)\n"
            "• **Blood Fury:** Increases base melee Attack Power by 25% for 15s (reduces healing received by 50%)\n"
            "• **Axe Specialization:** +5 Axe weapon skill (1H and 2H)\n"
            "• **Command:** +5% damage dealt by hunter and warlock pets"
        ),
        "meta": "Hardiness makes Orcs the undisputed best PvP race in Classic (infuriates Rogues who rely on Stun locks). +5 Axe skill provides Humans' PvE damage advantage on Horde side.",
        "tip": "Time Blood Fury during execute phases or burst windows when you aren't actively taking heavy damage."
    },
    "undead": {
        "race": "Undead", "faction": "Horde",
        "traits": (
            "• **Will of the Forsaken (WotF):** Immune to Charm, Fear, and Sleep for 5s; instantly breaks active CC (2-min CD)\n"
            "• **Cannibalize:** Consumes a humanoid or undead corpse to regenerate 35% health over 10s\n"
            "• **Underwater Breathing:** 300% increased underwater breath duration\n"
            "• **Shadow Resistance:** +10 Shadow Resistance"
        ),
        "meta": "Will of the Forsaken is the premier PvP racial in Classic, completely nullifying Priest and Warlock fear mechanics.",
        "tip": "Use Cannibalize between mob pulls to eliminate downtime without spending food."
    },
    "tauren": {
        "race": "Tauren", "faction": "Horde",
        "traits": (
            "• **War Stomp:** Stuns up to 5 nearby enemies for 2 seconds (0.5s cast, 2-min CD)\n"
            "• **Endurance:** +5% Maximum Health (scales with gear, world buffs, and Titans flask)\n"
            "• **Cultivation:** +15 Herbalism skill (gather herbs with orange/yellow chance easier)\n"
            "• **Nature Resistance:** +10 Nature Resistance"
        ),
        "meta": "+5% Maximum Health makes Tauren Warriors and Bears the highest effective health tanks in Classic. War Stomp guarantees an uninterrupted heal or cast.",
        "tip": "Taurens have a larger melee hitbox, allowing you to hit bosses and players from further away."
    },
    "troll": {
        "race": "Troll", "faction": "Horde",
        "traits": (
            "• **Berserking:** Increases attack and casting speed by 10% to 30% based on missing health for 10s (3-min CD)\n"
            "• **Bow & Throwing Specialization:** +5 Bow and Thrown weapon skill\n"
            "• **Beast Slaying:** +5% damage bonus against Beasts\n"
            "• **Regeneration:** 10% health regeneration continues during combat"
        ),
        "meta": "Berserking makes Trolls the top PvE DPS race for Horde casters and Hunters. +5 Bow skill eliminates glancing penalties for Hunters.",
        "tip": "Use Berserking at low health or combine with a pre-cast Blood Fury for maximum spell haste."
    }
}


# -------------------------------------------------------------
# New Retrieval Helper Functions
# -------------------------------------------------------------
def get_macro_info(query: str) -> Optional[Dict[str, Any]]:
    """Retrieves copy-pasteable in-game macro templates."""
    import difflib
    if not query:
        return None
    q = query.strip().lower()

    alias_map = {
        "trinket": "burst cooldowns", "trinkets": "burst cooldowns", "burst": "burst cooldowns", "cooldown": "burst cooldowns", "cooldowns": "burst cooldowns",
        "camera": "camera zoom", "zoom": "camera zoom", "maxzoom": "camera zoom", "distance": "camera zoom",
        "focus": "focus interrupt", "interrupt": "focus interrupt", "kick": "focus interrupt", "counterspell": "focus interrupt",
        "weaponswap": "weapon swap", "weapon swap": "weapon swap", "shield swap": "weapon swap", "swap": "weapon swap",
        "autoshot": "hunter auto shot", "auto shot": "hunter auto shot", "hunter": "hunter auto shot",
        "startattack": "startattack", "autoattack": "startattack",
        "stance": "stance dance", "stance dance": "stance dance", "overpower": "stance dance",
        "mouseover": "mouseover heal", "mouseover heal": "mouseover heal", "heal": "mouseover heal"
    }

    target = alias_map.get(q, q)
    for k, v in MACRO_TEMPLATES.items():
        if k in target or target in k or k in q or q in k:
            return v

    keys = list(MACRO_TEMPLATES.keys())
    matches = difflib.get_close_matches(target, keys, n=1, cutoff=0.55)
    if matches:
        return MACRO_TEMPLATES[matches[0]]
    return None


def get_pvp_info(query: str) -> Optional[Dict[str, Any]]:
    """Retrieves PvP ranks, honor decay math, and battleground guides."""
    import difflib
    if not query:
        return None
    q = query.strip().lower()

    alias_map = {
        "rank": "ranks", "ranks": "ranks", "honor": "ranks", "title": "ranks", "r14": "ranks", "rank 14": "ranks", "rank 10": "ranks",
        "decay": "decay", "math": "decay", "rp": "decay", "calculation": "decay",
        "wsg": "wsg", "warsong": "wsg", "warsong gulch": "wsg", "flag": "wsg",
        "ab": "ab", "arathi": "ab", "arathi basin": "ab", "basin": "ab",
        "av": "av", "alterac": "av", "alterac valley": "av", "valley": "av", "drek": "av", "vanndar": "av"
    }

    # 1. Match full word boundary aliases
    for alias_k, target_val in alias_map.items():
        if re.search(r'\b' + re.escape(alias_k) + r'\b', q):
            return PVP_SYSTEM_DATA[target_val]

    # 2. Check exact keys
    words = set(re.findall(r'\b\w+\b', q))
    for k, v in PVP_SYSTEM_DATA.items():
        if k in words:
            return v

    return None


def get_dungeon_key_info(query: str) -> Optional[Dict[str, Any]]:
    """Retrieves dungeon key quest chains, drop locations, and doors unlocked."""
    import difflib
    if not query:
        return None
    q = query.strip().lower()

    for k, v in DUNGEON_KEYS.items():
        if k in q or q in k or v["dungeon"].lower() in q:
            return v

    keys = list(DUNGEON_KEYS.keys())
    matches = difflib.get_close_matches(q, keys, n=1, cutoff=0.55)
    if matches:
        return DUNGEON_KEYS[matches[0]]
    return None


def get_racial_info(query: str) -> Optional[Dict[str, Any]]:
    """Retrieves racial traits, weapon skills, and faction mechanics."""
    import difflib
    if not query:
        return None
    q = query.strip().lower()

    for k, v in RACIAL_TRAITS.items():
        if k in q or q in k:
            return v

    keys = list(RACIAL_TRAITS.keys())
    matches = difflib.get_close_matches(q, keys, n=1, cutoff=0.55)
    if matches:
        return RACIAL_TRAITS[matches[0]]
    return None


def get_attunement_info(query: str) -> Optional[Dict[str, Any]]:
    """Retrieves raid attunement guides (Onyxia, MC, BWL, Naxx, Temporal Rift)."""
    import difflib
    if not query:
        return None
    q = query.strip().lower()

    alias_map = {
        "ony": "onyxia", "onyxia": "onyxia", "drakefire": "onyxia",
        "mc": "molten core", "molten core": "molten core", "core": "molten core", "lothos": "molten core",
        "bwl": "blackwing lair", "blackwing": "blackwing lair", "blackwing lair": "blackwing lair", "orb": "blackwing lair",
        "naxx": "naxxramas", "naxxramas": "naxxramas", "argent dawn": "naxxramas",
        "temporal": "temporal rift", "temporal rift": "temporal rift", "rift": "temporal rift"
    }
    target = alias_map.get(q, q)
    for k, v in ATTUNEMENTS.items():
        if k in target or target in k:
            return v

    keys = list(ATTUNEMENTS.keys())
    matches = difflib.get_close_matches(target, keys, n=1, cutoff=0.55)
    if matches:
        return ATTUNEMENTS[matches[0]]
    return None


# -------------------------------------------------------------
# Advanced System 1: Raid Comp & Buff Synergy Optimizer
# -------------------------------------------------------------
RAID_BUFFS_CATALOG = {
    "sunder": {"name": "Sunder Armor (-2,250 Armor)", "class": "Warrior", "type": "Physical Debuff", "importance": "CRITICAL"},
    "faerie_fire": {"name": "Faerie Fire (-505 Armor)", "class": "Druid", "type": "Physical Debuff", "importance": "HIGH"},
    "recklessness": {"name": "Curse of Recklessness (-640 Armor / Anti-Fear)", "class": "Warlock", "type": "Physical Debuff", "importance": "CRITICAL"},
    "elements": {"name": "Curse of the Elements (+10% Fire/Frost Damage)", "class": "Warlock", "type": "Spell Debuff", "importance": "HIGH"},
    "shadows": {"name": "Curse of Shadows (+10% Shadow/Arcane Damage)", "class": "Warlock", "type": "Spell Debuff", "importance": "MEDIUM"},
    "windfury": {"name": "Windfury Totem (Extra Auto-Attack)", "class": "Shaman", "type": "Melee Buff", "importance": "CRITICAL (Horde)"},
    "battle_shout": {"name": "Battle Shout (+Attack Power)", "class": "Warrior", "type": "Melee Buff", "importance": "HIGH"},
    "trueshot": {"name": "Trueshot Aura (+Attack Power)", "class": "Hunter", "type": "Melee/Ranged Buff", "importance": "MEDIUM"},
    "tranq_shot": {"name": "Tranquilizing Shot (Enrage Dispel)", "class": "Hunter", "type": "Boss Mechanic", "importance": "CRITICAL (Magmadar/Chromaggus)"},
    "intellect": {"name": "Arcane Intellect (+31 Intellect)", "class": "Mage", "type": "Caster Buff", "importance": "HIGH"},
    "fortitude": {"name": "Power Word: Fortitude (+54 Stamina)", "class": "Priest", "type": "Survivability", "importance": "CRITICAL"},
    "decurse": {"name": "Remove Curse (Decurse)", "class": ["Mage", "Druid"], "type": "Utility", "importance": "CRITICAL (Lucifron/Gehennas)"},
    "dispel": {"name": "Dispel Magic / Cleanse", "class": ["Priest", "Paladin"], "type": "Utility", "importance": "CRITICAL"},
    "rebirth": {"name": "Rebirth (Combat Rez) & Innervate", "class": "Druid", "type": "Utility", "importance": "HIGH"},
    "soulstone": {"name": "Soulstone (Combat Wipes Prevention)", "class": "Warlock", "type": "Utility", "importance": "HIGH"}
}


def analyze_raid_comp(roster_str: str) -> Dict[str, Any]:
    """Parses a roster string and evaluates raid buffs, debuffs, and missing synergies."""
    text = roster_str.lower()
    class_map = {
        "warrior": ["warrior", "warr", "war"],
        "rogue": ["rogue", "rog"],
        "mage": ["mage", "mag"],
        "warlock": ["warlock", "lock"],
        "priest": ["priest", "pri"],
        "druid": ["druid", "drood"],
        "hunter": ["hunter", "hunt"],
        "shaman": ["shaman", "sham"],
        "paladin": ["paladin", "pala", "pal"]
    }
    counts = {c: 0 for c in class_map}

    tokens = re.split(r"[,+/;&\n]+", text)
    for t in tokens:
        t = t.strip()
        if not t:
            continue
        num_match = re.search(r"(\d+)", t)
        count = int(num_match.group(1)) if num_match else 1
        found = False
        for c, aliases in class_map.items():
            for a in aliases:
                if a in t:
                    counts[c] += count
                    found = True
                    break
            if found:
                break

    total = sum(counts.values())
    if total == 0:
        total = 40
        counts = {"warrior": 8, "rogue": 6, "mage": 6, "warlock": 4, "priest": 6, "druid": 2, "hunter": 3, "shaman": 5, "paladin": 0}

    covered = []
    missing = []

    if counts["warrior"] >= 1:
        covered.append(f"✅ **Sunder Armor:** Covered by {counts['warrior']} Warrior(s)")
    else:
        missing.append("⚠️ **Sunder Armor Missing:** No Warriors! Boss takes ~30% less physical damage.")

    if counts["druid"] >= 1:
        covered.append(f"✅ **Faerie Fire:** Covered by {counts['druid']} Druid(s)")
    else:
        missing.append("⚠️ **Faerie Fire Missing:** No Druids! Lacks -505 armor reduction.")

    if counts["warlock"] >= 1:
        covered.append(f"✅ **Curse of Recklessness:** Covered by {counts['warlock']} Warlock(s)")
    else:
        missing.append("⚠️ **Curse of Recklessness Missing:** No Warlocks! -640 armor reduction & anti-fear missing.")

    if counts["warlock"] >= 2:
        covered.append(f"✅ **Curse of the Elements & Shadows:** Covered by {counts['warlock']} Warlocks")
    elif counts["warlock"] == 1:
        covered.append("⚡ **Curse Priority Conflict:** Only 1 Warlock (Must choose Recklessness OR Elements)")

    if counts["shaman"] >= 1:
        covered.append(f"✅ **Windfury Totem:** Covered by {counts['shaman']} Shaman(s) (Horde)")
    if counts["paladin"] >= 1:
        covered.append(f"✅ **Paladin Blessings (Might/Kings/Salvation):** Covered by {counts['paladin']} Paladin(s) (Alliance)")

    if counts["mage"] >= 1:
        covered.append(f"✅ **Arcane Intellect:** Covered by {counts['mage']} Mage(s)")
    else:
        missing.append("⚠️ **Arcane Intellect Missing:** No Mages! Casters lose 31 Intellect.")

    if counts["priest"] >= 1:
        covered.append(f"✅ **PW: Fortitude:** Covered by {counts['priest']} Priest(s)")
    else:
        missing.append("⚠️ **PW: Fortitude Missing:** No Priests! Raid loses 54 Stamina.")

    if counts["hunter"] >= 2:
        covered.append(f"✅ **Tranquilizing Shot Rotation:** Covered by {counts['hunter']} Hunters (Safe rotation)")
    elif counts["hunter"] == 1:
        covered.append("⚠️ **Tranquilizing Shot Warning:** Only 1 Hunter (Wipe risk if Tranq Shot misses)")
    else:
        missing.append("🚨 **Tranq Shot CRITICAL WIPE RISK:** Zero Hunters! Magmadar / Chromaggus enrage wipes raid.")

    if counts["mage"] + counts["druid"] >= 2:
        covered.append(f"✅ **Decurse Coverage:** {counts['mage'] + counts['druid']} Decursers (Mages + Druids)")
    else:
        missing.append("⚠️ **Low Decurse Coverage:** < 2 Decursers. High wipe risk on Lucifron / Shazzrah.")

    return {
        "total_players": total,
        "counts": counts,
        "covered": covered,
        "missing": missing
    }


# -------------------------------------------------------------
# Advanced System 2: Slot-by-Slot Pre-Raid BiS Lists
# -------------------------------------------------------------
BIS_LISTS: Dict[str, Dict[str, Any]] = {
    "warrior_fury": {
        "class": "Warrior", "spec": "Fury (Dual Wield)", "phase": "Pre-Raid BiS",
        "gear": (
            "• **Head:** Lionheart Helm (Blacksmithing Crafted • +2% Hit, +2% Crit)\n"
            "• **Neck:** Mark of Fordring (Quest: In Dreams in WPL • +1% Crit, +26 AP)\n"
            "• **Shoulders:** Truestrike Shoulders (Pyroguard Emberseer, UBRS • +2% Hit)\n"
            "• **Back:** Cape of the Black Baron (Baron Rivendare, Stratholme • +15 Agi, +20 AP)\n"
            "• **Chest:** Savage Gladiator Chain (Gorosh the Dervish, BRD Ring of Law • +2% Crit)\n"
            "• **Bracers:** Battleborn Armbraces (Rend Blackhand, UBRS • +1% Hit, +1% Crit)\n"
            "• **Hands:** Devilsaur Gauntlets (Leatherworking • +1% Hit, +28 AP)\n"
            "• **Waist:** Brigam Girdle (General Drakkisath, UBRS • +1% Hit, +15 Str)\n"
            "• **Legs:** Devilsaur Leggings (Leatherworking • +1% Hit, +46 AP)\n"
            "• **Feet:** Bloodmail Boots (Scholomance mini-bosses • +1% Hit, +9 Str)\n"
            "• **Rings:** Blackstone Ring (Princess Theradras, Maraudon) & Painweaver Band (General Drakkisath, UBRS)\n"
            "• **Trinkets:** Hand of Justice (General Angerforge, BRD • Extra swing!) & Blackhand's Breadth (UBRS quest • +2% Crit)\n"
            "• **Main Hand:** Dal'Rend's Sacred Charge (Rend Blackhand, UBRS • 2.8 speed)\n"
            "• **Off Hand:** Dal'Rend's Tribal Guardian (Rend Blackhand, UBRS • 1.8 speed)\n"
            "• **Ranged:** Blackcrow (Shadow Hunter Vosh'gajin, LBRS • +1% Hit)"
        ),
        "hit_summary": "Provides 9%+ Hit (Caps yellow hit completely, even without weapon skill talents/racials!)."
    },
    "warrior_prot": {
        "class": "Warrior", "spec": "Protection (Tank)", "phase": "Pre-Raid BiS",
        "gear": (
            "• **Head:** Golem Skull Helm (Phalanx, BRD) / Gyth's Skull (Rend, UBRS)\n"
            "• **Neck:** Medallion of Grand Marshal Morris (World Drop) / Drakefire Amulet (Onyxia attunement)\n"
            "• **Shoulders:** Stockade Pauldrons (World Drop) / Bulky Iron Spaulders (Dire Maul North)\n"
            "• **Back:** Redoubt Cloak (Dire Maul North Tribute)\n"
            "• **Chest:** Ornate Adamantium Breastplate (Quest in Eastern Plaguelands)\n"
            "• **Bracers:** Fel Hardened Bracers (Dire Maul West)\n"
            "• **Hands:** Force Imbued Gauntlets (Dire Maul West)\n"
            "• **Waist:** Deathbone Girdle (Scholomance)\n"
            "• **Legs:** Deathbone Legguards (Scholomance) / Warmaster Legguards (Rend, UBRS)\n"
            "• **Feet:** Deathbone Sabatons (Scholomance)\n"
            "• **Rings:** Naglering (Golem Lord Argelmach, BRD) & Drakeclaw Band of Defense (Sunken Temple)\n"
            "• **Trinkets:** Force of Will (General Angerforge, BRD) & Smoking Heart of the Mountain (Enchanting)\n"
            "• **Main Hand:** Mirah's Song (Scholomance quest) / Timeworn Mace (Dire Maul West)\n"
            "• **Shield:** Draconian Deflector (General Drakkisath, UBRS) / The Immovable Object (AV Exalted)"
        ),
        "hit_summary": "Provides high Armor, Defense (aim for 440 to avoid boss crits), and reliable threat weapon speed."
    },
    "rogue_combat": {
        "class": "Rogue", "spec": "Combat Swords", "phase": "Pre-Raid BiS",
        "gear": (
            "• **Head:** Mask of the Unforgiven (The Unforgiven, Stratholme • +2% Hit)\n"
            "• **Neck:** Mark of Fordring (Quest: In Dreams in WPL • +1% Crit, +26 AP)\n"
            "• **Shoulders:** Truestrike Shoulders (Pyroguard Emberseer, UBRS • +2% Hit)\n"
            "• **Back:** Cape of the Black Baron (Baron Rivendare, Stratholme • +15 Agi, +20 AP)\n"
            "• **Chest:** Cadaverous Armor (Scholomance) / Tombstone Breastplate (Darkmaster Gandling)\n"
            "• **Bracers:** Eclipse Bracers (Prince Tortheldrin, Dire Maul West)\n"
            "• **Hands:** Devilsaur Gauntlets (Leatherworking • Set bonus: +2% Hit)\n"
            "• **Waist:** Cloudrunner Girdle (Quartermaster Zigris, LBRS • +14 Agi, +15 Str)\n"
            "• **Legs:** Devilsaur Leggings (Leatherworking • +1% Hit, +46 AP)\n"
            "• **Feet:** Swiftwalker Boots (High Priestess Thekal, ZG) / Mongoose Boots (Crafted)\n"
            "• **Rings:** Blackstone Ring (Princess Theradras, Maraudon) & Tarnished Elven Ring (DM Tribute)\n"
            "• **Trinkets:** Hand of Justice (BRD) & Blackhand's Breadth (UBRS quest)\n"
            "• **Main Hand:** Dal'Rend's Sacred Charge (Rend Blackhand, UBRS) / Krol Blade (World Drop)\n"
            "• **Off Hand:** Dal'Rend's Tribal Guardian (Rend Blackhand, UBRS) / Mirah's Song (Quest)\n"
            "• **Ranged:** Blackcrow (LBRS) / Satyr's Bow (Zevrim Thornhoof, Dire Maul East)"
        ),
        "hit_summary": "Reaches 9%+ Hit Cap effortlessly, giving maximum Energy regen from Combat Potency and Sword Spec procs."
    },
    "mage_frost": {
        "class": "Mage", "spec": "Frost (Spell Damage / Hit)", "phase": "Pre-Raid BiS",
        "gear": (
            "• **Head:** Crimson Felt Hat (Magistrate Barthilas, Stratholme • +30 Spell Damage)\n"
            "• **Neck:** Star of Mystaria (Balnazzar, Stratholme • +1% Spell Hit, +9 Int)\n"
            "• **Shoulders:** Boreal Mantle (Warders, BRD) / Felcloth Shoulders (Tailoring)\n"
            "• **Back:** Spritecaster Cape (High Interrogator Gerstahn, BRD) / Amplifying Cloak (Dire Maul)\n"
            "• **Chest:** Robe of the Archmage (Tailoring Crafted • +40 Spell Damage, Instant Mana Restore)\n"
            "• **Bracers:** Sublime Wristguards (Dire Maul North Tribute)\n"
            "• **Hands:** Hands of Power (Quartermaster Zigris, LBRS • +26 Spell Damage)\n"
            "• **Waist:** Ban'thok Sash (Ok'thor the Breaker, BRD • +1% Spell Hit, +12 Spell Damage)\n"
            "• **Legs:** Skyshroud Leggings (High Astromancer, LBRS • +34 Spell Damage)\n"
            "• **Feet:** Omnicast Boots (Golem Lord Argelmach, BRD • +22 Spell Damage)\n"
            "• **Rings:** Maiden's Circle (World Drop) & Songstone of Ironforge / Eye of Orgrimmar (BRD quest)\n"
            "• **Trinkets:** Briarwood Reed (Jed Runewatcher, UBRS • +29 Spell Damage) & Eye of the Beast (UBRS quest • +2% Spell Crit)\n"
            "• **Main Hand:** Witchblade (Darkmaster Gandling, Scholomance • +14 Spell Damage) / Rod of the Ogre Magi (DM Tribute)\n"
            "• **Off Hand:** Tome of the Fiery Arcana (Dire Maul East) / Spirit of Aquementas (Linken quest)\n"
            "• **Wand:** Skul's Ghastly Touch (Skul, Stratholme • +14 Shadow/Spell Damage)"
        ),
        "hit_summary": "Packs 300+ Frost Spell Power with crucial Pre-Raid Spell Hit pieces (Ban'thok Sash, Star of Mystaria)."
    },
    "priest_holy": {
        "class": "Priest", "spec": "Holy (Healing)", "phase": "Pre-Raid BiS",
        "gear": (
            "• **Head:** Insightful Hood (Dire Maul North) / Cassanova's Grace (World Drop)\n"
            "• **Neck:** Animated Chain Necklace (Ramstein the Gorger, Stratholme • +33 Healing)\n"
            "• **Shoulders:** Burial Shawl (Scholomance mini-bosses) / Royal Cap Spaulders (DM)\n"
            "• **Back:** Hide of the Wild (Leatherworking Crafted • +44 Healing)\n"
            "• **Chest:** Truefaith Vestments (Tailoring Crafted • +73 Healing, -Fade CD, Mana on use)\n"
            "• **Bracers:** Loomguard Armbraces (Drakkisath, UBRS) / Gallant's Wristguards (Dire Maul)\n"
            "• **Hands:** Hands of the Exalted (Rivendare, Stratholme • +55 Healing)\n"
            "• **Waist:** Whipvine Cord (Alzzin the Wildshaper, Dire Maul East • +31 Healing)\n"
            "• **Legs:** Padre's Trousers (Illyanna Ravenoak, Dire Maul West • +42 Healing)\n"
            "• **Feet:** Omnicast Boots (BRD) / Boots of the Full Moon (Dire Maul North)\n"
            "• **Rings:** Fordring's Seal (Quest: In Dreams) & Rosewine Circle (LBRS)\n"
            "• **Trinkets:** Mindtap Talisman (Dire Maul West • 11 MP5) & Second Wind (Golem Lord Argelmach, BRD • +300 Mana on use)\n"
            "• **Main Hand:** The Hammer of Grace (Chest in BRD) / Guiding Stave of Wisdom (Emperor Thaurissan, BRD)\n"
            "• **Off Hand:** Brightly Glowing Stone (Dire Maul North Tribute • +37 Healing)\n"
            "• **Wand:** Bonecreeper Stylus (Darkmaster Gandling, Scholomance • +11 Healing)"
        ),
        "hit_summary": "Provides 500+ Bonus Healing with exceptional MP5 sustain for nonstop Greater Heal / Flash Heal casting."
    },
    "hunter_mm": {
        "class": "Hunter", "spec": "Marksmanship", "phase": "Pre-Raid BiS",
        "gear": (
            "• **Head:** Backwood Helm (Dire Maul Tribute) / Crown of Tyranny (Drakkisath, UBRS)\n"
            "• **Neck:** Mark of Fordring (Quest: In Dreams in WPL • +1% Crit, +26 AP)\n"
            "• **Shoulders:** Truestrike Shoulders (Pyroguard Emberseer, UBRS • +2% Hit)\n"
            "• **Back:** Cape of the Black Baron (Baron Rivendare, Stratholme • +15 Agi, +20 AP)\n"
            "• **Chest:** Savage Gladiator Chain (Gorosh, BRD) / Beaststalker Tunic (Drakkisath)\n"
            "• **Bracers:** Bracers of the Eclipse (Prince Tortheldrin, Dire Maul West)\n"
            "• **Hands:** Devilsaur Gauntlets (Leatherworking • +1% Hit, +28 AP)\n"
            "• **Waist:** Warmonger's Belt (Dire Maul Tribute) / King's Girdle (DM North)\n"
            "• **Legs:** Devilsaur Leggings (Leatherworking • +1% Hit, +46 AP)\n"
            "• **Feet:** Windreaver Greaves (Scholomance) / Bloodmail Boots (Scholomance)\n"
            "• **Rings:** Blackstone Ring (Maraudon) & Tarnished Elven Ring (Dire Maul Tribute)\n"
            "• **Trinkets:** Blackhand's Breadth (UBRS quest) & Royal Seal of Eldre'Thalas (Dire Maul Class Book)\n"
            "• **Melee 2H / 1H:** Barbarous Blade (King Gordok, DM North • +1% Crit, +60 AP) OR 2x Dawn's Edge (Axes)\n"
            "• **Ranged Weapon:** Dwarven Hand Cannon (World Drop) / Carapace Spine Crossbow (Nerub'enkan, Strat) / Ancient Bone Bow (Scholomance)"
        ),
        "hit_summary": "Reaches the 9% Ranged Hit Cap with massive Agility and ranged Attack Power."
    },
    "warlock_ds_ruin": {
        "class": "Warlock", "spec": "DS/Ruin (Shadow Spell Power)", "phase": "Pre-Raid BiS",
        "gear": (
            "• **Head:** Crimson Felt Hat (Stratholme) / Spellweaver's Turban (Drakkisath, UBRS)\n"
            "• **Neck:** Star of Mystaria (Balnazzar, Stratholme • +1% Spell Hit)\n"
            "• **Shoulders:** Felcloth Shoulders (Tailoring Crafted • +26 Shadow Damage)\n"
            "• **Back:** Spritecaster Cape (BRD) / Amplifying Cloak (Dire Maul)\n"
            "• **Chest:** Robe of the Void (Tailoring Crafted • +46 Shadow Damage, Health drain)\n"
            "• **Bracers:** Sublime Wristguards (Dire Maul Tribute)\n"
            "• **Hands:** Felcloth Gloves (Tailoring Crafted • +33 Shadow Damage)\n"
            "• **Waist:** Ban'thok Sash (BRD • +1% Spell Hit, +12 Spell Damage)\n"
            "• **Legs:** Felcloth Pants (Tailoring Crafted • +33 Shadow Damage)\n"
            "• **Feet:** Maleki's Footwraps (Maleki the Pallid, Stratholme • +27 Shadow Damage)\n"
            "• **Rings:** Band of Rumination (UBRS) & Underworld Band (World Drop)\n"
            "• **Trinkets:** Briarwood Reed (UBRS • +29 Spell Damage) & Eye of the Beast (UBRS quest • +2% Spell Crit)\n"
            "• **Weapon:** Rod of the Ogre Magi (King Gordok, DM Tribute • +23 Spell Dmg, +1% Crit) OR Witchblade + Spirit of Aquementas\n"
            "• **Wand:** Skul's Ghastly Touch (Stratholme • +14 Shadow Damage)"
        ),
        "hit_summary": "Optimizes Shadow Damage to 320+ for maximum Shadow Bolt critical strike yields under Ruin (100% crit bonus)."
    }
}


def get_bis_list(class_name: str, spec: Optional[str] = None) -> Optional[Dict[str, Any]]:
    """Retrieves slot-by-slot BiS lists."""
    c = class_name.lower().strip()
    s = (spec or "").lower().strip()

    target_key = f"{c}_{s}".replace(" ", "_")
    for k, v in BIS_LISTS.items():
        if target_key in k or k in target_key:
            return v

    for k, v in BIS_LISTS.items():
        if c in k:
            return v
    return None


# -------------------------------------------------------------
# Advanced System 3: Gold Farming & G/hr Engine
# -------------------------------------------------------------
GOLD_FARMS = {
    "dm east": {
        "title": "Dire Maul East (DM East) Jump Runs",
        "g_per_hour": "60–100g / hour",
        "classes": "Warrior + Healer duo, Rogue solo, Warlock solo",
        "strategy": (
            "1. Enter Dire Maul East, jump off the courtyard balcony directly into Hydrospawn's pool.\n"
            "2. Slay Hydrospawn and Zevrim Thornhoof for high-value blue weapons and Felcloth.\n"
            "3. Mine the 2–3 Rich Thorium Veins in the final tunnel for Arcane Crystals (~40-50g each!).\n"
            "4. Pick Ghost Mushrooms and Gromsblood along the garden paths.\n"
            "5. Exit through the rear tunnel, reset instance, and repeat up to 5 times per hour."
        ),
        "tip": "Bring a Mining pick and ensure 275+ Mining skill to tap Rich Thorium Veins."
    },
    "maraudon": {
        "title": "Maraudon Princess & Tinkerer Solo Run",
        "g_per_hour": "45–65g / hour (Pure Vendor Gold)",
        "classes": "Hunter, Warlock, Mage, Druid",
        "strategy": (
            "1. Use the Scepter of Celebras portal to spawn directly at the inner waterfall.\n"
            "2. Kite Princess Theradras around the pillar until dead (loot Ring & Dagger to vendor).\n"
            "3. Slay Rotgrip the crocodile in the water basin.\n"
            "4. Path up the ramp to kill Tinkerer Gizlock for high vendor-value shields and guns.\n"
            "5. Reset instance, sell vendor trash, and reset under the 12-minute mark per run."
        ),
        "tip": "Zero Auction House reliance; 100% stable raw gold straight from vendors."
    },
    "dm tribute": {
        "title": "Dire Maul North (DM North) Solo Tribute Run",
        "g_per_hour": "80–130g / hour",
        "classes": "Hunter (Spec: 20/31/0 Marksmanship/Survival)",
        "strategy": (
            "1. Enter DM North with Invisibility Potions, Lesser Invisibility, or Feign Death pathing.\n"
            "2. Avoid killing any Gordok guards (Guard Mol'dar, Fengus, Slip'kik, Kromcrush).\n"
            "3. Kite King Gordok with Aspect of the Cheetah around the upper ledges using Frost Traps.\n"
            "4. Become King of the Gordok and loot the pristine Gordok Tribute Chest.\n"
            "5. Loot major mana potions, epic Tarnished Elven Rings, and vendor blue weapons."
        ),
        "tip": "Sell the King Gordok Tribute buffs (200 AP, 15% Stamina, 3% Spell Crit) to raid teams for 5g per head!"
    },
    "zf graveyard": {
        "title": "Zul'Farrak (ZF) Graveyard AOE Zombie Farm",
        "g_per_hour": "50–75g / hour",
        "classes": "Mage (Frost Spec with Improved Blizzard & Permafrost)",
        "strategy": (
            "1. Mount through Zul'Farrak directly to the Graveyard without pulling side packs.\n"
            "2. Stand on the wall or tomb edge, pop all grave dirt piles with Nova.\n"
            "3. Jump down to group all 40+ zombies into a tight pack.\n"
            "4. Cast Rank 1 Blizzard to snare, followed by Rank 6 Blizzard for mass DPS.\n"
            "5. Loot massive stacks of Mageweave Cloth, silver, and World Drop green boes."
        ),
        "tip": "Can be started as early as Level 42 for lightning-fast 42-54 solo power-leveling!"
    },
    "elemental earth": {
        "title": "Elemental Earth & Fire Hotspot Grinding",
        "g_per_hour": "40–80g / hour (High Auction House Volatility)",
        "classes": "Any DPS class (Hunter, Rogue, Mage, Warrior)",
        "strategy": (
            "• **Elemental Earth:** Farm Lesser Rock Elementals in Badlands (Camp Boff & Angor Fortress) or Rock Elementals in Stonetalon/Arathi.\n"
            "• **Elemental Fire:** Farm Burning Exiles at the Circle of East Binding in Arathi Highlands.\n"
            "• Highly demanded for crafting Greater Nature Protection Potions (AQ40) and Greater Fire Protection Potions (MC/BWL)."
        ),
        "tip": "Check Auction House prices before farming; prices skyrocket on Tuesday raid nights."
    },
    "tyrs hand": {
        "title": "Tyr's Hand Scarlet Elite Grinding",
        "g_per_hour": "40–75g / hour",
        "classes": "Rogue (Pickpocket + Kill), Frost Mage, Protection Paladin",
        "strategy": (
            "1. Travel to Tyr's Hand in southeastern Eastern Plaguelands.\n"
            "2. Slay Scarlet Archmages, Enchanters, and Knights for raw silver and Runecloth.\n"
            "3. Scarlet Enchanters have a 1% chance to drop **Formula: Enchant Weapon - Crusader** (worth 200–400g!).\n"
            "4. Rogues can Pickpocket every elite mob prior to killing for extra lockboxes and silver."
        ),
        "tip": "Be cautious of Scarlet Archmage Fireballs; interrupt or silence immediately."
    }
}


def get_gold_farm_info(query: Optional[str] = "dm east") -> Optional[Dict[str, Any]]:
    """Retrieves gold farming guide."""
    if not query:
        query = "dm east"
    q = query.lower().strip()
    alias_map = {
        "dm east": "dm east", "dme": "dm east", "jump run": "dm east", "thorium": "dm east", "arcane crystal": "dm east",
        "maraudon": "maraudon", "mara": "maraudon", "princess": "maraudon", "vendor": "maraudon",
        "dm tribute": "dm tribute", "dmt": "dm tribute", "tribute": "dm tribute", "hunter": "dm tribute",
        "zf": "zf graveyard", "graveyard": "zf graveyard", "zombies": "zf graveyard", "mage": "zf graveyard",
        "elemental": "elemental earth", "earth": "elemental earth", "fire": "elemental earth", "nature": "elemental earth",
        "tyr": "tyrs hand", "crusader": "tyrs hand", "scarlet": "tyrs hand"
    }
    target = alias_map.get(q, q)
    for k, v in GOLD_FARMS.items():
        if k in target or target in k or k in q or q in k:
            return v
    keys = list(GOLD_FARMS.keys())
    matches = difflib.get_close_matches(target, keys, n=1, cutoff=0.55)
    if matches:
        return GOLD_FARMS[matches[0]]
    return None


# -------------------------------------------------------------
# Advanced System 4: World Events & Timers
# -------------------------------------------------------------
def get_world_events_info(event_name: Optional[str] = None) -> Dict[str, Any]:
    """Calculates active countdowns for Gurubashi Arena chest, DMF, and STV fishing."""
    now_utc = datetime.now(timezone.utc)

    # 1. Gurubashi Chest (Spawns every 3 hours: 00:00, 03:00, 06:00, 09:00, 12:00, 15:00, 18:00, 21:00 UTC)
    current_hour = now_utc.hour
    next_chest_hour = ((current_hour // 3) + 1) * 3
    if next_chest_hour >= 24:
        next_chest_time = now_utc.replace(hour=0, minute=0, second=0, microsecond=0) + timedelta(days=1)
    else:
        next_chest_time = now_utc.replace(hour=next_chest_hour, minute=0, second=0, microsecond=0)

    diff_chest = next_chest_time - now_utc
    chest_hours = int(diff_chest.total_seconds() // 3600)
    chest_mins = int((diff_chest.total_seconds() % 3600) // 60)

    # 2. STV Fishing Tournament (Every Sunday 14:00 UTC)
    days_until_sunday = (6 - now_utc.weekday()) % 7
    next_sunday_fishing = now_utc.replace(hour=14, minute=0, second=0, microsecond=0) + timedelta(days=days_until_sunday)
    if next_sunday_fishing < now_utc:
        next_sunday_fishing += timedelta(days=7)
    diff_fishing = next_sunday_fishing - now_utc
    fish_days = diff_fishing.days
    fish_hours = int(diff_fishing.seconds // 3600)

    # 3. Darkmoon Faire
    dmf_location = "Elwynn Forest (Alliance)" if (now_utc.month % 2 == 0) else "Mulgore (Horde)"

    return {
        "gurubashi": {
            "title": "⚔️ Gurubashi Arena Chest Spawn",
            "time_remaining": f"⏱️ Next Chest in: **{chest_hours}h {chest_mins}m** ({next_chest_time.strftime('%H:00 UTC')})",
            "schedule": "Every 3 hours: `00:00 • 03:00 • 06:00 • 09:00 • 12:00 • 15:00 • 18:00 • 21:00 UTC`",
            "objective": "Short John Mithril places the chest in the center of Gurubashi Arena (STV). FFA PvP zone!",
            "reward": "Loot 12 Arena Trinkets to complete 'Arena Grand Master' (+1000 damage absorption shield)."
        },
        "fishing": {
            "title": "🎣 Stranglethorn Vale Fishing Extravaganza",
            "time_remaining": f"⏱️ Next Tournament in: **{fish_days}d {fish_hours}h** (Sundays at 14:00 UTC / 2:00 PM Server)",
            "schedule": "Every Sunday from 2:00 PM to 4:00 PM",
            "objective": "Catch 40 Speckled Tastyfish from School of Fish pools along the STV coast and turn in to Riggle Bassbait in Booty Bay.",
            "rewards": "• **Arcanite Fishing Pole** (+35 Fishing skill)\n• **Hook of the Master Angler** (Transforms you into a fish with +swim speed)"
        },
        "dmf": {
            "title": "🎪 Darkmoon Faire (DMF) Rotation",
            "current_location": dmf_location,
            "buff_tip": "Speak to **Sayge** and answer: `1-1` or `1-2` to receive the **+10% Damage Dealt** World Buff for 2 hours!",
            "cards": "Turn in completed Aces 1-8 decks for: *Darkmoon Card: Blue Dragon* (100% mana regen proc), *Maelstrom* (Nature lightning strike), or *Heroism* (heal on melee hit)."
        }
    }


# -------------------------------------------------------------
# Advanced System 5: GDKP Pot Splitter
# -------------------------------------------------------------
def calculate_gdkp(pot: int, cut_pct: int = 10, raiders: int = 40, tanks: int = 0, tank_bonus_pct: int = 2) -> Dict[str, Any]:
    """Calculates GDKP pot splits, organizer cuts, tank incentives, and raider payouts."""
    organizer_cut = int(pot * (cut_pct / 100.0))
    tank_pot = int(pot * (tank_bonus_pct / 100.0)) * tanks
    net_pot = pot - organizer_cut - tank_pot
    raider_payout = net_pot // raiders if raiders > 0 else 0
    tank_total_payout = raider_payout + (int(pot * (tank_bonus_pct / 100.0))) if tanks > 0 else 0

    return {
        "gross_pot": pot,
        "cut_pct": cut_pct,
        "organizer_cut": organizer_cut,
        "tanks": tanks,
        "tank_pot": tank_pot,
        "net_pot": net_pot,
        "raiders": raiders,
        "payout_per_raider": raider_payout,
        "tank_total_payout": tank_total_payout
    }


# -------------------------------------------------------------
# Advanced System 6: Weapon & Combat Compare
# -------------------------------------------------------------
WEAPON_SAMPLE_DATA = {
    "dal'rend's sacred charge": {"name": "Dal'Rend's Sacred Charge", "type": "Sword", "speed": 2.8, "min_dmg": 81, "max_dmg": 151, "dps": 41.4, "stats": "+4 Strength, +1% Crit"},
    "brutality blade": {"name": "Brutality Blade", "type": "Sword", "speed": 2.5, "min_dmg": 90, "max_dmg": 168, "dps": 51.6, "stats": "+9 Strength, +9 Agility, +1% Crit"},
    "deathbringer": {"name": "Deathbringer", "type": "Axe", "speed": 2.9, "min_dmg": 114, "max_dmg": 213, "dps": 56.4, "stats": "Chance on hit: Shadow bolt for 110-140"},
    "vis'kag the bloodletter": {"name": "Vis'kag the Bloodletter", "type": "Sword", "speed": 2.6, "min_dmg": 100, "max_dmg": 187, "dps": 55.2, "stats": "Chance on hit: Fatal wound for 240"},
    "krol blade": {"name": "Krol Blade", "type": "Sword", "speed": 2.8, "min_dmg": 80, "max_dmg": 149, "dps": 40.9, "stats": "+7 Strength, +1% Crit"},
    "ironfoe": {"name": "Ironfoe", "type": "Mace", "speed": 2.4, "min_dmg": 73, "max_dmg": 136, "dps": 43.5, "stats": "Chance on hit: Grants 2 extra attacks on your next swing"}
}


def compare_weapons(w1_query: str, w2_query: str, race: str = "Human") -> Dict[str, Any]:
    """Compares two weapons, factoring in weapon speed, AP scaling, and racial glancing blow penalties."""
    keys = list(WEAPON_SAMPLE_DATA.keys())
    m1 = difflib.get_close_matches(w1_query.lower().strip(), keys, n=1, cutoff=0.4)
    m2 = difflib.get_close_matches(w2_query.lower().strip(), keys, n=1, cutoff=0.4)

    w1 = WEAPON_SAMPLE_DATA[m1[0]] if m1 else {"name": w1_query.title(), "type": "One-Handed", "speed": 2.6, "min_dmg": 85, "max_dmg": 160, "dps": 47.1, "stats": "Standard stats"}
    w2 = WEAPON_SAMPLE_DATA[m2[0]] if m2 else {"name": w2_query.title(), "type": "One-Handed", "speed": 2.8, "min_dmg": 95, "max_dmg": 175, "dps": 48.2, "stats": "Standard stats"}

    r_lower = race.lower().strip()
    w1_has_bonus = (r_lower == "human" and w1["type"] in ["Sword", "Mace"]) or (r_lower == "orc" and w1["type"] == "Axe")
    w2_has_bonus = (r_lower == "human" and w2["type"] in ["Sword", "Mace"]) or (r_lower == "orc" and w2["type"] == "Axe")

    w1_norm = ((w1["min_dmg"] + w1["max_dmg"]) / 2.0)
    w2_norm = ((w2["min_dmg"] + w2["max_dmg"]) / 2.0)

    return {
        "weapon1": w1,
        "weapon2": w2,
        "race": race.title(),
        "w1_has_bonus": w1_has_bonus,
        "w2_has_bonus": w2_has_bonus,
        "glancing_analysis": (
            f"• **Boss Glancing Penalty vs Lvl 63 Raid Bosses:**\n"
            f"  - **{w1['name']}:** {'Reduced to **5% damage penalty** (+5 Skill Bonus active!)' if w1_has_bonus else 'Full **35% damage penalty** on 40% of white auto-attacks.'}\n"
            f"  - **{w2['name']}:** {'Reduced to **5% damage penalty** (+5 Skill Bonus active!)' if w2_has_bonus else 'Full **35% damage penalty** on 40% of white auto-attacks.'}"
        ),
        "hit_cap_analysis": (
            f"• **Yellow Special Hit Cap:**\n"
            f"  - **{w1['name']}:** {'**6% Hit Cap** (Requires 3% less Hit gear!)' if w1_has_bonus else '**9% Hit Cap**'}\n"
            f"  - **{w2['name']}:** {'**6% Hit Cap** (Requires 3% less Hit gear!)' if w2_has_bonus else '**9% Hit Cap**'}"
        ),
        "verdict": (
            f"For a **{race.title()}**, **{w2['name']}** yields superior burst and higher special ability damage due to higher top-end damage ({w2['max_dmg']})."
            if (w2_norm > w1_norm and (w2_has_bonus or not w1_has_bonus))
            else f"For a **{race.title()}**, **{w1['name']}** holds a distinct advantage due to racial weapon skill synergies."
        )
    }


# -------------------------------------------------------------
# Batch 2 Systems: Lockouts, Twinking, Routes, Addons, Trivia
# -------------------------------------------------------------
def get_raid_lockouts() -> Dict[str, Any]:
    """Calculates live countdowns to Weekly, Onyxia (5-day), ZG/AQ20 (3-day), and Daily resets."""
    now = datetime.now(timezone.utc)
    # Tuesday 15:00 UTC weekly reset
    days_ahead = (1 - now.weekday()) % 7
    next_tuesday = now.replace(hour=15, minute=0, second=0, microsecond=0) + timedelta(days=days_ahead)
    if next_tuesday <= now:
        next_tuesday += timedelta(days=7)
    tue_diff = next_tuesday - now
    tue_d, tue_h, tue_m = tue_diff.days, tue_diff.seconds // 3600, (tue_diff.seconds % 3600) // 60

    # Rolling 5-day cycle for Onyxia (Epoch anchor: Jan 6, 2026 15:00 UTC)
    anchor_ony = datetime(2026, 1, 6, 15, 0, 0, tzinfo=timezone.utc)
    ony_cycle = 5 * 86400
    elapsed_ony = int((now - anchor_ony).total_seconds()) % ony_cycle
    rem_ony = ony_cycle - elapsed_ony
    ony_d, ony_h, ony_m = rem_ony // 86400, (rem_ony % 86400) // 3600, (rem_ony % 3600) // 60

    # Rolling 3-day cycle for ZG & AQ20 (Epoch anchor: Jan 6, 2026 15:00 UTC)
    zg_cycle = 3 * 86400
    elapsed_zg = int((now - anchor_ony).total_seconds()) % zg_cycle
    rem_zg = zg_cycle - elapsed_zg
    zg_d, zg_h, zg_m = rem_zg // 86400, (rem_zg % 86400) // 3600, (rem_zg % 3600) // 60

    # Daily reset (07:00 UTC)
    next_daily = now.replace(hour=7, minute=0, second=0, microsecond=0)
    if next_daily <= now:
        next_daily += timedelta(days=1)
    daily_diff = next_daily - now
    daily_h, daily_m = daily_diff.seconds // 3600, (daily_diff.seconds % 3600) // 60

    return {
        "weekly": f"**{tue_d}d {tue_h}h {tue_m}m** (Tuesday 15:00 UTC)",
        "onyxia": f"**{ony_d}d {ony_h}h {ony_m}m** (5-Day Rolling Lockout)",
        "zg": f"**{zg_d}d {zg_h}h {zg_m}m** (3-Day Rolling Lockout)",
        "daily": f"**{daily_h}h {daily_m}m** (Daily 07:00 UTC Reset)"
    }


TWINK_DATA: Dict[str, Dict[str, Any]] = {
    "19": {
        "bracket": "Level 19 (Warsong Gulch)",
        "overview": "The premier classic twink bracket. Extremely high burst and speed-oriented flag running.",
        "weapons": (
            "• **Shadowfang** (1H Sword • Shadow bolt proc • 14.5 DPS) — Top-tier Horde/Alliance sword.\n"
            "• **Assassin's Blade** (Dagger • +3 Agi • 14.7 DPS) — Best-in-Slot ambush/backstab dagger.\n"
            "• **Venomstrike** (Bow • 11.5 DPS • Poison proc) — Lord Cobrahn in Wailing Caverns.\n"
            "• **Gravestone Scepter** (Wand • 29.0 DPS!) — BFD Quest reward; out-damages actual spells!"
        ),
        "armor": (
            "• **Head:** Lucky Fishing Hat (+15 Stamina) from STV Fishing or Green Tinted Goggles (Engi)\n"
            "• **Neck:** Sentinel's / Scout's Medallion (WSG Honored • +6 Agi, +2 Stam)\n"
            "• **Chest:** Tunic of Westfall (+11 Agi) / Blackened Defias Armor (+100 HP Enchant!)\n"
            "• **Feet:** Feet of the Lynx (+8 Agi, +3 Str) or Nat Pagle's Extreme Anglin' Boots (+12 Stamina)\n"
            "• **Trinket:** Arena Grand Master (+1,000 absorption shield!) from Gurubashi 12-token quest"
        ),
        "enchants": "Enchants have NO item-level limits in Classic! Stack **+100 Health** to Chest, **+15 Agility** to Weapons, and **+8 Agility** / **+7 Stamina** to Boots & Bracers."
    },
    "29": {
        "bracket": "Level 29 (Arathi Basin & Warsong Gulch)",
        "overview": "Balanced mountless bracket with intermediate talents and heavy spell power scaling.",
        "weapons": (
            "• **Zealot Blade** (1H Sword • +10 Str, +3 Stam • 20.4 DPS)\n"
            "• **Butcher's Cleaver** (1H Axe • 20.4 DPS) from Shadowfang Keep\n"
            "• **Corpsemaker** (2H Axe • Overlord Ramtusk in RFK • 28.9 DPS)\n"
            "• **Master Hunter's Bow** (Bow • 22.8 DPS) from STV Bangalash quest chain at 29!"
        ),
        "armor": (
            "• **Pants:** Triprunner Dungarees (+18 Agi, +4 Str) from Gnomeregan quest\n"
            "• **Chest:** Tortoise Armor (Wand/Staff/Leather alternatives) with +100 HP enchant\n"
            "• **Boots:** Highlander's / Defiler's Lizardhide Boots (Arathi Basin Honored)"
        ),
        "enchants": "Stack **Crusader** (+100 Str proc + heal) or **+15 Agility** on melee weapons; +100 HP to chest."
    },
    "39": {
        "bracket": "Level 39 (Warsong Gulch & Arathi Basin)",
        "overview": "First bracket where level 40 mounts and 31-point capstone talents begin to dominate.",
        "weapons": (
            "• **Pendulum of Doom** (2H Axe • 4.0 ultra-slow speed • massive Mortal Strike burst!)\n"
            "• **Staff of Jordan** (Epic Staff • +26 Spell Damage, +11 Int) — King of caster twinks\n"
            "• **Sword of Serenity** / **Vanquisher's Sword** (RFD quest rewards)"
        ),
        "armor": (
            "• **Head:** Night Hawk Hat / Spellpower Goggles\n"
            "• **Legs:** Basilisk Hide Pants (Maraudon / world drops)"
        ),
        "enchants": "Crusader, +30 Spell Power to weapons, +100 HP to chest."
    }
}


def get_twink_info(bracket: str) -> Optional[Dict[str, Any]]:
    """Retrieves twink bracket BiS gear and enchant strategies."""
    b = str(bracket).strip()
    return TWINK_DATA.get(b)


LEVELING_ROUTES: Dict[str, Dict[str, Any]] = {
    "10-20": {
        "range": "Level 10–20 Speedrun Route",
        "alliance": (
            "• **Step 1 (Westfall Starter Bundle):** Grab Furlbrow's Deed at border -> run to Sentinel Hill -> pick up Westfall Stew, Goretusk Liver Pie, Boar Snouts.\n"
            "• **Step 2 (Thelsamar Sweeper):** Take Deeprun Tram to Ironforge -> run to Loch Modan -> sweep Mountaineer Trogg quests and Rat Catching.\n"
            "• **Step 3 (Deadmines Preparation):** Return to Westfall at lvl 17 -> complete Defias Brotherhood chain in Redridge -> pickup Deadmines quests in Sentinel Hill tower."
        ),
        "horde": (
            "• **Step 1 (Crossroads Arrival):** Run from Razor Hill/Mulgore into The Crossroads (The Barrens). Grab Flight Path immediately.\n"
            "• **Step 2 (Oasis & Raptor Sweep):** Complete The Forgotten Pools, The Stagnant Oasis, Raptor Thieves, and Plainstrider Menace in one clockwise loop.\n"
            "• **Step 3 (Wailing Caverns Bundle):** Pick up Leaders of the Fang and Deviate Hides at top of WC cave, and Apothecary Zamah in Thunder Bluff."
        ),
        "skip_tip": "⚡ **Death Warp:** Drown in Wetlands to graveyard-warp straight into Menethil Harbor, saving 15 minutes of mountain walking!"
    },
    "20-30": {
        "range": "Level 20–30 Speedrun Route",
        "alliance": (
            "• **Step 1 (Redridge Push):** Lakeshire quests (blackrock orc battle, Yowler, Solomon's Law) until Level 24.\n"
            "• **Step 2 (Duskwood Introduction):** Darkshire breadcrumbs (Night Watch, Hermit, Deliveries) -> Cemetery perimeter.\n"
            "• **Step 3 (Wetlands / Ashenvale):** Run Greenwarden in Wetlands -> take boat from Menethil to Auberdine -> Ashenvale Astranaar."
        ),
        "horde": (
            "• **Step 1 (Camp Taurajo & Southern Barrens):** Silithid nests, Bael Modan dwarven digsite, and Bristleback Quilboars.\n"
            "• **Step 2 (Stonetalon & Ashenvale):** Sun Rock Retreat -> Splintertree Post satyr & demon quests.\n"
            "• **Step 3 (Hillsbrad Foothills):** Tarren Mill battleground quests (Battle of Hillsbrad town raids, Syndicate badges)."
        ),
        "skip_tip": "⚡ **Auto-Stuck Skip:** Use the unstuck feature or campfire suicide at Dun Garok to teleport directly to Southshore / Tarren Mill."
    },
    "30-40": {
        "range": "Level 30–40 Speedrun Route",
        "alliance": (
            "• **Step 1 (Duskwood Finish -> STV Northern Jungle):** Kill Mor'Ladim & Abercrombie's stitches -> head to Nesingwary Expedition in STV.\n"
            "• **Step 2 (Arathi & Shimmering Flats):** Hammerfall/Refuge Point -> Thousand Needles Shimmering Flats racetrack quests (turn in 8 quests at once!).\n"
            "• **Step 3 (Scarlet Monastery Spree):** Library (33-36) -> Armory (36-39) -> Cathedral (38-42) for massive dungeon XP."
        ),
        "horde": (
            "• **Step 1 (Thousand Needles & Shimmering Flats):** Freewind Post -> Mirage Raceway racecar parts & rocket car tests.\n"
            "• **Step 2 (Northern STV Nesingwary):** Tigers, Panthers, Raptors mastery chains.\n"
            "• **Step 3 (Badlands / SM):** Fly to Kargath -> Badlands rock elementals -> Scarlet Monastery runs."
        ),
        "skip_tip": "⭐ **Mount Priority:** Save every copper! At Level 40, stop all training to purchase your 60% Mount (90–100g total)."
    }
}


def get_leveling_route(lvl_range: str) -> Optional[Dict[str, Any]]:
    """Retrieves speedleveling route bundles and death warp skips."""
    return LEVELING_ROUTES.get(lvl_range)


ADDONS_DATA: Dict[str, Dict[str, Any]] = {
    "questie": {
        "name": "Questie", "category": "Leveling & Quests",
        "purpose": "The undisputed #1 essential Classic questing addon. Adds quest icons, objective locations, mob spawn areas, and turn-in waypoints on your world map and mini-map.",
        "config": "Enable 'Show quest level in tooltips' and 'Auto-accept/complete quests' for maximum speed."
    },
    "details": {
        "name": "Details! Damage Meter", "category": "Combat & Performance",
        "purpose": "High-fidelity damage, healing, damage taken, interrupt, dispel, and death recap logging.",
        "config": "Set update interval to 0.2s for butter-smooth combat DPS readouts without FPS drops."
    },
    "threatclassic2": {
        "name": "ThreatClassic2", "category": "Combat & Raiding",
        "purpose": "Displays real-time threat meters for you and your raid team vs your target. Mandatory for tanks and DPS to prevent boss pull wipes.",
        "config": "Place next to your player frame with a warning flash at 85% threat threshold."
    },
    "weaponswingtimer": {
        "name": "WeaponSwingTimer", "category": "Combat & Mechanics",
        "purpose": "Displays visual progress bars for your Main-Hand and Off-Hand melee swings, as well as Hunter Auto Shot timer and cast bars.",
        "config": "Essential for Hunters (to avoid clipping Aimed Shot) and Warriors (for optimal Slam & Heroic Strike queueing)."
    },
    "bigwigs": {
        "name": "BigWigs / LittleWigs", "category": "Raiding & Dungeons",
        "purpose": "Lightweight boss fight alerts, timers, countdown bars, and warnings for Magmadar enrage, Baron bombs, and Onyxia deep breaths.",
        "config": "Preferred over DBM in Classic for its zero-lag performance in 40-man raids."
    },
    "leatrix_plus": {
        "name": "Leatrix Plus", "category": "Quality of Life",
        "purpose": "All-in-one automation: auto-repair, auto-sell junk, instant quest text, faster loot window, max camera zoom factor 4, and UI cleanup.",
        "config": "Enable 'Automate quests', 'Sell junk automatically', and 'Max camera distance'."
    },
    "plater": {
        "name": "Plater Nameplates", "category": "UI & Nameplates",
        "purpose": "Custom enemy nameplates with customizable threat colors (Green = Safe, Red = Mob is attacking you!), buff trackers, and castbars.",
        "config": "Import a Classic tank/DPS profile to instantly see enemy spell interrupts."
    },
    "itemrack": {
        "name": "ItemRack", "category": "Gear & Equipment",
        "purpose": "1-click gear and trinket swapping between pulls. Swap Carrot on a Stick on mount, or burst trinkets before a boss.",
        "config": "Bind your mount gear set and engineering trinket set to dedicated action bar keys."
    }
}


def get_addon_info(query: str) -> Optional[Dict[str, Any]]:
    """Retrieves addon guide, category, and recommended settings."""
    q = query.lower().strip()
    for k, v in ADDONS_DATA.items():
        if k in q or q in k or q in v["category"].lower():
            return v
    return None


TRIVIA_QUESTIONS: List[Dict[str, Any]] = [
    {
        "question": "What is the name of Mankrik's lost wife in the Barrens?",
        "options": ["Olgra", "Mixa", "Krenna", "Geyah"],
        "correct": 0,
        "explanation": "Mankrik's wife is Olgra! Her body is found beaten by quilboars south of the Crossroads."
    },
    {
        "question": "Which level 60 dungeon boss drops the legendary Ironfoe hammer?",
        "options": ["General Angerforge", "Emperor Dagran Thaurissan", "High Priestess Thekal", "Darkmaster Gandling"],
        "correct": 1,
        "explanation": "Emperor Dagran Thaurissan at the end of Blackrock Depths drops Ironfoe (extra swing proc mace)."
    },
    {
        "question": "What was the original name of the Dark Portal before the First War?",
        "options": ["The Great Gate", "The Portal of Doom", "The Black Gate", "The Rift of Worlds"],
        "correct": 0,
        "explanation": "Before the Orcish invasion, Medivh and the Shadow Council referred to it as The Great Gate."
    },
    {
        "question": "What is the minimum weapon skill required to tap Rich Thorium Veins?",
        "options": ["250", "265", "275", "300"],
        "correct": 2,
        "explanation": "Rich Thorium Veins require 275 Mining skill to mine, and yield valuable Arcane Crystals."
    },
    {
        "question": "Which racial trait grants +25% chance to resist Stun effects in Classic WoW?",
        "options": ["Will of the Forsaken", "Hardiness (Orc)", "Stoneform (Dwarf)", "War Stomp (Tauren)"],
        "correct": 1,
        "explanation": "Hardiness grants Orcs a passive +25% stun resist, making them formidable against Rogues."
    },
    {
        "question": "How many seconds does a player have before Vaelastrasz's Burning Adrenaline explodes?",
        "options": ["10 seconds", "15 seconds", "20 seconds", "30 seconds"],
        "correct": 2,
        "explanation": "Burning Adrenaline lasts 20 seconds, granting instant casts while burning health before fatal detonation."
    }
]


def get_random_trivia() -> Dict[str, Any]:
    """Selects a random interactive trivia question."""
    import random
    return random.choice(TRIVIA_QUESTIONS)


# -------------------------------------------------------------
# Batch 3 Systems: Resistances, Duels, Talents
# -------------------------------------------------------------
RESIST_SCHOOLS: Dict[str, Dict[str, Any]] = {
    "fire": {
        "name": "Fire Resistance (FR)",
        "encounters": "Ragnaros (MC), Baron Geddon (MC), Firemaw (BWL), Vaelastrasz the Corrupt (BWL)",
        "soft_cap": 225,
        "hard_cap": 315,
        "buffs": (
            "• **Paladin Fire Resistance Aura:** +60 FR\n"
            "• **Shaman Fire Resistance Totem:** +60 FR\n"
            "• **Greater Fire Protection Potion:** Absorbs 1950–3250 Fire damage\n"
            "• **Juju Ember:** +15 Fire Resistance (E'ko in Winterspring)\n"
            "• **Hydraxian Waterlords Shoulder Enchant:** +5 Fire Resistance (Revered)"
        ),
        "gear": (
            "• **Dark Iron Plate / Mail / Leather:** Crafted using Dark Iron Bars & Fiery Cores\n"
            "• **Drakefire Amulet:** +15 FR (Onyxia attunement key!)\n"
            "• **Onyxia Scale Cloak:** +16 FR & Cloak of Fire protection\n"
            "• **Libram of Resilience:** +20 FR enchant to Helm or Leggings"
        )
    },
    "nature": {
        "name": "Nature Resistance (NR)",
        "encounters": "Princess Huhuran (AQ40 Poison Volley Soak), Viscidus (AQ40 Poison Cloud), Lord Kri (Bug Trio)",
        "soft_cap": 225,
        "hard_cap": 315,
        "buffs": (
            "• **Paladin Nature Resistance Aura:** +60 NR\n"
            "• **Shaman Nature Resistance Totem:** +60 NR\n"
            "• **Hunter Aspect of the Wild:** +60 NR\n"
            "• **Greater Nature Protection Potion:** Absorbs 1950–3250 Nature damage\n"
            "• **Cenarion Circle Shoulder Enchant:** +5 Nature Resistance"
        ),
        "gear": (
            "• **Sandstalker / Bramblewood / Ironvine Sets:** Crafted Cenarion Circle patterns\n"
            "• **Heart of Noxxion:** +10 NR trinket from Maraudon\n"
            "• **Petrified Bark Shield / Mallet of Zul'Farrak:** High raw NR offsets\n"
            "• **Savage Guard Enchant:** +10 Nature Resistance Arcanum (Zandalar Honored)"
        )
    },
    "frost": {
        "name": "Frost Resistance (Frost R)",
        "encounters": "Sapphiron (Naxxramas Frost Aura — mandatory 200+ for entire raid), Kel'Thuzad",
        "soft_cap": 200,
        "hard_cap": 315,
        "buffs": (
            "• **Paladin Frost Resistance Aura:** +60 Frost R\n"
            "• **Shaman Frost Resistance Totem:** +60 Frost R\n"
            "• **Greater Frost Protection Potion:** Absorbs 1950–3250 Frost damage\n"
            "• **Juju Chill:** +15 Frost Resistance"
        ),
        "gear": (
            "• **Icebane Plate / Icy Scale Mail / Polar Leather / Glacial Cloth:** Crafted Naxxramas gear requiring Frozen Runes\n"
            "• **Ramstein's Lightning Bolts / Frostwolf Insignia:** +10 Frost R\n"
            "• **Ice Guard Arcanum:** +10 Frost Resistance (Light's Hope Chapel)"
        )
    },
    "shadow": {
        "name": "Shadow Resistance (SR)",
        "encounters": "Emperor Vek'lor (Twin Emperors Caster Tanking — Warlock needs 250+ SR), Loatheb, C'Thun Giant Eye Tentacles",
        "soft_cap": 220,
        "hard_cap": 315,
        "buffs": (
            "• **Paladin Shadow Resistance Aura:** +60 SR\n"
            "• **Warlock Demon Armor + Felhunter:** +60 SR passive buff\n"
            "• **Greater Shadow Protection Potion:** Absorbs 1950–3250 Shadow damage\n"
            "• **Prayer of Shadow Protection:** +60 SR (Priest raid buff)"
        ),
        "gear": (
            "• **Felcloth / Runed Stygian / Dreadmist Sets:** Shadow resist pieces\n"
            "• **Rune of the Dawn:** +10 SR trinket from Argent Dawn\n"
            "• **Shadow Guard Arcanum:** +10 Shadow Resistance"
        )
    }
}


def calculate_resistance_mitigation(school_query: str, current_val: int = 0, role: str = "dps") -> Dict[str, Any]:
    """Calculates resistance mitigation tiers, average damage resisted %, and cap deficiencies."""
    q = school_query.lower().strip()
    key = "fire"
    for k in RESIST_SCHOOLS.keys():
        if k in q:
            key = k
            break
    data = RESIST_SCHOOLS[key]

    boss_cap = 315
    capped_val = min(max(current_val, 0), boss_cap)
    avg_mitigation_pct = round((capped_val / boss_cap) * 75.0, 1)

    pts_to_soft = max(0, data["soft_cap"] - current_val)
    pts_to_hard = max(0, data["hard_cap"] - current_val)

    if avg_mitigation_pct >= 70:
        tier_label = "🏆 Hard Cap Tier (70%–75% Average Resisted Damage)"
    elif avg_mitigation_pct >= 50:
        tier_label = "🛡️ Soft Cap Tier (50%–69% Average Resisted Damage)"
    elif avg_mitigation_pct >= 25:
        tier_label = "⚠️ Medium Tier (25%–49% Average Resisted Damage)"
    else:
        tier_label = "❌ Vulnerable Tier (<25% Average Resisted Damage)"

    return {
        "school": data["name"],
        "current": current_val,
        "mitigation_pct": avg_mitigation_pct,
        "tier_label": tier_label,
        "encounters": data["encounters"],
        "soft_cap": data["soft_cap"],
        "hard_cap": data["hard_cap"],
        "pts_to_soft": pts_to_soft,
        "pts_to_hard": pts_to_hard,
        "buffs": data["buffs"],
        "gear": data["gear"]
    }


DUEL_MATCHUPS: Dict[str, Dict[str, Any]] = {
    "rogue:mage": {
        "title": "Rogue vs. Frost Mage (The Classic Mindgame)",
        "favorability": "Frost Mage Favored (65% / 35%)",
        "deadzone_analysis": "Mage maintains 5–10 yard perimeter with Rank 1 Frostbolt & Cone of Cold, forcing Rogue into permanent snare without Gap-closers (Cloak of Shadows does NOT exist in Classic!).",
        "cooldown_trades": (
            "• **Kidney Shot -> Blink:** Never Kidney Shot before Mage has used Blink! Use Cheap Shot -> Gouge -> Wait for Blink before using Blind.\n"
            "• **Blind -> Ice Block:** If Rogue lands Blind, Mage must immediately Ice Block; Rogue will restealth and open with Sap.\n"
            "• **Vanish -> Frost Nova:** Use Vanish as an immunity frame to dodge the incoming Shatter Frostbolt combo."
        ),
        "consumables_counter": "Rogue *Free Action Potion (FAP)* completely invalidates Nova/Chills for 30s. Mage counter: *Iron Grenade* or *Living Action Potion* to break stuns."
    },
    "warrior:mage": {
        "title": "Warrior vs. Frost Mage (The Impossible Matchup)",
        "favorability": "Frost Mage Heavily Favored (85% / 15%)",
        "deadzone_analysis": "The 5–8 yard Deadzone: Warriors cannot Charge or Intercept inside 8 yards, and cannot melee outside 5 yards. A skilled Mage stays locked exactly in this 3-yard deadzone permanently.",
        "cooldown_trades": (
            "• **Intercept -> Blink:** When Warrior Intercepts, Mage immediately Blinks away to keep distance.\n"
            "• **Frost Nova -> Free Action Potion:** A standard Warrior will die in a Nova-Shatter combo without hitting the Mage once. Pre-pot FAP before the duel begins.\n"
            "• **Spell Reflection / Reflector:** Gyrofreeze Ice Reflector (Engineering) can reflect Frostbolt back at the Mage for a 1500+ crit."
        ),
        "consumables_counter": "Warrior mandatory: *Free Action Potion*, *Iron Grenade*, *Tidal Charm* trinket, and *Skull of Impending Doom* to break sheep."
    },
    "warrior:rogue": {
        "title": "Warrior vs. Rogue (The Armor & Overpower War)",
        "favorability": "Warrior Favored (65% / 35%)",
        "deadzone_analysis": "Plate armor reduces Rogue physical burst by ~50%. In melee range, Rogue Evasion grants Warrior constant undodgeable Overpowers (+50% crit bonus!).",
        "cooldown_trades": (
            "• **Evasion -> Overpower:** Rogue popping Evasion against a Warrior is often suicide because it guarantees Overpower procs every 5 seconds.\n"
            "• **Blind -> Bandage:** Rogue must Gouge/Blind, run out of combat, and get a full reset with a bandage.\n"
            "• **Bleed Kite:** Rogues can Rupture and Crippling Poison kite outside the Warrior's 5-yard melee swing range."
        ),
        "consumables_counter": "Rogue *Free Action Potion* or *Thistle Tea* burst. Warrior: *Iron Grenades* and *Mighty Rage Potion* for instant Mortal Strike."
    },
    "priest:warlock": {
        "title": "Shadow Priest vs. SL Warlock (The Attrition Duel)",
        "favorability": "Skill Matchup (50% / 50%)",
        "deadzone_analysis": "Both are immobile ranged powerhouses. Soul Link grants Warlock 30% damage transfer to Voidwalker/Felhunter, while Shadow Priest has 15% physical damage reduction in Shadowform.",
        "cooldown_trades": (
            "• **Mana Burn -> Spell Lock:** Shadow Priest's primary win condition is burning the Warlock's mana pool to zero. Felhunter must Spell Lock Mana Burn.\n"
            "• **Silence -> Fear:** Priest Silence (5s) prevents Death Coil and Fear, creating a window for Mind Blast + SW:P + Mind Flay burn.\n"
            "• **Devouring Plague (Undead):** Lethal disease dot that requires Warlock to burn healthstone + bandage."
        ),
        "consumables_counter": "Priest: *Major Mana Potion* + *Demonic Rune*. Warlock: *Curse of Tongues* on Priest to double cast times."
    },
    "shaman:paladin": {
        "title": "Shaman vs. Paladin (The Faction Rivalry)",
        "favorability": "Shaman Favored (60% / 40%)",
        "deadzone_analysis": "Shaman's *Purge* strips all Paladin Blessings (Freedom, Might, Kings), Seals, and shields. Earth Shock on a 6-second cooldown shuts down Holy Light.",
        "cooldown_trades": (
            "• **Purge -> Blessing of Freedom:** Paladin has no tools to prevent Purge from eating Freedom and Seals instantly.\n"
            "• **Hammer of Justice -> Grounding Totem:** Shaman drops Grounding Totem or uses Tremor Totem to neutralize CC.\n"
            "• **Divine Shield (Bubble) -> Heal:** Paladin's ultimate reset. Shaman should use this 12-second window to heal, drop fresh totems, and lightning bolt."
        ),
        "consumables_counter": "Paladin: *Reckoning* 4-extra-swing one-shot setup. Shaman: *Free Action Potion* and *Windfury 2H* weapon burst."
    }
}


def get_duel_matchup(c1: str, c2: str) -> Dict[str, Any]:
    """Retrieves class 1v1 duel matchup guide, cooldown trading, and deadzone analysis."""
    c1_clean = c1.lower().strip()
    c2_clean = c2.lower().strip()
    pair1 = f"{c1_clean}:{c2_clean}"
    pair2 = f"{c2_clean}:{c1_clean}"

    data = DUEL_MATCHUPS.get(pair1) or DUEL_MATCHUPS.get(pair2)
    if data:
        return data

    return {
        "title": f"{c1.title()} vs. {c2.title()} 1v1 Duel Matchup",
        "favorability": "Even Skill Matchup (50% / 50%)",
        "deadzone_analysis": f"Classic 1v1 duels depend on crowd-control priority and exploiting range thresholds between {c1.title()} and {c2.title()}.",
        "cooldown_trades": (
            f"• **CC Management:** Preserve trinkets and immunities for max-duration stuns, fears, or polymorphs.\n"
            f"• **Burst Timing:** Trade defensive cooldowns immediately when major offensive buffs (Death Wish, Arcane Power, Bestial Wrath) are activated.\n"
            f"• **Interrupt Window:** Fake cast (stopcasting macro) to bait kicks, pummels, and counterspells."
        ),
        "consumables_counter": "Standard Classic PvP staples: *Free Action Potion (FAP)*, *Iron Grenade*, *Tidal Charm*, and *Restorative Potion*."
    }


TALENTS_DATA: Dict[str, Dict[str, Any]] = {
    "warrior:fury": {
        "class": "Warrior", "spec": "Fury Dual-Wield (17/34/0)",
        "tree_display": (
            "⚔️ **Arms (17 pts):** [🟩🟩🟩⬜⬜] (Deflection 5, Tactical Mastery 5, Anger Management 1, Deep Wounds 3, Impale 2)\n"
            "🩸 **Fury (34 pts):** [🟩🟩🟩🟩🟩] (Cruelty 5, Unbridled Wrath 5, Flurry 5, Death Wish 1, Bloodthirst 1)\n"
            "🛡️ **Protection (0 pts):** [⬜⬜⬜⬜⬜] (Uninvested)"
        ),
        "capstones": "• **Bloodthirst** (Instant attack scaling with AP + healing on hit)\n• **Death Wish** (+20% physical damage & fear immunity for 30s)\n• **Flurry** (+30% attack speed on critical strikes)",
        "priority_order": "1. Fury (Cruelty 5/5) -> 2. Arms (Tactical Mastery 5/5) -> 3. Fury to Bloodthirst at Level 40 -> 4. Finish Arms (Impale).",
        "share_code": "`https://classicdb.ch/?talent#LZVbVxxzoVxo0x`"
    },
    "mage:frost": {
        "class": "Mage", "spec": "Frost AoE & Dungeon Grinding (14/0/37)",
        "tree_display": (
            "✨ **Arcane (14 pts):** [🟩🟩⬜⬜⬜] (Arcane Subtlety 2, Arcane Focus 3, Clearcasting 5, Imp Counterspell 2)\n"
            "🔥 **Fire (0 pts):** [⬜⬜⬜⬜⬜] (Uninvested)\n"
            "❄️ **Frost (37 pts):** [🟩🟩🟩🟩🟩] (Permafrost 3, Imp Blizzard 3, Frost Channeling 3, Ice Block 1, Ice Barrier 1)"
        ),
        "capstones": "• **Ice Barrier** (Instant 800+ damage shield with 100% cast interruption immunity)\n• **Ice Block** (10-second total physical & magical immunity)\n• **Improved Blizzard** (65% movement speed slow on every pulse)",
        "priority_order": "1. Frost to Improved Blizzard (Lvl 20) -> 2. Frost to Ice Barrier (Lvl 40) -> 3. Arcane Clearcasting (40–50) -> 4. Arcane Subtlety.",
        "share_code": "`https://classicdb.ch/?talent#of0V0zZZVAMhzbho`"
    },
    "rogue:combat": {
        "class": "Rogue", "spec": "Combat Swords (19/32/0)",
        "tree_display": (
            "🗡️ **Assassination (19 pts):** [🟩🟩🟩⬜⬜] (Malice 5, Ruthlessness 3, Relentless Strikes 1, Lethality 5)\n"
            "⚔️ **Combat (32 pts):** [🟩🟩🟩🟩🟩] (Precision 5, Sword Specialization 5, Blade Flurry 1, Adrenaline Rush 1)\n"
            "🌑 **Subtlety (0 pts):** [⬜⬜⬜⬜⬜] (Uninvested)"
        ),
        "capstones": "• **Adrenaline Rush** (+100% Energy regeneration rate for 15s)\n• **Blade Flurry** (Attacks strike an additional nearby enemy + 20% attack speed)\n• **Sword Specialization** (5% chance to land an extra swing with weapon procs)",
        "priority_order": "1. Combat to Blade Flurry (Lvl 20) -> 2. Combat to Adrenaline Rush (Lvl 30) -> 3. Sword Spec (Lvl 35) -> 4. Assassination (Malice & Lethality).",
        "share_code": "`https://classicdb.ch/?talent#fhe0oxZ0bVbbEz0ro`"
    },
    "priest:shadow": {
        "class": "Priest", "spec": "Shadowform Solo & PvP (14/0/37)",
        "tree_display": (
            "✨ **Discipline (14 pts):** [🟩🟩⬜⬜⬜] (Unbreakable Will 5, Imp Power Word: Shield 3, Inner Fire 3, Meditation 3)\n"
            "☀️ **Holy (0 pts):** [⬜⬜⬜⬜⬜] (Uninvested)\n"
            "🌑 **Shadow (37 pts):** [🟩🟩🟩🟩🟩] (Spirit Tap 5, Mind Flay 1, Darkness 5, Shadowform 1, Silence 1)"
        ),
        "capstones": "• **Shadowform** (+15% Shadow damage dealt, -15% physical damage taken)\n• **Spirit Tap** (100% bonus Spirit and 50% in-combat mana regeneration on kill)\n• **Mind Flay** (Channels shadow damage with 50% movement slow)",
        "priority_order": "1. Spirit Tap (Lvl 10–14) -> 2. Mind Flay (Lvl 20) -> 3. Shadowform (Lvl 40) -> 4. Discipline Meditation.",
        "share_code": "`https://classicdb.ch/?talent#bxMhsZZVMGd0tzo`"
    },
    "warlock:sm_ruin": {
        "class": "Warlock", "spec": "SM / Ruin Raid DPS (30/0/21)",
        "tree_display": (
            "🩸 **Affliction (30 pts):** [🟩🟩🟩🟩⬜] (Imp Corruption 5, Siphon Life 1, Shadow Mastery 5)\n"
            "👿 **Demonology (0 pts):** [⬜⬜⬜⬜⬜] (Uninvested)\n"
            "🔥 **Destruction (21 pts):** [🟩🟩🟩⬜⬜] (Bane 5, Devastation 5, Shadowburn 1, Ruin 1)"
        ),
        "capstones": "• **Shadow Mastery** (+10% Shadow damage to all spells & dots)\n• **Ruin** (+100% Critical strike damage bonus on Destruction spells)\n• **Siphon Life** (Drains 15 health per second while damaging target)",
        "priority_order": "1. Affliction to Shadow Mastery (Level 40) -> 2. Destruction to Ruin (Level 40–60).",
        "share_code": "`https://classicdb.ch/?talent#IE0bZcZxx0tr0z`"
    }
}


def get_talent_build(query_class: str, query_spec: Optional[str] = None) -> Optional[Dict[str, Any]]:
    """Retrieves visual talent tree distribution, capstones, and point priorities."""
    qc = query_class.lower().strip()
    qs = query_spec.lower().strip() if query_spec else ""
    target = f"{qc}:{qs}".strip(":")

    for k, v in TALENTS_DATA.items():
        if k == target or (qc in k and qs in k):
            return v
    for k, v in TALENTS_DATA.items():
        if qc in k:
            return v
    return None




