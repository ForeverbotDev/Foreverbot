#!/usr/bin/env python3
"""
Test Suite for Foreverbot How-To Guide.
Runs and validates all 115 specific commands and prompt queries across all 23 slides.
"""

import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

import asyncio
import traceback
from typing import Dict, Any, List

import discord
import bot

class MockUser:
    def __init__(self, name="TestUser", user_id=123456789):
        self.name = name
        self.display_name = name
        self.id = user_id
        self.mention = f"<@{user_id}>"
    def __str__(self):
        return self.name

class MockGuild:
    def __init__(self, guild_id=987654321, name="Test Guild"):
        self.id = guild_id
        self.name = name

class MockChannel:
    def __init__(self, channel_id=555555555):
        self.id = channel_id

class MockResponse:
    def __init__(self):
        self._is_done = False
        self.messages: List[Dict[str, Any]] = []

    def is_done(self) -> bool:
        return self._is_done

    async def defer(self, ephemeral: bool = False, thinking: bool = False):
        self._is_done = True

    async def send_message(self, content=None, embed=None, embeds=None, view=None, ephemeral: bool = False):
        self._is_done = True
        self.messages.append({
            "content": content,
            "embed": embed,
            "embeds": embeds or ([] if not embed else [embed]),
            "view": view
        })

class MockFollowup:
    def __init__(self):
        self.messages: List[Dict[str, Any]] = []

    async def send(self, content=None, embed=None, embeds=None, view=None, ephemeral: bool = False):
        self.messages.append({
            "content": content,
            "embed": embed,
            "embeds": embeds or ([] if not embed else [embed]),
            "view": view
        })

class MockMessage:
    def __init__(self):
        self.id = 998877665544
    async def edit(self, content=None, embed=None, view=None):
        pass

class MockInteraction:
    def __init__(self):
        self.id = 1234567890123
        self.user = MockUser()
        self.guild = MockGuild()
        self.channel = MockChannel()
        self.response = MockResponse()
        self.followup = MockFollowup()
        self.command = None

    async def original_response(self):
        return MockMessage()

    def get_all_messages(self) -> List[Dict[str, Any]]:
        return self.response.messages + self.followup.messages


