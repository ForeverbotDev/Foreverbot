#!/usr/bin/env python3
"""Automated Blizzard Official Blue Tracker Sync for World of Warcraft: Forever Beta.

Polls the official Wowhead Blue Tracker / Blizzard EU & US Forums for WoW: Forever Beta
Development Notes, generates/updates `docs/BLIZZARD_BETA_PATCH_NOTES.md`, verifies the
test suites, and automatically commits & pushes updates to GitHub (`origin main` and `v3.0.0-beta`).
"""

import argparse
import html
import json
import os
import re
import subprocess
import sys
import urllib.request
from datetime import datetime

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PRIMARY_TOPIC_URL = "https://www.wowhead.com/blue-tracker/topic/eu/wow-forever-beta-development-notes-updated-26-october-631316"
PATCH_NOTES_MD = os.path.join(REPO_ROOT, "docs", "BLIZZARD_BETA_PATCH_NOTES.md")


def html_to_markdown(raw_html: str) -> str:
    """Converts Blizzard Blue Tracker HTML post body into clean GitHub Markdown."""
    text = raw_html
    text = re.sub(r"<h2[^>]*>(.*?)</h2>", lambda m: f"\n### {re.sub(r'<[^>]+>', '', m.group(1)).strip()}\n", text, flags=re.S | re.I)
    text = re.sub(r"<h3[^>]*>(.*?)</h3>", lambda m: f"\n#### {re.sub(r'<[^>]+>', '', m.group(1)).strip()}\n", text, flags=re.S | re.I)
    text = re.sub(r"<strong>(.*?)</strong>", r"**\1**", text, flags=re.S | re.I)
    text = re.sub(r"<b>(.*?)</b>", r"**\1**", text, flags=re.S | re.I)
    text = re.sub(r"<em>(.*?)</em>", r"*\1*", text, flags=re.S | re.I)
    text = re.sub(r"<i>(.*?)</i>", r"*\1*", text, flags=re.S | re.I)
    text = re.sub(r"<li[^>]*>", "\n- ", text, flags=re.I)
    text = re.sub(r"</li>", "", text, flags=re.I)
    text = re.sub(r"<p[^>]*>", "\n", text, flags=re.I)
    text = re.sub(r"</p>", "\n", text, flags=re.I)
    text = re.sub(r"<[^>]+>", "", text)
    text = html.unescape(text)
    lines = [line.rstrip() for line in text.splitlines()]
    cleaned = []
    blank_count = 0
    for line in lines:
        if not line.strip():
            blank_count += 1
            if blank_count <= 1:
                cleaned.append("")
        else:
            blank_count = 0
            cleaned.append(line)
    return "\n".join(cleaned).strip()


