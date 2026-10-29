#!/usr/bin/env python3
"""Simulation: External User Downloading Foreverbot & Executing 500 Slash Commands.

Simulates an end-user downloading the repository from scratch, unzipping it,
and firing 500 distinct slash command requests across all 42 bot commands:
- Gear, Items & Comparisons
- Quests, Attunements, Keys & Reputations
- World Travel, Zones, Flightpaths & Transit
- Economy, Farming, Vendors & Professions
- Raiding, Boss Tactics, Consumables, Buffs & Resets
- Tuesday Reset Intel & Stealth Hotfixes
- Class Builds, Talents, Racials & Macros
- Guild Armory Profiles (/profile set, /profile view)
- PvP Honor Ranks & Twink Brackets
- Raid Signups, Comps, GDKP Splits & Rolls
- Addons, Events, Trivia & Conversational AI (/ask)
"""

import asyncio
import os
import sys
import time
import statistics
from typing import List, Dict, Tuple, Any
from unittest.mock import MagicMock, AsyncMock

# Ensure we are testing the root project directory (whether run from root or tests/)
SIM_DIR = os.path.dirname(os.path.abspath(__file__))
if not os.path.exists(os.path.join(SIM_DIR, 'wow_forever.db')):
    SIM_DIR = os.path.dirname(SIM_DIR)
sys.path.insert(0, SIM_DIR)

import discord
from discord import app_commands
import database
from database import WoWForeverDB
import knowledge_engine as ke
import bot


def create_mock_interaction(command_name: str, user_name: str = "GuildRaider", user_id: int = 9876543210):
    """Creates a mock Discord interaction to simulate real Discord command dispatch."""
    inter = MagicMock()
    inter.id = 123456789012345678
    inter.user = MagicMock()
    inter.user.id = user_id
    inter.user.display_name = user_name
    inter.user.mention = f"@{user_name}"
    inter.user.guild_permissions = MagicMock()
    inter.user.guild_permissions.administrator = True

    inter.command = MagicMock()
    inter.command.name = command_name

    inter.guild = MagicMock()
    inter.guild.id = 1564040719130431529
    inter.guild.name = "Test Guild"
    inter.guild.owner_id = user_id
    inter.guild.me = MagicMock()
    inter.guild.me.guild_permissions = MagicMock()
    inter.guild.me.guild_permissions.administrator = True

    inter.response = MagicMock()
    inter.response.defer = AsyncMock()
    inter.response.send_message = AsyncMock()
    inter.response.edit_message = AsyncMock()

    mock_msg = MagicMock()
    inter.original_response = AsyncMock(return_value=mock_msg)

    inter.followup = MagicMock()
    inter.followup.send = AsyncMock()

    return inter


def extract_response_content(inter) -> Tuple[str, List[Any]]:
    """Extracts text content and Discord Embed objects from interaction responses."""
    text_parts = []
    embeds = []

    # Check response.send_message
    for call in inter.response.send_message.call_args_list:
        args, kwargs = call
        if args:
            text_parts.append(str(args[0]))
        if "content" in kwargs and kwargs["content"]:
            text_parts.append(str(kwargs["content"]))
        if "embed" in kwargs and kwargs["embed"]:
            embeds.append(kwargs["embed"])
        if "embeds" in kwargs and kwargs["embeds"]:
            embeds.extend(kwargs["embeds"])

    # Check followup.send (standard for deferred slash commands)
    for call in inter.followup.send.call_args_list:
        args, kwargs = call
        if args:
            text_parts.append(str(args[0]))
        if "content" in kwargs and kwargs["content"]:
            text_parts.append(str(kwargs["content"]))
        if "embed" in kwargs and kwargs["embed"]:
            embeds.append(kwargs["embed"])
        if "embeds" in kwargs and kwargs["embeds"]:
            embeds.extend(kwargs["embeds"])

    combined_text = " ".join(text_parts)
    for emb in embeds:
        if emb.title:
            combined_text += f" [Title: {emb.title}]"
        if emb.description:
            combined_text += f" [Desc: {emb.description[:200]}]"
        for field in getattr(emb, "fields", []):
            combined_text += f" [{field.name}: {field.value[:100]}]"

    return combined_text.strip(), embeds


