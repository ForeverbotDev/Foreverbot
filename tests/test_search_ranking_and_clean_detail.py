#!/usr/bin/env python3
"""
tests/test_search_ranking_and_clean_detail.py

Unit test suite verifying:
1. Search ranking: Items are matched first at top, exact match ranked #1, quests placed after items.
2. Thunderfury availability and cross-category fallback from scoped categories.
3. Clean removal of target macro feature across code, UI, and tooltips.
4. Clean removal of detail panel bottom buttons (Share to Chat / Search Source / Target Macro).
5. Clean ASCII quest badges without broken Unicode font glyphs.
6. Full LuaJIT bytecode compilation of ForeverGuide.lua and ForeverGuide_Data.lua.
"""

import os
import unittest
import subprocess

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ADDON_DIR = os.path.join(BASE_DIR, "addon", "ForeverGuide")
LUA_FILE = os.path.join(ADDON_DIR, "ForeverGuide.lua")
DATA_FILE = os.path.join(ADDON_DIR, "ForeverGuide_Data.lua")


class TestSearchRankingAndCleanDetail(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with open(LUA_FILE, "r", encoding="utf-8") as f:
            cls.lua_code = f.read()
        with open(DATA_FILE, "r", encoding="utf-8") as f:
            cls.data_code = f.read()

    def test_01_luajit_compilation(self):
        """Verify both ForeverGuide.lua and ForeverGuide_Data.lua compile cleanly in LuaJIT."""
        res_lua = subprocess.run(["luajit", "-b", LUA_FILE, "/dev/null"], capture_output=True, text=True)
        self.assertEqual(res_lua.returncode, 0, f"ForeverGuide.lua failed to compile: {res_lua.stderr}")

        res_data = subprocess.run(["luajit", "-b", DATA_FILE, "/dev/null"], capture_output=True, text=True)
        self.assertEqual(res_data.returncode, 0, f"ForeverGuide_Data.lua failed to compile: {res_data.stderr}")

    def test_02_thunderfury_present_in_data(self):
        """Verify Thunderfury, Blessed Blade of the Windseeker is present in the database export."""
        self.assertIn("19019", self.data_code)
        self.assertIn("Thunderfury, Blessed Blade of the Windseeker", self.data_code)

    def test_03_items_matched_first_in_search(self):
        """Verify that search results rank items first at the top before quests or creatures."""
        self.assertIn("local typeRankA = (a.type == \"item\" and 1)", self.lua_code)
        self.assertIn("local typeRankB = (b.type == \"item\" and 1)", self.lua_code)
        self.assertIn("typeRankA < typeRankB", self.lua_code)

    def test_04_search_relevance_scoring(self):
        """Verify multi-tier match quality scoring (exact match > prefix > word boundary > secondary)."""
        self.assertIn("function GetSearchMatchScore(match, query)", self.lua_code)
        self.assertIn("if nl == query then return 1 end", self.lua_code)
        self.assertIn("if nl:sub(1, #query) == query then return 2 end", self.lua_code)

    def test_05_cross_category_search_fallback(self):
        """Verify auto-fallback to 'All' category when user searches or scoped category returns 0."""
        self.assertIn("FG:SetActiveCategory(\"all\")", self.lua_code)
        self.assertIn("if #matches == 0 and cat ~= \"all\" and q ~= \"\" then", self.lua_code)

    def test_06_target_macro_completely_removed(self):
        """Verify target macro feature is completely removed from detail panels, tooltips, and scripts."""
        self.assertNotIn("Target Macro", self.lua_code)
        self.assertNotIn("/target ", self.lua_code)
        self.assertNotIn("targeting macro", self.lua_code)

    def test_07_detail_panel_bottom_buttons_removed(self):
        """Verify bottom buttons (Share to Chat / Search Source / Target Macro) are removed from all detail views."""
        self.assertNotIn("p.LinkBtn", self.lua_code)
        self.assertNotIn("p.ActBtn", self.lua_code)
        # Verify scrollframe extends to bottom
        self.assertIn('sf:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", -26, 12)', self.lua_code)

    def test_08_no_broken_unicode_font_glyphs(self):
        """Verify no missing-glyph unicode characters (✓, ★, ●, ○) in quest badges."""
        self.assertNotIn("[✓ Completed]", self.lua_code)
        self.assertNotIn("[★ Ready to Turn In]", self.lua_code)
        self.assertNotIn("[● Active in Log]", self.lua_code)
        self.assertNotIn("[○ Available]", self.lua_code)
        self.assertIn("[Completed]", self.lua_code)
        self.assertIn("[Ready to Turn In]", self.lua_code)
        self.assertIn("[Active]", self.lua_code)
        self.assertIn("[Available]", self.lua_code)

    def test_09_search_debounce_and_memoization(self):
        """Verify search debounce timer (150ms), Enter key immediate execution, and memoization."""
        # 1. Debounce and OnUpdate script
        self.assertIn("searchBox.searchDelay = 0", self.lua_code)
        self.assertIn("searchBox.pendingQuery = nil", self.lua_code)
        self.assertIn('searchBox:SetScript("OnUpdate"', self.lua_code)
        self.assertIn("self.searchDelay = 0.15", self.lua_code)
        self.assertIn('searchBox:SetScript("OnEnterPressed"', self.lua_code)

        # 2. Lazy memoization on entity tables
        self.assertIn("item._nl = item._nl or item.name:lower()", self.lua_code)
        self.assertIn("item._isInternal = FG:IsInternalItem(item.name)", self.lua_code)
        self.assertIn("c._isInternal = FG:IsInternalCreature(c.name, c.family)", self.lua_code)
        self.assertIn("quest._isInternal = FG:IsInternalQuest(quest.title)", self.lua_code)

        # 3. Precomputed match score and result caps
        self.assertIn("maxItems = (cat == \"all\") and 120 or 300", self.lua_code)
        self.assertIn("local scoreA = a.score or GetSearchMatchScore(a, q)", self.lua_code)
        self.assertIn("local scoreB = b.score or GetSearchMatchScore(b, q)", self.lua_code)


if __name__ == "__main__":
    unittest.main()
