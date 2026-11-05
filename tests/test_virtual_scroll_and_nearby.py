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
        self.assertIn('elseif subName == "Leather Armor" and item.itemType and item.itemType:find("Leather") then matchesFilter = true', self.lua_code)

    def test_04_creature_family_singular_plural_matching(self):
        """Verify singular/plural family matching resolves Elementals, Beasts, Demons, Giants, Humanoids."""
        # Query database counts for each family
        c = self.db.cursor()
        for fam, expected_min in [("Elemental", 380), ("Beast", 1100), ("Demon", 200), ("Giant", 50), ("Humanoid", 7000)]:
            c.execute("SELECT COUNT(*) FROM creatures WHERE family = ?", (fam,))
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


if __name__ == "__main__":
    unittest.main()
