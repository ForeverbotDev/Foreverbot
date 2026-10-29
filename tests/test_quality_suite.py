#!/usr/bin/env python3
"""Comprehensive Quality Testing Suite for WoW: Forever Bot."""

import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from database import WoWForeverDB
import knowledge_engine as ke

def run_tests():
    print("=" * 60)
    print("RUNNING COMPREHENSIVE BOT QUALITY TEST SUITE")
    print("=" * 60)
    
    db = WoWForeverDB()
    passed = 0
    total = 0

    def assert_test(name, condition, details=""):
        nonlocal passed, total
        total += 1
        if condition:
            print(f"  [PASS] {name}")
            passed += 1
        else:
            print(f"  [FAIL] {name} - {details}")

    # 1. Dungeons Lookup Test
    print("\n1. Testing Dungeon Engine & Hall of Thanes...")
    dungs, dym = db.search_dungeons("where is hall of thanes")
    assert_test("Hall of Thanes resolves correctly", len(dungs) > 0 and dungs[0]["name"] == "Hall of Thanes")
    assert_test("Hall of Thanes is in Ironforge", len(dungs) > 0 and "Ironforge" in dungs[0]["zone"])
    assert_test("Hall of Thanes is level 13-18", len(dungs) > 0 and dungs[0]["level_min"] == 13 and dungs[0]["level_max"] == 18)

    dungs_lord, _ = db.search_dungeons("ruins of lordaeron")
    assert_test("Ruins of Lordaeron resolves", len(dungs_lord) > 0 and dungs_lord[0]["name"] == "Ruins of Lordaeron")

    dungs_lvl, _ = db.search_dungeons(level=45)
    assert_test("Level 45 dungeon resolves Zul'Farrak or Uldaman", len(dungs_lvl) > 0 and any("Zul'Farrak" in d["name"] or "Uldaman" in d["name"] for d in dungs_lvl))

    # 2. Gold Farming Engine Test
    print("\n2. Testing Gold Farming Engine...")
    gf1 = ke.get_gold_farm_info("dm east")
    assert_test("DM East farm guide exists", gf1 is not None and "Dire Maul East" in gf1["title"])
    gf2 = ke.get_gold_farm_info(None)
    assert_test("Default farm guide works with None", gf2 is not None)
    gf3 = ke.get_gold_farm_info("mara")
    assert_test("Fuzzy Maraudon farm matches", gf3 is not None and "Maraudon" in gf3["title"])

    # 3. Weapons Comparison Engine
    print("\n3. Testing Weapon Comparison & Glancing Math...")
    cmp_res = ke.compare_weapons("Dal'Rend", "Brutality Blade", "Human")
    assert_test("Compare weapons executes cleanly", "weapon1" in cmp_res and "weapon2" in cmp_res)
    assert_test("Glancing analysis generated", "glancing_analysis" in cmp_res and len(cmp_res["glancing_analysis"]) > 0)

    # 4. Items Lookup Test
    print("\n4. Testing Items Database...")
    items, _ = db.search_items("Thunderfury")
    assert_test("Thunderfury found in items", len(items) > 0 and "Thunderfury" in items[0]["name"])
    items_t, _ = db.search_items("thundrfury")
    assert_test("Typo tolerance works for items", len(items_t) > 0 or _ is not None)

    # 5. Quests Lookup Test
    print("\n5. Testing Quests Database...")
    quests, _ = db.search_quests("Mankrik")
    assert_test("Mankrik quest found", len(quests) > 0)

    # 6. Creatures Lookup Test
    print("\n6. Testing Creatures Database...")
    mobs, _ = db.search_creatures("Ragnaros")
    assert_test("Ragnaros creature found", len(mobs) > 0 and "Ragnaros" in mobs[0]["name"])

    # 7. Attunements Test
    print("\n7. Testing Attunements...")
    att_mc = ke.get_attunement_info("Molten Core")
    assert_test("Molten Core attunement found", att_mc is not None and "Attunement to the Core" in att_mc["title"])
    att_ony = ke.get_attunement_info("Onyxia")
    assert_test("Onyxia attunement found", att_ony is not None and "Drakefire Amulet" in att_ony["alliance"])

    # 8. Dungeon Keys Test
    print("\n8. Testing Dungeon Keys...")
    key_sf = ke.get_dungeon_key_info("Shadowforge")
    assert_test("Shadowforge Key found", key_sf is not None and "Shadowforge Key" in key_sf["name"])

    # 9. Resistance Calculator Test
    print("\n9. Testing Resistance Mitigation Engine...")
    res_calc = ke.calculate_resistance_mitigation("Fire", 150, "dps")
    assert_test("Fire resist 150 calculates tiers", "mitigation_pct" in res_calc and "tier_label" in res_calc)

    # 10. Raid Comp Analyzer Test
    print("\n10. Testing Raid Comp Analyzer...")
    comp = ke.analyze_raid_comp("8 warr, 5 mage, 4 rogue, 4 priest, 3 hunter, 5 shaman")
    assert_test("Raid comp analyzes synergies", "covered" in comp and "missing" in comp)

    # 11. PvP System Test
    print("\n11. Testing PvP System...")
    pvp = ke.get_pvp_info("ranks")
    assert_test("PvP ranks data returned", pvp is not None and "title" in pvp)

    # 12. GDKP Calculator Test
    print("\n12. Testing GDKP Calculator...")
    gdkp = ke.calculate_gdkp(50000, 10, 40, 2, 2)
    assert_test("GDKP calculates organizer cut & net pot", gdkp["gross_pot"] == 50000 and gdkp["organizer_cut"] == 5000)

    # 13. World Events Test
    print("\n13. Testing World Events & Resets...")
    events = ke.get_world_events_info()
    assert_test("World events return active timers", "gurubashi" in events and "fishing" in events and "dmf" in events)
    lockouts = ke.get_raid_lockouts()
    assert_test("Raid lockouts calculate countdowns", "weekly" in lockouts and "onyxia" in lockouts)

    # 14. Talents & PvP Honor Test
    print("\n14. Testing Talents & PvP Honor Systems...")
    talents = ke.get_talent_build("Warrior", "Fury")
    assert_test("Warrior Fury talent build returns", talents is not None and "tree_display" in talents)
    pvp = ke.get_pvp_info("rank 14")
    assert_test("PvP Rank 14 returns", pvp is not None and "Grand Marshal" in pvp["description"])

    # 15. Twinks & Leveling Routes Test
    print("\n15. Testing Twink & Speedleveling Routes...")
    twink = ke.get_twink_info("19")
    assert_test("Lvl 19 Twink info returns", twink is not None and "weapons" in twink)
    route = ke.get_leveling_route("10-20")
    assert_test("10-20 leveling route returns", route is not None and "alliance" in route)

    print("\n" + "=" * 60)
    print(f"RESULTS: {passed} / {total} tests passed ({passed/total*100:.1f}%)")
    print("=" * 60)

    if passed < total:
        sys.exit(1)

if __name__ == "__main__":
    run_tests()
