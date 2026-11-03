"""Unit and integration test suite for Tuesday Weekly Intel & Database Sync."""

import os
import sys
import unittest
from unittest.mock import MagicMock, AsyncMock

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from scripts.tuesday_weekly_intel_sync import (
    fetch_latest_forum_intel,
    compile_bis_meta_shifts,
    compile_weekly_lockouts_and_prep,
    generate_intel_markdown,
    update_whole_database,
)
import bot


class TestTuesdayWeeklyIntel(unittest.TestCase):
    def test_fetch_intel_structure(self):
        intel = fetch_latest_forum_intel()
        self.assertIn("official_notes", intel)
        self.assertIn("developer_comments", intel)
        self.assertIn("stealth_changes", intel)
        self.assertTrue(len(intel["stealth_changes"]) >= 2)

    def test_bis_shifts_content(self):
        shifts = compile_bis_meta_shifts()
        self.assertTrue(len(shifts) >= 5)
        classes = [s["class"] for s in shifts]
        self.assertTrue(any("Warrior" in c for c in classes))
        self.assertTrue(any("Mage" in c for c in classes))
        self.assertTrue(any("Rogue" in c for c in classes))

    def test_weekly_lockouts_and_prep(self):
        lockouts = compile_weekly_lockouts_and_prep()
        self.assertIn("weekly_resets", lockouts)
        self.assertIn("active_raids", lockouts)
        self.assertIn("consumable_checklist", lockouts)
        self.assertTrue(len(lockouts["active_raids"]) >= 4)
        raids = [r["raid"] for r in lockouts["active_raids"]]
        self.assertIn("Molten Core", raids)

    def test_generate_intel_markdown(self):
        intel = fetch_latest_forum_intel()
        shifts = compile_bis_meta_shifts()
        lockouts = compile_weekly_lockouts_and_prep()
        md = generate_intel_markdown(intel, shifts, lockouts)
        self.assertIn("Tuesday Night Intel & Meta Briefing", md)
        self.assertIn("Developer Comments", md)
        self.assertIn("Best-in-Slot (BiS) & Class Meta Shifts", md)
        self.assertIn("Weekly Raid Lockouts", md)

    def test_database_update_dry_run(self):
        intel = fetch_latest_forum_intel()
        stats = update_whole_database(intel, dry_run=True)
        self.assertEqual(stats.get("status"), "dry_run")

    def test_bot_intel_command_registered(self):
        # Verify /intel command is registered in bot tree
        cmds = [cmd.name for cmd in bot.bot.tree.get_commands()]
        self.assertIn("intel", cmds)
        self.assertEqual(len(cmds), 42)


if __name__ == "__main__":
    unittest.main()
