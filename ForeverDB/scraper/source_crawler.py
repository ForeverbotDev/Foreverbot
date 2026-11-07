#!/usr/bin/env python3
"""
ForeverDB/scraper/source_crawler.py

Comprehensive source crawler targeting https://foreverdiff.gg/
- Discovers build metadata, sitemaps, and raw Vercel blob storage shards.
- Downloads all 15 required categories with concurrency, retry backoff, and local caching.
- Fetches community preview talents and comparison metadata.
- Validates discovered record counts against meta.json target counts.
"""

import os
import sys
import json
import time
import urllib.request
import urllib.error
import xml.etree.ElementTree as ET
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import Dict, List, Set, Any, Tuple

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RAW_SHARDS_DIR = os.path.join(BASE_DIR, "raw_shards")
METADATA_DIR = os.path.join(BASE_DIR, "metadata")
COMMUNITY_DIR = os.path.join(METADATA_DIR, "community_preview")

STORAGE_BASE = "https://kabltd6cwecga8ve.public.blob.vercel-storage.com"
BUILD_PATH = "builds/wow_classic_beta/1.60.1.70532"
BUILD_BASE_URL = f"{STORAGE_BASE}/{BUILD_PATH}"
SITE_BASE = "https://foreverdiff.gg"

USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 ForeverDiffBot/1.0"

CATEGORIES = [
    "items", "spells", "talents", "itemsets", "enchantments",
    "quests", "npcs", "objects", "zones", "dungeons",
    "factions", "achievements", "classes", "races", "skills"
]

CLASSES = [
    "warrior", "paladin", "hunter", "rogue", "priest",
    "shaman", "mage", "warlock", "druid"
]


def fetch_url(url: str, headers: Dict[str, str] = None, retries: int = 4, delay: float = 0.5) -> bytes:
    """Fetch URL with retries, exponential backoff, and custom headers."""
    req_headers = {"User-Agent": USER_AGENT}
    if headers:
        req_headers.update(headers)
    req = urllib.request.Request(url, headers=req_headers)

    for attempt in range(retries):
        try:
            with urllib.request.urlopen(req, timeout=25) as response:
                return response.read()
        except urllib.error.HTTPError as e:
            if e.code == 404:
                return None  # 404 is valid for missing shards
            if attempt < retries - 1:
                time.sleep(delay * (2 ** attempt))
            else:
                raise
        except Exception as e:
            if attempt < retries - 1:
                time.sleep(delay * (2 ** attempt))
            else:
                raise
    return None


def fetch_build_meta() -> Dict[str, Any]:
    """Fetch and persist build metadata from Vercel blob storage."""
    print(f"[*] Fetching master build metadata from {BUILD_BASE_URL}/meta.json...")
    data = fetch_url(f"{BUILD_BASE_URL}/meta.json")
    if not data:
        raise RuntimeError("Failed to fetch meta.json from blob storage!")
    meta = json.loads(data.decode("utf-8"))
    
    os.makedirs(METADATA_DIR, exist_ok=True)
    meta_path = os.path.join(METADATA_DIR, "build_info.json")
    with open(meta_path, "w", encoding="utf-8") as f:
        json.dump(meta, f, indent=2)
    print(f"[+] Saved build metadata to {meta_path} (Target build: {meta.get('version')}, BuildID: {meta.get('buildId')})")
    return meta


