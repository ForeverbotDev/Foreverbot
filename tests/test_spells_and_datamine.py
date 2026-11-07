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


if __name__ == "__main__":
    unittest.main()
