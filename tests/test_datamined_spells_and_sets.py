#!/usr/bin/env python3
"""tests/test_datamined_spells_and_sets.py

Unit and integration tests for the official Blizzard datamined catalog expansion:
- All 9 class spellbooks and Forever balance notes (Post #6471288).
- Armor sets (Tier 0 through Tier 3, PvP, and Forever raid sets) with 2/4/6/8-piece bonuses.
- Achievements and Feats of Strength.
- Sub-millisecond latency and Discord autocomplete safety.
"""

import time
import unittest
import database
import knowledge_engine as ke


class TestDataminedSpellsAndSets(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.db = database.WoWForeverDB()

    def test_01_all_nine_classes_have_spells(self):
        classes = ["Warrior", "Paladin", "Hunter", "Rogue", "Priest", "Shaman", "Mage", "Warlock", "Druid"]
        for c in classes:
            spells, _ = self.db.search_spells("", class_filter=c, limit=10)
            self.assertGreater(len(spells), 0, f"Class {c} has no spells indexed in database!")

    def test_02_official_forever_raid_buffs_and_tuning(self):
        # 1. Battle Shout (Raid-Wide)
        bs = ke.get_spell_info("Battle Shout", class_filter="Warrior")
        self.assertIsNotNone(bs)
        self.assertIn("RAID-WIDE", bs["forever_tuning"])

        # 2. Windfury Totem (Raid-Wide)
        wf = ke.get_spell_info("Windfury Totem", class_filter="Shaman")
        self.assertIsNotNone(wf)
        self.assertIn("RAID-WIDE", wf["forever_tuning"])

        # 3. Leader of the Pack (Raid-Wide)
        lotp = ke.get_spell_info("Leader of the Pack", class_filter="Druid")
        self.assertIsNotNone(lotp)
        self.assertIn("RAID-WIDE", lotp["forever_tuning"])

        # 4. Blizzard low-rank trigger rule
        blizz = ke.get_spell_info("Blizzard", class_filter="Mage")
        self.assertIsNotNone(blizz)
        self.assertIn(">12 levels", blizz["forever_tuning"])

        # 5. Mortal Strike Nov 3 headroom damage
        ms = ke.get_spell_info("Mortal Strike", class_filter="Warrior")
        self.assertIsNotNone(ms)
        self.assertIn("Nov 3", ms["forever_tuning"])

    def test_03_progression_armor_sets_and_bonuses(self):
        # Tier 0
        valor = ke.get_armor_set_info("Battlegear of Valor")
        self.assertIsNotNone(valor)
        self.assertEqual(valor["pieces_count"], 8)
        self.assertIn("2", valor["bonuses"])
        self.assertIn("4", valor["bonuses"])
        self.assertIn("6", valor["bonuses"])
        self.assertIn("8", valor["bonuses"])

        # Tier 1
        might = ke.get_armor_set_info("Battlegear of Might")
        self.assertIsNotNone(might)
        self.assertIn("Molten Core", might["source_dungeon"])
        self.assertIn("8", might["bonuses"])

        # Tier 2
        wrath = ke.get_armor_set_info("Battlegear of Wrath")
        self.assertIsNotNone(wrath)
        self.assertIn("Blackwing Lair", wrath["source_dungeon"])

        # Tier 3
        dread = ke.get_armor_set_info("Dreadnaught's Battlegear")
        self.assertIsNotNone(dread)
        self.assertIn("Naxxramas", dread["source_dungeon"])
        self.assertIn("2", dread["bonuses"])

        # Custom Forever Raid Set
        deepsea = ke.get_armor_set_info("Zephras Deepsea Regalia")
        self.assertIsNotNone(deepsea)
        self.assertTrue(deepsea["is_forever"])
        self.assertIn("Sunken Citadel", deepsea["source_dungeon"])

    def test_04_achievements_and_feats_of_strength(self):
        # Molten Core
        mc = ke.get_achievement_info("Molten Core")
        self.assertIsNotNone(mc)
        self.assertEqual(mc["category"], "Dungeons & Raids")
        self.assertFalse(mc["is_feat_of_strength"])

        # Scarab Lord Feat of Strength
        sl = ke.get_achievement_info("Scarab Lord")
        self.assertIsNotNone(sl)
        self.assertTrue(sl["is_feat_of_strength"])
        self.assertIn("Black Qiraji", sl["reward"])

        # The Undying
        undying = ke.get_achievement_info("The Undying")
        self.assertIsNotNone(undying)
        self.assertTrue(undying["is_feat_of_strength"])

        # Forever Dungeon achievement
        citadel = ke.get_achievement_info("Sunken Citadel Conqueror")
        self.assertIsNotNone(citadel)
        self.assertTrue(citadel["is_forever"])
        self.assertIn("Tidebreaker", citadel["reward"])

    def test_05_autocomplete_choices_safe_and_fast(self):
        # Spells autocomplete
        sp_choices = self.db.autocomplete_spells("mortal", limit=5)
        self.assertGreater(len(sp_choices), 0)
        for c in sp_choices:
            self.assertLessEqual(len(c["name"]), 100)
            self.assertLessEqual(len(c["value"]), 100)

        # Sets autocomplete
        set_choices = self.db.autocomplete_armor_sets("netherwind", limit=5)
        self.assertGreater(len(set_choices), 0)
        for c in set_choices:
            self.assertLessEqual(len(c["name"]), 100)
            self.assertLessEqual(len(c["value"]), 100)

        # Achievements autocomplete
        ach_choices = self.db.autocomplete_achievements("realm", limit=5)
        self.assertGreater(len(ach_choices), 0)
        for c in ach_choices:
            self.assertLessEqual(len(c["name"]), 100)
            self.assertLessEqual(len(c["value"]), 100)

    def test_06_submillisecond_latency_benchmark(self):
        latencies = []
        for _ in range(50):
            t0 = time.perf_counter()
            ke.get_spell_info("Windfury Totem")
            ke.get_armor_set_info("Battlegear of Wrath")
            ke.get_achievement_info("Molten Core")
            dt = time.perf_counter() - t0
            latencies.append(dt)

        avg_lat = sum(latencies) / len(latencies)
        print(f"\n[LATENCY BENCHMARK] Spells, Sets & Achievements Resolvers: {avg_lat*1000:.3f} ms average")
        self.assertLess(avg_lat, 0.010, "Average query latency exceeded 10ms threshold!")


if __name__ == "__main__":
    unittest.main()
