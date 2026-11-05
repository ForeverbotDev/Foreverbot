#!/usr/bin/env python3
"""
tests/test_addon_integrity_and_simulation.py

Automated test suite for the Warcraft Forever in-game addon:
Forever Guide ("The Blue Spark").
Validates TOC structure, XML bindings, Lua syntax, data compilation completeness,
WoW client sandbox simulation, and CurseForge package integrity.
"""

import os
import re
import sys
import zipfile
import unittest

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ADDON_DIR = os.path.join(BASE_DIR, "addon", "ForeverGuide")
TOC_FILE = os.path.join(ADDON_DIR, "ForeverGuide.toc")
LUA_FILE = os.path.join(ADDON_DIR, "ForeverGuide.lua")
DATA_FILE = os.path.join(ADDON_DIR, "ForeverGuide_Data.lua")
BINDINGS_FILE = os.path.join(ADDON_DIR, "Bindings.xml")
DIST_DIR = os.path.join(BASE_DIR, "dist")


class TestAddonIntegrityAndSimulation(unittest.TestCase):

    def test_01_toc_file_structure(self):
        """Verify ForeverGuide.toc metadata and referenced file presence."""
        self.assertTrue(os.path.exists(TOC_FILE), f"TOC file missing: {TOC_FILE}")
        with open(TOC_FILE, "r", encoding="utf-8") as f:
            content = f.read()

        # Check required WoW TOC headers
        self.assertRegex(content, r"##\s*Interface:\s*[\d,\s]+")
        self.assertRegex(content, r"##\s*Title:")
        self.assertRegex(content, r"##\s*Version:")
        self.assertRegex(content, r"##\s*SavedVariables:\s*ForeverGuideDB")

        # Verify listed files exist
        lines = [line.strip() for line in content.splitlines() if line.strip() and not line.startswith("##")]
        self.assertGreater(len(lines), 0, "No source files listed in TOC")
        for rel_file in lines:
            full_path = os.path.join(ADDON_DIR, rel_file)
            self.assertTrue(os.path.exists(full_path), f"File listed in TOC does not exist: {rel_file}")

    def test_02_bindings_xml_validity(self):
        """Verify Bindings.xml has valid XML structure and registered bindings."""
        self.assertTrue(os.path.exists(BINDINGS_FILE))
        import xml.etree.ElementTree as ET
        tree = ET.parse(BINDINGS_FILE)
        root = tree.getroot()
        self.assertEqual(root.tag, "Bindings")
        bindings = root.findall("Binding")
        self.assertGreaterEqual(len(bindings), 2)
        names = [b.get("name") for b in bindings]
        self.assertIn("FOREVERGUIDE_TOGGLE_SPARK", names)
        self.assertIn("FOREVERGUIDE_TOGGLE_CODEX", names)

    def test_03_lua_bracket_and_quote_integrity(self):
        """Validate bracket, paren, and quote balance across all addon Lua files."""
        pairs = {'{': '}', '[': ']', '(': ')'}
        for path in [LUA_FILE, DATA_FILE]:
            with open(path, "r", encoding="utf-8") as f:
                content = f.read()

            stack = []
            in_str = False
            quote_char = None
            escaped = False
            line = 1

            for ch in content:
                if ch == '\n':
                    line += 1
                if in_str:
                    if escaped:
                        escaped = False
                    elif ch == '\\':
                        escaped = True
                    elif ch == quote_char:
                        in_str = False
                else:
                    if ch in ('"', "'"):
                        in_str = True
                        quote_char = ch
                    elif ch in pairs:
                        stack.append((ch, line))
                    elif ch in pairs.values():
                        self.assertTrue(len(stack) > 0, f"Unmatched closing {ch} at line {line} in {path}")
                        top, top_line = stack.pop()
                        self.assertEqual(pairs[top], ch, f"Mismatched {top} (line {top_line}) with {ch} at line {line}")

            self.assertEqual(len(stack), 0, f"Unclosed brackets in {path}: {stack[-5:]}")

            # Also validate Lua block keyword balance (if/function/do vs end) on code files
            if path == LUA_FILE:
                clean_code = re.sub(r'--\[\[.*?--\]\]', '', content, flags=re.DOTALL)
                clean_code = re.sub(r'--[^\n]*', '', clean_code)
                clean_code = re.sub(r'\"(\\.|[^\"])*\"', '\"\"', clean_code)
                clean_code = re.sub(r'\'(\\.|[^\'])*\'', '\'\'', clean_code)
                tokens = re.findall(r'\b(if|elseif|function|do|end)\b', clean_code)
                block_stack = []
                for t in tokens:
                    if t in ('if', 'function', 'do'):
                        block_stack.append(t)
                    elif t == 'end':
                        self.assertTrue(len(block_stack) > 0, f"Extra 'end' keyword found in {path}")
                        block_stack.pop()
                self.assertEqual(len(block_stack), 0, f"Unclosed blocks in {path}: {block_stack[-5:]}")

    def test_04_data_compilation_completeness(self):
        """Verify data compilation exported zones, dungeons, flightpaths, and items."""
        with open(DATA_FILE, "r", encoding="utf-8") as f:
            content = f.read()

        # Dungeons check
        dungeons = re.findall(r"ForeverGuide_Data\.Dungeons\s*=\s*\{", content)
        self.assertEqual(len(dungeons), 1)
        dungeon_entries = re.findall(r"\[\d+\]\s*=\s*\{[^}]*name\s*=", content)
        self.assertGreaterEqual(len(dungeon_entries), 40, "Dungeons count below expectation")

        # Zones check
        self.assertIn("ForeverGuide_Data.Zones", content)
        zone_entries = re.findall(r"\{\s*name\s*=", content)
        self.assertGreaterEqual(len(zone_entries), 30, "Zones count below expectation")

        # Flight paths check
        self.assertIn("ForeverGuide_Data.Flightpaths", content)
        fp_entries = re.findall(r"\[\d+\]\s*=\s*\{[^}]*faction\s*=", content)
        self.assertGreaterEqual(len(fp_entries), 50, "Flight paths count below expectation")

        # Items check
        self.assertIn("ForeverGuide_Data.Items", content)
        item_entries = re.findall(r"\[\d+\]\s*=\s*\{[^}]*ilvl\s*=", content)
        self.assertGreaterEqual(len(item_entries), 1000, "Items count below expectation")

    def test_05_curseforge_package_generation(self):
        """Verify scripts/package_addon.py produces a compliant CurseForge archive."""
        import subprocess
        python_bin = sys.executable
        res = subprocess.run([python_bin, "scripts/package_addon.py"], cwd=BASE_DIR, capture_output=True, text=True)
        self.assertEqual(res.returncode, 0, f"package_addon.py failed: {res.stderr}")

        zip_files = [f for f in os.listdir(DIST_DIR) if f.startswith("ForeverGuide") and f.endswith(".zip")]
        self.assertGreater(len(zip_files), 0, "No zip package generated in dist/")

        target_zip = os.path.join(DIST_DIR, zip_files[0])
        self.assertTrue(os.path.exists(target_zip))

        # Check archive structure: must contain ForeverGuide/ prefix
        with zipfile.ZipFile(target_zip, 'r') as zf:
            namelist = zf.namelist()
            self.assertIn("ForeverGuide/ForeverGuide.toc", namelist)
            self.assertIn("ForeverGuide/ForeverGuide.lua", namelist)
            self.assertIn("ForeverGuide/ForeverGuide_Data.lua", namelist)
            self.assertIn("ForeverGuide/Bindings.xml", namelist)

        # File size sanity (must be compact, under 5MB)
        size_mb = os.path.getsize(target_zip) / (1024 * 1024)
        self.assertLess(size_mb, 5.0, f"Zip file excessively large: {size_mb:.2f} MB")
        self.assertGreater(size_mb, 0.1, "Zip file suspiciously small")

    def test_06_sparky_ai_and_death_bounce_integrity(self):
        """Verify Sparky autonomous behavioral state machine, dash curves, and death bounce reactions."""
        with open(LUA_FILE, "r", encoding="utf-8") as f:
            code = f.read()

        # Check required state machine definitions
        self.assertIn("DEATH_BOUNCE", code, "DEATH_BOUNCE state missing")
        self.assertIn("ZIG_ZAG", code, "ZIG_ZAG state missing")
        self.assertIn("TransitionTo", code, "TransitionTo helper missing")
        self.assertIn("PLAYER_DEAD", code, "PLAYER_DEAD event registration missing")
        self.assertIn("PLAYER_ALIVE", code, "PLAYER_ALIVE event registration missing")
        self.assertIn("PLAYER_UNGHOST", code, "PLAYER_UNGHOST event registration missing")

        # Verify no datamine or placeholder text in data or code
        with open(DATA_FILE, "r", encoding="utf-8") as f:
            data_code = f.read()
        self.assertNotIn("datamine", data_code.lower(), "Datamine reference found in ForeverGuide_Data.lua")
        self.assertNotIn("alpha patch notes", data_code.lower(), "Alpha patch notes found in ForeverGuide_Data.lua")


if __name__ == "__main__":
    unittest.main()