TEST_CASES = [
    # 1. /item
    ("item", {"query": "dal rend"}, ["Dal'Rend", "Sacred Charge", "Main Hand", "Sword"]),
    ("item", {"query": "hand of ragnaros"}, ["Sulfuras", "Ragnaros", "Two-Hand"]),
    ("item", {"query": "hoj"}, ["Hand of Justice", "Trinket", "Angerforge"]),
    ("item", {"query": "free action potion"}, ["Free Action Potion", "Immune", "Stun"]),
    ("item", {"query": "thudnerfury"}, ["Thunderfury", "Windseeker", "Legendary"]),

    # 2. /compare
    ("compare", {"query": "brutality blade", "weapon2": "deathbringer"}, ["Brutality Blade", "Deathbringer", "Comparison"]),
    ("compare", {"query": "dal rend charge", "weapon2": "mirah song"}, ["Dal'Rend", "Mirah", "Comparison"]),
    ("compare", {"query": "hoj", "weapon2": "blackhand breadth"}, ["Hand of Justice", "Blackhand", "Comparison"]),
    ("compare", {"query": "chromatic boots", "weapon2": "bloodmail boots"}, ["Comparison", "Boots"]),
    ("compare", {"query": "perdition blade", "weapon2": "core hound tooth"}, ["Perdition", "Core Hound", "Comparison"]),

    # 3. /bis
    ("bis", {"query": "warrior", "spec": "fury"}, ["Warrior", "Fury", "BiS"]),
    ("bis", {"query": "rogue", "spec": "swords"}, ["Rogue", "BiS"]),
    ("bis", {"query": "mage", "spec": "frost"}, ["Mage", "Frost", "BiS"]),
    ("bis", {"query": "priest", "spec": "holy"}, ["Priest", "Holy", "BiS"]),
    ("bis", {"query": "hunter", "spec": "marksman"}, ["Hunter", "BiS"]),

    # 4. /raid
    ("raid", {"query": "baron geddon"}, ["Geddon", "Living Bomb", "Inferno", "Dispel"]),
    ("raid", {"query": "rag"}, ["Ragnaros", "Submerge", "Sons of Flame"]),
    ("raid", {"query": "onyxia"}, ["Onyxia", "Deep Breath", "Phase"]),
    ("raid", {"query": "vaelastrasz"}, ["Vaelastrasz", "Burning Adrenaline"]),
    ("raid", {"query": "chromaggus"}, ["Chromaggus", "Breath", "Bronze"]),

    # 5. /consumes
    ("consumes", {"query": "fury warrior"}, ["Warrior", "Mongoose", "Titans", "Consumable"]),
    ("consumes", {"query": "rogue"}, ["Rogue", "Thistle Tea", "Mongoose"]),
    ("consumes", {"query": "holy paladin"}, ["Paladin", "Wisdom", "Mana"]),
    ("consumes", {"query": "fire mage"}, ["Mage", "Arcane Elixir", "Firepower"]),
    ("consumes", {"query": "feral tank"}, ["Druid", "Pummeler", "Defense"]),

    # 6. /dungeons
    ("dungeons", {"query": "42"}, ["Zul'Farrak", "Uldaman", "Razorfen"]),
    ("dungeons", {"query": "sm"}, ["Scarlet Monastery", "Cathedral", "Armory"]),
    ("dungeons", {"query": "brd"}, ["Blackrock Depths", "Emperor", "Bar"]),
    ("dungeons", {"query": "dire maul"}, ["Dire Maul", "East", "West", "North"]),
    ("dungeons", {"query": "thanes"}, ["Thane", "Dun Morogh", "Custom"]),

    # 7. /flightpath
    ("flightpath", {"query": "stv"}, ["Stranglethorn", "Booty Bay", "Grom'gol"]),
    ("flightpath", {"query": "feralas"}, ["Feralas", "Feathermoon", "Mojache"]),
    ("flightpath", {"query": "tanaris"}, ["Tanaris", "Gadgetzan"]),
    ("flightpath", {"query": "badlands"}, ["Badlands", "Kargath"]),
    ("flightpath", {"query": "hillsbrad"}, ["Hillsbrad", "Southshore", "Tarren Mill"]),

    # 8. /zones
    ("zones", {"query": "duskwood"}, ["Duskwood", "20-30", "Darkshire"]),
    ("zones", {"query": "stranglethorn vale"}, ["Stranglethorn", "30-45", "Booty Bay"]),
    ("zones", {"query": "zephras isle"}, ["Zephras", "Forever", "Pirate"]),
    ("zones", {"query": "searing gorge"}, ["Searing Gorge", "Thorium"]),
    ("zones", {"query": "felwood"}, ["Felwood", "Timbermaw"]),

    # 9. /mob
    ("mob", {"query": "garr"}, ["Garr", "Molten Core", "Firesworn"]),
    ("mob", {"query": "emperor dagran"}, ["Dagran", "Thaurissan", "Moira"]),
    ("mob", {"query": "devilsaur"}, ["Devilsaur", "Un'Goro", "Leather"]),
    ("mob", {"query": "lord kazzak"}, ["Kazzak", "Blasted Lands", "Supreme"]),
    ("mob", {"query": "high foreman bargul"}, ["Bargul", "Hateforge"]),

    # 10. /vendor
    ("vendor", {"query": "free action potion"}, ["Free Action Potion", "Recipe", "Vendor"]),
    ("vendor", {"query": "recipe elixir of superior defense"}, ["Superior Defense", "Vendor"]),
    ("vendor", {"query": "runecloth bag recipe"}, ["Runecloth Bag", "Qia", "Winterspring"]),
    ("vendor", {"query": "wildthorn tea"}, ["Tea", "Vendor"]),
    ("vendor", {"query": "heavy silk bandage"}, ["First Aid", "Bandage"]),

    # 11. /farm
    ("farm", {"query": "dm east jump run"}, ["Dire Maul", "East", "Jump", "Thorium"]),
    ("farm", {"query": "elemental earth"}, ["Elemental Earth", "Badlands"]),
    ("farm", {"query": "essence of water"}, ["Essence of Water", "Felwood"]),
    ("farm", {"query": "maraudon princess"}, ["Princess", "Theradras", "Maraudon"]),
    ("farm", {"query": "ghost mushroom"}, ["Ghost Mushroom", "Maraudon"]),

    # 12. /twink
    ("twink", {"query": "19 rogue"}, ["19", "Rogue", "Twink", "Shadowfang"]),
    ("twink", {"query": "29 warrior"}, ["29", "Warrior", "Twink", "Corpsemaker"]),
    ("twink", {"query": "39 mage"}, ["39", "Mage", "Twink"]),
    ("twink", {"query": "19 hunter"}, ["19", "Hunter", "Twink", "Venomstrike"]),
    ("twink", {"query": "29 paladin"}, ["29", "Paladin", "Twink"]),

    # 13. /build
    ("build", {"query": "warrior", "spec": "fury pve"}, ["Warrior", "Fury", "Talent"]),
    ("build", {"query": "mage", "spec": "aoe blizzard"}, ["Mage", "Blizzard", "Frost"]),
    ("build", {"query": "warlock", "spec": "sm ruin"}, ["Warlock", "Shadow", "Ruin"]),
    ("build", {"query": "druid", "spec": "hotw ns"}, ["Druid", "Nature"]),
    ("build", {"query": "rogue", "spec": "combat daggers"}, ["Rogue", "Combat", "Backstab"]),

    # 14. /talents
    ("talents", {"query": "warrior", "spec": "arms"}, ["Arms", "Warrior", "Mortal Strike"]),
    ("talents", {"query": "rogue", "spec": "combat"}, ["Combat", "Rogue", "Flurry"]),
    ("talents", {"query": "priest", "spec": "shadow"}, ["Shadow", "Priest", "Shadowform"]),
    ("talents", {"query": "mage", "spec": "frost"}, ["Frost", "Mage", "Barrier"]),
    ("talents", {"query": "hunter", "spec": "beast mastery"}, ["Beast", "Hunter", "Wrath"]),

    # 15. /attunement
    ("attunement", {"query": "onyxia alliance"}, ["Onyxia", "Windsor", "Jailbreak"]),
    ("attunement", {"query": "onyxia horde"}, ["Onyxia", "Rexxar", "Amulet"]),
    ("attunement", {"query": "bwl"}, ["Blackwing", "Command", "UBRS"]),
    ("attunement", {"query": "mc"}, ["Molten Core", "Fragment", "BRD"]),
    ("attunement", {"query": "naxxramas"}, ["Naxxramas", "Argent Dawn", "Citadel"]),

    # 16. /keys
    ("keys", {"query": "shadowforge key"}, ["Shadowforge", "Forgestone", "BRD"]),
    ("keys", {"query": "skeleton key"}, ["Skeleton Key", "Scholomance", "Plaguelands"]),
    ("keys", {"query": "key to the city"}, ["Key to the City", "Barthilas", "Stratholme"]),
    ("keys", {"query": "scarlet key"}, ["Scarlet Key", "Doan", "Library"]),
    ("keys", {"query": "crescent key"}, ["Crescent Key", "Pusillin", "Dire Maul"]),

    # 17. /resets
    ("resets", {"query": "onyxia"}, ["Onyxia", "Reset"]),
    ("resets", {"query": "zg"}, ["Zul'Gurub", "Reset"]),
    ("resets", {"query": "mc"}, ["Molten Core", "Reset"]),
    ("resets", {"query": "bwl"}, ["Blackwing Lair", "Reset"]),
    ("resets", {"query": "all"}, ["Reset", "Raid"]),

    # 18. /buffs
    ("buffs", {"query": "ony head"}, ["Dragonslayer", "Onyxia", "Buff"]),
    ("buffs", {"query": "rend"}, ["Warchief", "Blessing", "Rend"]),
    ("buffs", {"query": "songflower"}, ["Songflower", "Felwood", "Serenade"]),
    ("buffs", {"query": "dire maul tribute"}, ["Tribute", "Fengus", "Slip'kik"]),
    ("buffs", {"query": "zandalar"}, ["Zandalar", "Spirit", "Yojamba"]),

    # 19. /pvp
    ("pvp", {"query": "rank 10"}, ["Rank 10", "Champion", "Lieutenant"]),
    ("pvp", {"query": "rank 14"}, ["Rank 14", "Grand Marshal", "High Warlord"]),
    ("pvp", {"query": "weekly decay"}, ["Decay", "20%"]),
    ("pvp", {"query": "wsg flag carry"}, ["Warsong", "Flag", "Druid"]),
    ("pvp", {"query": "av rush"}, ["Alterac", "Drek", "Bunker"]),

    # 20. /roll
    ("roll", {"query": "Reins of the Deathcharger", "seconds": 30}, ["Roll", "Deathcharger"]),
    ("roll", {"query": "Vis'kag the Bloodletter", "seconds": 45}, ["Roll", "Vis'kag"]),
    ("roll", {"query": "Mageblade", "seconds": 30}, ["Roll", "Mageblade"]),
    ("roll", {"query": "Staff of Dominance", "seconds": 20}, ["Roll", "Staff of Dominance"]),
    ("roll", {"query": "Band of Sulfuras", "seconds": 30}, ["Roll", "Band of Sulfuras"]),

    # 21. /signup
    ("signup", {"query": "MC Sunday 7pm", "max_players": 40}, ["Sign Up", "Molten Core", "Tank"]),
    ("signup", {"query": "Onyxia Thursday 8pm", "max_players": 40}, ["Sign Up", "Onyxia"]),
    ("signup", {"query": "ZG Reset Run", "max_players": 20}, ["Sign Up", "ZG"]),
    ("signup", {"query": "BWL Progression Friday", "max_players": 40}, ["Sign Up", "BWL"]),
    ("signup", {"query": "Hateforge Quarry Guild Run", "max_players": 10}, ["Sign Up", "Hateforge"]),

    # 22. /macro
    ("macro", {"query": "stance dance overpower"}, ["Battle Stance", "Overpower", "Macro"]),
    ("macro", {"query": "mouseover heal"}, ["target=mouseover", "Macro"]),
    ("macro", {"query": "startattack sinister strike"}, ["startattack", "Macro"]),
    ("macro", {"query": "shoot wand cancel"}, ["Shoot", "Macro"]),
    ("macro", {"query": "spammable stealth"}, ["Stealth", "Macro"]),

    # 23. /ask
    ("ask", {"query": "what are the best pre-raid swords?"}, ["Sword", "Pre-Raid", "Dal'Rend"]),
    ("ask", {"query": "how does weapon skill work vs level 63 bosses?"}, ["Weapon Skill", "Glancing", "Boss"]),
    ("ask", {"query": "what level should i leave the barrens?"}, ["Barrens", "Level"]),
    ("ask", {"query": "what are the 9 custom dungeons on forever?"}, ["Dungeon", "Forever"]),
    ("ask", {"query": "how much gold is epic mount training?"}, ["Mount", "Gold", "Riding"])
]

