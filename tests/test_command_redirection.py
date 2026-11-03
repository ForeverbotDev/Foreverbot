#!/usr/bin/env python3
"""Unit and Integration Tests for Intelligent Slash Command Redirection.

Verifies that queries passed to the wrong slash command are accurately redirected
to the correct slash command by text, with clear guidance, syntax examples, and
contextual in-game hints (e.g. lost player navigation).
"""

import os
import sys
import unittest
import asyncio
from unittest.mock import AsyncMock, MagicMock

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

import discord
from redirection import get_command_redirection_advice
import bot

# ---------------------------------------------------------------------------
# Suite 1: Pure Redirection Engine Logic Tests
# ---------------------------------------------------------------------------
class TestRedirectionEngine(unittest.TestCase):
    def test_lost_player_duskwood_to_ask(self):
        query = "where am i? dark forest, wovles and skeletons, im trying to find stormwind"
        advice = get_command_redirection_advice(query, "map")
        self.assertIsNotNone(advice)
        self.assertEqual(advice["suggested_command"], "ask")
        self.assertIn("Duskwood", advice["full_text"])
        self.assertIn("North", advice["full_text"])
        self.assertIn("Elwynn Forest", advice["full_text"])
        self.assertIn("Stormwind", advice["full_text"])
        self.assertIn("👉 **Try:** `/ask", advice["full_text"])

    def test_conversational_question_to_ask(self):
        query = "how do I get to Darnassus from Stormwind?"
        advice = get_command_redirection_advice(query, "mob")
        self.assertIsNotNone(advice)
        self.assertEqual(advice["suggested_command"], "ask")
        self.assertIn("👉 **Try:** `/ask", advice["full_text"])

    def test_raid_boss_in_item_command(self):
        advice = get_command_redirection_advice("Baron Geddon", "item")
        self.assertIsNotNone(advice)
        self.assertIn(advice["suggested_command"], ("raid", "mob"))
        self.assertIn("Baron Geddon", advice["full_text"])
        self.assertIn("not an item!", advice["full_text"])

    def test_creature_in_item_command(self):
        advice = get_command_redirection_advice("Hogger", "item")
        self.assertIsNotNone(advice)
        self.assertIn(advice["suggested_command"], ("mob", "raid"))
        self.assertIn("Hogger", advice["full_text"])

    def test_item_in_mob_command(self):
        advice = get_command_redirection_advice("Thunderfury", "mob")
        self.assertIsNotNone(advice)
        self.assertEqual(advice["suggested_command"], "item")
        self.assertIn("Thunderfury", advice["full_text"])
        self.assertIn("not a mob!", advice["full_text"])

    def test_quest_in_item_command(self):
        advice = get_command_redirection_advice("In Dreams", "item")
        self.assertIsNotNone(advice)
        self.assertEqual(advice["suggested_command"], "quest")
        self.assertIn("In Dreams", advice["full_text"])
        self.assertIn("Western Plaguelands", advice["full_text"])

    def test_dungeon_in_map_command(self):
        advice = get_command_redirection_advice("Scarlet Monastery", "map")
        self.assertIsNotNone(advice)
        self.assertEqual(advice["suggested_command"], "dungeons")
        self.assertIn("dungeon", advice["full_text"])

    def test_zone_in_dungeons_command(self):
        advice = get_command_redirection_advice("Duskwood", "dungeons")
        self.assertIsNotNone(advice)
        self.assertEqual(advice["suggested_command"], "map")
        self.assertIn("zone/region", advice["full_text"])

    def test_flightpath_in_map_command(self):
        advice = get_command_redirection_advice("Ironforge to Light's Hope", "map")
        self.assertIsNotNone(advice)
        self.assertEqual(advice["suggested_command"], "flightpath")
        self.assertIn("`/flightpath", advice["full_text"])

    def test_weapon_comparison_in_item_command(self):
        advice = get_command_redirection_advice("Viskag vs Brutality Blade", "item")
        self.assertIsNotNone(advice)
        self.assertEqual(advice["suggested_command"], "compare")
        self.assertIn("`/compare", advice["full_text"])

    def test_bis_query_in_item_command(self):
        advice = get_command_redirection_advice("best in slot warrior", "item")
        self.assertIsNotNone(advice)
        self.assertEqual(advice["suggested_command"], "bis")
        self.assertIn("`/bis query:Warrior", advice["full_text"])

    def test_talents_query_in_item_command(self):
        advice = get_command_redirection_advice("warrior talents", "item")
        self.assertIsNotNone(advice)
        self.assertEqual(advice["suggested_command"], "build")
        self.assertTrue("`/build" in advice["full_text"] or "`/talents" in advice["full_text"])

    def test_attunement_query_in_dungeons_command(self):
        advice = get_command_redirection_advice("Onyxia attunement", "dungeons")
        self.assertIsNotNone(advice)
        self.assertEqual(advice["suggested_command"], "attunement")
        self.assertIn("`/attunement query:Onyxia", advice["full_text"])

    def test_gathering_node_in_item_command(self):
        advice = get_command_redirection_advice("Thorium Vein", "item")
        self.assertIsNotNone(advice)
        self.assertEqual(advice["suggested_command"], "gather")
        self.assertIn("`/gather query:", advice["full_text"])

    def test_profession_in_item_command(self):
        advice = get_command_redirection_advice("Blacksmithing", "item")
        self.assertIsNotNone(advice)
        self.assertEqual(advice["suggested_command"], "profession")
        self.assertIn("`/profession query:Blacksmithing", advice["full_text"])

    def test_gdkp_in_item_command(self):
        advice = get_command_redirection_advice("gdkp 25000", "item")
        self.assertIsNotNone(advice)
        self.assertEqual(advice["suggested_command"], "gdkp")
        self.assertIn("`/gdkp query:25000", advice["full_text"])

    def test_resistance_in_item_command(self):
        advice = get_command_redirection_advice("Fire resist", "item")
        self.assertIsNotNone(advice)
        self.assertEqual(advice["suggested_command"], "resist")
        self.assertIn("`/resist query:Fire", advice["full_text"])


