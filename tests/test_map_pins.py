#!/usr/bin/env python3
import unittest
import os
import re

class TestQuestMapPins(unittest.TestCase):
    def setUp(self):
        self.addon_lua_path = os.path.join(os.path.dirname(__file__), "..", "addon", "ForeverGuide", "ForeverGuide.lua")
        self.addon_toc_path = os.path.join(os.path.dirname(__file__), "..", "addon", "ForeverGuide", "ForeverGuide.toc")
        self.media_dir = os.path.join(os.path.dirname(__file__), "..", "addon", "ForeverGuide", "Media")
        self.assertTrue(os.path.exists(self.addon_lua_path), "ForeverGuide.lua must exist")
        self.assertTrue(os.path.exists(self.addon_toc_path), "ForeverGuide.toc must exist")
        with open(self.addon_lua_path, "r", encoding="utf-8") as f:
            self.content = f.read()
        with open(self.addon_toc_path, "r", encoding="utf-8") as f:
            self.toc_content = f.read()

    def test_default_config_has_map_pins(self):
        # World map is false by default to keep it completely clean per user request
        self.assertIn("showWorldMapPins = false,", self.content)
        # Zone minimap (BattlefieldMinimap) and HUD minimap are enabled by default
        self.assertIn("showZoneMapPins = true,", self.content)
        self.assertIn("showMinimapPins = true,", self.content)
        self.assertIn("zoneMapPinScale = 1.0,", self.content)
        self.assertIn("mapPinScale = 1.0,", self.content)

    def test_toc_includes_embedded_libs(self):
        self.assertIn("Libs/LibStub/LibStub.lua", self.toc_content)
        self.assertIn("Libs/CallbackHandler-1.0/CallbackHandler-1.0.lua", self.toc_content)
        self.assertIn("Libs/HereBeDragons/HereBeDragons-2.0.lua", self.toc_content)
        self.assertIn("Libs/HereBeDragons/HereBeDragons-Pins-2.0.lua", self.toc_content)

    def test_embedded_lib_files_exist(self):
        base_dir = os.path.join(os.path.dirname(__file__), "..", "addon", "ForeverGuide", "Libs")
        self.assertTrue(os.path.exists(os.path.join(base_dir, "LibStub", "LibStub.lua")))
        self.assertTrue(os.path.exists(os.path.join(base_dir, "CallbackHandler-1.0", "CallbackHandler-1.0.lua")))
        self.assertTrue(os.path.exists(os.path.join(base_dir, "HereBeDragons", "HereBeDragons-2.0.lua")))
        self.assertTrue(os.path.exists(os.path.join(base_dir, "HereBeDragons", "HereBeDragons-Pins-2.0.lua")))

    def test_3d_illuminated_hd_textures_exist(self):
        expected_textures = [
            "pin_available.tga",
            "pin_active.tga",
            "pin_turnin.tga",
            "pin_forever.tga",
            "pin_glow_halo.tga"
        ]
        for tex in expected_textures:
            tex_path = os.path.join(self.media_dir, tex)
            self.assertTrue(os.path.exists(tex_path), f"Texture file {tex} must exist in Media/")

    def test_pin_textures_table_defined_in_lua(self):
        self.assertIn("FG.PIN_TEXTURES = {", self.content)
        self.assertIn("pin_available.tga", self.content)
        self.assertIn("pin_active.tga", self.content)
        self.assertIn("pin_turnin.tga", self.content)
        self.assertIn("pin_forever.tga", self.content)
        self.assertIn("pin_glow_halo.tga", self.content)

    def test_zone_minimap_canvas_resolver(self):
        self.assertIn("function FG:GetZoneMapCanvas()", self.content)
        self.assertIn("BattlefieldMapFrame", self.content)
        self.assertIn("BattlefieldMinimap", self.content)

    def test_zone_name_to_map_id_mapping(self):
        self.assertIn('FG.ZONE_NAME_TO_MAP_ID = {', self.content)
        self.assertIn('["dun morogh"] = 1426', self.content)
        self.assertIn('["elwynn forest"] = 1429', self.content)
        self.assertIn('["durotar"] = 1411', self.content)
        self.assertIn('["mulgore"] = 1412', self.content)
        self.assertIn('["tirisfal glades"] = 1420', self.content)
        self.assertIn('["westfall"] = 1436', self.content)
        self.assertIn('["loch modan"] = 1432', self.content)
        self.assertIn('["the barrens"] = 1413', self.content)

    def test_quest_coordinates_helper(self):
        self.assertIn("function FG:GetQuestCoords(q)", self.content)
        self.assertIn("FG:FindCreatureByName(q.npc)", self.content)
        self.assertIn("q._cachedX = tonumber(cx)", self.content)

    def test_quest_difficulty_colors(self):
        self.assertIn("function FG:GetQuestDifficultyColor(qLevel, pLevel)", self.content)
        self.assertIn('"|cffff2020"', self.content) # Red
        self.assertIn('"|cffff7c0a"', self.content) # Orange
        self.assertIn('"|cffffd100"', self.content) # Yellow
        self.assertIn('"|cff20ff20"', self.content) # Green
        self.assertIn('"|cff808080"', self.content) # Gray

    def test_map_canvas_resolver(self):
        self.assertIn("function FG:GetMapCanvas()", self.content)
        self.assertIn("WorldMapFrame.ScrollContainer.Child", self.content)
        self.assertIn("WorldMapFrame:GetCanvas()", self.content)

    def test_update_zone_map_pins_engine(self):
        self.assertIn("function FG:UpdateZoneMapPins()", self.content)
        self.assertIn("function FG:UpdateWorldMapPins(forcedMapID)", self.content)
        self.assertIn("FG:ReleaseZoneMapPins()", self.content)
        self.assertIn("FG:UpdateZoneMapPinsScale()", self.content)

    def test_world_map_toggle_button(self):
        self.assertIn("function FG:CreateWorldMapToggleButton()", self.content)
        self.assertIn('CreateFrame("Button", "ForeverGuideWorldMapToggle", WorldMapFrame, "BackdropTemplate")', self.content)
        self.assertIn('btn:SetPoint("TOPRIGHT", WorldMapFrame, "TOPRIGHT", -36, -3)', self.content)

    def test_slash_command_pins(self):
        self.assertIn('cmd == "pins" or cmd == "mappins" or cmd == "pin"', self.content)
        self.assertIn("function FG:CmdMapPins(arg)", self.content)

    def test_hooks_and_event_dispatch(self):
        self.assertIn("function FG:HookZoneMap()", self.content)
        self.assertIn("function FG:HookWorldMap()", self.content)
        self.assertIn("FG:InitMapPins()", self.content)
        self.assertIn("FG:UpdateMapPins()", self.content)

if __name__ == "__main__":
    unittest.main()
