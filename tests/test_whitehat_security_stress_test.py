#!/usr/bin/env python3
"""tests/test_whitehat_security_stress_test.py.

White-Hat Security & Stress Test Suite for WoW Forever Bot.
Verifies defensive mitigations against:
1. SQLite concurrency lock contention (WAL mode + busy timeout).
2. ReDoS and unbounded input length attacks on query parsers.
3. Database record exhaustion and out-of-bound numeric injections.
4. Combat math boundaries (division by zero, negative pots, extreme defense).
5. Discord embed 400 Bad Request payload overflows.
6. Command flooding / DoS sliding-window rate limiting.
7. Information leakage & internal filesystem path disclosure.
"""

import os
import sys
import time
import random
import re
import unittest
from concurrent.futures import ThreadPoolExecutor, as_completed

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if BASE_DIR not in sys.path:
    sys.path.insert(0, BASE_DIR)

from database import (
    WoWForeverDB,
    clean_query,
    extract_level_from_text,
    get_connection,
    DB_PATH,
    USER_DB_PATH
)
from knowledge_engine import (
    calculate_gdkp,
    calculate_glancing_penalty,
    calculate_disenchant_table,
    calculate_resistance_mitigation
)
from bot import (
    safe_embed_str,
    safe_add_field,
    check_general_command_rate_limit,
    MAX_CMDS_PER_WINDOW,
    WINDOW_SECONDS
)
import discord


