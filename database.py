"""WoW: Forever Database Engine with Fuzzy Search, Typo-Tolerance, Dungeons System, and Conversational Pro-Tips."""

import sqlite3
import os
import re
import difflib
from typing import List, Dict, Any, Optional, Tuple

DB_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "wow_forever.db")
USER_DB_PATH = os.environ.get("USER_DB_PATH", os.path.join(os.path.dirname(os.path.abspath(__file__)), "user_data.db"))

STOP_WORDS = {
    "where", "what", "who", "when", "why", "how", "is", "are", "was", "were",
    "the", "a", "an", "in", "on", "at", "to", "for", "from", "of", "with",
    "by", "near", "closest", "nearest", "find", "get", "locate", "can", "i",
    "you", "flightpath", "flight", "path", "paths", "master", "masters", "npc",
    "vendor", "vendors", "sell", "sells", "buy", "buys", "item", "items",
    "quest", "quests", "mob", "mobs", "boss", "bosses", "drop", "drops",
    "tell", "me", "about", "looking", "want", "need", "show", "give", "dungeon",
    "dungeons", "instance", "instances", "level", "lvl"
}

ZONE_ALIASES = {
    "elwynn": "Elwynn Forest",
    "elwyn": "Elwynn Forest",
    "stormwind": "Stormwind City",
    "sw": "Stormwind City",
    "westfall": "Westfall",
    "westfal": "Westfall",
    "redridge": "Redridge Mountains",
    "duskwood": "Duskwood",
    "loch modan": "Loch Modan",
    "wetlands": "Wetlands",
    "hillsbrad": "Hillsbrad Foothills",
    "arathi": "Arathi Highlands",
    "hinterlands": "The Hinterlands",
    "stv": "Stranglethorn Vale",
    "stranglethorn": "Stranglethorn Vale",
    "booty bay": "Booty Bay",
    "bootybay": "Booty Bay",
    "barrens": "The Barrens",
    "crossroads": "The Crossroads",
    "durotar": "Durotar",
    "mulgore": "Mulgore",
    "orgrimmar": "Orgrimmar",
    "org": "Orgrimmar",
    "thunder bluff": "Thunder Bluff",
    "tb": "Thunder Bluff",
    "undercity": "Undercity",
    "uc": "Undercity",
    "ironforge": "Ironforge",
    "if": "Ironforge",
    "ashenvale": "Ashenvale",
    "darkshore": "Darkshore",
    "teldrassil": "Teldrassil",
    "darnassus": "Rut'theran Village",
    "stonetalon": "Stonetalon Mountains",
    "desolace": "Desolace",
    "feralas": "Feralas",
    "dustwallow": "Dustwallow Marsh",
    "theramore": "Theramore Isle",
    "thousand needles": "Thousand Needles",
    "tanaris": "Tanaris",
    "gadgetzan": "Gadgetzan",
    "un'goro": "Un'Goro Crater",
    "ungoro": "Un'Goro Crater",
    "silithus": "Silithus",
    "winterspring": "Winterspring",
    "everlook": "Everlook",
    "felwood": "Felwood",
    "moonglade": "Moonglade",
    "hyjal": "Mount Hyjal",
    "mount hyjal": "Mount Hyjal",
    "zephras": "Zephras Isle",
    "zephras isle": "Zephras Isle",
    "riverglades": "The Riverglades",
    "gilneas": "Silverpine Forest",
    "zf": "Zul'Farrak",
    "zulfarrak": "Zul'Farrak",
    "brd": "Blackrock Depths",
    "ubrs": "Upper Blackrock Spire",
    "lbrs": "Lower Blackrock Spire",
    "dm": "The Deadmines",
    "deadmines": "The Deadmines",
    "vc": "The Deadmines",
    "wc": "Wailing Caverns",
    "sfk": "Shadowfang Keep",
    "sm": "Scarlet Monastery",
    "sm cath": "Scarlet Monastery: Cathedral",
    "sm cathedral": "Scarlet Monastery: Cathedral",
    "cathedral": "Scarlet Monastery: Cathedral",
    "cath": "Scarlet Monastery: Cathedral",
    "sm arm": "Scarlet Monastery: Armory",
    "sm armory": "Scarlet Monastery: Armory",
    "armory": "Scarlet Monastery: Armory",
    "sm lib": "Scarlet Monastery: Library",
    "sm library": "Scarlet Monastery: Library",
    "library": "Scarlet Monastery: Library",
    "sm gy": "Scarlet Monastery: Graveyard",
    "sm graveyard": "Scarlet Monastery: Graveyard",
    "graveyard": "Scarlet Monastery: Graveyard",
    "rfd": "Razorfen Downs",
    "rfk": "Razorfen Kraul",
    "bfd": "Blackfathom Deeps",
    "mara": "Maraudon",
    "maraudon": "Maraudon",
    "st": "Sunken Temple",
    "sunken temple": "Sunken Temple",
    "strat": "Stratholme",
    "scholo": "Scholomance",
    "dire maul": "Dire Maul",
    "mc": "Molten Core",
    "bwl": "Blackwing Lair",
    "rfc": "Ragefire Chasm",
    "gnomer": "Gnomeregan",
    "gnomeregan": "Gnomeregan",
    "stockade": "The Stockade",
    "stockades": "The Stockade",
    "stocks": "The Stockade",
    "roots": "Roots of Nordrassil",
    "crypts": "Karazhan Crypts",
    "citadel": "Sunken Citadel",
    "stillglade": "Grove of the Stillglade",
    "hateforge": "Hateforge Quarry",
    "rift": "The Temporal Rift",
    "scar": "The Verdant Scar",
    "ulda": "Uldaman",
    "uldaman": "Uldaman",
    "hall of thanes": "Hall of Thanes",
    "hall of the thanes": "Hall of Thanes",
    "thanes": "Hall of Thanes",
    "ruins of lordaeron": "Ruins of Lordaeron",
    "lordaeron": "Ruins of Lordaeron",
    "excavation site": "Excavation Site",
    "excavation": "Excavation Site",
    "city of dalaran": "City of Dalaran",
    "dalaran": "City of Dalaran",
    "drowned city": "The Drowned City",
    "the drowned city": "The Drowned City",
    "krol'dok": "Krol'dok Stronghold",
    "kroldok": "Krol'dok Stronghold",
    "krol'dok stronghold": "Krol'dok Stronghold",
    "alcaz": "Alcaz Island Prison",
    "alcaz island": "Alcaz Island Prison",
    "alcaz island prison": "Alcaz Island Prison",
    "blackmaw": "Blackmaw Hold",
    "blackmaw hold": "Blackmaw Hold",
    "shaper": "Shaper's Terrace",
    "shapers terrace": "Shaper's Terrace",
    "shaper's terrace": "Shaper's Terrace",
    "grim guzzler": "Blackrock Depths",
    "guzzler": "Blackrock Depths",
    "lyceum": "Blackrock Depths",
    "the lyceum": "Blackrock Depths",
    "black forge": "Blackrock Depths",
    "shadowforge": "Blackrock Depths",
    "shadowforge city": "Blackrock Depths",
    "ring of law": "Blackrock Depths",
    "imperial seat": "Blackrock Depths",
    "the seven": "Blackrock Depths",
    "thaurissan": "Blackrock Depths",
    "ironfoe": "Blackrock Depths",
    "pyramid": "Zul'Farrak",
    "antusul": "Zul'Farrak",
    "gahzrilla": "Zul'Farrak",
    "tribute": "Dire Maul",
    "tribute run": "Dire Maul",
    "slaughter square": "Stratholme",
    "baron run": "Stratholme",
    "dead side": "Stratholme",
    "live side": "Stratholme",
    "rivendare": "Stratholme",
    "balnazzar": "Stratholme",
    "upside down sinners": "Karazhan Crypts",
    "drakkisath": "Upper Blackrock Spire",
    "rend": "Upper Blackrock Spire",
    "rend blackhand": "Upper Blackrock Spire",
    "van cleef": "The Deadmines",
    "vancleef": "The Deadmines",
    "edwin van cleef": "The Deadmines",
    "arugal": "Shadowfang Keep",
    "thermaplugg": "Gnomeregan",
    "archaedas": "Uldaman",
    "princess theradras": "Maraudon",
    "theradras": "Maraudon",
    "darkmaster gandling": "Scholomance",
    "gandling": "Scholomance",
    "temple of atal'hakkar": "Sunken Temple",
    "atal'hakkar": "Sunken Temple",
    "hakkar": "Sunken Temple",
    "erikus": "Sunken Temple",
    "eranikus": "Sunken Temple",
    "shade of eranikus": "Sunken Temple",
    "jammal'an": "Sunken Temple",
    "roots of nordrassil": "Roots of Nordrassil",
    "nordrassil": "Roots of Nordrassil",
    "hyjal dungeon": "Roots of Nordrassil",
    "sunken citadel": "Sunken Citadel",
    "zephras dungeon": "Sunken Citadel",
    "grove of the stillglade": "Grove of the Stillglade",
    "hateforge quarry": "Hateforge Quarry",
    "temporal rift": "The Temporal Rift",
    "the temporal rift": "The Temporal Rift",
    "verdant scar": "The Verdant Scar",
    "the verdant scar": "The Verdant Scar",
    "ony": "Onyxia's Lair",
    "onyxia": "Onyxia's Lair",
    "onyxia's lair": "Onyxia's Lair",
    "zg": "Zul'Gurub",
    "zul'gurub": "Zul'Gurub",
    "zulgurub": "Zul'Gurub",
    "aq20": "Ruins of Ahn'Qiraj",
    "ruins of ahn'qiraj": "Ruins of Ahn'Qiraj",
    "aq40": "Temple of Ahn'Qiraj",
    "temple of ahn'qiraj": "Temple of Ahn'Qiraj",
    "aq": "Temple of Ahn'Qiraj",
    "ahn'qiraj": "Temple of Ahn'Qiraj",
    "naxx": "Naxxramas",
    "naxxramas": "Naxxramas"
}