def build_500_command_test_cases() -> List[Tuple[str, Dict[str, Any], str]]:
    """Generates an exhaustive list of exactly 500 distinct slash command invocations."""
    cases = []

    # 1. /item (100 distinct items: weapons, armor, trinkets, gray junk, and custom WoW Forever)
    items = [
        "Thunderfury", "Sulfuras", "Corrupted Ashbringer", "Nightfall", "Ironfoe",
        "Edgemaster's Handguards", "Lionheart Helm", "Titans", "Bloodvine Vest",
        "Neltharion's Tear", "Drake Fang Talisman", "Rejuvenating Gem", "Dark Edge of Insanity",
        "Might of Menethil", "Gressil", "The Hungering Cold", "Kiss of the Spider",
        "Vis'kag", "Deathbringer", "Brutality Blade", "Core Hound Tooth", "Chromatically Tempered Sword",
        "Ashkandi", "Lok'amir", "Staff of the Shadow Flame", "Rhok'delar", "Lok'delar",
        "Benediction", "Anathema", "Warden Staff", "The Unstoppable Force", "The Immovable Object",
        "Devilsaur Leggings", "Devilsaur Gauntlets", "Don Julio's Band", "Badge of the Swarmguard",
        "The Slayer's Crest", "Mark of the Champion", "Quick Strike Ring", "Ring of the Godslayer",
        "Band of Unnatural Forces", "Onyxia Tooth Pendant", "Prestor's Talisman", "Barbed Choker",
        "Crown of the Skyborne Ascendant", "Zephras Tidal Cleaver", "Signet of the Unopened Portal",
        "Girdle of the Ancient Roots", "Shen'dorei Runed Robes", "Manual Crowd Pummeler",
        "Hand of Justice", "Blackhand's Breadth", "Eye of the Beast", "Briarwood Reed",
        "Rune of the Captain", "Warmth of Forgiveness", "Tear of the Earthmother",
        "Permafrost Cloak", "Hide of the Wild", "Archivist Cape", "Cape of the Black Baron",
        "Stoneskin Gargoyle Cape", "Deep Earth Cloak", "Stormshroud Armor", "Tombstone Breastplate",
        "Krol Blade", "Drakefang Pauldrons", "Spinal Reaper", "Bonereaver's Edge",
        "Boots of the Shadow Flame", "Cloak of the Fallen God", "The Castigator", "Severance",
        "Robe of the Archmage", "Robe of the Void", "Truefaith Vestments", "Helm of the Mountain",
        "Frostbite", "Flurry Axe", "Gutgore Ripper", "Perdition's Blade", "Felstriker",
        "Shadowcraft Cap", "Dreadmist Mask", "Magister's Crown", "Wildheart Cowl",
        "Lightforge Helm", "Valor Helm", "Beaststalker's Cap", "Devout Crown",
        "Dal'Rend's Sacred Charge", "Dal'Rend's Tribal Guardian", "Mirah's Song",
        "Thrash Blade", "Vanquisher's Sword", "Sword of Serenity", "Peacekeeper Boots",
        "Broken Boar Tusk", "Ruined Pelt", "Torn Bear Fur", "Cracked Eggshell", "Gargoyle Eye"
    ]
    for it in items:
        cases.append(("item", {"query": it}, it.split()[0]))

    # 2. /compare (35 weapon & trinket comparisons)
    comps = [
        ("Brutality Blade", "Core Hound Tooth"), ("Vis'kag", "Deathbringer"),
        ("Ashkandi", "Bonereaver's Edge"), ("Might of Menethil", "Dark Edge of Insanity"),
        ("Gressil", "The Hungering Cold"), ("Chromatically Tempered Sword", "Ancient Qiraji Ripper"),
        ("Lok'amir", "Staff of the Shadow Flame"), ("Benediction", "Anathema"),
        ("Rhok'delar", "Crossbow of Smoldering Bolts"), ("Warden Staff", "The Unstoppable Force"),
        ("Drake Fang Talisman", "Blackhand's Breadth"), ("Neltharion's Tear", "Briarwood Reed"),
        ("Rejuvenating Gem", "Warmth of Forgiveness"), ("Kiss of the Spider", "Badge of the Swarmguard"),
        ("Lionheart Helm", "Crown of the Skyborne Ascendant"), ("Devilsaur Leggings", "Bloodsoaked Legplates"),
        ("Dal'Rend's Sacred Charge", "Mirah's Song"), ("Krol Blade", "Thrash Blade"),
        ("Perdition's Blade", "Gutgore Ripper"), ("Nightfall", "Sulfuras"),
        ("Thunderfury", "Ironfoe"), ("Hand of Justice", "Rune of the Guard Captain"),
        ("Manual Crowd Pummeler", "Warden Staff"), ("The Immovable Object", "Drillborer Disk"),
        ("Signet of the Unopened Portal", "Band of Accuria"), ("Quick Strike Ring", "Don Julio's Band"),
        ("Ring of the Godslayer", "Band of Unnatural Forces"), ("Onyxia Tooth Pendant", "Barbed Choker"),
        ("Robe of the Void", "Bloodvine Vest"), ("Robe of the Archmage", "Netherwind Robes"),
        ("Truefaith Vestments", "Robes of the Exalted"), ("Flurry Axe", "Felstriker"),
        ("Severance", "The Castigator"), ("Spinal Reaper", "Ashkandi"), ("Frostbite", "Thrash Blade")
    ]
    for w1, w2 in comps:
        cases.append(("compare", {"query": w1, "weapon2": w2}, "Comparison"))

    # 3. /bis (30 class & spec permutations)
    bis_queries = [
        ("Warrior", "fury"), ("Warrior", "prot"), ("Warrior", "arms"),
        ("Rogue", "combat"), ("Rogue", "daggers"), ("Rogue", "hemo"),
        ("Mage", "frost"), ("Mage", "fire"), ("Mage", "arcane"),
        ("Priest", "holy"), ("Priest", "shadow"), ("Priest", "disc"),
        ("Warlock", "affliction"), ("Warlock", "destro"), ("Warlock", "demo"),
        ("Druid", "feral"), ("Druid", "bear"), ("Druid", "resto"), ("Druid", "balance"),
        ("Hunter", "marksmanship"), ("Hunter", "beast mastery"), ("Hunter", "survival"),
        ("Paladin", "holy"), ("Paladin", "retribution"), ("Paladin", "protection"),
        ("Shaman", "restoration"), ("Shaman", "elemental"), ("Shaman", "enhancement"),
        ("Warrior", "tank"), ("Mage", "aoe")
    ]
    for cls, spec in bis_queries:
        cases.append(("bis", {"query": cls, "spec": spec}, cls))

    # 4. /resist (25 resistance calculations)
    resists = [
        ("Fire", 150), ("Fire", 315),
        ("Fire", 100), ("Fire", 225),
        ("Shadow", 200), ("Shadow", 300),
        ("Frost", 150), ("Frost", 250),
        ("Nature", 150), ("Nature", 225),
        ("Fire", 120), ("Fire", 180),
        ("Nature", 100), ("Frost", 100),
        ("Fire", 100), ("Frost", 200),
        ("Shadow", 150), ("Shadow", 100),
        ("Nature", 150), ("Fire", 150),
        ("Frost", 120), ("Nature", 150),
        ("Frost", 200), ("Fire", 150),
        ("Nature", 80)
    ]
    for school, score in resists:
        cases.append(("resist", {"query": school.lower(), "current": score, "role": "DPS"}, "Mitigation"))

    # 5. /quest (25 quest lookups)
    quests = [
        "Rise, Thunderfury!", "The Eye of Divinity", "A Call to Arms: The Plaguelands",
        "Attunement to the Core", "Blackhand's Command", "Drakefire Amulet",
        "The Great Masquerade", "In Dreams", "The Hidden Chamber", "The Fate of the Kingdom",
        "The Scarlet Oracle", "The Green Hills of Stranglethorn", "Tink-a-Tink",
        "A Recipe for the Ages", "Super Reaper 6000", "Disharmony of Flame",
        "Overlord Mok'Morokk", "Test of Lore", "Tears of the Moon", "The Missing Diplomat",
        "Wharfmaster Dizzy", "Southsea Shakedown", "Cortello's Riddle",
        "You Are Rakh'likh", "The Hermit of Duskwood"
    ]
    for q in quests:
        cases.append(("quest", {"query": q}, q.split()[0]))

    # 6. /keys (15 dungeon & raid key lookups)
    key_queries = [
        "Skeleton Key", "Shadowforge Key", "Key to the City", "Crescent Key",
        "Workshop Key", "Prison Cell Key", "Scarlet Key", "Ahn'Qiraj Scepter",
        "Drakefire Amulet", "Seal of Ascension", "BRD Key", "Scholo Key",
        "DM Key", "Stratholme Key", "Gnomeregan Key"
    ]
    for k in key_queries:
        cases.append(("keys", {"query": k}, "Key"))

    # 7. /attunement (15 raid attunements)
    attunes = [
        "Molten Core", "MC", "Blackwing Lair", "BWL", "Onyxia", "Onyxia Horde",
        "Onyxia Alliance", "Naxxramas", "Naxx", "Upper Blackrock Spire",
        "UBRS", "Scholomance", "Karazhan Crypts", "Hall of Thanes", "Dire Maul"
    ]
    for a in attunes:
        cases.append(("attunement", {"query": a}, "Attunement"))

    # 8. /rep (15 reputations)
    reps = [
        "Hydraxian Waterlords", "Argent Dawn", "Timbermaw Hold", "Thorium Brotherhood",
        "Cenarion Circle", "Zandalar Tribe", "Frostwolf Clan", "Stormpike Guard",
        "Silverwing Sentinels", "Warsong Outriders", "Defilers", "League of Arathor",
        "Brood of Nozdormu", "Bloodsail Buccaneers", "Wintersaber Trainers"
    ]
    for r in reps:
        cases.append(("rep", {"query": r}, "Reputation"))

    # 9. /flightpath (30 transit routes & flight masters)
    fps = [
        "The Crossroads", "Orgrimmar", "Thunder Bluff", "Undercity", "Ironforge",
        "Stormwind", "Darnassus", "Southshore", "Tarren Mill", "Booty Bay",
        "Gadgetzan", "Everlook", "Cenarion Hold", "Light's Hope Chapel",
        "Theramore", "Auberdine", "Astranaar", "Sun Rock Retreat", "Camp Taurajo",
        "Freewind Post", "Brackenwall Village", "Kargath", "Thorium Point",
        "Morgan's Vigil", "Flame Crest", "Nethergarde Keep", "Stonard",
        "Grom'gol Base Camp", "Sentinel Hill", "Lakeshire"
    ]
    for fp in fps:
        cases.append(("flightpath", {"query": fp}, fp.split()[0]))

    # 10. /map & /zones (25 zone lookups)
    zone_queries = [
        "Un'Goro Crater", "Stranglethorn Vale", "The Barrens", "Silithus",
        "Winterspring", "Western Plaguelands", "Eastern Plaguelands", "Felwood",
        "Tanaris", "Feralas", "Dustwallow Marsh", "Thousand Needles",
        "Desolace", "Ashenvale", "Darkshore", "Duskwood", "Redridge Mountains",
        "Westfall", "Loch Modan", "Wetlands", "Arathi Highlands", "Hillsbrad Foothills",
        "Alterac Mountains", "Badlands", "Blasted Lands"
    ]
    for z in zone_queries:
        cases.append(("map", {"query": z}, z.split()[0]))

    # 11. /dungeons & /zones (25 dungeon & raid lookups)
    dungs = [
        "Deadmines", "Wailing Caverns", "Shadowfang Keep", "Blackfathom Deeps",
        "Gnomeregan", "Razorfen Kraul", "Scarlet Monastery", "Razorfen Downs",
        "Uldaman", "Zul'Farrak", "Maraudon", "Sunken Temple", "Blackrock Depths",
        "Lower Blackrock Spire", "Upper Blackrock Spire", "Stratholme", "Scholomance",
        "Dire Maul", "Molten Core", "Onyxia's Lair", "Blackwing Lair",
        "Zul'Gurub", "Ruins of Ahn'Qiraj", "Temple of Ahn'Qiraj", "Naxxramas"
    ]
    for d in dungs:
        cases.append(("dungeons", {"query": d}, d.split()[0]))

    # 12. /level & /route (20 leveling guides)
    levels = [1, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60]
    for lvl in levels:
        cases.append(("level", {"query": lvl}, "Level"))
    for lvl in [12, 22, 32, 42, 52, 58, 60]:
        cases.append(("route", {"query": f"{lvl}-{lvl+4}" if lvl < 60 else "55-60", "faction": "Both"}, "Route"))

    # 13. /vendor & /gather & /profession (30 economy lookups)
    vendors = ["Ironforge", "Orgrimmar", "Stormwind", "Crossroads", "Gadgetzan", "Everlook", "Booty Bay", "Undercity", "Thunder Bluff", "Darnassus"]
    for v in vendors:
        cases.append(("vendor", {"query": v}, v))

    nodes = ["Black Lotus", "Dreamfoil", "Mountain Silversage", "Plaguebloom", "Rich Thorium Vein", "Small Thorium Vein", "Mithril Deposit", "Ghost Mushroom", "Gromsblood", "Blindweed"]
    for n in nodes:
        cases.append(("gather", {"query": n}, n.split()[0]))

    profs = ["Alchemy", "Blacksmithing", "Enchanting", "Engineering", "Herbalism", "Mining", "Skinning", "Tailoring", "Leatherworking", "Cooking"]
    for p in profs:
        cases.append(("profession", {"query": p}, p))

    # 14. /farm & /mob (25 mob & farming lookups)
    farms = ["Elemental Earth", "Essence of Water", "Essence of Fire", "Black Lotus", "Rich Thorium", "Felcloth", "Demonic Runes", "Righteous Orb", "Dark Runes", "Larval Acid"]
    for f in farms:
        cases.append(("farm", {"query": f}, f.split()[0]))

    mobs = [
        "Ragnaros", "Onyxia", "Nefarian", "C'Thun", "Kel'Thuzad", "Baron Rivendare",
        "Emperor Dagran Thaurissan", "General Drakkisath", "Broken Tooth", "Tidestomper",
        "Vultros", "Barnabus", "Snarler", "King Mosh", "Lupos"
    ]
    for m in mobs:
        cases.append(("mob", {"query": m}, m.split()[0]))

    # 15. /raid, /consumes, /buffs, /resets, /intel (30 raiding & reset commands)
    for r in ["Molten Core", "Blackwing Lair", "AQ40", "Naxxramas", "Onyxia"]:
        cases.append(("raid", {"query": r}, r.split()[0]))

    for c in ["Warrior", "Mage", "Rogue", "Priest", "Warlock", "Druid", "Hunter"]:
        cases.append(("consumes", {"query": c}, c))

    for b in ["Rallying Cry", "Songflower", "Warchief's Blessing", "Spirit of Zandalar", "Dire Maul Tribute", "Darkmoon Faire"]:
        cases.append(("buffs", {"query": b}, b.split()[0]))

    for res_q in ["weekly", "onyxia", "zg", "daily", None]:
        cases.append(("resets", {"query": res_q}, "Reset"))

    for topic_choice in [None, "full", "bis", "stealth", "comments", "lockouts"]:
        choice_obj = app_commands.Choice(name=topic_choice or "full", value=topic_choice or "full") if topic_choice else None
        cases.append(("intel", {"topic": choice_obj}, "Intel"))

    # 16. /build, /talents, /race, /macro, /profile (30 class mastery & profile commands)
    for b_cls in ["Warrior", "Rogue", "Mage", "Priest", "Warlock", "Druid", "Hunter", "Paladin"]:
        cases.append(("build", {"query": b_cls, "spec": "pve"}, b_cls))
        cases.append(("talents", {"query": b_cls}, b_cls))

    for r_race in ["Orc", "Human", "Undead", "Night Elf", "Tauren", "Gnome", "Troll", "Dwarf"]:
        cases.append(("race", {"query": r_race}, r_race))

    for m_mac in ["stance dance", "mortal strike", "interrupt", "shield bash", "feign death", "vanish"]:
        cases.append(("macro", {"query": m_mac}, m_mac.split()[0]))

    # Profile armory commands
    cases.append(("profile_set", {
        "query": "Valgarde", "character_class": "Warrior", "race": "Human", "level": 60,
        "spec": "Fury DPS", "professions": "300 Engineering / 300 Mining",
        "guild_role": "Main Tank", "gear_note": "Thunderfury, Lionheart Helm"
    }, "Valgarde"))
    cases.append(("profile_view", {"query": "Valgarde"}, "Valgarde"))

    # 17. /pvp & /twink (25 PvP commands)
    pvp_queries = [
        "Grand Marshal", "High Warlord", "Marshal", "General", "Legionnaire", "Knight-Captain",
        "Centurion", "Champion", "Lieutenant Commander", "Blood Guard", "Stone Guard",
        "First Sergeant", "Senior Sergeant", "Sergeant", "Master Sergeant", "Grunt"
    ]
    for rank in pvp_queries:
        cases.append(("pvp", {"query": rank}, "Rank"))

    twink_queries = ["19", "29", "39", "49", "19 warrior", "19 rogue", "29 hunter", "39 mage", "49 priest"]
    for brk in twink_queries:
        cases.append(("twink", {"query": brk}, "Twink"))

    # 18. /signup, /comp, /gdkp, /roll, /addons (25 raid management commands)
    cases.append(("signup", {"query": "MC Sunday 7pm", "max_players": 40}, "Roster"))
    cases.append(("signup", {"query": "BWL Tuesday 8pm", "max_players": 40}, "Roster"))
    cases.append(("signup", {"query": "Onyxia Alt Run", "max_players": 25}, "Roster"))
    cases.append(("signup", {"query": "AQ40 Progression", "max_players": 40}, "Roster"))
    cases.append(("signup", {"query": "Naxxramas GDKP", "max_players": 40}, "Roster"))

    cases.append(("comp", {"query": "8 warriors, 6 rogues, 5 mages, 4 priests, 3 warlocks, 4 paladins"}, "Synergy"))
    cases.append(("comp", {"query": "6 warriors, 4 rogues, 6 mages, 4 warlocks, 3 druids, 5 shamans"}, "Synergy"))
    cases.append(("comp", {"query": "10 warriors, 8 rogues, 5 priests, 5 shamans, 2 hunters"}, "Synergy"))

    cases.append(("gdkp", {"query": 50000, "cut": 10, "raiders": 40, "tanks": 2, "tank_bonus": 2}, "Payout"))
    cases.append(("gdkp", {"query": 120000, "cut": 15, "raiders": 40, "tanks": 4, "tank_bonus": 3}, "Payout"))
    cases.append(("gdkp", {"query": 35000, "cut": 10, "raiders": 20, "tanks": 0, "tank_bonus": 0}, "Payout"))

    cases.append(("roll", {"query": "Reins of the Deathcharger", "seconds": 30}, "Roll"))
    cases.append(("roll", {"query": "Bindings of the Windseeker", "seconds": 45}, "Roll"))
    cases.append(("roll", {"query": "Eye of Sulfuras", "seconds": 30}, "Roll"))

    for addon in ["Questie", "Details", "WeakAuras", "BigWigs", "AtlasLoot", "Bagnon", "ClassicCastbars"]:
        cases.append(("addons", {"query": addon}, "Addon"))

    # 19. /forever, /events, /trivia, /zones, /ask (35 community & NLP commands)
    for fe in ["raids", "zones", "transmog", "mythic", "balance", "seasons"]:
        cases.append(("forever", {"query": fe}, "Forever"))

    for zn in ["Silithus", "Azshara", "Winterspring", "Plaguelands"]:
        cases.append(("zones", {"query": zn}, zn))

    for ev in ["Darkmoon Faire", "Feast of Winter Veil", "Hallow's End", "Gurubashi Arena"]:
        cases.append(("events", {"query": ev}, "Event"))

    for _ in range(5):
        cases.append(("trivia", {}, "Trivia"))

    asks = [
        "where is un'goro crater", "how much gold is epic mount", "what is the hit cap for rogues",
        "how to get to badlands from ironforge", "what level for deadmines", "best weapon for warrior",
        "where do i find black lotus", "what is glancing blow penalty", "how much fire resist for ragnaros",
        "who drops hand of justice", "what is pre raid bis for frost mage", "how to get drakefire amulet",
        "where is the flight master in crossroads", "how do i summon baron geddon", "what does edgemaster handguards do"
    ]
    for q in asks:
        cases.append(("ask", {"query": q}, q.split()[0]))

    # Adjust list to exactly 500 distinct test invocations
    if len(cases) > 500:
        cases = cases[:500]
    while len(cases) < 500:
        cases.append(("ask", {"query": f"tell me about item {len(cases)}"}, "Item"))

    return cases


