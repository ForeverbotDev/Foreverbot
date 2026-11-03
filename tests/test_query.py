import os
import sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
from database import WoWForeverDB

db = WoWForeverDB()
stats = db.get_database_stats()
print("Database statistics:", stats)

print("\n--- Test Item Search ('Ironfoe') ---")
items, _ = db.search_items("Ironfoe")
for item in items:
    print(f"[{item['quality']}] {item['name']} (Req Lvl {item['req_level']}) - {item['source']}")

print("\n--- Test Forever Item Search ('Skyborne') ---")
items_f, _ = db.search_items("Skyborne")
for item in items_f:
    print(f"[{item['quality']}] {item['name']} - Forever Content: {bool(item['is_forever_content'])}")

print("\n--- Test Quest Search ('Mankrik') ---")
quests, _ = db.search_quests("Mankrik")
for q in quests:
    print(f"Quest: {q['title']} in {q['zone']} (Starter: {q['start_npc']})")

print("\n--- Test Forever Quest Search ('Nordrassil') ---")
quests_f, _ = db.search_quests("Nordrassil")
for q in quests_f:
    print(f"Quest: {q['title']} in {q['zone']} (Starter: {q['start_npc']})")

print("\n--- Test Vendor Search ('Bronze Tube') ---")
vendors, _ = db.search_vendors("Bronze Tube")
for v in vendors:
    gold = v['cost_copper'] // 10000
    silver = (v['cost_copper'] % 10000) // 100
    copper = v['cost_copper'] % 100
    print(f"Vendor: {v['npc_name']} ({v['zone']}) sells {v['item_name']} for {silver}s {copper}c")
