#!/usr/bin/env python3
"""Generates an ultra-modern, high-impact PDF Guide for Foreverbot (WoW: Forever Companion).
Designed with a punchy, low-attention-span layout, card grids, stat badges, and realistic examples.
"""

from fpdf import FPDF
import os
import shutil

class ModernWoWPDF(FPDF):
    def __init__(self):
        super().__init__(orientation="P", unit="mm", format="A4")
        self.set_auto_page_break(auto=True, margin=15)

    def header(self):
        # Top banner
        self.set_fill_color(13, 17, 23)  # Deep slate / obsidian
        self.rect(0, 0, 210, 18, "F")

        # Gold accent bar
        self.set_fill_color(241, 196, 15)  # WoW Gold
        self.rect(0, 18, 210, 1.5, "F")

        self.set_xy(10, 4.5)
        self.set_font("Helvetica", "B", 11)
        self.set_text_color(241, 196, 15)
        self.cell(100, 5, "WORLD OF WARCRAFT: FOREVER (CLASSIC+)", ln=False)

        self.set_font("Helvetica", "B", 9)
        self.set_text_color(200, 210, 225)
        self.cell(90, 5, "FOREVERBOT // COMMAND DECK", align="R", ln=True)

    def footer(self):
        self.set_y(-12)
        self.set_font("Helvetica", "I", 8)
        self.set_text_color(140, 145, 155)
        self.cell(0, 8, f"Page {self.page_no()}  |  WoW: Forever Companion Guide  |  Launch: Nov 4, 2026", align="C")

    def section_header(self, title, tag=""):
        self.ln(3)
        self.set_fill_color(22, 27, 34)
        self.rect(10, self.get_y(), 190, 7.5, "F")

        self.set_xy(12, self.get_y() + 1.2)
        self.set_font("Helvetica", "B", 10)
        self.set_text_color(241, 196, 15)
        self.cell(130, 5, title)

        if tag:
            self.set_font("Helvetica", "B", 8)
            self.set_text_color(56, 189, 248)  # Cyan
            self.cell(54, 5, tag, align="R")

        self.ln(8)

    def pill_badge(self, x, y, w, h, text, bg_rgb=(30, 41, 59), text_rgb=(241, 196, 15)):
        self.set_fill_color(*bg_rgb)
        self.rect(x, y, w, h, "F")
        self.set_xy(x, y + 1)
        self.set_font("Helvetica", "B", 7.5)
        self.set_text_color(*text_rgb)
        self.cell(w, h - 2, text, align="C")

    def card(self, x, y, w, h, title, subtitle, bullets, example=""):
        # Card outer border & fill
        self.set_fill_color(248, 250, 252)
        self.set_draw_color(226, 232, 240)
        self.rect(x, y, w, h, "DF")

        # Accent left border strip
        self.set_fill_color(241, 196, 15)
        self.rect(x, y, 2, h, "F")

        # Title
        self.set_xy(x + 5, y + 2.5)
        self.set_font("Helvetica", "B", 9)
        self.set_text_color(15, 23, 42)
        self.cell(w - 10, 4.5, title, ln=True)

        # Subtitle
        if subtitle:
            self.set_xy(x + 5, y + 6.8)
            self.set_font("Helvetica", "I", 7.5)
            self.set_text_color(100, 116, 139)
            self.cell(w - 10, 3.5, subtitle, ln=True)

        # Bullets
        curr_y = y + (10.5 if subtitle else 7.5)
        self.set_font("Helvetica", "", 7.5)
        self.set_text_color(51, 65, 85)
        for b in bullets:
            self.set_xy(x + 5, curr_y)
            self.cell(w - 10, 3.8, f"- {b}", ln=True)
            curr_y += 3.8

        # Example pill box at bottom
        if example:
            self.set_fill_color(237, 242, 247)
            self.rect(x + 4, y + h - 6.5, w - 8, 4.8, "F")
            self.set_xy(x + 5, y + h - 6.2)
            self.set_font("Courier", "B", 7.2)
            self.set_text_color(22, 101, 52)  # Dark green
            self.cell(w - 10, 4.2, f"Try: {example}")


