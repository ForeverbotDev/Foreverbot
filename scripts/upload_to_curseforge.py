#!/usr/bin/env python3
"""
scripts/upload_to_curseforge.py

Automated CurseForge release uploader for ForeverGuide ("The Blue Spark").
Uploads the packaged pre-alpha distribution zip to the CurseForge Author API.

Usage:
    export CF_API_TOKEN="your-curseforge-api-token"
    export CF_PROJECT_ID="your-project-id"
    python3 scripts/upload_to_curseforge.py

Or dry-run / inspect release metadata:
    python3 scripts/upload_to_curseforge.py --dry-run
"""

import argparse
import json
import os
import sys
import urllib.request
import urllib.error

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIST_DIR = os.path.join(BASE_DIR, "dist")
ADDON_DIR = os.path.join(BASE_DIR, "addon", "ForeverGuide")
TOC_FILE = os.path.join(ADDON_DIR, "ForeverGuide.toc")

CHANGELOG_TEXT = """# ⚠️ PRE-ALPHA RELEASE: ForeverGuide v0.1.0-pre-alpha

> **NOTICE**: This addon is currently in **PRE-ALPHA** development for **Warcraft Forever** and **Classic Era**.
> Features, database schemas, and interface structures are undergoing active evolution. Feedback and bug reports are welcome!

### 🌟 Key Features in this Pre-Alpha Build:
- **Autonomous Wisp Companion (Sparky)**:
  - Ambient flight mechanics with smooth wandering, boundary tethering, and resting states.
  - Dynamic game interactivity: dashes and bounces along screen borders upon player death; celebrates upon resurrection and level up.
- **KDE Dolphin-Style Codex Navigation**:
  - Hierarchical folder browsing (`/quests`, `/items`, `/creatures`, `/dungeons`, `/flightpaths`, `/vendors`).
  - Interactive breadcrumbs and one-click `[ ⬆ Up ]` parent folder navigation.
  - Strict case-insensitive **A-to-Z alphabetical sorting** across all views.
- **Blizzard-Accurate Ground-Truth Database**:
  - **26,171 Items** enriched with authentic Blizzard `Interface\\Icons\\...` textures and quality-colored borders.
  - **11,236 Items** with Equip, Use, and Chance-on-Hit proc effects displayed in WoW green (`|cff20ff20`).
  - **1,122 Items** mapped to official Item Sets (e.g. *Embrace of the Viper*, *The Gladiator*).
  - **6,865 Creatures** with pinpoint zone map coordinates (`XX.X, YY.Y`) and instant `/target` macro generation.
  - **4,245 Quests** with complete lore story, task objectives, item rewards, and turn-in completion dialogues.
- **Full Sandboxing & Security Compliance**:
  - 100% compliant with Blizzard's AddOn Policy. Zero external dependencies, zero dangerous API calls.
"""


def get_latest_zip() -> str:
    if not os.path.exists(DIST_DIR):
        return ""
    zips = [f for f in os.listdir(DIST_DIR) if f.startswith("ForeverGuide") and f.endswith(".zip")]
    if not zips:
        return ""
    # Sort by mtime descending
    zips.sort(key=lambda x: os.path.getmtime(os.path.join(DIST_DIR, x)), reverse=True)
    return os.path.join(DIST_DIR, zips[0])


