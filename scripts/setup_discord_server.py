#!/usr/bin/env python3
"""
Automated Discord Server Setup for World of Warcraft: Forever.
Builds complete channel hierarchy, categories, roles, permissions, and welcome embeds.
"""

import os
import sys
import asyncio
import discord
from dotenv import load_dotenv

load_dotenv()
TOKEN = os.getenv("DISCORD_BOT_TOKEN") or os.getenv("DISCORD_TOKEN")

if not TOKEN:
    print("❌ ERROR: DISCORD_BOT_TOKEN not found in environment or .env file.")
    sys.exit(1)

# Categories and their channels (type: text or voice, topic, is_read_only)
SERVER_STRUCTURE = [
    {
        "category": "📜 WELCOME & INFO",
        "channels": [
            {
                "name": "welcome-and-info",
                "type": "text",
                "topic": "Welcome to World of Warcraft: Forever! Rules, guide & bot introduction.",
                "read_only": True
            },
            {
                "name": "announcements",
                "type": "text",
                "topic": "Official guild announcements, realm news & raid events.",
                "read_only": True
            },
            {
                "name": "rules-and-guidelines",
                "type": "text",
                "topic": "Guild code of conduct, loot policies and raiding rules.",
                "read_only": True
            },
            {
                "name": "role-selection",
                "type": "text",
                "topic": "Select your class, faction and raid roles.",
                "read_only": True
            }
        ]
    },
    {
        "category": "⚔️ FOREVERBOT & COMPANION",
        "channels": [
            {
                "name": "bot-commands",
                "type": "text",
                "topic": "Dedicated channel to test slash commands: /item, /bis, /dungeons, /ask, /roll.",
                "read_only": False
            },
            {
                "name": "gear-and-drops",
                "type": "text",
                "topic": "Item discussions, pre-raid BiS theorycrafting and drop rate lookups.",
                "read_only": False
            },
            {
                "name": "boss-tactics",
                "type": "text",
                "topic": "Strategies for classic raid bosses and WoW Forever custom dungeons.",
                "read_only": False
            },
            {
                "name": "gdkp-and-economy",
                "type": "text",
                "topic": "Gold farming guides, consumable checklists and GDKP pot splits.",
                "read_only": False
            }
        ]
    },
    {
        "category": "🛡️ GUILD & RAIDING",
        "channels": [
            {
                "name": "raid-announcements",
                "type": "text",
                "topic": "Raid schedules, lockout timers and roster assignments.",
                "read_only": True
            },
            {
                "name": "raid-signups",
                "type": "text",
                "topic": "Active raid signups with interactive buttons (/signup).",
                "read_only": False
            },
            {
                "name": "raid-roster-discussion",
                "type": "text",
                "topic": "Group comp synergy, buffs, consumables & lineup planning.",
                "read_only": False
            },
            {
                "name": "loot-council",
                "type": "text",
                "topic": "Loot priority discussion and item distribution records.",
                "read_only": False
            }
        ]
    },
    {
        "category": "🍻 COMMUNITY & TAVERN",
        "channels": [
            {
                "name": "general-chat",
                "type": "text",
                "topic": "General chat for World of Warcraft: Forever players.",
                "read_only": False
            },
            {
                "name": "lfg-dungeons",
                "type": "text",
                "topic": "Looking for group (LFG) for 5-man leveling dungeons and attunements.",
                "read_only": False
            },
            {
                "name": "pvp-and-duels",
                "type": "text",
                "topic": "Battleground premades, world PvP defense calls and duel tactics.",
                "read_only": False
            },
            {
                "name": "professions-trading",
                "type": "text",
                "topic": "Crafting orders, rare recipe crafters and material bartering.",
                "read_only": False
            },
            {
                "name": "screenshots-and-clips",
                "type": "text",
                "topic": "Share your best in-game moments, drops and achievements.",
                "read_only": False
            }
        ]
    },
    {
        "category": "🔊 VOICE CHANNELS",
        "channels": [
            {
                "name": "🔊 General Voice",
                "type": "voice",
                "topic": "",
                "read_only": False
            },
            {
                "name": "⚔️ Raid 1 (40-Man)",
                "type": "voice",
                "topic": "",
                "read_only": False
            },
            {
                "name": "⚔️ Raid 2 (Alt / 20-Man)",
                "type": "voice",
                "topic": "",
                "read_only": False
            },
            {
                "name": "🗡️ Dungeon Group Alpha",
                "type": "voice",
                "topic": "",
                "read_only": False
            },
            {
                "name": "🗡️ Dungeon Group Beta",
                "type": "voice",
                "topic": "",
                "read_only": False
            },
            {
                "name": "💤 AFK Lounge",
                "type": "voice",
                "topic": "",
                "read_only": False
            }
        ]
    }
]

