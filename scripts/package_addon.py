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

    libs_folder = os.path.join(ADDON_DIR, "Libs")
    if os.path.exists(libs_folder):
        for root, _, files in os.walk(libs_folder):
            for file in sorted(files):
                rel_path = os.path.relpath(os.path.join(root, file), ADDON_DIR)
                files_to_pack.append(rel_path)

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
    dist_aliases = [
        "ForeverGuide.zip",
        "ForeverGuide-latest.zip",
        "AlphaOpen.zip",
        "ForeverGuide-AlphaOpen.zip",
    ]
    for alias in dist_aliases:
        dest = os.path.join(DIST_DIR, alias)
        shutil.copy2(zip_path, dest)
        print(f"  -> {dest} ({size_mb:.2f} MB)")

    # User download folders
    user_dirs = [
        "/home/s1l3nt/Desktop",
        "/home/s1l3nt/Downloads",
        "/home/s1l3nt/Public",
    ]
    for udir in user_dirs:
        if os.path.exists(udir):
            for fname in [f"ForeverGuide-v{version}.zip", "ForeverGuide.zip", "AlphaOpen.zip", "ForeverGuide-AlphaOpen.zip"]:
                target_file = os.path.join(udir, fname)
                shutil.copy2(zip_path, target_file)
                print(f"  [Deployed to user folder] -> {target_file}")


if __name__ == "__main__":
    package()
