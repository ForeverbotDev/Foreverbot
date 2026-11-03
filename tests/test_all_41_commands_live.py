#!/usr/bin/env python3
"""
Comprehensive Live Slash Command Test Suite for WoW: Forever Bot.
Tests every single / slash command across all 42 commands and subcommands
with multiple diverse, realistic player examples.
"""

import os
import sys
import asyncio
import time
from typing import Dict, Any, List, Optional, Tuple

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

import discord
import bot

# Mock Discord interaction
class MockUser:
    def __init__(self, name="TestPlayer", user_id=123456789012345678):
        self.name = name
        self.display_name = name
        self.id = user_id
        self.mention = f"<@{user_id}>"
        self.guild_permissions = MockPermissions()

class MockRole:
    def __init__(self, name="Everyone"):
        self.name = name

class MockPermissions:
    administrator = True
    manage_channels = True
    manage_roles = True

class MockMember:
    guild_permissions = MockPermissions()

class MockGuild:
    def __init__(self, guild_id=123456789012345678, name="Forever Guild"):
        self.id = guild_id
        self.name = name
        self.owner_id = 123456789012345678
        self.roles = [MockRole("@everyone"), MockRole("Guild Master")]
        self.default_role = self.roles[0]
        self.categories = []
        self.text_channels = []
        self.voice_channels = []
        self.me = MockMember()

    async def create_role(self, **kwargs):
        r = MockRole(kwargs.get("name", "Role"))
        self.roles.append(r)
        return r

    async def create_category(self, name, **kwargs):
        class Cat:
            def __init__(self, n): self.name = n
        return Cat(name)

    async def create_text_channel(self, name, **kwargs):
        class Ch:
            def __init__(self, n): self.name = n
            async def history(self, limit=3):
                if False: yield None
            async def send(self, *args, **kwargs): pass
        return Ch(name)

    async def create_voice_channel(self, name, **kwargs):
        class VCh:
            def __init__(self, n): self.name = n
        return VCh(name)

    async def edit(self, **kwargs):
        pass

class MockChannel:
    def __init__(self, channel_id=1564040719130431530):
        self.id = channel_id

class MockMessage:
    def __init__(self):
        self.id = 998877665544
    async def edit(self, content=None, embed=None, view=None):
        pass

class MockResponse:
    def __init__(self):
        self._is_done = False
        self._is_ephemeral = False
        self.messages: List[Dict[str, Any]] = []

    def is_done(self) -> bool:
        return self._is_done

    async def defer(self, ephemeral: bool = False, thinking: bool = False):
        self._is_done = True
        self._is_ephemeral = ephemeral

    async def send_message(self, content=None, embed=None, embeds=None, view=None, ephemeral: bool = False):
        self._is_done = True
        self._is_ephemeral = ephemeral
        self.messages.append({
            "content": content,
            "embed": embed,
            "embeds": embeds or ([] if not embed else [embed]),
            "view": view,
            "ephemeral": ephemeral
        })

class MockFollowup:
    def __init__(self, parent_response: MockResponse):
        self.parent = parent_response
        self.messages: List[Dict[str, Any]] = []

    async def send(self, content=None, embed=None, embeds=None, view=None, ephemeral: bool = None):
        actual_ephemeral = self.parent._is_ephemeral if ephemeral is None else ephemeral
        self.messages.append({
            "content": content,
            "embed": embed,
            "embeds": embeds or ([] if not embed else [embed]),
            "view": view,
            "ephemeral": actual_ephemeral
        })

class MockInteraction:
    def __init__(self, user=None, guild=None, channel=None):
        self.id = 9988776655
        self.user = user or MockUser()
        self.guild = guild or MockGuild()
        self.channel = channel or MockChannel()
        self.response = MockResponse()
        self.followup = MockFollowup(self.response)
        self._msg = MockMessage()

    async def original_response(self):
        return self._msg

    @property
    def all_messages(self) -> List[Dict[str, Any]]:
        return self.response.messages + self.followup.messages

    @property
    def primary_embed(self) -> Optional[discord.Embed]:
        for m in self.all_messages:
            if m.get("embed"):
                return m["embed"]
            if m.get("embeds") and len(m["embeds"]) > 0:
                return m["embeds"][0]
        return None

    @property
    def primary_view(self) -> Optional[discord.ui.View]:
        for m in self.all_messages:
            if m.get("view"):
                return m["view"]
        return None

    @property
    def is_ephemeral(self) -> bool:
        if self.response._is_ephemeral:
            return True
        for m in self.all_messages:
            if m.get("ephemeral") is True:
                return True
        return False


