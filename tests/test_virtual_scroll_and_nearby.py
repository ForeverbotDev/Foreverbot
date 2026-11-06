#!/usr/bin/env python3
"""
tests/test_virtual_scroll_and_nearby.py

Automated verification of Virtual Scrolling, Uncapped Catalog Browsing,
Creature Family Matching, and Real-Time Live Radar [Nearby] Tab.
"""

import os
import re
import unittest
import sqlite3

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ADDON_DIR = os.path.join(BASE_DIR, "addon", "ForeverGuide")
LUA_FILE = os.path.join(ADDON_DIR, "ForeverGuide.lua")
DATA_FILE = os.path.join(ADDON_DIR, "ForeverGuide_Data.lua")
DB_FILE = os.path.join(BASE_DIR, "wow_forever.db")


class TestVirtualScrollAndNearby(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        with open(LUA_FILE, "r", encoding="utf-8") as f:
            cls.lua_code = f.read()
        cls.db = sqlite3.connect(DB_FILE)

    @classmethod
    def tearDownClass(cls):
        cls.db.close()

    def test_01_no_hardcoded_caps_in_codex(self):
        """Verify that all hardcoded 80, 50, 65, 75, 85 caps have been eliminated."""
        caps = re.findall(r'#matches\s*>=\s*\d+', self.lua_code)
        self.assertEqual(len(caps), 0, f"Found hardcoded caps in ForeverGuide.lua: {caps}")

    def test_02_virtual_scrolling_architecture(self):
        """Verify presence of Virtual Scrolling engine, row pool, and mouse wheel handlers."""
        self.assertIn("function FG:UpdateVirtualRows()", self.lua_code)
        self.assertIn("function FG:CreateCodexRowButton(parent, i)", self.lua_code)
        self.assertIn("function FG:ConfigureRowButton(btn, match)", self.lua_code)
        self.assertIn("content.RowPool = {}", self.lua_code)
        self.assertIn("OnMouseWheel", self.lua_code)
        self.assertIn("OnVerticalScroll", self.lua_code)
        self.assertIn("FG.currentMatches = matches", self.lua_code)

    def test_03_leather_armor_full_catalog_count(self):
        """Verify database contains 2,658 Leather Armor items and filter matches them all."""
        c = self.db.cursor()
        c.execute("SELECT COUNT(*) FROM items WHERE item_type LIKE '%Leather%'")
        count = c.fetchone()[0]
        self.assertEqual(count, 2658, f"Expected 2658 Leather Armor items, got {count}")

        # Check Lua matching condition
        self.assertIn('elseif subName == "Leather Armor" and not isRecipe and item.itemType and item.itemType:find("Leather") then matchesFilter = true', self.lua_code)

    def test_04_creature_family_singular_plural_matching(self):
        """Verify singular/plural family matching resolves Elementals, Beasts, Demons, Giants, Humanoids."""
        c = self.db.cursor()
        for fam, expected_min in [("Elemental", 350), ("Beast", 1100), ("Demon", 200), ("Giant", 50), ("Humanoid", 6800)]:
            c.execute("SELECT COUNT(*) FROM creatures WHERE family = ? AND forever_status = 'live'", (fam,))
            cnt = c.fetchone()[0]
            self.assertGreaterEqual(cnt, expected_min, f"Family {fam} count {cnt} below expected {expected_min}")

        # Check Lua matching logic: fam == s or fam .. "s" == s or (s:sub(-1) == "s" and fam == s:sub(1, -2))
        self.assertIn('fam == s or fam .. "s" == s or (s:sub(-1) == "s" and fam == s:sub(1, -2))', self.lua_code)

    def test_05_nearby_tab_and_zone_radar(self):
        """Verify [Nearby] pill, GetPlayerZoneInfo, and live radar event hooks."""
        # Nearby category pill
        self.assertIn('CreateCategoryPill("nearby", "Nearby", 52, 4, allBtn)', self.lua_code)
        self.assertIn('["nearby"] = "nearby"', self.lua_code)

        # GetPlayerZoneInfo implementation
        self.assertIn("function FG:GetPlayerZoneInfo()", self.lua_code)
        self.assertIn("GetRealZoneText", self.lua_code)
        self.assertIn("GetSubZoneText", self.lua_code)
        self.assertIn("FG.Data.Subzones", self.lua_code)

        # Zone change event registrations
        self.assertIn('EventFrame:RegisterEvent("ZONE_CHANGED")', self.lua_code)
        self.assertIn('EventFrame:RegisterEvent("ZONE_CHANGED_INDOORS")', self.lua_code)
        self.assertIn('EventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")', self.lua_code)

    def test_06_no_broken_unicode_emojis_in_navigation(self):
        """Verify no broken Unicode emoji glyphs in upBtn, breadcrumbs, or folder titles."""
        self.assertIn('"< Up"', self.lua_code)
        self.assertNotIn('"⬆ Up"', self.lua_code)
        self.assertNotIn('📁 Home', self.lua_code)
        self.assertNotIn('📂 Quests', self.lua_code)
        self.assertNotIn('▶', self.lua_code)

    def test_07_subzones_mapping_ground_truth(self):
        """Verify Subzones mapping in ForeverGuide_Data.lua resolves key subzones to parent zones."""
        with open(DATA_FILE, "r", encoding="utf-8") as f:
            data_head = f.read(50000)

        self.assertIn('ForeverGuide_Data.Subzones = {', data_head)
        self.assertIn('["northshire abbey"] = "Elwynn Forest"', data_head)
        self.assertIn('["northshire valley"] = "Elwynn Forest"', data_head)
        self.assertIn('["crystal lake"] = "Elwynn Forest"', data_head)
        self.assertIn('["moonbrook"] = "Westfall"', data_head)
        self.assertIn('["longshore"] = "Westfall"', data_head)

    def test_08_no_player_shapeshift_or_internal_dummies_in_creatures(self):
        """Verify shapeshift forms (Bear Form, Cat Form) and internal triggers/dummies are purged."""
        # 1. Database check
        c = self.db.cursor()
        c.execute("SELECT COUNT(*) FROM creatures WHERE forever_status = 'live' AND (name LIKE '%Bear Form%' OR name LIKE '%Cat Form%' OR name LIKE '%Dummy%')")
        live_junk = c.fetchone()[0]
        self.assertEqual(live_junk, 0, f"Found {live_junk} live shapeshift/dummy creatures in database")

        # 2. Lua exporter check
        with open(DATA_FILE, "r", encoding="utf-8") as f:
            data_content = f.read()
        self.assertNotIn('name = "Bear Form (Night Elf Druid)"', data_content)
        self.assertNotIn('name = "Bear Form (Tauren Druid)"', data_content)
        self.assertNotIn('name = "Combat Dummy"', data_content)

        # 3. Lua filter check
        self.assertIn("function FG:IsInternalCreature(name, family)", self.lua_code)
        self.assertIn('n:find(" form%f[%A]")', self.lua_code)

    def test_09_nearby_kde_folder_structure(self):
        """Verify Nearby tab features the 6 authentic KDE Dolphin folders without redundant 'Nearby ' prefix."""
        for path in ["nearby/quests", "nearby/rares", "nearby/creatures", "nearby/vendors", "nearby/dungeons", "nearby/loot"]:
            self.assertIn(f'path = "{path}"', self.lua_code)
        self.assertIn('name = "Quests"', self.lua_code)
        self.assertIn('name = "Rares & Bosses"', self.lua_code)
        self.assertIn('name = "Creatures & Mobs"', self.lua_code)
        self.assertIn('name = "Vendors & Flight Masters"', self.lua_code)
        self.assertIn('name = "Dungeons & Raids"', self.lua_code)
        self.assertIn('name = "Notable Loot & Drops"', self.lua_code)
        self.assertNotIn('name = "Nearby Quests"', self.lua_code)
        self.assertNotIn('name = "Nearby Rares & Bosses"', self.lua_code)

    def test_10_creatures_by_zone_and_strict_alphabetical_order(self):
        """Verify Creatures by Zone (EK & Kalimdor) and universal strict alphabetical sorting."""
        # Zone lists present
        self.assertIn("local EK_ZONE_NAMES = {", self.lua_code)
        self.assertIn("local KALIMDOR_ZONE_NAMES = {", self.lua_code)
        self.assertIn('path = "creatures/by_zone_ek"', self.lua_code)
        self.assertIn('path = "creatures/by_zone_kalimdor"', self.lua_code)
        self.assertIn('cur == "creatures/by_zone_ek"', self.lua_code)
        self.assertIn('cur == "creatures/by_zone_kalimdor"', self.lua_code)

        # Universal strict alphabetical sorting
        self.assertIn("return nameA:lower() < nameB:lower()", self.lua_code)

        # Items iLvl ascending sorting (lowest to highest)
        self.assertIn("return ilvlA < ilvlB", self.lua_code)
        self.assertIn("items in view (iLvl: Lowest to Highest)", self.lua_code)

    def test_11_armor_slot_subsections(self):
        """Verify armor slot subsections (Head, Shoulders, Chest, Wrist, Hands, Waist, Legs, Feet) exist for all armor types."""
        self.assertIn("local ARMOR_SLOT_DEFS = {", self.lua_code)
        for slot in ["Head", "Shoulder", "Chest", "Wrist", "Hands", "Waist", "Legs", "Feet"]:
            self.assertIn(f'slot = "{slot}"', self.lua_code)

        for armor in ["cloth", "leather", "mail", "plate"]:
            self.assertIn(f'["items/armor/{armor}"] = {{', self.lua_code)
            for slot in ["Head", "Shoulder", "Chest", "Wrist", "Hands", "Waist", "Legs", "Feet"]:
                self.assertIn(f'path = "items/armor/{armor}/{slot}"', self.lua_code)

        # Route matching
        self.assertIn('cur:find("^items/armor/([^/]+)/([^/]+)$")', self.lua_code)
        self.assertIn('cur:find("^items/armor/([^/]+)$")', self.lua_code)

    def test_12_menu_folders_status_text_not_ilvl(self):
        """Verify menus/folders display clean status text without '(A-Z)' and never 'items in view (iLvl: Lowest to Highest)'."""
        self.assertIn('elseif folderCount == #matches then', self.lua_code)
        self.assertIn('categories in view|r', self.lua_code)
        self.assertIn('items in view (iLvl: Lowest to Highest)', self.lua_code)
        self.assertIn('quests in view|r', self.lua_code)
        self.assertNotIn('(A-Z)', self.lua_code)
        self.assertNotIn('(A to Z)', self.lua_code)
    def test_13_luajit_syntax_compilation(self):
        """Compile ForeverGuide.lua using LuaJIT bytecode compiler to verify zero syntax errors."""
        import subprocess
        res = subprocess.run(["luajit", "-b", LUA_FILE, "/dev/null"], capture_output=True, text=True)
        self.assertEqual(res.returncode, 0, f"Lua syntax error detected:\n{res.stderr}")

    def test_14_calm_optometry_typography_and_no_overflow(self):
        """Verify typographic hierarchy, strict single-line isolation (zero overflow), and removal of visual clutter prefixes."""
        # 1. No noisy bracketed prefixes in titles
        self.assertNotIn('[Loot]|r ', self.lua_code)
        self.assertNotIn('[Nearby NPC]|r ', self.lua_code)
        self.assertNotIn('[Nearby Dungeon]|r ', self.lua_code)

        # 2. Single-line bounds and right margin clamping
        self.assertIn('titleText:SetWordWrap(false)', self.lua_code)
        self.assertIn('subText:SetWordWrap(false)', self.lua_code)
        self.assertIn('subText:SetHeight(15)', self.lua_code)

        # 3. Calm separator and soft muted palette in subtitles
        self.assertIn('table.concat(parts, " |cff475569·|r ")', self.lua_code)

    def test_15_home_screen_mission_control_dashboard(self):
        """Verify main screen categories and dashboard helper functions."""
        # 1. Functions and frames
        self.assertIn('function FG:CreateHomeDashboard(parent)', self.lua_code)
        self.assertIn('function FG:UpdateHomeDashboard()', self.lua_code)

        # 2. Hero Card: Location Bar (Clean, calm, no radar/connected tech theme)
        self.assertIn('Current Location', self.lua_code)
        self.assertNotIn('LIVE AREA RADAR', self.lua_code)
        self.assertIn('db.ZoneTitle = zoneTitle', self.lua_code)
        self.assertIn('db.QuestBadge = CreateStatBadge', self.lua_code)
        self.assertIn('db.RareBadge = CreateStatBadge', self.lua_code)
        self.assertIn('db.MobBadge = CreateStatBadge', self.lua_code)
        self.assertIn('db.DungeonBadge = CreateStatBadge', self.lua_code)
        self.assertIn('db.RadarBtn = radarBtn', self.lua_code)

        # 3. Featured 2x2 Hub Portals
        self.assertIn('db.HubForever = CreateHubCard', self.lua_code)
        self.assertIn('db.HubArmor = CreateHubCard', self.lua_code)
        self.assertIn('db.HubQuests = CreateHubCard', self.lua_code)
        self.assertIn('db.HubRares = CreateHubCard', self.lua_code)

        # 4. Sparky Field Notes & Shortcuts Card
        self.assertIn('SPARKY\'S FIELD NOTES & CONTROLS', self.lua_code)
        self.assertIn('Shift + Left-Click', self.lua_code)
        self.assertIn('Right-Click Row', self.lua_code)
        self.assertIn('/fg or /forever', self.lua_code)

        # 5. Root view displays categories directly in virtual row list
        self.assertIn('["root"] = {', self.lua_code)
        self.assertIn('Nearby Area Intel (Zone Radar)', self.lua_code)
        self.assertIn('Items & Equipment', self.lua_code)
        self.assertIn('Vendors & Flight Paths', self.lua_code)

    def test_16_available_and_recommended_dungeons_and_quests(self):
        """Verify presence of Available and Recommended across folders, list rows, and detail panels."""
        # 1. Folder hierarchy
        self.assertIn('{ path = "dungeons/available", name = "Available Dungeons"', self.lua_code)
        self.assertIn('{ path = "dungeons/recommended", name = "Recommended Dungeons"', self.lua_code)
        self.assertIn('{ path = "quests/available", name = "Available Quests"', self.lua_code)
        self.assertIn('{ path = "quests/recommended", name = "Recommended Quests"', self.lua_code)

        # 2. Detail panels
        self.assertIn('Available: |cff38bdf8Level', self.lua_code)
        self.assertIn('Recommended: |cff20ff20Level', self.lua_code)

        # 3. List rows and tooltips
        self.assertIn('Avail:', self.lua_code)
        self.assertIn('Rec:', self.lua_code)

    def test_17_proper_dynamic_icons(self):
        """Verify dynamic icon resolver functions and their usage in list rows and detail panel."""
        self.assertIn('function FG:GetCreatureIcon(c)', self.lua_code)
        self.assertIn('function FG:GetDungeonIcon(d)', self.lua_code)
        self.assertIn('function FG:GetVendorIcon(v)', self.lua_code)
        self.assertIn('function FG:GetQuestIcon(qData)', self.lua_code)

        # Verify creatures use FG:GetCreatureIcon instead of hardcoded murloc head
        self.assertIn('local cTex = FG:GetCreatureIcon(c)', self.lua_code)
        self.assertIn('local cTex = FG:GetCreatureIcon(data)', self.lua_code)
        self.assertIn('btn.Icon:SetTexture(cTex)', self.lua_code)

        # Verify dungeons use FG:GetDungeonIcon
        self.assertIn('btn.Icon:SetTexture(FG:GetDungeonIcon(d))', self.lua_code)
        self.assertIn('p.HeaderIcon:SetTexture(FG:GetDungeonIcon(data))', self.lua_code)

        # Verify vendors use FG:GetVendorIcon
        self.assertIn('btn.Icon:SetTexture(FG:GetVendorIcon(v))', self.lua_code)
        self.assertIn('p.HeaderIcon:SetTexture(FG:GetVendorIcon(data))', self.lua_code)

        # Verify quests use FG:GetQuestIcon
        self.assertIn('btn.Icon:SetTexture(FG:GetQuestIcon(qData))', self.lua_code)
        self.assertIn('p.HeaderIcon:SetTexture(FG:GetQuestIcon(data))', self.lua_code)

        # Verify folders use FG:GetFolderIcon and explicit authentic Blizzard icons
        self.assertIn('function FG:GetFolderIcon(folder)', self.lua_code)
        self.assertIn('local fTex = FG:GetFolderIcon(folder)', self.lua_code)
        self.assertIn('btn.Icon:SetTexture(fTex)', self.lua_code)
        self.assertIn('icon = "Interface\\\\Icons\\\\INV_Chest_Cloth_23"', self.lua_code)
        self.assertIn('icon = "Interface\\\\Icons\\\\INV_Chest_Leather_08"', self.lua_code)
        self.assertIn('icon = "Interface\\\\Icons\\\\INV_Chest_Chain_15"', self.lua_code)
        self.assertIn('icon = "Interface\\\\Icons\\\\INV_Chest_Plate03"', self.lua_code)
        self.assertIn('icon = "Interface\\\\Icons\\\\INV_Shield_04"', self.lua_code)
        self.assertIn('icon = "Interface\\\\Icons\\\\INV_Misc_Cape_19"', self.lua_code)

        # Verify authentic Blizzard creature and vendor icon resolution
        self.assertIn('INV_Misc_Bomb_01', self.lua_code) # Mortar team bomb round
        self.assertIn('Spell_Shadow_Haunting', self.lua_code) # Addled leper diseased icon
        self.assertIn('INV_Misc_Coin_01', self.lua_code) # Vendor commerce gold coin (never brown bag)
        self.assertIn('INV_Misc_Head_Dwarf_01', self.lua_code) # Authentic Dwarf race head
        self.assertIn('INV_Misc_Head_Gnome_01', self.lua_code) # Authentic Gnome race head
        self.assertIn('Ability_Mount_MechaStrider', self.lua_code) # Mechanostrider mount
        self.assertIn('INV_Misc_MonsterClaw_02', self.lua_code) # Troggs & Rockjaw
        self.assertIn('INV_Misc_Head_Troll_01', self.lua_code) # Trolls & Frostmane
        self.assertIn('Ability_Racial_BearForm', self.lua_code) # Wendigo & Yeti

    def test_18_dropper_coords_clickable_and_exclusives(self):
        """Verify dropper coordinates, clickable dropper buttons, multiple sources, exclusives rename, and internal filtering."""
        # 1. 'Custom' replaced with 'Exclusives'
        self.assertIn('Warcraft Forever Exclusives', self.lua_code)
        self.assertIn('Server gear, exclusive quests & endgame additions', self.lua_code)
        self.assertIn('Forever Exclusive Gear', self.lua_code)
        self.assertIn('Forever Exclusive NPCs', self.lua_code)
        self.assertNotIn('Warcraft Forever Custom', self.lua_code)

        # 2. Droppers inverted index and lookups
        self.assertIn('function FG:BuildItemDroppersIndex()', self.lua_code)
        self.assertIn('function FG:GetItemDroppers(itemId)', self.lua_code)
        self.assertIn('function FG:FindCreatureByName(name)', self.lua_code)
        self.assertIn('function FG:GetItemRowSourceText(item)', self.lua_code)

        # 3. Clickable droppers in item detail panel with coordinates
        self.assertIn('CONFIRMED DROPPERS & SOURCES', self.lua_code)
        self.assertIn('AddDropperButton', self.lua_code)
        self.assertIn('FG:ShowDetailPanel("creature", self.creatureData)', self.lua_code)
        self.assertIn('Open NPC intel & spawn location', self.lua_code)

        # 4. Multiple dropper indicator (+X more)
        self.assertIn('" +" .. (#droppers - 1) .. " more"', self.lua_code)

        # 5. Internal testing / non-applicable entity filtering
        self.assertIn('function FG:IsInternalCreature(name, family)', self.lua_code)
        self.assertIn('function FG:IsInternalItem(name)', self.lua_code)
        self.assertIn('function FG:IsInternalQuest(title)', self.lua_code)

        # Check filter patterns
        self.assertIn('not used', self.lua_code)
        self.assertIn('unused', self.lua_code)
        self.assertIn('deprecated', self.lua_code)
        self.assertIn('placeholder', self.lua_code)
        self.assertIn('monster %-', self.lua_code)

    def test_19_quest_completion_tracking_and_qol(self):
        """Verify quest completion tracking, live status badges, folders, and search filtering."""
        # 1. Helper function
        self.assertIn('function FG:GetQuestStatus(questID, questTitle)', self.lua_code)
        self.assertIn('C_QuestLog.IsQuestFlaggedCompleted', self.lua_code)
        self.assertIn('C_QuestLog.IsOnQuest', self.lua_code)
        self.assertIn('GetNumQuestLogEntries', self.lua_code)

        # 2. Badges and status rendering
        self.assertIn('[Completed]', self.lua_code)
        self.assertIn('[Ready to Turn In]', self.lua_code)
        self.assertIn('[Active]', self.lua_code)
        self.assertIn('[Available]', self.lua_code)

        # 3. Dedicated Folders
        self.assertIn('{ path = "quests/active", name = "Active in Log"', self.lua_code)
        self.assertIn('{ path = "quests/uncompleted", name = "Uncompleted Quests"', self.lua_code)
        self.assertIn('{ path = "quests/completed", name = "Completed Quests"', self.lua_code)

        # 4. Search status filtering
        self.assertIn('q == "completed"', self.lua_code)
        self.assertIn('q == "uncompleted"', self.lua_code)

        # 5. Live event listeners
        self.assertIn('EventFrame:RegisterEvent("QUEST_LOG_UPDATE")', self.lua_code)
        self.assertIn('EventFrame:RegisterEvent("QUEST_TURNED_IN")', self.lua_code)


if __name__ == "__main__":
    unittest.main()