ROLES_TO_CREATE = [
    {"name": "👑 Guild Master", "color": discord.Color(0xF1C40F), "hoist": True, "mentionable": True},
    {"name": "⚔️ Officer / Raid Leader", "color": discord.Color(0x9B59B6), "hoist": True, "mentionable": True},
    {"name": "🛡️ Core Raider", "color": discord.Color(0xE67E22), "hoist": True, "mentionable": True},
    {"name": "🗡️ Member (Level 60)", "color": discord.Color(0x3498DB), "hoist": True, "mentionable": False},
    {"name": "🏹 Recruit / Leveling", "color": discord.Color(0x2ECC71), "hoist": True, "mentionable": False},
    {"name": "🤖 Foreverbot Companion", "color": discord.Color(0x1ABC9C), "hoist": True, "mentionable": False},
]

WELCOME_BANNER = """
# ⚔️ Welcome to World of Warcraft: Forever!
> *The definitive guild & companion hub for World of Warcraft: Forever.*

### 🛡️ About This Community
Welcome to our guild server! Whether you're speed-leveling, farming pre-raid BiS, progressing through custom dungeons like **Hall of Thanes** and **Shaper's Terrace**, or preparing for 40-man Molten Core, this server is built to help our team succeed.

---

### 🤖 Foreverbot In-Game Companion
Our server is equipped with **Foreverbot** (`/`), providing instant game lookups, raid tools, and directions right inside Discord:

• **Private Per-User Replies:** When you run `/item`, `/bis`, `/dungeons`, or `/ask`, only you see the answer (`ephemeral`) so channels stay clean!
• **Raid Signups & Rolls:** Join raids with 1-click in <#raid-signups> using interactive buttons.
• **Complete 20,800+ Catalog:** Drop tables, quest objectives, and flightpaths are always accessible.

Head over to <#bot-commands> to test your first command!
"""

BOT_COMMANDS_CHEAT_SHEET = """
# 📖 Foreverbot Command Cheat Sheet

Try running these slash commands anywhere:

### 🗡️ Gear, Items & Loot
• `/item query: dal rend` — Instant item stats, weapon speed & drop locations.
• `/bis class: Warrior phase: Pre-raid` — Full best-in-slot gear list with drop sources.
• `/compare item1: Brutality Blade item2: Deathbringer race: Human` — Weapon comparison & boss glancing blow analysis.
• `/resist school: Fire value: 150` — Resistance tier mitigation percentage.

### 🏰 Dungeons & Progression
• `/dungeons level: 45` — Find all eligible classic & WoW Forever dungeons for your level.
• `/dungeons query: Hall of Thanes` — Level brackets, zone coordinates & boss lists.
• `/attunement query: Blackwing Lair` — Step-by-step attunement walkthrough.
• `/keys query: Shadowforge Key` — How to obtain every dungeon key.

### 🧭 Navigation & Leveling
• `/map zone: The Barrens` — Level ranges, connected zones, dungeons & flightpaths.
• `/flight query: Stormwind to Ironforge` — Taxi routes, connections & coords.
• `/route level: 10-20 faction: Alliance` — Optimized speedleveling questing path.

### ⚔️ Raiding & Guild Management
• `/signup title: Molten Core 40-Man date: Friday 8PM` — Interactive 1-click raid signup roster.
• `/roll dice: 100` — Public interactive dice roll with high-roller highlight.
• `/gdkp pot: 60000 cut: 10 bonus: 2 bonus_count: 2` — Automatic gold split calculator.
• `/comp warriors: 8 rogues: 6 mages: 5 priests: 4` — 40-man raid team synergy audit.
• `/resets` — Real-time countdown to Tuesday realm resets & raid lockouts.
"""

