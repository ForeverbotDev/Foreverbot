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
        for expected in ["vendors/flightpaths", "vendors/repairs", "vendors/reagents", "vendors/food", "vendors/weapons_armor", "vendors/tradesupplies", "vendors/trainers", "vendors/pvp", "vendors/specialty", "vendors/all"]:
            self.assertIn(f'path = "{expected}"', self.content, f"Missing vendor folder path: {expected}")

    def test_nearby_type_indexed_subfolders(self):
        # Nearby creatures subfolders
        self.assertIn('["nearby/creatures"] = {', self.content)
        for expected in ["nearby/creatures/beasts", "nearby/creatures/humanoids", "nearby/creatures/undead", "nearby/creatures/elementals", "nearby/creatures/demons", "nearby/creatures/dragonkin", "nearby/creatures/giants", "nearby/creatures/rares", "nearby/creatures/all"]:
            self.assertIn(f'path = "{expected}"', self.content, f"Missing nearby creature subfolder: {expected}")

        # Nearby vendors subfolders
        self.assertIn('["nearby/vendors"] = {', self.content)
        for expected in ["nearby/vendors/flight", "nearby/vendors/repairs", "nearby/vendors/reagents", "nearby/vendors/food", "nearby/vendors/weapons_armor", "nearby/vendors/tradesupplies", "nearby/vendors/trainers", "nearby/vendors/pvp", "nearby/vendors/specialty", "nearby/vendors/all"]:
            self.assertIn(f'path = "{expected}"', self.content, f"Missing nearby vendor subfolder: {expected}")

        # Nearby loot subfolders
        self.assertIn('["nearby/loot"] = {', self.content)
        for expected in ["nearby/loot/armor", "nearby/loot/weapons", "nearby/loot/recipes", "nearby/loot/accessories", "nearby/loot/all"]:
            self.assertIn(f'path = "{expected}"', self.content, f"Missing nearby loot subfolder: {expected}")

        # Nearby quests subfolders
        self.assertIn('["nearby/quests"] = {', self.content)
        for expected in ["nearby/quests/recommended", "nearby/quests/story", "nearby/quests/dungeons", "nearby/quests/all"]:
            self.assertIn(f'path = "{expected}"', self.content, f"Missing nearby quest subfolder: {expected}")

    def test_dungeon_quests_type_indexed_instances(self):
        self.assertIn('["quests/dungeons"] = {', self.content)
        dungeon_samples = [
            "quests/dungeons/The Deadmines",
            "quests/dungeons/Wailing Caverns",
            "quests/dungeons/Shadowfang Keep",
            "quests/dungeons/Blackfathom Deeps",
            "quests/dungeons/The Stockade",
            "quests/dungeons/Gnomeregan",
            "quests/dungeons/Scarlet Monastery",
            "quests/dungeons/Razorfen Kraul",
            "quests/dungeons/Razorfen Downs",
            "quests/dungeons/Uldaman",
            "quests/dungeons/Zul'Farrak",
            "quests/dungeons/Maraudon",
            "quests/dungeons/Sunken Temple",
            "quests/dungeons/Blackrock Depths",
            "quests/dungeons/Blackrock Spire",
            "quests/dungeons/Stratholme",
            "quests/dungeons/Scholomance",
            "quests/dungeons/Dire Maul",
            "quests/dungeons/Molten Core",
            "quests/dungeons/Blackwing Lair",
            "quests/dungeons/Zul'Gurub",
            "quests/dungeons/Ahn'Qiraj",
            "quests/dungeons/Naxxramas",
            "quests/dungeons/all"
        ]
        for path in dungeon_samples:
            self.assertIn(f'path = "{path}"', self.content, f"Missing dungeon quest folder: {path}")

    def test_vendor_subtype_matching_helper(self):
        self.assertIn("function FG:MatchesVendorSubtype(v, subType)", self.content)
        self.assertIn('subType == "tradesupplies"', self.content)
        self.assertIn('subType == "trainers"', self.content)
        self.assertIn('subType == "weapons_armor"', self.content)
        self.assertIn('subType == "repairs"', self.content)

    def test_accessories_and_containers_have_all_and_shields(self):
        self.assertIn('path = "items/sub/Shields"', self.content)
        self.assertIn('path = "items/sub/Off-hand"', self.content)
        self.assertIn('path = "items/sub/All Accessories"', self.content)
        self.assertIn('path = "items/sub/All Containers"', self.content)

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

