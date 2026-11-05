#!/usr/bin/env python3
"""
scripts/enrich_quests_full_text.py

Extracts authentic full quest lore, descriptions, dialogs, and completion reward texts
from scratch/ground_truth/world_full_14_june_2021.sql and enriches wow_forever.db.
"""

import sqlite3
import os
import re

DB_PATH = "wow_forever.db"
SQL_FILE = "scratch/ground_truth/world_full_14_june_2021.sql"


def clean_quest_text(text: str) -> str:
    if not text:
        return ""
    # Clean up WoW markup variables
    t = text.replace("$B$B", "\n\n").replace("$b$b", "\n\n").replace("$B", "\n").replace("$b", "\n")
    t = t.replace("$N", "Hero").replace("$n", "Hero")
    t = t.replace("$C", "adventurer").replace("$c", "adventurer")
    t = t.replace("$R", "traveler").replace("$r", "traveler")
    t = t.replace("$G", "")
    t = t.replace("\\r\\n", "\n").replace("\\n", "\n").replace("\\'", "'").replace('\\"', '"')
    return t.strip()


def parse_sql_row(s: str):
    s = s.strip()
    if s.startswith("("):
        s = s[1:]
    if s.endswith(";"):
        s = s[:-1].strip()
    if s.endswith(","):
        s = s[:-1].strip()
    if s.endswith(")"):
        s = s[:-1]

    tokens = []
    curr = []
    in_str = False
    escaped = False

    for ch in s:
        if in_str:
            if escaped:
                curr.append(ch)
                escaped = False
            elif ch == "\\":
                escaped = True
            elif ch == "'":
                in_str = False
            else:
                curr.append(ch)
        else:
            if ch == "'":
                in_str = True
            elif ch == ",":
                tokens.append("".join(curr).strip())
                curr = []
            else:
                curr.append(ch)
    if curr:
        tokens.append("".join(curr).strip())
    return tokens


def run_quest_enrichment():
    if not os.path.exists(SQL_FILE):
        print(f"Error: SQL dump not found at {SQL_FILE}")
        return

    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()

    # Ensure details and completion_text columns exist
    c.execute("PRAGMA table_info(quests)")
    cols = [r[1] for r in c.fetchall()]
    if "details" not in cols:
        c.execute("ALTER TABLE quests ADD COLUMN details TEXT DEFAULT ''")
    if "completion_text" not in cols:
        c.execute("ALTER TABLE quests ADD COLUMN completion_text TEXT DEFAULT ''")
    conn.commit()

    print(f"Reading and parsing quests from {SQL_FILE}...")
    quest_data = {}

    with open(SQL_FILE, "r", encoding="utf-8", errors="ignore") as f:
        in_insert = False
        buffer = []
        for line in f:
            if "INSERT INTO `quest_template`" in line:
                in_insert = True
                continue
            if in_insert:
                buffer.append(line)
                # Check for end of row
                stripped = line.strip()
                if stripped.endswith("),") or stripped.endswith(");"):
                    full_row = "".join(buffer)
                    buffer = []
                    try:
                        vals = parse_sql_row(full_row)
                        if len(vals) >= 34:
                            entry_id = int(vals[0])
                            title = vals[30]
                            details = clean_quest_text(vals[31])
                            objectives = clean_quest_text(vals[32])
                            offer_reward = clean_quest_text(vals[33])
                            quest_data[entry_id] = {
                                "title": title,
                                "details": details,
                                "objectives": objectives,
                                "offer_reward": offer_reward
                            }
                    except Exception:
                        pass
                if stripped.endswith(";"):
                    in_insert = False

    print(f"Parsed {len(quest_data):,} quests from quest_template dump!")

    # Fetch current quests in wow_forever.db
    c.execute("SELECT id, title, objectives, details, completion_text FROM quests")
    current_quests = c.fetchall()
    print(f"Loaded {len(current_quests):,} quests from database.")

    updates = []
    enriched_count = 0

    for q in current_quests:
        qid, title, curr_objs, curr_det, curr_comp = q
        if qid in quest_data:
            qd = quest_data[qid]
            new_det = qd["details"] or ""
            new_comp = qd["offer_reward"] or ""
            new_objs = qd["objectives"] or curr_objs or ""

            # For turn-in / exchange quests where Details is blank (e.g. Black Ram Exchange)
            if not new_det and new_comp:
                new_det = new_comp

            if not new_objs:
                new_objs = curr_objs or f"Complete task for {title}."

            updates.append((new_det, new_comp, new_objs, qid))
            enriched_count += 1
        else:
            # Fallback for custom quests or unmapped IDs
            if not curr_det or len(curr_det) < 10:
                gen_det = f"Speak with the questgiver in this region to undertake '{title}'. Complete all objectives and report back for your reward."
                updates.append((gen_det, curr_comp or "", curr_objs or "", qid))

    print(f"Applying updates to {len(updates):,} quests in database...")
    c.executemany("""
        UPDATE quests
        SET details = ?, completion_text = ?, objectives = ?
        WHERE id = ?
    """, updates)
    conn.commit()

    # Verify Black Ram Exchange (ID 7674)
    c.execute("SELECT id, title, details, objectives, completion_text FROM quests WHERE id = 7674")
    bre = c.fetchone()
    print("\nVerified Black Ram Exchange:")
    print(f"  Title: {bre[1]}")
    print(f"  Details: {bre[2]}")
    print(f"  Objectives: {bre[3]}")
    print(f"  Completion: {bre[4]}")

    c.execute("SELECT COUNT(*) FROM quests WHERE details != ''")
    print(f"\nTotal quests with full text: {c.fetchone()[0]:,}")

    conn.close()


if __name__ == "__main__":
    run_quest_enrichment()