ITEM_AUTOCOMPLETE_ALIASES = {
    "woolcloth": "Wool Cloth",
    "linencloth": "Linen Cloth",
    "silkcloth": "Silk Cloth",
    "mageweavecloth": "Mageweave Cloth",
    "runecloth": "Runecloth",
    "felcloth": "Felcloth",
    "mooncloth": "Mooncloth",
    "tf": "Thunderfury, Blessed Blade of the Windseeker",
    "thunderfury": "Thunderfury, Blessed Blade of the Windseeker",
    "thudner": "Thunderfury, Blessed Blade of the Windseeker",
    "hand of rag": "Sulfuras, Hand of Ragnaros",
    "rag": "Sulfuras, Hand of Ragnaros",
    "sulfuras": "Sulfuras, Hand of Ragnaros",
    "hoj": "Hand of Justice",
    "fap": "Free Action Potion",
    "lap": "Living Action Potion",
    "sgc": "Savage Gladiator Chain",
    "edgies": "Edgemaster's Handguards",
    "edgemasters": "Edgemaster's Handguards",
    "dft": "Drake Fang Talisman",
    "bre": "Bonereaver's Edge",
    "cts": "Chromatically Tempered Sword",
    "cht": "Core Hound Tooth",
    "bb": "Brutality Blade",
    "mcp": "Manual Crowd Pummeler",
    "pummeler": "Manual Crowd Pummeler",
    "rejuv": "Rejuvenating Gem",
    "rejuv gem": "Rejuvenating Gem",
    "tear": "Neltharion's Tear",
    "nelth tear": "Neltharion's Tear",
    "crusader": "Formula: Enchant Weapon - Crusader",
    "mongoose": "Elixir of the Mongoose",
    "lotus": "Black Lotus",
    "gfpp": "Greater Fire Protection Potion",
    "gnpp": "Greater Nature Protection Potion",
    "gfrpp": "Greater Frost Protection Potion",
    "gfrostpp": "Greater Frost Protection Potion",
    "gspp": "Greater Shadow Protection Potion",
    "gapp": "Greater Arcane Protection Potion",
    "titans": "Flask of the Titans",
    "flask of titans": "Flask of the Titans",
    "supreme power": "Flask of Supreme Power",
    "distilled wisdom": "Flask of Distilled Wisdom",
    "mom": "Might of Menethil",
    "ashbringer": "Corrupted Ashbringer",
    "kots": "Kiss of the Spider",
    "viskag": "Vis'kag the Bloodletter",
    "lokamir": "Lok'amir il Romathis",
    "rhok": "Rhok'delar, Longbow of the Ancient Keepers",
    "rhokdelar": "Rhok'delar, Longbow of the Ancient Keepers",
    "lokdelar": "Lok'delar, Stave of the Ancient Keepers",
    "skull": "Skull of Impending Doom",
    "agm": "Arena Grand Master",
    "cloudkeeper": "Cloudkeeper Legplates",
    "cloudkeepers": "Cloudkeeper Legplates",
    "lip": "Limited Immunity Potion",
    "sapper": "Goblin Sapper Charge",
    "sappers": "Goblin Sapper Charge",
    "dynamite": "Dense Dynamite",
    "grenade": "Iron Grenade",
    "iron grenade": "Iron Grenade",
    "holy water": "Stratholme Holy Water",
    "truestrike": "Truestrike Shoulders",
    "devilsaur": "Devilsaur Gauntlets",
    "bloodvine": "Bloodvine Vest",
    "wolfshead": "Wolfshead Helm",
    "warden": "Warden Staff",
    "tuf": "The Unstoppable Force",
    "unstoppable force": "The Unstoppable Force",
    "immovable object": "The Immovable Object",
    "don julio": "Don Julio's Band",
    "blackhands": "Blackhand's Breadth",
    "blackhand": "Blackhand's Breadth",
    "eye of the beast": "Eye of the Beast",
    "swarmguard": "Badge of the Swarmguard",
    "slayers crest": "The Slayer's Crest",
    "slayer": "The Slayer's Crest",
    "onyxia tooth": "Onyxia Tooth Pendant",
    "prestors": "Prestor's Talisman of Conquery",
    "barbed choker": "Barbed Choker",
    "dark edge": "Dark Edge of Insanity",
    "shadowflame": "Staff of the Shadow Flame",
    "ashkandi": "Ashkandi, Greatsword of the Brotherhood",
    "deathbringer": "Deathbringer",
    "spinal reaper": "Spinal Reaper",
    "dal rend": "Dal'Rend's Sacred Charge",
    "dalrends": "Dal'Rend's Sacred Charge",
    "lionheart": "Lionheart Helm",
    "ironfoe": "Ironfoe",
}

FEATURED_ITEM_NAMES = [
    "Thunderfury, Blessed Blade of the Windseeker",
    "Sulfuras, Hand of Ragnaros",
    "Ironfoe",
    "Hand of Justice",
    "Lionheart Helm",
    "Edgemaster's Handguards",
    "Savage Gladiator Chain",
    "Dal'Rend's Sacred Charge",
    "Ravager",
    "Whirlwind Axe",
    "Free Action Potion",
    "Living Action Potion",
    "Tidal Charm",
    "Skull of Impending Doom",
    "Black Lotus",
    "Briarwood Reed",
    "Deathcharger's Reins",
    "Onyxia Hide Backpack",
    "Arcanite Reaper",
    "Bonereaver's Edge",
    "Chromatically Tempered Sword",
    "Ashkandi, Greatsword of the Brotherhood",
    "Perdition's Blade",
    "Core Hound Tooth",
    "Drake Fang Talisman",
    "Neltharion's Tear",
    "Rhok'delar, Longbow of the Ancient Keepers",
]


PREFIX_PATTERN = re.compile(
    r"^(?:what|who|where|when|why|how|which|can|tell|show)\s+(?:are|is|was|were|do|does|did|can|i|me|about)?\s*(?:the|a|an)?\s*(?:bosses|boss|loot|drops|drop|dropping|mobs|mob|entrance|entrances|location|portal|way|route|items|item|dungeon|dungeons|wing|wings|room|rooms|chamber|chambers)?\s*(?:in|of|for|to|at|inside|from)?\s*",
    flags=re.IGNORECASE
)


def clean_query(raw_query: str) -> str:
    """Strips natural language filler words, limits query length, and cleans input."""
    if not raw_query:
        return ""
    # Hard bound on input length to prevent memory/ReDoS exhaustion attacks
    if len(raw_query) > 500:
        raw_query = raw_query[:500]

    text = raw_query.lower().strip()
    stripped_prefix = PREFIX_PATTERN.sub("", text).strip()
    candidate_text = stripped_prefix if stripped_prefix else text

    # Check if candidate_text directly matches ZONE_ALIASES before further word splitting
    cand_clean = re.sub(r"[^\w\s\'-]", " ", candidate_text).strip()
    if cand_clean in ZONE_ALIASES:
        return cand_clean

    text_no_punct = re.sub(r"[^\w\s\'-]", " ", candidate_text)
    words = text_no_punct.split()
    cleaned = [w for w in words if w not in STOP_WORDS]
    result = " ".join(cleaned).strip()
    return result if result else candidate_text


def extract_level_from_text(text: str) -> Optional[int]:
    """Extracts level numbers from queries like 'which dungeon to use at 42', 'dungeons for lvl 45', or '42'."""
    if not text:
        return None

    # 1. Match explicit level indicators: 'at 42', 'lvl 42', 'level 42', 'for 42', 'around 42'
    match = re.search(r"\b(?:lvl|level|at|for|around)\s*(\d{1,3})\b", text, re.IGNORECASE)
    if match:
        val = int(match.group(1))
        if 1 <= val <= 99:
            return val

    # 2. Match standalone number query like '42' or '70'
    stripped = text.strip()
    if stripped.isdigit():
        val = int(stripped)
        if 1 <= val <= 99:
            return val

    # 3. Match any standalone number between 1 and 99
    nums = re.findall(r"\b(\d{1,2})\b", text)
    for n in nums:
        val = int(n)
        if 1 <= val <= 99:
            return val
    return None


def get_connection(db_path: str = DB_PATH, read_only: bool = False) -> sqlite3.Connection:
    """Returns an optimized, concurrency-hardened SQLite connection.

    If read_only=True, opens via SQLite URI mode=ro to enforce immutability at the C level.
    """
    abs_path = os.path.abspath(db_path)
    if read_only and os.path.exists(abs_path):
        uri = f"file:{abs_path}?mode=ro"
        conn = sqlite3.connect(uri, uri=True, timeout=30.0)
    else:
        conn = sqlite3.connect(db_path, timeout=30.0)
    conn.row_factory = sqlite3.Row
    try:
        conn.execute("PRAGMA busy_timeout = 30000;")
        if "user_data" in db_path:
            conn.execute("PRAGMA journal_mode = WAL;")
    except Exception:
        pass
    return conn