# ---------------------------------------------------------------------------
# Suite 2: Discord Bot Slash Command Handler Integration Tests
# ---------------------------------------------------------------------------
class TestBotCommandHandlerRedirection(unittest.IsolatedAsyncioTestCase):
    async def _invoke(self, cmd, interaction, **kwargs):
        actual_fn = cmd.callback if hasattr(cmd, "callback") else cmd
        return await actual_fn(interaction, **kwargs)

    async def test_map_command_redirects_lost_player(self):
        interaction = MagicMock(spec=discord.Interaction)
        interaction.response = MagicMock()
        interaction.response.defer = AsyncMock()
        interaction.followup = MagicMock()
        interaction.followup.send = AsyncMock()

        query = "where am i? dark forest, wovles and skeletons, im trying to find stormwind"
        await self._invoke(bot.map_command, interaction, query=query)

        interaction.response.defer.assert_called_once_with(ephemeral=True)
        interaction.followup.send.assert_called_once()
        _, kwargs = interaction.followup.send.call_args
        embed = kwargs.get("embed")
        self.assertIsNotNone(embed)
        self.assertIn("Did you mean to use `/ask`?", embed.title)
        self.assertIn("Duskwood", embed.description)
        self.assertIn("Elwynn Forest", embed.description)

    async def test_item_command_redirects_creature(self):
        interaction = MagicMock(spec=discord.Interaction)
        interaction.response = MagicMock()
        interaction.response.defer = AsyncMock()
        interaction.followup = MagicMock()
        interaction.followup.send = AsyncMock()

        await self._invoke(bot.item_command, interaction, query="Baron Geddon")

        interaction.followup.send.assert_called_once()
        _, kwargs = interaction.followup.send.call_args
        embed = kwargs.get("embed")
        self.assertIsNotNone(embed)
        self.assertIn("Did you mean to use", embed.title)
        self.assertIn("Baron Geddon", embed.description)

    async def test_mob_command_redirects_item(self):
        interaction = MagicMock(spec=discord.Interaction)
        interaction.response = MagicMock()
        interaction.response.defer = AsyncMock()
        interaction.followup = MagicMock()
        interaction.followup.send = AsyncMock()

        await self._invoke(bot.mob_command, interaction, query="Ashkandi")

        interaction.followup.send.assert_called_once()
        _, kwargs = interaction.followup.send.call_args
        embed = kwargs.get("embed")
        self.assertIsNotNone(embed)
        self.assertIn("Did you mean to use `/item`?", embed.title)
        self.assertIn("Ashkandi", embed.description)

    async def test_quest_command_redirects_item(self):
        interaction = MagicMock(spec=discord.Interaction)
        interaction.response = MagicMock()
        interaction.response.defer = AsyncMock()
        interaction.followup = MagicMock()
        interaction.followup.send = AsyncMock()

        await self._invoke(bot.quest_command, interaction, query="Lionheart Helm")

        interaction.followup.send.assert_called_once()
        _, kwargs = interaction.followup.send.call_args
        embed = kwargs.get("embed")
        self.assertIsNotNone(embed)
        self.assertIn("Did you mean to use `/item`?", embed.title)

    async def test_dungeons_command_redirects_zone(self):
        interaction = MagicMock(spec=discord.Interaction)
        interaction.response = MagicMock()
        interaction.response.defer = AsyncMock()
        interaction.followup = MagicMock()
        interaction.followup.send = AsyncMock()

        await self._invoke(bot.dungeons_command, interaction, query="Duskwood")

        interaction.followup.send.assert_called_once()
        _, kwargs = interaction.followup.send.call_args
        embed = kwargs.get("embed")
        self.assertIsNotNone(embed)
        self.assertIn("Did you mean to use `/map`?", embed.title)
        self.assertIn("Duskwood", embed.description)


if __name__ == "__main__":
    unittest.main()
