"""World of Warcraft: Forever - Intelligent Discord Companion Bot.

Features fuzzy typo-tolerance, friendly conversational assistance,
condensed gaming-focused embeds, and 100% accurate Classic and Classic+ data.
"""

import os
import re
import difflib
import asyncio
from typing import Optional, List, Dict, Any
import discord
from discord import app_commands
from discord.ext import commands
from dotenv import load_dotenv
from database import WoWForeverDB, DB_PATH, extract_level_from_text
import knowledge_engine as ke
from knowledge_engine import (
    get_level_advice, ATTUNEMENTS, TRAVEL_ROUTES, GAMEPLAY_MECHANICS,
    get_gathering_info, get_profession_info, GATHERING_NODES, PROFESSIONS_DATA,
    get_class_build, CLASS_BUILDS, get_consumables_info, CONSUMABLES_DATA,
    get_world_buff_info, WORLD_BUFFS_DATA, get_raid_boss_info, RAID_BOSSES_DATA,
    get_reputation_info, REPUTATIONS_DATA,
    get_macro_info, MACRO_TEMPLATES,
    get_pvp_info, PVP_SYSTEM_DATA,
    get_dungeon_key_info, DUNGEON_KEYS,
    get_racial_info, RACIAL_TRAITS,
    get_attunement_info,
    analyze_raid_comp,
    get_bis_list,
    get_gold_farm_info,
    get_world_events_info,
    calculate_gdkp,
    compare_weapons,
    get_raid_lockouts,
    get_twink_info, TWINK_DATA,
    get_leveling_route, LEVELING_ROUTES,
    get_addon_info, ADDONS_DATA,
    get_random_trivia, TRIVIA_QUESTIONS,
    calculate_resistance_mitigation, RESIST_SCHOOLS,
    get_duel_matchup, DUEL_MATCHUPS,
    get_talent_build, TALENTS_DATA
)

# Load environment variables
load_dotenv()
TOKEN = os.getenv("DISCORD_BOT_TOKEN") or os.getenv("DISCORD_TOKEN")
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

# Initialize DB
db = WoWForeverDB(DB_PATH)

# Initialize Bot
intents = discord.Intents.default()
bot = commands.Bot(command_prefix="!", intents=intents)

# WoW Quality Colors
QUALITY_COLORS = {
    "Poor": 0x9D9D9D,
    "Common": 0xFFFFFF,
    "Uncommon": 0x1EFF00,
    "Rare": 0x0070DD,
    "Epic": 0xA335EE,
    "Legendary": 0xFF8000,
    "Artifact": 0xE6CC80,
}


def format_money(copper: int) -> str:
    """Formats copper amount into Gold, Silver, and Copper strings."""
    if copper <= 0:
        return "Free"
    gold = copper // 10000
    silver = (copper % 10000) // 100
    c = copper % 100

    parts = []
    if gold > 0:
        parts.append(f"{gold}g")
    if silver > 0:
        parts.append(f"{silver}s")
    if c > 0 or not parts:
        parts.append(f"{c}c")
    return " ".join(parts)


@bot.event
async def on_ready():
    print(f"Logged in as {bot.user.name} ({bot.user.id})")
    try:
        # Sync globally
        synced = await bot.tree.sync()
        print(f"Synced {len(synced)} global slash commands.")

        # Sync directly to each connected server for instant update
        for guild in bot.guilds:
            try:
                bot.tree.copy_global_to(guild=guild)
                guild_synced = await bot.tree.sync(guild=guild)
                print(f"Instantly synced {len(guild_synced)} commands to server: {guild.name} ({guild.id})")
            except Exception as ge:
                print(f"Guild sync notice for {guild.name}: {ge}")
    except Exception as e:
        print(f"Error syncing commands: {e}")
    await bot.change_presence(
        activity=discord.Game(name="WoW: Forever (Classic+) | /map | /dungeons | /ask")
    )


@bot.tree.error
async def on_app_command_error(interaction: discord.Interaction, error: app_commands.AppCommandError):
    print(f"🚨 [COMMAND ERROR] {interaction.command.name if interaction.command else 'Unknown'}: {error}")
    try:
        if not interaction.response.is_done():
            await interaction.response.send_message(f"⚠️ Error executing command: `{error}`", ephemeral=True)
        else:
            await interaction.followup.send(f"⚠️ Error executing command: `{error}`", ephemeral=True)
    except Exception as e:
        print(f"Failed to send error response: {e}")


@bot.event
async def on_app_command_completion(interaction: discord.Interaction, command: app_commands.Command):
    print(f"✅ [COMMAND USED] User: {interaction.user} | Command: /{command.name} | Data: {interaction.data.get('options', [])}")


def parse_key_value(text: str) -> Dict[str, str]:
    """Parses clean key: value lines from LLM responses."""
    data = {}
    for line in text.strip().splitlines():
        line = line.strip()
        if ":" in line:
            parts = line.split(":", 1)
            k = parts[0].strip().upper().replace("*", "").replace("-", "")
            v = parts[1].strip().replace("*", "")
            data[k] = v
    return data


def run_gemini_sync(prompt: str) -> Optional[str]:
    """Runs synchronous Gemini call in background thread with flash-lite model."""
    if not GEMINI_API_KEY:
        return None
    try:
        from google import genai
        client = genai.Client(api_key=GEMINI_API_KEY)
        for m in ["gemini-3.5-flash-lite", "gemini-3.8-flash", "gemini-3.5-flash"]:
            try:
                res = client.models.generate_content(model=m, contents=prompt)
                if res and res.text:
                    return res.text
            except Exception as e:
                print(f"Gemini {m} notice: {e}")
                continue
    except Exception as ge:
        print(f"Gemini client error: {ge}")
    return None


async def query_gemini_text(prompt: str) -> Optional[str]:
    """Non-blocking asynchronous wrapper around Gemini API."""
    return await asyncio.to_thread(run_gemini_sync, prompt)


def is_general_level_query(text: str) -> bool:
    """Disambiguates generic level requests from specific item, mount, or skill queries."""
    t = text.lower().strip()
    if t.isdigit() or t.startswith("lvl ") or t.startswith("level "):
        words = t.split()
        if len(words) <= 2:
            return True
    specific_keywords = [
        "wand", "wands", "mount", "mounts", "riding", "horse", "wolf", "kodo", "ram", "mechanostrider",
        "weapon", "weapons", "axe", "sword", "mace", "dagger", "bow", "gun", "staff",
        "pet", "pets", "tame", "taming", "cost", "buy", "vendor", "sell", "trainer", "talent",
        "attunement", "armor", "plate", "mail", "leather", "cloth", "dual wield",
        "hit cap", "defense cap", "how much", "price", "whirlwind"
    ]
    if any(k in t for k in specific_keywords):
        return False
    general_keywords = [
        "dungeon", "dungeons", "where to", "where do", "zone", "zones", "questing",
        "progression", "guide", "what to do", "route", "bracket", "grind"
    ]
    return any(k in t for k in general_keywords) or len(t.split()) <= 3


def handle_after_zone(question: str) -> Optional[Dict[str, Any]]:
    """Answers queries like 'where do i lvl after duskwood' using authoritative zone progression."""
    import re
    from knowledge_engine import get_zone_info, get_level_advice
    from database import ZONE_ALIASES
    m = re.search(r"\b(?:after|past|leave)\s+(?:the\s+)?([a-zA-Z\s\'-]+)", question.lower())
    if not m:
        return None
    raw_zone = m.group(1).replace("zone", "").replace("questing", "").replace("leveling", "").replace("?", "").strip()
    zone_info = get_zone_info(raw_zone, ZONE_ALIASES)
    if not zone_info:
        return None
    lvl_str = zone_info.get("level", "")
    nums = re.findall(r"\d+", lvl_str)
    if not nums:
        return None
    max_lvl = int(nums[-1])
    next_lvl = min(60, max_lvl + 1)
    advice = get_level_advice(next_lvl)
    dungs, _ = db.search_dungeons(level=next_lvl, limit=3)
    return {
        "from_zone": zone_info["name"],
        "from_level": zone_info["level"],
        "next_level": next_lvl,
        "advice": advice,
        "dungeons": dungs
    }


def is_travel_query(text: str) -> bool:
    """Detects transit/navigation inquiries requiring route guidance."""
    t = text.lower()
    return any(p in t for p in [
        "how to get from", "how do i get from", "travel from", "route from", "way from",
        "how to get to", "how do i get to", "travel to", "route to", "directions to", "way to",
        "getting to", "path to", "boat to", "zeppelin to", "tram to"
    ])


# -------------------------------------------------------------
# Slash Command: /item
# -------------------------------------------------------------
@bot.tree.command(name="item", description="Look up any item, weapon, or armor (Condensed & Typo-Tolerant)")
@app_commands.describe(query="Item name (e.g. 'Ironfoe', 'Wool Cloth', 'Ravager', 'Skyborne')")
async def item_command(interaction: discord.Interaction, query: str):
    name = query
    await interaction.response.defer(ephemeral=True)
    items, did_you_mean = db.search_items(name, limit=1)
    if items:
        item = items[0]
        color = QUALITY_COLORS.get(item["quality"], 0xFFFFFF)
        badge = "🌟 [Forever] " if item["is_forever_content"] else ""

        meta = []
        if item["slot"]:
            meta.append(f"**Slot:** {item['slot']}")
        if item["item_type"]:
            meta.append(f"**Type:** {item['item_type']}")
        meta.append(f"**Req:** Lvl {item['req_level']}")
        meta.append(f"**iLvl:** {item['item_level']}")

        desc_lines = [" • ".join(meta)]
        if item["stats"]:
            desc_lines.append(f"**Stats:** {item['stats']}")
        if item["description"]:
            desc_lines.append(f"**Effect:** *{item['description']}*")
        if item["source"]:
            desc_lines.append(f"**Source:** {item['source']}")
        if item.get("pro_tip"):
            desc_lines.append(f"💡 *Tip:* {item['pro_tip']}")

        embed = discord.Embed(
            title=f"{badge}{item['name']} ({item['quality']})",
            description="\n".join(desc_lines),
            color=color
        )
        if did_you_mean:
            embed.set_author(name=f"Corrected typo from '{name}'")
        embed.set_footer(text="World of Warcraft: Forever Companion")
        await interaction.followup.send(embed=embed)
        return

    # Fallback to Gemini if item not in offline database
    prompt = f"""
    You are Foreverbot, an expert World of Warcraft: Forever (Classic+) database assistant.
    The user is looking up the item: "{name}".
    Is this a real World of Warcraft (Classic Era or Classic+) item?
    If NO, respond with ONLY: NOT_FOUND
    If YES, provide the following structured breakdown:
    NAME: [Exact proper-cased item name]
    QUALITY: [Poor/Common/Uncommon/Rare/Epic/Legendary]
    REQ_LVL: [Required level or 1]
    ILVL: [Item Level]
    SLOT: [Equipment slot, or 'Inventory' or 'Consumable' or 'Container' or 'Key']
    TYPE: [Item type, e.g. 'Cloth', 'Two-Hand Axe', 'Potion', 'Reagent', 'Bag']
    STATS: [Key stats, or 'None']
    EFFECT: [Equip/Use/Proc effect, or 'None']
    SOURCE: [Where it drops, who drops it, quest, or vendor]
    TIP: [Best farming zone/dungeon, crafting use, or leveling tip]
    """
    ai_text = await query_gemini_text(prompt)
    if ai_text and "NOT_FOUND" not in ai_text:
        parsed = parse_key_value(ai_text)
        if parsed.get("NAME"):
            meta = []
            if parsed.get("SLOT") and parsed["SLOT"].lower() != "none":
                meta.append(f"**Slot:** {parsed['SLOT']}")
            if parsed.get("TYPE") and parsed["TYPE"].lower() != "none":
                meta.append(f"**Type:** {parsed['TYPE']}")
            meta.append(f"**Req:** Lvl {parsed.get('REQ_LVL', '1')}")
            meta.append(f"**iLvl:** {parsed.get('ILVL', '1')}")

            desc_lines = [" • ".join(meta)]
            if parsed.get("STATS") and parsed["STATS"].lower() != "none":
                desc_lines.append(f"**Stats:** {parsed['STATS']}")
            if parsed.get("EFFECT") and parsed["EFFECT"].lower() != "none":
                desc_lines.append(f"**Effect:** *{parsed['EFFECT']}*")
            if parsed.get("SOURCE") and parsed["SOURCE"].lower() != "none":
                desc_lines.append(f"**Source:** {parsed['SOURCE']}")
            if parsed.get("TIP") and parsed["TIP"].lower() != "none":
                desc_lines.append(f"💡 *Tip:* {parsed['TIP']}")

            color = QUALITY_COLORS.get(parsed.get("QUALITY", "Common"), 0xFFFFFF)
            embed = discord.Embed(
                title=f"{parsed.get('NAME', name)} ({parsed.get('QUALITY', 'Common')})",
                description="\n".join(desc_lines),
                color=color
            )
            embed.set_footer(text="World of Warcraft: Forever Companion")
            await interaction.followup.send(embed=embed)
            return

    await interaction.followup.send(
        f"❌ Item `{name}` not found. Check spelling or try `/ask`!",
        ephemeral=True
    )


@item_command.autocomplete("query")
async def item_autocomplete(interaction: discord.Interaction, current: str) -> List[app_commands.Choice[str]]:
    choices = db.autocomplete_items(current, limit=25)
    return [app_commands.Choice(name=c["name"], value=c["value"]) for c in choices]



# -------------------------------------------------------------
# Slash Command: /quest
# -------------------------------------------------------------
@bot.tree.command(name="quest", description="Look up quest giver, coords & objectives (Condensed)")
@app_commands.describe(query="Quest title or keywords (e.g. 'Mankrik', 'Nordrassil', 'Green Hills')")
async def quest_command(interaction: discord.Interaction, query: str):
    title = query
    await interaction.response.defer(ephemeral=True)
    quests, did_you_mean = db.search_quests(title, limit=1)
    if quests:
        quest = quests[0]
        badge = "🌟 [Forever] " if quest["is_forever_content"] else ""

        lines = [
            f"**Zone:** {quest['zone']} • **Quest Lvl:** {quest['quest_level']} (Req {quest['req_level']}) • **Faction:** {quest['faction']}",
            f"**Giver:** {quest['start_npc']}" + (f" `({quest['start_location']})`" if quest["start_location"] else ""),
            f"**Objective:** {quest['objectives']}"
        ]
        if quest.get("rewards"):
            lines.append(f"**Rewards:** {quest['rewards']}")
        if quest.get("pro_tip"):
            lines.append(f"💡 *Tip:* {quest['pro_tip']}")

        embed = discord.Embed(
            title=f"📜 {badge}{quest['title']}",
            description="\n".join(lines),
            color=0xF1C40F
        )
        if did_you_mean:
            embed.set_author(name=f"Corrected typo from '{title}'")
        embed.set_footer(text="World of Warcraft: Forever Companion")
        await interaction.followup.send(embed=embed)
        return

    # Fallback to Gemini
    prompt = f"""
    You are Foreverbot, an expert World of Warcraft: Forever (Classic+) database assistant.
    The user is looking up the quest: "{title}".
    Is this a real World of Warcraft (Classic Era or Classic+) quest?
    If NO, respond with ONLY: NOT_FOUND
    If YES, provide the following structured breakdown:
    TITLE: [Exact quest title]
    ZONE: [Zone name]
    QUEST_LVL: [Quest level]
    REQ_LVL: [Required level]
    FACTION: [Alliance/Horde/Both]
    GIVER: [Quest giver NPC and coordinates if known]
    OBJECTIVE: [Concise 1-2 sentence objective]
    REWARDS: [Key rewards or item choices]
    TIP: [Key tip for completing]
    """
    ai_text = await query_gemini_text(prompt)
    if ai_text and "NOT_FOUND" not in ai_text:
        parsed = parse_key_value(ai_text)
        if parsed.get("TITLE"):
            lines = [
                f"**Zone:** {parsed.get('ZONE', 'Unknown')} • **Quest Lvl:** {parsed.get('QUEST_LVL', '1')} (Req {parsed.get('REQ_LVL', '1')}) • **Faction:** {parsed.get('FACTION', 'Both')}",
                f"**Giver:** {parsed.get('GIVER', 'Unknown')}",
                f"**Objective:** {parsed.get('OBJECTIVE', 'N/A')}"
            ]
            if parsed.get("REWARDS") and parsed["REWARDS"].lower() != "none":
                lines.append(f"**Rewards:** {parsed['REWARDS']}")
            if parsed.get("TIP") and parsed["TIP"].lower() != "none":
                lines.append(f"💡 *Tip:* {parsed['TIP']}")

            embed = discord.Embed(
                title=f"📜 {parsed['TITLE']}",
                description="\n".join(lines),
                color=0xF1C40F
            )
            embed.set_footer(text="World of Warcraft: Forever Companion")
            await interaction.followup.send(embed=embed)
            return

    await interaction.followup.send(
        f"❌ Quest `{title}` not found. Check spelling or try `/ask`!",
        ephemeral=True
    )


@quest_command.autocomplete("query")
async def quest_autocomplete(interaction: discord.Interaction, current: str) -> List[app_commands.Choice[str]]:
    current_l = current.lower()
    matches = [q for q in db.quest_titles if current_l in q.lower()]
    matches.sort(key=lambda x: (not x.lower().startswith(current_l), x.lower()))
    return [app_commands.Choice(name=m[:100], value=m[:100]) for m in matches[:25]]


# -------------------------------------------------------------
# Slash Command: /mob
# -------------------------------------------------------------
@bot.tree.command(name="mob", description="Look up mob/boss location, strategy & loot drops (Condensed)")
@app_commands.describe(query="Mob or boss name (e.g. 'Emperor Dagran', 'Herod', 'Ragnaros')")
async def mob_command(interaction: discord.Interaction, query: str):
    name = query
    await interaction.response.defer(ephemeral=True)
    mobs, did_you_mean = db.search_creatures(name, limit=1)
    if mobs:
        mob = mobs[0]
        badge = "🌟 [Forever] " if mob["is_forever_content"] else ""
        lvl_str = f"Level {mob['level_min']}" if mob["level_min"] == mob["level_max"] else f"Level {mob['level_min']}-{mob['level_max']}"

        lines = [
            f"**Location:** {mob['zone']}" + (f" `({mob['location_details']})`" if mob.get("location_details") else "")
        ]
        if mob.get("loot"):
            loot_items = [f"{d['name']} ({d['drop_chance']}%)" for d in mob["loot"][:4]]
            lines.append(f"**Notable Loot:** {', '.join(loot_items)}")
        if mob.get("strategy_notes"):
            lines.append(f"⚔️ **Strategy:** {mob['strategy_notes']}")

        embed = discord.Embed(
            title=f"💀 {badge}{mob['name']} ({mob['classification']} • {lvl_str})",
            description="\n".join(lines),
            color=0xE74C3C if "Boss" in mob["classification"] or "Elite" in mob["classification"] else 0x95A5A6
        )
        if did_you_mean:
            embed.set_author(name=f"Corrected typo from '{name}'")
        embed.set_footer(text="World of Warcraft: Forever Companion")
        await interaction.followup.send(embed=embed)
        return

    # Fallback to Gemini
    prompt = f"""
    You are Foreverbot, an expert World of Warcraft: Forever (Classic+) database assistant.
    The user is looking up the creature/boss: "{name}".
    Is this a real World of Warcraft (Classic Era or Classic+) creature?
    If NO, respond with ONLY: NOT_FOUND
    If YES, provide the following structured breakdown:
    NAME: [Exact proper-cased creature name]
    ZONE: [Zone or dungeon name]
    LOCATION: [Specific coordinates or area inside zone/dungeon]
    LEVEL: [Level or level range]
    CLASSIFICATION: [Normal/Elite/Rare/Boss/World Boss]
    LOOT: [Top 2-4 notable item drops]
    STRATEGY: [1-2 concise tactical tips]
    """
    ai_text = await query_gemini_text(prompt)
    if ai_text and "NOT_FOUND" not in ai_text:
        parsed = parse_key_value(ai_text)
        if parsed.get("NAME"):
            lines = [
                f"**Location:** {parsed.get('ZONE', 'Unknown')}" + (f" `({parsed['LOCATION']})`" if parsed.get("LOCATION") and parsed["LOCATION"].lower() != "none" else "")
            ]
            if parsed.get("LOOT") and parsed["LOOT"].lower() != "none":
                lines.append(f"**Notable Loot:** {parsed['LOOT']}")
            if parsed.get("STRATEGY") and parsed["STRATEGY"].lower() != "none":
                lines.append(f"⚔️ **Strategy:** {parsed['STRATEGY']}")

            classification = parsed.get("CLASSIFICATION", "Normal")
            color = 0xE74C3C if "boss" in classification.lower() or "elite" in classification.lower() else 0x95A5A6
            embed = discord.Embed(
                title=f"💀 {parsed['NAME']} ({classification} • Level {parsed.get('LEVEL', '??')})",
                description="\n".join(lines),
                color=color
            )
            embed.set_footer(text="World of Warcraft: Forever Companion")
            await interaction.followup.send(embed=embed)
            return

    await interaction.followup.send(
        f"❌ Creature `{name}` not found. Check spelling or try `/ask`!",
        ephemeral=True
    )