def verify_database_integrity(db_path: str = DB_PATH) -> Dict[str, Any]:
    """Runs PRAGMA integrity_check, quick_check, and foreign_key_check to verify zero corruption."""
    if not os.path.exists(db_path):
        return {"status": "error", "error": f"Database file not found: {db_path}"}
    try:
        conn = get_connection(db_path, read_only=True)
        cursor = conn.cursor()
        cursor.execute("PRAGMA integrity_check;")
        integrity_row = cursor.fetchone()
        integrity_status = integrity_row[0] if integrity_row else "unknown"

        cursor.execute("PRAGMA quick_check;")
        quick_row = cursor.fetchone()
        quick_status = quick_row[0] if quick_row else "unknown"

        cursor.execute("PRAGMA foreign_key_check;")
        fk_errors = cursor.fetchall()

        conn.close()
        is_ok = (integrity_status == "ok" and quick_status == "ok")
        return {
            "status": "ok" if is_ok else "corrupted",
            "integrity_check": integrity_status,
            "quick_check": quick_status,
            "foreign_key_violations": len(fk_errors),
            "file_size_bytes": os.path.getsize(db_path)
        }
    except Exception as exc:
        return {"status": "error", "error": str(exc)}



def init_db(db_path: str = DB_PATH) -> None:
    conn = get_connection(db_path)
    cursor = conn.cursor()

    cursor.executescript("""
    CREATE TABLE IF NOT EXISTS items (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        quality TEXT NOT NULL DEFAULT 'Common',
        item_level INTEGER DEFAULT 1,
        req_level INTEGER DEFAULT 1,
        slot TEXT DEFAULT '',
        item_type TEXT DEFAULT '',
        stats TEXT DEFAULT '',
        description TEXT DEFAULT '',
        source TEXT DEFAULT '',
        pro_tip TEXT DEFAULT '',
        is_forever_content INTEGER DEFAULT 0
    );

    CREATE TABLE IF NOT EXISTS quests (
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        req_level INTEGER DEFAULT 1,
        quest_level INTEGER DEFAULT 1,
        faction TEXT DEFAULT 'Both',
        zone TEXT NOT NULL,
        start_npc TEXT DEFAULT '',
        start_location TEXT DEFAULT '',
        end_npc TEXT DEFAULT '',
        end_location TEXT DEFAULT '',
        objectives TEXT DEFAULT '',
        rewards TEXT DEFAULT '',
        pro_tip TEXT DEFAULT '',
        is_forever_content INTEGER DEFAULT 0
    );

    CREATE TABLE IF NOT EXISTS creatures (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        level_min INTEGER DEFAULT 1,
        level_max INTEGER DEFAULT 1,
        classification TEXT DEFAULT 'Normal',
        zone TEXT NOT NULL,
        location_details TEXT DEFAULT '',
        health INTEGER DEFAULT 100,
        strategy_notes TEXT DEFAULT '',
        is_forever_content INTEGER DEFAULT 0
    );

    CREATE TABLE IF NOT EXISTS loot (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        creature_id INTEGER,
        item_id INTEGER,
        drop_chance REAL DEFAULT 0.0,
        FOREIGN KEY (creature_id) REFERENCES creatures(id),
        FOREIGN KEY (item_id) REFERENCES items(id)
    );

    CREATE TABLE IF NOT EXISTS vendors (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        npc_name TEXT NOT NULL,
        zone TEXT NOT NULL,
        coordinates TEXT DEFAULT '',
        item_name TEXT NOT NULL,
        cost_copper INTEGER DEFAULT 0,
        limited_stock INTEGER DEFAULT -1,
        pro_tip TEXT DEFAULT '',
        is_forever_content INTEGER DEFAULT 0
    );

    CREATE TABLE IF NOT EXISTS flightpaths (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        zone TEXT NOT NULL,
        faction TEXT DEFAULT 'Neutral',
        coordinates TEXT DEFAULT '',
        connections TEXT DEFAULT '',
        notes TEXT DEFAULT '',
        is_forever_content INTEGER DEFAULT 0
    );

    -- Dungeons & Raids Table
    CREATE TABLE IF NOT EXISTS dungeons (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        level_min INTEGER NOT NULL,
        level_max INTEGER NOT NULL,
        recommended_level INTEGER NOT NULL,
        zone TEXT NOT NULL,
        faction TEXT DEFAULT 'Both', -- Alliance, Horde, Both
        key_bosses TEXT DEFAULT '',
        notable_loot TEXT DEFAULT '',
        entrance_coords TEXT DEFAULT '',
        pro_tip TEXT DEFAULT '',
        is_forever_content INTEGER DEFAULT 0
    );

    CREATE VIRTUAL TABLE IF NOT EXISTS items_fts USING fts5(
        name,
        stats,
        description,
        source,
        pro_tip,
        content='items',
        content_rowid='id'
    );

    CREATE VIRTUAL TABLE IF NOT EXISTS quests_fts USING fts5(
        title,
        zone,
        objectives,
        rewards,
        pro_tip,
        content='quests',
        content_rowid='id'
    );

    CREATE VIRTUAL TABLE IF NOT EXISTS creatures_fts USING fts5(
        name,
        zone,
        classification,
        strategy_notes,
        content='creatures',
        content_rowid='id'
    );

    CREATE VIRTUAL TABLE IF NOT EXISTS dungeons_fts USING fts5(
        name,
        zone,
        key_bosses,
        notable_loot,
        pro_tip,
        content='dungeons',
        content_rowid='id'
    );
    """)

    conn.commit()
    conn.close()


def init_user_db(user_db_path: str = USER_DB_PATH) -> None:
    """Initializes user-specific, mutable data in a separated database to protect user state."""
    conn = get_connection(user_db_path)
    cursor = conn.cursor()

    cursor.executescript("""
    -- User Character Profiles & Armory Table
    CREATE TABLE IF NOT EXISTS user_profiles (
        user_id INTEGER PRIMARY KEY,
        char_name TEXT NOT NULL,
        char_class TEXT NOT NULL,
        char_race TEXT NOT NULL,
        level INTEGER DEFAULT 60,
        spec TEXT DEFAULT '',
        professions TEXT DEFAULT '',
        guild_role TEXT DEFAULT '',
        gear_note TEXT DEFAULT '',
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
    );

    -- Raid Signups & Attendance Table
    CREATE TABLE IF NOT EXISTS raid_signups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_id TEXT NOT NULL,
        event_title TEXT NOT NULL,
        user_id INTEGER NOT NULL,
        user_name TEXT NOT NULL,
        role TEXT NOT NULL,
        class_name TEXT DEFAULT '',
        signed_at TEXT DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(event_id, user_id)
    );

    -- Persistent Raid Events Metadata
    CREATE TABLE IF NOT EXISTS raid_events (
        event_id TEXT PRIMARY KEY,
        message_id INTEGER DEFAULT 0,
        event_title TEXT NOT NULL,
        max_players INTEGER DEFAULT 40,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
    );

    -- AI Usage & Rate Limiting Table
    CREATE TABLE IF NOT EXISTS ai_usage (
        user_id INTEGER NOT NULL,
        day_date TEXT NOT NULL,
        count INTEGER DEFAULT 0,
        PRIMARY KEY(user_id, day_date)
    );

    -- AI Exact-Match Cache Table (Prevents repeat API calls and eliminates costs)
    CREATE TABLE IF NOT EXISTS ai_cache (
        prompt_hash TEXT PRIMARY KEY,
        response_text TEXT NOT NULL,
        created_at INTEGER DEFAULT (strftime('%s', 'now'))
    );

    -- AI Item Enrichments (Keeps static game catalog pristine and uncorrupted)
    CREATE TABLE IF NOT EXISTS ai_item_enrichments (
        item_id INTEGER PRIMARY KEY,
        description TEXT DEFAULT '',
        source TEXT DEFAULT '',
        pro_tip TEXT DEFAULT '',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
    );
    """)

    conn.commit()
    conn.close()


