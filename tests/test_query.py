from database import WoWForeverDB

db = WoWForeverDB()
stats = db.get_database_stats()
print("Database statistics:", stats)

print("\n--- Test Item Search ('Ironfoe') ---")
for item in db.search_items("Ironfoe"):
    print(f"[{item['quality']}] {item['name']} (Req Lvl {item['req_level']}) - {item['source']}")

print("\n--- Test Forever Item Search ('Skyborne') ---")
for item in db.search_items("Skyborne"):
    print(f"[{item['quality']}] {item['name']} - Forever Content: {bool(item['is_forever_content'])}")

print("\n--- Test Quest Search ('Mankrik') ---")
for q in db.search_quests("Mankrik"):
    print(f"Quest: {q['title']} in {q['zone']} (Starter: {q['start_npc']})")

print("\n--- Test Forever Quest Search ('Nordrassil') ---")
for q in db.search_quests("Nordrassil"):
    print(f"Quest: {q['title']} in {q['zone']} (Starter: {q['start_npc']})")

print("\n--- Test Vendor Search ('Bronze Tube') ---")
for v in db.search_vendors("Bronze Tube"):
    gold = v['cost_copper'] // 10000
    silver = (v['cost_copper'] % 10000) // 100
    copper = v['cost_copper'] % 100
    print(f"Vendor: {v['npc_name']} ({v['zone']}) sells {v['item_name']} for {silver}s {copper}c")