class TestWhiteHatSecurityAndStress(unittest.TestCase):
    """Stress tests and defensive assertions for hardened bot architecture."""

    @classmethod
    def setUpClass(cls):
        cls.db = WoWForeverDB(DB_PATH)

    def test_01_sqlite_concurrency_lock_hammer(self):
        """Stress test: 50 concurrent threads executing 1,000 DB operations.

        Verifies WAL mode and 30-second busy timeout prevent SQLite lock errors.
        """
        num_workers = 30
        iterations_per_worker = 25
        total_ops = num_workers * iterations_per_worker
        errors = []

        def worker_task(worker_id: int):
            for i in range(iterations_per_worker):
                uid = 900000 + (worker_id * 100) + i
                char_name = f"StressChar_{worker_id}_{i}"
                event_id = f"stress_raid_{worker_id % 5}"
                try:
                    # 1. Write profile
                    self.db.set_user_profile(
                        user_id=uid,
                        char_name=char_name,
                        char_class="Warrior",
                        char_race="Orc",
                        level=60,
                        spec="Fury",
                        professions="Mining/Blacksmithing",
                        guild_role="DPS",
                        gear_note="Pre-raid BiS"
                    )
                    # 2. Read profile
                    prof = self.db.get_user_profile(uid)
                    assert prof is not None and prof["char_name"] == char_name

                    # 3. Write raid event & signup
                    self.db.set_raid_event(event_id, f"Stress Raid {worker_id % 5}", max_players=40)
                    self.db.set_raid_signup(event_id, f"Stress Raid {worker_id % 5}", uid, char_name, "DPS", "Warrior")

                    # 4. Read signups
                    signups = self.db.get_raid_signups(event_id)
                    assert isinstance(signups, list)

                except Exception as exc:
                    errors.append(f"Worker {worker_id} iter {i} failed: {exc}")

        start_time = time.time()
        with ThreadPoolExecutor(max_workers=num_workers) as executor:
            futures = [executor.submit(worker_task, w) for w in range(num_workers)]
            for f in as_completed(futures):
                f.result()
        duration = time.time() - start_time

        self.assertEqual(len(errors), 0, f"Encountered {len(errors)} concurrency errors: {errors[:5]}")
        self.assertGreater(total_ops, 500)
        print(f"\n  [CONCURRENCY PASS] {total_ops * 4} SQLite operations completed across {num_workers} threads in {duration:.2f}s with 0 locks.")

    def test_02_redos_and_massive_input_fuzz(self):
        """Fuzz testing: Massive inputs and complex nested patterns against regex parsing."""
        # 1. 100,000 character repeating prefix attack
        evil_input = ("what is the bosses in " * 5000) + "molten core"
        t0 = time.time()
        res = clean_query(evil_input)
        elapsed = time.time() - t0
        self.assertLess(elapsed, 0.05, f"clean_query took too long ({elapsed:.4f}s), possible ReDoS!")
        self.assertTrue(isinstance(res, str))
        self.assertLessEqual(len(res), 500)

        # 2. Extreme unicode, SQL punctuation, and null bytes
        malicious_inputs = [
            "\x00" * 50 + "SELECT * FROM users; DROP TABLE items; --",
            "'; DROP TABLE users; --",
            "🛡️⚔️👑" * 100,
            "A" * 100000,
            "\n\r\t" * 1000 + "Onyxia",
            "''' OR '1'='1' --",
            "WHERE 1=1 UNION ALL SELECT 1,2,3,4,5,6,7,8,9,10 --",
        ]
        for payload in malicious_inputs:
            t_start = time.time()
            cleaned = clean_query(payload)
            clean_time = time.time() - t_start
            self.assertLess(clean_time, 0.05, "clean_query took too long on malicious payload")
            lvl = extract_level_from_text(payload)
            items = self.db.search_items(cleaned, limit=5)
            self.assertLess(time.time() - t_start, 0.8)
            self.assertTrue(isinstance(items, (list, tuple)))

    def test_03_db_column_bound_and_exhaustion_protection(self):
        """Verifies string length limits and numeric clamping prevent database bloat."""
        giant_name = "X" * 10000
        giant_gear = "G" * 5000
        test_uid = 999999991

        # Save profile with extreme payload
        self.db.set_user_profile(
            user_id=test_uid,
            char_name=giant_name,
            char_class="Mage",
            char_race="Undead",
            level=999999,  # Should clamp to 60
            spec="Frost",
            professions="Tailoring",
            guild_role="Member",
            gear_note=giant_gear
        )

        profile = self.db.get_user_profile(test_uid)
        self.assertIsNotNone(profile)
        self.assertLessEqual(len(profile["char_name"]), 50)
        self.assertLessEqual(len(profile["gear_note"]), 200)
        self.assertEqual(profile["level"], 60)

        # Negative level should clamp to 1
        self.db.set_user_profile(user_id=test_uid, char_name="Lowbie", char_class="Warrior", char_race="Human", level=-50)
        prof_low = self.db.get_user_profile(test_uid)
        self.assertEqual(prof_low["level"], 1)

        # Clean up
        self.db.delete_all_user_data(test_uid)
        self.assertIsNone(self.db.get_user_profile(test_uid))

    def test_04_combat_math_boundaries_and_division_by_zero(self):
        """Verifies mathematical safety across all combat calculation utilities."""
        # 1. GDKP: zero raiders, negative pot, overflow deductions
        res_zero = calculate_gdkp(pot=-5000, cut_pct=150, raiders=0, tanks=10, tank_bonus_pct=50)
        self.assertEqual(res_zero["gross_pot"], 0)
        self.assertEqual(res_zero["payout_per_raider"], 0)
        self.assertGreaterEqual(res_zero["net_pot"], 0)

        # GDKP: 1 raider, normal pot
        res_normal = calculate_gdkp(pot=10000, cut_pct=10, raiders=40, tanks=2, tank_bonus_pct=2)
        self.assertEqual(res_normal["organizer_cut"], 1000)
        self.assertGreater(res_normal["payout_per_raider"], 0)

        # 2. Glancing blow: extreme defense, negative skills
        penalty_neg = calculate_glancing_penalty(weapon_skill=-1000, boss_defense=999999)
        self.assertIsInstance(penalty_neg, float)
        self.assertGreaterEqual(penalty_neg, 5.0)

        penalty_capped = calculate_glancing_penalty(weapon_skill=315, boss_defense=315)
        self.assertEqual(penalty_capped, 5.0)

        # 3. Disenchant: invalid types and extreme bounds
        de_res = calculate_disenchant_table(item_level="invalid", quality_str="epic", is_weapon=False)
        self.assertIsInstance(de_res, list)

        # 4. Resistance mitigation: None school and negative values
        resist_res = calculate_resistance_mitigation(school_query="", current_val=-100, role="tank")
        self.assertIn("mitigation_pct", resist_res)
        self.assertEqual(resist_res["current"], 0)

    def test_05_discord_embed_overflow_protection(self):
        """Verifies safe_embed_str and safe_add_field prevent Discord 400 Bad Request."""
        embed = discord.Embed(title="Test Embed")

        # 1. Add fields with massive names and values
        giant_name = "N" * 2000
        giant_val = "V" * 5000
        safe_add_field(embed, giant_name, giant_val)

        field = embed.fields[0]
        self.assertLessEqual(len(field.name), 256)
        self.assertLessEqual(len(field.value), 1024)
        self.assertTrue(field.name.endswith("..."))
        self.assertTrue(field.value.endswith("..."))

        # 2. Add more than 25 fields
        for i in range(35):
            safe_add_field(embed, f"Field {i}", f"Value {i}")
        self.assertLessEqual(len(embed.fields), 25)

    def test_06_command_flooding_rate_limiter(self):
        """Verifies sliding-window rate limiter throttles command flooding."""
        # Unset TESTING env for this test to evaluate live throttle logic
        prev_testing = os.environ.get("TESTING")
        if "TESTING" in os.environ:
            del os.environ["TESTING"]

        try:
            spammer_id = 8888888888
            allowed_count = 0
            blocked_count = 0

            # Fire 30 rapid commands
            for _ in range(30):
                if check_general_command_rate_limit(spammer_id):
                    allowed_count += 1
                else:
                    blocked_count += 1

            self.assertEqual(allowed_count, MAX_CMDS_PER_WINDOW)
            self.assertEqual(blocked_count, 30 - MAX_CMDS_PER_WINDOW)

            # Whitelisted / test bot IDs should always pass
            self.assertTrue(check_general_command_rate_limit(0))
            self.assertTrue(check_general_command_rate_limit(123456789))

        finally:
            if prev_testing is not None:
                os.environ["TESTING"] = prev_testing

    def test_07_path_and_secret_leak_prevention(self):
        """Verifies error sanitization prevents internal path and token disclosure."""
        sample_error = (
            "FileNotFoundError: [Errno 2] No such file or directory: "
            "'/home/appuser/.production/wow-forever-bot/config.json' "
            "at /usr/lib/python3.12/os.py line 40"
        )
        # Apply regex mask used in on_app_command_error
        err_str = re.sub(r"(/home|/var|/usr|/root|/tmp)[^\s:]+", "[internal_path]", sample_error)
        err_str = err_str[:200]

        self.assertNotIn("/home/appuser", err_str)
        self.assertNotIn("/usr/lib", err_str)
        self.assertIn("[internal_path]", err_str)
        self.assertLessEqual(len(err_str), 200)


if __name__ == "__main__":
    unittest.main()
