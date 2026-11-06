#!/usr/bin/env python3
"""
tests/test_giraffe_icon_and_inspect_button.py

Unit test suite validating:
1. Authentic Blizzard icon mapping for Barrens Giraffe and savanna grazers (Tallstrider icon, never a wolf).
2. Universal Beast fallback is the neutral beast tracking paw print (Ability_Tracking), never a wolf.
3. Dedicated Inspect button (btn.InspectBtn) opens the detail panel.
4. Left-clicking the row body pins/tracks coordinates and does NOT pop open the inspect window.
5. Structured Nearby folder hierarchy (Closest radar, Beasts & Wildlife, Humanoids, Flight Masters, etc.).
6. Proximity-based distance sorting in Nearby view.
"""

import os
import re
import unittest

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LUA_FILE = os.path.join(BASE_DIR, "addon", "ForeverGuide", "ForeverGuide.lua")


class TestGiraffeIconAndInspectButton(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with open(LUA_FILE, "r", encoding="utf-8") as f:
            cls.lua = f.read()

    def test_01_giraffe_and_tallstrider_authentic_blizzard_icon(self):
        """Verify Barrens Giraffe is mapped to authentic Tallstrider savannah icon, not a wolf."""
        self.assertIn('name:find("giraffe")', self.lua)
        self.assertIn('"Interface\\\\Icons\\\\Ability_Hunter_Pet_TallStrider"', self.lua)

    def test_02_beast_fallback_neutral_paw_print(self):
        """Verify beasts without a specific species match fall back to neutral tracking paw print, never a wolf."""
        # Check that the beast block ends with Ability_Tracking
        beast_block = self.lua[self.lua.find('-- 6. Beasts'):self.lua.find('-- 7. Elementals')]
        self.assertIn('return "Interface\\\\Icons\\\\Ability_Tracking"', beast_block)
        # Verify giraffe is checked BEFORE the return
        self.assertIn('if name:find("giraffe")', beast_block)

    def test_03_dedicated_inspect_button_created(self):
        """Verify btn.InspectBtn is created as an interactive Button frame."""
        self.assertIn('local inspectBtn = CreateFrame("Button", nil, btn)', self.lua)
        self.assertIn('btn.InspectBtn = inspectBtn', self.lua)
        self.assertIn('btn.Hint = hint', self.lua)
        self.assertIn('inspectBtn:SetScript("OnClick", function(self)', self.lua)
        self.assertIn('FG:ShowDetailPanel(self.entityType, self.entityData)', self.lua)

    def test_04_row_clicking_pins_coordinates_not_inspect(self):
        """Verify clicking the row body tracks/pins coordinates and does NOT call ShowDetailPanel."""
        # Find creature row OnClick
        creature_click = re.search(r'elseif match\.type == "creature" then.*?(btn:SetScript\("OnClick", function\(\).*?end\))', self.lua, re.DOTALL)
        self.assertIsNotNone(creature_click)
        code = creature_click.group(1)
        self.assertIn('FG:TrackEntityCoords(c.name, c.zone, c.coords)', code)
        self.assertNotIn('FG:ShowDetailPanel', code)

    def test_05_nearby_folder_structure_and_subcategories(self):
        """Verify Nearby has sub-categories for Beasts, Humanoids, Flight Masters, and Closest Radar."""
        self.assertIn('nearby/closest', self.lua)
        self.assertIn('["nearby/creatures"]', self.lua)
        self.assertIn('nearby/creatures/beasts', self.lua)
        self.assertIn('nearby/creatures/humanoids', self.lua)
        self.assertIn('nearby/creatures/all', self.lua)
        self.assertIn('["nearby/vendors"]', self.lua)
        self.assertIn('nearby/vendors/flight', self.lua)
        self.assertIn('nearby/vendors/repairs', self.lua)
        self.assertIn('nearby/vendors/all', self.lua)

    def test_06_live_distance_and_bearing_calculation(self):
        """Verify FG:GetDistanceAndBearing and FG:TrackEntityCoords methods exist."""
        self.assertIn('function FG:GetPlayerCoords()', self.lua)
        self.assertIn('function FG:GetDistanceAndBearing(coordStr)', self.lua)
        self.assertIn('function FG:TrackEntityCoords(name, zone, coords)', self.lua)

    def test_07_nearby_proximity_sorting(self):
        """Verify table.sort prioritizes closer entities when in Nearby view."""
        self.assertIn('local isNearbyView = (cur:find("^nearby") ~= nil) or (cat == "nearby")', self.lua)
        self.assertIn('if distA and distB and math.abs(distA - distB) > 0.05 then', self.lua)
        self.assertIn('return distA < distB', self.lua)


if __name__ == "__main__":
    unittest.main()