@mob_command.autocomplete("query")
async def mob_autocomplete(interaction: discord.Interaction, current: str) -> List[app_commands.Choice[str]]:
    current_l = current.lower()
    matches = [m for m in db.creature_names if current_l in m.lower()]
    matches.sort(key=lambda x: (not x.lower().startswith(current_l), x.lower()))
    return [app_commands.Choice(name=m[:100], value=m[:100]) for m in matches[:25]]


# -------------------------------------------------------------
# Slash Command: /vendor
# -------------------------------------------------------------
@bot.tree.command(name="vendor", description="Find NPC merchants selling an item (Condensed)")
@app_commands.describe(query="Item name (e.g. 'Bronze Tube', 'Heavy Leather', 'Rucksack')")
async def vendor_command(interaction: discord.Interaction, query: str):
    item_name = query
    await interaction.response.defer(ephemeral=True)
    vendors, did_you_mean = db.search_vendors(item_name, limit=4)
    if vendors:
        target = did_you_mean if did_you_mean else item_name
        lines = []
        for v in vendors:
            cost = format_money(v["cost_copper"])
            coord = f" `({v['coordinates']})`" if v["coordinates"] else ""
            stock = " *(Limited)*" if v["limited_stock"] > 0 else ""
            lines.append(f"• **{v['npc_name']}** — {v['zone']}{coord} • **{cost}**{stock}")

        embed = discord.Embed(
            title=f"🛒 Vendors Selling: {target}",
            description="\n".join(lines),
            color=0x2ECC71
        )
        if did_you_mean:
            embed.set_author(name=f"Corrected typo from '{item_name}'")
        embed.set_footer(text="World of Warcraft: Forever Companion")
        await interaction.followup.send(embed=embed)
        return

    # Fallback to Gemini
    prompt = f"""
    You are Foreverbot, an expert World of Warcraft: Forever (Classic+) assistant.
    A player is asking which vendors/merchants sell: "{item_name}".
    List 1-3 specific NPC vendor names, their exact zone, and coordinates if known.
    If no vendor sells this item (e.g. drop only or crafted only), state clearly how it is obtained.
    Never output LaTeX math. Keep it to 2-3 concise bullets.
    """
    ai_text = await query_gemini_text(prompt)
    if ai_text:
        embed = discord.Embed(
            title=f"🛒 Vendor Info: {item_name}",
            description=ai_text.strip(),
            color=0x2ECC71
        )
        embed.set_footer(text="World of Warcraft: Forever Companion")
        await interaction.followup.send(embed=embed)
        return

    await interaction.followup.send(
        f"❌ No vendors found selling `{item_name}`.",
        ephemeral=True
    )


@vendor_command.autocomplete("query")
async def vendor_autocomplete(interaction: discord.Interaction, current: str) -> List[app_commands.Choice[str]]:
    current_l = current.lower()
    matches = [v for v in db.vendor_items if current_l in v.lower()]
    matches.sort(key=lambda x: (not x.lower().startswith(current_l), x.lower()))
    return [app_commands.Choice(name=m[:100], value=m[:100]) for m in matches[:25]]


# -------------------------------------------------------------
# Slash Command: /flightpath
# -------------------------------------------------------------
@bot.tree.command(name="flightpath", description="Find flight masters and routes by zone (Condensed)")
@app_commands.describe(query="Zone or city (e.g. 'Westfall', 'STV', 'Crossroads')")
async def flightpath_command(interaction: discord.Interaction, query: str):
    await interaction.response.defer(ephemeral=True)
    nodes, did_you_mean = db.search_flightpaths(query, limit=3)
    if nodes:
        target = did_you_mean if did_you_mean else query
        lines = []
        for n in nodes:
            badge = "🌟 " if n["is_forever_content"] else ""
            coord = f" `({n['coordinates']})`" if n["coordinates"] else ""
            lines.append(f"• {badge}**{n['name']}** [{n['faction']}] — {n['zone']}{coord}\n  *Routes:* {n['connections']}")

        embed = discord.Embed(
            title=f"🦅 Flight Masters: {target}",
            description="\n\n".join(lines),
            color=0x3498DB
        )
        if did_you_mean:
            embed.set_author(name=f"Showing closest match: '{did_you_mean}'")
        embed.set_footer(text="World of Warcraft: Forever Companion")
        await interaction.followup.send(embed=embed)
        return

    # Fallback to Gemini
    prompt = f"""
    You are Foreverbot, an expert World of Warcraft: Forever (Classic+) assistant.
    A player is asking about flight paths / flight masters for: "{query}".
    Provide the exact flight master NPC names, exact zone coordinates, and connecting routes.
    Never output LaTeX math. Keep it to 2-3 concise bullets.
    """
    ai_text = await query_gemini_text(prompt)
    if ai_text:
        embed = discord.Embed(
            title=f"🦅 Flight Masters for '{query}'",
            description=ai_text.strip(),
            color=0x3498DB
        )
        embed.set_footer(text="World of Warcraft: Forever Companion")
        await interaction.followup.send(embed=embed)
        return

    await interaction.followup.send(
        f"❌ No flight paths found for `{query}`.",
        ephemeral=True
    )


@flightpath_command.autocomplete("query")
async def flightpath_autocomplete(interaction: discord.Interaction, current: str) -> List[app_commands.Choice[str]]:
    current_l = current.lower()
    matches = [f for f in db.flight_names if current_l in f.lower()]
    matches.sort(key=lambda x: (not x.lower().startswith(current_l), x.lower()))
    return [app_commands.Choice(name=m[:100], value=m[:100]) for m in matches[:25]]


# -------------------------------------------------------------
# Slash Command: /map
# -------------------------------------------------------------
@bot.tree.command(name="map", description="Zone map with coordinates, towns, flight masters & dungeons (Condensed)")
@app_commands.describe(query="Zone name, city, or abbreviation (e.g. 'Westfall', 'Tanaris', 'STV')")
async def map_command(interaction: discord.Interaction, query: Optional[str] = None):
    zone = query
    await interaction.response.defer(ephemeral=True)
    if not zone or not zone.strip():
        embed = discord.Embed(
            title="🗺️ Azeroth World Map & Zone Directory",
            description=(
                "Type `/map <zone>` (e.g. `/map Westfall`, `/map Tanaris`, `/map Hyjal`, `/map STV`).\n\n"
                "**Eastern Kingdoms:**\n"
                "• Elwynn (1-10), Westfall (10-20), Redridge (15-25), Duskwood (20-30), Hillsbrad (20-30), Arathi (30-40), STV (30-45), Badlands (35-45), Searing Gorge (43-50), Burning Steppes (50-58), WPL/EPL (51-60)\n\n"
                "**Kalimdor:**\n"
                "• Durotar/Mulgore (1-10), Barrens (10-25), Ashenvale (18-30), 1k Needles (25-35), Desolace (30-40), Dustwallow (35-45), Tanaris (40-50), Feralas (40-50), Felwood/Un'Goro (48-55), Winterspring/Silithus (55-60)\n\n"
                "**🌟 WoW: Forever (Classic+):**\n"
                "• Zephras Isle (1-25), Ruins of Gilneas (50-54), The Riverglades (54-58), Mount Hyjal (58-60)"
            ),
            color=0x1ABC9C
        )
        embed.set_footer(text="World of Warcraft: Forever Companion")
        await interaction.followup.send(embed=embed)
        return

    info = db.get_zone_map(zone)
    if not info:
        # Fallback to Gemini for subzones, landmarks, or unlisted zones
        prompt = f"""
        You are Foreverbot, an expert World of Warcraft: Forever (Classic+) cartographer.
        A player is asking for map and zone details about: "{zone}".

        If this is a valid World of Warcraft (Classic Era or Classic+) zone, town, landmark, or subzone:
        Provide an ultra-condensed breakdown (maximum 3-4 bullet points):
        - **Parent Zone & Continent:** [Location details, continent, coordinates if applicable]
        - **Faction & Level Range:** [Alliance/Horde/Contested, Recommended level]
        - **Key Hubs & Flight Masters:** [Nearby towns, flight masters]
        - **Dungeons & Points of Interest:** [Notable instances or landmarks]

        If this is completely unrecognized, respond with ONLY: NOT_A_ZONE

        Strict formatting:
        - Never output LaTeX math syntax (never use $\\rightarrow$, use simple text '->').
        - Alt-tab friendly, concise bullets. Zero conversational fluff.
        """
        ai_map = await query_gemini_text(prompt)
        if ai_map and "NOT_A_ZONE" not in ai_map:
            clean_map = ai_map.replace("$\\rightarrow$", "->").replace("\\rightarrow", "->")
            embed = discord.Embed(
                title=f"🗺️ Map Info: {zone.title()}",
                description=clean_map.strip(),
                color=0x1ABC9C
            )
            embed.set_footer(text="World of Warcraft: Forever Companion")
            await interaction.followup.send(embed=embed)
            return

        await interaction.followup.send(
            f"❌ Zone `{zone}` not found. Try `/map Westfall`, `/map Tanaris`, or `/map Barrens`!",
            ephemeral=True
        )
        return

    badge = "🌟 [Forever] " if info.get("is_forever") else ""
    title = f"🗺️ {badge}{info['name']} (Lvl {info['level']} • {info['faction']} • {info['continent']})"

    desc_lines = [
        f"• **Towns & Hubs:** {info['hubs']}"
    ]

    if info.get("flightpaths"):
        fp_strs = [f"{fp['name']} [{fp['faction']}] `({fp['coordinates']})`" for fp in info["flightpaths"]]
        desc_lines.append(f"• **Flight Masters:** {', '.join(fp_strs)}")

    if info.get("dungeons"):
        dung_strs = [
            f"**{d['name']}** (Lvl {d['level_min']}-{d['level_max']}" +
            (f" • `{d['entrance_coords']}`" if d.get("entrance_coords") else "") + ")"
            for d in info["dungeons"]
        ]
        desc_lines.append(f"• **Dungeons & Raids:** {', '.join(dung_strs)}")

    desc_lines.append(f"• **Borders:** {info['borders']}")

    if info.get("pois"):
        desc_lines.append(f"• **Points of Interest:** {info['pois']}")

    embed = discord.Embed(
        title=title,
        description="\n\n".join(desc_lines),
        color=0x1ABC9C
    )
    embed.set_footer(text="World of Warcraft: Forever Companion")
    await interaction.followup.send(embed=embed)


@map_command.autocomplete("query")
async def map_autocomplete(interaction: discord.Interaction, current: str) -> List[app_commands.Choice[str]]:
    current_l = current.lower()
    from knowledge_engine import ZONES_DATA
    zone_names = list(ZONES_DATA.keys())
    matches = [z for z in zone_names if current_l in z.lower()]
    matches.sort(key=lambda x: (not x.lower().startswith(current_l), x.lower()))
    return [app_commands.Choice(name=m[:100], value=m[:100]) for m in matches[:25]]


# -------------------------------------------------------------
# Slash Command: /zones (WoW: Forever World Overview)
# -------------------------------------------------------------
@bot.tree.command(name="zones", description="View zone details, level brackets, hubs, and new Forever zones")
@app_commands.describe(query="Optional zone search or filter (e.g. 'Duskwood', 'STV', 'Hyjal')")
async def zones_command(interaction: discord.Interaction, query: Optional[str] = None):
    if query:
        q = query.strip().lower()
        matched_zone = None
        for z_name, z_info in ke.ZONES_DATA.items():
            if q == z_name.lower() or q in z_name.lower() or z_name.lower() in q:
                matched_zone = (z_name, z_info)
                break
        
        # Check common aliases
        if not matched_zone and q in ["stv", "stranglethorn", "stranglethorn vale"]:
            matched_zone = ("Stranglethorn Vale", ke.ZONES_DATA.get("Stranglethorn Vale"))

        if matched_zone and matched_zone[1]:
            z_name, z_info = matched_zone
            badge = "🌟 [Forever Classic+]" if z_info.get("is_forever") else "⚔️ [Classic Era]"
            desc = [
                f"• **Level:** {z_info.get('level')} • **Faction:** {z_info.get('faction')}",
                f"• **Continent:** {z_info.get('continent')}",
                f"• **Towns & Hubs:** {z_info.get('hubs')}",
                f"• **Borders:** {z_info.get('borders')}",
                f"• **Notable POIs:** {z_info.get('pois')}"
            ]
            embed = discord.Embed(
                title=f"{badge} {z_name}",
                description="\n".join(desc),
                color=0x1ABC9C if not z_info.get("is_forever") else 0xF59E0B
            )
            embed.set_footer(text="World of Warcraft: Forever Companion")
            await interaction.response.send_message(embed=embed, ephemeral=True)
            return

    embed = discord.Embed(
        title="🗺️ WoW: Forever — New & Expanded Zones",
        description=(
            "• **Mount Hyjal (58–60)**: High-level Cenarion zone. *Roots of Nordrassil* 5-man dungeon & *The Verdant Scar* raid.\n"
            "• **Zephras Isle (1–25)**: Home of playable Skyborne Elves with aerial cliffs & *Sunken Citadel* dungeon.\n"
            "• **The Riverglades (54–58)**: Contested marshland PvP hub & *Grove of the Stillglade* dungeon.\n"
            "• **Ruins of Gilneas (50–54)**: Greymane Wall border reconnaissance questline."
        ),
        color=0x1ABC9C
    )
    embed.set_footer(text="World of Warcraft: Forever • Launching Nov 4, 2026")
    await interaction.response.send_message(embed=embed, ephemeral=True)


# -------------------------------------------------------------
# Slash Command: /dungeons (Dungeon Finder by Level, Name, or Zone)
# -------------------------------------------------------------
@bot.tree.command(name="dungeons", description="Find dungeons by level (e.g. 42), name, or zone (Condensed & Relevant)")
@app_commands.describe(query="Level (e.g. 42), dungeon name (e.g. ZF), or zone")
async def dungeons_command(interaction: discord.Interaction, query: Optional[str] = None):
    await interaction.response.defer(ephemeral=True)
    # If empty query: Show concise bracket cheat sheet
    if not query or not query.strip():
        embed = discord.Embed(
            title="🏰 Dungeon Finder (Classic & WoW: Forever)",
            description=(
                "Type `/dungeons 42` or `/dungeons zf` to find specific instances.\n\n"
                "**Level Brackets:**\n"
                "• **13–24:** Hall of Thanes (13-18), Ruins of Lordaeron (15-20), Ragefire Chasm (13-18), Deadmines (17-26), Wailing Caverns (17-24)\n"
                "• **22–33:** SFK (22-30), Sunken Citadel (22-26), BFD (24-32), Stockade (24-32), Excavation Site (24-29), Dalaran (28-33)\n"
                "• **29–46:** Drowned City (35-40), Krol'dok (40-45), Gnomer (29-38), RFK (29-38), SM (29-45), RFD (37-46), Uldaman (41-51)\n"
                "• **44–55:** Zul'Farrak (44-54), Maraudon (46-55), Alcaz Island (48-53), Sunken Temple (50-60)\n"
                "• **52–60:** Blackmaw Hold (55-60), Shaper's Terrace (58-60), Hateforge (52-56), Stillglade (54-58), BRD (52-60), LBRS/UBRS (55-60)\n"
                "• **Endgame 60:** Stratholme, Scholomance, Dire Maul, Roots of Nordrassil, Karazhan Crypts, Temporal Rift"
            ),
            color=0x9B59B6
        )
        embed.set_footer(text="World of Warcraft: Forever Companion")
        await interaction.followup.send(embed=embed)
        return

    extracted_lvl = extract_level_from_text(query)

    # Edge Case: Under level 13 (Starter Bracket)
    if extracted_lvl is not None and extracted_lvl < 13:
        embed = discord.Embed(
            title=f"🏰 Level {extracted_lvl} (Starter Bracket)",
            description=(
                f"Dungeons in World of Warcraft begin at **Level 13**!\n\n"
                f"• **Level 1–12 Advice:** Focus on starter zone quests to build talents and gear.\n"
                f"• **Earliest Dungeons:**\n"
                f"  - **Ragefire Chasm (Lvl 13–18):** Inside Orgrimmar (Horde)\n"
                f"  - **The Deadmines (Lvl 17–26):** Westfall, Moonbrook (Alliance)\n"
                f"  - **Wailing Caverns (Lvl 17–24):** The Barrens (Both)"
            ),
            color=0x9B59B6
        )
        embed.set_footer(text="World of Warcraft: Forever Companion")
        await interaction.followup.send(embed=embed)
        return

    # Edge Case: Over level 60 (Forever Cap)
    if extracted_lvl is not None and extracted_lvl > 60:
        dungs_60, _ = db.search_dungeons(level=60, limit=5)
        lines = []
        for d in dungs_60:
            badge = "🌟 " if d["is_forever_content"] else ""
            coord = f" `({d['entrance_coords']})`" if d.get("entrance_coords") else ""
            lines.append(f"• {badge}**{d['name']}** (Lvl {d['level_min']}–{d['level_max']}) — {d['zone']}{coord}")

        embed = discord.Embed(
            title=f"🏰 Level {extracted_lvl} -> Level 60 Cap (WoW: Forever)",
            description=(
                f"**WoW: Forever features a permanent Level 60 cap** with horizontal progression!\n\n"
                f"**Endgame Dungeons & Raids:**\n" + "\n".join(lines)
            ),
            color=0x9B59B6
        )
        embed.set_footer(text="World of Warcraft: Forever Companion")
        await interaction.followup.send(embed=embed)
        return

    dungs, did_you_mean = db.search_dungeons(query=query, limit=5)

    if not dungs:
        # Fallback to Gemini for natural language queries, subzones, boss queries, or uncataloged encounters
        prompt = f"""
        You are Foreverbot, an expert World of Warcraft: Forever (Classic+) dungeon master.
        A player entered this into the /dungeons command: "{query}".

        If this query relates to a WoW dungeon, raid, wing, chamber, boss, or encounter:
        Provide an ultra-condensed breakdown (maximum 3-4 bullet points):
        - **Dungeon & Location:** [Dungeon name, parent zone, entrance coords, recommended level]
        - **Area / Context:** [Specific room, wing, or chamber context, e.g. The Grim Guzzler or Shadowforge City in Blackrock Depths, noting lore or Classic+ features]
        - **Key Bosses:** [Key bosses in this room or instance]
        - **Notable Drops:** [Iconic loot items]

        If this query is completely unrelated to World of Warcraft dungeons, reply with ONLY: NOT_A_DUNGEON

        Strict formatting:
        - Never use LaTeX math notation (never use $\\rightarrow$, use simple text '->').
        - Alt-tab friendly, concise bullets. Zero conversational fluff.
        """
        ai_dung = await query_gemini_text(prompt)
        if ai_dung and "NOT_A_DUNGEON" not in ai_dung:
            clean_dung = ai_dung.replace("$\\rightarrow$", "->").replace("\\rightarrow", "->")
            embed = discord.Embed(
                title=f"🏰 Dungeon Info: {query[:100]}",
                description=clean_dung.strip(),
                color=0x9B59B6
            )
            embed.set_footer(text="World of Warcraft: Forever Companion")
            await interaction.followup.send(embed=embed)
            return

        await interaction.followup.send(
            f"❌ No dungeons found matching `{query}`. Try `/dungeons 42` or `/dungeons zf`!",
            ephemeral=True
        )
        return

    if extracted_lvl:
        embed = discord.Embed(
            title=f"🏰 Level {extracted_lvl} Dungeons ({len(dungs)} Found)",
            color=0x9B59B6
        )
        lines = []
        for d in dungs:
            badge = "🌟 " if d["is_forever_content"] else ""
            coord = f" `({d['entrance_coords']})`" if d.get("entrance_coords") else ""
            lines.append(
                f"• {badge}**{d['name']}** (Lvl {d['level_min']}–{d['level_max']} • Rec {d['recommended_level']}) — {d['zone']}{coord}\n  *Key Loot:* {d.get('notable_loot', 'N/A')}"
            )
        embed.description = "\n\n".join(lines)
    else:
        embed = discord.Embed(
            title=f"🏰 Dungeons Matching: '{did_you_mean if did_you_mean else query}'",
            color=0x9B59B6
        )
        lines = []
        for d in dungs:
            badge = "🌟 [Forever] " if d["is_forever_content"] else ""
            coord = f" `({d['entrance_coords']})`" if d.get("entrance_coords") else ""
            loot = f"\n  *Loot:* {d['notable_loot']}" if d.get("notable_loot") else ""
            bosses = f"\n  *Bosses:* {d['key_bosses']}" if d.get("key_bosses") else ""
            tip = f"\n  *Tip:* {d['pro_tip']}" if d.get("pro_tip") else ""
            lines.append(
                f"• {badge}**{d['name']}** (Lvl {d['level_min']}–{d['level_max']} • Rec {d['recommended_level']}) — {d['zone']}{coord}{bosses}{loot}{tip}"
            )
        embed.description = "\n\n".join(lines)

    embed.set_footer(text="World of Warcraft: Forever Companion")
    await interaction.followup.send(embed=embed)


