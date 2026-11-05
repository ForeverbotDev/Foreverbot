#!/usr/bin/env python3
"""
Enrich creature intelligence in wow_forever.db with:
1. Exact creature families (from ground-truth cache + keyword heuristics).
2. Deep tactical combat strategy notes, crowd control vulnerabilities, and mechanics.
3. Dungeon sub-zone and encounter locations.
"""

import sqlite3
import glob
import json
import re
import os

DB_PATH = "wow_forever.db"
CACHE_DIR = "scratch/ground_truth/forever_cache/npc"

# Famous classic / forever boss encounter tactics
BOSS_TACTICS = {
    # Shadowfang Keep
    "Archmage Arugal": "Teleports between high balcony platforms and casts Void Bolt (heavy Shadow damage) and Thundershock. Casts Arugal's Curse (charms the highest threat target). Line-of-sight Void Bolts behind pillars. Polymorph or Fear charmed party members until dispelled.",
    "Baron Silverlaine": "Casts Veil of Shadow on the tank (reducing healing taken by 75%). Healers must immediately dispel curse or swap burst heals. Watch for high physical burst.",
    "Commander Springvale": "Unholy melee paladin boss. Uses Shield of the Faithful (absorbs damage) and Desecration. Focus adds down first, then burn Springvale. Dispel magic buffs.",
    "Sever": "Brutal melee cleaver. High physical strikes. Tank keep faced away from party to prevent cleave on melee DPS.",
    "Rethilgore": "Soul drainer fiend. Enrages at 30% health, gaining attack speed. Defensive cooldowns on tank; burn with maximum DPS during enrage.",
    "Nandeb the Dark": "Shadow caster. Casts Shadow Bolt Volley and Shadow Word: Pain. Interrupt shadow casts and cleanse curse/shadow dots.",
    "Razorclaw the Butcher": "High attack speed butcher. Applies stacking Butcher's Cleaver bleed. Keep tank topped; stuns and disarms are effective.",
    "Odo the Blindwatcher": "Accompanied by bat pets. Blinds the tank, dropping threat. Off-tank or hunter pet pick up boss during Blind; kill bats first.",
    "Deathsworn Captain": "Undead warrior. Summons shadowy adds and fears nearby players. Shackle or turn undead adds; keep boss pinned against wall.",
    "Haunted Servitor": "Undead caster minion. Casts Haunting Spirits (shadow DoT) and Shadow Bolt. Priority interrupt; vulnerable to Shackle Undead and Turn Undead. Drops prized BoE epics & rares (Shadowfang, Mindthrust Bracers, Witching Stave).",

    # Deadmines
    "Edwin VanCleef": "Rogue guildmaster. Applies Thrash (extra attacks). At 75% and 50% health, summons two Defias Blackguards. Off-tank or CC the Blackguards while burning VanCleef. Disarm or stun through evasion.",
    "Mr. Smite": "Three-phase pirate boss. At 66% and 33% health, casts Smite Slam (group-wide stun) and runs to weapon chest to equip heavier weapons. Reset positioning after each stun. Save lust/burst cooldowns for final two-handed phase.",
    "Captain Greenskin": "Accompanied by Defias guards. Uses Cleave and Poisoned Harpoon. Kill adds first; tank face boss away from party.",
    "Cookie": "Murloc chef. Throws Acid Acid and Rotten Apples onto ground. Don't stand in green pools. Interrupt Cookie's cooking casts.",
    "Rhahk'Zor": "Ogre brute. Heavy physical damage and Rhahk'Zor Slam (knockdown and threat wipe). Tank taunt back immediately after slam.",
    "Sneed": "Two-phase mechanical boss. Defeat Sneed's Shredder first (watch out for Terrify fear and buzzsaw). Sneed ejects at 0% and must be killed separately.",
    "Gilnid": "Goblin blacksmith. Summons molten metal adds. Drag Gilnid away from furnaces and focus adds down quickly.",

    # Wailing Caverns
    "Mutanus the Devourer": "Final Nightmare boss summoned after escorting Disciple of Naralex. Uses Naralex's Nightmare (sleep) and Thundershock (AoE stun). Dispel sleep on healer immediately; save mana through the preceding add waves.",
    "Lord Cobrahn": "Druid of the Fang. Casts Poison and Lightning Bolt; shifts into serpent form at 40% health. Interrupt heals and poison casts.",
    "Lord Pythas": "Druid of the Fang caster. Casts Sleep and Thunderclap. Dispel magic sleep immediately.",
    "Lady Anacondra": "Druid of the Fang. Casts Lightning Bolt and Sleep. Interrupt Healing Touch.",
    "Lord Serpentis": "Druid leader. Casts Sleep and transforms into serpent. Kill Serpentis before Mutanus ritual.",
    "Verdan the Everliving": "Ancient tree giant. Tremendous melee damage via Grasping Vines. Tank must use shield block and armor buffs; kite if healer runs low on mana.",
    "Kresh": "Giant turtle. Shell shield reflects damage at low health. Pause DPS when shell shield activates.",

    # Scarlet Monastery
    "High Inquisitor Whitemane": "High Priestess. Casts Holy Smite and Power Word: Shield. When Mograine falls, enters arena, casts Deep Slumber (AoE sleep), and resurrects Mograine with full health. Save group burst for Whitemane once she begins resurrection.",
    "Scarlet Commander Mograine": "Holy crusader. High melee damage and Retribution Aura. Resurrected by Whitemane. Focus Whitemane down second, then finish Mograine.",
    "Herod": "Scarlet Champion. Casts Whirlwind (high AoE physical damage) and Cleave. Melee DPS MUST run out when Herod shouts 'Blades of Light!'. Summons wave of scarlet trainees at 0% health.",
    "Houndmaster Loksey": "Accompanied by hunting dogs. Use Polymorph or Trap on Loksey while burning down the dogs, then defeat Loksey.",
    "Arcanist Doan": "Fire/Arcane mage. At 50% health, casts Silence on all players, shields himself, and begins Detonation (massive AoE fire blast). Line-of-sight behind pillars when Detonation begins!",
    "Bloodmage Thalnos": "Undead fire mage. Casts Flame Shock and summons ghostly souls. Dispel flame debuffs; AoE down ghostly adds.",

    # Zul'Farrak
    "Antu'sul": "Sul'thraze guardian. Summons waves of Sul'thraze vipers and casts Earth Shock. Kill vipers with AoE immediately.",
    "Chief Ukorz Sandscalp": "Sandfury chieftain. Accompanied by Ruuzlu. Enrages heavily when Ruuzlu dies. Crowd control Ruuzlu or cleave both down evenly.",
    "Gahz'rilla": "Hydra summoned with Mallet of Zul'Farrak. Casts Slam (knocks players high into the air) and Freeze. Fight near water to soften fall damage.",
    "Witch Doctor Zum'rah": "Summons skeleton zombies from graveyard tombs. Interrupt shadow casts and burn ward totems immediately.",

    # Stratholme
    "Baron Rivendare": "Lord of Stratholme. Unholy Aura pulses continuous shadow damage to entire group. Summons continuous skeleton adds. Tank face Baron away; healers rotate shadow protection potions. Burn boss before aura drains healer mana.",
    "Maleki the Pallid": "Necromancer. Freezes tank in Ice Tomb and drops threat. Off-tank or hunter pet pick up boss; dispel frost debuffs.",
    "Nerub'enkan": "Crypt lord. Casts Crypt Scarabs and Enveloping Webs. Tank swap on web; AoE scarabs.",
    "Ramstein the Gorger": "Abomination. Enormous melee damage and Flub. High armor tanking required; prepare for wave of Black Guard swordsmen immediately after.",

    # Scholomance
    "Darkmaster Gandling": "Headmaster of Scholomance. Randomly teleports individual party members into locked dungeon rooms filled with zombies. Kill zombie adds quickly to unlock room and rejoin the fight.",
    "Doctor Theolen Krastinov": "Butcher. Frenzies, increasing attack speed. Disarm and stun during Frenzy.",
    "Jandice Barov": "Illusionist. Creates dozens of clone illusions. AoE burst to identify and target the real Jandice.",
    "Rattlegore": "Bone construct. Tremendous physical damage that scales with bone armor buffs. Dispel/purge bone armor; tank mitigation priority.",

    # Molten Core / Raids
    "Ragnaros": "Firelord. Submerges at 3 minutes, spawning Sons of Flame. High fire resistance gear (200+ FR) required. Knockbacks require wall tanking. Ranged spread 15 yards apart to avoid Wrath of Ragnaros.",
    "Majordomo Executus": "Accompanied by 4 Flamewaker Priests and 4 Healers. Crowd control priests with Sheep. Kill adds to defeat Executus (he surrenders when all guards die).",
    "Baron Geddon": "Living Bomb on random player (target explodes after 8s for fatal AoE damage). Living Bomb target MUST run out of the raid immediately! Dispel Ignite Mana from casters.",
    "Lucifron": "Applies Lucifron's Curse (doubles mana/rage/energy costs) and Shadow Shock. Mages and Druids must prioritize Decurse above all else.",
    "Gehennas": "Gehennas' Curse reduces healing received by 75%. Decurse tank immediately; move out of Rain of Fire.",
    "Garr": "Accompanied by 8 Firesworn adds. Warlocks Banish 4-5 adds; kill remaining adds away from raid (they explode upon death). Purge Garr's Enrage.",
    "Onyxia": "Three-phase dragon encounter. Phase 1: Tank against north wall, watch for Cleave, Flame Breath, and Tail Sweep. Phase 2: Onyxia flies; spread out to minimize Deep Breath cone. Phase 3: Bellowing Roar fears raid; keep Fear Ward on main tank.",
}

