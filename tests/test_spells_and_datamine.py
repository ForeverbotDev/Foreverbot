#!/usr/bin/env python3
"""
Unit tests for Spells, Abilities, and Datamined Forever Additions in ForeverGuide.
Verifies class abilities, Alpha reworked talents, custom racials, and folder integration.
"""

import os
import unittest
import re

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ADDON_LUA = os.path.join(BASE_DIR, "addon", "ForeverGuide", "ForeverGuide.lua")
DATA_LUA = os.path.join(BASE_DIR, "addon", "ForeverGuide", "ForeverGuide_Data.lua")


class TestSpellsAndDatamine(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with open(ADDON_LUA, "r", encoding="utf-8") as f:
            cls.addon_lua = f.read()

        # Read beginning of ForeverGuide_Data.lua for fast metadata checks
        # and sample checks from Spells table
        cls.data_has_spells = False
        with open(DATA_LUA, "r", encoding="utf-8") as f:
            f.seek(max(0, os.path.getsize(DATA_LUA) - 1500000))
            cls.data_tail = f.read()
            if "ForeverGuide_Data.Spells" in cls.data_tail:
                cls.data_has_spells = True

    def test_01_spells_table_in_data_lua(self):
        """Verify ForeverGuide_Data.Spells exists in ForeverGuide_Data.lua."""
        self.assertTrue(self.data_has_spells, "ForeverGuide_Data.Spells table not found in ForeverGuide_Data.lua")

    def test_02_spells_category_pill(self):
        """Verify Spells category pill is created in the header row."""
        self.assertIn('CreateCategoryPill("spells", "Spells"', self.addon_lua)
        self.assertIn('["spells"] = "spells"', self.addon_lua)

    def test_03_spells_folder_hierarchy(self):
        """Verify Spells folder and class subfolders are defined in FolderTree."""
        self.assertIn('{ path = "spells", name = "Spells & Abilities"', self.addon_lua)
        self.assertIn('["spells"] = {', self.addon_lua)
        for cls_name in ["druid", "hunter", "mage", "paladin", "priest", "rogue", "shaman", "warlock", "warrior", "racials", "forever", "all"]:
            self.assertIn(f'path = "spells/{cls_name}"', self.addon_lua)

    def test_04_spell_row_button_configuration(self):
        """Verify row button configuration for match.type == 'spell'."""
        self.assertIn('elseif match.type == "spell" then', self.addon_lua)
        self.assertIn('btn.InspectBtn.entityType = "spell"', self.addon_lua)
        self.assertIn('FG:ShowDetailPanel("spell", s)', self.addon_lua)

    def test_05_spell_detail_panel_inspector(self):
        """Verify deep inspector panel for entityType == 'spell'."""
        self.assertIn('elseif entityType == "spell" then', self.addon_lua)
        self.assertIn("Spell & Ability Intel", self.addon_lua)
        self.assertIn("CASTING & RESOURCE", self.addon_lua)
        self.assertIn("EFFECT & TOOLTIP", self.addon_lua)

    def test_06_spell_chat_linking(self):
        """Verify spell chat linking in LinkEntityToChat."""
        self.assertIn('elseif entityType == "spell" then', self.addon_lua)
        self.assertIn('[Spell: ', self.addon_lua)

    def test_07_spell_slash_command(self):
        """Verify /spark spell and /spark spells slash command aliases."""
        self.assertIn('cmd == "spell" or cmd == "spells"', self.addon_lua)

    def test_08_sample_custom_alpha_spells_in_data(self):
        """Verify custom Alpha spells (Shank, Revive, Death Mark, Skyborne racials) exist in data."""
        self.assertIn('name = "Shank"', self.data_tail)
        self.assertIn('id = 437138', self.data_tail) # Druid Revive
        self.assertIn('name = "Death Mark"', self.data_tail)
        self.assertIn('name = "Wind-Blessed"', self.data_tail)
        self.assertIn('name = "Plainsrunning"', self.data_tail)

    def test_09_aspect_of_the_monkey_official_blizzard_intel(self):
        """Verify Aspect of the Monkey (13163) has 100% official Blizzard tooltip, cost, icon and mechanics."""
        with open(DATA_LUA, "r", encoding="utf-8") as f:
            text = f.read()
        spells_idx = text.find("ForeverGuide_Data.Spells")
        self.assertGreater(spells_idx, 0, "Spells table not found")
        spells_text = text[spells_idx:]

        m = re.search(r"t\[13163\]\s*=\s*\{([\s\S]*?)\}", spells_text)
        self.assertIsNotNone(m, "Spell 13163 not found in Spells table")
        block = m.group(1)
        self.assertIn('name = "Aspect of the Monkey"', block)
        self.assertIn('class = "Hunter"', block)
        self.assertIn('cost = "20 Mana"', block)
        self.assertIn('castTime = "Instant"', block)
        self.assertIn('range = "100 yd range"', block)
        self.assertIn('icon = "Interface\\\\Icons\\\\ability_hunter_aspectofthemonkey"', block)
        self.assertIn('desc = "The hunter takes on the aspects of a monkey, increasing chance to dodge by 8%.  Only one Aspect can be active at a time."', block)

    def test_10_zero_placeholder_spell_descriptions(self):
        """Verify no dummy 'class ability trained at level' placeholder descriptions exist in data."""
        with open(DATA_LUA, "r", encoding="utf-8") as f:
            text = f.read()
        spells_idx = text.find("ForeverGuide_Data.Spells")
        spells_text = text[spells_idx:]
        self.assertEqual(spells_text.count("class ability trained at level"), 0, "Found placeholder spell descriptions in ForeverGuide_Data.Spells")

    def test_11_zero_quadruple_backslashes_in_data(self):
        """Verify no quadruple backslash texture paths exist in data (would break WoW texture engine)."""
        with open(DATA_LUA, "r", encoding="utf-8") as f:
            text = f.read()
        self.assertEqual(text.count("\\\\\\\\"), 0, "Found double-escaped quadruple backslashes in ForeverGuide_Data.lua")

    def test_12_spell_runtime_helpers_in_addon(self):
        """Verify FG:GetSpellIcon, FG:GetSpellDescription, and FG:GetSpellCastingInfo exist in ForeverGuide.lua."""
        self.assertIn("function FG:GetSpellIcon(s)", self.addon_lua)
        self.assertIn("function FG:GetSpellDescription(s)", self.addon_lua)
        self.assertIn("function FG:GetSpellCastingInfo(s)", self.addon_lua)
        self.assertIn("local sIcon = FG:GetSpellIcon(data)", self.addon_lua)
        self.assertIn("local descText = FG:GetSpellDescription(data)", self.addon_lua)


if __name__ == "__main__":
    unittest.main()
