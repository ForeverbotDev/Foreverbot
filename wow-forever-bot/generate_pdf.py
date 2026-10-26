"""Generates a high-quality PDF command guide for WoW: Forever & Foreverbot."""

from fpdf import FPDF
import os


class WoWGuidePDF(FPDF):
    def header(self):
        # Header banner
        self.set_fill_color(22, 27, 34)  # Dark slate
        self.rect(0, 0, 210, 22, "F")

        # Gold accent bar
        self.set_fill_color(218, 165, 32)  # Gold
        self.rect(0, 22, 210, 2, "F")

        self.set_xy(10, 5)
        self.set_font("Helvetica", "B", 13)
        self.set_text_color(255, 215, 0)  # Gold text
        self.cell(0, 6, "WORLD OF WARCRAFT: FOREVER (CLASSIC+)", ln=True)

        self.set_xy(10, 12)
        self.set_font("Helvetica", "I", 9)
        self.set_text_color(180, 190, 205)
        self.cell(0, 6, "Foreverbot Companion & Command Reference Guide - Launching Nov 4, 2026", ln=True)
        self.ln(10)

    def footer(self):
        self.set_y(-15)
        self.set_font("Helvetica", "I", 8)
        self.set_text_color(130, 130, 130)
        self.cell(0, 10, f"Page {self.page_no()} | World of Warcraft: Forever Discord Bot Companion", align="C")

    def section_title(self, title):
        self.ln(4)
        self.set_fill_color(36, 41, 46)
        self.set_text_color(255, 215, 0)  # Gold
        self.set_font("Helvetica", "B", 11)
        self.cell(0, 7, f"  {title}", fill=True, ln=True)
        self.set_text_color(40, 40, 40)
        self.ln(2)

    def command_card(self, cmd_name, param_str, desc, example, is_forever=False):
        box_x = 10
        box_y = self.get_y()
        box_w = 190
        box_h = 22

        # Draw card background
        self.set_fill_color(248, 250, 252)
        self.set_draw_color(215, 222, 230)
        self.rect(box_x, box_y, box_w, box_h, "DF")

        # Top row: Command Name + Params + Badge
        self.set_xy(box_x + 3, box_y + 2)
        self.set_font("Courier", "B", 10)
        self.set_text_color(30, 95, 185)
        self.cell(32, 5, cmd_name)

        self.set_font("Helvetica", "I", 8.5)
        self.set_text_color(90, 100, 110)
        self.cell(70, 5, param_str)

        if is_forever:
            self.set_font("Helvetica", "B", 7.5)
            self.set_text_color(180, 105, 0)
            self.cell(80, 5, "[WOW: FOREVER CLASSIC+]", align="R")

        # Description
        self.set_xy(box_x + 3, box_y + 7.5)
        self.set_font("Helvetica", "", 8.5)
        self.set_text_color(45, 55, 72)
        self.multi_cell(184, 4.5, desc)

        # Example
        self.set_xy(box_x + 3, box_y + 15.5)
        self.set_font("Courier", "B", 8)
        self.set_text_color(35, 125, 60)
        self.cell(184, 4.5, f"Example: {example}")

        self.set_xy(box_x, box_y + box_h + 3)


