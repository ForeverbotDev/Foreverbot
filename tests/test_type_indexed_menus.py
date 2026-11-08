#!/usr/bin/env python3
import unittest
import os
import re

class TestTypeIndexedMenus(unittest.TestCase):
    def setUp(self):
        self.addon_lua_path = os.path.join(os.path.dirname(__file__), "..", "addon", "ForeverGuide", "ForeverGuide.lua")
        self.assertTrue(os.path.exists(self.addon_lua_path), "ForeverGuide.lua must exist")
        with open(self.addon_lua_path, "r", encoding="utf-8") as f:
            self.content = f.read()

    def test_consumable_subfolders_defined(self):
        self.assertIn('["items/consumables"] = {', self.content)
        for expected in ["items/sub/Potions", "items/sub/Elixirs", "items/sub/Flasks", "items/sub/Food", "items/sub/Bandages", "items/sub/Scrolls", "items/sub/Oils", "items/sub/All Consumables"]:
            self.assertIn(f'path = "{expected}"', self.content, f"Missing consumable folder path: {expected}")

    def test_recipes_subfolders_defined(self):
        self.assertIn('["items/recipes"] = {', self.content)
        for expected in ["items/recipes/alchemy", "items/recipes/blacksmithing", "items/recipes/cooking", "items/recipes/enchanting", "items/recipes/engineering", "items/recipes/first_aid", "items/recipes/leatherworking", "items/recipes/tailoring", "items/recipes/all"]:
            self.assertIn(f'path = "{expected}"', self.content, f"Missing recipe folder path: {expected}")

    def test_trade_goods_subfolders_defined(self):
        self.assertIn('["items/trade_goods"] = {', self.content)
        for expected in ["items/sub/Cloth", "items/sub/Elemental", "items/sub/Gems", "items/sub/Herbs", "items/sub/Leather", "items/sub/Ore", "items/sub/Parts", "items/sub/Reagents", "items/sub/All Trade Goods"]:
            self.assertIn(f'path = "{expected}"', self.content, f"Missing trade goods folder path: {expected}")

    def test_containers_subfolders_defined(self):
        self.assertIn('["items/containers"] = {', self.content)
        for expected in ["items/sub/Bags", "items/sub/Quivers", "items/sub/Specialty_Bags"]:
            self.assertIn(f'path = "{expected}"', self.content, f"Missing container folder path: {expected}")

    def test_vendors_subfolders_defined(self):
        self.assertIn('["vendors"] = {', self.content)
        for expected in ["vendors/flightpaths", "vendors/repairs", "vendors/reagents", "vendors/food", "vendors/weapons_armor", "vendors/pvp", "vendors/specialty", "vendors/all"]:
            self.assertIn(f'path = "{expected}"', self.content, f"Missing vendor folder path: {expected}")

    def test_potions_strictly_excludes_elixirs_and_flasks(self):
        # Verify that subName == "Potions" condition does NOT pool Elixirs and Flasks
        m = re.search(r'elseif subName == "Potions"[^\n]+\n(.*?)(?=elseif subName == "Elixirs")', self.content, re.DOTALL)
        self.assertIsNotNone(m, "Potions block must exist")
        potions_code = m.group(1)
        self.assertIn('not name:find("Elixir")', potions_code)
        self.assertIn('not name:find("Flask")', potions_code)

    def test_leaf_folder_ilvl_sorting(self):
        # Verify that in folder browsing mode, leaf folders sort strictly by iLvl ascending
        self.assertIn("local isLeafItemFolder = cur:find(\"^items/sub/\")", self.content)
        self.assertIn("ilvlA < ilvlB", self.content)

    def test_upgrades_tab_and_slash_commands(self):
        # Verify Upgrades tab pill button and category mapping
        self.assertIn('CreateCategoryPill("upgrades", "Upgrades", 60, 3, itemsBtn)', self.content)
        self.assertIn('["upgrades"] = "upgrades"', self.content)
        # Slash commands
        self.assertIn('cmd == "upgrade" or cmd == "upgrades" or cmd == "gear" or cmd == "armor"', self.content)

    def test_upgrades_folder_tree_and_types(self):
        # Main upgrades category folder
        self.assertIn('["upgrades"] = {', self.content)
        for expected in [
            "upgrades/recommended",
            "upgrades/cloth",
            "upgrades/leather",
            "upgrades/mail",
            "upgrades/plate",
            "upgrades/accessories",
            "upgrades/dungeons",
            "upgrades/quests",
            "upgrades/all"
        ]:
            self.assertIn(f'path = "{expected}"', self.content, f"Missing upgrades folder path: {expected}")

        # Cloth / Leather / Mail / Plate subfolders
        for armor_type in ["cloth", "leather", "mail", "plate"]:
            self.assertIn(f'["upgrades/{armor_type}"] = {{', self.content)
            for slot in ["Head", "Shoulder", "Chest", "Wrist", "Hands", "Waist", "Legs", "Feet"]:
                self.assertIn(f'path = "upgrades/{armor_type}/{slot}"', self.content)

        # Accessories subfolder
        self.assertIn('["upgrades/accessories"] = {', self.content)
        for acc_slot in ["Cloaks", "Amulets", "Rings", "Trinkets", "Shields", "Off-hand"]:
            self.assertIn(f'path = "upgrades/acc/{acc_slot}"', self.content)

    def test_armor_upgrade_helpers_and_source_text(self):
        # Check IsArmorOrUpgradeItem and source text
        self.assertIn("function FG:IsArmorOrUpgradeItem(item)", self.content)
        self.assertIn("function FG:GetItemRowSourceText(item)", self.content)
        self.assertIn('table.insert(parts, "|cff38bdf8" .. srcText .. "|r")', self.content)
        self.assertIn("PLAYER_LEVEL_UP", self.content)

if __name__ == "__main__":
    unittest.main()
