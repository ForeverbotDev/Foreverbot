#!/usr/bin/env python3
"""
scripts/package_addon.py

Packages the ForeverGuide addon into a CurseForge-compliant distribution zip.
The archive is placed in dist/ForeverGuide-v<version>.zip
"""

import os
import re
import shutil
import zipfile

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ADDON_DIR = os.path.join(BASE_DIR, "addon", "ForeverGuide")
TOC_FILE = os.path.join(ADDON_DIR, "ForeverGuide.toc")
DIST_DIR = os.path.join(BASE_DIR, "dist")


def get_addon_version() -> str:
    if os.path.exists(TOC_FILE):
        with open(TOC_FILE, "r", encoding="utf-8") as f:
            for line in f:
                m = re.match(r"^##\s*Version:\s*([^\s]+)", line.strip())
                if m:
                    return m.group(1)
    return "1.0.0"


def package():
    version = get_addon_version()
    os.makedirs(DIST_DIR, exist_ok=True)
    zip_path = os.path.join(DIST_DIR, f"ForeverGuide-v{version}.zip")

    print(f"Packaging ForeverGuide v{version} for CurseForge...")

    files_to_pack = [
        "ForeverGuide.toc",
        "ForeverGuide.lua",
        "ForeverGuide_Data.lua",
        "Bindings.xml",
    ]
    media_folder = os.path.join(ADDON_DIR, "Media")
    if os.path.exists(media_folder):
        for mfile in sorted(os.listdir(media_folder)):
            files_to_pack.append(os.path.join("Media", mfile))

    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
        for fname in files_to_pack:
            fpath = os.path.join(ADDON_DIR, fname)
            if os.path.exists(fpath):
                arcname = os.path.join("ForeverGuide", fname)
                zf.write(fpath, arcname=arcname)
                print(f"  + Added: {arcname} ({os.path.getsize(fpath) / 1024:.1f} KB)")
            else:
                print(f"  ! Warning: {fname} missing!")

    size_mb = os.path.getsize(zip_path) / (1024 * 1024)
    print(f"\nSuccessfully built CurseForge release archive:")
    print(f"  -> {zip_path} ({size_mb:.2f} MB)")

    # Build AlphaOpen distribution packages requested by user
    alpha_open_path = os.path.join(DIST_DIR, "AlphaOpen.zip")
    fg_alpha_open_path = os.path.join(DIST_DIR, "ForeverGuide-AlphaOpen.zip")
    shutil.copy2(zip_path, alpha_open_path)
    shutil.copy2(zip_path, fg_alpha_open_path)
    print(f"  -> {alpha_open_path} ({size_mb:.2f} MB)")
    print(f"  -> {fg_alpha_open_path} ({size_mb:.2f} MB)")


if __name__ == "__main__":
    package()
