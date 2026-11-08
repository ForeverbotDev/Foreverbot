#!/usr/bin/env python3
import unittest
import os
import re

class TestNearbyRadarQuality(unittest.TestCase):
    def setUp(self):
        self.addon_lua_path = os.path.join(os.path.dirname(__file__), "..", "addon", "ForeverGuide", "ForeverGuide.lua")
        self.assertTrue(os.path.exists(self.addon_lua_path), "ForeverGuide.lua must exist")
        with open(self.addon_lua_path, "r", encoding="utf-8") as f:
            self.content = f.read()

    def test_nearby_creatures_folder_rendering(self):
        # Assert that nearby/creatures with q == "" inserts the 4 category folders
        self.assertIn('if cur == "nearby/creatures" and q == "" then', self.content)
        self.assertIn('"nearby/creatures/beasts"', self.content)
        self.assertIn('"nearby/creatures/humanoids"', self.content)
        self.assertIn('"nearby/creatures/rares"', self.content)
        self.assertIn('"nearby/creatures/all"', self.content)

    def test_nearby_vendors_folder_rendering(self):
        # Assert that nearby/vendors with q == "" inserts the 4 category folders
        self.assertIn('if cur == "nearby/vendors" and q == "" then', self.content)
        self.assertIn('"nearby/vendors/flight"', self.content)
        self.assertIn('"nearby/vendors/repairs"', self.content)
        self.assertIn('"nearby/vendors/reagents"', self.content)
        self.assertIn('"nearby/vendors/all"', self.content)

    def test_show_all_creatures_not_restricted_by_query(self):
        # Assert that folder view renders subfolders without dumping raw rows, and shows creatures on subpath or search
        self.assertIn('local showCreatures = (creatureSub ~= nil)', self.content)
        self.assertIn('(cur == "nearby/creatures" and q ~= "")', self.content)

    def test_nearby_empty_state_zone_customization(self):
        # Assert that NoResultsState checks cur:find("^nearby")
        self.assertIn('if cur == "nearby" or cat == "nearby" or cur:find("^nearby") then', self.content)
        self.assertIn('No nearby intel found in', self.content)

    def test_nearby_breadcrumbs_contain_subcategories(self):
        # Assert that UpdateDolphinBreadcrumbs maps all nearby subcategories via lookup tables
        self.assertIn('cur:find("^nearby/creatures/(.+)$")', self.content)
        self.assertIn('beasts = "Beasts"', self.content)
        self.assertIn('humanoids = "Humanoids"', self.content)
        self.assertIn('cur:find("^nearby/vendors/(.+)$")', self.content)
        self.assertIn('flight = "Flight Masters"', self.content)
        self.assertIn('repairs = "Repairs & Armorers"', self.content)

    def test_navigate_up_hierarchical_for_nearby(self):
        # Assert that NavigateUpFolder correctly resolves nearby/creatures and nearby/vendors
        self.assertIn('elseif cur:find("^nearby/creatures/") then', self.content)
        self.assertIn('parent = "nearby/creatures"', self.content)
        self.assertIn('elseif cur:find("^nearby/vendors/") then', self.content)
        self.assertIn('parent = "nearby/vendors"', self.content)

    def test_subzone_creature_matching_and_priority(self):
        # Assert that inZone checks both zone and location, and inSub is prioritized
        self.assertIn('(c.zone and c.zone:lower() == pZoneLower) or (c.location and c.location:lower():find(pZoneLower, 1, true))', self.content)
        self.assertIn('if a.inSub and not b.inSub then return true end', self.content)

if __name__ == "__main__":
    unittest.main()