# Family CC vulnerability and combat matrix
FAMILY_CC_MAP = {
    "Undead": {
        "cc": "CC Vulnerabilities: Shackle Undead (Priest), Turn Undead (Paladin), Freezing Trap (Hunter). Immune to Polymorph, Bleeds, and Poison.",
        "immunities": "Immune to Polymorph, Bleed, Poison.",
        "tactic": "Undead minion. Holy spells deal additional damage. Prioritize Shackle Undead to control pulls."
    },
    "Humanoid": {
        "cc": "CC Vulnerabilities: Polymorph (Mage), Sap (Rogue), Freezing Trap (Hunter), Blind, Kidney Shot, Stuns. Flees at low health.",
        "immunities": "None.",
        "tactic": "Humanoid fighter. Flees when health drops below 15%; apply snaring effects or stuns to prevent pulling adjacent packs."
    },
    "Beast": {
        "cc": "CC Vulnerabilities: Hibernate (Druid), Scare Beast (Hunter), Polymorph (Mage), Freezing Trap (Hunter).",
        "immunities": "None.",
        "tactic": "Beast enemy. Susceptible to Druid Hibernate and Hunter Scare Beast. Watch for Enrage, Frenzy, or charge openers."
    },
    "Demon": {
        "cc": "CC Vulnerabilities: Banish (Warlock), Enslave Demon (Warlock), Exorcism (Paladin). Immune to Polymorph.",
        "immunities": "Immune to Polymorph.",
        "tactic": "Demonic minion. Warlocks can Banish or Enslave. Immune to Mage Polymorph. Cleanses and Shadow protection recommended."
    },
    "Elemental": {
        "cc": "CC Vulnerabilities: Banish (Warlock). Immune to Bleeds, Poisons, and Disease effects.",
        "immunities": "Immune to Bleed, Poison, Disease.",
        "tactic": "Elemental entity. Warlock Banish is the primary crowd control. Immune to physical bleeds and rogue poisons."
    },
    "Dragonkin": {
        "cc": "CC Vulnerabilities: Sleep (Druid Slumber), Stuns, Disorients. Immune to Polymorph and Trap.",
        "immunities": "Immune to Polymorph.",
        "tactic": "Dragonkin combatant. Tank must face away from the group to prevent frontal cone breath damage and tail swipes."
    },
    "Giant": {
        "cc": "CC Vulnerabilities: Stuns, Movement Snares, Kiting. High physical crush damage.",
        "immunities": "Immune to Polymorph and Sap.",
        "tactic": "Giant behemoth. Heavy physical crush and cleave damage. Keep tank mitigated with defensive cooldowns; kite when enraged."
    },
    "Mechanical": {
        "cc": "CC Vulnerabilities: Freezing Trap (Hunter), Stuns. Immune to Bleed, Poison, Disease, and Fear effects.",
        "immunities": "Immune to Bleed, Poison, Disease, Fear.",
        "tactic": "Clockwork automaton. Immune to bleed, poison, disease, and fear effects. Vulnerable to hunter traps and nature damage."
    },
    "Critter": {
        "cc": "Harmless ambient creature.",
        "immunities": "None.",
        "tactic": "Peaceful non-combat creature."
    }
}