@dungeons_command.autocomplete("query")
async def dungeons_autocomplete(interaction: discord.Interaction, current: str) -> List[app_commands.Choice[str]]:
    current_l = current.lower().strip()
    level_suggestions = ["15", "20", "25", "30", "35", "40", "42", "45", "50", "55", "60"]
    combined = []
    if current_l.isdigit():
        combined.append(app_commands.Choice(name=f"Level {current_l}", value=current_l))
    for lvl in level_suggestions:
        if current_l in lvl or current_l in f"level {lvl}":
            combined.append(app_commands.Choice(name=f"Level {lvl}", value=lvl))
    d_matches = [d for d in db.dungeon_names if current_l in d.lower()]
    d_matches.sort(key=lambda x: (not x.lower().startswith(current_l), x.lower()))
    for d in d_matches:
        combined.append(app_commands.Choice(name=d[:100], value=d[:100]))
    return combined[:25]


# -------------------------------------------------------------
# Slash Command: /level (Level Progression & Milestones Guide)
# -------------------------------------------------------------
@bot.tree.command(name="level", description="Quick progression guide for any level 1-60 (Condensed)")
@app_commands.describe(query="Level (1-60, e.g. 42)")
async def level_command(interaction: discord.Interaction, query: int):
    level = query
    await interaction.response.defer(ephemeral=True)
    if level < 1 or level > 60:
        await interaction.followup.send("Please choose a level between 1 and 60!", ephemeral=True)
        return

    advice = get_level_advice(level)
    dungs, _ = db.search_dungeons(level=level, limit=4)

    embed = discord.Embed(
        title=f"🛡️ Level {level} Quick Guide",
        color=0x3498DB
    )

    dung_summary = " • ".join([f"**{d['name']}** ({d['level_min']}-{d['level_max']})" for d in dungs]) if dungs else "None (Focus on questing)"

    embed.description = (
        f"🏰 **Dungeons:** {dung_summary}\n\n"
        f"🌲 **Questing Zones:**\n"
        f"• **Alliance:** {advice['alliance_zones']}\n"
        f"• **Horde:** {advice['horde_zones']}\n\n"
        f"⭐ **Milestones:** {advice['milestones']}"
    )
    embed.set_footer(text="World of Warcraft: Forever Companion")
    await interaction.followup.send(embed=embed)


# -------------------------------------------------------------
# Slash Command: /gather (Mining Ores, Herbs, Leather & Farming)
# -------------------------------------------------------------
@bot.tree.command(name="gather", description="Find ore veins, herbs, leather & farming routes (Condensed & Accurate)")
@app_commands.describe(query="Ore vein, herb name, or leather (e.g. 'Copper', 'Black Lotus', 'Thorium', 'Fadeleaf')")
async def gather_command(interaction: discord.Interaction, query: str):
    node = query
    await interaction.response.defer(ephemeral=True)
    info = get_gathering_info(node)
    if info:
        embed = discord.Embed(
            title=f"⛏️ {info['name']} ({info['type']} • Req {info['skill_req']})",
            color=0x2ECC71
        )
        embed.description = (
            f"• **Yield:** {info['item']}\n"
            f"• **Best Zones:** {info['zones']}\n"
            f"• **Optimal Route:** {info['route']}\n"
            f"💡 *Tip:* {info['tip']}"
        )
        embed.set_footer(text="World of Warcraft: Forever Companion")
        await interaction.followup.send(embed=embed)
        return

    # Fallback to Gemini
    prompt = f"""
    You are Foreverbot, an expert World of Warcraft: Forever (Classic+) gathering assistant.
    A player is asking where to gather/farm: "{node}".
    Provide an ultra-condensed breakdown (maximum 3 bullet points):
    - **Skill & Node Type:** [Mining/Herbalism/Skinning/Fishing and skill required]
    - **Best Zones & Spawns:** [Top 2-3 zones with highest node density]
    - **Optimal Farming Route:** [Perimeter loop, caves, or exact paths]
    Rules: Never output LaTeX math. Plain text only. Alt-tab friendly.
    """
    ai_text = await query_gemini_text(prompt)
    if ai_text:
        clean_text = ai_text.replace("$\\rightarrow$", "->").replace("\\rightarrow", "->")
        embed = discord.Embed(
            title=f"⛏️ Gathering Info: {node.title()}",
            description=clean_text.strip(),
            color=0x2ECC71
        )
        embed.set_footer(text="World of Warcraft: Forever Companion")
        await interaction.followup.send(embed=embed)
        return

    await interaction.followup.send(f"❌ Could not find gathering node `{node}`.", ephemeral=True)


@gather_command.autocomplete("query")
async def gather_autocomplete(interaction: discord.Interaction, current: str) -> List[app_commands.Choice[str]]:
    current_l = current.lower()
    keys = list(GATHERING_NODES.keys())
    matches = [k for k in keys if current_l in k.lower()]
    matches.sort(key=lambda x: (not x.lower().startswith(current_l), x.lower()))
    return [app_commands.Choice(name=m.title()[:100], value=m[:100]) for m in matches[:25]]


# -------------------------------------------------------------
# Slash Command: /profession (1-300 Guides, Perks & Synergy)
# -------------------------------------------------------------
@bot.tree.command(name="profession", description="Profession leveling brackets (1-300), key perks & pairings (Condensed)")
@app_commands.describe(query="Profession name (e.g. 'Mining', 'Herbalism', 'Engineering', 'Alchemy')")
async def profession_command(interaction: discord.Interaction, query: str):
    name = query
    await interaction.response.defer(ephemeral=True)
    info = get_profession_info(name)
    if info:
        embed = discord.Embed(
            title=f"🛠️ {info['name']} Guide ({info['type']})",
            color=0xE67E22
        )
        embed.description = (
            f"• **Best Pairing:** {info['gathering_pair']}\n"
            f"• **Overview:** {info['description']}\n"
            f"• **Key Crafts:** {info['key_crafts']}\n\n"
            f"**1–300 Leveling Brackets:**\n{info['leveling_brackets']}\n\n"
            f"💡 *Tip:* {info['tip']}"
        )
        embed.set_footer(text="World of Warcraft: Forever Companion")
        await interaction.followup.send(embed=embed)
        return

    # Fallback to Gemini
    prompt = f"""
    You are Foreverbot, an expert World of Warcraft: Forever (Classic+) profession trainer.
    A player is asking about the profession: "{name}".
    Provide an ultra-condensed breakdown (maximum 3 bullet points):
    - **Overview & Best Pairing:** [Best classes and complementary gathering profession]
    - **1-300 Leveling Roadmap:** [Core items crafted per bracket: 1-75, 75-150, 150-225, 225-300]
    - **Top Endgame Perks:** [Most impactful crafted BiS gear or consumables]
    Rules: Never output LaTeX math. Plain text only. Alt-tab friendly.
    """
    ai_text = await query_gemini_text(prompt)
    if ai_text:
        clean_text = ai_text.replace("$\\rightarrow$", "->").replace("\\rightarrow", "->")
        embed = discord.Embed(
            title=f"🛠️ Profession Guide: {name.title()}",
            description=clean_text.strip(),
            color=0xE67E22
        )
        embed.set_footer(text="World of Warcraft: Forever Companion")
        await interaction.followup.send(embed=embed)
        return

    await interaction.followup.send(f"❌ Profession `{name}` not found.", ephemeral=True)


@profession_command.autocomplete("query")
async def profession_autocomplete(interaction: discord.Interaction, current: str) -> List[app_commands.Choice[str]]:
    current_l = current.lower()
    keys = list(PROFESSIONS_DATA.keys())
    matches = [k for k in keys if current_l in k.lower()]
    matches.sort(key=lambda x: (not x.lower().startswith(current_l), x.lower()))
    return [app_commands.Choice(name=m[:100], value=m[:100]) for m in matches[:25]]


# -------------------------------------------------------------
# Slash Command: /build (Class Talents, Stats, Rotations)
# -------------------------------------------------------------
@bot.tree.command(name="build", description="Class talent specs, stat priorities & rotations (Condensed & Top Meta)")
@app_commands.describe(query="Class (e.g. 'Warrior', 'Mage', 'Rogue', 'Priest')", spec="Spec (e.g. 'Fury', 'Arms', 'Frost AoE', 'Shadow')")
async def build_command(interaction: discord.Interaction, query: str, spec: Optional[str] = None):
    class_name = query
    await interaction.response.defer(ephemeral=True)
    b = get_class_build(class_name, spec)
    if b:
        embed = discord.Embed(
            title=f"🌳 {b['class']} — {b['spec']} ({b['points']})",
            color=0x1ABC9C
        )
        embed.description = (
            f"• **Role:** {b['role']}\n"
            f"• **Stat Priority:** {b['stat_priority']}\n"
            f"• **Rotation:** {b['rotation']}\n"
            f"• **Key Milestones:** {b['milestones']}\n"
            f"💡 *Tip:* {b['tip']}"
        )
        embed.set_footer(text="World of Warcraft: Forever Companion")
        await interaction.followup.send(embed=embed)
        return

    # Fallback to Gemini
    spec_query = f"{class_name} {spec}".strip()
    prompt = f"""
    You are Foreverbot, an expert World of Warcraft: Forever (Classic+) theorycrafter.
    A player is asking for a talent build: "{spec_query}".
    Provide an ultra-condensed breakdown (maximum 3 bullet points):
    - **Talent Points & Role:** [e.g. 17/34/0 Melee DPS]
    - **Stat Priority:** [Key hit caps and stat priority]
    - **Core Rotation & Key Talents:** [3-step rotation]
    Rules: Never output LaTeX math. Plain text only. Alt-tab friendly. Zero fluff.
    """
    ai_text = await query_gemini_text(prompt)
    if ai_text:
        clean_text = ai_text.replace("$\\rightarrow$", "->").replace("\\rightarrow", "->")
        embed = discord.Embed(
            title=f"🌳 Build Guide: {spec_query.title()}",
            description=clean_text.strip(),
            color=0x1ABC9C
        )
        embed.set_footer(text="World of Warcraft: Forever Companion")
        await interaction.followup.send(embed=embed)
        return

    await interaction.followup.send(f"❌ Could not find build for `{spec_query}`.", ephemeral=True)


@build_command.autocomplete("query")
async def build_class_autocomplete(interaction: discord.Interaction, current: str) -> List[app_commands.Choice[str]]:
    classes = ["Warrior", "Mage", "Rogue", "Priest", "Warlock", "Hunter", "Druid", "Paladin", "Shaman"]
    current_l = current.lower()
    matches = [c for c in classes if current_l in c.lower()]
    return [app_commands.Choice(name=m, value=m) for m in matches[:25]]


@build_command.autocomplete("spec")
async def build_spec_autocomplete(interaction: discord.Interaction, current: str) -> List[app_commands.Choice[str]]:
    specs = sorted(list(set([v["spec"] for v in CLASS_BUILDS.values()])))
    current_l = current.lower()
    matches = [s for s in specs if current_l in s.lower()]
    return [app_commands.Choice(name=m[:100], value=m[:100]) for m in matches[:25]]


# -------------------------------------------------------------
# Slash Command: /consumes (Raid Consumables Checklist)
# -------------------------------------------------------------
@bot.tree.command(name="consumes", description="Raid consumables checklist by class or role (Condensed)")
@app_commands.describe(query="Class or role (e.g. 'Warrior', 'Mage', 'Healer', 'Tank', 'Melee DPS')")
async def consumes_command(interaction: discord.Interaction, query: str):
    role_or_class = query
    await interaction.response.defer(ephemeral=True)
    c = get_consumables_info(role_or_class)
    if c:
        embed = discord.Embed(
            title=f"🧪 Raid Consumables: {c['role']}",
            color=0x9B59B6
        )
        embed.description = (
            f"• **Flasks & Elixirs:** {c['flasks_elixirs']}\n"
            f"• **Food Buff:** {c['food_buffs']}\n"
            f"• **Weapon Buff:** {c['weapon_buffs']}\n"
            f"• **Potions:** {c['potions']}\n"
            f"💡 *Tip:* {c['tip']}"
        )
        embed.set_footer(text="World of Warcraft: Forever Companion")
        await interaction.followup.send(embed=embed)
        return

    # Fallback to Gemini
    prompt = f"""
    You are Foreverbot, an expert World of Warcraft: Forever (Classic+) raid leader.
    A player is asking for the consumable checklist for: "{role_or_class}".
    Provide an ultra-condensed breakdown (maximum 3 bullet points):
    - **Flasks & Elixirs:** [Essential Flasks and Elixirs]
    - **Food & Weapon Buffs:** [Optimal food and oils/sharpening stones]
    - **Combat & Protection Potions:** [Mana/Rage/Protection potions needed]
    Rules: Never output LaTeX math. Plain text only. Alt-tab friendly.
    """
    ai_text = await query_gemini_text(prompt)
    if ai_text:
        clean_text = ai_text.replace("$\\rightarrow$", "->").replace("\\rightarrow", "->")
        embed = discord.Embed(
            title=f"🧪 Consumables: {role_or_class.title()}",
            description=clean_text.strip(),
            color=0x9B59B6
        )
        embed.set_footer(text="World of Warcraft: Forever Companion")
        await interaction.followup.send(embed=embed)
        return

    await interaction.followup.send(f"❌ Consumables for `{role_or_class}` not found.", ephemeral=True)


@consumes_command.autocomplete("query")
async def consumes_autocomplete(interaction: discord.Interaction, current: str) -> List[app_commands.Choice[str]]:
    suggestions = ["Melee DPS", "Caster DPS", "Healer", "Tank", "Warrior", "Rogue", "Mage", "Warlock", "Priest", "Hunter", "Druid", "Paladin", "Shaman"]
    current_l = current.lower()
    matches = [s for s in suggestions if current_l in s.lower()]
    return [app_commands.Choice(name=m, value=m) for m in matches[:25]]


# -------------------------------------------------------------
# Slash Command: /buffs (World Buffs Locations, Timers & Effects)
# -------------------------------------------------------------
@bot.tree.command(name="buffs", description="World buff turn-ins, respawn timers, and effects (Condensed)")
@app_commands.describe(query="World buff name (e.g. 'Onyxia', 'Songflower', 'Warchief', 'Zandalar', 'Tribute')")
async def buffs_command(interaction: discord.Interaction, query: Optional[str] = None):
    buff = query
    await interaction.response.defer(ephemeral=True)
    if not buff or not buff.strip():
        lines = []
        for k, v in WORLD_BUFFS_DATA.items():
            lines.append(f"• **{v['name']}:** {v['effect']} `({v['cooldown']})`")
        embed = discord.Embed(
            title="✨ World Buffs Directory (Classic & WoW: Forever)",
            description="\n\n".join(lines) + "\n\n*Type `/buffs <name>` for turn-in coords and stacking rules!*",
            color=0xF1C40F
        )
        embed.set_footer(text="World of Warcraft: Forever Companion")
        await interaction.followup.send(embed=embed)
        return

    wb = get_world_buff_info(buff)
    if wb:
        embed = discord.Embed(
            title=f"✨ {wb['name']}",
            color=0xF1C40F
        )
        embed.description = (
            f"• **Source & Turn-In:** {wb['source']}\n"
            f"• **Effect:** {wb['effect']}\n"
            f"• **Cooldown / Timer:** {wb['cooldown']}\n"
            f"💡 *Tip:* {wb['tip']}"
        )
        embed.set_footer(text="World of Warcraft: Forever Companion")
        await interaction.followup.send(embed=embed)
        return

    # Fallback to Gemini
    prompt = f"""
    You are Foreverbot, an expert World of Warcraft: Forever (Classic+) coordinator.
    A player is asking about the world buff: "{buff}".
    Provide an ultra-condensed breakdown (maximum 3 bullet points):
    - **Buff & Source:** [Name and exact turn-in location/NPC]
    - **Effect & Duration:** [Exact combat stat buffs]
    - **Reset Timer & Tip:** [Cooldown timer and coordination tips]
    Rules: Never output LaTeX math. Plain text only. Alt-tab friendly.
    """
    ai_text = await query_gemini_text(prompt)
    if ai_text:
        clean_text = ai_text.replace("$\\rightarrow$", "->").replace("\\rightarrow", "->")
        embed = discord.Embed(
            title=f"✨ World Buff: {buff.title()}",
            description=clean_text.strip(),
            color=0xF1C40F
        )
        embed.set_footer(text="World of Warcraft: Forever Companion")
        await interaction.followup.send(embed=embed)
        return

    await interaction.followup.send(f"❌ World buff `{buff}` not found.", ephemeral=True)


