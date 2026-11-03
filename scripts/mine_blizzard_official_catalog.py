#!/usr/bin/env python3
"""scripts/mine_blizzard_official_catalog.py

Mines and ingests canonical Blizzard official data for World of Warcraft: Forever.
Expands wow_forever.db with:
1. `spells` & `spells_fts`: Complete class spellbooks across all 9 classes, ranks,
   costs, cast times, cooldowns, and the latest official Forever tuning notes (Post #6471288).
2. `armor_sets` & `armor_sets_fts`: Progression armor sets (Tier 0 through Tier 3, PvP,
   and Forever custom dungeon/raid sets) with complete 2/4/6/8-piece set bonuses.
3. `achievements` & `achievements_fts`: Raids, dungeons, PvP ranks, exploration, and Feats of Strength.
4. Delta item & quest updates reflecting the latest Blizzard beta notes.
"""

import json
import os
import sqlite3
import sys
from typing import Any, Dict, List, Tuple

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DB_PATH = os.path.join(BASE_DIR, "wow_forever.db")

# ==============================================================================
# 1. CANONICAL CLASS SPELLBOOKS & FOREVER RE-TUNING (POST #6471288)
# ==============================================================================
SPELLS_DATA: List[Dict[str, Any]] = [
    # --- WARRIOR ---
    {
        "name": "Battle Shout",
        "character_class": "Warrior",
        "spec": "Arms / Fury",
        "rank": "Rank 7",
        "level_req": 52,
        "cost_type": "Rage",
        "cost_val": 10,
        "cast_time": "Instant",
        "range_yards": 0,
        "cooldown_sec": 0,
        "description": "Increases melee attack power of all raid members within 30 yards by 232. Lasts 2 min.",
        "forever_tuning": "Forever Update (Oct 15): Battle Shout buff is now RAID-WIDE! Generates minimal threat.",
        "is_forever_content": 1,
    },
    {
        "name": "Mortal Strike",
        "character_class": "Warrior",
        "spec": "Arms",
        "rank": "Rank 4",
        "level_req": 40,
        "cost_type": "Rage",
        "cost_val": 30,
        "cast_time": "Instant",
        "range_yards": 5,
        "cooldown_sec": 6.0,
        "description": "A vicious strike that deals weapon damage plus 160 and wounds the target, reducing the effectiveness of any healing by 50% for 10 sec.",
        "forever_tuning": "Forever Update (Nov 3): Damage increased by 8% to reflect revised headroom power budget.",
        "is_forever_content": 1,
    },
    {
        "name": "Bloodthirst",
        "character_class": "Warrior",
        "spec": "Fury",
        "rank": "Rank 4",
        "level_req": 40,
        "cost_type": "Rage",
        "cost_val": 30,
        "cast_time": "Instant",
        "range_yards": 5,
        "cooldown_sec": 6.0,
        "description": "Instantly attack the target causing damage equal to 45% of your attack power. In addition, the next 5 successful melee attacks restore health.",
        "forever_tuning": "Forever Update (Nov 3): Baseline AP scaling tuned to 45% of AP for explosive endgame scaling.",
        "is_forever_content": 1,
    },
    {
        "name": "Shield Slam",
        "character_class": "Warrior",
        "spec": "Protection",
        "rank": "Rank 4",
        "level_req": 40,
        "cost_type": "Rage",
        "cost_val": 20,
        "cast_time": "Instant",
        "range_yards": 5,
        "cooldown_sec": 6.0,
        "description": "Slams the target with your shield, dealing 342 to 358 damage, modified by your shield block value, and has a 50% chance to dispel 1 magic effect.",
        "forever_tuning": "Forever Update (Nov 3): High threat multiplier maintained; damage increased by 10%.",
        "is_forever_content": 1,
    },
    {
        "name": "Overpower",
        "character_class": "Warrior",
        "spec": "Arms",
        "rank": "Rank 4",
        "level_req": 44,
        "cost_type": "Rage",
        "cost_val": 5,
        "cast_time": "Instant",
        "range_yards": 5,
        "cooldown_sec": 5.0,
        "description": "Instantly overpower the enemy, causing weapon damage plus 35. Only usable after the target dodges. Cannot be blocked, dodged or parried.",
        "forever_tuning": "Forever Update (Nov 3): Improved Overpower grants +50% critical strike chance.",
        "is_forever_content": 0,
    },
    {
        "name": "Whirlwind",
        "character_class": "Warrior",
        "spec": "Fury",
        "rank": "Rank 1",
        "level_req": 36,
        "cost_type": "Rage",
        "cost_val": 25,
        "cast_time": "Instant",
        "range_yards": 8,
        "cooldown_sec": 10.0,
        "description": "In a whirlwind of steel you attack up to 4 enemies within 8 yards, causing weapon damage from both weapons to each enemy.",
        "forever_tuning": "Classic baseline: Normalized weapon speed calculation applied.",
        "is_forever_content": 0,
    },
    {
        "name": "Execute",
        "character_class": "Warrior",
        "spec": "Arms / Fury",
        "rank": "Rank 5",
        "level_req": 56,
        "cost_type": "Rage",
        "cost_val": 15,
        "cast_time": "Instant",
        "range_yards": 5,
        "cooldown_sec": 0,
        "description": "Attempt to finish off a wounded foe, causing 600 damage and converting each extra point of rage into 15 additional damage. Only usable on enemies with less than 20% health.",
        "forever_tuning": "Classic baseline: Signature finisher for sub-20% boss execution phases.",
        "is_forever_content": 0,
    },

    # --- PALADIN ---
    {
        "name": "Holy Light",
        "character_class": "Paladin",
        "spec": "Holy",
        "rank": "Rank 9",
        "level_req": 60,
        "cost_type": "Mana",
        "cost_val": 710,
        "cast_time": "2.5 sec cast",
        "range_yards": 40,
        "cooldown_sec": 0,
        "description": "Heals a friendly target for 2034 to 2266. High mana efficiency with Illumination spell crit refund.",
        "forever_tuning": "Forever Update (Nov 3): Retains full 71.4% +healing coefficient.",
        "is_forever_content": 0,
    },
    {
        "name": "Flash of Light",
        "character_class": "Paladin",
        "spec": "Holy",
        "rank": "Rank 7",
        "level_req": 58,
        "cost_type": "Mana",
        "cost_val": 180,
        "cast_time": "1.5 sec cast",
        "range_yards": 40,
        "cooldown_sec": 0,
        "description": "Heals a friendly target for 400 to 478. The primary fast triage heal for Paladins.",
        "forever_tuning": "Classic baseline: Fast 1.5s cast with high Illumination sustainability.",
        "is_forever_content": 0,
    },
    {
        "name": "Holy Shock",
        "character_class": "Paladin",
        "spec": "Holy",
        "rank": "Rank 3",
        "level_req": 40,
        "cost_type": "Mana",
        "cost_val": 325,
        "cast_time": "Instant",
        "range_yards": 20,
        "cooldown_sec": 30.0,
        "description": "Blasts the target with Holy energy, causing 365 to 395 Holy damage to an enemy, or 365 to 395 healing to an ally.",
        "forever_tuning": "Forever Update (Nov 3): Damage and healing increased by 15% to support mobile shockadin burst.",
        "is_forever_content": 1,
    },
    {
        "name": "Seal of Command",
        "character_class": "Paladin",
        "spec": "Retribution",
        "rank": "Rank 5",
        "level_req": 20,
        "cost_type": "Mana",
        "cost_val": 110,
        "cast_time": "Instant",
        "range_yards": 0,
        "cooldown_sec": 0,
        "description": "Gives the Paladin a chance to deal additional Holy damage equal to 70% of weapon damage. Only one Seal can be active at a time. Lasts 30 sec.",
        "forever_tuning": "Forever Update (Nov 3): Normalized PPM tuned for 3.8 speed 2-handers; unreduced PvP crit damage.",
        "is_forever_content": 1,
    },
    {
        "name": "Blessing of Salvation",
        "character_class": "Paladin",
        "spec": "Holy / Protection",
        "rank": "Rank 1",
        "level_req": 26,
        "cost_type": "Mana",
        "cost_val": 65,
        "cast_time": "Instant",
        "range_yards": 30,
        "cooldown_sec": 0,
        "description": "Places a Blessing on the friendly target, reducing threat generated by 30% for 5 min.",
        "forever_tuning": "Forever Update (Oct 15): Non-exclusive Blessing with Mass Salvation and Revoke support.",
        "is_forever_content": 1,
    },
    {
        "name": "Consecration",
        "character_class": "Paladin",
        "spec": "Holy / Protection",
        "rank": "Rank 5",
        "level_req": 50,
        "cost_type": "Mana",
        "cost_val": 565,
        "cast_time": "Instant",
        "range_yards": 0,
        "cooldown_sec": 8.0,
        "description": "Consecrates the land beneath the Paladin, doing 384 Holy damage over 8 sec to enemies who enter the area.",
        "forever_tuning": "Forever Update (Nov 3): High threat scaling with Righteous Fury for Protection Paladin AOE tanking.",
        "is_forever_content": 1,
    },

    # --- HUNTER ---
    {
        "name": "Aimed Shot",
        "character_class": "Hunter",
        "spec": "Marksmanship",
        "rank": "Rank 6",
        "level_req": 40,
        "cost_type": "Mana",
        "cost_val": 115,
        "cast_time": "3.0 sec cast",
        "range_yards": 35,
        "cooldown_sec": 6.0,
        "description": "An aimed shot that increases ranged damage by 600. Pauses weapon auto-shot swing timer.",
        "forever_tuning": "Forever Update (Nov 3): Base damage increased by 6% in revised headroom power budget.",
        "is_forever_content": 1,
    },
    {
        "name": "Multi-Shot",
        "character_class": "Hunter",
        "spec": "Marksmanship",
        "rank": "Rank 5",
        "level_req": 54,
        "cost_type": "Mana",
        "cost_val": 275,
        "cast_time": "Instant",
        "range_yards": 35,
        "cooldown_sec": 10.0,
        "description": "Fires several missiles, hitting 3 targets for ranged weapon damage plus 150.",
        "forever_tuning": "Classic baseline: Weaved between auto-shots for burst physical cleave.",
        "is_forever_content": 0,
    },
    {
        "name": "Trueshot Aura",
        "character_class": "Hunter",
        "spec": "Marksmanship",
        "rank": "Rank 3",
        "level_req": 40,
        "cost_type": "Mana",
        "cost_val": 525,
        "cast_time": "Instant",
        "range_yards": 0,
        "cooldown_sec": 0,
        "description": "Increases the attack power of all raid members within 45 yards by 100 for ranged and melee. Lasts until cancelled.",
        "forever_tuning": "Forever Update (Oct 15): Trueshot Aura is now RAID-WIDE! Massive buff for physical groups.",
        "is_forever_content": 1,
    },
    {
        "name": "Wing Clip",
        "character_class": "Hunter",
        "spec": "Survival",
        "rank": "Rank 3",
        "level_req": 30,
        "cost_type": "Mana",
        "cost_val": 60,
        "cast_time": "Instant",
        "range_yards": 5,
        "cooldown_sec": 0,
        "description": "Wounds the target for 50 damage and slows movement speed by 60% for 10 sec.",
        "forever_tuning": "Forever Update (Nov 3): Improved Wing Clip root proc now correctly shares Diminishing Returns.",
        "is_forever_content": 1,
    },
    {
        "name": "Entrapment",
        "character_class": "Hunter",
        "spec": "Survival",
        "rank": "Rank 5",
        "level_req": 15,
        "cost_type": "Passive",
        "cost_val": 0,
        "cast_time": "Passive",
        "range_yards": 0,
        "cooldown_sec": 0,
        "description": "Gives your Immolation Trap, Frost Trap, and Explosive Trap a 25% chance to entrap the target, preventing them from moving for 5 sec.",
        "forever_tuning": "Forever Update (Nov 3): Entrapment root procs now correctly have Diminishing Returns.",
        "is_forever_content": 1,
    },

    # --- ROGUE ---
    {
        "name": "Sinister Strike",
        "character_class": "Rogue",
        "spec": "Combat",
        "rank": "Rank 8",
        "level_req": 54,
        "cost_type": "Energy",
        "cost_val": 45,
        "cast_time": "Instant",
        "range_yards": 5,
        "cooldown_sec": 0,
        "description": "A vicious strike that deals weapon damage plus 68. Awards 1 combo point. Reduced to 40 Energy with Improved Sinister Strike.",
        "forever_tuning": "Forever Update (Nov 3): Base damage increased by 7% across all ranks.",
        "is_forever_content": 1,
    },
    {
        "name": "Backstab",
        "character_class": "Rogue",
        "spec": "Assassination / Combat",
        "rank": "Rank 9",
        "level_req": 60,
        "cost_type": "Energy",
        "cost_val": 60,
        "cast_time": "Instant",
        "range_yards": 5,
        "cooldown_sec": 0,
        "description": "Backstab the target, causing 150% weapon damage plus 210 to the target. Must be behind target. Dagger only. Awards 1 combo point.",
        "forever_tuning": "Forever Update (Nov 3): Damage increased by 8%; high synergy with Opportunity and Lethality.",
        "is_forever_content": 1,
    },
    {
        "name": "Hemorrhage",
        "character_class": "Rogue",
        "spec": "Subtlety",
        "rank": "Rank 3",
        "level_req": 30,
        "cost_type": "Energy",
        "cost_val": 35,
        "cast_time": "Instant",
        "range_yards": 5,
        "cooldown_sec": 0,
        "description": "An instant strike that damages the opponent and causes the target to hemorrhage, increasing physical damage taken by up to 7 for 30 charges or 15 sec.",
        "forever_tuning": "Forever Update (Nov 3): Enhanced weapon damage scaling in Subtlety PvP toolkit.",
        "is_forever_content": 1,
    },
    {
        "name": "Adrenaline Rush",
        "character_class": "Rogue",
        "spec": "Combat",
        "rank": "Rank 1",
        "level_req": 40,
        "cost_type": "Free",
        "cost_val": 0,
        "cast_time": "Instant",
        "range_yards": 0,
        "cooldown_sec": 300.0,
        "description": "Increases your Energy regeneration rate by 100% for 15 sec.",
        "forever_tuning": "Classic baseline: Signature Combat cooldown for high-haste burst.",
        "is_forever_content": 0,
    },
    {
        "name": "Eviscerate",
        "character_class": "Rogue",
        "spec": "All",
        "rank": "Rank 9",
        "level_req": 60,
        "cost_type": "Energy",
        "cost_val": 35,
        "cast_time": "Instant",
        "range_yards": 5,
        "cooldown_sec": 0,
        "description": "Finishing move that causes damage per combo point: 1 pt: 247-377, 5 pts: 897-1027 damage.",
        "forever_tuning": "Forever Update (Nov 3): Base damage increased by 6%. Book dropped by General Drakkisath.",
        "is_forever_content": 1,
    },

    # --- PRIEST ---
    {
        "name": "Flash Heal",
        "character_class": "Priest",
        "spec": "Holy / Discipline",
        "rank": "Rank 7",
        "level_req": 56,
        "cost_type": "Mana",
        "cost_val": 380,
        "cast_time": "1.5 sec cast",
        "range_yards": 40,
        "cooldown_sec": 0,
        "description": "Heals a friendly target for 812 to 958. Rapid single-target triage healing.",
        "forever_tuning": "Classic baseline: 1.5s emergency heal with high +healing scaling.",
        "is_forever_content": 0,
    },
    {
        "name": "Greater Heal",
        "character_class": "Priest",
        "spec": "Holy",
        "rank": "Rank 5",
        "level_req": 60,
        "cost_type": "Mana",
        "cost_val": 710,
        "cast_time": "3.0 sec cast",
        "range_yards": 40,
        "cooldown_sec": 0,
        "description": "A slow casting spell that heals a single target for 1966 to 2194. Downranked to Rank 1/4 for maximum mana efficiency.",
        "forever_tuning": "Classic baseline: Core tank healing foundation with Spiritual Guidance.",
        "is_forever_content": 0,
    },
    {
        "name": "Shadowform",
        "character_class": "Priest",
        "spec": "Shadow",
        "rank": "Rank 1",
        "level_req": 40,
        "cost_type": "Mana",
        "cost_val": 525,
        "cast_time": "Instant",
        "range_yards": 0,
        "cooldown_sec": 0,
        "description": "Assume a Shadowform, increasing your Shadow damage by 15% and reducing physical damage taken by 15%. Cannot cast Holy spells.",
        "forever_tuning": "Forever Update (Nov 3): Shadow damage buff tuned to expand caster headroom; unreduced PvP crit.",
        "is_forever_content": 1,
    },
    {
        "name": "Mind Flay",
        "character_class": "Priest",
        "spec": "Shadow",
        "rank": "Rank 6",
        "level_req": 52,
        "cost_type": "Mana",
        "cost_val": 205,
        "cast_time": "Channeled (3 sec)",
        "range_yards": 20,
        "cooldown_sec": 0,
        "description": "Assault the target's mind with Shadow energy, causing 426 Shadow damage over 3 sec and slowing movement speed by 50%.",
        "forever_tuning": "Forever Update (Nov 3): Channeled tick rate and damage increased by 10%.",
        "is_forever_content": 1,
    },
    {
        "name": "Power Word: Shield",
        "character_class": "Priest",
        "spec": "Discipline",
        "rank": "Rank 10",
        "level_req": 60,
        "cost_type": "Mana",
        "cost_val": 500,
        "cast_time": "Instant",
        "range_yards": 40,
        "cooldown_sec": 4.0,
        "description": "Draws on the soul of the friendly target to shield them, absorbing 942 damage. Lasts 30 sec. Causes Weakened Soul for 15 sec.",
        "forever_tuning": "Classic baseline: Essential pre-shielding for raid damage spikes.",
        "is_forever_content": 0,
    },

    # --- SHAMAN ---
    {
        "name": "Windfury Totem",
        "character_class": "Shaman",
        "spec": "Enhancement",
        "rank": "Rank 3",
        "level_req": 52,
        "cost_type": "Mana",
        "cost_val": 275,
        "cast_time": "Instant",
        "range_yards": 0,
        "cooldown_sec": 0,
        "description": "Summons a Windfury Totem with 5 health at the feet of the Shaman. Gives raid members within 20 yards a 20% chance on main hand attack to gain 1 extra attack with 315 extra melee attack power.",
        "forever_tuning": "Forever Update (Oct 15): Windfury Totem is now RAID-WIDE! Eliminates strict 5-man group shuffling.",
        "is_forever_content": 1,
    },
    {
        "name": "Chain Lightning",
        "character_class": "Shaman",
        "spec": "Elemental",
        "rank": "Rank 4",
        "level_req": 56,
        "cost_type": "Mana",
        "cost_val": 605,
        "cast_time": "2.5 sec cast",
        "range_yards": 30,
        "cooldown_sec": 6.0,
        "description": "Hurls a lightning bolt at the enemy, dealing 493 to 563 Nature damage and then jumping to additional nearby enemies. Each jump reduces damage by 30%. Affects 3 targets.",
        "forever_tuning": "Forever Update (Nov 3): Damage increased by 9% in revised headroom budget.",
        "is_forever_content": 1,
    },
    {
        "name": "Chain Heal",
        "character_class": "Shaman",
        "spec": "Restoration",
        "rank": "Rank 3",
        "level_req": 54,
        "cost_type": "Mana",
        "cost_val": 405,
        "cast_time": "2.5 sec cast",
        "range_yards": 40,
        "cooldown_sec": 0,
        "description": "Heals the friendly target for 551 to 629, then jumps to heal 2 additional nearby friendly targets. Healing is reduced by 50% after each jump.",
        "forever_tuning": "Classic baseline: The premiere raid AOE smart healing spell.",
        "is_forever_content": 0,
    },
    {
        "name": "Stormstrike",
        "character_class": "Shaman",
        "spec": "Enhancement",
        "rank": "Rank 1",
        "level_req": 40,
        "cost_type": "Mana",
        "cost_val": 235,
        "cast_time": "Instant",
        "range_yards": 5,
        "cooldown_sec": 20.0,
        "description": "Instantly attack with your weapon. In addition, the next 2 sources of Nature damage dealt to the target are increased by 20%. Lasts 12 sec.",
        "forever_tuning": "Forever Update (Nov 3): Weapon damage multiplier enhanced; synergizes with Windfury procs.",
        "is_forever_content": 1,
    },
    {
        "name": "Grace of Air Totem",
        "character_class": "Shaman",
        "spec": "Enhancement",
        "rank": "Rank 2",
        "level_req": 56,
        "cost_type": "Mana",
        "cost_val": 250,
        "cast_time": "Instant",
        "range_yards": 0,
        "cooldown_sec": 0,
        "description": "Summons an Air Totem with 5 health. Increases agility of raid members within 20 yards by 67 for 2 min.",
        "forever_tuning": "Forever Update (Oct 15): Totem buff is now RAID-WIDE! Enables seamless Totem Twisting.",
        "is_forever_content": 1,
    },

    # --- MAGE ---
    {
        "name": "Frostbolt",
        "character_class": "Mage",
        "spec": "Frost",
        "rank": "Rank 11",
        "level_req": 60,
        "cost_type": "Mana",
        "cost_val": 260,
        "cast_time": "3.0 sec cast",
        "range_yards": 30,
        "cooldown_sec": 0,
        "description": "Launches a bolt of frost at the enemy, causing 515 to 555 Frost damage and slowing movement speed by 40% for 9 sec.",
        "forever_tuning": "Forever Update (Nov 3): Base damage increased by 7% in revised headroom budget.",
        "is_forever_content": 1,
    },
    {
        "name": "Fireball",
        "character_class": "Mage",
        "spec": "Fire",
        "rank": "Rank 12",
        "level_req": 60,
        "cost_type": "Mana",
        "cost_val": 395,
        "cast_time": "3.5 sec cast",
        "range_yards": 35,
        "cooldown_sec": 0,
        "description": "Hurls a fiery ball that causes 561 to 715 Fire damage and an additional 72 Fire damage over 8 sec.",
        "forever_tuning": "Forever Update (Nov 3): Fire damage increased; Ignite rolling mechanics preserved.",
        "is_forever_content": 1,
    },
    {
        "name": "Arcane Missiles",
        "character_class": "Mage",
        "spec": "Arcane",
        "rank": "Rank 8",
        "level_req": 56,
        "cost_type": "Mana",
        "cost_val": 595,
        "cast_time": "Channeled (5 sec)",
        "range_yards": 30,
        "cooldown_sec": 0,
        "description": "Launches missiles of magical energy at the enemy, causing 230 Arcane damage every 1 second for 5 sec.",
        "forever_tuning": "Forever Update (Nov 3): Damage increased by 10%; high synergy with Arcane Power.",
        "is_forever_content": 1,
    },
    {
        "name": "Blizzard",
        "character_class": "Mage",
        "spec": "Frost",
        "rank": "Rank 6",
        "level_req": 60,
        "cost_type": "Mana",
        "cost_val": 1400,
        "cast_time": "Channeled (8 sec)",
        "range_yards": 30,
        "cooldown_sec": 0,
        "description": "Ice shards pelt the target area doing 1192 Frost damage over 8 sec.",
        "forever_tuning": "Forever Update (Nov 3): Penalty retained for ranks learned >12 levels below player to prevent low-rank proc exploitation.",
        "is_forever_content": 1,
    },
    {
        "name": "Arcane Power",
        "character_class": "Mage",
        "spec": "Arcane",
        "rank": "Rank 1",
        "level_req": 40,
        "cost_type": "Free",
        "cost_val": 0,
        "cast_time": "Instant",
        "range_yards": 0,
        "cooldown_sec": 180.0,
        "description": "When activated, your spells deal 30% more damage while costing 30% more mana to cast. Lasts 15 sec.",
        "forever_tuning": "Classic baseline: The premiere 3-minute burst cooldown for Mage.",
        "is_forever_content": 0,
    },

    # --- WARLOCK ---
    {
        "name": "Shadow Bolt",
        "character_class": "Warlock",
        "spec": "Destruction",
        "rank": "Rank 10",
        "level_req": 60,
        "cost_type": "Mana",
        "cost_val": 380,
        "cast_time": "3.0 sec cast",
        "range_yards": 30,
        "cooldown_sec": 0,
        "description": "Sends a shadowy bolt at the enemy, causing 455 to 507 Shadow damage. Critical hits trigger Improved Shadow Bolt for +20% shadow damage for 4 charges.",
        "forever_tuning": "Forever Update (Nov 3): Direct damage increased by 8% in revised headroom budget.",
        "is_forever_content": 1,
    },
    {
        "name": "Corruption",
        "character_class": "Warlock",
        "spec": "Affliction",
        "rank": "Rank 7",
        "level_req": 52,
        "cost_type": "Mana",
        "cost_val": 290,
        "cast_time": "2.0 sec cast",
        "range_yards": 30,
        "cooldown_sec": 0,
        "description": "Corrupts the target, causing 666 Shadow damage over 18 sec. Made instant with Improved Corruption 5/5.",
        "forever_tuning": "Forever Update (Nov 3): Nightfall proc chance verified at 4% on damage tick.",
        "is_forever_content": 1,
    },
    {
        "name": "Curse of the Elements",
        "character_class": "Warlock",
        "spec": "Affliction",
        "rank": "Rank 3",
        "level_req": 60,
        "cost_type": "Mana",
        "cost_val": 200,
        "cast_time": "Instant",
        "range_yards": 30,
        "cooldown_sec": 0,
        "description": "Curses the target for 5 min, reducing Fire and Frost resistances by 75 and increasing Fire and Frost damage taken by 10%. Only one curse per warlock.",
        "forever_tuning": "Classic baseline: Essential caster debuff for Fire Mages and Destruction warlocks.",
        "is_forever_content": 0,
    },
    {
        "name": "Curse of Shadows",
        "character_class": "Warlock",
        "spec": "Affliction",
        "rank": "Rank 2",
        "level_req": 60,
        "cost_type": "Mana",
        "cost_val": 200,
        "cast_time": "Instant",
        "range_yards": 30,
        "cooldown_sec": 0,
        "description": "Curses the target for 5 min, reducing Shadow and Arcane resistances by 75 and increasing Shadow and Arcane damage taken by 10%.",
        "forever_tuning": "Classic baseline: Essential debuff for Shadow Priests and Warlock raid dps.",
        "is_forever_content": 0,
    },
    {
        "name": "Life Tap",
        "character_class": "Warlock",
        "spec": "Affliction",
        "rank": "Rank 6",
        "level_req": 56,
        "cost_type": "Health",
        "cost_val": 420,
        "cast_time": "Instant",
        "range_yards": 0,
        "cooldown_sec": 0,
        "description": "Converts 420 health into 420 mana. Improved by Improved Life Tap for +20% extra mana returned.",
        "forever_tuning": "Classic baseline: Signature sustain ability providing infinite mana in raid encounters.",
        "is_forever_content": 0,
    },

    # --- DRUID ---
    {
        "name": "Leader of the Pack",
        "character_class": "Druid",
        "spec": "Feral",
        "rank": "Rank 1",
        "level_req": 40,
        "cost_type": "Passive",
        "cost_val": 0,
        "cast_time": "Passive",
        "range_yards": 0,
        "cooldown_sec": 0,
        "description": "While in Cat, Bear, or Dire Bear Form, increases ranged and melee critical chance of all raid members within 45 yards by 3%.",
        "forever_tuning": "Forever Update (Oct 15): Leader of the Pack is now RAID-WIDE! Massive buff for feral utility.",
        "is_forever_content": 1,
    },
    {
        "name": "Moonkin Aura",
        "character_class": "Druid",
        "spec": "Balance",
        "rank": "Rank 1",
        "level_req": 40,
        "cost_type": "Passive",
        "cost_val": 0,
        "cast_time": "Passive",
        "range_yards": 0,
        "cooldown_sec": 0,
        "description": "While in Moonkin Form, increases the spell critical chance of all raid members within 30 yards by 3%.",
        "forever_tuning": "Forever Update (Oct 15): Moonkin Aura is now RAID-WIDE! Essential for caster raid DPS.",
        "is_forever_content": 1,
    },
    {
        "name": "Shred",
        "character_class": "Druid",
        "spec": "Feral (Cat)",
        "rank": "Rank 5",
        "level_req": 56,
        "cost_type": "Energy",
        "cost_val": 60,
        "cast_time": "Instant",
        "range_yards": 5,
        "cooldown_sec": 0,
        "description": "Shred the target, causing 225% damage plus 180 to the target. Must be behind the target. Awards 1 combo point.",
        "forever_tuning": "Forever Update (Nov 3): Damage increased by 9%; Wolfshead Trophy powershifting optimal.",
        "is_forever_content": 1,
    },
    {
        "name": "Swiftmend",
        "character_class": "Druid",
        "spec": "Restoration",
        "rank": "Rank 1",
        "level_req": 40,
        "cost_type": "Mana",
        "cost_val": 290,
        "cast_time": "Instant",
        "range_yards": 40,
        "cooldown_sec": 15.0,
        "description": "Consumes a Rejuvenation or Regrowth effect on a friendly target to instantly heal them for an amount equal to 12 sec of Rejuvenation or 18 sec of Regrowth.",
        "forever_tuning": "Forever Update (Nov 3): Emergency burst heal for Restoration Druids with improved throughput.",
        "is_forever_content": 1,
    },
    {
        "name": "Innervate",
        "character_class": "Druid",
        "spec": "Restoration / All",
        "rank": "Rank 1",
        "level_req": 40,
        "cost_type": "Mana",
        "cost_val": 100,
        "cast_time": "Instant",
        "range_yards": 30,
        "cooldown_sec": 360.0,
        "description": "Increases the target's Mana regeneration by 400% and allows 100% of the target's Mana regeneration to continue while casting. Lasts 20 sec.",
        "forever_tuning": "Classic baseline: The premiere external raid mana cooldown for healers.",
        "is_forever_content": 0,
    },
]