# Dungeon area mappings
DUNGEON_LOCATIONS = {
    "Shadowfang Keep": "Courtyard, Butcher's Quarters, and Arugal's Tower",
    "Deadmines": "The Smelting Vat, Goblin Foundry, and Ironclad Cove",
    "Wailing Caverns": "Fissure of the Crags and Sludge Fen",
    "Blackfathom Deeps": "The Pool of Ask'ar and Moonshrine Ruins",
    "Scarlet Monastery": "Graveyard, Library, Armory, and Cathedral",
    "Razorfen Kraul": "Thorn Caves and Death's Head Den",
    "Razorfen Downs": "Spiral Thorns and Crag of the Undead",
    "Uldaman": "Excavation Halls and Chamber of the Stone Watcher",
    "Zul'Farrak": "Sandfury Pyramids and Sacred Pool",
    "Maraudon": "Purple Crystal Caverns, Orange Grotto, and Zaetar's Grave",
    "Sunken Temple": "Atal'ai Sanctum, Hall of the Serpent, and Eranikus Lair",
    "Blackrock Depths": "Shadowforge City, Ring of Law, and Molten Bridge",
    "Lower Blackrock Spire": "Tazz'Alor, Spirestone Den, and Hall of the Blackhand",
    "Upper Blackrock Spire": "Dragonspire Hall, Rookery, and Stadium of Blackrock",
    "Stratholme": "Crusaders' Square, Festival Lane, and Baron's Slaughterhouse",
    "Scholomance": "The Great Ossuary, Lab of Krastinov, and Gandling's Study",
    "Dire Maul": "Warpwood Grotto (East), Capital Gardens (West), Gordok Commons (North)",
    "Molten Core": "Lava Core Chambers and Ragnaros' Subterranean Lair",
    "Onyxia's Lair": "Brood Den and Onyxia's Perch",
    "Blackwing Lair": "Dragonspire Peak and Nefarian's Laboratory",
    "Zul'Gurub": "Hakkar's Temple, Edge of Madness, and Bloodfire Pit",
}


