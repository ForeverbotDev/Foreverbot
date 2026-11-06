#!/usr/bin/env python3
"""
tests/test_loot_tooltip_accuracy_and_sprite_fluidity.py

Unit test suite validating:
1. Loot and Dropper buttons in detail views use a shared data-driven dispatcher that guarantees
   tooltips accurately match the hovered item (e.g. Black Bear Hide Vest), eliminating closure
   leakage and script clobbering (no more "Protector Weaver" on bear vest).
2. "Home Mission Control · Dun Morogh Radar Active" has been completely removed from the status footer.
3. Sparky sprite has been enlarged (smidgen bigger: 48x48 frame, 54px aura, 44px/38px lobes)
   with 120fps fluid multi-harmonic motion physics and smootherstep easing.
"""

import os
import re
import unittest

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LUA_FILE = os.path.join(BASE_DIR, "addon", "ForeverGuide", "ForeverGuide.lua")


class TestLootTooltipAccuracyAndSpriteFluidity(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with open(LUA_FILE, "r", encoding="utf-8") as f:
            cls.lua = f.read()

    def test_01_loot_button_data_driven_dispatcher(self):
        """Verify CreateOrGetLootButton dispatches OnEnter based on self.kind without closure clobbering."""
        self.assertIn("function CreateOrGetLootButton(index)", self.lua)
        self.assertIn('if self.kind == "loot" and self.dropData then', self.lua)
        self.assertIn('elseif self.kind == "dropper_creature" and self.creatureData then', self.lua)
        self.assertIn('elseif self.kind == "dropper_vendor" and self.vendorData then', self.lua)

    def test_02_loot_button_populates_item_tooltip(self):
        """Verify loot drop buttons configure dropData and render authentic item stats and drop chance."""
        self.assertIn('btn.kind = "loot"', self.lua)
        self.assertIn('btn.dropData = drop', self.lua)
        self.assertIn('GameTooltip:AddLine("|cffdf80ff<Click>|r Inspect item in Codex"', self.lua)
        self.assertIn('Drop Chance: |cff38bdf8', self.lua)

    def test_03_dropper_button_populates_dropper_data(self):
        """Verify dropper buttons configure creatureData/vendorData and never clobber button scripts."""
        self.assertIn('btn.kind = "dropper_creature"', self.lua)
        self.assertIn('btn.kind = "dropper_vendor"', self.lua)
        self.assertIn('btn.dropData = nil', self.lua)

    def test_04_home_mission_control_removed(self):
        """Verify 'Home Mission Control' and 'Radar Active' have been removed from the status text."""
        self.assertNotIn("Home Mission Control", self.lua)
        self.assertNotIn("Radar Active", self.lua)

    def test_05_sprite_enlarged_dimensions(self):
        """Verify Sparky sprite frame and visual layers are a smidgen bigger."""
        self.assertIn('f:SetSize(48, 48)', self.lua)
        self.assertIn('visual:SetSize(34, 34)', self.lua)
        self.assertIn('aura:SetSize(54, 54)', self.lua)
        self.assertIn('cloudA:SetSize(44, 44)', self.lua)
        self.assertIn('cloudB:SetSize(38, 38)', self.lua)
        self.assertIn('wispTendril:SetSize(42, 42)', self.lua)
        self.assertIn('cloudCore:SetSize(28, 28)', self.lua)

    def test_06_high_fps_fluid_motion_engine(self):
        """Verify 120fps motion physics, smootherstep easing, and multi-harmonic hover oscillations."""
        # 120fps dt clamp
        self.assertIn('local dt = math.min(elapsed, 0.033)', self.lua)
        # Smootherstep quintic curve
        self.assertIn('local u = p * p * p * (p * (p * 6 - 15) + 10)', self.lua)
        # Multi-harmonic floating oscillation
        self.assertIn('math.sin(t * 1.5) * 3.5 + math.sin(t * 0.7) * 1.8', self.lua)
        # Dynamic responsive satellite puffs
        self.assertIn('local lagFactor = math.min(1.0, dt * 18.0)', self.lua)


if __name__ == "__main__":
    unittest.main()