def upload_to_curseforge(project_id: str, token: str, zip_path: str, dry_run: bool = False):
    if not os.path.exists(zip_path):
        print(f"Error: Release zip not found at {zip_path}")
        print("Please run `python3 scripts/package_addon.py` first.")
        sys.exit(1)

    zip_filename = os.path.basename(zip_path)
    file_size_mb = os.path.getsize(zip_path) / (1024 * 1024)

    metadata = {
        "changelog": CHANGELOG_TEXT,
        "changelogType": "markdown",
        "displayName": f"ForeverGuide [Pre-Alpha] - {zip_filename}",
        "parentFileID": None,
        "releaseType": "alpha",  # CurseForge convention for Pre-Alpha / Alpha
    }

    print("=" * 70)
    print("   CURSEFORGE PRE-ALPHA UPLOAD MANIFEST")
    print("=" * 70)
    print(f"Project ID    : {project_id or '(Not specified)'}")
    print(f"Release File  : {zip_path} ({file_size_mb:.2f} MB)")
    print(f"Release Type  : {metadata['releaseType'].upper()} (Explicit Pre-Alpha)")
    print(f"Display Name  : {metadata['displayName']}")
    print("-" * 70)

    if dry_run or not token or not project_id:
        print("\n[DRY RUN / MANUAL UPLOAD INSTRUCTIONS]")
        print("To complete upload via the CurseForge Author Portal:")
        print("1. Log in to https://authors.curseforge.com/")
        print("2. Navigate to your project -> 'Files' -> 'Upload File'.")
        print(f"3. Upload the pre-packaged archive:\n   {zip_path}")
        print("4. Set 'Release Type' to 'Alpha'.")
        print(f"5. Set 'Display Name' to 'ForeverGuide v0.1.0 [Pre-Alpha]'.")
        print("6. Paste the Pre-Alpha Changelog (shown above) into the changelog box.")
        print("\nTo upload automatically via this CLI script:")
        print("   export CF_API_TOKEN=\"<your-api-token>\"")
        print("   export CF_PROJECT_ID=\"<your-project-id>\"")
        print("   python3 scripts/upload_to_curseforge.py\n")
        return

    # API Upload execution
    api_url = f"https://wow.curseforge.com/api/projects/{project_id}/upload-file"
    print(f"Connecting to CurseForge API: {api_url} ...")

    boundary = "----CurseForgeFormBoundary7MA4YWxkTrZu0gW"
    body = bytearray()

    # Part 1: metadata JSON
    body.extend(f"--{boundary}\r\n".encode("utf-8"))
    body.extend(b'Content-Disposition: form-data; name="metadata"\r\n\r\n')
    body.extend(json.dumps(metadata).encode("utf-8"))
    body.extend(b"\r\n")

    # Part 2: zip file binary
    body.extend(f"--{boundary}\r\n".encode("utf-8"))
    body.extend(f'Content-Disposition: form-data; name="file"; filename="{zip_filename}"\r\n'.encode("utf-8"))
    body.extend(b"Content-Type: application/zip\r\n\r\n")
    with open(zip_path, "rb") as f:
        body.extend(f.read())
    body.extend(b"\r\n")

    # Final boundary
    body.extend(f"--{boundary}--\r\n".encode("utf-8"))

    req = urllib.request.Request(api_url, data=bytes(body))
    req.add_header("X-Api-Token", token)
    req.add_header("Content-Type", f"multipart/form-data; boundary={boundary}")

    try:
        with urllib.request.urlopen(req) as response:
            resp_data = response.read().decode("utf-8")
            print(f"Upload successfully accepted! Response: {resp_data}")
    except urllib.error.HTTPError as e:
        err_msg = e.read().decode("utf-8") if e.fp else str(e)
        print(f"HTTP Error {e.code}: {err_msg}")
        sys.exit(1)
    except Exception as e:
        print(f"Upload failed: {e}")
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser(description="Upload ForeverGuide Pre-Alpha to CurseForge")
    parser.add_argument("--project-id", default=os.environ.get("CF_PROJECT_ID", ""), help="CurseForge Project ID")
    parser.add_argument("--token", default=os.environ.get("CF_API_TOKEN", os.environ.get("CURSEFORGE_API_TOKEN", "")), help="CurseForge API Token")
    parser.add_argument("--zip", default="", help="Path to zip archive (defaults to latest in dist/)")
    parser.add_argument("--dry-run", action="store_true", help="Perform dry run without calling API")
    args = parser.parse_args()

    zip_path = args.zip or get_latest_zip()
    upload_to_curseforge(args.project_id, args.token, zip_path, dry_run=args.dry_run)


if __name__ == "__main__":
    main()