def infer_family_from_name(name: str) -> str:
    n = name.lower()
    if any(k in n for k in ["wolf", "bear", "boar", "spider", "tiger", "raptor", "lion", "cat", "crawler", "stag", "crocolisk", "basilisk", "gorilla", "hyena", "scorpid", "serpent", "bat", "bird", "strider", "owl", "crab", "turtle", "wasp", "tarantula", "mastiff", "lynx"]):
        return "Beast"
    if any(k in n for k in ["skeleton", "zombie", "ghoul", "geist", "ghost", "spectre", "wraith", "shade", "lich", "banshee", "abomination", "servitor", "mummy", "corpse", "haunted"]):
        return "Undead"
    if any(k in n for k in ["demon", "succubus", "felhound", "imp", "voidwalker", "infernal", "doomguard", "dreadlord", "satyr", "incubus", "hellhound"]):
        return "Demon"
    if any(k in n for k in ["elemental", "water", "fire", "air", "earth", "slime", "ooze", "spark", "ember"]):
        return "Elemental"
    if any(k in n for k in ["dragon", "whelp", "drake", "wyrm", "dragonkin"]):
        return "Dragonkin"
    if any(k in n for k in ["giant", "colossus", "goliath", "ettin", "cyclops"]):
        return "Giant"
    if any(k in n for k in ["golem", "mech", "robot", "clockwork", "shredder", "alarm-o-bot"]):
        return "Mechanical"
    if any(k in n for k in ["rabbit", "frog", "toad", "squirrel", "prairie dog", "cockroach", "deer", "hare", "sheep", "fawn", "chicken"]):
        return "Critter"
    return "Humanoid"