@buffs_command.autocomplete("query")
async def buffs_autocomplete(interaction: discord.Interaction, current: str) -> List[app_commands.Choice[str]]:
    suggestions = ["Onyxia (Dragonslayer)", "Nefarian", "Warchief's Blessing (Rend)", "Songflower Serenade", "Spirit of Zandalar", "Dire Maul Tribute", "Sayge (Darkmoon Faire)"]
    current_l = current.lower()
    matches = [s for s in suggestions if current_l in s.lower()]
    return [app_commands.Choice(name=m[:100], value=m[:100]) for m in matches[:25]]


# -------------------------------------------------------------
# Slash Command: /raid (Boss Tactics & Wipe Prevention)
# -------------------------------------------------------------
@bot.tree.command(name="raid", description="Quick boss mechanics & wipe prevention cheatsheet (Condensed)")
@app_commands.describe(query="Boss or raid name (e.g. 'Baron Geddon', 'Vaelastrasz', 'Chromaggus', 'C'Thun', 'Temporal Rift')")
async def raid_command(interaction: discord.Interaction, query: str):
    boss = query
    await interaction.response.defer(ephemeral=True)
    rb = get_raid_boss_info(boss)
    if rb:
        embed = discord.Embed(
            title=f"⚔️ {rb['name']} ({rb['raid']})",
            color=0xE74C3C
        )
        embed.description = f"{rb['key_mechanics']}\n\n💡 *Tip:* {rb['tip']}"
        embed.set_footer(text="World of Warcraft: Forever Companion")
        await interaction.followup.send(embed=embed)
        return

    # Fallback to Gemini
    prompt = f"""
    You are Foreverbot, an expert World of Warcraft: Forever (Classic+) raid leader.
    A player is asking for the quick strategy/tactics for raid boss: "{boss}".
    Provide an ultra-condensed breakdown (maximum 3-4 bullet points):
    - **Boss & Raid:** [Boss name, raid, and level]
    - **Lethal Mechanics & Positioning:** [Exact positioning and deadly wipe mechanics to watch for]
    - **Assignments & Strategy:** [Tank swaps, decursing, interrupts, or kill priority]
    Rules: Never output LaTeX math. Plain text only. Alt-tab friendly.
    """
    ai_text = await query_gemini_text(prompt)
    if ai_text:
        clean_text = ai_text.replace("$\\rightarrow$", "->").replace("\\rightarrow", "->")
        embed = discord.Embed(
            title=f"⚔️ Raid Strategy: {boss.title()}",
            description=clean_text.strip(),
            color=0xE74C3C
        )
        embed.set_footer(text="World of Warcraft: Forever Companion")
        await interaction.followup.send(embed=embed)
        return

    await interaction.followup.send(f"❌ Raid boss `{boss}` not found.", ephemeral=True)


@raid_command.autocomplete("query")
async def raid_autocomplete(interaction: discord.Interaction, current: str) -> List[app_commands.Choice[str]]:
    boss_list = [
        "Baron Geddon", "Ragnaros", "Onyxia", "Vaelastrasz", "Chromaggus", "Nefarian",
        "C'Thun", "Patchwerk", "The Temporal Rift", "The Verdant Scar",
        "Lucifron", "Magmadar", "Garr", "Razorgore", "Hakkar", "Twin Emperors", "Four Horsemen", "Kel'Thuzad"
    ]
    current_l = current.lower()
    matches = [b for b in boss_list if current_l in b.lower()]
    return [app_commands.Choice(name=m[:100], value=m[:100]) for m in matches[:25]]


# -------------------------------------------------------------
# Slash Command: /rep (Faction Reputations, Farming Loops & Rewards)
# -------------------------------------------------------------
@bot.tree.command(name="rep", description="Reputation farming loops, turn-ins & reward breakpoints (Condensed)")
@app_commands.describe(query="Faction name (e.g. 'Timbermaw', 'Argent Dawn', 'Thorium Brotherhood', 'Hydraxian', 'Cenarion')")
async def rep_command(interaction: discord.Interaction, query: str):
    faction = query
    await interaction.response.defer(ephemeral=True)
    rep = get_reputation_info(faction)
    if rep:
        embed = discord.Embed(
            title=f"🛡️ {rep['name']} Guide",
            color=0x3498DB
        )
        embed.description = (
            f"• **Location:** {rep['location']}\n"
            f"• **Farming Loop & Turn-Ins:** {rep['farm_loop']}\n\n"
            f"**Key Rewards:**\n{rep['rewards']}\n\n"
            f"💡 *Tip:* {rep['tip']}"
        )
        embed.set_footer(text="World of Warcraft: Forever Companion")
        await interaction.followup.send(embed=embed)
        return

    # Fallback to Gemini
    prompt = f"""
    You are Foreverbot, an expert World of Warcraft: Forever (Classic+) reputation guide.
    A player is asking about the faction: "{faction}".
    Provide an ultra-condensed breakdown (maximum 3-4 bullet points):
    - **Faction & Hub:** [Faction name and central quest hub]
    - **Farming Loop:** [Best mob grinding spots and turn-in items]
    - **Key Rewards:** [Top Friendly/Honored/Revered/Exalted rewards]
    Rules: Never output LaTeX math. Plain text only. Alt-tab friendly.
    """
    ai_text = await query_gemini_text(prompt)
    if ai_text:
        clean_text = ai_text.replace("$\\rightarrow$", "->").replace("\\rightarrow", "->")
        embed = discord.Embed(
            title=f"🛡️ Reputation Guide: {faction.title()}",
            description=clean_text.strip(),
            color=0x3498DB
        )
        embed.set_footer(text="World of Warcraft: Forever Companion")
        await interaction.followup.send(embed=embed)
        return

    await interaction.followup.send(f"❌ Reputation faction `{faction}` not found.", ephemeral=True)


@rep_command.autocomplete("query")
async def rep_autocomplete(interaction: discord.Interaction, current: str) -> List[app_commands.Choice[str]]:
    factions = ["Timbermaw Hold", "Argent Dawn", "Thorium Brotherhood", "Hydraxian Waterlords", "Cenarion Circle", "Zandalar Tribe", "Wintersaber Trainers", "Brood of Nozdormu"]
    current_l = current.lower()
    matches = [f for f in factions if current_l in f.lower()]
    return [app_commands.Choice(name=m[:100], value=m[:100]) for m in matches[:25]]


# -------------------------------------------------------------
# Slash Command: /macro (Dynamic Macro Builder & Query)
# -------------------------------------------------------------
@bot.tree.command(name="macro", description="Generate copy-pasteable WoW in-game macros or look up templates")
@app_commands.describe(query="Macro query or template (e.g. 'mouseover', 'stance dance', 'startattack', or custom query)")
async def macro_command(interaction: discord.Interaction, query: str):
    await interaction.response.defer(ephemeral=True)

    # 1. Check known templates first
    m = get_macro_info(query)
    if m:
        embed = discord.Embed(
            title=f"📋 WoW Macro: {m['title']}",
            color=0x3498DB
        )
        code_block = f"```lua\n{m['code']}\n```"
        embed.description = (
            f"**Description:** {m['description']}\n\n"
            f"{code_block}\n"
            f"• **Characters:** {len(m['code'])} / 255\n"
            f"💡 *Tip:* {m['instructions']}"
        )
        embed.set_footer(text="World of Warcraft: Forever Companion • Click 'Copy' above & paste into /macro in WoW")
        await interaction.followup.send(embed=embed)
        return

    # 2. Dynamic AI Macro Builder via Gemini
    prompt = f"""
    You are Foreverbot, an expert World of Warcraft Macro Engineer.
    A player needs an in-game WoW Classic macro for: "{query}".
    Generate a 100% syntactically valid WoW Classic / Classic+ macro (maximum 255 characters).
    Format your response EXACTLY as:
    ```lua
    [exact macro code]
    ```
    EXPLANATION: [1-2 concise bullet points explaining mechanics, target priority, or keybind advice]

    Strict rules:
    - Only valid Classic WoW macro commands (/cast, /castsequence, /use, /startattack, /stopcasting, /cancelaura, /equipslot, [@mouseover,help,nodead], [stance:X], [mod:shift], etc.).
    - Keep macro under 255 characters so it fits in the standard WoW macro editor.
    - Zero conversational fluff.
    """
    ai_text = await query_gemini_text(prompt)
    if ai_text:
        import re
        code_match = re.search(r"```(?:lua)?\s*(.*?)\s*```", ai_text, re.DOTALL)
        if code_match:
            macro_code = code_match.group(1).strip()
            explanation = re.sub(r"```(?:lua)?.*?```", "", ai_text, flags=re.DOTALL).replace("EXPLANATION:", "").strip()
        else:
            macro_code = ai_text.strip()
            explanation = "Custom macro generated."

        clean_expl = explanation.replace("$\\rightarrow$", "->").replace("\\rightarrow", "->")
        embed = discord.Embed(
            title=f"📋 WoW Macro Builder: {query.title()[:80]}",
            color=0x3498DB
        )
        code_block = f"```lua\n{macro_code}\n```"
        char_count = len(macro_code)
        char_warn = " ⚠️ (Exceeds 255 chars!)" if char_count > 255 else ""
        embed.description = (
            f"{code_block}\n"
            f"• **Characters:** {char_count} / 255{char_warn}\n\n"
            f"{clean_expl}"
        )
        embed.set_footer(text="World of Warcraft: Forever Companion • Click 'Copy' above & paste into /macro in WoW")
        await interaction.followup.send(embed=embed)
        return

    await interaction.followup.send(f"❌ Could not build macro for `{query}`.", ephemeral=True)


@macro_command.autocomplete("query")
async def macro_autocomplete(interaction: discord.Interaction, current: str) -> List[app_commands.Choice[str]]:
    templates = [
        "Mouseover Healing / Decurse",
        "Warrior Stance Dance (Charge / Intercept)",
        "Melee Auto-Attack Start (/startattack)",
        "Hunter Auto Shot Clipping Prevention",
        "Burst Trinket & Cooldown Stacking",
        "Max Camera Distance Zoom (/console)",
        "Focus Target Interrupt",
        "1H and Shield Weapon Swap"
    ]
    current_l = current.lower()
    matches = [t for t in templates if current_l in t.lower()]
    return [app_commands.Choice(name=m[:100], value=m[:100]) for m in matches[:25]]


# -------------------------------------------------------------
# Slash Command: /pvp (Honor Ranks, Decay Math, Battleground Guides)
# -------------------------------------------------------------
@bot.tree.command(name="pvp", description="PvP Honor ranks 1-14, 20% weekly decay math, and Battleground guides")
@app_commands.describe(query="PvP topic (e.g. 'ranks', 'decay', 'wsg', 'ab', 'av')")
async def pvp_command(interaction: discord.Interaction, query: Optional[str] = "ranks"):
    await interaction.response.defer(ephemeral=True)
    q = query or "ranks"
    p = get_pvp_info(q)

    if p:
        embed = discord.Embed(title=f"⚔️ {p['title']}", color=0xC0392B)
        embed.description = f"{p['description']}\n\n💡 *Tip:* {p.get('tip', '')}"
        embed.set_footer(text="World of Warcraft: Forever Companion • PvP Honor System")
        await interaction.followup.send(embed=embed)
        return

    # Fallback to Gemini
    prompt = f"""
    You are Foreverbot, an expert World of Warcraft: Forever PvP and Honor system guide.
    A player is asking about: "{q}".
    Provide an ultra-condensed breakdown (maximum 3 bullet points):
    - Exact RP brackets, rank thresholds, BG strategies, or decay mechanics.
    - Zero conversational fluff. Never use LaTeX math.
    """
    ai_text = await query_gemini_text(prompt)
    if ai_text:
        clean_text = ai_text.replace("$\\rightarrow$", "->").replace("\\rightarrow", "->")
        embed = discord.Embed(
            title=f"⚔️ PvP Guide: {q.title()}",
            description=clean_text.strip(),
            color=0xC0392B
        )
        embed.set_footer(text="World of Warcraft: Forever Companion")
        await interaction.followup.send(embed=embed)
        return

    await interaction.followup.send(f"❌ PvP info for `{q}` not found.", ephemeral=True)


@pvp_command.autocomplete("query")
async def pvp_autocomplete(interaction: discord.Interaction, current: str) -> List[app_commands.Choice[str]]:
    topics = [
        "Honor Ranks 1-14 & Titles",
        "20% Weekly Decay & RP Calculation",
        "Warsong Gulch (WSG) Strategy & Rep",
        "Arathi Basin (AB) Strategy & Rep",
        "Alterac Valley (AV) Strategy & Rep"
    ]
    current_l = current.lower()
    matches = [t for t in topics if current_l in t.lower()]
    return [app_commands.Choice(name=m[:100], value=m[:100]) for m in matches[:25]]


# -------------------------------------------------------------
# Slash Command: /attunement (Raid Attunements)
# -------------------------------------------------------------
@bot.tree.command(name="attunement", description="Step-by-step raid attunements (Onyxia, MC, BWL, Naxx, Temporal Rift)")
@app_commands.describe(query="Raid instance (e.g. 'Onyxia', 'Molten Core', 'Blackwing Lair', 'Naxxramas', 'Temporal Rift')")
async def attunement_command(interaction: discord.Interaction, query: Optional[str] = None):
    instance = query
    await interaction.response.defer(ephemeral=True)
    if not instance or instance.lower() in ["all", "list", "directory"]:
        embed = discord.Embed(
            title="📜 Raid Attunements Directory",
            description=(
                "• **Onyxia's Lair:** Long quest chain (Marshal Windsor for Alliance / Rexxar & Drakkisath for Horde) -> Drakefire Amulet.\n"
                "• **Molten Core:** Speak to Lothos Riftwaker at Blackrock Mountain -> retrieve Core Fragment from BRD.\n"
                "• **Blackwing Lair:** Kill Scarshield Quartermaster outside UBRS -> slay Drakkisath & touch Orb of Ascension.\n"
                "• **Naxxramas:** Archmage Angela Dosantos at Light's Hope Chapel (Honored/Revered/Exalted Argent Dawn).\n"
                "• **The Temporal Rift (Classic+):** Watcher Leor at Blasted Lands Redoubt -> gather Temporal Shards."
            ),
            color=0xF1C40F
        )
        embed.set_footer(text="World of Warcraft: Forever Companion • Use /attunement <instance> for full guide")
        await interaction.followup.send(embed=embed)
        return

    att = get_attunement_info(instance)
    if att:
        embed = discord.Embed(title=f"📜 {att['title']}", color=0xF1C40F)
        if "guide" in att:
            embed.description = att["guide"]
        elif "alliance" in att and "horde" in att:
            embed.description = f"**Alliance:**\n{att['alliance']}\n\n**Horde:**\n{att['horde']}"
        if "tip" in att:
            embed.set_footer(text=f"💡 Tip: {att['tip']}")
        await interaction.followup.send(embed=embed)
        return

    # Fallback to Gemini
    prompt = f"""
    You are Foreverbot, an expert World of Warcraft: Forever raid attunement guide.
    A player is asking about the attunement for: "{instance}".
    Provide an ultra-condensed step-by-step checklist (maximum 4 bullet points):
    - Quest starter NPC and zone coords
    - Key dungeon / mob objectives
    - Final turn-in and teleport item / portal mechanics
    Rules: Never output LaTeX math. Plain text only. Alt-tab friendly.
    """
    ai_text = await query_gemini_text(prompt)
    if ai_text:
        clean_text = ai_text.replace("$\\rightarrow$", "->").replace("\\rightarrow", "->")
        embed = discord.Embed(
            title=f"📜 Raid Attunement: {instance.title()}",
            description=clean_text.strip(),
            color=0xF1C40F
        )
        embed.set_footer(text="World of Warcraft: Forever Companion")
        await interaction.followup.send(embed=embed)
        return

    await interaction.followup.send(f"❌ Attunement guide for `{instance}` not found.", ephemeral=True)


@attunement_command.autocomplete("query")
async def attunement_autocomplete(interaction: discord.Interaction, current: str) -> List[app_commands.Choice[str]]:
    instances = [
        "Onyxia's Lair",
        "Molten Core",
        "Blackwing Lair",
        "Naxxramas",
        "The Temporal Rift"
    ]
    current_l = current.lower()
    matches = [i for i in instances if current_l in i.lower()]
    return [app_commands.Choice(name=m[:100], value=m[:100]) for m in matches[:25]]


# -------------------------------------------------------------
# Slash Command: /keys (Dungeon Key Questlines & Doors Unlocked)
# -------------------------------------------------------------
@bot.tree.command(name="keys", description="Dungeon key questlines, drop locations, and doors unlocked")
@app_commands.describe(query="Dungeon key or dungeon name (e.g. 'Shadowforge Key', 'Scholo', 'Strat', 'Maraudon')")
async def keys_command(interaction: discord.Interaction, query: Optional[str] = None):
    dungeon = query
    await interaction.response.defer(ephemeral=True)
    if not dungeon or dungeon.lower() in ["all", "list", "directory"]:
        embed = discord.Embed(
            title="🗝️ Classic & Classic+ Dungeon Keys Directory",
            description=(
                "• **Shadowforge Key (BRD):** Ghost Franclorn Forgewright -> Ironfel to Shrine of Thaurissan (Lockpicking 250)\n"
                "• **Skeleton Key (Scholomance):** Long plagueland quest chain via Gadgetzan/Araj -> Key (Lockpicking 280)\n"
                "• **Key to the City (Stratholme):** Drops from Magistrate Barthilas in Service Entrance (Lockpicking 275)\n"
                "• **Scarlet Key (SM):** Looted from Doan's Strongbox behind Arcanist Doan in Library (Lockpicking 175)\n"
                "• **Crescent Key (Dire Maul):** Catch Pusillin the imp in Dire Maul East (Lockpicking 300 / Seaforium)\n"
                "• **Scepter of Celebras (Maraudon):** Combine Celebrian Rod & Diamond from Celebras (No key lock)\n"
                "• **Workshop Key (Gnomeregan):** Drops from Electrocutioner 6000 for back door (Lockpicking 150)"
            ),
            color=0xE67E22
        )
        embed.set_footer(text="World of Warcraft: Forever Companion • Use /keys <dungeon> for full guide")
        await interaction.followup.send(embed=embed)
        return

    k = get_dungeon_key_info(dungeon)
    if k:
        embed = discord.Embed(
            title=f"🗝️ {k['name']} ({k['dungeon']})",
            color=0xE67E22
        )
        embed.description = (
            f"• **Source:** {k['source']}\n"
            f"• **Unlocks:** {k['unlocks']}\n\n"
            f"**Quest Steps:**\n{k['steps']}\n\n"
            f"💡 *Tip:* {k['tip']}"
        )
        embed.set_footer(text="World of Warcraft: Forever Companion")
        await interaction.followup.send(embed=embed)
        return

    # Fallback to Gemini
    prompt = f"""
    You are Foreverbot, an expert World of Warcraft dungeon key guide.
    A player is asking about the key for: "{dungeon}".
    Provide an ultra-condensed breakdown (maximum 3 bullet points):
    - Key name and drop or quest chain source
    - Doors and shortcuts unlocked
    - Lockpicking skill or Seaforium charge alternative
    Rules: Never output LaTeX math. Plain text only. Alt-tab friendly.
    """
    ai_text = await query_gemini_text(prompt)
    if ai_text:
        clean_text = ai_text.replace("$\\rightarrow$", "->").replace("\\rightarrow", "->")
        embed = discord.Embed(
            title=f"🗝️ Dungeon Key: {dungeon.title()}",
            description=clean_text.strip(),
            color=0xE67E22
        )
        embed.set_footer(text="World of Warcraft: Forever Companion")
        await interaction.followup.send(embed=embed)
        return

    await interaction.followup.send(f"❌ Key info for `{dungeon}` not found.", ephemeral=True)


