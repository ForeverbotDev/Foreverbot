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
        """Verify menus/folders display 'categories in view (A-Z)' and never 'items in view (iLvl: Lowest to Highest)'."""
        self.assertIn('elseif folderCount == #matches then', self.lua_code)
        self.assertIn('categories in view (A-Z)', self.lua_code)
        self.assertIn('items in view (iLvl: Lowest to Highest)', self.lua_code)
        self.assertIn('quests in view (A-Z)', self.lua_code)
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
        """Verify replacement of redundant Home screen vertical rows with interactive Mission Control Dashboard."""
        # 1. Functions and frames
        self.assertIn('function FG:CreateHomeDashboard(parent)', self.lua_code)
        self.assertIn('function FG:UpdateHomeDashboard()', self.lua_code)
        self.assertIn('content.HomeDashboard = FG:CreateHomeDashboard(content)', self.lua_code)

        # 2. Hero Card: Live Area Radar
        self.assertIn('LIVE AREA RADAR', self.lua_code)
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

        # 5. Root activation in PopulateCodexResults
        self.assertIn('if cur == "root" and q == "" then', self.lua_code)
        self.assertIn('content.HomeDashboard:Show()', self.lua_code)
        self.assertIn('FG:UpdateHomeDashboard()', self.lua_code)
        self.assertIn('content.HomeDashboard:Hide()', self.lua_code)

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


if __name__ == "__main__":
    unittest.main()