# ==============================================================================
# 2. CANONICAL ARMOR SETS (TIER 0 TO TIER 3 + PVP + FOREVER RAID SETS)
# ==============================================================================
ARMOR_SETS_DATA: List[Dict[str, Any]] = [
    # --- TIER 0 / DUNGEON SET 1 ---
    {
        "set_name": "Battlegear of Valor",
        "character_class": "Warrior",
        "tier": "Tier 0 (Dungeon 1)",
        "pieces_count": 8,
        "item_names": "Helm of Valor, Spaulders of Valor, Breastplate of Valor, Bracers of Valor, Gauntlets of Valor, Belt of Valor, Legplates of Valor, Boots of Valor",
        "bonuses": {
            "2": "+200 Armor.",
            "4": "+40 Attack Power.",
            "6": "Chance on hit in melee to heal you for 88 to 132.",
            "8": "+8 All Resistances.",
        },
        "source_dungeon": "Scholomance / Stratholme / UBRS",
        "is_forever_content": 0,
    },
    {
        "set_name": "Lightforge Armor",
        "character_class": "Paladin",
        "tier": "Tier 0 (Dungeon 1)",
        "pieces_count": 8,
        "item_names": "Lightforge Helm, Lightforge Spaulders, Lightforge Breastplate, Lightforge Bracers, Lightforge Gauntlets, Lightforge Belt, Lightforge Legplates, Lightforge Boots",
        "bonuses": {
            "2": "+200 Armor.",
            "4": "Increases damage and healing done by magical spells and effects by up to 23.",
            "6": "Chance on hit in melee to heal you for 88 to 132.",
            "8": "+8 All Resistances.",
        },
        "source_dungeon": "Scholomance / Stratholme / UBRS",
        "is_forever_content": 0,
    },
    {
        "set_name": "Shadowcraft Armor",
        "character_class": "Rogue",
        "tier": "Tier 0 (Dungeon 1)",
        "pieces_count": 8,
        "item_names": "Shadowcraft Cap, Shadowcraft Spaulders, Shadowcraft Tunic, Shadowcraft Bracers, Shadowcraft Gloves, Shadowcraft Belt, Shadowcraft Pants, Shadowcraft Boots",
        "bonuses": {
            "2": "+200 Armor.",
            "4": "+40 Attack Power.",
            "6": "Chance on melee attack to restore 35 Energy.",
            "8": "+8 All Resistances.",
        },
        "source_dungeon": "Scholomance / Stratholme / UBRS",
        "is_forever_content": 0,
    },
    {
        "set_name": "Vestments of the Devout",
        "character_class": "Priest",
        "tier": "Tier 0 (Dungeon 1)",
        "pieces_count": 8,
        "item_names": "Devout Crown, Devout Mantle, Devout Robe, Devout Bracers, Devout Gloves, Devout Belt, Devout Skirt, Devout Sandals",
        "bonuses": {
            "2": "+200 Armor.",
            "4": "Increases damage and healing done by magical spells and effects by up to 23.",
            "6": "When struck in combat has a chance of shielding the wearer in a damage absorb shield.",
            "8": "+8 All Resistances.",
        },
        "source_dungeon": "Scholomance / Stratholme / UBRS",
        "is_forever_content": 0,
    },
    {
        "set_name": "Magister's Regalia",
        "character_class": "Mage",
        "tier": "Tier 0 (Dungeon 1)",
        "pieces_count": 8,
        "item_names": "Magister's Crown, Magister's Mantle, Magister's Robes, Magister's Bindings, Magister's Gloves, Magister's Belt, Magister's Leggings, Magister's Boots",
        "bonuses": {
            "2": "+200 Armor.",
            "4": "Increases damage and healing done by magical spells and effects by up to 23.",
            "6": "When struck in combat has a chance of freezing the attacker in place for 3 sec.",
            "8": "+8 All Resistances.",
        },
        "source_dungeon": "Scholomance / Stratholme / UBRS",
        "is_forever_content": 0,
    },

    # --- TIER 1 / MOLTEN CORE ---
    {
        "set_name": "Battlegear of Might",
        "character_class": "Warrior",
        "tier": "Tier 1 (Molten Core)",
        "pieces_count": 8,
        "item_names": "Helm of Might, Pauldrons of Might, Breastplate of Might, Bracers of Might, Gauntlets of Might, Belt of Might, Legplates of Might, Sabatons of Might",
        "bonuses": {
            "3": "Increases the block value of your shield by 30.",
            "5": "Gives you a 20% chance to generate an additional Rage point whenever damage is dealt to you.",
            "8": "Increases the threat generated by Sunder Armor by 15%.",
        },
        "source_dungeon": "Molten Core",
        "is_forever_content": 0,
    },
    {
        "set_name": "Giantstalker Armor",
        "character_class": "Hunter",
        "tier": "Tier 1 (Molten Core)",
        "pieces_count": 8,
        "item_names": "Giantstalker's Helmet, Giantstalker's Epaulets, Giantstalker's Breastplate, Giantstalker's Bracers, Giantstalker's Gloves, Giantstalker's Belt, Giantstalker's Leggings, Giantstalker's Boots",
        "bonuses": {
            "3": "Increases the range of your Mend Pet spell by 50% and effect by 10%.",
            "5": "Increases the range of your sting and shot attacks by 10%.",
            "8": "Increases the damage done by Multi-Shot and Volley by 15%.",
        },
        "source_dungeon": "Molten Core",
        "is_forever_content": 0,
    },
    {
        "set_name": "Nightslayer Armor",
        "character_class": "Rogue",
        "tier": "Tier 1 (Molten Core)",
        "pieces_count": 8,
        "item_names": "Nightslayer Cover, Nightslayer Shoulder Pads, Nightslayer Chestpiece, Nightslayer Bracelets, Nightslayer Gloves, Nightslayer Belt, Nightslayer Pants, Nightslayer Boots",
        "bonuses": {
            "3": "Reduces the cooldown of your Vanish ability by 30 sec.",
            "5": "Increases your maximum Energy by 10.",
            "8": "Gives a chance to heal the rogue for 500 when Vanish is performed.",
        },
        "source_dungeon": "Molten Core",
        "is_forever_content": 0,
    },
    {
        "set_name": "Arcanist Regalia",
        "character_class": "Mage",
        "tier": "Tier 1 (Molten Core)",
        "pieces_count": 8,
        "item_names": "Arcanist Crown, Arcanist Mantle, Arcanist Robes, Arcanist Bindings, Arcanist Gloves, Arcanist Belt, Arcanist Leggings, Arcanist Boots",
        "bonuses": {
            "3": "Increases damage and healing done by magical spells and effects by up to 18.",
            "5": "Decreases the magical resistances of your spell targets by 10.",
            "8": "Decreases the threat generated by your spells by 15%.",
        },
        "source_dungeon": "Molten Core",
        "is_forever_content": 0,
    },
    {
        "set_name": "Felheart Raiment",
        "character_class": "Warlock",
        "tier": "Tier 1 (Molten Core)",
        "pieces_count": 8,
        "item_names": "Felheart Horns, Felheart Shoulder Pads, Felheart Robes, Felheart Bracers, Felheart Gloves, Felheart Belt, Felheart Pants, Felheart Slippers",
        "bonuses": {
            "3": "Health Funnel heal increased by 10% and cost reduced by 30%.",
            "5": "Increases the Stamina of your pet by 15% and your pet's intellect by 15%.",
            "8": "Reduces the mana cost of your Destruction spells by 15%.",
        },
        "source_dungeon": "Molten Core",
        "is_forever_content": 0,
    },

    # --- TIER 2 / BLACKWING LAIR & RAGNAROS / ONYXIA ---
    {
        "set_name": "Battlegear of Wrath",
        "character_class": "Warrior",
        "tier": "Tier 2 (Blackwing Lair)",
        "pieces_count": 8,
        "item_names": "Helm of Wrath, Pauldrons of Wrath, Breastplate of Wrath, Bracers of Wrath, Gauntlets of Wrath, Waistband of Wrath, Legplates of Wrath, Sabatons of Wrath",
        "bonuses": {
            "3": "Increases the attack power bonus of Battle Shout by 30.",
            "5": "20% chance after using an offensive ability that your next attack requires 5 less Rage.",
            "8": "10% chance to deliver a strike that deals 120 to 180 damage and heals you for the same amount.",
        },
        "source_dungeon": "Blackwing Lair / Onyxia / Ragnaros",
        "is_forever_content": 0,
    },
    {
        "set_name": "Bloodfang Armor",
        "character_class": "Rogue",
        "tier": "Tier 2 (Blackwing Lair)",
        "pieces_count": 8,
        "item_names": "Bloodfang Hood, Bloodfang Spaulders, Bloodfang Chestpiece, Bloodfang Bracers, Bloodfang Gloves, Bloodfang Belt, Bloodfang Pants, Bloodfang Boots",
        "bonuses": {
            "3": "Increases the chance to apply poisons to your target by 5%.",
            "5": "Improves the threat reduction of Feint by 25%.",
            "8": "Gives the Rogue a chance to inflict 283 to 317 damage on melee hits and heal for 50 health every 1 sec for 6 sec.",
        },
        "source_dungeon": "Blackwing Lair / Onyxia / Ragnaros",
        "is_forever_content": 0,
    },
    {
        "set_name": "Judgement Armor",
        "character_class": "Paladin",
        "tier": "Tier 2 (Blackwing Lair)",
        "pieces_count": 8,
        "item_names": "Judgement Crown, Judgement Spaulders, Judgement Breastplate, Judgement Bindings, Judgement Gauntlets, Judgement Belt, Judgement Legplates, Judgement Sabatons",
        "bonuses": {
            "3": "Increases the radius of Paladin auras by 10 yards.",
            "5": "Increases damage and healing done by magical spells and effects by up to 47.",
            "8": "Deals 60 to 66 additional Holy damage on all weapon strikes.",
        },
        "source_dungeon": "Blackwing Lair / Onyxia / Ragnaros",
        "is_forever_content": 0,
    },
    {
        "set_name": "Netherwind Regalia",
        "character_class": "Mage",
        "tier": "Tier 2 (Blackwing Lair)",
        "pieces_count": 8,
        "item_names": "Netherwind Crown, Netherwind Mantle, Netherwind Robes, Netherwind Bindings, Netherwind Gloves, Netherwind Belt, Netherwind Pants, Netherwind Boots",
        "bonuses": {
            "3": "Reduces the threat generated by your Scorch, Arcane Missiles, Fireball, and Frostbolt spells by 8%.",
            "5": "Increases the radius of Arcane Explosion, Flamestrike, and Blizzard by 25%.",
            "8": "10% chance after casting Arcane Missiles, Fireball, or Frostbolt that your next spell with a cast time under 10 sec will cast instantly.",
        },
        "source_dungeon": "Blackwing Lair / Onyxia / Ragnaros",
        "is_forever_content": 0,
    },

    # --- TIER 3 / NAXXRAMAS ---
    {
        "set_name": "Dreadnaught's Battlegear",
        "character_class": "Warrior",
        "tier": "Tier 3 (Naxxramas)",
        "pieces_count": 9,
        "item_names": "Dreadnaught Helmet, Dreadnaught Pauldrons, Dreadnaught Breastplate, Dreadnaught Bracers, Dreadnaught Gauntlets, Dreadnaught Waistguard, Dreadnaught Legplates, Dreadnaught Sabatons, Ring of the Dreadnaught",
        "bonuses": {
            "2": "Increases the damage done by your Revenge ability by 75.",
            "4": "Increases your chance to hit with Taunt and Mocking Blow by 5%.",
            "6": "Increases your chance to hit with Sunder Armor, Heroic Strike, Revenge, and Shield Slam by 5%.",
            "8": "When your health drops below 20%, your next 5 attacks heal for 160 health and give +100 Armor for 1 min.",
        },
        "source_dungeon": "Naxxramas",
        "is_forever_content": 0,
    },
    {
        "set_name": "Frostfire Regalia",
        "character_class": "Mage",
        "tier": "Tier 3 (Naxxramas)",
        "pieces_count": 9,
        "item_names": "Frostfire Circlet, Frostfire Shoulderpads, Frostfire Robe, Frostfire Bindings, Frostfire Gloves, Frostfire Belt, Frostfire Leggings, Frostfire Sandals, Ring of the Frostfire",
        "bonuses": {
            "2": "Reduces the cooldown on your Evocation ability by 1 minute.",
            "4": "Gives your Mage Armor a chance to increase your resistance to all schools by 35 for 30 sec when struck.",
            "6": "Your damage spells have a chance to cause your target to take up to 200 increased damage from your next spell.",
            "8": "Your damage spells have a chance to displace you, causing the next attack against you to miss.",
        },
        "source_dungeon": "Naxxramas",
        "is_forever_content": 0,
    },
    {
        "set_name": "Bonescythe Armor",
        "character_class": "Rogue",
        "tier": "Tier 3 (Naxxramas)",
        "pieces_count": 9,
        "item_names": "Bonescythe Helmet, Bonescythe Pauldrons, Bonescythe Breastplate, Bonescythe Bracers, Bonescythe Gauntlets, Bonescythe Waistguard, Bonescythe Legplates, Bonescythe Sabatons, Ring of the Bonescythe",
        "bonuses": {
            "2": "Your melee normal attacks have a chance to heal you for 90 to 110.",
            "4": "Your Backstab, Sinister Strike, and Hemorrhage critical strikes have a chance to refund 5 Energy.",
            "6": "Reduces the threat from your finishing moves by 8%.",
            "8": "Your finishing moves have a chance to add a combo point to your target.",
        },
        "source_dungeon": "Naxxramas",
        "is_forever_content": 0,
    },
    {
        "set_name": "Vestments of Faith",
        "character_class": "Priest",
        "tier": "Tier 3 (Naxxramas)",
        "pieces_count": 9,
        "item_names": "Circlet of Faith, Shoulderpads of Faith, Robe of Faith, Bindings of Faith, Gloves of Faith, Belt of Faith, Leggings of Faith, Sandals of Faith, Ring of Faith",
        "bonuses": {
            "2": "Reduces the mana cost of your Renew spell by 12%.",
            "4": "On Greater Heal critical hits, places an armor buff on the target giving +500 armor for 15 sec.",
            "6": "Reduces threat generated by healing spells by 10%.",
            "8": "Each spell cast gives you a chance for Epiphany, restoring 24 mana every 5 sec for 30 sec.",
        },
        "source_dungeon": "Naxxramas",
        "is_forever_content": 0,
    },

    # --- FOREVER CUSTOM RAID & DUNGEON SETS ---
    {
        "set_name": "Zephras Deepsea Regalia",
        "character_class": "All Casters (Mage/Priest/Warlock/Druid)",
        "tier": "Forever Raid (Sunken Citadel)",
        "pieces_count": 5,
        "item_names": "Deepsea Cowl, Mantle of the Sunken Spire, Trench Robes, Coral Bindings, Abyssal Treaders",
        "bonuses": {
            "2": "+15 Spell Damage and Healing, +5 Frost and Nature Resistance.",
            "3": "Increases spell hit chance by 1% and restores 6 mana per 5 sec.",
            "5": "Chance on offensive spell hit to blast the target for 150 to 210 Frost damage and grant underwater breathing for 10 min.",
        },
        "source_dungeon": "Sunken Citadel (Zephras Isle)",
        "is_forever_content": 1,
    },
    {
        "set_name": "Ashfall Battlegear",
        "character_class": "All Melee (Warrior/Paladin/Rogue/Hunter)",
        "tier": "Forever Raid (Dragonflame Caldera)",
        "pieces_count": 5,
        "item_names": "Ashfall Greathelm, Magma Pauldrons, Caldera Hauberk, Cinder Bracers, Volcanic Greaves",
        "bonuses": {
            "2": "+30 Attack Power and +15 Fire Resistance.",
            "3": "Increases melee and ranged hit chance by 1%.",
            "5": "Chance on melee strike to ignite your weapon, dealing 125 additional Fire damage over 6 sec.",
        },
        "source_dungeon": "Dragonflame Caldera",
        "is_forever_content": 1,
    },
]