async def setup_server(guild_id: int):
    intents = discord.Intents.default()
    intents.guilds = True
    client = discord.Client(intents=intents)

    @client.event
    async def on_ready():
        print(f"Logged in as {client.user} ({client.user.id})")
        guild = client.get_guild(guild_id)
        if not guild:
            print(f"❌ Could not find guild with ID: {guild_id}")
            print(f"Available guilds: {[f'{g.name} ({g.id})' for g in client.guilds]}")
            await client.close()
            return

        print(f"\n🚀 Beginning Automated Server Setup for: {guild.name} ({guild.id})")
        
        # Check permissions
        me = guild.me
        if not me.guild_permissions.administrator and not (me.guild_permissions.manage_channels and me.guild_permissions.manage_roles):
            print("\n⚠️ WARNING: Foreverbot does not have Manage Channels and Manage Roles permissions in this server.")
            print("Please grant Foreverbot 'Manage Channels' and 'Manage Roles' in Server Settings -> Roles, or re-authorize using:")
            print(f"https://discord.com/oauth2/authorize?client_id={client.user.id}&permissions=268812840&scope=bot%20applications.commands")
            await client.close()
            return

        # 1. Create Roles
        print("\n[1/4] Configuring Server Roles...")
        existing_role_names = {r.name.lower(): r for r in guild.roles}
        created_roles = {}
        for r_spec in ROLES_TO_CREATE:
            if r_spec["name"].lower() not in existing_role_names:
                try:
                    new_role = await guild.create_role(
                        name=r_spec["name"],
                        color=r_spec["color"],
                        hoist=r_spec["hoist"],
                        mentionable=r_spec["mentionable"],
                        reason="Automated WoW Forever server setup"
                    )
                    created_roles[r_spec["name"]] = new_role
                    print(f"  ✅ Created role: {r_spec['name']}")
                except Exception as e:
                    print(f"  ❌ Failed to create role {r_spec['name']}: {e}")
            else:
                created_roles[r_spec["name"]] = existing_role_names[r_spec["name"].lower()]
                print(f"  ℹ️ Role already exists: {r_spec['name']}")

        # 2. Update Server Icon if asset exists
        icon_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "assets", "server_icon.jpg"))
        if os.path.exists(icon_path):
            print("\n[2/4] Setting Server Icon Logo...")
            try:
                with open(icon_path, "rb") as f:
                    icon_bytes = f.read()
                await guild.edit(icon=icon_bytes, reason="Automated WoW Forever icon update")
                print("  ✅ Successfully uploaded server logo!")
            except Exception as e:
                print(f"  ℹ️ Notice on icon upload: {e} (You can also upload it manually from Downloads)")

        # 3. Create Categories and Channels
        print("\n[3/4] Creating Categories & Channels...")
        created_channels = {}
        everyone_role = guild.default_role

        for cat_spec in SERVER_STRUCTURE:
            cat_name = cat_spec["category"]
            category = discord.utils.get(guild.categories, name=cat_name)
            if not category:
                try:
                    category = await guild.create_category(cat_name, reason="Automated WoW Forever setup")
                    print(f"\n📂 Created Category: {cat_name}")
                except Exception as e:
                    print(f"\n❌ Failed to create category {cat_name}: {e}")
                    continue
            else:
                print(f"\n📂 Category exists: {cat_name}")

            for ch_spec in cat_spec["channels"]:
                ch_name = ch_spec["name"]
                ch_type = ch_spec["type"]
                topic = ch_spec.get("topic", "")
                read_only = ch_spec.get("read_only", False)

                # Overwrite permissions for read-only channels
                overwrites = {}
                if read_only:
                    overwrites[everyone_role] = discord.PermissionOverwrite(
                        send_messages=False,
                        add_reactions=True,
                        read_messages=True
                    )
                    # Allow officers / GM to post
                    for r_name in ["👑 Guild Master", "⚔️ Officer / Raid Leader"]:
                        if r_name in created_roles:
                            overwrites[created_roles[r_name]] = discord.PermissionOverwrite(
                                send_messages=True,
                                manage_messages=True
                            )

                if ch_type == "text":
                    existing_ch = discord.utils.get(guild.text_channels, name=ch_name, category=category)
                    if not existing_ch:
                        try:
                            new_ch = await guild.create_text_channel(
                                ch_name,
                                category=category,
                                topic=topic,
                                overwrites=overwrites if read_only else None,
                                reason="Automated WoW Forever setup"
                            )
                            created_channels[ch_name] = new_ch
                            print(f"  #️⃣ Created text channel: #{ch_name}")
                        except Exception as e:
                            print(f"  ❌ Error creating text channel #{ch_name}: {e}")
                    else:
                        created_channels[ch_name] = existing_ch
                        print(f"  #️⃣ Channel already exists: #{ch_name}")

                elif ch_type == "voice":
                    existing_v = discord.utils.get(guild.voice_channels, name=ch_name, category=category)
                    if not existing_v:
                        try:
                            await guild.create_voice_channel(
                                ch_name,
                                category=category,
                                reason="Automated WoW Forever setup"
                            )
                            print(f"  🔊 Created voice channel: {ch_name}")
                        except Exception as e:
                            print(f"  ❌ Error creating voice channel {ch_name}: {e}")
                    else:
                        print(f"  🔊 Voice channel already exists: {ch_name}")

        # 4. Post Welcome Embeds & Cheatsheet
        print("\n[4/4] Posting Guides & Cheatsheets...")
        if "welcome-and-info" in created_channels:
            welcome_ch = created_channels["welcome-and-info"]
            # Check if already posted
            hist = [m async for m in welcome_ch.history(limit=5)]
            if not hist:
                try:
                    embed = discord.Embed(
                        title="⚔️ World of Warcraft: Forever — Guild & Discord Hub",
                        description=WELCOME_BANNER,
                        color=0xF59E0B
                    )
                    embed.set_footer(text="World of Warcraft: Forever • Companion Server")
                    await welcome_ch.send(embed=embed)
                    print("  ✅ Posted welcome embed to #welcome-and-info")
                except Exception as e:
                    print(f"  ❌ Could not post to #welcome-and-info: {e}")

        if "bot-commands" in created_channels:
            cmd_ch = created_channels["bot-commands"]
            hist = [m async for m in cmd_ch.history(limit=5)]
            if not hist:
                try:
                    embed = discord.Embed(
                        title="📖 Foreverbot Command Hub",
                        description=BOT_COMMANDS_CHEAT_SHEET,
                        color=0x3498DB
                    )
                    embed.set_footer(text="Foreverbot • 40 Slash Commands Ready")
                    await cmd_ch.send(embed=embed)
                    print("  ✅ Posted command cheatsheet to #bot-commands")
                except Exception as e:
                    print(f"  ❌ Could not post to #bot-commands: {e}")

        print("\n🎉 ALL DONE! Your Discord server has been completely set up and structured.")
        await client.close()

    await client.start(TOKEN)


if __name__ == "__main__":
    target_guild_id = None
    if len(sys.argv) > 1:
        try:
            target_guild_id = int(sys.argv[1])
        except ValueError:
            print("Please pass a valid integer Guild ID.")
            sys.exit(1)
    else:
        env_guild = os.environ.get("TARGET_GUILD_ID")
        if env_guild and env_guild.isdigit():
            target_guild_id = int(env_guild)
        else:
            print("Usage: python scripts/setup_discord_server.py <GUILD_ID>")
            print("Or set TARGET_GUILD_ID in your environment.")
            sys.exit(1)

    asyncio.run(setup_server(target_guild_id))