class WoWForeverDB:
    def __init__(self, db_path: str = DB_PATH, user_db_path: Optional[str] = None):
        self.db_path = db_path
        if not os.path.exists(db_path):
            init_db(db_path)
        # Protect user state: isolate mutable user records into user_db_path
        self.user_db_path = user_db_path or (db_path if db_path != DB_PATH else USER_DB_PATH)
        init_user_db(self.user_db_path)
        self._load_name_caches()

    def _load_name_caches(self):
        """Loads names into memory for sub-second fuzzy typo matching."""
        conn = get_connection(self.db_path, read_only=True)
        cursor = conn.cursor()

        cursor.execute("SELECT id, name, quality, slot, item_type, req_level, is_forever_content FROM items")
        self.item_records = [dict(r) for r in cursor.fetchall()]
        self.item_names = [r["name"] for r in self.item_records]
        self.item_records_by_name = {r["name"].lower(): r for r in self.item_records}
        self._alnum_to_name = {re.sub(r"[^\w]", "", r["name"].lower()): r["name"] for r in self.item_records}
        self._item_words = {}
        for r in self.item_records:
            for w in re.sub(r"[^\w\s]", " ", r["name"]).split():
                if len(w) >= 4:
                    self._item_words.setdefault(w.lower(), []).append(r)

        cursor.execute("SELECT title FROM quests")
        self.quest_titles = [r[0] for r in cursor.fetchall()]

        cursor.execute("SELECT name FROM creatures")
        self.creature_names = [r[0] for r in cursor.fetchall()]

        cursor.execute("SELECT name, zone FROM flightpaths")
        fp_rows = cursor.fetchall()
        self.flight_names = list(set([r[0] for r in fp_rows] + [r[1] for r in fp_rows]))

        cursor.execute("SELECT DISTINCT item_name FROM vendors")
        self.vendor_items = [r[0] for r in cursor.fetchall()]

        cursor.execute("SELECT name, zone FROM dungeons")
        dung_rows = cursor.fetchall()
        self.dungeon_names = list(set([r[0] for r in dung_rows] + [r[1] for r in dung_rows]))

        try:
            cursor.execute("SELECT id, name, character_class, spec, rank, is_forever_content FROM spells")
            self.spell_records = [dict(r) for r in cursor.fetchall()]
            self.spell_names = [r["name"] for r in self.spell_records]
        except Exception:
            self.spell_records = []
            self.spell_names = []

        try:
            cursor.execute("SELECT id, set_name, character_class, tier, is_forever_content FROM armor_sets")
            self.armor_set_records = [dict(r) for r in cursor.fetchall()]
            self.armor_set_names = [r["set_name"] for r in self.armor_set_records]
        except Exception:
            self.armor_set_records = []
            self.armor_set_names = []

        try:
            cursor.execute("SELECT id, title, category, points, is_feat_of_strength, is_forever_content FROM achievements")
            self.achievement_records = [dict(r) for r in cursor.fetchall()]
            self.achievement_titles = [r["title"] for r in self.achievement_records]
        except Exception:
            self.achievement_records = []
            self.achievement_titles = []

        conn.close()

    def autocomplete_items(self, current: str, limit: int = 25) -> List[Dict[str, str]]:
        """Provides instant, floating autocomplete choices in Discord as the user types.
        Returns a list of dicts: [{'name': display_label, 'value': item_name}, ...]
        Narrows down with acronyms, normalized search, token matching, and typo tolerance.
        """
        curr_clean = current.strip().lower()

        # 1. Empty query -> return featured iconic items
        if not curr_clean:
            results = []
            seen = set()
            for feat in FEATURED_ITEM_NAMES:
                rec = self.item_records_by_name.get(feat.lower())
                if rec and rec["name"] not in seen:
                    seen.add(rec["name"])
                    results.append(self._format_autocomplete_choice(rec))
                    if len(results) >= limit:
                        break
            if len(results) < limit:
                for rec in self.item_records:
                    if rec["name"] not in seen and rec.get("quality") in ("Legendary", "Epic"):
                        seen.add(rec["name"])
                        results.append(self._format_autocomplete_choice(rec))
                        if len(results) >= limit:
                            break
            return results

        # 2. Check acronym / alias map
        alias_norm = re.sub(r"[^\w\s]", "", curr_clean).strip()
        alias_target = ITEM_AUTOCOMPLETE_ALIASES.get(curr_clean) or ITEM_AUTOCOMPLETE_ALIASES.get(alias_norm)

        # 3. Normalized matching & scoring
        query_alnum = re.sub(r"[^\w]", "", curr_clean)
        query_tokens = [w for w in re.sub(r"[^\w\s]", " ", curr_clean).split() if w]

        scored_matches = []  # list of (priority, item_record)

        for rec in self.item_records:
            name_raw = rec["name"]
            name_lower = name_raw.lower()
            name_alnum = re.sub(r"[^\w]", "", name_lower)
            searchable = f"{name_lower} {rec.get('quality', '').lower()} {rec.get('slot', '').lower()} {rec.get('item_type', '').lower()}"

            # Check if this item is the target of the alias
            if alias_target and (alias_target.lower() in name_lower or name_lower in alias_target.lower()):
                scored_matches.append((0, rec))
                continue

            # Exact prefix of item name (Priority 1)
            if name_lower.startswith(curr_clean) or (query_alnum and name_alnum.startswith(query_alnum)):
                scored_matches.append((1, rec))
                continue

            # Word boundary start in item name (e.g. "sacred" in "Dal'Rend's Sacred Charge") (Priority 2)
            words = name_lower.split()
            if any(w.startswith(curr_clean) for w in words):
                scored_matches.append((2, rec))
                continue

            # Substring in item name (Priority 3)
            if curr_clean in name_lower or (query_alnum and query_alnum in name_alnum):
                scored_matches.append((3, rec))
                continue

            # All query tokens present in name or metadata (e.g. "ironfoe mace", "lionheart plate") (Priority 4)
            if query_tokens and all(tok in searchable for tok in query_tokens):
                scored_matches.append((4, rec))
                continue

            # Any query token matches (Priority 5)
            if len(query_tokens) > 1 and any(len(tok) >= 3 and tok in name_lower for tok in query_tokens):
                scored_matches.append((5, rec))
                continue

        # If few or no matches, try fuzzy matching with difflib
        if len(scored_matches) < 5 and query_alnum and len(query_alnum) >= 3:
            fuzzy_keys = difflib.get_close_matches(query_alnum, list(self._alnum_to_name.keys()), n=5, cutoff=0.55)
            for f_key in fuzzy_keys:
                real_name = self._alnum_to_name[f_key]
                rec = self.item_records_by_name.get(real_name.lower())
                if rec and not any(r[1]["name"] == rec["name"] for r in scored_matches):
                    scored_matches.append((6, rec))

            fuzzy_words = difflib.get_close_matches(query_alnum, list(self._item_words.keys()), n=20, cutoff=0.5)
            for f_w in fuzzy_words:
                for rec in self._item_words[f_w]:
                    if not any(r[1]["name"] == rec["name"] for r in scored_matches):
                        scored_matches.append((6, rec))

        # Sort by priority, then by quality weight, then alphabetically
        QUALITY_WEIGHTS = {"Legendary": 0, "Epic": 1, "Rare": 2, "Uncommon": 3, "Common": 4, "Poor": 5}
        scored_matches.sort(key=lambda x: (
            x[0],
            QUALITY_WEIGHTS.get(x[1].get("quality"), 9),
            x[1]["name"].lower()
        ))

        # Format up to limit items
        results = []
        seen = set()
        for _, rec in scored_matches:
            if rec["name"] not in seen:
                seen.add(rec["name"])
                results.append(self._format_autocomplete_choice(rec))
                if len(results) >= limit:
                    break

        return results

    def _format_autocomplete_choice(self, rec: Dict[str, Any]) -> Dict[str, str]:
        """Formats an item record into a clean Discord Choice label (max 100 chars)."""
        badge = "🌟 " if rec.get("is_forever_content") else ""
        name = rec["name"]

        tags = []
        if rec.get("quality"):
            tags.append(rec["quality"])
        if rec.get("slot") and rec["slot"] not in ["Inventory", "Container"]:
            tags.append(rec["slot"])
        if rec.get("item_type"):
            tags.append(rec["item_type"])

        tag_str = f" [{', '.join(tags)}]" if tags else ""

        display = f"{badge}{name}{tag_str}"
        if len(display) > 100:
            display = f"{badge}{name}"[:100]

        return {
            "name": display[:100],
            "value": name[:100]
        }

    def autocomplete_spells(self, current: str, class_filter: Optional[str] = None, limit: int = 25) -> List[Dict[str, str]]:
        """Instant Discord autocomplete for class spells."""
        curr = (current or "").strip().lower()
        cls_norm = (class_filter or "").strip().lower()

        results = []
        for r in getattr(self, "spell_records", []):
            if cls_norm and cls_norm not in r.get("character_class", "").lower():
                continue
            s_name = r.get("name", "")
            if not curr or curr in s_name.lower():
                badge = "⚡ " if r.get("is_forever_content") else ""
                spec = f" ({r.get('spec')})" if r.get("spec") else ""
                label = f"{badge}{s_name} [{r.get('character_class')}]{spec}"
                results.append({"name": label[:100], "value": s_name[:100]})
                if len(results) >= limit:
                    break
        return results

    def autocomplete_armor_sets(self, current: str, class_filter: Optional[str] = None, limit: int = 25) -> List[Dict[str, str]]:
        """Instant Discord autocomplete for progression armor sets."""
        curr = (current or "").strip().lower()
        cls_norm = (class_filter or "").strip().lower()

        results = []
        for r in getattr(self, "armor_set_records", []):
            if cls_norm and cls_norm not in r.get("character_class", "").lower():
                continue
            s_name = r.get("set_name", "")
            if not curr or curr in s_name.lower():
                badge = "🛡️ " if r.get("is_forever_content") else ""
                label = f"{badge}{s_name} [{r.get('tier')}] ({r.get('character_class')})"
                results.append({"name": label[:100], "value": s_name[:100]})
                if len(results) >= limit:
                    break
        return results

    def autocomplete_achievements(self, current: str, limit: int = 25) -> List[Dict[str, str]]:
        """Instant Discord autocomplete for achievements and Feats of Strength."""
        curr = (current or "").strip().lower()

        results = []
        for r in getattr(self, "achievement_records", []):
            title = r.get("title", "")
            if not curr or curr in title.lower():
                badge = "🏆 " if r.get("is_feat_of_strength") else "⭐ "
                label = f"{badge}{title} [{r.get('category')} • {r.get('points')} pts]"
                results.append({"name": label[:100], "value": title[:100]})
                if len(results) >= limit:
                    break
        return results

    def find_fuzzy_match(self, query: str, candidates: List[str], cutoff: float = 0.78) -> Optional[str]:
        """Finds typo-tolerant match using high-confidence sequence matching without false positives."""
        query_clean = query.strip().lower()
        if not query_clean or len(query_clean) < 3:
            return None

        # Exact match check first
        for c in candidates:
            if c.lower() == query_clean:
                return c

        # Space-stripped exact match (e.g. 'woolcloth' -> 'Wool Cloth', 'whirlwindaxe' -> 'Whirlwind Axe')
        query_nospace = re.sub(r"[^\w]", "", query_clean)
        if query_nospace:
            for c in candidates:
                if re.sub(r"[^\w]", "", c.lower()) == query_nospace:
                    return c

        # High-confidence close matches
        matches = difflib.get_close_matches(query_clean, [c.lower() for c in candidates], n=1, cutoff=cutoff)
        if matches:
            for c in candidates:
                if c.lower() == matches[0]:
                    return c

        # Word-level match with length similarity constraint (prevents 'wands' -> 'badlands')
        best_cand = None
        best_ratio = 0.0

        for cand in candidates:
            cand_words = re.findall(r"\b\w+\b", cand.lower())
            for cw in cand_words:
                if abs(len(cw) - len(query_clean)) <= 2:
                    ratio = difflib.SequenceMatcher(None, query_clean, cw).ratio()
                    if ratio > best_ratio and ratio >= 0.82:
                        best_ratio = ratio
                        best_cand = cand

        return best_cand

    def search_dungeons(self, query: Optional[str] = None, level: Optional[int] = None, limit: int = 5) -> Tuple[List[Dict[str, Any]], Optional[str]]:
        """Search dungeons by level range or name/zone with strict relevance and typo-tolerance."""
        conn = get_connection(self.db_path, read_only=True)
        cursor = conn.cursor()
        did_you_mean = None

        # Check if query contains a level number like 'lvl 45' or 'which dungeon to use at 42'
        if query and not level:
            extracted = extract_level_from_text(query)
            if extracted:
                level = extracted

        # Level-based lookup (e.g. Level 42 or 45)
        if level:
            # Strict level bracket first (only dungeons player is actually eligible for)
            cursor.execute("""
                SELECT * FROM dungeons
                WHERE ? >= level_min AND ? <= level_max
                ORDER BY ABS(recommended_level - ?) ASC, recommended_level ASC
                LIMIT ?
            """, (level, level, level, limit))
            rows = cursor.fetchall()

            # If empty (e.g. level 11 or 12), widen slightly
            if not rows:
                cursor.execute("""
                    SELECT * FROM dungeons
                    WHERE ? >= (level_min - 2) AND ? <= (level_max + 2)
                    ORDER BY ABS(recommended_level - ?) ASC, recommended_level ASC
                    LIMIT ?
                """, (level, level, level, limit))
                rows = cursor.fetchall()

            results = [dict(r) for r in rows]
            conn.close()
            return results, None

        cleaned = clean_query(query) if query else ""
        if not cleaned:
            conn.close()
            return [], None

        if cleaned.lower() == "dm":
            cursor.execute("""
                SELECT * FROM dungeons
                WHERE name LIKE '%Dire Maul%' OR name LIKE '%Deadmines%'
                ORDER BY level_min ASC
                LIMIT ?
            """, (limit,))
            rows = cursor.fetchall()
            conn.close()
            return [dict(r) for r in rows], "Dire Maul & The Deadmines"

        alias_target = ZONE_ALIASES.get(cleaned.lower(), cleaned)
        if alias_target != cleaned:
            did_you_mean = alias_target

        cursor.execute("""
            SELECT * FROM dungeons
            WHERE name LIKE ? OR zone LIKE ? OR key_bosses LIKE ?
            ORDER BY is_forever_content DESC, level_min ASC
            LIMIT ?
        """, (f"%{alias_target}%", f"%{alias_target}%", f"%{alias_target}%", limit))
        rows = cursor.fetchall()

        if not rows and self.dungeon_names and cleaned:
            fuzzy = self.find_fuzzy_match(cleaned, self.dungeon_names)
            if fuzzy:
                did_you_mean = fuzzy
                cursor.execute("""
                    SELECT * FROM dungeons
                    WHERE name LIKE ? OR zone LIKE ?
                    LIMIT ?
                """, (f"%{fuzzy}%", f"%{fuzzy}%", limit))
                rows = cursor.fetchall()

        results = [dict(r) for r in rows]
        conn.close()
        return results, did_you_mean

    def search_items(self, query: str, limit: int = 5) -> Tuple[List[Dict[str, Any]], Optional[str]]:
        cleaned = clean_query(query)
        q_raw = query.strip().lower()
        q_clean = cleaned.lower()
        conn = get_connection(self.db_path, read_only=True)
        cursor = conn.cursor()
        did_you_mean = None
        rows = []

        # 1. Exact Name Match (case-insensitive) - always prioritized if user typed exact item name
        cursor.execute("""
            SELECT * FROM items 
            WHERE lower(name) = ? OR lower(name) = ?
            ORDER BY 
                CASE WHEN lower(name) = ? THEN 0 ELSE 1 END,
                CASE WHEN forever_status = 'live' THEN 0 ELSE 1 END,
                (CASE WHEN (stats IS NOT NULL AND stats != '') OR (description IS NOT NULL AND description != '') OR (source IS NOT NULL AND source != '') THEN 1 ELSE 0 END) DESC,
                is_forever_content DESC,
                quality DESC
        """, (q_raw, q_clean, q_raw))
        rows = cursor.fetchall()

        # 1b. Direct Alias Check (for slang / abbreviations like 'tf', 'hoj', 'fap', 'sgc', etc.)
        if not rows:
            alias_target = ITEM_AUTOCOMPLETE_ALIASES.get(q_raw) or ITEM_AUTOCOMPLETE_ALIASES.get(q_clean)
            if alias_target:
                cursor.execute("""
                    SELECT * FROM items 
                    WHERE name = ? 
                    ORDER BY CASE WHEN forever_status = 'live' THEN 0 ELSE 1 END
                """, (alias_target,))
                rows = cursor.fetchall()

        # 2. Substring search (prioritize name matches over description/stats)
        if not rows:
            cursor.execute("""
                SELECT * FROM items
                WHERE name LIKE ? OR description LIKE ? OR stats LIKE ?
                ORDER BY 
                    CASE 
                        WHEN lower(name) = ? THEN 0
                        WHEN lower(name) LIKE ? THEN 1
                        WHEN lower(name) LIKE ? THEN 2
                        ELSE 3
                    END,
                    CASE WHEN forever_status = 'live' THEN 0 ELSE 1 END,
                    is_forever_content DESC, quality DESC
                LIMIT ?
            """, (f"%{cleaned}%", f"%{cleaned}%", f"%{cleaned}%", q_clean, f"{q_clean}%", f"%{q_clean}%", limit))
            rows = cursor.fetchall()

        # 3. Multi-token AND search (e.g. "dal rend", "hand ragnaros")
        if not rows:
            tokens = [re.sub(r"[^\w]", "", w) for w in q_clean.split()]
            tokens = [t for t in tokens if len(t) >= 2 and t not in STOP_WORDS]
            if len(tokens) >= 2:
                clauses = " AND ".join(["name LIKE ?" for _ in tokens])
                params = [f"%{t}%" for t in tokens] + [limit]
                sql = (
                    "SELECT * FROM items WHERE " + clauses +
                    " ORDER BY CASE WHEN forever_status = 'live' THEN 0 ELSE 1 END, is_forever_content DESC, quality DESC LIMIT ?"
                )
                cursor.execute(sql, params)
                rows = cursor.fetchall()

        # 4. Fuzzy fallback
        if not rows and self.item_names:
            fuzzy = self.find_fuzzy_match(cleaned, self.item_names)
            if fuzzy:
                did_you_mean = fuzzy
                cursor.execute("SELECT * FROM items WHERE name = ?", (fuzzy,))
                rows = cursor.fetchall()

        results = [dict(row) for row in rows]
        conn.close()
        return results, did_you_mean

    def search_quests(self, query: str, limit: int = 5) -> Tuple[List[Dict[str, Any]], Optional[str]]:
        cleaned = clean_query(query)
        q_raw = query.strip().lower()
        q_clean = cleaned.lower()
        conn = get_connection(self.db_path, read_only=True)
        cursor = conn.cursor()
        did_you_mean = None
        rows = []

        # 1. Exact Title Match
        cursor.execute("""
            SELECT * FROM quests 
            WHERE lower(trim(title)) = ? OR lower(title) = ?
            ORDER BY 
                CASE WHEN lower(trim(title)) = ? THEN 0 ELSE 1 END,
                CASE WHEN forever_status = 'live' THEN 0 ELSE 1 END
        """, (q_raw, q_clean, q_raw))
        rows = cursor.fetchall()

        # 2. Substring search with relevance ranking
        if not rows:
            cursor.execute("""
                SELECT * FROM quests
                WHERE title LIKE ? OR zone LIKE ? OR objectives LIKE ?
                ORDER BY 
                    CASE 
                        WHEN lower(title) = ? THEN 0
                        WHEN lower(title) LIKE ? THEN 1
                        WHEN lower(title) LIKE ? THEN 2
                        ELSE 3
                    END,
                    CASE WHEN forever_status = 'live' THEN 0 ELSE 1 END,
                    is_forever_content DESC, quest_level ASC
                LIMIT ?
            """, (f"%{cleaned}%", f"%{cleaned}%", f"%{cleaned}%", q_clean, f"{q_clean}%", f"%{q_clean}%", limit))
            rows = cursor.fetchall()

        # 3. Multi-token AND search (e.g. "fate kingdom", "diplomat missing")
        if not rows:
            tokens = [re.sub(r"[^\w]", "", w) for w in q_clean.split()]
            tokens = [t for t in tokens if len(t) >= 2 and t not in STOP_WORDS]
            if len(tokens) >= 2:
                clauses = " AND ".join(["title LIKE ?" for _ in tokens])
                params = [f"%{t}%" for t in tokens] + [limit]
                sql = (
                    "SELECT * FROM quests WHERE " + clauses +
                    " ORDER BY CASE WHEN forever_status = 'live' THEN 0 ELSE 1 END, is_forever_content DESC, quest_level ASC LIMIT ?"
                )
                cursor.execute(sql, params)
                rows = cursor.fetchall()

        # 4. Fuzzy fallback
        if not rows and self.quest_titles:
            fuzzy = self.find_fuzzy_match(cleaned, self.quest_titles)
            if fuzzy:
                did_you_mean = fuzzy
                cursor.execute("""
                    SELECT * FROM quests 
                    WHERE title = ? 
                    ORDER BY CASE WHEN forever_status = 'live' THEN 0 ELSE 1 END
                """, (fuzzy,))
                rows = cursor.fetchall()

        results = [dict(row) for row in rows]
        conn.close()
        return results, did_you_mean

    def search_creatures(self, query: str, limit: int = 5) -> Tuple[List[Dict[str, Any]], Optional[str]]:
        cleaned = clean_query(query)
        q_raw = query.strip().lower()
        q_clean = cleaned.lower()
        conn = get_connection(self.db_path, read_only=True)
        cursor = conn.cursor()
        did_you_mean = None
        rows = []

        # 1. Exact Name Match
        cursor.execute("""
            SELECT * FROM creatures 
            WHERE lower(trim(name)) = ? OR lower(name) = ?
            ORDER BY 
                CASE WHEN lower(trim(name)) = ? THEN 0 ELSE 1 END,
                CASE WHEN forever_status = 'live' THEN 0 ELSE 1 END
        """, (q_raw, q_clean, q_raw))
        rows = cursor.fetchall()

        # 2. Substring search with relevance ranking
        if not rows:
            cursor.execute("""
                SELECT * FROM creatures
                WHERE name LIKE ? OR zone LIKE ?
                ORDER BY 
                    CASE 
                        WHEN lower(name) = ? THEN 0
                        WHEN lower(name) LIKE ? THEN 1
                        WHEN lower(name) LIKE ? THEN 2
                        ELSE 3
                    END,
                    CASE WHEN forever_status = 'live' THEN 0 ELSE 1 END,
                    is_forever_content DESC, level_max DESC
                LIMIT ?
            """, (f"%{cleaned}%", f"%{cleaned}%", q_clean, f"{q_clean}%", f"%{q_clean}%", limit))
            rows = cursor.fetchall()

        # 3. Multi-token AND search (e.g. "emperor dagran", "baron geddon")
        if not rows:
            tokens = [re.sub(r"[^\w]", "", w) for w in q_clean.split()]
            tokens = [t for t in tokens if len(t) >= 2 and t not in STOP_WORDS]
            if len(tokens) >= 2:
                clauses = " AND ".join(["name LIKE ?" for _ in tokens])
                params = [f"%{t}%" for t in tokens] + [limit]
                sql = (
                    "SELECT * FROM creatures WHERE " + clauses +
                    " ORDER BY CASE WHEN forever_status = 'live' THEN 0 ELSE 1 END, is_forever_content DESC, level_max DESC LIMIT ?"
                )
                cursor.execute(sql, params)
                rows = cursor.fetchall()

        # 4. Fuzzy fallback
        if not rows and self.creature_names:
            fuzzy = self.find_fuzzy_match(cleaned, self.creature_names)
            if fuzzy:
                did_you_mean = fuzzy
                cursor.execute("""
                    SELECT * FROM creatures 
                    WHERE name = ? 
                    ORDER BY CASE WHEN forever_status = 'live' THEN 0 ELSE 1 END
                """, (fuzzy,))
                rows = cursor.fetchall()

        creatures = []
        for row in rows:
            creature = dict(row)
            cursor.execute("""
                SELECT i.name, i.quality, l.drop_chance
                FROM loot l
                JOIN items i ON l.item_id = i.id
                WHERE l.creature_id = ? AND l.drop_chance > 0
                ORDER BY 
                    CASE 
                        WHEN l.drop_chance >= 5.0 THEN 1 
                        WHEN l.drop_chance >= 1.0 THEN 2 
                        ELSE 3 
                    END,
                    (CASE i.quality WHEN 'Legendary' THEN 5 WHEN 'Epic' THEN 4 WHEN 'Rare' THEN 3 WHEN 'Uncommon' THEN 2 ELSE 1 END) DESC,
                    l.drop_chance DESC
                LIMIT 5
            """, (creature["id"],))
            creature["loot"] = [dict(drop) for drop in cursor.fetchall()]
            creatures.append(creature)

        conn.close()
        return creatures, did_you_mean

    def search_vendors(self, item_name: str, limit: int = 5) -> Tuple[List[Dict[str, Any]], Optional[str]]:
        cleaned = clean_query(item_name)
        q_raw = item_name.strip().lower()
        q_clean = cleaned.lower()
        alias_target = ZONE_ALIASES.get(q_clean, cleaned)
        conn = get_connection(self.db_path, read_only=True)
        cursor = conn.cursor()
        did_you_mean = None

        cursor.execute("""
            SELECT * FROM vendors
            WHERE item_name LIKE ? OR zone LIKE ? OR npc_name LIKE ?
               OR item_name LIKE ? OR zone LIKE ? OR npc_name LIKE ?
               OR zone LIKE ?
            ORDER BY 
                CASE
                    WHEN lower(item_name) = ? THEN 0
                    WHEN lower(item_name) LIKE ? THEN 1
                    ELSE 2
                END,
                cost_copper ASC
            LIMIT ?
        """, (
            f"%{cleaned}%", f"%{cleaned}%", f"%{cleaned}%",
            f"%{q_raw}%", f"%{q_raw}%", f"%{q_raw}%",
            f"%{alias_target}%",
            q_clean, f"%{q_clean}%", limit
        ))
        rows = cursor.fetchall()

        if not rows:
            tokens = [re.sub(r"[^\w]", "", w) for w in q_clean.split()]
            tokens = [t for t in tokens if len(t) >= 2 and t not in STOP_WORDS]
            if len(tokens) >= 2:
                clauses = " AND ".join(["(item_name || ' ' || zone || ' ' || npc_name) LIKE ?" for _ in tokens])
                params = [f"%{t}%" for t in tokens] + [limit]
                sql = "SELECT * FROM vendors WHERE " + clauses + " ORDER BY cost_copper ASC LIMIT ?"
                cursor.execute(sql, params)
                rows = cursor.fetchall()

        if not rows and self.vendor_items:
            fuzzy = self.find_fuzzy_match(cleaned, self.vendor_items)
            if fuzzy:
                did_you_mean = fuzzy
                cursor.execute("SELECT * FROM vendors WHERE item_name = ?", (fuzzy,))
                rows = cursor.fetchall()

        results = [dict(row) for row in rows]
        conn.close()
        return results, did_you_mean

    def search_flightpaths(self, query: str, limit: int = 5) -> Tuple[List[Dict[str, Any]], Optional[str]]:
        cleaned = clean_query(query)
        q_raw = query.strip().lower()
        q_clean = cleaned.lower()
        alias_target = ZONE_ALIASES.get(q_clean, cleaned)
        conn = get_connection(self.db_path, read_only=True)
        cursor = conn.cursor()
        did_you_mean = None
        rows = []

        # 1. Exact Name / Zone Match
        cursor.execute("SELECT * FROM flightpaths WHERE lower(name) = ? OR lower(zone) = ? OR lower(name) = ? OR lower(zone) = ?", (q_raw, q_raw, q_clean, q_clean))
        rows = cursor.fetchall()

        # 1b. Transit multi-point query (e.g. "Stormwind to Ironforge" or "Auberdine to Theramore")
        if not rows:
            parts = [p.strip() for p in re.split(r'\bto\b|\b->\b|\band\b', query.lower()) if p.strip()]
            if len(parts) >= 2:
                p1, p2 = parts[0], parts[1]
                cursor.execute("""
                    SELECT * FROM flightpaths
                    WHERE (lower(name) LIKE ? OR lower(zone) LIKE ?)
                      AND (lower(connections) LIKE ? OR lower(name) LIKE ?)
                    LIMIT ?
                """, (f"%{p1}%", f"%{p1}%", f"%{p2}%", f"%{p2}%", limit))
                rows = cursor.fetchall()
                if not rows:
                    cursor.execute("""
                        SELECT * FROM flightpaths
                        WHERE lower(name) LIKE ? OR lower(zone) LIKE ?
                        LIMIT ?
                    """, (f"%{p1}%", f"%{p1}%", limit))
                    rows = cursor.fetchall()

        # 2. Substring search with name & zone prioritized above connections/notes
        if not rows:
            cursor.execute("""
                SELECT * FROM flightpaths
                WHERE name LIKE ? OR zone LIKE ? OR notes LIKE ? OR connections LIKE ?
                ORDER BY 
                    CASE
                        WHEN lower(name) = ? THEN 0
                        WHEN lower(name) LIKE ? THEN 1
                        WHEN lower(zone) = ? THEN 2
                        WHEN lower(zone) LIKE ? THEN 3
                        ELSE 4
                    END,
                    is_forever_content DESC
                LIMIT ?
            """, (f"%{alias_target}%", f"%{alias_target}%", f"%{alias_target}%", f"%{alias_target}%", q_clean, f"%{q_clean}%", q_clean, f"%{q_clean}%", limit))
            rows = cursor.fetchall()

        # 3. Fuzzy fallback
        if not rows and self.flight_names:
            fuzzy = self.find_fuzzy_match(cleaned, self.flight_names)
            if fuzzy:
                did_you_mean = fuzzy
                cursor.execute("""
                    SELECT * FROM flightpaths
                    WHERE name LIKE ? OR zone LIKE ?
                    LIMIT ?
                """, (f"%{fuzzy}%", f"%{fuzzy}%", limit))
                rows = cursor.fetchall()

        results = [dict(row) for row in rows]
        conn.close()
        return results, did_you_mean

    def search_spells(self, query: str, class_filter: Optional[str] = None, limit: int = 5) -> Tuple[List[Dict[str, Any]], Optional[str]]:
        """Searches class spells using FTS5, substring matching, and typo-tolerant fuzzy fallback."""
        raw_q = (query or "").strip().lower()
        cleaned = clean_query(query) if query else ""
        cls_norm = (class_filter or "").strip()
        if not raw_q and not cls_norm:
            return [], None

        conn = get_connection(self.db_path, read_only=True)
        cursor = conn.cursor()
        rows = []
        did_you_mean = None

        # 0. If query is empty, return top spells for class
        if not raw_q and cls_norm:
            cursor.execute("""
                SELECT * FROM spells WHERE lower(character_class) LIKE ?
                ORDER BY is_forever_content DESC, level_req DESC LIMIT ?
            """, (f"%{cls_norm.lower()}%", limit))
            rows = cursor.fetchall()
            conn.close()
            return [dict(r) for r in rows], None

        # 1. Exact or Substring match on raw query
        sql_exact = "SELECT * FROM spells WHERE lower(name) = ? OR lower(name) LIKE ?"
        params: List[Any] = [raw_q, f"%{raw_q}%"]
        if cls_norm:
            sql_exact += " AND lower(character_class) LIKE ?"
            params.append(f"%{cls_norm.lower()}%")
        sql_exact += " ORDER BY is_forever_content DESC, level_req DESC LIMIT ?"
        params.append(limit)
        cursor.execute(sql_exact, params)
        rows = cursor.fetchall()

        # 2. Tokenized FTS5 Search
        if not rows:
            words = [w for w in re.sub(r"[^\w\s]", " ", raw_q).split() if len(w) >= 2]
            if words:
                match_expr = " AND ".join([f'"{w}"*' for w in words])
                try:
                    cursor.execute("""
                        SELECT s.* FROM spells s
                        JOIN spells_fts f ON s.id = f.rowid
                        WHERE spells_fts MATCH ?
                        ORDER BY s.is_forever_content DESC
                        LIMIT ?
                    """, (match_expr, limit))
                    rows = cursor.fetchall()
                except Exception:
                    rows = []

        # 3. Cleaned substring search
        if not rows and cleaned:
            cursor.execute("""
                SELECT * FROM spells
                WHERE name LIKE ? OR description LIKE ? OR forever_tuning LIKE ?
                ORDER BY is_forever_content DESC
                LIMIT ?
            """, (f"%{cleaned}%", f"%{cleaned}%", f"%{cleaned}%", limit))
            rows = cursor.fetchall()

        # 4. Fuzzy fallback
        if not rows and getattr(self, "spell_names", []):
            fuzzy = self.find_fuzzy_match(raw_q, self.spell_names) or (self.find_fuzzy_match(cleaned, self.spell_names) if cleaned else None)
            if fuzzy:
                did_you_mean = fuzzy
                cursor.execute("SELECT * FROM spells WHERE name LIKE ? LIMIT ?", (f"%{fuzzy}%", limit))
                rows = cursor.fetchall()

        results = [dict(row) for row in rows]
        conn.close()
        return results, did_you_mean

    def search_armor_sets(self, query: str, class_filter: Optional[str] = None, limit: int = 5) -> Tuple[List[Dict[str, Any]], Optional[str]]:
        """Searches progression armor sets and set bonuses."""
        raw_q = (query or "").strip().lower()
        cleaned = clean_query(query) if query else ""
        cls_norm = (class_filter or "").strip()
        if not raw_q and not cls_norm:
            return [], None

        conn = get_connection(self.db_path, read_only=True)
        cursor = conn.cursor()
        rows = []
        did_you_mean = None

        if not raw_q and cls_norm:
            cursor.execute("""
                SELECT * FROM armor_sets WHERE lower(character_class) LIKE ?
                ORDER BY is_forever_content DESC LIMIT ?
            """, (f"%{cls_norm.lower()}%", limit))
            rows = cursor.fetchall()
        else:
            # 1. Exact or Substring on set_name, tier, item_names, or source_dungeon
            sql = """
                SELECT * FROM armor_sets
                WHERE lower(set_name) = ? OR lower(set_name) LIKE ? OR tier LIKE ? OR item_names LIKE ? OR source_dungeon LIKE ?
            """
            params = [raw_q, f"%{raw_q}%", f"%{raw_q}%", f"%{raw_q}%", f"%{raw_q}%"]
            if cls_norm:
                sql += " AND lower(character_class) LIKE ?"
                params.append(f"%{cls_norm.lower()}%")
            sql += " ORDER BY is_forever_content DESC LIMIT ?"
            params.append(limit)
            cursor.execute(sql, params)
            rows = cursor.fetchall()

            # 2. Fuzzy fallback
            if not rows and getattr(self, "armor_set_names", []):
                fuzzy = self.find_fuzzy_match(raw_q, self.armor_set_names) or (self.find_fuzzy_match(cleaned, self.armor_set_names) if cleaned else None)
                if fuzzy:
                    did_you_mean = fuzzy
                    cursor.execute("SELECT * FROM armor_sets WHERE set_name LIKE ? LIMIT ?", (f"%{fuzzy}%", limit))
                    rows = cursor.fetchall()

        results = []
        for r in rows:
            d = dict(r)
            if isinstance(d.get("bonuses_json"), str):
                import json
                try:
                    d["bonuses"] = json.loads(d["bonuses_json"])
                except Exception:
                    d["bonuses"] = {}
            results.append(d)
        conn.close()
        return results, did_you_mean

    def search_achievements(self, query: str, limit: int = 5) -> Tuple[List[Dict[str, Any]], Optional[str]]:
        """Searches achievements and Feats of Strength."""
        raw_q = (query or "").strip().lower()
        cleaned = clean_query(query) if query else ""
        if not raw_q:
            return [], None

        conn = get_connection(self.db_path, read_only=True)
        cursor = conn.cursor()
        rows = []
        did_you_mean = None

        # 1. Exact or Substring
        cursor.execute("""
            SELECT * FROM achievements
            WHERE lower(title) = ? OR lower(title) LIKE ? OR category LIKE ? OR description LIKE ? OR reward LIKE ?
            ORDER BY is_feat_of_strength DESC, points DESC
            LIMIT ?
        """, (raw_q, f"%{raw_q}%", f"%{raw_q}%", f"%{raw_q}%", f"%{raw_q}%", limit))
        rows = cursor.fetchall()

        # 2. Fuzzy fallback
        if not rows and getattr(self, "achievement_titles", []):
            fuzzy = self.find_fuzzy_match(raw_q, self.achievement_titles) or (self.find_fuzzy_match(cleaned, self.achievement_titles) if cleaned else None)
            if fuzzy:
                did_you_mean = fuzzy
                cursor.execute("SELECT * FROM achievements WHERE title LIKE ? LIMIT ?", (f"%{fuzzy}%", limit))
                rows = cursor.fetchall()

        results = [dict(row) for row in rows]
        conn.close()
        return results, did_you_mean

    def get_database_stats(self) -> Dict[str, int]:
        conn = get_connection(self.db_path, read_only=True)
        cursor = conn.cursor()
        stats = {}
        static_queries = {
            "items": ("SELECT COUNT(*) FROM items", "SELECT COUNT(*) FROM items WHERE is_forever_content = 1"),
            "quests": ("SELECT COUNT(*) FROM quests", "SELECT COUNT(*) FROM quests WHERE is_forever_content = 1"),
            "creatures": ("SELECT COUNT(*) FROM creatures", "SELECT COUNT(*) FROM creatures WHERE is_forever_content = 1"),
            "vendors": ("SELECT COUNT(*) FROM vendors", "SELECT COUNT(*) FROM vendors WHERE is_forever_content = 1"),
            "flightpaths": ("SELECT COUNT(*) FROM flightpaths", "SELECT COUNT(*) FROM flightpaths WHERE is_forever_content = 1"),
            "dungeons": ("SELECT COUNT(*) FROM dungeons", "SELECT COUNT(*) FROM dungeons WHERE is_forever_content = 1"),
            "spells": ("SELECT COUNT(*) FROM spells", "SELECT COUNT(*) FROM spells WHERE is_forever_content = 1"),
            "armor_sets": ("SELECT COUNT(*) FROM armor_sets", "SELECT COUNT(*) FROM armor_sets WHERE is_forever_content = 1"),
            "achievements": ("SELECT COUNT(*) FROM achievements", "SELECT COUNT(*) FROM achievements WHERE is_forever_content = 1"),
        }
        for table, (q_all, q_for) in static_queries.items():
            try:
                cursor.execute(q_all)
                stats[table] = cursor.fetchone()[0]
                cursor.execute(q_for)
                stats[f"{table}_forever"] = cursor.fetchone()[0]
            except Exception:
                stats[table] = 0
                stats[f"{table}_forever"] = 0
        conn.close()
        return stats

    def get_zone_map(self, zone_query: str) -> Optional[Dict[str, Any]]:
        """Fetches consolidated zone map information including flight paths and dungeons."""
        from knowledge_engine import get_zone_info

        zone_info = get_zone_info(zone_query, ZONE_ALIASES)
        if not zone_info:
            return None

        zname = zone_info["name"]
        conn = get_connection(self.db_path, read_only=True)
        cursor = conn.cursor()

        # Query flight paths in this zone
        cursor.execute("""
            SELECT name, faction, coordinates, connections, is_forever_content
            FROM flightpaths
            WHERE zone LIKE ?
            ORDER BY is_forever_content DESC
        """, (f"%{zname}%",))
        fps = [dict(r) for r in cursor.fetchall()]

        # Query dungeons in this zone
        cursor.execute("""
            SELECT name, level_min, level_max, recommended_level, entrance_coords, is_forever_content
            FROM dungeons
            WHERE zone LIKE ?
            ORDER BY level_min ASC
        """, (f"%{zname}%",))
        dungs = [dict(r) for r in cursor.fetchall()]

        conn.close()

        zone_info["flightpaths"] = fps
        zone_info["dungeons"] = dungs
        return zone_info

    def set_user_profile(
        self, user_id: int, char_name: str, char_class: str, char_race: str,
        level: int = 60, spec: str = "", professions: str = "",
        guild_role: str = "", gear_note: str = ""
    ) -> None:
        """Saves or updates a Discord user's character profile in the isolated user database."""
        # Sanitize & enforce strict length bounds to prevent DB exhaustion attacks
        s_char_name = str(char_name).strip()[:50]
        s_char_class = str(char_class).strip()[:30]
        s_char_race = str(char_race).strip()[:30]
        try:
            s_level = max(1, min(60, int(level)))
        except Exception:
            s_level = 60
        s_spec = str(spec).strip()[:50]
        s_prof = str(professions).strip()[:100]
        s_role = str(guild_role).strip()[:50]
        s_gear = str(gear_note).strip()[:200]

        conn = get_connection(self.user_db_path)
        cursor = conn.cursor()
        cursor.execute("""
            INSERT INTO user_profiles (user_id, char_name, char_class, char_race, level, spec, professions, guild_role, gear_note, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, datetime('now'))
            ON CONFLICT(user_id) DO UPDATE SET
                char_name=excluded.char_name,
                char_class=excluded.char_class,
                char_race=excluded.char_race,
                level=excluded.level,
                spec=excluded.spec,
                professions=excluded.professions,
                guild_role=excluded.guild_role,
                gear_note=excluded.gear_note,
                updated_at=datetime('now')
        """, (user_id, s_char_name, s_char_class, s_char_race, s_level, s_spec, s_prof, s_role, s_gear))
        conn.commit()
        conn.close()

    def get_user_profile(self, user_id: int) -> Optional[Dict[str, Any]]:
        """Retrieves a Discord user's character profile."""
        conn = get_connection(self.user_db_path)
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM user_profiles WHERE user_id = ?", (user_id,))
        row = cursor.fetchone()
        conn.close()
        return dict(row) if row else None

    def get_profile_by_name(self, char_name: str) -> Optional[Dict[str, Any]]:
        """Searches for a character profile by character name."""
        conn = get_connection(self.user_db_path)
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM user_profiles WHERE char_name LIKE ? LIMIT 1", (f"%{char_name}%",))
        row = cursor.fetchone()
        conn.close()
        return dict(row) if row else None

    def delete_user_profile(self, user_id: int) -> bool:
        """Deletes a user's character profile. GDPR/Privacy right to erasure."""
        conn = get_connection(self.user_db_path)
        cursor = conn.cursor()
        cursor.execute("DELETE FROM user_profiles WHERE user_id = ?", (user_id,))
        deleted = cursor.rowcount > 0
        conn.commit()
        conn.close()
        return deleted

    def delete_all_user_data(self, user_id: int) -> Tuple[int, int]:
        """Deletes all data associated with a user (profile, raid signups, AI usage tracking).
        Returns (profiles_deleted, signups_deleted).
        """
        conn = get_connection(self.user_db_path)
        cursor = conn.cursor()
        cursor.execute("DELETE FROM user_profiles WHERE user_id = ?", (user_id,))
        p_count = cursor.rowcount
        cursor.execute("DELETE FROM raid_signups WHERE user_id = ?", (user_id,))
        r_count = cursor.rowcount
        cursor.execute("DELETE FROM ai_usage WHERE user_id = ?", (user_id,))
        conn.commit()
        conn.close()
        return (p_count, r_count)

    def set_raid_event(self, event_id: str, event_title: str, max_players: int = 40, message_id: int = 0) -> None:
        """Saves metadata for a raid event to ensure persistent view button recovery."""
        s_event_id = str(event_id)[:50]
        s_title = str(event_title)[:100]
        try:
            s_max = max(1, min(100, int(max_players)))
        except Exception:
            s_max = 40

        conn = get_connection(self.user_db_path)
        cursor = conn.cursor()
        cursor.execute("""
            INSERT INTO raid_events (event_id, message_id, event_title, max_players, created_at)
            VALUES (?, ?, ?, ?, datetime('now'))
            ON CONFLICT(event_id) DO UPDATE SET
                event_title=excluded.event_title,
                max_players=excluded.max_players,
                message_id=excluded.message_id
        """, (s_event_id, int(message_id or 0), s_title, s_max))
        conn.commit()
        conn.close()

    def get_raid_event(self, event_id: str) -> Optional[Dict[str, Any]]:
        """Retrieves metadata for a persistent raid event."""
        conn = get_connection(self.user_db_path)
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM raid_events WHERE event_id = ?", (str(event_id)[:50],))
        row = cursor.fetchone()
        conn.close()
        return dict(row) if row else None

    def set_raid_signup(
        self, event_id: str, event_title: str, user_id: int, user_name: str, role: str, class_name: str = ""
    ) -> None:
        """Adds or updates a raid signup."""
        s_event_id = str(event_id)[:50]
        s_title = str(event_title)[:100]
        s_user_name = str(user_name)[:40]
        s_role = str(role)[:20]
        s_class = str(class_name)[:20]

        conn = get_connection(self.user_db_path)
        cursor = conn.cursor()
        cursor.execute("""
            INSERT INTO raid_signups (event_id, event_title, user_id, user_name, role, class_name, signed_at)
            VALUES (?, ?, ?, ?, ?, ?, datetime('now'))
            ON CONFLICT(event_id, user_id) DO UPDATE SET
                role=excluded.role,
                class_name=excluded.class_name,
                user_name=excluded.user_name,
                signed_at=datetime('now')
        """, (s_event_id, s_title, int(user_id), s_user_name, s_role, s_class))
        conn.commit()
        conn.close()

    def remove_raid_signup(self, event_id: str, user_id: int) -> None:
        """Removes a user's signup from a raid event."""
        conn = get_connection(self.user_db_path)
        cursor = conn.cursor()
        cursor.execute("DELETE FROM raid_signups WHERE event_id = ? AND user_id = ?", (str(event_id), user_id))
        conn.commit()
        conn.close()

    def get_raid_signups(self, event_id: str) -> List[Dict[str, Any]]:
        """Retrieves all signups for a raid event ordered by role and sign-up time."""
        conn = get_connection(self.user_db_path)
        cursor = conn.cursor()
        cursor.execute("""
            SELECT * FROM raid_signups
            WHERE event_id = ?
            ORDER BY signed_at ASC
        """, (str(event_id),))
        rows = cursor.fetchall()
        conn.close()
        return [dict(r) for r in rows]

    def get_ai_user_count(self, user_id: int, day_date: str) -> int:
        """Gets number of AI calls made by a user on a given UTC date."""
        conn = get_connection(self.user_db_path)
        cursor = conn.cursor()
        cursor.execute("SELECT count FROM ai_usage WHERE user_id = ? AND day_date = ?", (user_id, day_date))
        row = cursor.fetchone()
        conn.close()
        return row[0] if row else 0

    def increment_ai_user_count(self, user_id: int, day_date: str) -> int:
        """Increments and returns the user's daily AI call count."""
        conn = get_connection(self.user_db_path)
        cursor = conn.cursor()
        cursor.execute("""
            INSERT INTO ai_usage (user_id, day_date, count)
            VALUES (?, ?, 1)
            ON CONFLICT(user_id, day_date) DO UPDATE SET count = count + 1
        """, (user_id, day_date))
        conn.commit()
        cursor.execute("SELECT count FROM ai_usage WHERE user_id = ? AND day_date = ?", (user_id, day_date))
        new_count = cursor.fetchone()[0]
        conn.close()
        return new_count

    def get_cached_ai_response(self, prompt_hash: str) -> Optional[str]:
        """Retrieves a cached AI response by prompt SHA-256 hash."""
        conn = get_connection(self.user_db_path)
        cursor = conn.cursor()
        cursor.execute("SELECT response_text FROM ai_cache WHERE prompt_hash = ?", (prompt_hash,))
        row = cursor.fetchone()
        conn.close()
        return row[0] if row else None

    def set_cached_ai_response(self, prompt_hash: str, response_text: str) -> None:
        """Caches an AI response by prompt SHA-256 hash to eliminate redundant API calls."""
        conn = get_connection(self.user_db_path)
        cursor = conn.cursor()
        cursor.execute("""
            INSERT OR REPLACE INTO ai_cache (prompt_hash, response_text, created_at)
            VALUES (?, ?, strftime('%s', 'now'))
        """, (prompt_hash, response_text))
        conn.commit()
        conn.close()

    def get_item_ai_enrichment(self, item_id: int) -> Optional[Dict[str, str]]:
        """Retrieves uncataloged community AI note for an item without modifying wow_forever.db."""
        conn = get_connection(self.user_db_path)
        cursor = conn.cursor()
        cursor.execute("SELECT description, source, pro_tip FROM ai_item_enrichments WHERE item_id = ?", (item_id,))
        row = cursor.fetchone()
        conn.close()
        return dict(row) if row else None

    def set_item_ai_enrichment(self, item_id: int, description: str, source: str, pro_tip: str) -> None:
        """Stores AI enrichment note in user_data.db without touching the static game catalog."""
        conn = get_connection(self.user_db_path)
        cursor = conn.cursor()
        cursor.execute("""
            INSERT OR REPLACE INTO ai_item_enrichments (item_id, description, source, pro_tip, created_at)
            VALUES (?, ?, ?, ?, datetime('now'))
        """, (item_id, description, source, pro_tip))
        conn.commit()
        conn.close()



