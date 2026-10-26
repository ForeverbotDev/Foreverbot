"""
Generates a landscape presentation slide deck PDF for Foreverbot.
Each slide is a visual card explaining how to use each slash command.
"""

import os
import shutil
from fpdf import FPDF

class PresentationPDF(FPDF):
    def __init__(self):
        super().__init__(orientation="L", unit="mm", format="A4") # 297 x 210 mm
        self.set_auto_page_break(auto=False)

    def draw_slide_background(self, title, category, slide_num, total_slides=12):
        self.add_page()
        # Top banner background
        self.set_fill_color(15, 23, 42) # Slate 900
        self.rect(0, 0, 297, 26, "F")

        # Top Accent line
        self.set_fill_color(245, 158, 11) # Amber 500
        self.rect(0, 25, 297, 1.5, "F")

        # Slide Category pill
        self.set_xy(14, 6)
        self.set_font("Helvetica", "B", 8)
        self.set_text_color(245, 158, 11)
        self.cell(80, 4, category.upper())

        # Slide Title
        self.set_xy(14, 11)
        self.set_font("Helvetica", "B", 14)
        self.set_text_color(255, 255, 255)
        self.cell(180, 8, title)

        # Slide Number
        self.set_xy(240, 10)
        self.set_font("Helvetica", "B", 9)
        self.set_text_color(148, 163, 184)
        self.cell(43, 6, f"SLIDE {slide_num} / {total_slides}", align="R")

        # Bottom footer bar
        self.set_fill_color(241, 245, 249)
        self.rect(0, 198, 297, 12, "F")
        self.set_xy(14, 201)
        self.set_font("Helvetica", "", 7.5)
        self.set_text_color(100, 116, 139)
        self.cell(150, 6, "FOREVERBOT DISCORD COMPANION // COMPLETE SLASH COMMAND HOW-TO GUIDE")
        self.set_xy(200, 201)
        self.cell(83, 6, "Type / in Discord to access any command", align="R")

    def draw_command_card(self, x, y, w, h, cmd_name, params, desc, example, result):
        # Card background & border
        self.set_fill_color(255, 255, 255)
        self.set_draw_color(226, 232, 240)
        self.rect(x, y, w, h, "DF")

        # Left colored indicator bar
        self.set_fill_color(30, 95, 185) # Blue indicator
        self.rect(x, y, 2.5, h, "F")

        # Command name & parameters
        self.set_xy(x + 5, y + 2.5)
        self.set_font("Courier", "B", 10.5)
        self.set_text_color(30, 95, 185)
        self.cell(45, 5, cmd_name)

        if params:
            self.set_font("Helvetica", "I", 7.5)
            self.set_text_color(100, 116, 139)
            self.cell(w - 55, 5, f"Options: {params}", align="R")

        # Description
        self.set_xy(x + 5, y + 8)
        self.set_font("Helvetica", "", 8)
        self.set_text_color(30, 41, 59)
        self.multi_cell(w - 10, 4, desc)

        # Example code block box
        box_y = y + h - 14.5
        self.set_fill_color(248, 250, 252)
        self.set_draw_color(226, 232, 240)
        self.rect(x + 5, box_y, w - 10, 11.5, "DF")

        self.set_xy(x + 7, box_y + 1.2)
        self.set_font("Courier", "B", 7.5)
        self.set_text_color(22, 101, 52) # Dark green
        self.cell(w - 14, 4, f"TRY: {example}")

        self.set_xy(x + 7, box_y + 5.8)
        self.set_font("Helvetica", "", 7.2)
        self.set_text_color(71, 85, 105)
        self.cell(w - 14, 4, f"-> {result}")