@keys_command.autocomplete("query")
async def keys_autocomplete(interaction: discord.Interaction, current: str) -> List[app_commands.Choice[str]]:
    keys = [
        "Shadowforge Key (Blackrock Depths)",
        "Skeleton Key (Scholomance)",
        "Key to the City (Stratholme)",
        "Scarlet Key (Scarlet Monastery)",
        "Crescent Key (Dire Maul)",
        "Scepter of Celebras (Maraudon)",
        "Workshop Key (Gnomeregan)"
    ]
    current_l = current.lower()
    matches = [k for k in keys if current_l in k.lower()]
    return [app_commands.Choice(name=m[:100], value=m[:100]) for m in matches[:25]]


# -------------------------------------------------------------
# Slash Command: /race (Racial Traits, Weapon Skills & Meta)
# -------------------------------------------------------------
@bot.tree.command(name="race", description="Racial traits, weapon skill bonuses (+5 swords/axes), and PvP/PvE meta")
@app_commands.describe(query="Playable race (e.g. 'Human', 'Skyborne Elf', 'Orc', 'Undead', 'Dwarf', 'Gnome')")
async def race_command(interaction: discord.Interaction, query: str):
    name = query
    await interaction.response.defer(ephemeral=True)
    r = get_racial_info(name)
    if r:
        faction_color = 0x2980B9 if r["faction"] == "Alliance" else 0xC0392B
        embed = discord.Embed(
            title=f"🛡️ {r['race']} ({r['faction']}) Racial Traits",
            color=faction_color
        )
        embed.description = (
            f"{r['traits']}\n\n"
            f"**Meta & Mechanics:**\n{r['meta']}\n\n"
            f"💡 *Tip:* {r['tip']}"
        )
        embed.set_footer(text="World of Warcraft: Forever Companion • Race Mechanics")
        await interaction.followup.send(embed=embed)
        return

    # Fallback to Gemini
    prompt = f"""
    You are Foreverbot, an expert World of Warcraft race and mechanics guide.
    A player is asking about the race: "{name}".
    Provide an ultra-condensed breakdown:
    - All racial traits & passives
    - Weapon skill advantages (e.g. +5 skill eliminating glancing blow penalties)
    - PvE and PvP meta evaluation
    Rules: Never output LaTeX math. Plain text only. Alt-tab friendly.
    """
    ai_text = await query_gemini_text(prompt)
    if ai_text:
        clean_text = ai_text.replace("$\\rightarrow$", "->").replace("\\rightarrow", "->")
        embed = discord.Embed(
            title=f"🛡️ Race Guide: {name.title()}",
            description=clean_text.strip(),
            color=0x3498DB
        )
        embed.set_footer(text="World of Warcraft: Forever Companion")
        await interaction.followup.send(embed=embed)
        return

    await interaction.followup.send(f"❌ Race `{name}` not found.", ephemeral=True)


@race_command.autocomplete("query")
async def race_autocomplete(interaction: discord.Interaction, current: str) -> List[app_commands.Choice[str]]:
    races = [
        "Human (Alliance)",
        "Dwarf (Alliance)",
        "Night Elf (Alliance)",
        "Gnome (Alliance)",
        "Skyborne Elf (Alliance - Classic+)",
        "Orc (Horde)",
        "Undead (Horde)",
        "Tauren (Horde)",
        "Troll (Horde)"
    ]
    current_l = current.lower()
    matches = [r for r in races if current_l in r.lower()]
    return [app_commands.Choice(name=m[:100], value=m[:100]) for m in matches[:25]]


# -------------------------------------------------------------
# Slash Command: /comp (Raid Comp & Buff Synergy Optimizer)
# -------------------------------------------------------------
@bot.tree.command(name="comp", description="Raid comp & buff synergy optimizer (Sunder, Windfury, CoR, Tranq Shot)")
@app_commands.describe(query="Roster composition (e.g. '8 warr, 6 rogue, 6 mage, 4 lock, 6 priest, 3 hunter, 5 shaman, 2 druid')")
async def comp_command(interaction: discord.Interaction, query: str):
    roster = query
    await interaction.response.defer(ephemeral=True)
    res = analyze_raid_comp(roster)
    counts = res["counts"]
    breakdown = (
        f"**Roster ({res['total_players']} Players):** "
        f"{counts['warrior']} Warr • {counts['rogue']} Rog • {counts['mage']} Mage • {counts['warlock']} Lock • "
        f"{counts['priest']} Priest • {counts['druid']} Druid • {counts['hunter']} Hunt • {counts['shaman']} Sham • {counts['paladin']} Pal"
    )

    covered_str = "\n".join(res["covered"][:8]) if res["covered"] else "No major buffs covered."
    missing_str = "\n".join(res["missing"]) if res["missing"] else "✨ All critical raid debuffs and utility covered!"

    embed = discord.Embed(
        title="🛡️ Raid Composition & Synergy Analysis",
        description=f"{breakdown}\n\n**Covered Buffs & Synergies:**\n{covered_str}\n\n**Missing Synergies & Risks:**\n{missing_str}",
        color=0x2ECC71 if not res["missing"] else 0xE67E22
    )
    embed.set_footer(text="World of Warcraft: Forever Companion • Raid Synergy")
    await interaction.followup.send(embed=embed)


# -------------------------------------------------------------
# Slash Command: /bis (Slot-by-Slot Pre-Raid & Phase BiS Lists)
# -------------------------------------------------------------
@bot.tree.command(name="bis", description="Slot-by-slot Pre-Raid and Phase BiS gear lists with drop sources")
@app_commands.describe(query="Your class", spec="Specialization (e.g. 'Fury', 'Combat', 'Frost', 'Holy', 'Marksmanship')")
async def bis_command(interaction: discord.Interaction, query: str, spec: Optional[str] = None):
    class_name = query
    await interaction.response.defer(ephemeral=True)
    b = get_bis_list(class_name, spec)
    if b:
        embed = discord.Embed(
            title=f"💎 {b['class']} — {b['spec']} ({b['phase']})",
            color=0x9B59B6
        )
        embed.description = f"{b['gear']}\n\n💡 *Hit & Stat Summary:* {b['hit_summary']}"
        embed.set_footer(text="World of Warcraft: Forever Companion • Best-in-Slot Directory")
        await interaction.followup.send(embed=embed)
        return

    # Fallback to Gemini
    prompt = f"""
    You are Foreverbot, an expert World of Warcraft: Forever (Classic+) gear itemization guide.
    A player needs the Best-in-Slot (BiS) gear list for: Class="{class_name}", Spec="{spec or 'Standard'}".
    Provide a condensed slot-by-slot list for:
    Head, Neck, Shoulders, Back, Chest, Bracers, Hands, Waist, Legs, Feet, Rings, Trinkets, Weapons, Ranged/Wand.
    Include exact boss and dungeon drop source for each piece.
    Rules: Plain text only, zero conversational fluff, alt-tab friendly.
    """
    ai_text = await query_gemini_text(prompt)
    if ai_text:
        clean_text = ai_text.replace("$\\rightarrow$", "->").replace("\\rightarrow", "->")
        embed = discord.Embed(
            title=f"💎 {class_name.title()} {spec.title() if spec else ''} BiS Gear",
            description=clean_text.strip(),
            color=0x9B59B6
        )
        embed.set_footer(text="World of Warcraft: Forever Companion")
        await interaction.followup.send(embed=embed)
        return

    await interaction.followup.send(f"❌ BiS list for `{class_name}` not found.", ephemeral=True)


@bis_command.autocomplete("query")
async def bis_class_autocomplete(interaction: discord.Interaction, current: str) -> List[app_commands.Choice[str]]:
    classes = ["Warrior", "Rogue", "Mage", "Priest", "Warlock", "Hunter", "Druid", "Paladin", "Shaman"]
    current_l = current.lower()
    matches = [c for c in classes if current_l in c.lower()]
    return [app_commands.Choice(name=m, value=m) for m in matches[:25]]


# -------------------------------------------------------------
# Slash Command: /farm (Gold Farming & G/hr Engine)
# -------------------------------------------------------------
@bot.tree.command(name="farm", description="Gold farming hotspots, solo dungeon skips, and estimated G/hr")
@app_commands.describe(query="Farm location or class (e.g. 'dm east', 'maraudon', 'tribute', 'zf graveyard', 'elemental earth')")
async def farm_command(interaction: discord.Interaction, query: Optional[str] = "dm east"):
    await interaction.response.defer(ephemeral=True)
    q = query or "dm east"
    gf = get_gold_farm_info(q)
    if gf:
        embed = discord.Embed(
            title=f"🪙 {gf['title']}",
            color=0xF1C40F
        )
        embed.description = (
            f"• **Estimated Yield:** **{gf['g_per_hour']}**\n"
            f"• **Recommended Classes:** {gf['classes']}\n\n"
            f"**Execution Strategy:**\n{gf['strategy']}\n\n"
            f"💡 *Tip:* {gf['tip']}"
        )
        embed.set_footer(text="World of Warcraft: Forever Companion • Gold Making")
        await interaction.followup.send(embed=embed)
        return

    # Fallback to Gemini
    prompt = f"""
    You are Foreverbot, an expert World of Warcraft gold-farming guide.
    A player is asking about the gold farm: "{q}".
    Provide an ultra-condensed breakdown (maximum 3-4 bullet points):
    - Estimated Gold/Hour and market demand
    - Best classes and gear/spec requirements
    - Step-by-step route and reset / lock-out mechanics
    Rules: Plain text only, zero conversational fluff.
    """
    ai_text = await query_gemini_text(prompt)
    if ai_text:
        clean_text = ai_text.replace("$\\rightarrow$", "->").replace("\\rightarrow", "->")
        embed = discord.Embed(
            title=f"🪙 Gold Farm: {q.title()}",
            description=clean_text.strip(),
            color=0xF1C40F
        )
        embed.set_footer(text="World of Warcraft: Forever Companion")
        await interaction.followup.send(embed=embed)
        return

    await interaction.followup.send(f"❌ Gold farm `{q}` not found.", ephemeral=True)


@farm_command.autocomplete("query")
async def farm_autocomplete(interaction: discord.Interaction, current: str) -> List[app_commands.Choice[str]]:
    farms = [
        "Dire Maul East (DM East) Jump Runs",
        "Maraudon Princess & Tinkerer Solo Run",
        "Dire Maul North (DM North) Solo Tribute Run",
        "Zul'Farrak (ZF) Graveyard AOE Zombie Farm",
        "Elemental Earth & Fire Hotspot Grinding",
        "Tyr's Hand Scarlet Elite Grinding"
    ]
    current_l = current.lower()
    matches = [f for f in farms if current_l in f.lower()]
    return [app_commands.Choice(name=m[:100], value=m[:100]) for m in matches[:25]]


# -------------------------------------------------------------
# Slash Command: /events (World Events, DMF & Gurubashi Timers)
# -------------------------------------------------------------
@bot.tree.command(name="events", description="World events, Darkmoon Faire, STV Fishing contest, and Gurubashi chest timers")
@app_commands.describe(query="Specific event (e.g. 'gurubashi', 'dmf', 'fishing', or 'all')")
async def events_command(interaction: discord.Interaction, query: Optional[str] = "all"):
    event = query
    await interaction.response.defer(ephemeral=True)
    we = get_world_events_info(event)
    ev_lower = (event or "all").lower().strip()

    if ev_lower in ["gurubashi", "arena", "chest"]:
        g = we["gurubashi"]
        embed = discord.Embed(title=g["title"], color=0xE74C3C)
        embed.description = f"{g['time_remaining']}\n• **Schedule:** {g['schedule']}\n• **Objective:** {g['objective']}\n• **Reward:** {g['reward']}"
    elif ev_lower in ["fishing", "stv", "extravaganza"]:
        f_ev = we["fishing"]
        embed = discord.Embed(title=f_ev["title"], color=0x3498DB)
        embed.description = f"{f_ev['time_remaining']}\n• **Schedule:** {f_ev['schedule']}\n• **Objective:** {f_ev['objective']}\n\n**Rewards:**\n{f_ev['rewards']}"
    elif ev_lower in ["dmf", "darkmoon", "faire"]:
        d = we["dmf"]
        embed = discord.Embed(title=d["title"], color=0x9B59B6)
        embed.description = f"• **Current Location:** **{d['current_location']}**\n• **+10% Damage Buff:** {d['buff_tip']}\n• **Epic Decks:** {d['cards']}"
    else:
        # All events summary
        g = we["gurubashi"]
        f_ev = we["fishing"]
        d = we["dmf"]
        embed = discord.Embed(title="⏰ World Events & Timers Directory", color=0xF39C12)
        embed.description = (
            f"**⚔️ Gurubashi Arena Chest:**\n{g['time_remaining']}\n\n"
            f"**🎣 STV Fishing Extravaganza:**\n{f_ev['time_remaining']}\n\n"
            f"**🎪 Darkmoon Faire (DMF):**\n• Setup Location: **{d['current_location']}**\n• {d['buff_tip']}"
        )
    embed.set_footer(text="World of Warcraft: Forever Companion • Events & Timers")
    await interaction.followup.send(embed=embed)


# -------------------------------------------------------------
# Slash Command: /gdkp (GDKP Pot Splitter)
# -------------------------------------------------------------
@bot.tree.command(name="gdkp", description="GDKP raid pot splitter, organizer cuts, tank bonuses, and per-raider payout")
@app_commands.describe(
    query="Total pot in gold (e.g. 50000)",
    cut="Organizer cut % (default 10%)",
    raiders="Total raiders splitting the pot (default 40)",
    tanks="Number of main tanks getting bonus cut (default 0)",
    tank_bonus="Bonus % per tank (default 2%)"
)
async def gdkp_command(interaction: discord.Interaction, query: int, cut: Optional[int] = 10, raiders: Optional[int] = 40, tanks: Optional[int] = 0, tank_bonus: Optional[int] = 2):
    pot = query
    res = calculate_gdkp(pot, cut_pct=cut or 10, raiders=raiders or 40, tanks=tanks or 0, tank_bonus_pct=tank_bonus or 2)
    embed = discord.Embed(
        title=f"💰 GDKP Pot Split Calculator ({pot:,}g Gross)",
        color=0xF1C40F
    )
    desc = (
        f"• **Gross Pot:** **{res['gross_pot']:,}g**\n"
        f"• **Organizer Cut ({res['cut_pct']}%):** -{res['organizer_cut']:,}g\n"
    )
    if res["tanks"] > 0:
        desc += f"• **Tank Incentive ({res['tanks']} tanks • {tank_bonus}%):** -{res['tank_pot']:,}g\n"
    desc += (
        f"• **Net Distributable Pot:** **{res['net_pot']:,}g**\n\n"
        f"🏆 **Payout Per Raider ({res['raiders']} players):** **{res['payout_per_raider']:,}g**\n"
    )
    if res["tanks"] > 0:
        desc += f"🛡️ **Total Tank Payout (Raider + Bonus):** **{res['tank_total_payout']:,}g**\n"
    embed.description = desc
    embed.set_footer(text="World of Warcraft: Forever Companion • GDKP Ledger")
    await interaction.response.send_message(embed=embed, ephemeral=True)


# -------------------------------------------------------------
# Loot Roll Interactive View & Command: /roll
# -------------------------------------------------------------
class LootRollView(discord.ui.View):
    def __init__(self, item_name: str, timeout: int = 30):
        super().__init__(timeout=timeout)
        self.item_name = item_name
        self.rolls: Dict[int, tuple] = {}
        self.message = None

    @discord.ui.button(label="🎲 Roll (1-100)", style=discord.ButtonStyle.primary, custom_id="roll_button")
    async def roll_button(self, interaction: discord.Interaction, button: discord.ui.Button):
        user = interaction.user
        if user.id in self.rolls:
            await interaction.response.send_message(f"⚠️ You already rolled a **{self.rolls[user.id][1]}**!", ephemeral=True)
            return

        import random
        val = random.randint(1, 100)
        self.rolls[user.id] = (user.display_name, val)
        sorted_rolls = sorted(self.rolls.values(), key=lambda x: x[1], reverse=True)
        lines = [f"**#{i+1}** {name}: **{v}**" for i, (name, v) in enumerate(sorted_rolls[:10])]

        embed = discord.Embed(
            title=f"🎲 Loot Roll: {self.item_name}",
            description=f"Click the button below to roll!\n\n**Current Rolls ({len(self.rolls)} total):**\n" + ("\n".join(lines) if lines else "No rolls yet!"),
            color=0xA335EE
        )
        embed.set_footer(text="World of Warcraft: Forever Loot Council")
        await interaction.response.edit_message(embed=embed, view=self)

    async def on_timeout(self):
        for item in self.children:
            item.disabled = True
        sorted_rolls = sorted(self.rolls.values(), key=lambda x: x[1], reverse=True)
        if sorted_rolls:
            winner_name, top_roll = sorted_rolls[0]
            embed = discord.Embed(
                title=f"🏆 Winner: {winner_name} rolled {top_roll}!",
                description=(
                    f"Congratulations **{winner_name}** on winning **{self.item_name}** with a roll of **{top_roll}**!\n\n"
                    f"**Final Leaderboard:**\n" + "\n".join([f"• {name}: **{val}**" for name, val in sorted_rolls[:5]])
                ),
                color=0xFF8000
            )
        else:
            embed = discord.Embed(
                title=f"🎲 Roll Expired: {self.item_name}",
                description="No rolls were placed before the timer expired.",
                color=0x95A5A6
            )
        embed.set_footer(text="World of Warcraft: Forever Companion • Roll Closed")
        try:
            if self.message:
                await self.message.edit(embed=embed, view=self)
        except Exception:
            pass


@bot.tree.command(name="roll", description="Interactive raid loot roll engine with real-time countdown and button UI")
@app_commands.describe(query="Item name being rolled (e.g. 'Neltharion\\'s Tear')", seconds="Roll timer in seconds (default 30)")
async def roll_command(interaction: discord.Interaction, query: Optional[str] = "Item", seconds: Optional[int] = 30):
    item = query
    timeout_val = min(max(seconds or 30, 10), 120)
    view = LootRollView(item_name=item or "Item", timeout=timeout_val)
    embed = discord.Embed(
        title=f"🎲 Loot Roll: {item}",
        description=f"A loot roll for **{item}** has been initiated!\nClick **Roll (1-100)** below within **{timeout_val} seconds** to enter your roll.",
        color=0xA335EE
    )
    embed.set_footer(text=f"Timer: {timeout_val} seconds • 1 roll per player")
    await interaction.response.send_message(embed=embed, view=view)
    view.message = await interaction.original_response()