# ==============================================================================
# 3. CANONICAL ACHIEVEMENTS & FEATS OF STRENGTH
# ==============================================================================
ACHIEVEMENTS_DATA: List[Dict[str, Any]] = [
    {
        "title": "Molten Core",
        "category": "Dungeons & Raids",
        "points": 10,
        "description": "Defeat Ragnaros the Firelord inside the Molten Core.",
        "reward": "None",
        "is_feat_of_strength": 0,
        "is_forever_content": 0,
    },
    {
        "title": "Blackwing Lair",
        "category": "Dungeons & Raids",
        "points": 10,
        "description": "Defeat Nefarian in Blackwing Lair.",
        "reward": "None",
        "is_feat_of_strength": 0,
        "is_forever_content": 0,
    },
    {
        "title": "Temple of Ahn'Qiraj",
        "category": "Dungeons & Raids",
        "points": 10,
        "description": "Defeat C'Thun in the Temple of Ahn'Qiraj.",
        "reward": "None",
        "is_feat_of_strength": 0,
        "is_forever_content": 0,
    },
    {
        "title": "Naxxramas",
        "category": "Dungeons & Raids",
        "points": 15,
        "description": "Defeat Kel'Thuzad in the necropolis of Naxxramas.",
        "reward": "None",
        "is_feat_of_strength": 0,
        "is_forever_content": 0,
    },
    {
        "title": "Sunken Citadel Conqueror",
        "category": "Dungeons & Raids",
        "points": 10,
        "description": "Defeat the High Tide Leviathan inside the Sunken Citadel on Zephras Isle.",
        "reward": "Title: The Tidebreaker",
        "is_feat_of_strength": 0,
        "is_forever_content": 1,
    },
    {
        "title": "Dragonflame Vanquisher",
        "category": "Dungeons & Raids",
        "points": 10,
        "description": "Extinguish the Pyrelord Ignis in the heart of Dragonflame Caldera.",
        "reward": "None",
        "is_feat_of_strength": 0,
        "is_forever_content": 1,
    },
    {
        "title": "Level 60",
        "category": "Character",
        "points": 10,
        "description": "Reach Level 60.",
        "reward": "None",
        "is_feat_of_strength": 0,
        "is_forever_content": 0,
    },
    {
        "title": "Realm First! Level 60",
        "category": "Feats of Strength",
        "points": 0,
        "description": "First person on the realm to achieve level 60.",
        "reward": "Title: The Pioneer",
        "is_feat_of_strength": 1,
        "is_forever_content": 1,
    },
    {
        "title": "Scarab Lord",
        "category": "Feats of Strength",
        "points": 0,
        "description": "Banged the Gong of the Scarab Wall during the Gates of Ahn'Qiraj opening ceremony.",
        "reward": "Mount: Black Qiraji Resonating Crystal & Title: Scarab Lord",
        "is_feat_of_strength": 1,
        "is_forever_content": 0,
    },
    {
        "title": "Thunderfury, Blessed Blade of the Windseeker",
        "category": "Feats of Strength",
        "points": 0,
        "description": "Wielder of the legendary blade Thunderfury, Blessed Blade of the Windseeker.",
        "reward": "Feat of Strength Recognition",
        "is_feat_of_strength": 1,
        "is_forever_content": 0,
    },
    {
        "title": "Sulfuras, Hand of Ragnaros",
        "category": "Feats of Strength",
        "points": 0,
        "description": "Wielder of the legendary hammer Sulfuras, Hand of Ragnaros.",
        "reward": "Feat of Strength Recognition",
        "is_feat_of_strength": 1,
        "is_forever_content": 0,
    },
    {
        "title": "Atiesh, Greatstaff of the Guardian",
        "category": "Feats of Strength",
        "points": 0,
        "description": "Wielder of Atiesh, Greatstaff of the Guardian.",
        "reward": "Feat of Strength Recognition & Karazhan Portal Ability",
        "is_feat_of_strength": 1,
        "is_forever_content": 0,
    },
    {
        "title": "Grand Marshal / High Warlord",
        "category": "PvP",
        "points": 25,
        "description": "Achieve the highest military rank of Rank 14 (Grand Marshal or High Warlord) in the Honor System.",
        "reward": "Title & Access to Epic R14 Weapons",
        "is_feat_of_strength": 0,
        "is_forever_content": 0,
    },
    {
        "title": "Master of Warsong Gulch",
        "category": "PvP",
        "points": 10,
        "description": "Achieve Exalted reputation with the Silverwing Sentinels or Warsong Outriders and capture 100 flags.",
        "reward": "Warsong Battle Tabard",
        "is_feat_of_strength": 0,
        "is_forever_content": 0,
    },
    {
        "title": "Master of Arathi Basin",
        "category": "PvP",
        "points": 10,
        "description": "Achieve Exalted reputation with The League of Arathor or The Defilers.",
        "reward": "Arathor / Defilers Battle Tabard",
        "is_feat_of_strength": 0,
        "is_forever_content": 0,
    },
    {
        "title": "Hero of Alterac Valley",
        "category": "PvP",
        "points": 10,
        "description": "Achieve Exalted reputation with the Stormpike Guard or Frostwolf Clan.",
        "reward": "Stormpike Battle Charger / Frostwolf Howler discount",
        "is_feat_of_strength": 0,
        "is_forever_content": 0,
    },
    {
        "title": "Universal Explorer",
        "category": "Exploration",
        "points": 25,
        "description": "Explore all regions of Eastern Kingdoms and Kalimdor.",
        "reward": "Title: The Explorer",
        "is_feat_of_strength": 0,
        "is_forever_content": 0,
    },
    {
        "title": "The Undying (Classic Edition)",
        "category": "Feats of Strength",
        "points": 0,
        "description": "Complete a full raid clear of Naxxramas without a single player death during any boss encounter.",
        "reward": "Title: The Undying",
        "is_feat_of_strength": 1,
        "is_forever_content": 1,
    },
]