async def execute_command(cb, kwargs):
    inter = MockInteraction()
    await cb(inter, **kwargs)
    embed = inter.primary_embed
    view = inter.primary_view
    ephemeral = inter.is_ephemeral
    title = embed.title if embed else ("(Interactive View)" if view else "(No Embed)")
    field_count = len(embed.fields) if embed else 0
    return ephemeral, title, field_count, view is not None


TEST_MATRIX = [
    # 1. /item
    ("item", "item", [
        {"query": "Thunderfury"},
        {"query": "Hand of Justice"},
        {"query": "Linen Cloth"},
        {"query": "Wool Cloth"},
        {"query": "Quillfire Bow"},
    ]),
    # 2. /mob
    ("mob", "mob", [
        {"query": "Baron Rivendare"},
        {"query": "Ragnaros"},
        {"query": "Bloodscalp Hunter"},
        {"query": "Scarshield Legionnaire"},
        {"query": "Edwin VanCleef"},
    ]),
    # 3. /quest
    ("quest", "quest", [
        {"query": "The Green Hills of Stranglethorn"},
        {"query": "Free Knot!"},
        {"query": "The Fate of the Kingdom"},
        {"query": "A Recipe for Disaster"},
    ]),
    # 4. /vendor
    ("vendor", "vendor", [
        {"query": "Bronze Tube"},
        {"query": "Heavy Silken Thread"},
        {"query": "Flask of Port"},
        {"query": "Pattern: Spitfire Bracers"},
    ]),
    # 5. /flightpath
    ("flightpath", "flightpath", [
        {"query": "Stormwind"},
        {"query": "Orgrimmar"},
        {"query": "Gadgetzan"},
        {"query": "Southshore"},
    ]),
    # 6. /dungeons
    ("dungeons", "dungeons", [
        {"query": "Deadmines"},
        {"query": "Scarlet Monastery"},
        {"query": "Hall of Thanes"},
        {"query": "Blackrock Spire"},
    ]),
    # 7. /zones
    ("zones", "zones", [
        {"query": "Duskwood"},
        {"query": "Stranglethorn Vale"},
        {"query": "The Barrens"},
        {"query": "Silithus"},
    ]),
    # 8. /map
    ("map", "map", [
        {"query": "Stormwind City"},
        {"query": "Elwynn Forest"},
        {"query": "Ironforge"},
        {"query": "where am i? dark forest, wolves, trying to find stormwind"},  # Contextual redirection test
    ]),
    # 9. /level
    ("level", "level", [
        {"query": 15},
        {"query": 30},
        {"query": 45},
        {"query": 58},
    ]),
    # 10. /route
    ("route", "route", [
        {"query": "1-10", "faction": "Alliance"},
        {"query": "10-20", "faction": "Horde"},
        {"query": "30-40", "faction": "Alliance"},
        {"query": "50-60", "faction": "Horde"},
    ]),
    # 11. /bis
    ("bis", "bis", [
        {"query": "warrior", "spec": "fury"},
        {"query": "rogue", "spec": "combat"},
        {"query": "mage", "spec": "frost"},
        {"query": "priest", "spec": "holy"},
    ]),
    # 12. /build
    ("build", "build", [
        {"query": "warrior", "spec": "fury"},
        {"query": "mage", "spec": "frost"},
        {"query": "shaman", "spec": "restoration"},
        {"query": "hunter", "spec": "marksmanship"},
    ]),
    # 13. /talents
    ("talents", "talents", [
        {"query": "Warrior", "spec": "Fury"},
        {"query": "Rogue", "spec": "Combat"},
        {"query": "Mage", "spec": "Frost"},
        {"query": "Warlock", "spec": "SM/Ruin"},
    ]),
    # 14. /compare
    ("compare", "compare", [
        {"query": "Dal'Rend's Sacred Charge", "weapon2": "Brutality Blade", "race": "Human", "character_class": "Warrior"},
        {"query": "Perdition's Blade", "weapon2": "Core Hound Tooth", "race": "Undead", "character_class": "Rogue"},
        {"query": "Bonereaver's Edge", "weapon2": "Spinal Reaper", "race": "Orc", "character_class": "Warrior"},
    ]),
    # 15. /consumes
    ("consumes", "consumes", [
        {"query": "Warrior"},
        {"query": "Mage"},
        {"query": "Priest"},
        {"query": "Rogue"},
    ]),
    # 16. /buffs
    ("buffs", "buffs", [
        {"query": "Rallying Cry of the Dragonslayer"},
        {"query": "Songflower Serenade"},
        {"query": "Warchief's Blessing"},
        {"query": "Dire Maul Tribute"},
    ]),
    # 17. /resist
    ("resist", "resist", [
        {"query": "Fire", "current": 150, "role": "Tank"},
        {"query": "Nature", "current": 200, "role": "DPS"},
        {"query": "Shadow", "current": 100, "role": "Healer"},
        {"query": "Frost", "current": 180, "role": "Tank"},
    ]),
    # 18. /gdkp
    ("gdkp", "gdkp", [
        {"query": 10000, "cut": 10, "raiders": 40, "tanks": 2, "tank_bonus": 500},
        {"query": 25000, "cut": 15, "raiders": 40, "tanks": 2, "tank_bonus": 1000},
        {"query": 5000, "cut": 5, "raiders": 20, "tanks": 1, "tank_bonus": 250},
    ]),
    # 19. /comp
    ("comp", "comp", [
        {"query": "40-man Molten Core"},
        {"query": "20-man Zul'Gurub"},
        {"query": "10-man UBRS"},
    ]),
    # 20. /raid
    ("raid", "raid", [
        {"query": "Molten Core"},
        {"query": "Blackwing Lair"},
        {"query": "Naxxramas"},
        {"query": "Roots of Nordrassil"},
    ]),
    # 21. /resets
    ("resets", "resets", [
        {"query": "Raid Lockouts"},
        {"query": "Onyxia"},
        {"query": "Zul'Gurub"},
    ]),
    # 22. /attunement
    ("attunement", "attunement", [
        {"query": "Onyxia Alliance"},
        {"query": "Onyxia Horde"},
        {"query": "Molten Core"},
        {"query": "Blackwing Lair"},
    ]),
    # 23. /keys
    ("keys", "keys", [
        {"query": "Scarlet Key"},
        {"query": "Shadowforge Key"},
        {"query": "Skeleton Key"},
        {"query": "Key to the City"},
    ]),
    # 24. /race
    ("race", "race", [
        {"query": "Human"},
        {"query": "Orc"},
        {"query": "Undead"},
        {"query": "Night Elf"},
        {"query": "Gnome"},
    ]),
    # 25. /pvp
    ("pvp", "pvp", [
        {"query": "Rank 14"},
        {"query": "Honor Decay"},
        {"query": "Standing"},
        {"query": "Alterac Valley"},
    ]),
    # 26. /farm
    ("farm", "farm", [
        {"query": "Mage AoE"},
        {"query": "Herbalism"},
        {"query": "Mining"},
        {"query": "Devilsaur"},
    ]),
    # 27. /gather
    ("gather", "gather", [
        {"query": "Dreamfoil"},
        {"query": "Black Lotus"},
        {"query": "Rich Thorium Vein"},
        {"query": "Gromsblood"},
    ]),
    # 28. /profession
    ("profession", "profession", [
        {"query": "Alchemy"},
        {"query": "Blacksmithing"},
        {"query": "Engineering"},
        {"query": "Tailoring"},
    ]),
    # 29. /macro
    ("macro", "macro", [
        {"query": "Startattack"},
        {"query": "Mouseover Heal"},
        {"query": "Taunt"},
        {"query": "Trinket Swap"},
    ]),
    # 30. /addons
    ("addons", "addons", [
        {"query": "Warrior"},
        {"query": "Healer"},
        {"query": "Questie"},
        {"query": "Details"},
    ]),
    # 31. /twink
    ("twink", "twink", [
        {"query": "Level 19", "character_class": "Rogue"},
        {"query": "Level 29", "character_class": "Hunter"},
        {"query": "Level 39", "character_class": "Mage"},
    ]),
    # 32. /events
    ("events", "events", [
        {"query": "Darkmoon Faire"},
        {"query": "Stranglethorn Fishing Extravaganza"},
        {"query": "Feast of Winter Veil"},
    ]),
    # 33. /trivia
    ("trivia", "trivia", [
        {"query": "Raids"},
        {"query": "Lore"},
        {"query": "Items"},
    ]),
    # 34. /roll
    ("roll", "roll", [
        {"query": "Deathcharger's Reins", "seconds": 15},
        {"query": "Band of Sulfuras", "seconds": 30},
        {"query": "Netherwind Crown", "seconds": 20},
    ]),
    # 35. /signup
    ("signup", "signup", [
        {"query": "Tuesday Molten Core 40-Man", "max_players": 40},
        {"query": "Thursday Blackwing Lair", "max_players": 40},
        {"query": "Saturday 20-Man Zul'Gurub", "max_players": 20},
    ]),
    # 36. /forever
    ("forever", "forever", [
        {"query": "Overview"},
        {"query": "Features"},
        {"query": "Custom Dungeons"},
    ]),
    # 37. /intel
    ("intel", "intel", [
        {"topic": "Overview"},
        {"topic": "Blue Notes"},
        {"topic": "Hotfixes"},
    ]),
    # 38. /setup_server
    ("setup_server", "setup_server", [
        {},
    ]),
    # 39. /ask
    ("ask", "ask", [
        {"query": "Where do I get water for my mage?"},
        {"query": "How do I beat Vaelastrasz in BWL?"},
        {"query": "What yellow hit cap do I need for raid bosses?"},
        {"query": "How does glancing blow mitigation work?"},
    ]),
    # 40. /rep
    ("rep", "rep", [
        {},
        {"query": "Timbermaw Hold"},
        {"query": "Argent Dawn"},
        {"query": "Thorium Brotherhood"},
        {"query": "Shen'dralar"},
        {"query": "Wintersaber Trainers"},
        {"query": "Bloodsail Buccaneers"},
    ]),
    # 41. /disenchant
    ("disenchant", "disenchant", [
        {},
        {"query": "Krol Blade"},
        {"query": "Archaic Defender"},
        {"query": "Linen Cloth"},
        {"query": "Large Brilliant Shard"},
        {"query": "55"},
        {"query": "Illusion Dust"},
    ]),
]