# -------------------------------------------------------------
# Slash Command: /compare (Weapon & Combat Simulator)
# -------------------------------------------------------------
@bot.tree.command(name="compare", description="Compare two weapons with glancing blow math (+5 weapon skill vs lvl 63 bosses)")
@app_commands.describe(query="First weapon name", weapon2="Second weapon name", race="Character race (e.g. 'Human', 'Orc', 'Dwarf')", character_class="Class (default 'Warrior')")
async def compare_command(interaction: discord.Interaction, query: str, weapon2: str, race: Optional[str] = "Human", character_class: Optional[str] = "Warrior"):
    weapon1 = query
    await interaction.response.defer(ephemeral=True)
    comp = compare_weapons(weapon1, weapon2, race=race or "Human")
    w1, w2 = comp["weapon1"], comp["weapon2"]

    embed = discord.Embed(
        title=f"⚔️ Weapon Compare: {w1['name']} vs {w2['name']}",
        color=0x3498DB
    )
    embed.description = (
        f"**1. {w1['name']} ({w1['type']})**\n"
        f"• Speed: {w1['speed']}s • Damage: {w1['min_dmg']}–{w1['max_dmg']} ({w1['dps']} DPS)\n"
        f"• Stats: {w1['stats']}\n\n"
        f"**2. {w2['name']} ({w2['type']})**\n"
        f"• Speed: {w2['speed']}s • Damage: {w2['min_dmg']}–{w2['max_dmg']} ({w2['dps']} DPS)\n"
        f"• Stats: {w2['stats']}\n\n"
        f"{comp['glancing_analysis']}\n\n"
        f"{comp['hit_cap_analysis']}\n\n"
        f"💡 **Verdict for {comp['race']} {character_class.title() if character_class else ''}:**\n{comp['verdict']}"
    )
    embed.set_footer(text="World of Warcraft: Forever Companion • Combat Mechanics")
    await interaction.followup.send(embed=embed)

# -------------------------------------------------------------
# Slash Command: /resets (Dynamic Raid Lockout & Reset Clock)
# -------------------------------------------------------------
@bot.tree.command(name="resets", description="View live countdowns to Weekly, Onyxia (5-day), ZG (3-day), and Daily resets")
@app_commands.describe(query="Optional filter for resets (e.g. 'onyxia', 'zg', 'weekly')")
async def resets_command(interaction: discord.Interaction, query: Optional[str] = None):
    await interaction.response.defer(ephemeral=True)
    res = get_raid_lockouts()
    embed = discord.Embed(
        title="⏳ World of Warcraft Raid & World Resets",
        color=0x3498DB
    )
    embed.description = (
        f"**🗓️ Weekly Raid Lockout Reset:**\n{res['weekly']}\n"
        f"*(Molten Core, Blackwing Lair, Temple of Ahn'Qiraj, Naxxramas, World Bosses)*\n\n"
        f"**🐉 Onyxia's Lair (5-Day Rolling Cycle):**\n{res['onyxia']}\n\n"
        f"**🌴 Zul'Gurub & Ruins of Ahn'Qiraj (3-Day Cycle):**\n{res['zg']}\n\n"
        f"**☀️ Daily Quest & Dungeon Reset:**\n{res['daily']}\n\n"
        f"💡 *Raid IDs bind upon killing the first boss. 3-day and 5-day lockouts rotate independently of Tuesday resets!*"
    )
    embed.set_footer(text="World of Warcraft: Forever Companion • Raid Lockouts")
    await interaction.followup.send(embed=embed)


# -------------------------------------------------------------
# Slash Command: /twink (Twink Gear & Battleground Brackets)
# -------------------------------------------------------------
@bot.tree.command(name="twink", description="Twink Best-in-Slot weapons, armor, and uncapped Classic enchants")
@app_commands.describe(query="Twink level bracket (19, 29, or 39)", character_class="Optional character class (e.g. Rogue, Hunter, Warrior, Priest)")
async def twink_command(interaction: discord.Interaction, query: str, character_class: Optional[str] = None):
    bracket = query
    await interaction.response.defer(ephemeral=True)
    tw = get_twink_info(bracket)
    if not tw:
        await interaction.followup.send(f"❌ Unknown bracket `{bracket}`. Supported brackets: 19, 29, 39.", ephemeral=True)
        return

    cls_str = f" • {character_class.title()}" if character_class else ""
    embed = discord.Embed(
        title=f"⚔️ Twink Guide: {tw['bracket']}{cls_str}",
        color=0xE67E22
    )
    embed.description = (
        f"*{tw['overview']}*\n\n"
        f"**🗡️ Top Weapons:**\n{tw['weapons']}\n\n"
        f"**🛡️ BiS Armor & Accessories:**\n{tw['armor']}\n\n"
        f"**✨ Uncapped Classic Enchants:**\n{tw['enchants']}"
    )
    embed.set_footer(text="World of Warcraft: Forever Companion • Twink Metas")
    await interaction.followup.send(embed=embed)


@twink_command.autocomplete("query")
async def twink_bracket_autocomplete(interaction: discord.Interaction, current: str) -> List[app_commands.Choice[str]]:
    brackets = ["19", "29", "39"]
    return [app_commands.Choice(name=f"Level {b} Bracket", value=b) for b in brackets if current in b]


# -------------------------------------------------------------
# Slash Command: /route (Speedleveling Quest Route Bundles)
# -------------------------------------------------------------
@bot.tree.command(name="route", description="Speedleveling quest routes (10-20, 20-30, 30-40) with death warps and skips")
@app_commands.describe(query="Level range bundle (10-20, 20-30, 30-40)", faction="Faction filter (Alliance, Horde, or Both)")
async def route_command(interaction: discord.Interaction, query: str, faction: Optional[str] = "Both"):
    level = query
    await interaction.response.defer(ephemeral=True)
    rt = get_leveling_route(level)
    if not rt:
        await interaction.followup.send(f"❌ Unknown level range `{level}`. Supported: 10-20, 20-30, 30-40.", ephemeral=True)
        return

    f_lower = (faction or "both").lower().strip()
    embed = discord.Embed(
        title=f"🗺️ Speedrun Quest Route: {rt['range']}",
        color=0x2ECC71
    )
    desc_parts = []
    if f_lower in ["alliance", "both", "all"]:
        desc_parts.append(f"**🦁 Alliance Route:**\n{rt['alliance']}")
    if f_lower in ["horde", "both", "all"]:
        desc_parts.append(f"**⚡ Horde Route:**\n{rt['horde']}")

    desc_parts.append(f"\n{rt['skip_tip']}")
    embed.description = "\n\n".join(desc_parts)
    embed.set_footer(text="World of Warcraft: Forever Companion • Speedleveling")
    await interaction.followup.send(embed=embed)


@route_command.autocomplete("query")
async def route_level_autocomplete(interaction: discord.Interaction, current: str) -> List[app_commands.Choice[str]]:
    routes = ["10-20", "20-30", "30-40"]
    return [app_commands.Choice(name=f"Level {r} Route", value=r) for r in routes if current in r]


# -------------------------------------------------------------
# Slash Command: /addons (Essential Addon Directory & Recommendations)
# -------------------------------------------------------------
@bot.tree.command(name="addons", description="Essential Classic WoW addons, optimal settings, and zero-lag configurations")
@app_commands.describe(query="Addon name or category (e.g. 'questie', 'details', 'threatclassic2', 'bigwigs', 'itemrack')")
async def addons_command(interaction: discord.Interaction, query: Optional[str] = None):
    await interaction.response.defer(ephemeral=True)
    if query:
        ad = get_addon_info(query)
        if ad:
            embed = discord.Embed(
                title=f"🧩 Addon Guide: {ad['name']} ({ad['category']})",
                color=0x1ABC9C
            )
            embed.description = (
                f"**Purpose & Features:**\n{ad['purpose']}\n\n"
                f"⚙️ **Optimal In-Game Configuration:**\n{ad['config']}"
            )
            embed.set_footer(text="World of Warcraft: Forever Companion • Addons Directory")
            await interaction.followup.send(embed=embed)
            return

    # Directory view of essential addons
    embed = discord.Embed(
        title="🧩 Essential Classic WoW Addons Directory",
        description="The highest-rated, zero-lag addons recommended for raiding, leveling, and PvP:",
        color=0x1ABC9C
    )
    for k, v in list(ADDONS_DATA.items())[:6]:
        embed.add_field(name=f"• {v['name']} ({v['category']})", value=v['purpose'][:150] + "...", inline=False)
    embed.set_footer(text="Run `/addons query:<name>` for in-depth configuration guide!")
    await interaction.followup.send(embed=embed)


@addons_command.autocomplete("query")
async def addons_autocomplete(interaction: discord.Interaction, current: str) -> List[app_commands.Choice[str]]:
    keys = list(ADDONS_DATA.keys())
    matches = [k for k in keys if current.lower() in k]
    return [app_commands.Choice(name=ADDONS_DATA[m]["name"], value=m) for m in matches[:25]]


# -------------------------------------------------------------
# Slash Command: /trivia (Interactive WoW Lore & Mechanics Trivia)
# -------------------------------------------------------------
class TriviaView(discord.ui.View):
    def __init__(self, trivia: Dict[str, Any], timeout: int = 30):
        super().__init__(timeout=timeout)
        self.trivia = trivia
        self.answered = False
        self.message: Optional[discord.Message] = None

        labels = ["A", "B", "C", "D"]
        for i, opt in enumerate(trivia["options"]):
            btn = discord.ui.Button(
                label=f"{labels[i]}: {opt}"[:80],
                style=discord.ButtonStyle.secondary,
                custom_id=f"trivia_opt_{i}"
            )
            btn.callback = self._make_callback(i)
            self.add_item(btn)

    def _make_callback(self, index: int):
        async def button_callback(interaction: discord.Interaction):
            if self.answered:
                await interaction.response.send_message("This question has already been answered!", ephemeral=True)
                return

            if index == self.trivia["correct"]:
                self.answered = True
                for item in self.children:
                    if isinstance(item, discord.ui.Button):
                        item.disabled = True
                        if item.custom_id == f"trivia_opt_{index}":
                            item.style = discord.ButtonStyle.success
                        else:
                            item.style = discord.ButtonStyle.secondary

                embed = discord.Embed(
                    title=f"🎉 Correct! {interaction.user.display_name} won the trivia!",
                    description=(
                        f"**Question:** {self.trivia['question']}\n\n"
                        f"✅ **Correct Answer:** **{self.trivia['options'][index]}**\n\n"
                        f"📖 **Lore & History:**\n{self.trivia['explanation']}"
                    ),
                    color=0x2ECC71
                )
                embed.set_footer(text=f"Answered by {interaction.user.display_name} • World of Warcraft Trivia")
                await interaction.response.edit_message(embed=embed, view=self)
                self.stop()
            else:
                await interaction.response.send_message(
                    f"❌ **{self.trivia['options'][index]}** is incorrect! Keep guessing or let a guildie try!",
                    ephemeral=True
                )
        return button_callback

    async def on_timeout(self):
        if not self.answered:
            for item in self.children:
                if isinstance(item, discord.ui.Button):
                    item.disabled = True
                    if item.custom_id == f"trivia_opt_{self.trivia['correct']}":
                        item.style = discord.ButtonStyle.success

            embed = discord.Embed(
                title="⏰ Time's Up! No one answered in time.",
                description=(
                    f"**Question:** {self.trivia['question']}\n\n"
                    f"✅ **Correct Answer:** **{self.trivia['options'][self.trivia['correct']]}**\n\n"
                    f"📖 **Lore & History:**\n{self.trivia['explanation']}"
                ),
                color=0xE74C3C
            )
            embed.set_footer(text="World of Warcraft Trivia • Timed out after 30s")
            if self.message:
                try:
                    await self.message.edit(embed=embed, view=self)
                except Exception:
                    pass


@bot.tree.command(name="trivia", description="Test your WoW lore and mechanics knowledge with interactive Discord buttons")
@app_commands.describe(query="Optional topic or category (e.g. 'lore', 'raids', 'mechanics')")
async def trivia_command(interaction: discord.Interaction, query: Optional[str] = None):
    q = get_random_trivia()
    view = TriviaView(trivia=q, timeout=30)
    embed = discord.Embed(
        title="🧠 World of Warcraft Trivia Challenge",
        description=f"**{q['question']}**\n\nClick a button below within **30 seconds** to submit your answer!",
        color=0x9B59B6
    )
    embed.set_footer(text="World of Warcraft: Forever Companion • Lore Trivia (30s timer)")
    await interaction.response.send_message(embed=embed, view=view, ephemeral=True)
    view.message = await interaction.original_response()


# -------------------------------------------------------------
# Slash Command Group: /profile (Guild Character Armory & Profile)
# -------------------------------------------------------------
profile_group = app_commands.Group(name="profile", description="Guild character armory and profile management")

CLASS_COLORS = {
    "warrior": 0xC79C6E,
    "paladin": 0xF58CBA,
    "hunter": 0xABD473,
    "rogue": 0xFFF569,
    "priest": 0xFFFFFF,
    "shaman": 0x0070DE,
    "mage": 0x69CCF0,
    "warlock": 0x9482C9,
    "druid": 0xFF7D0A
}

@profile_group.command(name="set", description="Set or update your character's armory profile")
@app_commands.describe(
    query="Character Name",
    character_class="Class (Warrior, Mage, Rogue, Priest, Warlock, Hunter, Druid, Paladin, Shaman)",
    race="Race (Human, Orc, Dwarf, Undead, Night Elf, Tauren, Gnome, Troll, Skyborne Elf)",
    level="Level (1-60, default 60)",
    spec="Talent Spec (e.g. 'Fury DPS', 'Frost AoE', 'Holy Healer')",
    professions="Professions (e.g. '300 Engineering / 300 Mining')",
    guild_role="Guild Role (e.g. 'Main Tank', 'Officer', 'Raid DPS', 'Healer')",
    gear_note="Key Gear / Goals (e.g. '8/8 T2 Netherwind, Neltharion\\'s Tear')"
)
async def profile_set(
    interaction: discord.Interaction,
    query: str,
    character_class: str,
    race: str,
    level: Optional[int] = 60,
    spec: Optional[str] = "",
    professions: Optional[str] = "",
    guild_role: Optional[str] = "",
    gear_note: Optional[str] = ""
):
    await interaction.response.defer(ephemeral=True)
    name = query
    lvl = min(max(level or 60, 1), 60)
    db.set_user_profile(
        user_id=interaction.user.id,
        char_name=name.strip().title(),
        char_class=character_class.strip().title(),
        char_race=race.strip().title(),
        level=lvl,
        spec=spec.strip(),
        professions=professions.strip(),
        guild_role=guild_role.strip(),
        gear_note=gear_note.strip()
    )
    c_color = CLASS_COLORS.get(character_class.lower().strip(), 0xF1C40F)
    embed = discord.Embed(
        title=f"🛡️ Profile Saved: {name.strip().title()}",
        description=(
            f"**Level {lvl} {race.strip().title()} {character_class.strip().title()}**\n\n"
            f"• **Talent Spec:** {spec.strip() or 'Not specified'}\n"
            f"• **Professions:** {professions.strip() or 'None recorded'}\n"
            f"• **Guild Role:** {guild_role.strip() or 'Member'}\n"
            f"• **Notable Gear:** {gear_note.strip() or 'None recorded'}\n\n"
            f"✅ *Profile registered to {interaction.user.mention}! View anytime with `/profile view`.*"
        ),
        color=c_color
    )
    embed.set_footer(text=f"Updated by @{interaction.user.display_name} • Guild Armory")
    await interaction.followup.send(embed=embed)


@profile_group.command(name="view", description="View a guild member's character armory profile")
@app_commands.describe(
    query="Character name to look up",
    member="Discord guild member to look up"
)
async def profile_view(
    interaction: discord.Interaction,
    query: Optional[str] = None,
    member: Optional[discord.Member] = None
):
    character_name = query
    await interaction.response.defer(ephemeral=True)
    prof = None
    target_label = ""
    if character_name:
        prof = db.get_profile_by_name(character_name)
        target_label = f"Character `{character_name}`"
    else:
        target_user = member or interaction.user
        prof = db.get_user_profile(target_user.id)
        target_label = target_user.mention

    if not prof:
        await interaction.followup.send(f"❌ No character profile found for {target_label}. Register one using `/profile set`!", ephemeral=True)
        return

    c_color = CLASS_COLORS.get(prof["char_class"].lower().strip(), 0x3498DB)
    embed = discord.Embed(
        title=f"🛡️ Armory: {prof['char_name']} (Lvl {prof['level']} {prof['char_race']} {prof['char_class']})",
        color=c_color
    )
    embed.description = (
        f"• **Talent Spec:** {prof['spec'] or 'N/A'}\n"
        f"• **Professions:** {prof['professions'] or 'N/A'}\n"
        f"• **Guild Role:** {prof['guild_role'] or 'Guild Member'}\n"
        f"• **Notable Gear / Notes:** {prof['gear_note'] or 'None recorded'}\n\n"
        f"🕒 *Last updated: {prof.get('updated_at', 'Recently')}*"
    )
    embed.set_footer(text="World of Warcraft: Forever Companion • Guild Armory")
    await interaction.followup.send(embed=embed)

bot.tree.add_command(profile_group)


# -------------------------------------------------------------
# Slash Command: /resist (Resistance Cap & Mitigation Calculator)
# -------------------------------------------------------------
@bot.tree.command(name="resist", description="Calculate resistance mitigation tiers, average damage resisted %, and cap math")
@app_commands.describe(query="Resistance school (Fire, Nature, Frost, Shadow)", current="Current resistance rating (default 0)", role="Raid role (Tank, DPS, Healer)")
async def resist_command(interaction: discord.Interaction, query: str, current: Optional[int] = 0, role: Optional[str] = "DPS"):
    school = query
    await interaction.response.defer(ephemeral=True)
    r = calculate_resistance_mitigation(school, current_val=current or 0, role=role or "DPS")

    color_map = {
        "Fire Resistance (FR)": 0xE74C3C,
        "Nature Resistance (NR)": 0x2ECC71,
        "Frost Resistance (Frost R)": 0x3498DB,
        "Shadow Resistance (SR)": 0x9B59B6
    }
    c = color_map.get(r["school"], 0xF39C12)

    embed = discord.Embed(
        title=f"🛡️ {r['school']} Mitigation Calculator",
        color=c
    )
    embed.description = (
        f"• **Current Rating:** **{r['current']}** ({r['tier_label']})\n"
        f"• **Average Resisted Damage:** **{r['mitigation_pct']}%** vs Level 63 Raid Bosses\n"
        f"• **Target Breakpoints:** Soft Cap: **{r['soft_cap']}** (Need +{r['pts_to_soft']}) • Hard Cap: **{r['hard_cap']}** (Need +{r['pts_to_hard']})\n\n"
        f"🎯 **Key Raid Encounters:**\n{r['encounters']}\n\n"
        f"✨ **Recommended Buffs & Auras:**\n{r['buffs']}\n\n"
        f"🛡️ **BiS Resistance Gear & Enchants:**\n{r['gear']}"
    )
    embed.set_footer(text="World of Warcraft: Forever Companion • Resistance Mechanics")
    await interaction.followup.send(embed=embed)


@resist_command.autocomplete("query")
async def resist_autocomplete(interaction: discord.Interaction, current: str) -> List[app_commands.Choice[str]]:
    schools = ["Fire", "Nature", "Frost", "Shadow"]
    return [app_commands.Choice(name=f"{s} Resistance", value=s.lower()) for s in schools if current.lower() in s.lower()]


# -------------------------------------------------------------
# Slash Command: /duels (1v1 PvP Matchup & Cooldown Trading)
# -------------------------------------------------------------
@bot.tree.command(name="duels", description="1v1 PvP matchup simulator with deadzone analysis and cooldown trading")
@app_commands.describe(query="First character class (e.g. Rogue, Warrior, Mage)", class2="Second character class (e.g. Frost Mage, Priest, Warlock)")
async def duels_command(interaction: discord.Interaction, query: str, class2: str):
    class1 = query
    await interaction.response.defer(ephemeral=True)
    m = get_duel_matchup(class1, class2)

    embed = discord.Embed(
        title=f"⚔️ 1v1 PvP: {m['title']}",
        color=0xE67E22
    )
    embed.description = (
        f"⚖️ **Matchup Odds:** **{m['favorability']}**\n\n"
        f"🎯 **Deadzone & Range Dynamic:**\n{m['deadzone_analysis']}\n\n"
        f"🔄 **Crucial Cooldown Trades:**\n{m['cooldown_trades']}\n\n"
        f"🧪 **Key Consumable Counters:**\n{m['consumables_counter']}"
    )
    embed.set_footer(text="World of Warcraft: Forever Companion • Classic 1v1 PvP Metas")
    await interaction.followup.send(embed=embed)


