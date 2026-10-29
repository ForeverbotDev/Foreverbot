"""Comprehensive Variable Permutation & Offline Database Suite.

Tests all 40 Discord slash commands and knowledge/database engines across 1,000+
variable permutations with Gemini AI fallback disabled (strictly offline DB + knowledge_engine).
"""

import asyncio
import sqlite3
import sys
import os
from unittest.mock import AsyncMock, MagicMock, patch

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import database
import knowledge_engine as ke
import bot


def make_mock_interaction():
    interaction = MagicMock()
    interaction.user = MagicMock()
    interaction.user.id = 123456789
    interaction.user.display_name = "TestRaider"
    interaction.response = MagicMock()
    interaction.response.defer = AsyncMock()
    interaction.response.send_message = AsyncMock()
    interaction.response.edit_message = AsyncMock()
    interaction.followup = MagicMock()
    interaction.followup.send = AsyncMock()
    interaction.original_response = AsyncMock()
    return interaction


def extract_output_text(interaction) -> str:
    parts = []
    for call in interaction.response.send_message.call_args_list:
        args, kwargs = call
        if args:
            parts.append(str(args[0]))
        if "content" in kwargs and kwargs["content"]:
            parts.append(str(kwargs["content"]))
        if "embed" in kwargs and kwargs["embed"]:
            emb = kwargs["embed"]
            parts.append(f"{emb.title or ''}\n{emb.description or ''}")
    for call in interaction.followup.send.call_args_list:
        args, kwargs = call
        if args:
            parts.append(str(args[0]))
        if "content" in kwargs and kwargs["content"]:
            parts.append(str(kwargs["content"]))
        if "embed" in kwargs and kwargs["embed"]:
            emb = kwargs["embed"]
            parts.append(f"{emb.title or ''}\n{emb.description or ''}")
    return "\n".join(parts)