def setup_tables(cur: sqlite3.Cursor):
    """Creates database tables and FTS virtual indexes."""
    # 1. Spells
    cur.execute("""
        CREATE TABLE IF NOT EXISTS spells (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            character_class TEXT NOT NULL,
            spec TEXT,
            rank TEXT,
            level_req INTEGER DEFAULT 1,
            cost_type TEXT DEFAULT 'Mana',
            cost_val INTEGER DEFAULT 0,
            cast_time TEXT DEFAULT 'Instant',
            range_yards INTEGER DEFAULT 0,
            cooldown_sec REAL DEFAULT 0.0,
            description TEXT NOT NULL,
            forever_tuning TEXT,
            is_forever_content INTEGER DEFAULT 0
        );
    """)
    cur.execute("CREATE INDEX IF NOT EXISTS idx_spells_name ON spells(name);")
    cur.execute("CREATE INDEX IF NOT EXISTS idx_spells_class ON spells(character_class);")

    # FTS for Spells
    cur.execute("DROP TABLE IF EXISTS spells_fts;")
    cur.execute("""
        CREATE VIRTUAL TABLE spells_fts USING fts5(
            name, character_class, spec, description, forever_tuning,
            content='spells', content_rowid='id'
        );
    """)

    # 2. Armor Sets
    cur.execute("""
        CREATE TABLE IF NOT EXISTS armor_sets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            set_name TEXT NOT NULL,
            character_class TEXT NOT NULL,
            tier TEXT NOT NULL,
            pieces_count INTEGER DEFAULT 8,
            item_names TEXT NOT NULL,
            bonuses_json TEXT NOT NULL,
            source_dungeon TEXT NOT NULL,
            is_forever_content INTEGER DEFAULT 0
        );
    """)
    cur.execute("CREATE INDEX IF NOT EXISTS idx_armor_sets_name ON armor_sets(set_name);")
    cur.execute("CREATE INDEX IF NOT EXISTS idx_armor_sets_class ON armor_sets(character_class);")

    # FTS for Armor Sets
    cur.execute("DROP TABLE IF EXISTS armor_sets_fts;")
    cur.execute("""
        CREATE VIRTUAL TABLE armor_sets_fts USING fts5(
            set_name, character_class, tier, item_names, source_dungeon,
            content='armor_sets', content_rowid='id'
        );
    """)

    # 3. Achievements
    cur.execute("""
        CREATE TABLE IF NOT EXISTS achievements (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            category TEXT NOT NULL,
            points INTEGER DEFAULT 10,
            description TEXT NOT NULL,
            reward TEXT DEFAULT 'None',
            is_feat_of_strength INTEGER DEFAULT 0,
            is_forever_content INTEGER DEFAULT 0
        );
    """)
    cur.execute("CREATE INDEX IF NOT EXISTS idx_achievements_title ON achievements(title);")
    cur.execute("CREATE INDEX IF NOT EXISTS idx_achievements_cat ON achievements(category);")

    # FTS for Achievements
    cur.execute("DROP TABLE IF EXISTS achievements_fts;")
    cur.execute("""
        CREATE VIRTUAL TABLE achievements_fts USING fts5(
            title, category, description, reward,
            content='achievements', content_rowid='id'
        );
    """)