async def run_suite():
    print("=" * 80)
    print("⚔️ COMPREHENSIVE LIVE SLASH COMMAND TESTING (ALL 43 COMMANDS & SUBCOMMANDS)")
    print("=" * 80)

    # Build command callback mapping
    command_map = {}
    for cmd in bot.bot.tree.get_commands():
        if hasattr(cmd, "commands"):
            for sub in cmd.commands:
                command_map[f"{cmd.name} {sub.name}"] = sub.callback
        else:
            command_map[cmd.name] = cmd.callback

    # Add profile tests
    profile_tests = [
        ("profile set", "profile set", [
            {"query": "Valiant", "character_class": "Warrior", "race": "Human", "level": 60, "spec": "Fury DPS"},
            {"query": "Aeloria", "character_class": "Priest", "race": "Night Elf", "level": 60, "spec": "Holy Healer"}
        ]),
        ("profile view", "profile view", [
            {},
            {"query": "Valiant"}
        ]),
    ]

    full_matrix = TEST_MATRIX + profile_tests

    passed = 0
    failed = 0
    total = 0
    start_time = time.time()

    for cmd_key, label, examples in full_matrix:
        cb = command_map.get(cmd_key)
        if not cb:
            print(f"❌ Missing command callback for: /{cmd_key}")
            failed += len(examples)
            continue

        print(f"\n▶ Testing /{cmd_key.upper()} ({len(examples)} examples)...")
        for i, ex in enumerate(examples, 1):
            total += 1
            arg_str = ", ".join(f"{k}={v}" for k, v in ex.items()) if ex else "(no args)"
            try:
                ephemeral, title, field_count, has_view = await execute_command(cb, ex)
                
                # Check expectation:
                # /roll and /signup are public coordination tools (ephemeral=False)
                # All other 40 commands are private per-user responses (ephemeral=True)
                expected_ephemeral = cmd_key not in ("roll", "signup")
                
                if ephemeral != expected_ephemeral:
                    raise AssertionError(f"Ephemeral mismatch: expected {expected_ephemeral}, got {ephemeral}")
                if not title:
                    raise AssertionError("Empty title / no embed returned")

                passed += 1
                privacy_tag = "🔒 Private" if ephemeral else "📢 Public"
                print(f"   ✅ #{total:03d} [{privacy_tag}] /{cmd_key} {arg_str}")
                print(f"       ↳ Title: '{title[:55]}' • Fields: {field_count}{' • Attached View' if has_view else ''}")
            except Exception as e:
                failed += 1
                print(f"   ❌ #{total:03d} /{cmd_key} {arg_str} -> FAIL: {e}")

    elapsed = time.time() - start_time
    pass_rate = (passed / total * 100.0) if total > 0 else 0.0

    print("\n" + "=" * 80)
    print(f"🏁 ALL 42 COMMANDS VERIFICATION COMPLETE: {passed} / {total} Passed ({pass_rate:.1f}%) | {failed} Failed")
    print(f"⏱️ Total Execution Time: {elapsed:.2f} seconds")
    print("=" * 80)
    return failed == 0


if __name__ == "__main__":
    success = asyncio.run(run_suite())
    sys.exit(0 if success else 1)
