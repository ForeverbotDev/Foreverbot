#!/usr/bin/env python3
"""
Extracts community preview talent trees from foreverdiff.gg/talent-calc/{class}?src=community
and stores them strictly segregated in ForeverDB/metadata/community_preview/talents_community_preview.json
"""

import urllib.request
import json
import os
import re
import sys
from datetime import datetime, timezone

CLASSES = [
    "warrior",
    "paladin",
    "hunter",
    "rogue",
    "priest",
    "shaman",
    "mage",
    "warlock",
    "druid"
]

def extract_for_class(cls_name):
    url = f"https://foreverdiff.gg/talent-calc/{cls_name}?src=community"
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 ForeverDiff-Extractor/1.0"})
    with urllib.request.urlopen(req, timeout=15) as resp:
        html = resp.read().decode('utf-8')
    
    # Locate \"klass\":{
    marker = r'\"klass\":{'
    idx = html.find(marker)
    if idx == -1:
        print(f"[-] Marker not found for {cls_name}")
        return None
    
    start = idx + len(r'\"klass\":')
    depth = 0
    in_quote = False
    escape = False
    end = -1
    for i in range(start, len(html)):
        ch = html[i]
        if escape:
            escape = False
            continue
        if ch == '\\':
            escape = True
            continue
        if ch == '"':
            in_quote = not in_quote
            continue
        if not in_quote:
            if ch == '{':
                depth += 1
            elif ch == '}':
                depth -= 1
                if depth == 0:
                    end = i + 1
                    break
    
    if end == -1:
        print(f"[-] Balanced braces not found for {cls_name}")
        return None
    
    raw = html[start:end]
    # Unescape json
    try:
        decoded = json.loads('"' + raw + '"')
        klass_obj = json.loads(decoded)
        return klass_obj
    except Exception as e:
        print(f"[-] Failed to decode JSON for {cls_name}: {e}")
        return None

def main():
    out_dir = os.path.join(os.path.dirname(__file__), "..", "metadata", "community_preview")
    os.makedirs(out_dir, exist_ok=True)
    out_file = os.path.join(out_dir, "talents_community_preview.json")
    
    result = {
        "source": "wowforevertalents.com",
        "curator": "Milenkas (BlizzCon footage)",
        "classification": "unverified_community_preview",
        "extracted_at": datetime.now(timezone.utc).isoformat(),
        "note": "Community preview talent tree reconstructions based on BlizzCon 2026 recorded footage. Kept strictly segregated from official datamined client database tables.",
        "classes": {}
    }
    
    print("[*] Extracting community talent trees for all 9 classes...")
    total_talents = 0
    for cls in CLASSES:
        data = extract_for_class(cls)
        if data:
            c_name = data.get("name", cls.capitalize())
            tabs = data.get("tabs", [])
            class_talents = sum(len(t.get("talents", [])) for t in tabs)
            total_talents += class_talents
            result["classes"][cls] = {
                "id": data.get("id"),
                "name": c_name,
                "file": data.get("file"),
                "tabs": tabs
            }
            print(f" [+] {c_name}: {len(tabs)} tabs, {class_talents} preview talents extracted")
        else:
            print(f" [!] Could not extract {cls}")
            
    with open(out_file, "w", encoding="utf-8") as f:
        json.dump(result, f, indent=2, ensure_ascii=False)
        
    print(f"[✓] Community preview talent trees successfully written to {out_file} (Total preview talents: {total_talents})")

if __name__ == "__main__":
    main()