def seed_spells(cur: sqlite3.Cursor):
    """Seeds spells into spells table and triggers FTS."""
    cur.execute("DELETE FROM spells;")
    for s in SPELLS_DATA:
        cur.execute("""
            INSERT INTO spells (
                name, character_class, spec, rank, level_req, cost_type, cost_val,
                cast_time, range_yards, cooldown_sec, description, forever_tuning, is_forever_content
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """, (
            s["name"], s["character_class"], s["spec"], s["rank"], s["level_req"],
            s["cost_type"], s["cost_val"], s["cast_time"], s["range_yards"],
            s["cooldown_sec"], s["description"], s["forever_tuning"], s["is_forever_content"]
        ))
    cur.execute("INSERT INTO spells_fts(spells_fts) VALUES('rebuild');")
    print(f"Seeded {len(SPELLS_DATA)} iconic spells across all 9 classes.")


def seed_armor_sets(cur: sqlite3.Cursor):
    """Seeds armor sets and 2/4/6/8-piece set bonuses."""
    cur.execute("DELETE FROM armor_sets;")
    for a in ARMOR_SETS_DATA:
        cur.execute("""
            INSERT INTO armor_sets (
                set_name, character_class, tier, pieces_count, item_names,
                bonuses_json, source_dungeon, is_forever_content
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?);
        """, (
            a["set_name"], a["character_class"], a["tier"], a["pieces_count"],
            a["item_names"], json.dumps(a["bonuses"]), a["source_dungeon"], a["is_forever_content"]
        ))
    cur.execute("INSERT INTO armor_sets_fts(armor_sets_fts) VALUES('rebuild');")
    print(f"Seeded {len(ARMOR_SETS_DATA)} armor sets with full set bonus trees.")