def generate_guide(output_pdf="wow_forever_bot_guide.pdf"):
    pdf = ModernWoWPDF()

    # =========================================================================
    # PAGE 1: HERO, WHAT THIS IS, HOW IT WORKS & FLOATING SEARCH
    # =========================================================================
    pdf.add_page()
    pdf.ln(4)

    # Hero Banner
    pdf.set_fill_color(15, 23, 42)  # Obsidian
    pdf.rect(10, 22, 190, 24, "F")

    pdf.set_xy(14, 25)
    pdf.set_font("Helvetica", "B", 16)
    pdf.set_text_color(255, 255, 255)
    pdf.cell(100, 7, "FOREVERBOT // COMMAND DECK", ln=False)

    pdf.set_font("Helvetica", "B", 8.5)
    pdf.set_text_color(241, 196, 15)
    pdf.cell(82, 7, "[OFFICIAL DISCORD COMPANION]", align="R", ln=True)

    pdf.set_xy(14, 32.5)
    pdf.set_font("Helvetica", "", 8.5)
    pdf.set_text_color(203, 213, 225)
    pdf.cell(180, 5, "The ultimate second-screen co-pilot for World of Warcraft: Forever (Classic+) & Classic Era.", ln=True)

    # Stat Badges
    badge_y = 39.5
    pdf.pill_badge(14, badge_y, 40, 5, "42 SLASH COMMANDS", (30, 41, 59), (56, 189, 248))
    pdf.pill_badge(58, badge_y, 42, 5, "FLOATING AUTOCOMPLETE", (30, 41, 59), (241, 196, 15))
    pdf.pill_badge(104, badge_y, 42, 5, "SUB-MS OFFLINE MATH", (30, 41, 59), (74, 222, 128))
    pdf.pill_badge(150, badge_y, 50, 5, "9 NEW FOREVER DUNGEONS", (30, 41, 59), (248, 113, 113))

    pdf.set_xy(10, 49)

    # Section: What This All Is (3 Core Pillars)
    pdf.section_header("1. WHAT THIS ALL IS (IN 30 SECONDS)", "NO ALT-TABBING")

    card_w = 60.5
    card_h = 32
    # Pillar 1
    pdf.card(
        10, 58, card_w, card_h,
        "Second-Screen Co-Pilot",
        "Keep playing without pausing",
        [
            "Look up gear, drops & coords instantly",
            "Runs on second monitor or phone",
            "Zero lag, zero browser overhead"
        ],
        "/ask where do I find..."
    )
    # Pillar 2
    pdf.card(
        74.5, 58, card_w, card_h,
        "Hardcore Math Engine",
        "100% accurate raid calculations",
        [
            "+5 racial glancing penalty math",
            "Resistance boss curve (315 cap)",
            "GDKP pot & raider split calculator"
        ],
        "/compare w1: Brutality w2: Death"
    )
    # Pillar 3
    pdf.card(
        139.5, 58, card_w, card_h,
        "WoW: Forever Classic+",
        "Day-1 support for Nov 4, 2026",
        [
            "All 9 custom leveling dungeons",
            "Skyborne Elf racial data",
            "Horizontal Level 60 raid sets"
        ],
        "/forever query: Horizontal"
    )

    # Section: How It Works (Step-by-Step Flow)
    pdf.set_xy(10, 93)
    pdf.section_header("2. HOW IT WORKS IN DISCORD", "REAL-TIME GATEWAY")

    flow_h = 24
    step_w = 60.5
    pdf.card(
        10, 102, step_w, flow_h,
        "Step 1: Type / in Discord",
        "Browse 42 verified slash tools",
        [
            "Type /item, /dungeons, or /raid",
            "Full natural language question support"
        ],
        "/dungeons query: 42"
    )
    pdf.card(
        74.5, 102, step_w, flow_h,
        "Step 2: Floating Suggestions",
        "Narrows down as you type",
        [
            "Acronyms (tf, fap, hoj, bre, cts)",
            "Typo tolerant (thudner -> Thunderfury)"
        ],
        "/item query: fap"
    )
    pdf.card(
        139.5, 102, step_w, flow_h,
        "Step 3: Instant Rich Card",
        "Sub-millisecond data delivery",
        [
            "Quality-colored embeds & coords",
            "Offline FTS5 + Gemini AI fallback"
        ],
        "/vendor query: Bronze Tube"
    )

    # Section: Spotlight Features (/item & /compare)
    pdf.set_xy(10, 129)
    pdf.section_header("3. SPOTLIGHT: NEW FLOATING SEARCH & WEAPON MATH", "CORE DEMOS")

    # Spotlight Card 1: /item
    pdf.card(
        10, 138, 92, 48,
        "Real-Time Item Floating Search (/item)",
        "Instant dropdown that narrows down with badges",
        [
            "Featured Picks: Top 25 iconic items show before typing",
            "Multi-word parsing: 'dal rend' matches both swords",
            "Acronyms: 'tf' -> Thunderfury, 'hoj' -> Hand of Justice",
            "Pill Badges: Shows [Epic, 1H, Sword] directly in Discord",
            "152 high-priority Classic + Forever raid items cataloged"
        ],
        "/item query: dal rend"
    )

    # Spotlight Card 2: /compare
    pdf.card(
        108, 138, 92, 48,
        "Weapon Glancing & Racial Math (/compare)",
        "Eliminate debate on weapon upgrades",
        [
            "Glancing Penalty: Calculates Human/Orc +5 skill",
            "Boss Penalty: Drops 35% damage penalty down to 5%",
            "Hit Cap Shift: Reduces yellow hit cap from 9% to 6%",
            "Swing Timers: Normalizes AP burst on 2.6 vs 2.8+ speed",
            "Clear Verdict: Explains whether OH or MH gains advantage"
        ],
        "/compare query: Brutality Blade weapon2: Deathbringer race: Orc"
    )

    # Pro Tip Banner at bottom
    pdf.set_fill_color(240, 253, 244)  # Light green
    pdf.set_draw_color(187, 247, 208)
    pdf.rect(10, 190, 190, 11, "DF")
    pdf.set_xy(13, 192)
    pdf.set_font("Helvetica", "B", 8)
    pdf.set_text_color(22, 101, 52)
    pdf.cell(184, 4, "PRO-TIP: EVERY COMMAND SUPPORTS NATURAL LANGUAGE", ln=True)
    pdf.set_xy(13, 196)
    pdf.set_font("Helvetica", "", 7.5)
    pdf.set_text_color(21, 128, 61)
    pdf.cell(184, 4, "You don't need exact syntax. Try '/dungeons where is thanes' or '/vendor who sells free action potion'!", ln=True)


    # =========================================================================
    # PAGE 2: CORE FEATURE SUITES & PRACTICAL EXAMPLES
    # =========================================================================
    pdf.add_page()
    pdf.ln(4)

    pdf.section_header("4. CORE FEATURE SUITES & READY-TO-USE EXAMPLES", "PRACTICAL PLAYBOOK")

    suite_w = 92
    suite_h = 39

    # Suite A: Raiding & Bosses
    pdf.card(
        10, 27, suite_w, suite_h,
        "Raiding, Wipe Prevention & Tactics",
        "/raid  |  /comp  |  /buffs  |  /consumes",
        [
            "Instant wipe mechanics (Living Bomb, Burning Adrenaline)",
            "40-player comp analyzer: flags missing Sunder/Windfury",
            "World buff cooldowns (Onyxia, Nefarian, Rend, Songflower)",
            "Mandatory flask, elixir & food checklists by class role"
        ],
        "/raid query: Baron Geddon"
    )

    # Suite B: Leveling & Speedruns
    pdf.card(
        108, 27, suite_w, suite_h,
        "Speedleveling, Routes & Twinks",
        "/level  |  /route  |  /twink  |  /gather",
        [
            "1-60 zone progression and class milestone alerts",
            "Optimized leveling routes with death warps and travel skips",
            "Twink Best-in-Slot lists (19, 29, 39, 49) with uncapped enchants",
            "Gathering circuits for Black Lotus, Thorium & Heavy Leather"
        ],
        "/route query: 10-20 faction: Alliance"
    )

    # Suite C: Guild Operations & Loot
    pdf.card(
        10, 69, suite_w, suite_h,
        "Raid Signups, GDKP & Loot Rolling",
        "/signup  |  /roll  |  /gdkp  |  /events",
        [
            "Interactive signup embeds with Tank/Healer/DPS buttons",
            "Live countdown raid loot roller with winner announcement",
            "GDKP calculator: gross pot, 10% cut, tank pot, raider split",
            "World event calendar (Darkmoon Faire, STV Fishing, Gurubashi)"
        ],
        "/gdkp query: 60000 cut: 10 raiders: 40 tanks: 2"
    )

    # Suite D: PvP & Matchups
    pdf.card(
        108, 69, suite_w, suite_h,
        "PvP Ranks, Duels & Battlegrounds",
        "/pvp  |  /duels  |  /macro",
        [
            "Rank 1-14 Honor RP requirements & 20% weekly decay math",
            "1v1 Duel simulator: analyzes deadzone spacing & kite windows",
            "Battleground macro templates (startattack, stance dancing)",
            "Consumable counters (Free Action Potion, Iron Grenades)"
        ],
        "/duels query: Warrior class2: Frost Mage"
    )

    # Suite E: World Navigation & Fast Travel
    pdf.card(
        10, 111, suite_w, suite_h,
        "World Maps, Travel & Dungeon Portals",
        "/dungeons  |  /map  |  /flightpath  |  /keys",
        [
            "Level bracket matching (e.g. '42' -> ZF, Uldaman, Maraudon)",
            "Consolidated zone maps with flight paths & coordinates",
            "Key chains: Shadowforge, Skeleton, Key to City, Crescent",
            "Full flight network across Kalimdor & Eastern Kingdoms"
        ],
        "/dungeons query: 42"
    )

    # Suite F: Audio, Voice & Community
    pdf.card(
        108, 111, suite_w, suite_h,
        "Audio Chimes, Ambience & Trivia",
        "/sound  |  /ambience  |  /trivia  |  /ask",
        [
            "Streams sound effects in voice chat (Level Up, Murloc, Aggro)",
            "Atmospheric background audio (Lion's Pride Tavern, Orgrimmar)",
            "Interactive trivia quiz with multiple-choice buttons",
            "Freeform conversational AI for complex lore & theorycrafting"
        ],
        "/sound query: Level Up"
    )

    # Section: Official 9 WoW: Forever Dungeons
    pdf.set_xy(10, 153)
    pdf.section_header("5. THE 9 OFFICIAL WOW: FOREVER LEVELING DUNGEONS", "CUSTOM CLASSIC+")

    # Table Header
    table_y = 162
    pdf.set_fill_color(30, 41, 59)
    pdf.rect(10, table_y, 190, 6, "F")
    pdf.set_xy(12, table_y + 1)
    pdf.set_font("Helvetica", "B", 7.5)
    pdf.set_text_color(241, 196, 15)
    pdf.cell(50, 4, "DUNGEON NAME", ln=False)
    pdf.cell(24, 4, "LEVELS", ln=False)
    pdf.cell(46, 4, "ZONE LOCATION", ln=False)
    pdf.cell(26, 4, "FACTION", ln=False)
    pdf.cell(44, 4, "NOTABLE BOSSES", ln=True)

    dungeons_data = [
        ("Hall of Thanes", "13 - 18", "Old Ironforge (High Seat)", "Alliance", "Faldrim Anvilmar, Durgen"),
        ("Ruins of Lordaeron", "15 - 20", "Tirisfal Glades (Underbelly)", "Horde", "Necro-Lord Vardas"),
        ("Excavation Site", "24 - 29", "Wetlands (Raptor Ridge)", "Both", "Excavator Prospector"),
        ("City of Dalaran", "28 - 33", "Alterac Mountains (Shield)", "Both", "Archmage Echo"),
        ("The Drowned City", "35 - 40", "Stranglethorn Vale (Coast)", "Both", "High Priestess Mar'gok"),
        ("Krol'dok Stronghold", "40 - 45", "The Riverglades (Marsh)", "Both", "Warlord Krol'jin"),
        ("Alcaz Island Prison", "48 - 53", "Dustwallow Marsh (Isle)", "Both", "Commander Malveaux"),
        ("Blackmaw Hold", "55 - 60", "Azshara (Timbermaw Border)", "Both", "Blackmaw Chieftain"),
        ("Shaper's Terrace", "58 - 60", "Un'Goro Crater (Terrace)", "Both", "Titan Custodian 09")
    ]

    curr_row_y = table_y + 6
    for idx, (name, lvl, zone, fac, boss) in enumerate(dungeons_data):
        bg = (248, 250, 252) if idx % 2 == 0 else (255, 255, 255)
        pdf.set_fill_color(*bg)
        pdf.rect(10, curr_row_y, 190, 4.8, "F")

        pdf.set_xy(12, curr_row_y + 0.6)
        pdf.set_font("Helvetica", "B", 7.2)
        pdf.set_text_color(15, 23, 42)
        pdf.cell(50, 3.8, name, ln=False)

        pdf.set_font("Courier", "B", 7.2)
        pdf.set_text_color(30, 95, 185)
        pdf.cell(24, 3.8, lvl, ln=False)

        pdf.set_font("Helvetica", "", 7.2)
        pdf.set_text_color(71, 85, 105)
        pdf.cell(46, 3.8, zone, ln=False)

        pdf.set_font("Helvetica", "B", 7)
        fac_color = (180, 105, 0) if fac == "Alliance" else ((185, 28, 28) if fac == "Horde" else (15, 118, 110))
        pdf.set_text_color(*fac_color)
        pdf.cell(26, 3.8, fac, ln=False)

        pdf.set_font("Helvetica", "I", 7)
        pdf.set_text_color(100, 116, 139)
        pdf.cell(44, 3.8, boss, ln=True)

        curr_row_y += 4.8


    # =========================================================================
    # PAGE 3: COMPLETE 42-COMMAND RAPID FIRE CHEAT SHEET
    # =========================================================================
    pdf.add_page()
    pdf.ln(4)

    pdf.section_header("6. COMPLETE 42-COMMAND RAPID REFERENCE", "FULL ARSENAL")

    # 2-column layout for 42 commands (21 on left, 21 on right)
    col_w = 93
    row_h = 8.5

    all_commands = [
        # Col 1
        ("01", "/item", "query: Dal'Rend's", "Real-time floating search tooltip stats & drop sources"),
        ("02", "/quest", "query: In Dreams", "Givers, map coords, escort tips, and item rewards"),
        ("03", "/mob", "query: Emperor Dagran", "HP pools, spawn coords, abilities, and drop rates"),
        ("04", "/vendor", "query: Free Action Potion", "NPC merchants, pricing in gold/silver, and restocks"),
        ("05", "/flightpath", "query: Westfall", "Flight masters, coords, and transit connections"),
        ("06", "/map", "query: Duskwood", "Zone map with towns, flight masters & instances"),
        ("07", "/zones", "query: Zephras Isle", "Level ranges, lore & hubs in new Forever zones"),
        ("08", "/dungeons", "query: 42", "Eligible instances for level brackets or acronyms"),
        ("09", "/level", "query: 40", "Level 1-60 zone progression & milestone alerts"),
        ("10", "/gather", "query: Black Lotus", "Ore, herb, and leather nodes and circuit paths"),
        ("11", "/profession", "query: Engineering", "1-300 skill brackets, material counts & perks"),
        ("12", "/build", "query: Mage spec: Frost", "Meta talent specs, stat weights & spell rotations"),
        ("13", "/consumes", "query: Fury Warrior", "Mandatory raid flasks, elixirs, potions & food"),
        ("14", "/buffs", "query: Onyxia", "World buff turn-ins, cooldowns, and raid bonuses"),
        ("15", "/raid", "query: Baron Geddon", "Boss wipe prevention and positioning mechanics"),
        ("16", "/rep", "query: Argent Dawn", "Reputation farming loops, turn-ins & reward tiers"),
        ("17", "/macro", "query: Stance dance", "Copy-pasteable in-game macros with triggers"),
        ("18", "/pvp", "query: Rank 14", "Honor rank math, 20% weekly decay, and BGs"),
        ("19", "/attunement", "query: Blackwing Lair", "Step-by-step questline guides for raid entry"),
        ("20", "/keys", "query: Shadowforge Key", "Key chains, tomb locations, and doors unlocked"),
        ("21", "/race", "query: Human vs Orc", "Racial passives, +5 weapon skill & PvP ratings"),
        # Col 2
        ("22", "/comp", "query: 8 warrior, 6 rogue...", "Roster analyzer checking Sunder, Windfury & CoR"),
        ("23", "/bis", "query: Rogue spec: Swords", "Slot-by-slot Pre-Raid & Phase BiS checklist"),
        ("24", "/farm", "query: DM East jump", "Estimated G/hr, class requirements & solo pulls"),
        ("25", "/events", "query: Darkmoon Faire", "Event calendar, schedules, and Gurubashi chest"),
        ("26", "/gdkp", "query: 60000 cut: 10", "Gross pot, organizer cut, tank pot & payout"),
        ("27", "/roll", "query: Reins seconds: 30", "Interactive raid roll engine with live timer"),
        ("28", "/compare", "query: Brutality weapon2: Death", "Weapon glancing blow math vs Lvl 63 bosses"),
        ("29", "/sound", "query: Level Up", "Plays iconic WoW sound chimes in voice chat"),
        ("30", "/resets", "query: Onyxia", "Live countdowns to weekly, 5-day & 3-day resets"),
        ("31", "/twink", "query: 29 class: Warrior", "Twink BiS gear & uncapped Classic enchants"),
        ("32", "/route", "query: 10-20 faction: Ally", "Speedrun quest routing with death warps & skips"),
        ("33", "/addons", "query: raiding UI", "Recommended UI addons with zero-lag settings"),
        ("34", "/trivia", "query: Raids", "Interactive Discord lore trivia with button UI"),
        ("35", "/profile", "set / view", "Guild character armory tracking spec & gear"),
        ("36", "/resist", "query: Fire current: 150", "Resistance mitigation curve up to 315 hard cap"),
        ("37", "/duels", "query: Warrior class2: Mage", "1v1 matchup analysis: deadzones & CD trading"),
        ("38", "/signup", "query: MC Sunday 7pm", "Interactive raid roster with Tank/Healer buttons"),
        ("39", "/ambience", "query: Lion's Pride", "Streams ambient tavern music in voice chat"),
        ("40", "/talents", "query: Warrior spec: Arms", "ASCII talent tree layouts & leveling point order"),
        ("41", "/forever", "query: Horizontal", "WoW: Forever Classic+ server rules & tier systems"),
        ("42", "/ask", "query: what are pre-raid swords?", "Conversational AI assistant for any WoW question")
    ]

    col1 = all_commands[:21]
    col2 = all_commands[21:]

    start_y = 26
    for i, (num, cmd, eg, desc) in enumerate(col1):
        y_pos = start_y + (i * row_h)

        # Left Column Box
        bg_color = (248, 250, 252) if i % 2 == 0 else (255, 255, 255)
        pdf.set_fill_color(*bg_color)
        pdf.set_draw_color(226, 232, 240)
        pdf.rect(10, y_pos, col_w, row_h - 0.5, "DF")

        pdf.set_xy(11.5, y_pos + 0.8)
        pdf.set_font("Courier", "B", 7.2)
        pdf.set_text_color(30, 95, 185)
        pdf.cell(24, 3.5, f"{num}. {cmd}", ln=False)

        pdf.set_font("Courier", "", 6.8)
        pdf.set_text_color(22, 101, 52)
        pdf.cell(col_w - 26, 3.5, f"[{eg}]", align="R", ln=True)

        pdf.set_xy(11.5, y_pos + 4.2)
        pdf.set_font("Helvetica", "", 6.6)
        pdf.set_text_color(71, 85, 105)
        pdf.cell(col_w - 3, 3.2, desc, ln=True)

    for i, (num, cmd, eg, desc) in enumerate(col2):
        y_pos = start_y + (i * row_h)

        # Right Column Box
        bg_color = (248, 250, 252) if i % 2 == 0 else (255, 255, 255)
        pdf.set_fill_color(*bg_color)
        pdf.set_draw_color(226, 232, 240)
        pdf.rect(107, y_pos, col_w, row_h - 0.5, "DF")

        pdf.set_xy(108.5, y_pos + 0.8)
        pdf.set_font("Courier", "B", 7.2)
        pdf.set_text_color(30, 95, 185)
        pdf.cell(24, 3.5, f"{num}. {cmd}", ln=False)

        pdf.set_font("Courier", "", 6.8)
        pdf.set_text_color(22, 101, 52)
        pdf.cell(col_w - 26, 3.5, f"[{eg}]", align="R", ln=True)

        pdf.set_xy(108.5, y_pos + 4.2)
        pdf.set_font("Helvetica", "", 6.6)
        pdf.set_text_color(71, 85, 105)
        pdf.cell(col_w - 3, 3.2, desc, ln=True)

    # Save PDF
    pdf.output(output_pdf)
    print(f"Modern PDF successfully generated at: {output_pdf}")

    # Also copy to artifacts directory
    artifact_dir = "/home/s1l3nt/.gemini/antigravity/brain/14f2f633-6ca3-4a1c-a167-21a6d54a6ab6"
    if os.path.exists(artifact_dir):
        dest_pdf = os.path.join(artifact_dir, "wow_forever_bot_guide.pdf")
        shutil.copy2(output_pdf, dest_pdf)
        print(f"Copied to artifact directory: {dest_pdf}")

if __name__ == "__main__":
    generate_guide()