def crawl_sitemaps() -> Dict[str, Set[int]]:
    """Crawl sitemap index and sub-sitemaps to extract entity IDs and shard numbers."""
    print(f"[*] Fetching sitemap index from {SITE_BASE}/sitemap.xml...")
    index_xml = fetch_url(f"{SITE_BASE}/sitemap.xml")
    if not index_xml:
        raise RuntimeError("Failed to fetch sitemap.xml!")
    
    tree = ET.fromstring(index_xml)
    sub_sitemaps = []
    for loc in tree.findall(".//{http://www.sitemaps.org/schemas/sitemap/0.9}loc"):
        sub_sitemaps.append(loc.text)
    
    print(f"[*] Discovered {len(sub_sitemaps)} sub-sitemaps across categories.")
    
    category_shards: Dict[str, Set[int]] = {cat: set() for cat in CATEGORIES}
    category_ids: Dict[str, Set[int]] = {cat: set() for cat in CATEGORIES}
    
    for s_url in sub_sitemaps:
        # e.g. https://foreverdiff.gg/sitemaps/items/0
        parts = s_url.rstrip("/").split("/")
        cat_candidate = parts[-2]
        if cat_candidate == "pages":
            continue
        if cat_candidate not in category_shards:
            print(f"  [?] Unknown category in sitemap: {cat_candidate}")
            continue
        
        xml_data = fetch_url(s_url)
        if not xml_data:
            continue
        s_tree = ET.fromstring(xml_data)
        for loc in s_tree.findall(".//{http://www.sitemaps.org/schemas/sitemap/0.9}loc"):
            url_str = loc.text
            raw_id = url_str.split("=")[-1].split("/")[-1]
            try:
                ent_id = int(raw_id)
                category_ids[cat_candidate].add(ent_id)
                category_shards[cat_candidate].add(ent_id // 250)
            except ValueError:
                pass
                
    for cat in CATEGORIES:
        print(f"  -> {cat:15}: {len(category_ids[cat]):6} public IDs mapped to {len(category_shards[cat]):4} initial shards")
        
    return category_shards


def download_category_shards(category: str, shards: Set[int], max_workers: int = 16) -> Dict[str, Any]:
    """Download all JSON shards for a category concurrently with disk caching."""
    cat_dir = os.path.join(RAW_SHARDS_DIR, category)
    os.makedirs(cat_dir, exist_ok=True)
    
    records: Dict[str, Any] = {}
    shards_to_download = []
    
    # 1. Read existing cached shards first
    for shard in sorted(shards):
        shard_file = os.path.join(cat_dir, f"{shard}.json")
        if os.path.exists(shard_file) and os.path.getsize(shard_file) > 10:
            try:
                with open(shard_file, "r", encoding="utf-8") as f:
                    shard_data = json.load(f)
                    if isinstance(shard_data, dict):
                        records.update(shard_data)
                        continue
            except Exception:
                pass
        shards_to_download.append(shard)
        
    if not shards_to_download:
        print(f"  [CACHE] {category:15}: All {len(shards)} shards loaded from cache ({len(records)} records)")
        return records
        
    print(f"  [FETCH] {category:15}: Downloading {len(shards_to_download)} / {len(shards)} shards ({len(records)} already cached)...")
    
    def fetch_shard_worker(shard_num: int) -> Tuple[int, Dict[str, Any]]:
        url = f"{BUILD_BASE_URL}/{category}/{shard_num}.json"
        data_bytes = fetch_url(url)
        if not data_bytes:
            return shard_num, None
        try:
            parsed = json.loads(data_bytes.decode("utf-8"))
            if isinstance(parsed, dict) and len(parsed) > 0:
                dest = os.path.join(cat_dir, f"{shard_num}.json")
                with open(dest, "wb") as f:
                    f.write(data_bytes)
                return shard_num, parsed
        except Exception:
            pass
        return shard_num, None

    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        future_map = {executor.submit(fetch_shard_worker, s): s for s in shards_to_download}
        for future in as_completed(future_map):
            s_num, s_data = future.result()
            if s_data:
                records.update(s_data)
                
    print(f"  [DONE]  {category:15}: Total extracted records = {len(records):6}")
    return records


def probe_internal_shards(category: str, known_shards: Set[int], target_count: int, max_shard_limit: int = 1200, max_workers: int = 20) -> Set[int]:
    """Probe for shards that only contain internal entities not indexed in public sitemaps."""
    cat_dir = os.path.join(RAW_SHARDS_DIR, category)
    os.makedirs(cat_dir, exist_ok=True)
    
    # Check what we already have
    current_records = 0
    existing_shards = set(known_shards)
    for fname in os.listdir(cat_dir):
        if fname.endswith(".json"):
            try:
                s_num = int(fname[:-5])
                existing_shards.add(s_num)
                with open(os.path.join(cat_dir, fname), "r", encoding="utf-8") as f:
                    data = json.load(f)
                    current_records += len(data)
            except Exception:
                pass
                
    if current_records >= target_count:
        return existing_shards
        
    print(f"  [SCAN]  {category:15}: Current records = {current_records} / Target = {target_count}. Probing gaps in shards 0..{max_shard_limit}...")
    
    unprobed_shards = [s for s in range(max_shard_limit + 1) if s not in existing_shards]
    if not unprobed_shards:
        return existing_shards
        
    found_new_shards = set()
    
    def probe_worker(s_num: int) -> Tuple[int, Dict[str, Any]]:
        url = f"{BUILD_BASE_URL}/{category}/{s_num}.json"
        req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
        try:
            with urllib.request.urlopen(req, timeout=12) as resp:
                if resp.status == 200:
                    data_bytes = resp.read()
                    parsed = json.loads(data_bytes.decode("utf-8"))
                    if isinstance(parsed, dict) and len(parsed) > 0:
                        dest = os.path.join(cat_dir, f"{s_num}.json")
                        with open(dest, "wb") as f:
                            f.write(data_bytes)
                        return s_num, parsed
        except Exception:
            pass
        return s_num, None

    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        future_map = {executor.submit(probe_worker, s): s for s in unprobed_shards}
        for future in as_completed(future_map):
            s_num, s_data = future.result()
            if s_data:
                found_new_shards.add(s_num)
                current_records += len(s_data)
                existing_shards.add(s_num)
                if current_records >= target_count:
                    # Cancel remaining futures if target reached
                    for f in future_map:
                        f.cancel()
                    break

    if found_new_shards:
        print(f"  [+] Discovered {len(found_new_shards)} internal shards for {category}! New record total: {current_records}")
    return existing_shards


def fetch_community_talent_preview():
    """Fetch unverified community talent preview from wowforevertalents.com (Milenkas BlizzCon footage)."""
    print(f"[*] Fetching community talent preview for all 9 classes...")
    os.makedirs(COMMUNITY_DIR, exist_ok=True)
    
    community_talents: Dict[str, Any] = {}
    for cls_name in CLASSES:
        url = f"{SITE_BASE}/talent-calc/{cls_name}?src=community"
        try:
            data_bytes = fetch_url(url, headers={"RSC": "1"})
            if data_bytes:
                content = data_bytes.decode("utf-8", errors="replace")
                # Locate TalentPlanner component invocation
                idx = content.find("TalentPlanner")
                if idx != -1:
                    # Find json props after TalentPlanner
                    klass_match = content.find('{"klass":{', idx)
                    if klass_match != -1:
                        # Extract balanced JSON object for klass
                        brace_count = 0
                        end_pos = klass_match
                        for i in range(klass_match, min(len(content), klass_match + 50000)):
                            if content[i] == '{':
                                brace_count += 1
                            elif content[i] == '}':
                                brace_count -= 1
                                if brace_count == 0:
                                    end_pos = i + 1
                                    break
                        if end_pos > klass_match:
                            try:
                                klass_data = json.loads(content[klass_match:end_pos])
                                community_talents[cls_name] = klass_data.get("klass", klass_data)
                            except Exception:
                                pass
        except Exception as e:
            print(f"  [!] Failed fetching community talent for {cls_name}: {e}")
            
    out_file = os.path.join(COMMUNITY_DIR, "talents_community_preview.json")
    with open(out_file, "w", encoding="utf-8") as f:
        json.dump({
            "source": "wowforevertalents.com",
            "curator": "Milenkas (BlizzCon footage)",
            "classification": "unverified_community_preview",
            "extracted_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
            "note": "Community preview talent tree reconstructions based on BlizzCon 2026 recorded footage. Kept strictly segregated from official datamined client database tables.",
            "classes": community_talents
        }, f, indent=2)
    print(f"[+] Saved {len(community_talents)} / 9 community talent trees to {out_file}")


def fetch_comparison_summary():
    """Fetch Classic Era vs Forever Beta comparison summary."""
    print(f"[*] Fetching comparison metadata (Forever Beta vs Classic Era)...")
    url = f"{SITE_BASE}/compare/wow_classic_beta-1.60.1.70532__vs__wow_classic_era-1.15.9.69722"
    try:
        data = fetch_url(url, headers={"RSC": "1"})
        if data:
            content = data.decode("utf-8", errors="replace")
            summary_path = os.path.join(METADATA_DIR, "comparison_summary.json")
            with open(summary_path, "w", encoding="utf-8") as f:
                json.dump({
                    "url": url,
                    "target_build": "wow_classic_beta-1.60.1.70532",
                    "baseline_build": "wow_classic_era-1.15.9.69722",
                    "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
                    "rsc_snapshot": content[:100000]
                }, f, indent=2)
            print(f"[+] Saved comparison summary to {summary_path}")
    except Exception as e:
        print(f"  [!] Failed to fetch comparison summary: {e}")


def run_crawler():
    """Main crawler execution pipeline."""
    start_time = time.time()
    print("================================================================================")
    print("FOREVERDIFF COMPLETE DATA ACQUISITION PIPELINE: SOURCE CRAWLER")
    print("================================================================================")
    
    meta = fetch_build_meta()
    target_counts = meta.get("counts", {})
    
    category_shards = crawl_sitemaps()
    
    all_category_records: Dict[str, Dict[str, Any]] = {}
    for cat in CATEGORIES:
        shards = category_shards.get(cat, set())
        # First download known sitemap shards
        records = download_category_shards(cat, shards, max_workers=20)
        all_category_records[cat] = records
        
        # Probe for any remaining internal/unindexed shards
        tgt = target_counts.get(cat, len(records))
        if len(records) < tgt:
            # Set appropriate probe limit
            limit = 1200
            if cat == "spells": limit = 5400
            elif cat == "objects": limit = 12100
            elif cat in ["talents", "itemsets", "enchantments", "dungeons", "factions", "classes", "races", "skills"]:
                limit = 100
            all_shards = probe_internal_shards(cat, shards, tgt, max_shard_limit=limit, max_workers=24)
            # Re-read any newly discovered shards
            records = download_category_shards(cat, all_shards, max_workers=20)
            all_category_records[cat] = records

    fetch_community_talent_preview()
    fetch_comparison_summary()
    
    elapsed = time.time() - start_time
    total_records = sum(len(r) for r in all_category_records.values())
    print("\n--------------------------------------------------------------------------------")
    print(f"SOURCE CRAWLER COMPLETED IN {elapsed:.2f}s")
    print(f"TOTAL RECORDS ACQUIRED: {total_records:,}")
    print("--------------------------------------------------------------------------------")
    for cat in CATEGORIES:
        count = len(all_category_records[cat])
        target = target_counts.get(cat, "N/A")
        print(f"  • {cat:15}: {count:6} records (Target: {target})")
    print("================================================================================\n")


if __name__ == "__main__":
    run_crawler()
