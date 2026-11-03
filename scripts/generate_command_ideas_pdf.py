"""
Generates a clean, modern, low-attention-span slide deck PDF:
One slide per command, exactly 5 concrete ideas on what to type.
"""

import os
import shutil
from fpdf import FPDF

class CommandIdeasPDF(FPDF):
    def __init__(self):
        super().__init__(orientation="L", unit="mm", format="A4") # 297 x 210 mm
        self.set_auto_page_break(auto=False)

    def draw_command_slide(self, cmd_name, one_liner, ideas, slide_num, total_slides):
        self.add_page()
        
        # Background
        self.set_fill_color(248, 250, 252) # Slate 50
        self.rect(0, 0, 297, 210, "F")

        # Top Banner (Dark Navy)
        self.set_fill_color(15, 23, 42) # Slate 900
        self.rect(0, 0, 297, 36, "F")

        # Amber Accent Bar
        self.set_fill_color(245, 158, 11) # Amber 500
        self.rect(0, 35, 297, 1.5, "F")

        # Tag
        self.set_xy(16, 7)
        self.set_font("Helvetica", "B", 8)
        self.set_text_color(245, 158, 11)
        self.cell(100, 4, "FOREVERBOT // COMMAND CHEATSHEET")

        # Slide Number
        self.set_xy(230, 7)
        self.set_font("Helvetica", "B", 9)
        self.set_text_color(148, 163, 184)
        self.cell(51, 4, f"SLIDE {slide_num} OF {total_slides}", align="R")

        # Command Name (Big & Bold)
        self.set_xy(16, 14)
        self.set_font("Courier", "B", 18)
        self.set_text_color(255, 255, 255)
        self.cell(120, 8, cmd_name)

        # One Liner
        self.set_xy(16, 23)
        self.set_font("Helvetica", "", 10)
        self.set_text_color(203, 213, 225)
        self.cell(240, 6, one_liner)

        # Section Heading
        self.set_xy(16, 42)
        self.set_font("Helvetica", "B", 11)
        self.set_text_color(30, 41, 59)
        self.cell(200, 6, "5 THINGS TO TYPE INTO DISCORD:")

        # 5 Idea Cards
        card_y = 52
        card_h = 24
        card_w = 265
        gap = 5

        for i, (typed_text, explanation) in enumerate(ideas):
            y = card_y + (i * (card_h + gap))
            
            # Card background
            self.set_fill_color(255, 255, 255)
            self.set_draw_color(226, 232, 240)
            self.rect(16, y, card_w, card_h, "DF")

            # Left number pill
            self.set_fill_color(30, 95, 185) # Blue
            self.rect(16, y, 14, card_h, "F")
            self.set_xy(16, y + 7)
            self.set_font("Helvetica", "B", 12)
            self.set_text_color(255, 255, 255)
            self.cell(14, 10, str(i + 1), align="C")

            # Typed command (Green code font)
            self.set_xy(34, y + 4)
            self.set_font("Courier", "B", 11)
            self.set_text_color(22, 101, 52) # Emerald 800
            self.cell(card_w - 40, 6, typed_text)

            # Explanation
            self.set_xy(34, y + 12)
            self.set_font("Helvetica", "", 9)
            self.set_text_color(71, 85, 105) # Slate 600
            self.cell(card_w - 40, 6, f"Result: {explanation}")

        # Footer
        self.set_fill_color(241, 245, 249)
        self.rect(0, 200, 297, 10, "F")
        self.set_xy(16, 202)
        self.set_font("Helvetica", "", 7.5)
        self.set_text_color(100, 116, 139)
        self.cell(150, 6, "Press / in Discord and pick from the floating menu")
        self.set_xy(180, 202)
        self.cell(101, 6, "Foreverbot Co-Pilot for WoW: Forever", align="R")