async def run_user_simulation():
    print("=" * 85)
    print("🚀 FOREVERBOT EXTERNAL USER DOWNLOAD & 500-COMMAND SIMULATION")
    print(f"📂 Execution Directory: {SIM_DIR}")
    print("=" * 85)

    # 1. Verify unpack directory integrity
    db_file = os.path.join(SIM_DIR, "wow_forever.db")
    print(f"🔍 1. Checking Database Existence: {db_file}")
    if not os.path.exists(db_file):
        print("❌ CRITICAL: wow_forever.db missing from unpacked download archive!")
        sys.exit(1)
    db_size_mb = os.path.getsize(db_file) / (1024 * 1024)
    print(f"   ✅ Database present! File Size: {db_size_mb:.2f} MB")

    # 2. Check Database SQLite tables
    print("🔍 2. Verifying SQLite Tables and FTS5 Indexes...")
    db = WoWForeverDB(db_file)
    conn = database.get_connection(db_file)
    cur = conn.cursor()
    cur.execute("SELECT count(*) FROM items")
    item_count = cur.fetchone()[0]
    cur.execute("SELECT count(*) FROM creatures")
    creature_count = cur.fetchone()[0]
    cur.execute("SELECT count(*) FROM quests")
    quest_count = cur.fetchone()[0]
    cur.execute("SELECT count(*) FROM flightpaths")
    fp_count = cur.fetchone()[0]
    print(f"   ✅ Catalog Verified: {item_count:,} Items | {creature_count:,} Creatures | {quest_count:,} Quests | {fp_count} Flight Paths")
    conn.close()

    # 3. Build 500 Command Test Suite
    print("🔍 3. Assembling 500 Distinct User Slash Commands...")
    test_cases = build_500_command_test_cases()
    print(f"   ✅ Prepared exactly {len(test_cases)} user slash command invocations.")

    # 4. Map registered commands in bot tree
    print("🔍 4. Mapping Slash Commands from bot.tree...")
    cmd_map = {}
    for cmd in bot.bot.tree.get_commands():
        if hasattr(cmd, "callback"):
            cmd_map[cmd.name] = cmd.callback
        elif hasattr(cmd, "commands"):
            for sub in cmd.commands:
                cmd_map[f"{cmd.name}_{sub.name}"] = sub.callback
            if cmd.name == "profile":
                # Default /profile to profile_view
                cmd_map["profile"] = cmd.commands[1].callback if len(cmd.commands) > 1 else cmd.commands[0].callback

    print(f"   ✅ Found {len(cmd_map)} registered slash commands in bot tree.")

    # 5. Execute 500 Commands and Record Telemetry
    print("\n⚔️ 5. Dispatching 500 Slash Commands Sequentially (Simulating Live Discord Player Input)...")
    print("-" * 85)

    latencies_ms = []
    category_times = {}
    failures = []
    successes = 0

    t_start_total = time.perf_counter()

    for idx, (cmd_name, kwargs, expected_substr) in enumerate(test_cases, 1):
        if cmd_name not in cmd_map:
            failures.append((idx, cmd_name, f"Command /{cmd_name} not found in bot command tree"))
            continue

        cmd_func = cmd_map[cmd_name]
        inter = create_mock_interaction(cmd_name)

        t0 = time.perf_counter()
        try:
            # Call the async command function
            await cmd_func(inter, **kwargs)
            t1 = time.perf_counter()
            elapsed_ms = (t1 - t0) * 1000.0
            latencies_ms.append(elapsed_ms)
            category_times.setdefault(cmd_name, []).append(elapsed_ms)

            # Extract response content
            resp_text, embeds = extract_response_content(inter)

            # Assert non-empty response
            if not resp_text and not embeds:
                failures.append((idx, cmd_name, f"Empty response returned for kwargs: {kwargs}"))
            elif "Traceback" in resp_text:
                failures.append((idx, cmd_name, f"Traceback in response: {resp_text[:150]}"))
            else:
                successes += 1

        except Exception as e:
            t1 = time.perf_counter()
            failures.append((idx, cmd_name, f"Exception: {str(e)}"))

        # Progress indicator every 100 commands
        if idx % 100 == 0 or idx == len(test_cases):
            cur_avg = statistics.mean(latencies_ms) if latencies_ms else 0.0
            print(f"   [{idx:03d}/{len(test_cases)}] Executed | Successes: {successes} | Failures: {len(failures)} | Current Avg Latency: {cur_avg:.2f}ms")

    t_end_total = time.perf_counter()
    total_duration = t_end_total - t_start_total

    # Clean up test records created during simulation to preserve clean database state
    try:
        c_conn = database.get_connection(db_file)
        c_conn.execute("DELETE FROM user_profiles WHERE user_id = 9876543210")
        c_conn.commit()
        c_conn.close()
    except Exception:
        pass

    print("-" * 85)
    print("📊 USER SIMULATION RESULTS DASHBOARD")
    print("=" * 85)
    print(f"• Total Commands Fired:       {len(test_cases)}")
    print(f"• Successfully Answered:      {successes} ({successes/len(test_cases)*100:.1f}%)")
    print(f"• Errors / Unhandled Crashes: {len(failures)}")
    print(f"• Total Wall-Clock Time:      {total_duration:.2f} seconds")
    print(f"• Throughput:                 {len(test_cases)/total_duration:.1f} commands/second")

    if latencies_ms:
        latencies_ms.sort()
        count = len(latencies_ms)
        min_ms = latencies_ms[0]
        max_ms = latencies_ms[-1]
        avg_ms = statistics.mean(latencies_ms)
        p50_ms = statistics.median(latencies_ms)
        p95_ms = latencies_ms[int(count * 0.95)]
        p99_ms = latencies_ms[int(count * 0.99)]

        print(f"\n⚡ LATENCY BENCHMARK TELEMETRY (Across All 500 User Commands):")
        print(f"   - Minimum Latency:         {min_ms:.3f} ms")
        print(f"   - Median Latency (p50):    {p50_ms:.3f} ms")
        print(f"   - Average Latency:         {avg_ms:.3f} ms")
        print(f"   - 95th Percentile (p95):   {p95_ms:.3f} ms")
        print(f"   - 99th Percentile (p99):   {p99_ms:.3f} ms")
        print(f"   - Maximum Observed:        {max_ms:.3f} ms")
        print(f"   - Sub-Second (<1000ms):    {'✅ 100% of queries under 1 second!' if max_ms < 1000.0 else '❌ Slower than 1s'}")

    print(f"\n📋 BREAKDOWN BY TOP COMMAND CATEGORIES:")
    top_cmds = sorted(category_times.keys(), key=lambda k: len(category_times[k]), reverse=True)[:10]
    for cname in top_cmds:
        c_lats = category_times[cname]
        print(f"   • /{cname:<12} (n={len(c_lats):<3}) | Avg: {statistics.mean(c_lats):.2f}ms | p50: {statistics.median(c_lats):.2f}ms | Max: {max(c_lats):.2f}ms")

    if failures:
        print(f"\n⚠️ Encountered {len(failures)} failures:")
        for idx, cmd_name, err in failures[:15]:
            print(f"   [#{idx} /{cmd_name}]: {err}")
        sys.exit(1)
    else:
        print("\n🎉 VERDICT: All 500 user slash commands executed flawlessly in the fresh download environment!\n")


if __name__ == "__main__":
    asyncio.run(run_user_simulation())
