#!/usr/bin/env python3
"""Resumable fetcher for the WoW: Forever tooltip datamine (Wowhead `forever` namespace).

Every response is cached verbatim under scratch/ground_truth/forever_cache/<kind>/<id>.json
so the ground truth used for the rebuild can be re-audited later without re-fetching.
Records that do not exist in WoW: Forever are cached as {"_absent": true, "_status": <code>}.

Usage:
    python scripts/integrity/fetch_forever_tooltips.py --kind item --from-db
    python scripts/integrity/fetch_forever_tooltips.py --kind quest --ids-file ids.txt
"""

import argparse
import json
import os
import random
import sqlite3
import sys
import threading
import time
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CACHE_ROOT = os.path.join(REPO_ROOT, "scratch", "ground_truth", "forever_cache")
DB_PATH = os.path.join(REPO_ROOT, "wow_forever.db")
BASE_URL = "https://nether.wowhead.com/forever/tooltip/{kind}/{id}"
DB_SOURCES = {"item": ("items", "id"), "quest": ("quests", "id"), "npc": ("creatures", "id")}

_lock = threading.Lock()
_stats = {"fetched": 0, "absent": 0, "cached": 0, "errors": 0}


def cache_path(kind: str, record_id: int) -> str:
    return os.path.join(CACHE_ROOT, kind, f"{record_id}.json")


def fetch_one(kind: str, record_id: int, delay: float) -> None:
    path = cache_path(kind, record_id)
    if os.path.exists(path):
        with _lock:
            _stats["cached"] += 1
        return

    url = BASE_URL.format(kind=kind, id=record_id)
    req = urllib.request.Request(url, headers={"User-Agent": "Foreverbot-IntegrityAudit/1.0"})
    payload = None
    for attempt in range(5):
        try:
            with urllib.request.urlopen(req, timeout=15) as resp:
                data = json.loads(resp.read().decode("utf-8"))
            if not data.get("name") or "tooltip" not in data:
                payload = {"_absent": True, "_status": 200, "_raw": data}
            else:
                payload = data
            break
        except urllib.error.HTTPError as exc:
            if exc.code == 404:
                payload = {"_absent": True, "_status": 404}
                break
            if exc.code in (429, 500, 502, 503, 504):
                time.sleep((2 ** attempt) + random.random())
                continue
            payload = None
            break
        except Exception:
            time.sleep((2 ** attempt) + random.random())

    if payload is None:
        with _lock:
            _stats["errors"] += 1
        return

    payload["_fetched_at"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    payload["_url"] = url
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False)
    os.replace(tmp, path)
    with _lock:
        _stats["absent" if payload.get("_absent") else "fetched"] += 1
    time.sleep(delay)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--kind", required=True, choices=["item", "quest", "npc", "object"])
    ap.add_argument("--from-db", action="store_true", help="Fetch every ID present in wow_forever.db")
    ap.add_argument("--ids-file", help="Newline-separated list of IDs")
    ap.add_argument("--workers", type=int, default=6)
    ap.add_argument("--delay", type=float, default=0.15, help="Per-worker pause between requests")
    args = ap.parse_args()

    ids = set()
    if args.from_db:
        allowed_queries = {
            "item": "SELECT id FROM items",
            "quest": "SELECT id FROM quests",
            "npc": "SELECT id FROM creatures",
            "spell": "SELECT id FROM spells",
        }
        query_sql = allowed_queries.get(args.kind, "SELECT id FROM items")
        ids |= {r[0] for r in sqlite3.connect(DB_PATH).execute(query_sql)}
    if args.ids_file:
        with open(args.ids_file) as f:
            ids |= {int(x) for x in f.read().split() if x.strip().isdigit()}
    ids = sorted(ids)
    os.makedirs(os.path.join(CACHE_ROOT, args.kind), exist_ok=True)

    total = len(ids)
    print(f"[{args.kind}] {total} IDs queued", flush=True)
    start = time.time()
    with ThreadPoolExecutor(args.workers) as ex:
        for i, _ in enumerate(ex.map(lambda rid: fetch_one(args.kind, rid, args.delay), ids), 1):
            if i % 500 == 0 or i == total:
                with _lock:
                    s = dict(_stats)
                rate = i / max(time.time() - start, 1e-6)
                print(f"[{args.kind}] {i}/{total} fetched={s['fetched']} absent={s['absent']} "
                      f"cached={s['cached']} errors={s['errors']} ({rate:.1f}/s)", flush=True)
    return 1 if _stats["errors"] else 0


if __name__ == "__main__":
    sys.exit(main())