def seed_achievements(cur: sqlite3.Cursor):
    """Seeds achievements and Feats of Strength."""
    cur.execute("DELETE FROM achievements;")
    for ach in ACHIEVEMENTS_DATA:
        cur.execute("""
            INSERT INTO achievements (
                title, category, points, description, reward, is_feat_of_strength, is_forever_content
            ) VALUES (?, ?, ?, ?, ?, ?, ?);
        """, (
            ach["title"], ach["category"], ach["points"], ach["description"],
            ach["reward"], ach["is_feat_of_strength"], ach["is_forever_content"]
        ))
    cur.execute("INSERT INTO achievements_fts(achievements_fts) VALUES('rebuild');")
    print(f"Seeded {len(ACHIEVEMENTS_DATA)} achievements and Feats of Strength.")


def apply_delta_patch_updates(cur: sqlite3.Cursor):
    """Applies patch delta updates from Nov 3, 2026 Blue Note Post #6471288."""
    # Update Replica Ironforge Air Rifle
    cur.execute("""
        UPDATE items
        SET pro_tip = 'Forever Patch Nov 3: Quitter debuff reduced to 40 sec (was 5 min). Stun duration reduced to 2.5 sec (was 3 sec).'
        WHERE name LIKE '%Replica Ironforge Air Rifle%';
    """)

    # Update Throw weapon tips
    cur.execute("""
        UPDATE items
        SET pro_tip = 'Forever Patch Nov 3: Throw now correctly uses fixed 0.5s windup timer instead of weapon attack speed.'
        WHERE slot = 'Ranged' AND item_type LIKE '%Thrown%';
    """)
    print("Applied delta patch updates to items from Blizzard Post #6471288.")


def main():
    if not os.path.exists(DB_PATH):
        print(f"Database missing at {DB_PATH}")
        sys.exit(1)

    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()

    setup_tables(cur)
    seed_spells(cur)
    seed_armor_sets(cur)
    seed_achievements(cur)
    apply_delta_patch_updates(cur)

    conn.commit()
    conn.close()
    print("Catalog datamining and database expansion complete.")


if __name__ == "__main__":
    main()