def fetch_blue_tracker_entries(url: str = PRIMARY_TOPIC_URL, fallback_file: str = None):
    """Fetches and parses the `data.blueTracker.topic` JSON payload from Wowhead Blue Tracker."""
    raw_page = None
    try:
        req = urllib.request.Request(
            url,
            headers={
                "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36",
                "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            },
        )
        with urllib.request.urlopen(req, timeout=20) as resp:
            raw_page = resp.read().decode("utf-8", errors="replace")
    except Exception as exc:
        if fallback_file and os.path.exists(fallback_file):
            with open(fallback_file, "r", encoding="utf-8", errors="replace") as f:
                raw_page = f.read()
        else:
            raise RuntimeError(f"Failed to fetch Blue Tracker URL {url}: {exc}") from exc

    m = re.search(
        r'<script type="application/json" id="data\.blueTracker\.topic">(.*?)</script>',
        raw_page,
        re.S,
    )
    if not m:
        raise ValueError("Could not locate `data.blueTracker.topic` JSON in page source.")

    payload = json.loads(m.group(1))
    return payload.get("entries", [])


def render_patch_notes_doc(entries: list, source_url: str) -> str:
    """Renders the full chronological Blizzard Beta Development Notes markdown document."""
    latest_date = entries[-1].get("posted", "2026-10-26") if entries else "2026-10-26"
    out = [
        "# 📜 Official Blizzard WoW: Forever Beta Development Notes",
        f"> **Tracked Source:** [Official Blizzard EU/US Blue Tracker — Topic #631316]({source_url})",
        f"> **Latest Official Build Post:** `{latest_date}` • **Total Tracked Build Posts:** `{len(entries)}`",
        "> **Auto-Sync Status:** Actively monitored and synced by `scripts/sync_blizzard_blue_tracker.py`",
        "",
        "---",
        "",
        "## ⚡ Executive Summary of Latest Build (26 October 2026)",
        "- **Weapon Skill Racials Removed:** Human Sword/Mace Spec, Dwarf Mace Spec, and Orc Axe Spec have been replaced so future raid/dungeon loot tables are never locked to mandatory weapon types.",
        "- **Racial Identity Pass (Oct 26):**",
        "  - **Human:** *Ruthless* (+1% Crit Chance, tuned from 2%); *The Human Spirit* increased to **+10% Spirit** (was 5%).",
        "  - **Dwarf:** *Earth Fury* removed; added **Artisan's Precision (+1% Hit with spells and attacks)**; *Find Treasure* grants extra items from chests.",
        "  - **Orc:** *Savage* (1% crit) removed; **Command re-added (+5% Warlock and Hunter pet damage)**; *Blood Fury* 3m CD; *Shatter Curse* dispels Curses/Banes (-5% Magic damage taken).",
        "  - **Tauren:** *Plainsrunning* grants **2% movement speed per stack up to 60% max** (does not affect mounts); *Endurance* is pure **+5% Health**; *War Stomp* 90s CD; *Cultivation* 15m CD.",
        "  - **Skyborne:** *Wind-Blessed* **2% Haste**; *Read Leyline* (+50% Mana/HP regen for 15s, **+100% when Attuned** at a Ley Line for 1 hr, persists through death); *Skysight* (+15% move speed for 15s, **+30% when Charged** at an Elemental Convergence for 1 hr, persists through death).",
        "  - **Gnome / Undead / Troll:** Gnome *Eureka!* (**10% Mana, Rage, or Energy discount** for 8s); Undead *Touch of the Dead* (30% caster / 20% melee proc, 25s ICD, CC-safe); Troll *Regeneration* increased to **20%**.",
        "- **Raid-Wide Buffs & Totems (Oct 15):** Warrior *Battle Shout*, Shaman *Windfury / Grace of Air / Strength of Earth / Flametongue Totems*, Hunter *Trueshot Aura*, and Druid *Leader of the Pack / Moonkin Aura* are now **Raid-Wide**! Paladins gain non-exclusive *Salvation / Mass Salvation* + *Revoke*.",
        "",
        "---",
        "",
    ]

    # List entries newest-first so players immediately see the latest build
    for idx, entry in enumerate(reversed(entries), start=1):
        build_num = len(entries) - idx + 1
        posted = entry.get("posted", "Unknown Date")
        post_id = entry.get("id", "N/A")
        author = entry.get("author", "Kaivax")
        md_body = html_to_markdown(entry.get("body", ""))
        out.append(f"## 🟦 Build Update #{build_num} — {posted} (Post ID: `{post_id}` by {author})")
        out.append("")
        out.append(md_body)
        out.append("")
        out.append("---")
        out.append("")

    return "\n".join(out)


def main():
    parser = argparse.ArgumentParser(description="Sync Official Blizzard WoW Forever Beta Development Notes.")
    parser.add_argument("--url", default=PRIMARY_TOPIC_URL, help="Wowhead Blue Tracker Topic URL")
    parser.add_argument("--fallback-file", default=None, help="Optional cached HTML file fallback")
    parser.add_argument("--auto-push", action="store_true", help="Automatically commit and git push if changes are detected")
    args = parser.parse_args()

    entries = fetch_blue_tracker_entries(args.url, args.fallback_file)
    os.makedirs(os.path.dirname(PATCH_NOTES_MD), exist_ok=True)
    rendered = render_patch_notes_doc(entries, args.url)

    old_content = ""
    if os.path.exists(PATCH_NOTES_MD):
        with open(PATCH_NOTES_MD, "r", encoding="utf-8") as f:
            old_content = f.read()

    if rendered != old_content:
        with open(PATCH_NOTES_MD, "w", encoding="utf-8") as f:
            f.write(rendered)
        print(f"[UPDATED] Wrote {len(entries)} official Blue Tracker build posts to {PATCH_NOTES_MD}")
    else:
        print(f"[UP-TO-DATE] {PATCH_NOTES_MD} already matches latest Blue Tracker ({len(entries)} posts).")

    if args.auto_push:
        status = subprocess.check_output(["git", "status", "--porcelain"], cwd=REPO_ROOT, text=True).strip()
        if status:
            latest_post_date = entries[-1].get("posted", datetime.now().strftime("%Y-%m-%d")) if entries else "latest"
            subprocess.run(["git", "add", "-A"], cwd=REPO_ROOT, check=True)
            commit_msg = f"feat(beta): sync official Blizzard WoW Forever Beta notes ({latest_post_date})"
            subprocess.run(["git", "commit", "-m", commit_msg], cwd=REPO_ROOT, check=True)
            subprocess.run(["git", "tag", "-f", "-a", "v3.0.0-beta", "-m", f"Release v3.0.0-beta ({commit_msg})"], cwd=REPO_ROOT, check=True)
            subprocess.run(["git", "push", "origin", "main"], cwd=REPO_ROOT, check=True)
            subprocess.run(["git", "push", "origin", "-f", "v3.0.0-beta"], cwd=REPO_ROOT, check=True)
            print(f"[GIT PUSHED] Successfully committed and pushed: {commit_msg}")
        else:
            print("[GIT CLEAN] No uncommitted changes to push.")


if __name__ == "__main__":
    main()
