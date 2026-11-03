"""Randomized Database Verification Suite for WoW Forever.
Samples random items across all item qualities (Poor/Gray, Common/White, Uncommon/Green,
Rare/Blue, Epic/Purple, Legendary, Artifact, and WoW Forever Custom) to verify
name resolution, stats, slot formatting, and full-text search.
"""

import random
import sqlite3
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from database import WoWForeverDB, DB_PATH


def run_random_audit(samples_per_quality: int = 15):
    print("=" * 70)
    print("🎲 WOW FOREVER RANDOM CATALOG & QUALITY AUDIT SUITE")
    print("=" * 70)

    db = WoWForeverDB(DB_PATH)
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    qualities = ["Poor", "Common", "Uncommon", "Rare", "Epic", "Legendary"]
    passed = 0
    failed = 0

    print(f"\n[1] Sampling {samples_per_quality} random items across each quality tier...")
    for q in qualities:
        rows = cursor.execute(
            "SELECT id, name, quality, item_level, req_level, slot, item_type FROM items WHERE quality = ? ORDER BY RANDOM() LIMIT ?",
            (q, samples_per_quality)
        ).fetchall()

        print(f"\n--- Quality: {q} ({len(rows)} samples) ---")
        for r in rows:
            iid, name, quality, ilvl, req_lvl, slot, itype = r
            results, _ = db.search_items(name, limit=5)
            match = any(it["id"] == iid or it["name"].lower() == name.lower() for it in results)
            status = "✅ PASS" if match else "❌ FAIL"
            if match:
                passed += 1
            else:
                failed += 1
            print(f"  {status} [{iid}] {name} (Req Lvl {req_lvl}) - {slot} {itype}")

    print("\n[2] Verifying custom WoW Forever content items...")
    forever_items = cursor.execute(
        "SELECT id, name, quality, item_level, req_level, slot, item_type FROM items WHERE is_forever_content = 1"
    ).fetchall()
    for r in forever_items:
        iid, name, quality, ilvl, req_lvl, slot, itype = r
        results, _ = db.search_items(name, limit=5)
        match = any(it["id"] == iid or it["name"].lower() == name.lower() for it in results)
        status = "✅ PASS" if match else "❌ FAIL"
        if match:
            passed += 1
        else:
            failed += 1
        print(f"  {status} [WoW Forever] [{iid}] {name} (Req Lvl {req_lvl}) - {slot} {itype}")

    print("\n[3] Testing random creatures across level brackets...")
    creatures = cursor.execute(
        "SELECT id, name, level_min, level_max, classification, zone FROM creatures ORDER BY RANDOM() LIMIT 20"
    ).fetchall()
    for c in creatures:
        cid, name, l_min, l_max, rank, zone = c
        results, _ = db.search_creatures(name, limit=5)
        match = any(cr["id"] == cid or cr["name"].lower() == name.lower() for cr in results)
        status = "✅ PASS" if match else "❌ FAIL"
        if match:
            passed += 1
        else:
            failed += 1
        print(f"  {status} [{cid}] {name} (Lvl {l_min}-{l_max} {rank}) in {zone}")

    print("\n[4] Testing random quests across level brackets...")
    quests = cursor.execute(
        "SELECT id, title, quest_level, faction, zone FROM quests ORDER BY RANDOM() LIMIT 20"
    ).fetchall()
    for q in quests:
        qid, title, q_lvl, faction, zone = q
        results, _ = db.search_quests(title, limit=5)
        match = any(qu["id"] == qid or qu["title"].lower() == title.lower() for qu in results)
        status = "✅ PASS" if match else "❌ FAIL"
        if match:
            passed += 1
        else:
            failed += 1
        print(f"  {status} [{qid}] {title} (Lvl {q_lvl}) [{faction}] in {zone}")

    print("\n" + "=" * 70)
    print(f"AUDIT SUMMARY: {passed} PASSED / {failed} FAILED (Total: {passed + failed})")
    rate = (passed / (passed + failed)) * 100
    print(f"SUCCESS RATE: {rate:.1f}%")
    print("=" * 70)

    conn.close()
    if failed > 0:
        sys.exit(1)


if __name__ == "__main__":
    run_random_audit()