# -------------------------------------------------------------
# Slash Command: /signup (Interactive Raid Signups & Roster Board)
# -------------------------------------------------------------
class RaidSignupView(discord.ui.View):
    def __init__(self, event_id: str, event_title: str, max_players: int = 40):
        super().__init__(timeout=None)
        self.event_id = event_id
        self.event_title = event_title
        self.max_players = max_players

    def _render_embed(self) -> discord.Embed:
        signups = db.get_raid_signups(self.event_id)
        tanks = [s["user_name"] for s in signups if s["role"] == "Tank"]
        melee = [s["user_name"] for s in signups if s["role"] == "Melee"]
        ranged = [s["user_name"] for s in signups if s["role"] == "Caster"]
        healers = [s["user_name"] for s in signups if s["role"] == "Healer"]
        bench = [s["user_name"] for s in signups if s["role"] == "Bench"]

        active_count = len(tanks) + len(melee) + len(ranged) + len(healers)

        embed = discord.Embed(
            title=f"📅 Raid Signups: {self.event_title}",
            description=f"**Roster:** **{active_count} / {self.max_players} Players** (Bench: {len(bench)})\nClick a role button below to sign up or switch roles!",
            color=0x2ECC71 if active_count < self.max_players else 0xE67E22
        )

        embed.add_field(name=f"🛡️ Tanks ({len(tanks)})", value=", ".join(tanks) if tanks else "*None yet*", inline=False)
        embed.add_field(name=f"⚔️ Melee DPS ({len(melee)})", value=", ".join(melee) if melee else "*None yet*", inline=False)
        embed.add_field(name=f"🏹 Caster / Ranged ({len(ranged)})", value=", ".join(ranged) if ranged else "*None yet*", inline=False)
        embed.add_field(name=f"💚 Healers ({len(healers)})", value=", ".join(healers) if healers else "*None yet*", inline=False)
        if bench:
            embed.add_field(name=f"⏳ Bench / Tentative ({len(bench)})", value=", ".join(bench), inline=False)

        embed.set_footer(text=f"Event ID: {self.event_id} • World of Warcraft: Forever Companion")
        return embed

    @discord.ui.button(label="Tank", style=discord.ButtonStyle.primary, emoji="🛡️", custom_id="signup_btn_tank")
    async def tank_button(self, interaction: discord.Interaction, button: discord.ui.Button):
        db.set_raid_signup(self.event_id, self.event_title, interaction.user.id, interaction.user.display_name, "Tank")
        await interaction.response.edit_message(embed=self._render_embed(), view=self)

    @discord.ui.button(label="Melee", style=discord.ButtonStyle.danger, emoji="⚔️", custom_id="signup_btn_melee")
    async def melee_button(self, interaction: discord.Interaction, button: discord.ui.Button):
        db.set_raid_signup(self.event_id, self.event_title, interaction.user.id, interaction.user.display_name, "Melee")
        await interaction.response.edit_message(embed=self._render_embed(), view=self)

    @discord.ui.button(label="Caster", style=discord.ButtonStyle.secondary, emoji="🏹", custom_id="signup_btn_caster")
    async def caster_button(self, interaction: discord.Interaction, button: discord.ui.Button):
        db.set_raid_signup(self.event_id, self.event_title, interaction.user.id, interaction.user.display_name, "Caster")
        await interaction.response.edit_message(embed=self._render_embed(), view=self)

    @discord.ui.button(label="Healer", style=discord.ButtonStyle.success, emoji="💚", custom_id="signup_btn_healer")
    async def healer_button(self, interaction: discord.Interaction, button: discord.ui.Button):
        db.set_raid_signup(self.event_id, self.event_title, interaction.user.id, interaction.user.display_name, "Healer")
        await interaction.response.edit_message(embed=self._render_embed(), view=self)

    @discord.ui.button(label="Bench", style=discord.ButtonStyle.secondary, emoji="⏳", custom_id="signup_btn_bench")
    async def bench_button(self, interaction: discord.Interaction, button: discord.ui.Button):
        db.set_raid_signup(self.event_id, self.event_title, interaction.user.id, interaction.user.display_name, "Bench")
        await interaction.response.edit_message(embed=self._render_embed(), view=self)

    @discord.ui.button(label="Leave", style=discord.ButtonStyle.secondary, emoji="❌", custom_id="signup_btn_leave")
    async def leave_button(self, interaction: discord.Interaction, button: discord.ui.Button):
        db.remove_raid_signup(self.event_id, interaction.user.id)
        await interaction.response.edit_message(embed=self._render_embed(), view=self)


@bot.tree.command(name="signup", description="Create an interactive raid signup and attendance roster board with role buttons")
@app_commands.describe(query="Raid title and schedule (e.g. 'Molten Core - Tuesday 8 PM EST')", max_players="Raid size limit (default 40)")
async def signup_command(interaction: discord.Interaction, query: str, max_players: Optional[int] = 40):
    title = query
    size = min(max(max_players or 40, 5), 40)
    event_id = f"raid_{interaction.id}"
    view = RaidSignupView(event_id=event_id, event_title=title, max_players=size)
    embed = view._render_embed()
    await interaction.response.send_message(embed=embed, view=view)

# -------------------------------------------------------------
# Slash Command: /talents (Spec Code Generator & Talent Tree Visualizer)
# -------------------------------------------------------------
@bot.tree.command(name="talents", description="Spec talent trees, visual ASCII point distribution, and leveling order")
@app_commands.describe(query="Class (Warrior, Mage, Rogue, Priest, Warlock, Hunter, Druid, Paladin, Shaman)", spec="Spec (e.g. 'Fury', 'Frost', 'Combat', 'Shadow', 'SM/Ruin')")
async def talents_command(interaction: discord.Interaction, query: str, spec: Optional[str] = None):
    character_class = query
    await interaction.response.defer(ephemeral=True)
    t = get_talent_build(character_class, spec)
    if not t:
        cb = get_class_build(character_class, spec)
        if cb:
            embed = discord.Embed(
                title=f"🔮 Talent Spec: {cb['class']} {cb['spec']} ({cb['points']})",
                color=0x9B59B6
            )
            embed.description = (
                f"• **Role:** {cb['role']}\n"
                f"• **Stat Priority:** {cb['stat_priority']}\n"
                f"• **Rotation:** {cb['rotation']}\n"
                f"• **Key Milestones:** {cb['milestones']}\n\n"
                f"💡 *Tip:* {cb['tip']}"
            )
            embed.set_footer(text="World of Warcraft: Forever Companion • Talents")
            await interaction.followup.send(embed=embed)
            return
        await interaction.followup.send(f"❌ Unknown build for `{character_class}`. Try Warrior, Mage, Rogue, Priest, Warlock, etc.", ephemeral=True)
        return

    embed = discord.Embed(
        title=f"🔮 Talent Tree: {t['class']} {t['spec']}",
        color=0x9B59B6
    )
    embed.description = (
        f"**Visual Point Distribution:**\n{t['tree_display']}\n\n"
        f"⭐ **Key Capstone Talents:**\n{t['capstones']}\n\n"
        f"📈 **Leveling Point Priority (10 -> 60):**\n{t['priority_order']}\n\n"
        f"🔗 **Talent Calculator URL:**\n{t['share_code']}"
    )
    embed.set_footer(text="World of Warcraft: Forever Companion • Talents Engine")
    await interaction.followup.send(embed=embed)


@talents_command.autocomplete("query")
async def talents_class_autocomplete(interaction: discord.Interaction, current: str) -> List[app_commands.Choice[str]]:
    classes = ["Warrior", "Mage", "Rogue", "Priest", "Warlock", "Hunter", "Druid", "Paladin", "Shaman"]
    return [app_commands.Choice(name=c, value=c.lower()) for c in classes if current.lower() in c.lower()]



# -------------------------------------------------------------
# Slash Command: /forever (Overview & Official Blizzard Beta Patch Notes)
# -------------------------------------------------------------
@bot.tree.command(name="forever", description="WoW: Forever Classic+ Overview & Official Beta Patch Notes (Updated Oct 26)")
@app_commands.describe(query="Topic (e.g. 'patch notes', 'racials', 'classes', 'raid buffs', 'legacy', 'overview')")
async def forever_command(interaction: discord.Interaction, query: Optional[str] = None):
    info = ke.get_forever_beta_info(query)
    embed = discord.Embed(
        title=info["title"],
        description=f"{info['description']}\n\n💡 *Tip:* {info['tip']}",
        color=0xF39C12
    )
    embed.set_footer(text="World of Warcraft: Forever • Open Beta (Updated Oct 26, 2026) • Launching Nov 4, 2026")
    await interaction.response.send_message(embed=embed, ephemeral=True)


@forever_command.autocomplete("query")
async def forever_query_autocomplete(interaction: discord.Interaction, current: str) -> List[app_commands.Choice[str]]:
    topics = [
        ("🌟 Overview & Horizontal Progression", "overview"),
        ("📜 Latest Official Beta Patch Notes (Oct 26)", "patch notes"),
        ("🧬 Racial Abilities & Traits Overhaul (Oct 26)", "racials"),
        ("🛡️ Raid-Wide Buffs, Totems & Mass Salvation", "raid buffs"),
        ("⚔️ Class & Talent Reworks (Druid, Warrior, Mage, Shaman, etc.)", "classes"),
        ("🏕️ Legacy System (16 Pts), Camping, Cooldown Manager & Gamepad", "legacy"),
    ]
    return [app_commands.Choice(name=label, value=val) for label, val in topics if current.lower() in label.lower() or current.lower() in val.lower()]


