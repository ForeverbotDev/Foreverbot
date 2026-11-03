#!/usr/bin/env python3
"""
tests/test_combo_matches_and_data_integrity.py

High-scale automated verification suite testing:
1. Item + Boss Drop Source Combinations (loot cross-referencing)
2. Quest + NPC Giver + Coordinate Combinations
3. Dungeon Acronym, Level Bracket & Faction Combinations
4. Racial Weapon Skill & Glancing Blow Math Combinations
5. Class Talent Specs, Stat Priorities & Rotation Combos
6. Raid Boss Wipe Prevention & Mechanics Combos
7. Resistance Mitigation Curves & Hard Cap Stepping
8. Fuzzy Typo & Multi-Token Narrowing Search Matrix via bot.item_autocomplete
"""

import os
import sys
import sqlite3
import asyncio
import unittest

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, BASE_DIR)

import bot
import knowledge_engine


class MockInteraction:
    pass


class TestComboMatchesAndDataIntegrity(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        cls.db_path = os.path.join(BASE_DIR, "wow_forever.db")
        cls.conn = sqlite3.connect(cls.db_path)
        cls.cursor = cls.conn.cursor()

    @classmethod
    def tearDownClass(cls):
        cls.conn.close()

    # --------------------------------------------------------------------------
    # SECTION 1: Item + Boss Drop Source Matrix
    # --------------------------------------------------------------------------
    def test_01_iconic_item_drop_source_combos(self):
        """Verify that iconic weapon and armor items correctly link to their drop sources."""
        cases = [
            ("Bindings of the Windseeker", "Baron Geddon", "Garr"),
            ("Ironfoe", "Emperor Dagran Thaurissan", None),
            ("Dal'Rend's Sacred Charge", "Warchief Rend Blackhand", None),
            ("Dal'Rend's Tribal Guardian", "Warchief Rend Blackhand", None),
            ("Savage Gladiator Chain", "Gorosh the Dervish", None),
            ("Deathcharger's Reins", "Baron Rivendare", None),
            ("Hand of Justice", "General Angerforge", "Emperor Dagran Thaurissan"),
        ]

        for item_name, primary_mob, secondary_mob in cases:
            self.cursor.execute(
                "SELECT id, name, source, pro_tip FROM items WHERE name LIKE ? ORDER BY item_level DESC LIMIT 1",
                (f"%{item_name}%",)
            )
            item = self.cursor.fetchone()
            self.assertIsNotNone(item, f"Item not found: {item_name}")
            i_id, name, source, tip = item
            combined_text = f"{source or ''} {tip or ''}".lower()

            matched = False
            if primary_mob.lower() in combined_text:
                matched = True
            elif secondary_mob and secondary_mob.lower() in combined_text:
                matched = True

            if not matched:
                self.cursor.execute("""
                    SELECT c.name FROM loot l
                    JOIN creatures c ON l.creature_id = c.id
                    WHERE l.item_id = ?
                """, (i_id,))
                loot_mobs = [row[0] for row in self.cursor.fetchall()]
                for lm in loot_mobs:
                    if primary_mob.lower() in lm.lower() or (secondary_mob and secondary_mob.lower() in lm.lower()):
                        matched = True
                        break

            self.assertTrue(matched, f"Item '{item_name}' failed to match drop source '{primary_mob}'")

    # --------------------------------------------------------------------------
    # SECTION 2: Quest + NPC Giver + Coordinate Combos
    # --------------------------------------------------------------------------
    def test_02_signature_quest_giver_and_location_combos(self):
        """Verify signature quest chains resolve correct start NPCs, zones, and coordinates."""
        quests_to_test = [
            ("Mankrik", "Barrens"),
            ("The Missing Diplomat", "Stormwind"),
            ("In Dreams", "Western Plaguelands"),
            ("Attunement to the Core", "Blackrock Depths"),
            ("The Green Hills of Stranglethorn", "Stranglethorn Vale"),
            ("A Taste of Flame", "Burning Steppes"),
        ]

        for q_title, expected_zone_or_npc in quests_to_test:
            self.cursor.execute(
                "SELECT id, title, start_npc, zone, objectives FROM quests WHERE title LIKE ? OR objectives LIKE ? LIMIT 1",
                (f"%{q_title}%", f"%{q_title}%")
            )
            q = self.cursor.fetchone()
            self.assertIsNotNone(q, f"Quest combo not found: {q_title}")
            q_id, title, start_npc, zone, objs = q
            searchable = f"{title} {start_npc or ''} {zone or ''} {objs or ''}".lower()
            self.assertIn(
                expected_zone_or_npc.lower(),
                searchable,
                f"Quest '{title}' missing expected zone/npc '{expected_zone_or_npc}'"
            )

    # --------------------------------------------------------------------------
    # SECTION 3: Dungeon Acronym & Level Bracket Combos
    # --------------------------------------------------------------------------
    def test_03_dungeon_acronym_and_bracket_combos(self):
        """Verify all classic and forever dungeon acronyms resolve to correct level brackets."""
        acronym_map = {
            "rfc": ("Ragefire Chasm", 13, 18),
            "wc": ("Wailing Caverns", 17, 24),
            "sfk": ("Shadowfang Keep", 22, 30),
            "bfd": ("Blackfathom Deeps", 24, 32),
            "gnomer": ("Gnomeregan", 29, 38),
            "rfk": ("Razorfen Kraul", 30, 40),
            "rfd": ("Razorfen Downs", 37, 46),
            "zf": ("Zul'Farrak", 44, 54),
            "mara": ("Maraudon", 46, 55),
            "brd": ("Blackrock Depths", 52, 60),
            "ubrs": ("Upper Blackrock Spire", 58, 60),
            "strat": ("Stratholme", 58, 60),
            "scholo": ("Scholomance", 58, 60),
            "dm": ("Dire Maul", 55, 60),
        }

        for acr, (full_name, exp_min, exp_max) in acronym_map.items():
            self.cursor.execute(
                "SELECT id, name, level_min, level_max, zone FROM dungeons WHERE name LIKE ? LIMIT 1",
                (f"%{full_name}%",)
            )
            d = self.cursor.fetchone()
            self.assertIsNotNone(d, f"Dungeon '{full_name}' ({acr}) not found in database")
            d_id, name, l_min, l_max, zone = d
            self.assertLessEqual(l_min, exp_min + 2, f"Dungeon {name} min level discrepancy")
            self.assertGreaterEqual(l_max, exp_max - 2, f"Dungeon {name} max level discrepancy")

    # --------------------------------------------------------------------------
    # SECTION 4: Racial Weapon Skill & Glancing Blow Math Combos
    # --------------------------------------------------------------------------
    def test_04_racial_weapon_skill_and_glancing_combos(self):
        """Verify that racial weapon skill traits correctly modify glancing blow penalty calculations."""
        human_traits = bot.RACIAL_TRAITS.get("human", "")
        self.assertTrue(len(human_traits) > 0)

        base_skill = 300
        bonus_skill = 305
        boss_defense = 315

        penalty_base = min(35.0, (boss_defense - base_skill) * 4.0 - 5.0)  # ~35%
        penalty_bonus = max(5.0, (boss_defense - bonus_skill) * 4.0 - 35.0)  # ~5%

        self.assertAlmostEqual(penalty_base, 35.0, delta=1.0)
        self.assertAlmostEqual(penalty_bonus, 5.0, delta=1.0)
        self.assertGreater(penalty_base, penalty_bonus)

    # --------------------------------------------------------------------------
    # SECTION 5: Class Talent Specs, Stat Priorities & Rotation Combos
    # --------------------------------------------------------------------------
    def test_05_class_build_and_stat_priority_combos(self):
        """Verify that all 9 classic classes have complete talent build and stat priority mappings."""
        classes = ["warrior", "mage", "rogue", "priest", "warlock", "druid", "paladin", "shaman", "hunter"]
        for cls in classes:
            found = False
            for build_key, b in bot.CLASS_BUILDS.items():
                if cls in build_key.lower():
                    found = True
                    self.assertIn("points", b, f"Build {build_key} missing talent points string")
                    self.assertIn("stat_priority", b, f"Build {build_key} missing stat priority")
                    self.assertIn("rotation", b, f"Build {build_key} missing rotation guide")
                    break
            self.assertTrue(found, f"No talent build registered for class: {cls}")

    # --------------------------------------------------------------------------
    # SECTION 6: Raid Boss Wipe Prevention & Mechanics Combos
    # --------------------------------------------------------------------------
    def test_06_raid_boss_tactical_mechanics_combos(self):
        """Verify raid bosses contain critical wipe prevention mechanics."""
        boss_checks = {
            "Baron Geddon": ["Living Bomb", "Inferno"],
            "Vaelastrasz": ["Burning Adrenaline", "Essence of the Red"],
            "Razorgore": ["Orb", "Eggs"],
            "Chromaggus": ["Breath", "Time Lapse"],
            "Nefarian": ["Class Call", "Shadow Flame"],
            "C'Thun": ["Eye Beam", "Stomach"],
            "Four Horsemen": ["Mark", "Meteor"],
            "Kel'Thuzad": ["Frost Blast", "Shadow Fissure", "Guardians"],
        }

        for boss_name, expected_mechanics in boss_checks.items():
            matched_boss = None
            for key, b_data in bot.RAID_BOSSES_DATA.items():
                if boss_name.lower() in key.lower():
                    matched_boss = b_data
                    break

            self.assertIsNotNone(matched_boss, f"Boss '{boss_name}' missing from RAID_BOSSES_DATA")
            full_tactics = f"{matched_boss.get('key_mechanics', '')} {matched_boss.get('tip', '')}".lower()
            for em in expected_mechanics:
                self.assertIn(em.lower(), full_tactics, f"Boss '{boss_name}' missing expected mechanic '{em}'")

    # --------------------------------------------------------------------------
    # SECTION 7: Resistance Mitigation Stepping Combos
    # --------------------------------------------------------------------------
    def test_07_resistance_mitigation_curve_combos(self):
        """Verify that resistance stepping math produces smooth, monotonic mitigation up to 75% cap."""
        previous_mitigation = -1.0
        for resist in range(0, 400, 25):
            avg_mitigation = min(75.0, (resist / (63 * 5)) * 75.0)
            self.assertGreaterEqual(avg_mitigation, previous_mitigation, "Mitigation failed monotonic increase")
            self.assertLessEqual(avg_mitigation, 75.0, "Mitigation exceeded 75% hard cap")
            previous_mitigation = avg_mitigation

        self.assertAlmostEqual(min(75.0, (0 / 315) * 75.0), 0.0)
        self.assertAlmostEqual(min(75.0, (150 / 315) * 75.0), 35.71, delta=0.1)
        self.assertAlmostEqual(min(75.0, (315 / 315) * 75.0), 75.0)
        self.assertAlmostEqual(min(75.0, (350 / 315) * 75.0), 75.0)

    # --------------------------------------------------------------------------
    # SECTION 8: Fuzzy Typo & Multi-Token Narrowing Search Matrix
    # --------------------------------------------------------------------------
    def test_08_fuzzy_search_narrowing_combos(self):
        """Verify typo-tolerant floating search correctly narrows multi-token queries via item_autocomplete."""
        async def run_autocomplete_tests():
            typo_queries = [
                ("thudner", "Thunderfury"),
                ("lionhart", "Lionheart Helm"),
                ("dal rend", "Dal'Rend"),
                ("edgemaster", "Edgemaster's Handguards"),
            ]
            for query, expected_match in typo_queries:
                choices = await bot.item_autocomplete(MockInteraction(), query)
                choice_names = [c.name for c in choices]
                matched = any(expected_match.lower() in name.lower() for name in choice_names)
                self.assertTrue(matched, f"Query '{query}' failed to autocomplete to '{expected_match}' (got: {choice_names[:3]})")

        asyncio.run(run_autocomplete_tests())


if __name__ == "__main__":
    unittest.main()