def build_presentation():
    pdf = PresentationPDF()

    # SLIDE 1: Title & Quickstart
    pdf.draw_slide_background("Welcome to Foreverbot: How It Works", "QUICKSTART GUIDE", 1)
    
    # 3 Big Getting Started Cards
    card_w = 85
    card_h = 150
    start_y = 36

    # Box 1: The Basics
    pdf.set_fill_color(255, 255, 255)
    pdf.set_draw_color(203, 213, 225)
    pdf.rect(14, start_y, card_w, card_h, "DF")
    pdf.set_fill_color(30, 95, 185)
    pdf.rect(14, start_y, card_w, 8, "F")
    pdf.set_xy(18, start_y + 1.5)
    pdf.set_font("Helvetica", "B", 9)
    pdf.set_text_color(255, 255, 255)
    pdf.cell(card_w - 8, 5, "1. HOW TO ACCESS COMMANDS")

    pdf.set_xy(18, start_y + 12)
    pdf.set_font("Helvetica", "", 8.5)
    pdf.set_text_color(51, 65, 85)
    steps1 = [
        "In any channel where Foreverbot is present,",
        "simply press the slash key (/) on your keyboard.",
        "",
        "Discord displays the interactive command menu.",
        "Click any command or keep typing its name.",
        "",
        "Every command has auto-completing options so you",
        "never have to guess arguments or syntax.",
        "",
        "Works seamlessly on both Desktop and Mobile!"
    ]
    for s in steps1:
        pdf.cell(card_w - 8, 4.5, s)
        pdf.set_xy(18, pdf.get_y() + 4.5)

    # Box 2: Floating Autocomplete
    pdf.set_fill_color(255, 255, 255)
    pdf.rect(106, start_y, card_w, card_h, "DF")
    pdf.set_fill_color(16, 185, 129) # Emerald
    pdf.rect(106, start_y, card_w, 8, "F")
    pdf.set_xy(110, start_y + 1.5)
    pdf.set_font("Helvetica", "B", 9)
    pdf.set_text_color(255, 255, 255)
    pdf.cell(card_w - 8, 5, "2. LIVE FLOATING AUTOCOMPLETE")

    pdf.set_xy(110, start_y + 12)
    pdf.set_font("Helvetica", "", 8.5)
    pdf.set_text_color(51, 65, 85)
    steps2 = [
        "Commands like /item feature real-time narrowing:",
        "",
        "Type common acronyms:",
        "  - 'tf' -> Thunderfury",
        "  - 'hoj' -> Hand of Justice",
        "  - 'fap' -> Free Action Potion",
        "  - 'mcp' -> Manual Crowd Pummeler",
        "",
        "Typo-tolerant matching:",
        "  - 'thudner' -> Thunderfury",
        "  - 'dall rend' -> Dal'Rend's Arms",
        "",
        "Pick from the dropdown for instant guaranteed stats!"
    ]
    for s in steps2:
        pdf.cell(card_w - 8, 4.5, s)
        pdf.set_xy(110, pdf.get_y() + 4.5)

    # Box 3: Plain English Fallback
    pdf.set_fill_color(255, 255, 255)
    pdf.rect(198, start_y, card_w, card_h, "DF")
    pdf.set_fill_color(245, 158, 11) # Amber
    pdf.rect(198, start_y, card_w, 8, "F")
    pdf.set_xy(202, start_y + 1.5)
    pdf.set_font("Helvetica", "B", 9)
    pdf.set_text_color(255, 255, 255)
    pdf.cell(card_w - 8, 5, "3. NATURAL LANGUAGE SEARCH")

    pdf.set_xy(202, start_y + 12)
    pdf.set_font("Helvetica", "", 8.5)
    pdf.set_text_color(51, 65, 85)
    steps3 = [
        "You never need strict database terminology.",
        "",
        "Type questions naturally:",
        "  - /dungeons where is thanes?",
        "  - /vendor who sells free action potion?",
        "  - /gather best circuit for dreamfoil",
        "",
        "If you ever don't know which command to use,",
        "simply type /ask with any question and the",
        "built-in AI assistant will answer immediately!"
    ]
    for s in steps3:
        pdf.cell(card_w - 8, 4.5, s)
        pdf.set_xy(202, pdf.get_y() + 4.5)

    # Helper for 4 cards per slide (2x2 grid)
    # x1=14, x2=152, y1=34, y2=114, w=131, h=74
    def draw_2x2_slide(title, cat, slide_num, c1, c2, c3, c4):
        pdf.draw_slide_background(title, cat, slide_num)
        cards = [c1, c2, c3, c4]
        coords = [(14, 34), (152, 34), (14, 114), (152, 114)]
        w = 131
        h = 74
        for (x, y), (cmd, params, desc, eg, res) in zip(coords, cards):
            pdf.draw_command_card(x, y, w, h, cmd, params, desc, eg, res)

    # SLIDE 2: Gear, Items & Comparisons
    draw_2x2_slide(
        "Gear, Items & Stat Comparison", "CORE COMMANDS", 2,
        ("/item", "query: [name/abbreviation]", "Instant visual tooltip card with item stats, durability, equip effects, boss drop source, and drop percentage.", "/item query: Dal'Rend's", "Shows stats, drop rate from Rend Blackhand & set bonus"),
        ("/compare", "query: [item1] weapon2: [item2] race: [...]", "Side-by-side stat evaluation with glancing blow math (+5 weapon skill vs lvl 63 raid bosses).", "/compare query: Brutality Blade weapon2: Deathbringer", "Shows AP, crit delta, and glancing blow penalty math"),
        ("/bis", "query: [class] spec: [spec]", "Complete slot-by-slot checklist of Pre-Raid BiS or Phase BiS items with dungeon/raid drop locations.", "/bis query: Rogue spec: Swords", "Returns full Head-to-Toe BiS gear list with drop sources"),
        ("/resist", "query: [school] current: [amount] role: [...]", "Calculates magic resistance mitigation curve, average % damage resisted, and points needed to reach cap.", "/resist query: Fire current: 150", "Returns average 37.5% mitigation and points to 315 cap")
    )

    # SLIDE 3: Quests, Keys & Attunements
    draw_2x2_slide(
        "Quests, Keys & Raid Attunements", "PROGRESSION & UNLOCKS", 3,
        ("/quest", "query: [quest name / zone]", "Looks up quest givers, map coordinates, prerequisite chains, step-by-step objectives, and item rewards.", "/quest query: In Dreams", "Gives Taelan Fordring escort guide, coords & rewards"),
        ("/keys", "query: [key name / dungeon]", "Details dungeon key quest chains, drop locations, ghost run triggers, and which doors each key opens.", "/keys query: Shadowforge Key", "Shows Franclorn Forgestone ghost questline in BRD"),
        ("/attunement", "query: [raid name / faction]", "Complete step-by-step quest walkthroughs for Onyxia, Molten Core, BWL, Naxxramas, and Temporal Rift.", "/attunement query: Onyxia Alliance", "Full 16-step Marshal Windsor questline walkthrough"),
        ("/rep", "query: [faction name]", "Reputation farming loops, repeatable turn-ins, and reward tiers from Neutral to Exalted.", "/rep query: Argent Dawn", "Shows Scourgestone turn-ins, Cauldron runs & rewards")
    )

    # SLIDE 4: World Navigation & Travel
    draw_2x2_slide(
        "World Travel & Zone Exploration", "NAVIGATION", 4,
        ("/flightpath", "query: [zone or town name]", "Finds flight master NPC names, exact coordinates, and all direct flight connections for Alliance & Horde.", "/flightpath query: Westfall", "Returns Thor (Sentinel Hill, 56.6, 52.6) and routes"),
        ("/map", "query: [zone name]", "ASCII visual zone overview showing major towns, flight paths, instance portals, and level brackets.", "/map query: Duskwood", "Displays Darkshire hub, Raven Hill, and cemetery spots"),
        ("/zones", "query: [zone name / all]", "Comprehensive information on new, expanded, and custom zones in WoW: Forever (Classic+).", "/zones query: Zephras Isle", "Level 48-55 pirate haven coords, hubs & faction status"),
        ("/dungeons", "query: [level, name, or acronym]", "Finds all eligible dungeons for a specific level bracket, or looks up entrances and wing locations.", "/dungeons query: 42", "Returns Zul'Farrak, Uldaman, and Razorfen Downs")
    )

    # SLIDE 5: Leveling 1-60 & Speedrun Routes
    draw_2x2_slide(
        "Leveling 1-60 & Speedrun Routes", "LEVELING COMPANION", 5,
        ("/level", "query: [1-60 level number]", "Provides a zone roadmap, elite quest warnings, and class milestone alerts (mount at 40, talents at 10).", "/level query: 40", "Alerts 60% mount purchase, Stranglethorn Vale & Badlands"),
        ("/route", "query: [level bracket] faction: [...]", "Speedrun quest routing instructions with death-warps, hearthstone bindings, and optimal quest skips.", "/route query: 10-20 faction: Alliance", "Westfall -> Loch Modan -> Redridge rotation guide"),
        ("/mob", "query: [mob or boss name]", "Spawn coordinates, HP pools, special spell immunities, patrol routes, and verified loot drop tables.", "/mob query: Emperor Dagran Thaurissan", "Ironforge Princess mechanics, avatar phase & drops"),
        ("/rare", "query: [rare mob name / zone]", "Rare elite spawn timers, patrol paths, and unique BoE/BoP drop items.", "/rare query: Broken Tooth", "1.0 attack speed beast spawn coords in Badlands")
    )

    # SLIDE 6: Economy, Gathering & Professions
    draw_2x2_slide(
        "Economy, Gathering & Professions", "ECONOMY & PROFESSIONS", 6,
        ("/vendor", "query: [item or recipe name]", "Locates NPC merchants selling limited supply recipes, reagents, and food with faction and restock times.", "/vendor query: Free Action Potion", "Returns Kor'geld (Horde) and Ulthir (Alliance) coords"),
        ("/gather", "query: [herb, ore, or leather]", "Farming circuits, node spawn densities, and best zones for mining, herbalism, and skinning.", "/gather query: Black Lotus", "Winterspring, Silithus, EPL, and Burning Steppes routes"),
        ("/profession", "query: [profession name]", "1-300 skill leveling brackets, estimated material counts, trainer locations, and unique perks.", "/profession query: Engineering", "Gnomish vs Goblin specialization perks and leveling path"),
        ("/farm", "query: [item, zone, or class]", "Top gold farming hotspots, solo dungeon farming pulls, and estimated Gold-per-Hour yields.", "/farm query: Dire Maul East jump", "Rich Thorium & felcloth solo farm guide for Casters")
    )

    # SLIDE 7: Raiding & Dungeon Cheatsheets
    draw_2x2_slide(
        "Raid Boss Tactics, Consumables & Buffs", "RAIDING ARSENAL", 7,
        ("/raid", "query: [boss or raid name]", "Concise boss mechanic cheatsheet: wipe prevention, positioning, tank swaps, and dispel priorities.", "/raid query: Baron Geddon", "Living Bomb run-out directions, ignite dispel alerts"),
        ("/consumes", "query: [class and role / raid]", "Mandatory and optional consumable checklists: flasks, elixirs, potions, buff foods, and weapon oils.", "/consumes query: Fury Warrior", "Mongoose, Giants, Winterfall Firewater & Jujus list"),
        ("/buffs", "query: [buff or raid name]", "World buff turn-in locations, NPC trigger cooldowns, and raid stat increases (Ony, Rend, DM, ZG).", "/buffs query: Onyxia", "Head of Onyxia rally cry timers and Stormwind/Ogrimmar buffs"),
        ("/resets", "query: [raid or all]", "Live countdowns to weekly raid resets (MC/BWL), 5-day resets (Onyxia), and 3-day resets (ZG).", "/resets query: Onyxia", "Shows exact days/hours until next Onyxia reset")
    )

    # SLIDE 8: Class Builds, Talents & Macros
    draw_2x2_slide(
        "Class Builds, Talents & Optimization", "CLASS MASTERY", 8,
        ("/build", "query: [class] spec: [spec]", "Top PvE and PvP meta talent builds, stat priority weights, and single-target / AoE spell rotations.", "/build query: Mage spec: Frost", "Winter's Chill raid spec, spell hit caps & rotation"),
        ("/talents", "query: [class] spec: [spec]", "Visual ASCII talent tree allocation and step-by-step leveling point investment order.", "/talents query: Warrior spec: Arms", "Displays 31/20/0 Mortal Strike talent point roadmap"),
        ("/race", "query: [race comparison / class]", "Analyzes racial passives, +5 weapon skill impact, and PvP racial ratings (Will of the Forsaken, etc.).", "/race query: Human vs Orc Warrior", "Compares +5 Swords/Maces vs +5 Axes & Blood Fury"),
        ("/macro", "query: [action or class]", "Generates copy-pasteable in-game WoW macros with clean triggers and stance conditionals.", "/macro query: Stance Dance Overpower", "Clean macro switching to Battle Stance and casting Overpower")
    )

    # SLIDE 9: PvP Honor, Twinking & Matchups
    draw_2x2_slide(
        "PvP Honor, Twinking & 1v1 Duels", "PVP & COMPETITIVE", 9,
        ("/pvp", "query: [rank number or topic]", "Honor rank math (1-14), 20% weekly decay calculations, RP breakpoints, and Battleground guides.", "/pvp query: Rank 14", "Requirements, weekly bracket targets, and Grand Marshal weapons"),
        ("/twink", "query: [bracket] character_class: [...]", "Best-in-Slot weapons, armor, and uncapped Classic enchants for 19, 29, 39, and 49 twink brackets.", "/twink query: 29 character_class: Warrior", "Corpsemaker, +100 HP chest, and +9 damage enchants"),
        ("/duels", "query: [class1] class2: [class2]", "1v1 PvP matchup simulator: deadzone management, key cooldown trades, and counter-strategies.", "/duels query: Rogue class2: Frost Mage", "Vanish blink prediction and Ice Block baiting tactics"),
        ("/profile", "query: [set or view]", "Personal character profile saving your class, spec, level, and guild armory status.", "/profile query: view", "Displays your saved character card in Discord")
    )

    # SLIDE 10: Raid Leader & Guild Event Tools
    draw_2x2_slide(
        "Raid Leader & Guild Event Tools", "EVENT & LOOT MANAGEMENT", 10,
        ("/signup", "query: [raid title] max_players: [...]", "Creates an interactive raid roster in Discord with clickable Tank, Healer, DPS, and Bench buttons.", "/signup query: MC Sunday 7pm max_players: 40", "Interactive embed with live roster counter & role slots"),
        ("/comp", "query: [roster list]", "Analyzes your raid comp: checks Sunder Armor, Windfury, Curse of Recklessness, and Tranq Shot coverage.", "/comp query: 8 warriors, 5 rogues, 3 mages...", "Reports buff synergies, missing debuffs, and raid balance"),
        ("/gdkp", "query: [pot] cut: [cut] raiders: [...]", "Calculates gross pot, organizer cut %, tank bonus pot, and exact gold payout per raider.", "/gdkp query: 60000 cut: 10 raiders: 40", "Shows 6,000 organizer cut, 54,000 pot, 1,350 gold/raider"),
        ("/roll", "query: [item name] seconds: [...]", "Interactive raid roll engine with a real-time countdown timer, roll tracking, and winner announcement.", "/roll query: Reins of the Deathcharger seconds: 30", "Live 30s roll button, ties resolution, and winner card")
    )

    # SLIDE 11: Classic+ Lore, Voice & Fun Features
    # 6 items on this slide
    pdf.draw_slide_background("WoW: Forever Features, Voice & Fun", "SERVER & COMMUNITY", 11)
    
    # 6 cards (3x2 grid)
    c_w = 86
    c_h = 74
    c_coords = [
        (14, 34), (105, 34), (196, 34),
        (14, 114), (105, 114), (196, 114)
    ]
    fun_cards = [
        ("/forever", "query: [topic]", "Server overview of WoW: Forever Classic+, horizontal progression, custom tiers & racial balances.", "/forever query: horizontal progression", "Explains itemization philosophy and custom endgame tiers"),
        ("/sound", "query: [sound name]", "Plays iconic Classic WoW sound effects (Level Up, Murloc Aggro, Ready Check) in voice chat.", "/sound query: Level Up", "Streams golden chime into current voice channel"),
        ("/ambience", "query: [tavern/zone]", "Streams relaxing Classic WoW atmospheric music (Lion's Pride, Elwynn Forest, Barrens) in voice.", "/ambience query: Lion's Pride Inn", "Plays warm hearthstone tavern ambience in voice channel"),
        ("/events", "query: [event name]", "Schedules for Darkmoon Faire, Stranglethorn Fishing Extravaganza, and Gurubashi Arena chest timers.", "/events query: Darkmoon Faire", "Next spawn date, Terokkar/Mulgore/Elwynn rotation calendar"),
        ("/trivia", "query: [category]", "Interactive Discord lore trivia mini-game with 4 clickable answer buttons and score tracking.", "/trivia query: Raids", "Spawns 4 multiple-choice buttons for raid mechanic trivia"),
        ("/ask", "query: [natural language]", "Conversational AI assistant trained on Vanilla WoW & Classic+ for any custom question.", "/ask query: what are the best pre-raid swords?", "Direct answer comparing Dal'Rends, Mirah's & Thrash Blade")
    ]
    for (x, y), (cmd, params, desc, eg, res) in zip(c_coords, fun_cards):
        pdf.draw_command_card(x, y, c_w, c_h, cmd, params, desc, eg, res)

    # SLIDE 12: Rapid Cheat Sheet & Summary
    pdf.draw_slide_background("Complete 42-Command Cheat Sheet", "RAPID REFERENCE", 12)
    
    # 3-column table of all 42 commands
    col_width = 86
    row_height = 6.2
    start_y = 32

    all_cmds = [
        ("/item", "Gear stats & drop rates"),
        ("/compare", "Stat delta & glancing math"),
        ("/bis", "Slot-by-slot BiS lists"),
        ("/resist", "Mitigation curve & caps"),
        ("/quest", "Givers, coords & walkthroughs"),
        ("/keys", "Dungeon keys & door unlocks"),
        ("/attunement", "Raid attunement chains"),
        ("/rep", "Reputation farming loops"),
        ("/flightpath", "Flight masters & routes"),
        ("/map", "ASCII zone map & hubs"),
        ("/zones", "New Forever Classic+ zones"),
        ("/dungeons", "Dungeon finder by level"),
        ("/level", "1-60 zone progression"),
        ("/route", "Speedrun leveling paths"),
        # Col 2
        ("/mob", "HP, coords, immunities & loot"),
        ("/rare", "Rare elite spawn timers"),
        ("/vendor", "Limited stock NPC recipes"),
        ("/gather", "Ore/herb farming circuits"),
        ("/profession", "1-300 leveling & perks"),
        ("/farm", "Gold hotspots & solo skips"),
        ("/raid", "Boss wipe prevention guides"),
        ("/consumes", "Mandatory raid buffs/potions"),
        ("/buffs", "World buff turn-ins & timers"),
        ("/resets", "Weekly, Ony & ZG resets"),
        ("/build", "Meta talent specs & rotations"),
        ("/talents", "ASCII trees & leveling points"),
        ("/race", "Racial traits & weapon skills"),
        ("/macro", "Copy-pasteable WoW macros"),
        # Col 3
        ("/pvp", "Honor ranks 1-14 & decay"),
        ("/twink", "19/29/39/49 BiS gear & enchants"),
        ("/duels", "1v1 PvP matchup simulator"),
        ("/profile", "Save/view character card"),
        ("/signup", "Interactive raid roster buttons"),
        ("/comp", "Raid comp & synergy analyzer"),
        ("/gdkp", "Pot splitter & payouts"),
        ("/roll", "Live countdown loot roll engine"),
        ("/addons", "Recommended UI & zero-lag addons"),
        ("/forever", "Classic+ server features"),
        ("/sound", "Plays WoW chimes in voice"),
        ("/ambience", "Streams tavern music in voice"),
        ("/events", "Darkmoon & Gurubashi timers"),
        ("/trivia", "Discord lore trivia mini-game"),
        ("/ask", "Plain-English AI assistant"),
        ("/help", "Displays command directory")
    ]

    col1 = all_cmds[:14]
    col2 = all_cmds[14:28]
    col3 = all_cmds[28:42]

    columns = [(14, col1), (105, col2), (196, col3)]
    for col_x, cmd_list in columns:
        for idx, (c_name, c_desc) in enumerate(cmd_list):
            row_y = start_y + (idx * (row_height + 4.5))
            
            # Row box
            bg = (248, 250, 252) if idx % 2 == 0 else (255, 255, 255)
            pdf.set_fill_color(*bg)
            pdf.set_draw_color(226, 232, 240)
            pdf.rect(col_x, row_y, col_width, row_height + 3.5, "DF")

            # Left command tag
            pdf.set_xy(col_x + 3, row_y + 1.2)
            pdf.set_font("Courier", "B", 8)
            pdf.set_text_color(30, 95, 185)
            pdf.cell(32, 4, c_name)

            # Description
            pdf.set_font("Helvetica", "", 7.2)
            pdf.set_text_color(71, 85, 105)
            pdf.cell(col_width - 36, 4, c_desc, align="R")

            # Command hint
            pdf.set_xy(col_x + 3, row_y + 5.5)
            pdf.set_font("Courier", "", 6.5)
            pdf.set_text_color(22, 101, 52)
            pdf.cell(col_width - 6, 3.2, f"Type {c_name} in Discord")

    # Output
    out_file = "Foreverbot_How_To_Guide.pdf"
    pdf.output(out_file)
    print(f"Presentation PDF successfully built at: {out_file}")

    # Copy to artifacts directory
    artifact_dir = "/home/s1l3nt/.gemini/antigravity/brain/14f2f633-6ca3-4a1c-a167-21a6d54a6ab6"
    if os.path.exists(artifact_dir):
        dest = os.path.join(artifact_dir, "Foreverbot_How_To_Guide.pdf")
        shutil.copy2(out_file, dest)
        print(f"Copied to artifact dir: {dest}")

if __name__ == "__main__":
    build_presentation()