# -------------------------------------------------------------
# Slash Command: /ask (Friendly Natural Language Guide)
# -------------------------------------------------------------
@bot.tree.command(name="ask", description="Ask any question in plain English (Condensed & Highly Relevant)")
@app_commands.describe(query="Your question (e.g. 'which dungeon to use at 42', 'mankrik wife', 'how to get from duskwood to thousand needles')")
async def ask_command(interaction: discord.Interaction, query: str):
    question = query
    await interaction.response.defer(ephemeral=True)
    q_lower = question.lower()

    # 0. Official Blizzard Beta Patch Notes / Development Notes Check
    if any(p in q_lower for p in ["patch note", "patch notes", "dev note", "development note", "blue tracker", "oct 26", "october 26", "beta update", "new racial", "racial change"]):
        info = ke.get_forever_beta_info(question)
        embed = discord.Embed(
            title=info["title"],
            description=f"{info['description']}\n\n💡 *Tip:* {info['tip']}",
            color=0xF39C12
        )
        embed.set_footer(text="World of Warcraft: Forever • Official Beta Notes (Updated Oct 26, 2026)")
        await interaction.followup.send(embed=embed)
        return

    # 1. Level-specific queries (Only if it's genuinely a level query, not a specific item/mechanic query)
    extracted_lvl = extract_level_from_text(question)
    if extracted_lvl and is_general_level_query(question):
        dungs, _ = db.search_dungeons(level=extracted_lvl, limit=4)
        advice = get_level_advice(extracted_lvl)

        embed = discord.Embed(
            title=f"🏰 Level {extracted_lvl} Guide",
            color=0x9B59B6
        )

        dung_lines = []
        for d in dungs:
            badge = "🌟 " if d["is_forever_content"] else ""
            coord = f" `({d['entrance_coords']})`" if d.get("entrance_coords") else ""
            dung_lines.append(
                f"• {badge}**{d['name']}** (Lvl {d['level_min']}–{d['level_max']} • Rec {d['recommended_level']}) — {d['zone']}{coord}\n  *Top Loot:* {d.get('notable_loot', 'N/A')}"
            )

        desc = "**Recommended Dungeons:**\n" + ("\n".join(dung_lines) if dung_lines else "None for this level (Focus on starter quests).")
        desc += f"\n\n**Quest Zones:**\n• Alliance: {advice['alliance_zones']}\n• Horde: {advice['horde_zones']}"
        embed.description = desc
        embed.set_footer(text="World of Warcraft: Forever Companion")
        await interaction.followup.send(embed=embed)
        return

    # 2. 'After [zone]' progression check (e.g. 'where do i lvl after duskwood', 'where to go after westfall')
    after_data = handle_after_zone(question)
    if after_data:
        from_z = after_data["from_zone"]
        adv = after_data["advice"]
        dungs = after_data["dungeons"]
        dung_str = " • ".join([f"**{d['name']}** ({d['level_min']}-{d['level_max']})" for d in dungs]) if dungs else "Questing focus"

        embed = discord.Embed(
            title=f"🗺️ Progression After {from_z} (Lvl {after_data['next_level']}+)",
            description=(
                f"**Alliance Next Zones:**\n• {adv['alliance_zones']}\n\n"
                f"**Horde Next Zones:**\n• {adv['horde_zones']}\n\n"
                f"🏰 **Recommended Dungeons:** {dung_str}"
            ),
            color=0x1ABC9C
        )
        embed.set_footer(text="World of Warcraft: Forever Companion")
        await interaction.followup.send(embed=embed)
        return

    # 3. Attunements Check
    att_info = get_attunement_info(question)
    if att_info and any(w in q_lower for w in ["attune", "attunement", "onyxia", "ony", "molten core", "mc", "bwl", "blackwing", "naxx", "temporal rift"]):
        embed = discord.Embed(title=f"📜 {att_info['title']}", color=0xF1C40F)
        if "guide" in att_info:
            embed.description = att_info["guide"]
        elif "alliance" in att_info and "horde" in att_info:
            embed.description = f"**Alliance:**\n{att_info['alliance']}\n\n**Horde:**\n{att_info['horde']}"
        if "tip" in att_info:
            embed.set_footer(text=f"💡 Tip: {att_info['tip']}")
        await interaction.followup.send(embed=embed)
        return

    # 4. Core Gameplay Mechanics (Wands, Mounts, Weapon Trainers, Hit/Defense Caps, Armor)
    for mech_k, mech_v in GAMEPLAY_MECHANICS.items():
        if mech_k in q_lower or (mech_k == "wand" and "wands" in q_lower) or (mech_k == "mount" and "riding" in q_lower):
            embed = discord.Embed(
                title=mech_v["title"],
                description=mech_v["description"],
                color=0x9B59B6
            )
            embed.set_footer(text="World of Warcraft: Forever Companion")
            await interaction.followup.send(embed=embed)
            return

    # 5. Travel & Transit Check
    if is_travel_query(question):
        prompt = f"""
        You are Foreverbot, an expert World of Warcraft: Forever (Classic+) navigation assistant.
        A player is asking: "{question}".
        Provide the exact, optimal step-by-step route:
        - Give clear, separate instructions for Alliance and Horde.
        - Mention exact roads, border passes, boats (Booty Bay <-> Ratchet, Menethil <-> Auberdine/Theramore), zeppelins (Orgrimmar <-> Undercity/Grom'gol), or Deeprun Tram.
        - Never output LaTeX math syntax (never use $\\rightarrow$, use simple plain text '->').
        - Ultra-condensed, 2-3 clean bullets total. Zero conversational fluff. Alt-tab friendly.
        """
        ai_travel = await query_gemini_text(prompt)
        if ai_travel:
            clean_travel = ai_travel.replace("$\\rightarrow$", "->").replace("\\rightarrow", "->")
            embed = discord.Embed(
                title=f"🧭 Travel Route: {question[:150]}",
                description=clean_travel.strip(),
                color=0x3498DB
            )
            embed.set_footer(text="World of Warcraft: Forever Companion")
            await interaction.followup.send(embed=embed)
            return

    # 5.5. Gathering Nodes & Farming Routes Check
    gather_info = get_gathering_info(question)
    if gather_info and any(w in q_lower for w in ["gather", "farm", "where", "find", "ore", "herb", "node", "vein", "lotus", "leather", "mining", "herbalism", "skinning"]):
        embed = discord.Embed(
            title=f"⛏️ {gather_info['name']} ({gather_info['type']} • Req {gather_info['skill_req']})",
            color=0x2ECC71
        )
        embed.description = (
            f"• **Yield:** {gather_info['item']}\n"
            f"• **Best Zones:** {gather_info['zones']}\n"
            f"• **Optimal Route:** {gather_info['route']}\n"
            f"💡 *Tip:* {gather_info['tip']}"
        )
        embed.set_footer(text="World of Warcraft: Forever Companion")
        await interaction.followup.send(embed=embed)
        return

    # 5.6. Profession Guide & Leveling Check
    prof_info = get_profession_info(question)
    if prof_info and any(w in q_lower for w in ["profession", "professions", "leveling", "guide", "brackets", "craft", "train", "trainer", "pair", "synergy", "perks", "specialization"]):
        embed = discord.Embed(
            title=f"🛠️ {prof_info['name']} Guide ({prof_info['type']})",
            color=0xE67E22
        )
        embed.description = (
            f"• **Best Pairing:** {prof_info['gathering_pair']}\n"
            f"• **Overview:** {prof_info['description']}\n"
            f"• **Key Crafts:** {prof_info['key_crafts']}\n\n"
            f"**1–300 Leveling Brackets:**\n{prof_info['leveling_brackets']}\n\n"
            f"💡 *Tip:* {prof_info['tip']}"
        )
        embed.set_footer(text="World of Warcraft: Forever Companion")
        await interaction.followup.send(embed=embed)
        return

    # 5.7. Class Build & Spec Check
    if any(w in q_lower for w in ["build", "spec", "talents", "rotation", "stat priority"]):
        for cls in ["warrior", "mage", "rogue", "priest", "warlock", "hunter", "druid", "paladin", "shaman"]:
            if cls in q_lower:
                b = get_class_build(cls, question)
                if b:
                    embed = discord.Embed(
                        title=f"🌳 {b['class']} — {b['spec']} ({b['points']})",
                        color=0x1ABC9C
                    )
                    embed.description = (
                        f"• **Role:** {b['role']}\n"
                        f"• **Stat Priority:** {b['stat_priority']}\n"
                        f"• **Rotation:** {b['rotation']}\n"
                        f"• **Key Milestones:** {b['milestones']}\n"
                        f"💡 *Tip:* {b['tip']}"
                    )
                    embed.set_footer(text="World of Warcraft: Forever Companion")
                    await interaction.followup.send(embed=embed)
                    return

    # 5.8. Raid Boss Strategy Check
    rb = get_raid_boss_info(question)
    if rb and any(w in q_lower for w in ["boss", "raid", "tactics", "strategy", "mechanics", "how to kill", "wipe", "geddon", "vaelastrasz", "chromaggus", "nefarian", "c'thun", "patchwerk"]):
        embed = discord.Embed(
            title=f"⚔️ {rb['name']} ({rb['raid']})",
            color=0xE74C3C
        )
        embed.description = f"{rb['key_mechanics']}\n\n💡 *Tip:* {rb['tip']}"
        embed.set_footer(text="World of Warcraft: Forever Companion")
        await interaction.followup.send(embed=embed)
        return

    # 5.9. World Buff Check
    wb = get_world_buff_info(question)
    if wb and any(w in q_lower for w in ["world buff", "buff", "onyxia", "rend", "warchief", "songflower", "zandalar", "tribute", "dmt", "sayge", "dmf"]):
        embed = discord.Embed(
            title=f"✨ {wb['name']}",
            color=0xF1C40F
        )
        embed.description = (
            f"• **Source & Turn-In:** {wb['source']}\n"
            f"• **Effect:** {wb['effect']}\n"
            f"• **Cooldown / Timer:** {wb['cooldown']}\n"
            f"💡 *Tip:* {wb['tip']}"
        )
        embed.set_footer(text="World of Warcraft: Forever Companion")
        await interaction.followup.send(embed=embed)
        return

    # 5.10. Reputation Check
    rep = get_reputation_info(question)
    if rep and any(w in q_lower for w in ["rep", "reputation", "timbermaw", "argent dawn", "thorium", "hydraxian", "cenarion", "zandalar", "furbolg", "scourgestone"]):
        embed = discord.Embed(
            title=f"🛡️ {rep['name']} Guide",
            color=0x3498DB
        )
        embed.description = (
            f"• **Location:** {rep['location']}\n"
            f"• **Farming Loop & Turn-Ins:** {rep['farm_loop']}\n\n"
            f"**Key Rewards:**\n{rep['rewards']}\n\n"
            f"💡 *Tip:* {rep['tip']}"
        )
        embed.set_footer(text="World of Warcraft: Forever Companion")
        await interaction.followup.send(embed=embed)
        return

    # 5.11. Macro Builder & Template Check
    m_info = get_macro_info(question)
    if m_info and any(w in q_lower for w in ["macro", "#showtooltip", "/cast", "mouseover", "startattack", "stance dance", "weaponswap"]):
        embed = discord.Embed(
            title=f"📋 WoW Macro: {m_info['title']}",
            color=0x3498DB
        )
        embed.description = (
            f"**Description:** {m_info['description']}\n\n"
            f"```lua\n{m_info['code']}\n```\n"
            f"• **Characters:** {len(m_info['code'])} / 255\n"
            f"💡 *Tip:* {m_info['instructions']}"
        )
        embed.set_footer(text="World of Warcraft: Forever Companion • Click 'Copy' above & paste into /macro in WoW")
        await interaction.followup.send(embed=embed)
        return

    # 5.12. PvP System & Honor Decay Check
    pvp_data = get_pvp_info(question)
    if pvp_data and any(re.search(r'\b' + re.escape(w) + r'\b', q_lower) for w in ["pvp", "honor", "decay", "rank 14", "r14", "wsg", "arathi", "alterac", "ab", "av", "high warlord", "grand marshal"]):
        embed = discord.Embed(title=f"⚔️ {pvp_data['title']}", color=0xC0392B)
        embed.description = f"{pvp_data['description']}\n\n💡 *Tip:* {pvp_data.get('tip', '')}"
        embed.set_footer(text="World of Warcraft: Forever Companion • PvP Honor System")
        await interaction.followup.send(embed=embed)
        return

    # 5.13. Dungeon Keys Check
    dk_info = get_dungeon_key_info(question)
    if dk_info and any(w in q_lower for w in ["key", "keys", "lockpick", "shadowforge", "skeleton key", "city key", "scarlet key", "crescent key", "celebras", "workshop key"]):
        embed = discord.Embed(
            title=f"🗝️ {dk_info['name']} ({dk_info['dungeon']})",
            color=0xE67E22
        )
        embed.description = (
            f"• **Source:** {dk_info['source']}\n"
            f"• **Unlocks:** {dk_info['unlocks']}\n\n"
            f"**Quest Steps:**\n{dk_info['steps']}\n\n"
            f"💡 *Tip:* {dk_info['tip']}"
        )
        embed.set_footer(text="World of Warcraft: Forever Companion")
        await interaction.followup.send(embed=embed)
        return

    # 5.14. Race Mechanics & Traits Check
    race_info = get_racial_info(question)
    if race_info and any(w in q_lower for w in ["race", "racial", "traits", "skyborne", "human", "dwarf", "gnome", "night elf", "orc", "undead", "tauren", "troll", "hardiness", "wotf", "stoneform", "shadowmeld"]):
        faction_color = 0x2980B9 if race_info["faction"] == "Alliance" else 0xC0392B
        embed = discord.Embed(
            title=f"🛡️ {race_info['race']} ({race_info['faction']}) Racial Traits",
            color=faction_color
        )
        embed.description = (
            f"{race_info['traits']}\n\n"
            f"**Meta & Mechanics:**\n{race_info['meta']}\n\n"
            f"💡 *Tip:* {race_info['tip']}"
        )
        embed.set_footer(text="World of Warcraft: Forever Companion • Race Mechanics")
        await interaction.followup.send(embed=embed)
        return

    # 5.15. BiS List Check
    if any(w in q_lower for w in ["bis", "best in slot", "pre-raid", "preraid", "pre raid"]):
        for cls in ["warrior", "rogue", "mage", "priest", "warlock", "hunter", "druid", "paladin", "shaman"]:
            if cls in q_lower:
                b = get_bis_list(cls, question)
                if b:
                    embed = discord.Embed(
                        title=f"💎 {b['class']} — {b['spec']} ({b['phase']})",
                        color=0x9B59B6
                    )
                    embed.description = f"{b['gear']}\n\n💡 *Hit & Stat Summary:* {b['hit_summary']}"
                    embed.set_footer(text="World of Warcraft: Forever Companion • Best-in-Slot")
                    await interaction.followup.send(embed=embed)
                    return

    # 5.16. Gold Farming Check
    if any(w in q_lower for w in ["gold farm", "make gold", "g/hr", "gold per hour", "farm gold", "jump run"]):
        gf = get_gold_farm_info(question)
        if gf:
            embed = discord.Embed(
                title=f"🪙 {gf['title']}",
                color=0xF1C40F
            )
            embed.description = (
                f"• **Estimated Yield:** **{gf['g_per_hour']}**\n"
                f"• **Recommended Classes:** {gf['classes']}\n\n"
                f"**Execution Strategy:**\n{gf['strategy']}\n\n"
                f"💡 *Tip:* {gf['tip']}"
            )
            embed.set_footer(text="World of Warcraft: Forever Companion • Gold Making")
            await interaction.followup.send(embed=embed)
            return

    # 5.17. World Events & Timers Check
    if any(w in q_lower for w in ["gurubashi", "arena chest", "darkmoon faire", "dmf", "fishing contest", "fishing extravaganza", "next chest"]):
        we = get_world_events_info(question)
        g = we["gurubashi"]
        f_ev = we["fishing"]
        d = we["dmf"]
        embed = discord.Embed(title="⏰ World Events & Timers Directory", color=0xF39C12)
        embed.description = (
            f"**⚔️ Gurubashi Arena Chest:**\n{g['time_remaining']}\n\n"
            f"**🎣 STV Fishing Extravaganza:**\n{f_ev['time_remaining']}\n\n"
            f"**🎪 Darkmoon Faire (DMF):**\n• Setup Location: **{d['current_location']}**\n• {d['buff_tip']}"
        )
        embed.set_footer(text="World of Warcraft: Forever Companion • Events & Timers")
        await interaction.followup.send(embed=embed)
        return

    # 5.18. Raid Comp & Synergy Check
    if any(w in q_lower for w in ["raid comp", "buff synergy", "missing buffs", "comp check", "roster check"]):
        res = analyze_raid_comp(question)
        counts = res["counts"]
        breakdown = (
            f"**Roster ({res['total_players']} Players):** "
            f"{counts['warrior']} Warr • {counts['rogue']} Rog • {counts['mage']} Mage • {counts['warlock']} Lock • "
            f"{counts['priest']} Priest • {counts['druid']} Druid • {counts['hunter']} Hunt • {counts['shaman']} Sham • {counts['paladin']} Pal"
        )
        covered_str = "\n".join(res["covered"][:8]) if res["covered"] else "No major buffs covered."
        missing_str = "\n".join(res["missing"]) if res["missing"] else "✨ All critical raid debuffs and utility covered!"
        embed = discord.Embed(
            title="🛡️ Raid Composition & Synergy Analysis",
            description=f"{breakdown}\n\n**Covered Buffs & Synergies:**\n{covered_str}\n\n**Missing Synergies & Risks:**\n{missing_str}",
            color=0x2ECC71 if not res["missing"] else 0xE67E22
        )
        embed.set_footer(text="World of Warcraft: Forever Companion • Raid Synergy")
        await interaction.followup.send(embed=embed)
        return

    # 5.19. Resets & Lockouts Check
    if any(w in q_lower for w in ["lockout", "lockouts", "raid reset", "weekly reset", "onyxia reset", "zg reset", "resets"]):
        res = get_raid_lockouts()
        embed = discord.Embed(
            title="⏳ World of Warcraft Raid & World Resets",
            color=0x3498DB
        )
        embed.description = (
            f"**🗓️ Weekly Raid Lockout:** {res['weekly']}\n"
            f"**🐉 Onyxia's Lair (5-Day):** {res['onyxia']}\n"
            f"**🌴 Zul'Gurub & AQ20 (3-Day):** {res['zg']}\n"
            f"**☀️ Daily Reset:** {res['daily']}\n\n"
            f"💡 *Raid IDs bind upon killing the first boss.*"
        )
        embed.set_footer(text="World of Warcraft: Forever Companion • Raid Lockouts")
        await interaction.followup.send(embed=embed)
        return

    # 5.20. Twink Gear Check
    if any(w in q_lower for w in ["twink", "twinking", "bracket 19", "bracket 29", "bracket 39"]):
        bracket = "19"
        if "29" in q_lower:
            bracket = "29"
        elif "39" in q_lower:
            bracket = "39"
        tw = get_twink_info(bracket)
        if tw:
            embed = discord.Embed(
                title=f"⚔️ Twink Guide: {tw['bracket']}",
                color=0xE67E22
            )
            embed.description = (
                f"*{tw['overview']}*\n\n"
                f"**🗡️ Top Weapons:**\n{tw['weapons']}\n\n"
                f"**🛡️ BiS Armor:**\n{tw['armor']}\n\n"
                f"**✨ Enchants:**\n{tw['enchants']}"
            )
            embed.set_footer(text="World of Warcraft: Forever Companion • Twink Metas")
            await interaction.followup.send(embed=embed)
            return

    # 5.21. Speedrun Routes Check
    if any(w in q_lower for w in ["speedlevel", "leveling route", "speedrun route", "quest route", "death warp"]):
        range_key = "10-20"
        if "20-30" in q_lower or "20 to 30" in q_lower or "25" in q_lower:
            range_key = "20-30"
        elif "30-40" in q_lower or "30 to 40" in q_lower or "35" in q_lower:
            range_key = "30-40"
        rt = get_leveling_route(range_key)
        if rt:
            embed = discord.Embed(
                title=f"🗺️ Speedrun Quest Route: {rt['range']}",
                color=0x2ECC71
            )
            embed.description = f"**🦁 Alliance:**\n{rt['alliance']}\n\n**⚡ Horde:**\n{rt['horde']}\n\n{rt['skip_tip']}"
            embed.set_footer(text="World of Warcraft: Forever Companion • Speedleveling")
            await interaction.followup.send(embed=embed)
            return

    # 5.22. Addon Recommendations Check
    if any(w in q_lower for w in ["addon", "addons", "questie", "threatclassic", "swing timer", "leatrix", "plater", "itemrack"]):
        ad = get_addon_info(question)
        if ad:
            embed = discord.Embed(
                title=f"🧩 Addon Guide: {ad['name']} ({ad['category']})",
                color=0x1ABC9C
            )
            embed.description = f"**Purpose:**\n{ad['purpose']}\n\n⚙️ **Configuration:**\n{ad['config']}"
            embed.set_footer(text="World of Warcraft: Forever Companion • Addon Directory")
            await interaction.followup.send(embed=embed)
            return

    # 5.23. Resistance & Mitigation Check
    if any(w in q_lower for w in ["fire resist", "nature resist", "frost resist", "shadow resist", "resist cap", "resistance cap", "how much fr", "how much nr"]):
        school = "fire"
        if "nature" in q_lower or "nr" in q_lower:
            school = "nature"
        elif "frost" in q_lower:
            school = "frost"
        elif "shadow" in q_lower or "sr" in q_lower:
            school = "shadow"
        r = calculate_resistance_mitigation(school, current_val=0)
        embed = discord.Embed(
            title=f"🛡️ {r['school']} Mitigation Guide",
            description=(
                f"• **Hard Cap:** **{r['hard_cap']}** (75% Average Resisted Damage vs Lvl 63 Bosses)\n"
                f"• **Soft Cap:** **{r['soft_cap']}** (Recommended for off-tanks / soakers)\n\n"
                f"🎯 **Key Encounters:**\n{r['encounters']}\n\n"
                f"✨ **Key Buffs:**\n{r['buffs']}"
            ),
            color=0xF39C12
        )
        embed.set_footer(text="World of Warcraft: Forever Companion • Resistance Mechanics")
        await interaction.followup.send(embed=embed)
        return

    # 5.24. 1v1 PvP Duel Matchup Check
    if any(w in q_lower for w in ["duel", "1v1", "matchup"]) and any(c in q_lower for c in ["rogue", "mage", "warrior", "priest", "warlock", "hunter", "shaman", "paladin", "druid"]):
        classes_found = [c for c in ["rogue", "mage", "warrior", "priest", "warlock", "hunter", "shaman", "paladin", "druid"] if c in q_lower]
        c1 = classes_found[0] if len(classes_found) > 0 else "warrior"
        c2 = classes_found[1] if len(classes_found) > 1 else "mage"
        m = get_duel_matchup(c1, c2)
        embed = discord.Embed(
            title=f"⚔️ 1v1 PvP: {m['title']}",
            description=f"⚖️ **Odds:** **{m['favorability']}**\n\n🎯 **Deadzone:**\n{m['deadzone_analysis']}\n\n🔄 **Cooldowns:**\n{m['cooldown_trades']}",
            color=0xE67E22
        )
        embed.set_footer(text="World of Warcraft: Forever Companion • PvP Duel Simulator")
        await interaction.followup.send(embed=embed)
        return

    # 5.25. Talent Trees & Calculator Check
    if any(w in q_lower for w in ["talent", "talents", "spec tree", "talent tree", "talent code"]):
        classes_found = [c for c in ["warrior", "mage", "rogue", "priest", "warlock", "hunter", "shaman", "paladin", "druid"] if c in q_lower]
        if classes_found:
            t = get_talent_build(classes_found[0])
            if t:
                embed = discord.Embed(
                    title=f"🔮 Talent Tree: {t['class']} {t['spec']}",
                    description=f"{t['tree_display']}\n\n⭐ **Capstones:**\n{t['capstones']}\n\n📈 **Priority:**\n{t['priority_order']}",
                    color=0x9B59B6
                )
                embed.set_footer(text="World of Warcraft: Forever Companion • Talents")
                await interaction.followup.send(embed=embed)
                return



    # 6. Database Quick Checks: Quests, Vendors, Items, Flightpaths, Mobs, Dungeons
    if any(w in q_lower for w in ["quest", "mankrik", "turn in", "objective"]):
        quests, _ = db.search_quests(question, limit=1)
        if quests:
            q = quests[0]
            embed = discord.Embed(
                title=f"📜 {q['title']} (Lvl {q['quest_level']})",
                description=f"**Zone:** {q['zone']} • **Giver:** {q['start_npc']}" + (f" `({q['start_location']})`" if q["start_location"] else "") + f"\n**Objective:** {q['objectives']}\n**Rewards:** {q['rewards']}",
                color=0xF1C40F
            )
            embed.set_footer(text="World of Warcraft: Forever Companion")
            await interaction.followup.send(embed=embed)
            return

    items, _ = db.search_items(question, limit=1)
    if items:
        it = items[0]
        embed = discord.Embed(
            title=f"⚔️ {it['name']} ({it['quality']} • iLvl {it['item_level']})",
            description=f"**Slot:** {it['slot']} • **Type:** {it['item_type']} • **Req:** Lvl {it['req_level']}\n**Stats:** {it['stats']}\n**Source:** {it['source']}",
            color=QUALITY_COLORS.get(it["quality"], 0xFFFFFF)
        )
        embed.set_footer(text="World of Warcraft: Forever Companion")
        await interaction.followup.send(embed=embed)
        return

    mobs, _ = db.search_creatures(question, limit=1)
    if mobs:
        m = mobs[0]
        lines = [f"**Location:** {m['zone']}" + (f" `({m['location_details']})`" if m.get("location_details") else "")]
        if m.get("loot"):
            loot_items = [f"{d['name']} ({d['drop_chance']}%)" for d in m["loot"][:3]]
            lines.append(f"**Notable Loot:** {', '.join(loot_items)}")
        embed = discord.Embed(
            title=f"💀 {m['name']} ({m['classification']})",
            description="\n".join(lines),
            color=0xE74C3C
        )
        embed.set_footer(text="World of Warcraft: Forever Companion")
        await interaction.followup.send(embed=embed)
        return

    # 7. General Gemini Intelligence
    general_prompt = f"""
    You are Foreverbot, an ultra-concise World of Warcraft: Forever (Classic+) companion.
    A player is asking: "{question}".
    Give an ultra-condensed, highly relevant answer (maximum 2-3 bullet points).
    Strict rules:
    - Include exact coordinates, levels, and drop rates if applicable.
    - Zero conversational fluff, greetings, or sign-offs. Alt-tab friendly.
    - Never use LaTeX math notation (e.g. do NOT use $\\rightarrow$, use simple text '->').
    """
    response_text = await query_gemini_text(general_prompt)
    if response_text:
        clean_text = response_text.replace("$\\rightarrow$", "->").replace("\\rightarrow", "->")
        embed = discord.Embed(
            title=f"❓ {question[:200]}",
            description=clean_text[:2000],
            color=0x9B59B6
        )
        embed.set_footer(text="World of Warcraft: Forever Companion")
        await interaction.followup.send(embed=embed)
        return

    # Clean fallback if all else fails
    embed = discord.Embed(
        title=f"❓ '{question}'",
        description=(
            "I couldn't find a direct match. Try one of these quick commands:\n"
            "• `/map Westfall` — Zone coordinates, hubs & flight masters\n"
            "• `/dungeons 42` — Dungeons for your level\n"
            "• `/item Ironfoe` — Item stats & source\n"
            "• `/quest Mankrik` — Quest guide & coords\n"
            "• `/flightpath Westfall` — Flight master coords\n"
            "• `/vendor Bronze Tube` — Vendor location & price"
        ),
        color=0x9B59B6
    )
    embed.set_footer(text="World of Warcraft: Forever Companion")
    await interaction.followup.send(embed=embed)


def start_health_server():
    """Starts a lightweight HTTP health check server if PORT is defined (for Render / Railway / Fly.io)."""
    port_str = os.environ.get("PORT")
    if not port_str:
        return
    try:
        from http.server import HTTPServer, BaseHTTPRequestHandler
        import threading

        class HealthHandler(BaseHTTPRequestHandler):
            def do_GET(self):
                self.send_response(200)
                self.send_header("Content-type", "text/plain")
                self.end_headers()
                self.wfile.write(b"Foreverbot is live and healthy!\n")

            def log_message(self, format, *args):
                pass

        port = int(port_str)
        server = HTTPServer(("0.0.0.0", port), HealthHandler)
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        print(f"Healthcheck HTTP server running on port {port} (Cloud Service Live)")
    except Exception as e:
        print(f"Health server note: {e}")


if __name__ == "__main__":
    if not TOKEN or TOKEN == "YOUR_DISCORD_BOT_TOKEN_HERE":
        print("Error: DISCORD_BOT_TOKEN is missing in .env file.")
        print("Please copy .env.example to .env and insert your bot token.")
    else:
        start_health_server()
        bot.run(TOKEN)