def generate_strategy_notes(name: str, classification: str, family: str, zone: str, health: int, min_lvl: int, max_lvl: int) -> str:
    # 1. Check if famous named boss
    if name in BOSS_TACTICS:
        return BOSS_TACTICS[name]

    parts = []
    fam_info = FAMILY_CC_MAP.get(family, FAMILY_CC_MAP["Humanoid"])

    # Classification & Role analysis
    n = name.lower()
    is_caster = any(k in n for k in ["servitor", "sorcerer", "warlock", "mage", "necromancer", "conjurer", "acolyte", "cultist", "pyromancer", "shadowcaster", "shaman", "witch", "defiler", "elementalist", "summoner", "seer"])
    is_stealth = any(k in n for k in ["assassin", "rogue", "shadow", "stalker", "infiltrator", "thief", "cutpurse", "ambusher", "skulker"])
    is_healer = any(k in n for k in ["priest", "healer", "cleric", "medic", "diviner", "apothecary", "restorer", "witchdoctor"])
    is_bruiser = any(k in n for k in ["warrior", "guard", "berserker", "enforcer", "defender", "gladiator", "slayer", "champion", "butcher", "brawler", "brute"])
    is_ranged = any(k in n for k in ["archer", "ranger", "hunter", "marksman", "rifleman", "sharpshooter"])

    if classification in ("Boss", "Rare Elite"):
        parts.append(f"Major encounter in {zone}.")
    elif classification == "Elite":
        parts.append(f"Elite {family} encounter in {zone}.")
    elif classification == "Rare":
        parts.append(f"Rare spawn in {zone}. High value target.")

    # Role specific tactics
    if is_healer:
        parts.append("High priority kill target. Interrupt, kick, or stun healing casts immediately to prevent prolonging combat.")
    elif is_caster:
        parts.append("Dangerous ranged spellcaster. Interrupt cast bars with Kick, Pummel, or Counterspell. Dispel magic and curse debuffs quickly.")
    elif is_stealth:
        parts.append("Stealth ambush combatant. Utilize Hunter's Mark, Faerie Fire, or Flares. Keep defensive buffs up to counter opener burst.")
    elif is_bruiser:
        parts.append("Heavy physical melee fighter. Tank keep faced away from group to prevent frontal cleaves; watch out for enrage under 25% health.")
    elif is_ranged:
        parts.append("Ranged physical attacker. Line-of-sight around corners or obstacles to pull into melee range for efficient AoE grouping.")
    elif family == "Beast":
        parts.append("Beast attacker. Watch for knockdown bites, bleeds, and frenzy enrage at low health.")
    elif family == "Undead":
        parts.append("Undead foe. Susceptible to Priest Shackle Undead and Paladin Exorcism. High shadow resistance recommended.")
    else:
        parts.append(f"{classification} {family} encounter.")

    # Add CC Vulnerability note
    parts.append(fam_info["cc"])

    return " ".join(parts)