def build_ideas_deck():
    pdf = CommandIdeasPDF()

    slides_data = [
        (
            "/item",
            "Instantly view any item, weapon, or armor stats, drop rate, and who drops it.",
            [
                ("/item query: dal rend", "Shows stats, drop rate from Rend Blackhand & set bonus with Tribal Guardian"),
                ("/item query: hand of ragnaros", "Sulfuras stats, craft reagents, and Eye of Sulfuras drop rate from Rag"),
                ("/item query: hoj", "Hand of Justice trinket stats and drop rate from General Angerforge in BRD"),
                ("/item query: free action potion", "FAP duration, recipe materials, and craft sell value"),
                ("/item query: thudnerfury", "Typo-tolerant: recognizes Thunderfury and shows chain quest & stats")
            ]
        ),
        (
            "/compare",
            "Compare two weapons or armor pieces side-by-side with stat deltas and glancing math.",
            [
                ("/compare query: brutality blade weapon2: deathbringer", "Side-by-side Attack Power, Crit %, and weapon speed differences"),
                ("/compare query: dal rend charge weapon2: mirah song", "Compares raw weapon DPS, AP bonus vs fast off-hand stats"),
                ("/compare query: hoj weapon2: blackhand breadth", "Compares extra attack proc value vs flat 2% physical crit"),
                ("/compare query: chromatic boots weapon2: bloodmail boots", "Compares BWL BiS plate boots vs Strat pre-raid agility/strength boots"),
                ("/compare query: perdition blade weapon2: core hound tooth", "Compares top dagger choices for Rogues with glancing blow math")
            ]
        ),
        (
            "/bis",
            "Get your exact slot-by-slot Pre-Raid and Phase Best-in-Slot gear checklists.",
            [
                ("/bis query: warrior spec: fury", "Returns complete Pre-Raid BiS list from Lionheart Helm to Battleborn Armbraces"),
                ("/bis query: rogue spec: swords", "Complete Phase 1 BiS list with Shadowcraft, Dal'Rends, and HoJ drops"),
                ("/bis query: mage spec: frost", "Spell damage & hit gear list: Robes of the Archmage, Briarwood Reed, etc."),
                ("/bis query: priest spec: holy", "Healing power and mp5 checklist with drop locations from dungeons"),
                ("/bis query: hunter spec: marksman", "Pre-raid ranged BiS checklist: Truestrike Shoulders, Blackcrow, Devilsaur")
            ]
        ),
        (
            "/raid",
            "Boss wipe prevention, positioning diagrams, dispel alerts, and tank swaps.",
            [
                ("/raid query: baron geddon", "Living Bomb run-out positioning, Ignite Magic dispels, and Inferno phase"),
                ("/raid query: rag", "Submerge timer (3 min), Sons of Flame banish order, and knockback spread"),
                ("/raid query: onyxia", "Phase 2 fireball spread, deep breath safe zones, and whelp room control"),
                ("/raid query: vaelastrasz", "Burning Adrenaline rotation, tank swap positions, and threat ceiling"),
                ("/raid query: chromaggus", "Hour of Bronze sand dispel priorities, breath timers, and color weaknesses")
            ]
        ),
        (
            "/consumes",
            "Mandatory flasks, elixirs, potions, and food buffs for your class on raid night.",
            [
                ("/consumes query: fury warrior", "Flask of the Titans, Elixir of the Mongoose, Winterfall Firewater, Jujus"),
                ("/consumes query: rogue", "Thistle Tea, Mongoose, Elemental Sharpening Stones, Grilled Squid"),
                ("/consumes query: holy paladin", "Flask of Distilled Wisdom, Greater Arcane Elixir, Mana Potion stacks"),
                ("/consumes query: fire mage", "Greater Arcane Elixir, Elixir of Greater Firepower, Nightfin Soup"),
                ("/consumes query: feral tank", "Manual Crowd Pummelers, Elixir of Superior Defense, Dirge's Chops")
            ]
        ),
        (
            "/dungeons",
            "Find eligible dungeons for your level bracket, wing levels, and custom instances.",
            [
                ("/dungeons query: 42", "Eligible level 42 dungeons: Zul'Farrak, Uldaman, Razorfen Downs"),
                ("/dungeons query: sm", "Scarlet Monastery 4-wing level breakdown: Graveyard, Lib, Armory, Cath"),
                ("/dungeons query: brd", "Blackrock Depths level ranges, Prison vs City wings, and Emperor run"),
                ("/dungeons query: dire maul", "DM East, West, and North level requirements and key boss names"),
                ("/dungeons query: thanes", "WoW Forever custom dungeon: level brackets, location & boss guide")
            ]
        ),
        (
            "/flightpath",
            "Find the nearest flight master and connected flight routes for both factions.",
            [
                ("/flightpath query: stv", "Alliance (Booty Bay, Rebel Camp) and Horde (Booty Bay, Grom'gol) coords"),
                ("/flightpath query: feralas", "Feathermoon Stronghold (Alliance) and Camp Mojache (Horde) masters"),
                ("/flightpath query: tanaris", "Gadgetzan flight masters, coords, and connections to Theramore/Brackenwall"),
                ("/flightpath query: badlands", "Kargath flight master (Horde) and nearest Alliance flight master in Loch Modan"),
                ("/flightpath query: hillsbrad", "Southshore (Alliance) and Tarren Mill (Horde) flight master positions")
            ]
        ),
        (
            "/zones",
            "Check level brackets, faction hubs, and mob notes for any zone.",
            [
                ("/zones query: duskwood", "Level 20-30 Alliance contested zone, Darkshire hub, and Stitches alerts"),
                ("/zones query: stranglethorn vale", "Level 30-45 PvP hotspot, Nesingwary camp, and rebel outposts"),
                ("/zones query: zephras isle", "WoW Forever custom zone: level 48-55 pirate haven and faction hubs"),
                ("/zones query: searing gorge", "Level 43-50 Thorium Point neutral flight path and Blackrock Mountain gates"),
                ("/zones query: felwood", "Level 48-55 corrupted herb cleanings, Timbermaw hold entrance, and hubs")
            ]
        ),
        (
            "/mob",
            "Boss HP pools, spawn coordinates, abilities, and loot drop rates.",
            [
                ("/mob query: garr", "Garr HP pool, 8 Firesworn adds, Magma Shackles slow, and Bindings drop %"),
                ("/mob query: emperor dagran", "Spawn location, Avatar of Flame phase, and Princess Moira add rules"),
                ("/mob query: devilsaur", "Spawn circuits in Un'Goro Crater, stealth detection, and skinning value"),
                ("/mob query: lord kazzak", "World boss spawn in Blasted Lands, Supreme Mode timer, and Shadowbolt Volley"),
                ("/mob query: high foreman bargul", "WoW Forever custom boss in Hateforge Quarry: mechanics & loot")
            ]
        ),
        (
            "/vendor",
            "Locate NPC merchants selling limited recipes, reagents, and food.",
            [
                ("/vendor query: free action potion", "Kor'geld (Horde) and Ulthir (Alliance) exact merchant coords"),
                ("/vendor query: recipe elixir of superior defense", "Sula Brumblefoot coords in Wetlands, limited quantity timer"),
                ("/vendor query: runecloth bag recipe", "Qia in Winterspring: coords, price, and restock timer"),
                ("/vendor query: wildthorn tea", "Kaldorei merchant location and agility drink value"),
                ("/vendor query: heavy silk bandage", "First aid trainer coordinates in Arathi Highlands and Dustwallow")
            ]
        ),
        (
            "/farm",
            "Best gold farming hotspots, solo dungeon pulls, and G/hr yields.",
            [
                ("/farm query: dm east jump run", "Solo caster route: Rich Thorium nodes, Boss kills, and 60+ G/hr yield"),
                ("/farm query: elemental earth", "Badlands rock elementals spawn density, competition, and gold yield"),
                ("/farm query: essence of water", "Felwood and Eastern Plaguelands water elemental pools and farm guide"),
                ("/farm query: maraudon princess", "Solo Princess Theradras runs for Blackstone Ring and vendor trash"),
                ("/farm query: ghost mushroom", "Maraudon and Hinterlands cave farming circuit for Shadow Oil")
            ]
        ),
        (
            "/twink",
            "Best-in-slot gear and uncapped enchants for battleground twinks.",
            [
                ("/twink query: 19 rogue", "Shadowfang, Assassin's Blade, Feet of the Lynx, and +100 HP chest enchant"),
                ("/twink query: 29 warrior", "Corpsemaker 2H axe, Warsong boots, and Crusader weapon enchant"),
                ("/twink query: 39 mage", "Spell power dagger, Hypnotic Blade, and Silk Mantle of the Eagle"),
                ("/twink query: 19 hunter", "Venomstrike bow, Strikegiver, and +3 weapon damage enchant"),
                ("/twink query: 29 paladin", "Verigan's Fist, Cobalt armor, and movement speed boots")
            ]
        ),
        (
            "/build",
            "Meta talent specs, stat weights, and spell rotations.",
            [
                ("/build query: warrior spec: fury pve", "17/34/0 Deep Wounds & Flurry spec, 6% hit cap, and Bloodthirst rotation"),
                ("/build query: mage spec: aoe blizzard", "Permafrost & Improved Blizzard farming spec with safe pull steps"),
                ("/build query: warlock spec: sm ruin", "30/0/21 Shadow Mastery & Ruin spec for raid corruption and shadowbolts"),
                ("/build query: druid spec: hotw ns", "0/30/21 Heart of the Wild & Nature's Swiftness hybrid PvP build"),
                ("/build query: rogue spec: combat daggers", "15/31/5 Backstab spec with Opportunity and weapon expertise")
            ]
        ),
        (
            "/talents",
            "Visual ASCII talent tree layout and point-by-point leveling order.",
            [
                ("/talents query: warrior spec: arms", "Visual Arms tree (31/20/0) with leveling point order to Mortal Strike"),
                ("/talents query: rogue spec: combat", "Visual Combat Swords tree with Riposte and Blade Flurry priorities"),
                ("/talents query: priest spec: shadow", "Shadow tree leveling progression to Shadowform at level 40"),
                ("/talents query: mage spec: frost", "Frost tree point order: Shatter, Ice Shards, and Ice Barrier"),
                ("/talents query: hunter spec: beast mastery", "BM leveling tree: Bestial Swiftness, Frenzy, and Bestial Wrath")
            ]
        ),
        (
            "/attunement",
            "Step-by-step quest chains to get into raids.",
            [
                ("/attunement query: onyxia alliance", "Full 16-step Marshal Windsor jailbreak chain in Blackrock Depths"),
                ("/attunement query: onyxia horde", "Warlord's Command, Rexxar questline, and Highborne test of skulls"),
                ("/attunement query: bwl", "Blackhand's Command questline in UBRS and orb attunement"),
                ("/attunement query: mc", "Attunement to the Core: Core Fragment pickup inside BRD entrance"),
                ("/attunement query: naxxramas", "The Dread Citadel: Argent Dawn reputation requirements and gold cost")
            ]
        ),
        (
            "/keys",
            "Find where to get dungeon keys and what doors they unlock.",
            [
                ("/keys query: shadowforge key", "Franclorn Forgestone ghost quest inside BRD and Shrine of Thaurissan"),
                ("/keys query: skeleton key", "A Plague Upon Thee quest chain in Western Plaguelands for Scholomance"),
                ("/keys query: key to the city", "Magistrate Barthilas drop in Stratholme unlocking the Service Gate"),
                ("/keys query: scarlet key", "Doan's Strongbox inside Scarlet Monastery Library for Armory/Cath"),
                ("/keys query: crescent key", "Pusillin chase in Dire Maul East for DM West and North doors")
            ]
        ),
        (
            "/resets",
            "Live countdowns to weekly, 5-day, and 3-day raid lockouts.",
            [
                ("/resets query: onyxia", "Live days and hours remaining on the 5-day Onyxia lockout timer"),
                ("/resets query: zg", "Live countdown to the 3-day Zul'Gurub reset"),
                ("/resets query: mc", "Live countdown to the Tuesday weekly Molten Core reset"),
                ("/resets query: bwl", "Live countdown to the Tuesday weekly Blackwing Lair reset"),
                ("/resets query: all", "Master dashboard displaying all active raid lockout countdowns")
            ]
        ),
        (
            "/buffs",
            "World buff turn-in locations, cooldowns, and raid bonuses.",
            [
                ("/buffs query: ony head", "Rallying Cry of the Dragonslayer (+10% spell crit, +140 AP, 5% crit)"),
                ("/buffs query: rend", "Warchief's Blessing (+300 HP, 15% melee haste, 10 mp5) in Orgrimmar"),
                ("/buffs query: songflower", "Songflower Serenade (+15 all stats, +5% crit) cleansing routes in Felwood"),
                ("/buffs query: dire maul tribute", "Fengus' Ferocity, Slip'kik's Savvy, and Mol'dar's Moxie buffs"),
                ("/buffs query: zandalar", "Spirit of Zandalar (+10% all stats, 10% move speed) Yojamba turn-in")
            ]
        ),
        (
            "/pvp",
            "Honor rank math, weekly decay, and battleground guides.",
            [
                ("/pvp query: rank 10", "Rank 10 Champion/Lieutenant Commander honor math and blue PvP set unlocks"),
                ("/pvp query: rank 14", "Grand Marshal/High Warlord honor pool requirements and weapon rewards"),
                ("/pvp query: weekly decay", "How the 20% weekly rank point decay formula works in Classic"),
                ("/pvp query: wsg flag carry", "Warsong Gulch druid flag carry jumps, routes, and speed gear"),
                ("/pvp query: av rush", "Alterac Valley drek/galv rush tactics, lieutenants, and bunker captures")
            ]
        ),
        (
            "/roll",
            "Interactive raid loot roll engine with a countdown timer.",
            [
                ("/roll query: Reins of the Deathcharger seconds: 30", "Starts 30-second raid roll button for Baron Rivendare's mount"),
                ("/roll query: Vis'kag the Bloodletter seconds: 45", "45-second roll button for Onyxia sword with tie-breaker logic"),
                ("/roll query: Mageblade seconds: 30", "Roll engine for Azuresong Mageblade with live player tracking"),
                ("/roll query: Staff of Dominance seconds: 20", "Fast 20-second countdown for caster staff"),
                ("/roll query: Band of Sulfuras seconds: 30", "Interactive roll for Ragnaros legendary ring")
            ]
        ),
        (
            "/signup",
            "Create interactive raid roster signups with Tank, Healer, and DPS buttons.",
            [
                ("/signup query: MC Sunday 7pm max_players: 40", "Creates live 40-man Molten Core signup board with role counts"),
                ("/signup query: Onyxia Thursday 8pm max_players: 40", "Interactive Onyxia raid roster with Bench & Tentative buttons"),
                ("/signup query: ZG Reset Run max_players: 20", "20-man Zul'Gurub signup embed with real-time class tracking"),
                ("/signup query: BWL Progression Friday max_players: 40", "Blackwing Lair signup board with automatic player list updates"),
                ("/signup query: Hateforge Quarry Guild Run max_players: 10", "10-man roster for WoW Forever custom dungeon")
            ]
        ),
        (
            "/macro",
            "Copy-pasteable in-game macros with stance and target triggers.",
            [
                ("/macro query: stance dance overpower", "Single-button Battle Stance swap, Overpower cast, and Berserker return"),
                ("/macro query: mouseover heal", "Heals the target under your mouse cursor without deselecting current target"),
                ("/macro query: startattack sinister strike", "Ensures melee auto-attack starts even if you don't have enough energy"),
                ("/macro query: shoot wand cancel", "Prevents wand shooting toggle lag and casts spells immediately"),
                ("/macro query: spammable stealth", "Spam-safe stealth macro that never accidentally un-stealths you")
            ]
        ),
        (
            "/ask",
            "Freeform conversational AI assistant for any WoW question.",
            [
                ("/ask query: what are the best pre-raid swords?", "Ranks Dal'Rends, Mirah's Song, Thrash Blade, and Sword of Zeal"),
                ("/ask query: how does weapon skill work vs level 63 bosses?", "Explains glancing blow damage penalty reduction from 300 to 305+"),
                ("/ask query: what level should i leave the barrens?", "Recommends exact level (24-26) and where to travel next (Stonetalon/Ashenvale)"),
                ("/ask query: what are the 9 custom dungeons on forever?", "Lists all 9 custom instances, level ranges, and key bosses"),
                ("/ask query: how much gold is epic mount training?", "Exact breakdown of riding skill cost, faction discounts, and mount price")
            ]
        )
    ]

    total_slides = len(slides_data)
    for idx, (cmd_name, one_liner, ideas) in enumerate(slides_data):
        pdf.draw_command_slide(cmd_name, one_liner, ideas, idx + 1, total_slides)

    out_file = "Foreverbot_Command_Ideas.pdf"
    pdf.output(out_file)
    print(f"Command ideas PDF successfully generated at: {out_file}")

    # Copy to downloads if directory exists
    downloads_dir = os.path.expanduser("~/Downloads")
    if os.path.exists(downloads_dir):
        downloads_path = os.path.join(downloads_dir, "Foreverbot_Command_Ideas.pdf")
        shutil.copy2(out_file, downloads_path)
        print(f"Copied directly to user Downloads: {downloads_path}")

if __name__ == "__main__":
    build_ideas_deck()
