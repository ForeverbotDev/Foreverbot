"""Bulk CSV importer for WoW: Forever database.
Allows importing datamined lists of items, quests, mobs, or vendors directly into the SQLite database.
"""

import csv
import sys
import os
from database import get_connection, DB_PATH


def import_items_csv(csv_path: str):
    conn = get_connection(DB_PATH)
    cursor = conn.cursor()

    count = 0
    with open(csv_path, mode="r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            cursor.execute("""
                INSERT OR REPLACE INTO items (id, name, quality, item_level, req_level, slot, item_type, stats, description, source, is_forever_content)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                int(row["id"]),
                row["name"],
                row.get("quality", "Common"),
                int(row.get("item_level", 1)),
                int(row.get("req_level", 1)),
                row.get("slot", ""),
                row.get("item_type", ""),
                row.get("stats", ""),
                row.get("description", ""),
                row.get("source", ""),
                int(row.get("is_forever_content", 1))
            ))
            count += 1

    # Re-sync FTS
    cursor.execute("DELETE FROM items_fts;")
    cursor.execute("""
        INSERT INTO items_fts(rowid, name, stats, description, source)
        SELECT id, name, stats, description, source FROM items;
    """)

    conn.commit()
    conn.close()
    print(f"Successfully imported {count} items from {csv_path}!")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 ingest_csv.py <path_to_items.csv>")
        sys.exit(1)

    csv_file = sys.argv[1]
    if not os.path.exists(csv_file):
        print(f"File not found: {csv_file}")
        sys.exit(1)

    import_items_csv(csv_file)