async def run_all_tests():
    print("=" * 75)
    print("STARTING HOW-TO GUIDE COMPREHENSIVE VERIFICATION SUITE")
    print(f"Total Test Cases to Execute: {len(TEST_CASES)} (23 Slides x 5 Prompts)")
    print("=" * 75)

    cmd_map = {cmd.name: cmd for cmd in bot.bot.tree.get_commands()}
    passed = 0
    failed = 0
    errors = []

    for i, (cmd_name, kwargs, expected_terms) in enumerate(TEST_CASES, start=1):
        if cmd_name not in cmd_map:
            print(f"❌ #{i:03d} [{cmd_name}] -> Command not registered in bot tree!")
            failed += 1
            errors.append((cmd_name, kwargs, "Command not registered"))
            continue

        cmd = cmd_map[cmd_name]
        interaction = MockInteraction()
        try:
            # Execute callback with kwargs
            await cmd.callback(interaction, **kwargs)
            messages = interaction.get_all_messages()

            if not messages:
                print(f"❌ #{i:03d} [/{cmd_name} {kwargs}] -> No response message sent!")
                failed += 1
                errors.append((cmd_name, kwargs, "No response message sent"))
                continue

            # Extract text from content and embed fields
            full_text = ""
            for m in messages:
                if m.get("content"):
                    full_text += " " + str(m["content"])
                for emb in m.get("embeds", []):
                    if emb:
                        if getattr(emb, "title", None):
                            full_text += " " + str(emb.title)
                        if getattr(emb, "description", None):
                            full_text += " " + str(emb.description)
                        for f in getattr(emb, "fields", []):
                            full_text += f" {f.name} {f.value}"
                        if getattr(emb, "footer", None) and getattr(emb.footer, "text", None):
                            full_text += " " + str(emb.footer.text)

            # Check if any expected keyword exists (case-insensitive)
            matched = [t for t in expected_terms if t.lower() in full_text.lower()]
            if not matched:
                print(f"⚠️ #{i:03d} [/{cmd_name} {kwargs}] -> Text returned did not match expected terms: {expected_terms}")
                print(f"   Excerpt: {full_text[:180]}...")
                failed += 1
                errors.append((cmd_name, kwargs, f"Missing terms {expected_terms} in output"))
            else:
                arg_str = " ".join([f"{k}: {v}" for k, v in kwargs.items()])
                matched_str = ", ".join(matched[:2])
                print(f"✅ #{i:03d} [/{cmd_name} {arg_str}] -> OK (Matched: {matched_str})")
                passed += 1

        except Exception as e:
            tb = traceback.format_exc()
            print(f"💥 #{i:03d} [/{cmd_name} {kwargs}] -> EXCEPTION: {e}")
            failed += 1
            errors.append((cmd_name, kwargs, f"Exception: {e}"))

    print("\n" + "=" * 75)
    print(f"VERIFICATION RESULTS: {passed} PASSED / {failed} FAILED (Total: {len(TEST_CASES)})")
    if failed == 0:
        print("🎉 100% OF ALL 115 HOW-TO COMMANDS & PROMPT IDEAS VERIFIED WORKING!")
    else:
        print(f"⚠️ {failed} tests require attention:")
        for cmd_name, kwargs, reason in errors:
            print(f"  - /{cmd_name} {kwargs} -> {reason}")
    print("=" * 75)
    return passed, failed

if __name__ == "__main__":
    p, f = asyncio.run(run_all_tests())
    sys.exit(0 if f == 0 else 1)