def run_enrichment():
    print(f"Connecting to {DB_PATH}...")
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()

    # Ensure family column exists
    c.execute("PRAGMA table_info(creatures)")
    cols = [r[1] for r in c.fetchall()]
    if "family" not in cols:
        c.execute("ALTER TABLE creatures ADD COLUMN family TEXT DEFAULT ''")
        conn.commit()

    # Step 1: Update family from cache files
    cache_files = glob.glob(os.path.join(CACHE_DIR, "*.json"))
    print(f"Loaded {len(cache_files)} NPC cache files...")

    cache_family_map = {}
    for fpath in cache_files:
        fname = os.path.basename(fpath)
        cid_str = fname.replace(".json", "")
        if not cid_str.isdigit():
            continue
        cid = int(cid_str)
        try:
            with open(fpath, "r", encoding="utf-8") as fp:
                d = json.load(fp)
                tt = d.get("tooltip", "")
                m = re.search(r"Level\s+\d+(?:\s*-\s*\d+)?\s+([A-Za-z\s]+?)(?:\s*\((.*?)\))?</td>", tt)
                if m:
                    fam = m.group(1).strip()
                    cls_found = m.group(2).strip() if m.group(2) else None
                    cache_family_map[cid] = (fam, cls_found)
        except Exception:
            pass

    # Step 2: Fetch all creatures
    c.execute("SELECT id, name, level_min, level_max, classification, zone, location_details, health, strategy_notes, family FROM creatures")
    creatures = c.fetchall()
    print(f"Processing {len(creatures)} creatures...")

    updated_rows = []
    for row in creatures:
        cid, name, l_min, l_max, classification, zone, loc, hp, strat, fam = row

        # Determine family
        new_fam = fam
        new_class = classification
        if cid in cache_family_map:
            cached_fam, cached_cls = cache_family_map[cid]
            if cached_fam:
                new_fam = cached_fam
            if cached_cls and cached_cls != "Normal":
                new_class = cached_cls
        
        if not new_fam:
            new_fam = infer_family_from_name(name)

        # Determine location details
        new_loc = loc or ""
        if not new_loc and zone in DUNGEON_LOCATIONS:
            new_loc = DUNGEON_LOCATIONS[zone]

        # Generate strategy
        new_strat = strat or ""
        if not new_strat or len(new_strat) < 15:
            new_strat = generate_strategy_notes(name, new_class, new_fam, zone, hp, l_min or 1, l_max or 1)

        updated_rows.append((new_fam, new_class, new_loc, new_strat, cid))

    print(f"Applying updates for {len(updated_rows)} creatures...")
    c.executemany("""
        UPDATE creatures
        SET family = ?, classification = ?, location_details = ?, strategy_notes = ?
        WHERE id = ?
    """, updated_rows)
    conn.commit()

    # Verification query
    c.execute("SELECT COUNT(*) FROM creatures WHERE strategy_notes != ''")
    strat_cnt = c.fetchone()[0]
    c.execute("SELECT COUNT(*) FROM creatures WHERE family != ''")
    fam_cnt = c.fetchone()[0]
    print(f"Enrichment Complete: {fam_cnt:,} creatures have family, {strat_cnt:,} have deep strategy notes!")

    # Check Haunted Servitor
    c.execute("SELECT id, name, classification, family, zone, location_details, strategy_notes FROM creatures WHERE id = 3875")
    hs = c.fetchone()
    print("\nVerified Haunted Servitor:")
    print(f"  Name: {hs[1]} ({hs[3]} {hs[2]})")
    print(f"  Location: {hs[4]} - {hs[5]}")
    print(f"  Strategy: {hs[6]}")

    conn.close()


if __name__ == "__main__":
    run_enrichment()