def build_pdf(output_path="wow_forever_bot_guide.pdf"):
    pdf = WoWGuidePDF(orientation="P", unit="mm", format="A4")
    pdf.set_auto_page_break(auto=True, margin=20)
    pdf.add_page()

    # Introduction block
    pdf.set_font("Helvetica", "", 9)
    pdf.set_text_color(60, 60, 60)
    intro = (
        "World of Warcraft: Forever is Blizzard's official Classic+ experience, launching globally on November 4, 2026. "
        "Featuring a permanent Level 60 cap, an alternate timeline where the Dark Portal never reopened, 9 new dungeons, "
        "new zones (Mount Hyjal, Zephras Isle, Riverglades), Skyborne Elves, and horizontal progression. "
        "Foreverbot gives you real-time Discord lookups directly on your second screen or phone while playing."
    )
    pdf.multi_cell(190, 4.5, intro)
    pdf.ln(2)

    # 1. Item Lookups
    pdf.section_title("1. ITEM & GEAR LOOKUPS")
    pdf.command_card(
        "/item",
        "name: <item name>",
        "Displays full tooltip stats, slot, type, required level, item level, equip effects, and drop/vendor source. Color-coded by quality.",
        "/item name: Ironfoe",
        is_forever=True
    )
    pdf.command_card(
        "/item",
        "name: <Skyborne gear>",
        "Look up new horizontal level 60 tier sets, new weapons, and resistance items added in WoW: Forever.",
        "/item name: Skyborne",
        is_forever=True
    )

    # 2. Quests
    pdf.section_title("2. QUESTS & LEVELING")
    pdf.command_card(
        "/quest",
        "title: <quest name>",
        "Shows quest level, required level, faction, starter NPC, map coordinates, objectives, and item/XP rewards.",
        "/quest title: Mankrik's Wife",
        is_forever=False
    )
    pdf.command_card(
        "/quest",
        "title: <Forever quest>",
        "Look up new Classic+ quest chains for Skyborne Elves, Mount Hyjal, and Riverglades.",
        "/quest title: Roots Beneath Nordrassil",
        is_forever=True
    )

    # 3. Mobs & Loot
    pdf.section_title("3. MOBS, BOSSES & LOOT TABLES")
    pdf.command_card(
        "/mob",
        "name: <boss or mob>",
        "Displays creature level, classification (Elite/Boss), zone, subzone location, total health, and top loot drops with percentages.",
        "/mob name: Emperor Dagran Thaurissan",
        is_forever=False
    )
    pdf.command_card(
        "/mob",
        "name: <Forever boss>",
        "Check stats and drop tables for new dungeon and raid bosses in Mount Hyjal and Zephras Citadel.",
        "/mob name: Archdruid Valeth",
        is_forever=True
    )

    # 4. Vendors & Economy
    pdf.section_title("4. VENDORS & REAGENTS")
    pdf.command_card(
        "/vendor",
        "item_name: <item>",
        "Finds which NPCs sell a specific item, coordinates, and price formatted in gold (g), silver (s), and copper (c).",
        "/vendor item_name: Bronze Tube",
        is_forever=False
    )

    # Page 2
    pdf.add_page()

    # 5. Flight Paths
    pdf.section_title("5. FLIGHT PATHS & FAST TRAVEL")
    pdf.command_card(
        "/flightpath",
        "query: <zone or hub>",
        "Lists flight masters by zone or node name, their faction (Alliance/Horde/Neutral), coordinates, and all connected routes.",
        "/flightpath query: Booty Bay",
        is_forever=False
    )
    pdf.command_card(
        "/flightpath",
        "query: <Forever zone>",
        "Look up flight connections for new zones like Zephras Aerie, Mount Hyjal Ridge, and Riverglades Sanctuary.",
        "/flightpath query: Zephras",
        is_forever=True
    )

    # 6. Natural Language Assistant
    pdf.section_title("6. NATURAL LANGUAGE ASSISTANT (/ask)")
    pdf.command_card(
        "/ask",
        "question: <plain English>",
        "Ask questions in natural language. The bot searches all database tables (quests, items, mobs, vendors, flight paths) to synthesize a direct answer.",
        "/ask question: Where do I turn in Mankrik's quest?",
        is_forever=True
    )
    pdf.command_card(
        "/ask",
        "question: <price check>",
        "Query items or vendors without typing exact syntax.",
        "/ask question: Who sells bronze tubes and for how much?",
        is_forever=True
    )

    # 7. Maps, Zones & Dungeons
    pdf.section_title("7. MAPS, ZONES & DUNGEONS (/map, /dungeons, /zones)")
    pdf.command_card(
        "/map",
        "[zone: <zone name or city>]",
        "Consolidated zone map card with coordinates, key towns, flight masters, dungeon entrances, and connecting borders.",
        "/map zone: Westfall",
        is_forever=True
    )
    pdf.command_card(
        "/dungeons",
        "[query: <level or name>]",
        "Finds strictly eligible dungeons for any level (e.g. 42) or name (e.g. ZF) with entrance coords & key drops. Condensed single card.",
        "/dungeons query: 42",
        is_forever=True
    )
    pdf.command_card(
        "/zones",
        "(No parameters)",
        "Lists all new & expanded zones in WoW: Forever (Mount Hyjal, Zephras Isle, Riverglades, Gilneas).",
        "/zones",
        is_forever=True
    )

    # 8. Game Overview Card
    pdf.section_title("8. GAME OVERVIEW CARD")
    pdf.command_card(
        "/forever",
        "(No parameters)",
        "Displays official WoW: Forever launch info, Nov 4 release details, level 60 cap philosophy, new zones, and dungeons.",
        "/forever",
        is_forever=True
    )

    # Color Quality Legend
    pdf.ln(2)
    pdf.section_title("WOW ITEM QUALITY COLOR CODING IN DISCORD")
    pdf.set_font("Helvetica", "", 8.5)

    qualities = [
        ("Common", "(White / #FFFFFF)", "Standard vendor items and basic gear"),
        ("Uncommon", "(Green / #1EFF00)", "Good leveling gear and quest rewards"),
        ("Rare", "(Blue / #0070DD)", "Dungeon drops and superior craftables"),
        ("Epic", "(Purple / #A335EE)", "Raid loot, high-end dungeon drops, and Forever horizontal sets"),
        ("Legendary", "(Orange / #FF8000)", "Thunderfury, Sulfuras, and historic artifacts"),
    ]

    for name, code, note in qualities:
        pdf.set_font("Helvetica", "B", 8.5)
        pdf.set_text_color(30, 30, 30)
        pdf.cell(26, 5, f"- {name}: ")
        pdf.set_font("Courier", "", 8)
        pdf.set_text_color(80, 80, 80)
        pdf.cell(35, 5, code)
        pdf.set_font("Helvetica", "I", 8)
        pdf.set_text_color(100, 100, 100)
        pdf.cell(120, 5, note, ln=True)

    # Save PDF
    pdf.output(output_path)
    print(f"PDF successfully created at: {output_path}")


if __name__ == "__main__":
    build_pdf()
