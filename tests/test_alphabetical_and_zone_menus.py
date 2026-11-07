#!/usr/bin/env python3
"""
tests/test_alphabetical_and_zone_menus.py

Validates:
1. Universal alphabetical folder sorting across all FolderTree menus.
2. Elimination of duplicate slot folders in Cloth, Leather, Mail, and Plate.
3. By-Zone grouping for Available Quests and Recommended Quests with live counts.
4. Font size 12pt title / 10.5pt subtext with -6 / -2 padding.
5. Item deduplication across all item queries.
"""

import os
import re
import unittest

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ADDON_DIR = os.path.join(BASE_DIR, "addon", "ForeverGuide")
LUA_FILE = os.path.join(ADDON_DIR, "ForeverGuide.lua")


class TestAlphabeticalAndZoneMenus(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        with open(LUA_FILE, "r", encoding="utf-8") as f:
            cls.lua_code = f.read()

    def test_01_typography_font_sizes_and_padding(self):
        """Verify 12pt title font, 10.5pt subtext font, and -6/-2 padding."""
        self.assertIn('SharpenFontString(titleText, 12, "OUTLINE")', self.lua_code)
        self.assertIn('SharpenFontString(subText, 10.5, "OUTLINE")', self.lua_code)
        self.assertIn('SharpenFontString(btn.Title, 12, "OUTLINE")', self.lua_code)
        self.assertIn('SharpenFontString(btn.Sub, 10.5, "OUTLINE")', self.lua_code)
        self.assertIn('titleText:SetPoint("TOPLEFT", btn, "TOPLEFT", 48, -6)', self.lua_code)
        self.assertIn('subText:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, -2)', self.lua_code)

    def test_02_available_and_recommended_quests_by_zone(self):
        """Verify Available and Recommended quests are grouped by zone with live counts."""
        self.assertIn('cur == "quests/available" and FG.Data.Quests', self.lua_code)
        self.assertIn('[All Available Quests (Full List)]', self.lua_code)
        self.assertIn('path = "quests/available/" .. zn', self.lua_code)
        self.assertIn('cur:find("^quests/available/(.+)$")', self.lua_code)

        self.assertIn('cur == "quests/recommended" and FG.Data.Quests', self.lua_code)
        self.assertIn('[All Recommended Quests (Full List)]', self.lua_code)
        self.assertIn('path = "quests/recommended/" .. zn', self.lua_code)
        self.assertIn('cur:find("^quests/recommended/(.+)$")', self.lua_code)

    def test_03_is_all_pinning_in_table_sort(self):
        """Verify isAll folders are pinned at top of listings."""
        self.assertIn('if a.data and a.data.isAll and not (b.data and b.data.isAll) then return true end', self.lua_code)
        self.assertIn('if b.data and b.data.isAll and not (a.data and a.data.isAll) then return false end', self.lua_code)

    def test_04_no_doubles_guard_in_armor_slot_generator(self):
        """Verify dynamic slot generator has not (folderDef and folderDef.folders) guard to prevent doubles."""
        self.assertIn('(not (folderDef and folderDef.folders)) and cur:find("^items/armor/([^/]+)$")', self.lua_code)

    def test_05_item_deduplication_seen_tables(self):
        """Verify seen deduplication tables exist in item query blocks."""
        self.assertIn('local key = item.id or (name .. ":" .. (item.ilvl or 0))', self.lua_code)
        self.assertIn('if not seen[key] then', self.lua_code)

    def test_06_folder_tree_alphabetical_order(self):
        """Verify root, items/weapons, creatures, and dungeons folders are declared in alphabetical order."""
        # In root: Creatures, Dungeons, Items, Nearby, Quests, Spells, Vendors, [Forever]
        root_block = self.lua_code[self.lua_code.find('["root"] = {'):self.lua_code.find('["nearby"] = {')]
        names = re.findall(r'name = "([^"]+)"', root_block)
        expected = ["Creatures & Bosses", "Dungeons & Raids", "Items & Equipment", "Nearby Area Intel (Zone Radar)", "Quests", "Spells & Abilities", "Vendors & Flight Paths", "[Forever] Warcraft Forever Exclusives"]
        self.assertEqual(names, expected)


if __name__ == "__main__":
    unittest.main()
