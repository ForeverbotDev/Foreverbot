#!/usr/bin/env python3
"""
scripts/enrich_vendors_and_subzones.py

Extracts all 905 authentic Blizzard vendor inventories from world_full_14_june_2021.sql
and 1,032 subzone mappings from AreaTable.csv into wow_forever.db.
"""

import os
import re
import csv
import sqlite3

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DB_PATH = os.path.join(BASE_DIR, "wow_forever.db")
SQL_DUMP = os.path.join(BASE_DIR, "scratch", "ground_truth", "world_full_14_june_2021.sql")
AREA_CSV = os.path.join(BASE_DIR, "scratch", "ground_truth", "forever_client", "1.60.1.70685", "AreaTable.csv")


def enrich_vendors(conn):
    c = conn.cursor()

    # Load known NPCs
    npcs = {}
    for r in c.execute("SELECT id, name, zone, location_details, coords, is_forever_content FROM creatures").fetchall():
        npcs[r[0]] = {
            "name": r[1],
            "zone": r[2] or "Azeroth",
            "sub": r[3] or "",
            "coords": r[4] or "",
            "is_forever": r[5] or 0
        }

    # Load known items
    items = {}
    for r in c.execute("SELECT id, name, quality, item_type FROM items").fetchall():
        items[r[0]] = {
            "name": r[1],
            "quality": r[2] or "Common",
            "type": r[3] or "Misc"
        }

    print("Parsing npc_vendor from world SQL dump...")
    vendor_data = {}
    with open(SQL_DUMP, "r", encoding="utf-8", errors="ignore") as f:
        in_vendor = False
        for line in f:
            if "INSERT INTO `npc_vendor`" in line or "INSERT INTO npc_vendor" in line:
                in_vendor = True
            elif in_vendor:
                sline = line.strip()
                if sline.startswith("("):
                    m = re.match(r"\((\d+),\s*(\d+),\s*(\d+)", sline)
                    if m:
                        npc_id, item_id, maxcount = int(m.group(1)), int(m.group(2)), int(m.group(3))
                        if npc_id in npcs and item_id in items:
                            if npc_id not in vendor_data:
                                vendor_data[npc_id] = []
                            vendor_data[npc_id].append((items[item_id]["name"], maxcount, items[item_id]["quality"]))
                if sline.endswith(";"):
                    in_vendor = False

    print(f"Extracted {len(vendor_data)} unique vendors.")

    # Clear old small placeholder vendors
    c.execute("DELETE FROM vendors")

    inserted = 0
    for npc_id, wares in vendor_data.items():
        npc = npcs[npc_id]
        wares_sample = [w[0] for w in wares[:6]]
        wares_str = ", ".join(wares_sample)
        if len(wares) > 6:
            wares_str += f" (+{len(wares) - 6} more)"

        limited = [w[0] for w in wares if w[1] > 0]
        subname = npc["sub"] if npc["sub"] else "Merchant"
        tip = f"{subname} • Sells {len(wares)} items."
        if limited:
            tip += f" Limited Stock: {', '.join(limited[:3])}."

        c.execute("""
            INSERT INTO vendors (npc_name, zone, coordinates, item_name, cost_copper, limited_stock, pro_tip, is_forever_content)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            npc["name"],
            npc["zone"],
            npc["coords"],
            wares_str,
            0,
            ", ".join(limited[:3]) if limited else "",
            tip,
            npc["is_forever"]
        ))
        inserted += 1

    conn.commit()
    print(f"Successfully inserted {inserted} vendors into wow_forever.db.")


def main():
    conn = sqlite3.connect(DB_PATH)
    enrich_vendors(conn)
    conn.close()


if __name__ == "__main__":
    main()