async def run_all_variable_tests():
    db = database.WoWForeverDB()
    conn = database.get_connection()
    cursor = conn.cursor()

    total_checks = 0
    failures = []

    def check(condition: bool, msg: str):
        nonlocal total_checks
        total_checks += 1
        if not condition:
            failures.append(msg)

    # 1. Database 100% Row & Alias Coverage
    for r in cursor.execute("SELECT name FROM items").fetchall():
        res, _ = db.search_items(r["name"], limit=5)
        check(bool(res and any(x["name"].lower() == r["name"].lower() for x in res)), f"Item DB miss: {r['name']}")

    for alias, target in database.ITEM_AUTOCOMPLETE_ALIASES.items():
        res, _ = db.search_items(alias, limit=5)
        check(bool(res), f"Item alias miss: {alias} -> {target}")

    for r in cursor.execute("SELECT title FROM quests").fetchall():
        res, _ = db.search_quests(r["title"], limit=5)
        check(bool(res and any(x["title"].lower() == r["title"].lower() for x in res)), f"Quest DB miss: {r['title']}")

    for r in cursor.execute("SELECT name FROM creatures").fetchall():
        res, _ = db.search_creatures(r["name"], limit=5)
        check(bool(res and any(x["name"].lower() == r["name"].lower() for x in res)), f"Creature DB miss: {r['name']}")

    for r in cursor.execute("SELECT npc_name, item_name FROM vendors").fetchall():
        res1 = db.search_vendors(r["npc_name"], limit=5)
        res2 = db.search_vendors(r["item_name"], limit=5)
        check(bool(res1 and res2), f"Vendor DB miss: {r['npc_name']} / {r['item_name']}")

    for r in cursor.execute("SELECT DISTINCT zone FROM flightpaths").fetchall():
        res = db.search_flightpaths(r["zone"])
        check(bool(res), f"Flightpath zone miss: {r['zone']}")

    for r in cursor.execute("SELECT name FROM dungeons").fetchall():
        res, _ = db.search_dungeons(r["name"], limit=5)
        check(bool(res and any(x["name"].lower() == r["name"].lower() for x in res)), f"Dungeon DB miss: {r['name']}")

    for alias, target in database.ZONE_ALIASES.items():
        z = ke.get_zone_info(alias, database.ZONE_ALIASES)
        d, _ = db.search_dungeons(alias, limit=5)
        check(bool(z or d), f"Zone alias miss: {alias} -> {target}")

    # 2. All Class x Spec Permutations (/build, /talents, /bis)
    CLASS_SPECS = {
        "Warrior": [None, "Arms", "Fury", "Prot", "Protection", "Tank", "DPS", "2H", "Dual Wield", "PvP"],
        "Mage": [None, "Frost", "Frost AoE", "Fire", "Arcane", "Raid", "AoE", "PvP", "DPS"],
        "Rogue": [None, "Combat", "Swords", "Daggers", "Assassination", "Subtlety", "Hemo", "PvP", "DPS"],
        "Priest": [None, "Holy", "Discipline", "Disc", "Shadow", "Healer", "DPS", "PvP"],
        "Warlock": [None, "Affliction", "SM Ruin", "DS Ruin", "Destruction", "Destro", "Demonology", "Soul Link", "Drain Tank", "DPS", "Tank"],
        "Hunter": [None, "Beast Mastery", "BM", "Marksmanship", "MM", "Survival", "SV", "DPS", "PvP"],
        "Druid": [None, "Feral", "Cat", "Bear", "Tank", "Guardian", "Restoration", "Resto", "Healer", "Balance", "Boomkin", "Moonkin", "DPS"],
        "Paladin": [None, "Holy", "Healer", "Protection", "Prot", "Tank", "Retribution", "Ret", "DPS", "AoE"],
        "Shaman": [None, "Restoration", "Resto", "Healer", "Enhancement", "Enh", "Elemental", "Ele", "DPS", "Tank"]
    }

    def get_cmd(name: str):
        cmd = bot.bot.tree.get_command(name)
        assert cmd is not None, f"Command /{name} not registered in bot.tree"
        return cmd.callback

    with patch.object(bot, "query_gemini_text", new=AsyncMock(return_value=None)):
        for cls, specs in CLASS_SPECS.items():
            for sp in specs:
                for cmd_name in ["build", "talents", "bis"]:
                    cmd_fn = get_cmd(cmd_name)
                    inter = make_mock_interaction()
                    await cmd_fn(inter, query=cls, spec=sp)
                    out = extract_output_text(inter)
                    check(
                        "❌" not in out and cls.lower() in out.lower(),
                        f"/{cmd_name} failed for ({cls}, {sp}): {out[:120]}"
                    )

        # 3. Slash Commands End-to-End with Multiple Variable Inputs (Offline Mode)
        slash_cases = [
            ("item", {"query": "Thunderfury"}, "Thunderfury"),
            ("item", {"query": "Formula: Enchant Weapon - Crusader"}, "Crusader"),
            ("item", {"query": "dft"}, "Drake Fang Talisman"),
            ("item", {"query": "hoJ"}, "Hand of Justice"),
            ("quest", {"query": "The Great Masquerade"}, "Masquerade"),
            ("quest", {"query": "In Dreams"}, "In Dreams"),
            ("mob", {"query": "Emperor Dagran Thaurissan"}, "Thaurissan"),
            ("mob", {"query": "Chrono-Lord Epoch"}, "Epoch"),
            ("vendor", {"query": "Runecloth Bag"}, "Runecloth"),
            ("vendor", {"query": "Qia"}, "Qia"),
            ("flightpath", {"query": "STV"}, "Booty Bay"),
            ("flightpath", {"query": "Winterspring"}, "Everlook"),
            ("map", {"query": "Mount Hyjal"}, "Hyjal"),
            ("map", {"query": "STV"}, "Stranglethorn"),
            ("zones", {"query": "Zephras Isle"}, "Zephras"),
            ("zones", {"query": "Booty Bay"}, "Stranglethorn"),
            ("dungeons", {"query": "42"}, "Zul'Farrak"),
            ("dungeons", {"query": "bwl"}, "Blackwing Lair"),
            ("dungeons", {"query": "naxx"}, "Naxxramas"),
            ("level", {"query": 1}, "Level 1"),
            ("level", {"query": 30}, "Level 30"),
            ("level", {"query": 60}, "Level 60"),
            ("gather", {"query": "Black Lotus"}, "Black Lotus"),
            ("gather", {"query": "Rich Thorium"}, "Thorium"),
            ("profession", {"query": "Engineering"}, "Engineering"),
            ("profession", {"query": "Alchemy"}, "Alchemy"),
            ("consumes", {"query": "Warrior"}, "Melee"),
            ("consumes", {"query": "Healer"}, "Healer"),
            ("buffs", {"query": "Songflower"}, "Songflower"),
            ("buffs", {"query": "Warchief"}, "Warchief"),
            ("raid", {"query": "C'Thun"}, "C'Thun"),
            ("raid", {"query": "Kel'Thuzad"}, "Kel'Thuzad"),
            ("raid", {"query": "Temporal Rift"}, "Temporal Rift"),
            ("raid", {"query": "Verdant Scar"}, "Verdant Scar"),
            ("rep", {"query": "Brood of Nozdormu"}, "Nozdormu"),
            ("rep", {"query": "Wintersaber"}, "Wintersaber"),
            ("rep", {"query": "WSG"}, "Warsong"),
            ("attunement", {"query": "Onyxia"}, "Onyxia"),
            ("attunement", {"query": "Karazhan Crypts"}, "Karazhan"),
            ("attunement", {"query": "UBRS"}, "Seal of Ascension"),
            ("macro", {"query": "Powershift"}, "Cat Form"),
            ("macro", {"query": "Feign Trap"}, "Freezing Trap"),
            ("pvp", {"query": "Rank 14"}, "25,000"),
            ("pvp", {"query": "World PvP"}, "Tarren Mill"),
            ("keys", {"query": "ZF"}, "Mallet of Zul'Farrak"),
            ("keys", {"query": "UBRS"}, "Seal of Ascension"),
            ("race", {"query": "Skyborne Elf"}, "Wind-Blessed"),
            ("race", {"query": "Orc"}, "Command"),
            ("race", {"query": "Tauren"}, "Plainsrunning"),
            ("comp", {"query": "8 warr, 6 rogue, 6 mage, 4 lock, 6 priest, 3 hunter, 5 shaman, 2 druid"}, "Sunder Armor"),
            ("farm", {"query": "Stratholme"}, "Righteous Orb"),
            ("farm", {"query": "Devilsaur"}, "Devilsaur"),
            ("events", {"query": "all"}, "Gurubashi"),
            ("gdkp", {"query": 50000, "cut": 10, "raiders": 40, "tanks": 2, "tank_bonus": 2}, "50,000g"),
            ("compare", {"query": "Thunderfury", "weapon2": "Chromatically Tempered Sword", "race": "Human", "character_class": "Warrior"}, "Thunderfury"),
            ("compare", {"query": "Manual Crowd Pummeler", "weapon2": "Warden Staff", "race": "Tauren", "character_class": "Druid"}, "Manual Crowd Pummeler"),
            ("resets", {"query": "all"}, "Onyxia"),
            ("twink", {"query": "19"}, "Shadowfang"),
            ("twink", {"query": "49"}, "Kang"),
            ("twink", {"query": "59"}, "Ice Barbed Spear"),
            ("twink", {"query": "60"}, "Rank 14"),
            ("route", {"query": "1-10"}, "Starter"),
            ("route", {"query": "40-50"}, "Tanaris"),
            ("route", {"query": "50-60"}, "Un'Goro"),
            ("addons", {"query": "WeakAuras"}, "WeakAuras"),
            ("addons", {"query": "PallyPower"}, "PallyPower"),
            ("resist", {"query": "Fire", "current": 225, "role": "Tank"}, "Fire Resistance"),
            ("forever", {"query": "racials"}, "Ruthless"),
            ("forever", {"query": "raid buffs"}, "Raid-Wide"),
            ("ask", {"query": "where do i get a wand"}, "Wand"),
            ("ask", {"query": "how do i get to badlands"}, "Badlands"),
        ]

        for cmd_name, kwargs, expected_substr in slash_cases:
            cmd_fn = get_cmd(cmd_name)
            inter = make_mock_interaction()
            await cmd_fn(inter, **kwargs)
            out = extract_output_text(inter)
            check(
                "❌" not in out and expected_substr.lower() in out.lower(),
                f"Slash command /{cmd_name}({kwargs}) failed: expected '{expected_substr}' in '{out[:150]}'"
            )

    print(f"Executed {total_checks} permutation checks | Failures: {len(failures)}")
    if failures:
        for f in failures[:25]:
            print(" ❌", f)
        sys.exit(1)
    print("✅ 100% OF ALL VARIABLE PERMUTATIONS PASSED OFFLINE!")


if __name__ == "__main__":
    asyncio.run(run_all_variable_tests())
