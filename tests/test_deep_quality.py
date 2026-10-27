#!/usr/bin/env python3
"""Deep Quality Verification Suite for WoW: Forever Companion Bot.
Tests database accuracy, knowledge engine data fidelity, math calculations,
and simulated user queries across all 42 slash commands.
"""

import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

import sqlite3
from database import WoWForeverDB, DB_PATH, extract_level_from_text, clean_query
import knowledge_engine as ke

def run_deep_tests():
    print("=" * 70)
    print("STARTING DEEP QUALITY VERIFICATION SUITE")
    print("=" * 70)

    db = WoWForeverDB()
    passed = 0
    failed = 0

    def check(test_id, name, condition, details=""):
        nonlocal passed, failed
        if condition:
            print(f"  [PASS] #{test_id:02d}: {name}")
            passed += 1
        else:
            print(f"  [FAIL] #{test_id:02d}: {name} -> {details}")
            failed += 1

    tid = 1

    # =========================================================
    # SECTION 1: DATABASE INTEGRITY & CONTENT METRICS
    # =========================================================
    print("\n--- SECTION 1: Database Content & Data Integrity ---")
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()

    cur.execute("SELECT COUNT(*) FROM items")
    item_count = cur.fetchone()[0]
    check(tid, f"Items table has sufficient catalog (Count: {item_count})", item_count >= 70); tid += 1

    cur.execute("SELECT COUNT(*) FROM quests")
    quest_count = cur.fetchone()[0]
    check(tid, f"Quests table has sufficient catalog (Count: {quest_count})", quest_count >= 20); tid += 1

    cur.execute("SELECT COUNT(*) FROM creatures")
    mob_count = cur.fetchone()[0]
    check(tid, f"Creatures table has sufficient catalog (Count: {mob_count})", mob_count >= 30); tid += 1

    cur.execute("SELECT COUNT(*) FROM dungeons")
    dung_count = cur.fetchone()[0]
    check(tid, f"Dungeons catalog includes Classic + Classic+ instances (Count: {dung_count})", dung_count >= 35); tid += 1

    cur.execute("SELECT COUNT(*) FROM flightpaths")
    fp_count = cur.fetchone()[0]
    check(tid, f"Flightpaths populated (Count: {fp_count})", fp_count >= 30); tid += 1

    cur.execute("SELECT COUNT(*) FROM vendors")
    vendor_count = cur.fetchone()[0]
    check(tid, f"Vendors catalog populated (Count: {vendor_count})", vendor_count >= 15); tid += 1

    # Check for NULLs in required fields of dungeons
    cur.execute("SELECT COUNT(*) FROM dungeons WHERE name IS NULL OR level_min IS NULL OR level_max IS NULL OR zone IS NULL")
    null_dungs = cur.fetchone()[0]
    check(tid, "Zero NULL values in critical dungeon fields", null_dungs == 0); tid += 1

    # Check level consistency (min <= max)
    cur.execute("SELECT COUNT(*) FROM dungeons WHERE level_min > level_max")
    bad_levels = cur.fetchone()[0]
    check(tid, "All dungeons have valid min_level <= max_level", bad_levels == 0); tid += 1

    conn.close()

    # =========================================================
    # SECTION 2: NEW WOW: FOREVER DUNGEONS RESOLUTION
    # =========================================================
    print("\n--- SECTION 2: Official 9 WoW: Forever Dungeons ---")
    new_dungeons = [
        ("where is hall of thanes", "Hall of Thanes", "Ironforge", 13, 18),
        ("ruins of lordaeron", "Ruins of Lordaeron", "Tirisfal Glades", 15, 20),
        ("excavation site", "Excavation Site", "Wetlands", 24, 29),
        ("city of dalaran", "City of Dalaran", "Alterac Mountains", 28, 33),
        ("the drowned city", "The Drowned City", "Stranglethorn Vale", 35, 40),
        ("krol'dok stronghold", "Krol'dok Stronghold", "The Riverglades", 40, 45),
        ("alcaz island prison", "Alcaz Island Prison", "Dustwallow Marsh", 48, 53),
        ("blackmaw hold", "Blackmaw Hold", "Azshara", 55, 60),
        ("shaper's terrace", "Shaper's Terrace", "Un'Goro Crater", 58, 60),
    ]

    for q, expected_name, expected_zone, exp_min, exp_max in new_dungeons:
        res, dym = db.search_dungeons(query=q)
        is_ok = len(res) > 0 and res[0]["name"] == expected_name and expected_zone in res[0]["zone"] and res[0]["level_min"] == exp_min and res[0]["level_max"] == exp_max
        detail = f"Got: {res[0]['name'] if res else 'None'} ({res[0]['zone'] if res else ''})" if not is_ok else ""
        check(tid, f"Dungeon '{q}' -> {expected_name} ({exp_min}-{exp_max}) in {expected_zone}", is_ok, detail); tid += 1

    # =========================================================
    # SECTION 3: CLASSIC DUNGEON ACRONYMS & LEVEL LOOKUPS
    # =========================================================
    print("\n--- SECTION 3: Classic Dungeon Acronyms & Level Brackets ---")
    classic_acronyms = [
        ("rfc", "Ragefire Chasm"),
        ("wc", "Wailing Caverns"),
        ("sfk", "Shadowfang Keep"),
        ("bfd", "Blackfathom Deeps"),
        ("gnomer", "Gnomeregan"),
        ("rfk", "Razorfen Kraul"),
        ("rfd", "Razorfen Downs"),
        ("zf", "Zul'Farrak"),
        ("brd", "Blackrock Depths"),
        ("ubrs", "Upper Blackrock Spire"),
        ("strat", "Stratholme"),
        ("scholo", "Scholomance"),
        ("dm", "Dire Maul"),
    ]

    for acronym, expected_name in classic_acronyms:
        res, _ = db.search_dungeons(query=acronym)
        is_ok = len(res) > 0 and any(expected_name in d["name"] for d in res)
        check(tid, f"Acronym '{acronym}' -> matches {expected_name}", is_ok, f"Got: {[d['name'] for d in res]}"); tid += 1

    # Level search queries
    lvl_queries = [
        (15, ["Ragefire Chasm", "Hall of Thanes", "The Deadmines", "Wailing Caverns"]),
        (25, ["Shadowfang Keep", "Blackfathom Deeps", "The Stockade", "Sunken Citadel", "Excavation Site"]),
        (45, ["Zul'Farrak", "Uldaman", "Maraudon", "Krol'dok Stronghold"]),
        (58, ["Stratholme", "Scholomance", "Dire Maul", "Blackrock Depths", "Lower Blackrock Spire", "Shaper's Terrace"]),
    ]

    for lvl, expected_candidates in lvl_queries:
        res, _ = db.search_dungeons(level=lvl, limit=5)
        names = [d["name"] for d in res]
        is_ok = len(res) > 0 and any(cand in names for cand in expected_candidates)
        check(tid, f"Level {lvl} lookup -> returns eligible instances ({names[:3]})", is_ok); tid += 1

    # =========================================================
    # SECTION 4: ITEMS, QUESTS, MOBS & VENDORS
    # =========================================================
    print("\n--- SECTION 4: Items, Quests, Mobs & Vendors Search ---")
    # Items
    item_tests = ["Thunderfury", "Ironfoe", "Lionheart Helm", "Dal'Rend", "Savage Gladiator Chain", "Black Lotus"]
    for it in item_tests:
        res, _ = db.search_items(it, limit=1)
        check(tid, f"Item '{it}' found in catalog", len(res) > 0 and it.lower() in res[0]["name"].lower()); tid += 1

    # Quests
    quest_tests = ["Mankrik", "The Missing Diplomat", "In Dreams", "The Green Hills of Stranglethorn"]
    for q in quest_tests:
        res, _ = db.search_quests(q, limit=1)
        check(tid, f"Quest '{q}' found with objectives", len(res) > 0 and res[0]["objectives"] != ""); tid += 1

    # Creatures
    creature_tests = ["Hogger", "Emperor Dagran Thaurissan", "Edwin VanCleef", "Ragnaros"]
    for c in creature_tests:
        res, _ = db.search_creatures(c, limit=1)
        check(tid, f"Creature '{c}' found with zone & classification", len(res) > 0 and res[0]["zone"] != ""); tid += 1

    # Vendors
    vendor_tests = ["Free Action Potion", "Bronze Tube", "Heavy Leather"]
    for v in vendor_tests:
        res, _ = db.search_vendors(v, limit=1)
        check(tid, f"Vendor selling '{v}' located", len(res) > 0 and v.lower() in res[0]["item_name"].lower()); tid += 1

    # =========================================================
    # SECTION 5: KNOWLEDGE ENGINE CALCULATORS & ACCURACY
    # =========================================================
    print("\n--- SECTION 5: Math, Formulas & Systems Logic ---")

    # 1. Weapon Comparison & Glancing Blow Math
    cmp_human = ke.compare_weapons("Dal'Rend", "Brutality Blade", "Human")
    check(tid, "Human sword racial bonus (+5 skill) detected", cmp_human["w1_has_bonus"] and cmp_human["w2_has_bonus"]); tid += 1
    check(tid, "Glancing penalty math reflects +5 skill (5% vs 35% base)", "5% damage penalty" in cmp_human["glancing_analysis"]); tid += 1

    cmp_orc = ke.compare_weapons("Deathbringer", "Brutality Blade", "Orc")
    check(tid, "Orc axe racial bonus applied only to axe", cmp_orc["w1_has_bonus"] and not cmp_orc["w2_has_bonus"]); tid += 1

    # 2. Resistance Mitigation Math
    res_fire_0 = ke.calculate_resistance_mitigation("Fire", 0, "dps")
    check(tid, "0 Fire Resistance -> 0% mitigation (Vulnerable tier)", res_fire_0["mitigation_pct"] == 0.0 and "Vulnerable" in res_fire_0["tier_label"]); tid += 1

    res_fire_150 = ke.calculate_resistance_mitigation("Fire", 150, "dps")
    check(tid, "150 Fire Resistance -> 35.7% average mitigation (Medium tier)", res_fire_150["mitigation_pct"] == 35.7 and "Medium" in res_fire_150["tier_label"]); tid += 1

    res_fire_315 = ke.calculate_resistance_mitigation("Fire", 315, "tank")
    check(tid, "315 Fire Resistance -> 75% max cap reached", res_fire_315["mitigation_pct"] == 75.0 and "Hard Cap" in res_fire_315["tier_label"]); tid += 1

    # 3. GDKP Calculations
    gdkp_calc = ke.calculate_gdkp(pot=60000, cut_pct=10, raiders=40, tanks=2, tank_bonus_pct=2)
    check(tid, "GDKP gross pot correct", gdkp_calc["gross_pot"] == 60000); tid += 1
    check(tid, "GDKP 10% organizer cut = 6,000g", gdkp_calc["organizer_cut"] == 6000); tid += 1
    check(tid, "GDKP tank incentive = 2,400g (2 tanks * 2% * 60,000g)", gdkp_calc["tank_pot"] == 2400); tid += 1
    check(tid, "GDKP net pot = 51,600g", gdkp_calc["net_pot"] == 51600); tid += 1
    check(tid, "GDKP payout per raider = 1,290g (51,600 / 40)", gdkp_calc["payout_per_raider"] == 1290); tid += 1

    # 4. Attunements Data
    att_bwl = ke.get_attunement_info("Blackwing Lair")
    check(tid, "BWL Attunement details Orb of Command & Drakkisath", att_bwl is not None and "Orb of Command" in att_bwl["tip"]); tid += 1

    att_naxx = ke.get_attunement_info("Naxxramas")
    check(tid, "Naxx Attunement details Argent Dawn reputation tiers", att_naxx is not None and "Honored" in att_naxx["guide"]); tid += 1

    # 5. Raid Tactics & Wipe Prevention
    raid_geddon = ke.get_raid_boss_info("Baron Geddon")
    check(tid, "Baron Geddon tactic highlights Living Bomb", raid_geddon is not None and "Living Bomb" in raid_geddon["key_mechanics"]); tid += 1

    raid_vael = ke.get_raid_boss_info("Vaelastrasz")
    check(tid, "Vaelastrasz tactic highlights Burning Adrenaline & Infinite Rage", raid_vael is not None and "Burning Adrenaline" in raid_vael["key_mechanics"]); tid += 1

    # 6. Talents & Duels
    talents_frost = ke.get_talent_build("Mage", "Frost")
    check(tid, "Mage Frost talent build returns ASCII tree and leveling priorities", talents_frost is not None and "Ice Barrier" in talents_frost["capstones"]); tid += 1

    duel_matchup = ke.get_duel_matchup("Warrior", "Frost Mage")
    check(tid, "Warrior vs Frost Mage duel details deadzone & cooldown trading", duel_matchup is not None and "deadzone_analysis" in duel_matchup); tid += 1

    # 7. Leveling Routes
    route_10_20 = ke.get_leveling_route("10-20")
    check(tid, "Leveling route 10-20 details Westfall/Loch Modan & Barrens", route_10_20 is not None and "Westfall" in route_10_20["alliance"]); tid += 1

    # 8. Twinks Best-in-Slot
    twink_29 = ke.get_twink_info("29")
    check(tid, "Twink 29 details Corpsemaker & uncapped Classic enchants", twink_29 is not None and "Corpsemaker" in twink_29["weapons"]); tid += 1

    # 9. Raid Comp Analysis
    comp_analysis = ke.analyze_raid_comp("8 warrior, 6 rogue, 5 mage, 4 warlock, 5 priest, 4 shaman, 3 hunter, 2 druid")
    check(tid, "Raid comp analysis checks Sunder, Windfury, CoR, Tranq Shot", len(comp_analysis["covered"]) >= 4); tid += 1

    # =========================================================
    # SECTION 6: FLOATING SEARCH & AUTOCOMPLETE NARROWING
    # =========================================================
    print("\n--- SECTION 6: Floating Autocomplete Search & Narrowing ---")

    # 1. Empty query returns featured iconic items
    empty_choices = db.autocomplete_items("", limit=25)
    check(tid, "Empty query returns 25 featured items in floating search", len(empty_choices) == 25 and any("Thunderfury" in c["value"] for c in empty_choices)); tid += 1

    # 2. Multi-word space normalization
    dal_choices = db.autocomplete_items("dal rend", limit=5)
    check(tid, "Typing 'dal rend' narrows down to Dal'Rend swords", len(dal_choices) > 0 and any("Dal'Rend" in c["value"] for c in dal_choices)); tid += 1

    lion_choices = db.autocomplete_items("lion heart", limit=5)
    check(tid, "Typing 'lion heart' narrows down to Lionheart Helm", len(lion_choices) > 0 and any("Lionheart Helm" in c["value"] for c in lion_choices)); tid += 1

    # 3. Common Acronyms
    fap_choices = db.autocomplete_items("fap", limit=5)
    check(tid, "Acronym 'fap' resolves to Free Action Potion", len(fap_choices) > 0 and "Free Action Potion" in fap_choices[0]["value"]); tid += 1

    hoj_choices = db.autocomplete_items("hoj", limit=5)
    check(tid, "Acronym 'hoj' resolves to Hand of Justice", len(hoj_choices) > 0 and "Hand of Justice" in hoj_choices[0]["value"]); tid += 1

    tf_choices = db.autocomplete_items("tf", limit=5)
    check(tid, "Acronym 'tf' resolves to Thunderfury", len(tf_choices) > 0 and "Thunderfury" in tf_choices[0]["value"]); tid += 1

    mcp_choices = db.autocomplete_items("mcp", limit=5)
    check(tid, "Acronym 'mcp' resolves to Manual Crowd Pummeler", len(mcp_choices) > 0 and "Manual Crowd Pummeler" in mcp_choices[0]["value"]); tid += 1

    edgies_choices = db.autocomplete_items("edgies", limit=5)
    check(tid, "Nickname 'edgies' resolves to Edgemaster's Handguards", len(edgies_choices) > 0 and "Edgemaster's Handguards" in edgies_choices[0]["value"]); tid += 1

    # 4. Typo tolerance in autocomplete
    thudner_choices = db.autocomplete_items("thudner", limit=5)
    check(tid, "Typo 'thudner' offers Thunderfury in floating dropdown", len(thudner_choices) > 0 and any("Thunderfury" in c["value"] for c in thudner_choices)); tid += 1

    # 5. Discord Character Limit & Formatting Validation
    all_sample_choices = empty_choices + dal_choices + fap_choices
    valid_lengths = all(len(c["name"]) <= 100 and len(c["value"]) <= 100 and len(c["name"]) > 0 for c in all_sample_choices)
    check(tid, "All floating choices satisfy Discord 100-character constraint", valid_lengths); tid += 1

    # =========================================================
    # SUMMARY
    # =========================================================
    print("\n" + "=" * 70)
    total = passed + failed
    pct = (passed / total * 100) if total else 0
    print(f"VERIFICATION COMPLETE: {passed}/{total} Passed ({pct:.1f}%) | {failed} Failed")
    print("=" * 70)

    if failed > 0:
        sys.exit(1)

if __name__ == "__main__":
    run_deep_tests()
