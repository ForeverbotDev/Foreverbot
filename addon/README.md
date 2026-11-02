# Forever Guide: The Blue Spark ✨

An interactive in-game World of Warcraft companion addon designed for **Warcraft Forever**, Classic Era, and Season realms. Distributed via **CurseForge** and **Wago.io**.

Themed after the cinematic trailer's celestial **Blue Spark**, this companion hovers dynamically alongside your UI to illuminate your path through Azeroth with zero frame drops, zero network lag, and native Blizzard UI styling.

---

## 🌟 Features

### 1. The Blue Spark Companion (Floating Widget)
- **Living Celestial Orb**: A gentle, pulsing blue spark with a subtle glowing aura that hovers by your side.
- **Draggable & Dockable**: Click and drag anywhere on your screen. Lock it down with `/spark lock` once positioned.
- **Reactive Intelligence**:
  - **Zone Transitions**: Pulses with a celestial shimmer when you cross into a new zone, providing instant level ranges, recommended quest hubs, flight masters, and local dungeon entrances.
  - **Dungeon Entrance Tactician**: Expands with quick boss notes and entrance coordinates when nearing an instance.
  - **Combat Auto-Fade**: Smoothly fades to 15% opacity or hides during combat so it never obstructs your raid frames or spellcasts.
- **Native Blizzard Soundscapes**: Subtle, ambient chimes when discovering new areas or opening the codex.

### 2. In-Game Forever Codex (`/spark` or `/fg`)
- **Instant Search**: Search through thousands of items, dungeons, bosses, and Warcraft Forever content in real time.
- **Rich Native Tooltips**: Hover over items in the search window to view authentic Blizzard tooltips, item stats, and drop rates.
- **Chat Link Insertion**: Shift-click or click results to link items directly into guild, party, or raid chat.
- **Dungeon & Raid Docket**: One-click list of all 46 classic dungeons and raids with minimum/maximum level requirements and entrance coordinates.

### 3. Minimap Beacon
- Integrated minimap button that can be dragged smoothly around the minimap rim.
- Left-click to toggle the Codex, Right-click to toggle the Spark companion.

---

## 🎮 In-Game Slash Commands

| Command | Action |
| :--- | :--- |
| `/spark` or `/fg` | Toggle the Forever Codex search window |
| `/spark zone` or `/spark where` | Ask the Blue Spark for intel on your current zone |
| `/spark find <query>` | Instant search for items, bosses, or dungeon loot |
| `/spark lock` | Toggle position locking for the floating spark |
| `/spark toggle` | Summon or dismiss the floating spark companion |
| `/spark reset` | Reset the Blue Spark to screen center |

---

## 📦 Installation

### Option A: CurseForge App (Recommended)
1. Open the **CurseForge App**.
2. Search for **Forever Guide**.
3. Click **Install**.

### Option B: Manual Installation
1. Download the latest `ForeverGuide-v1.0.0.zip` from [Releases](https://github.com/ForeverbotDev/foreverbot/releases).
2. Extract the `ForeverGuide` folder into your World of Warcraft directory:
   - `World of Warcraft/_classic_era_/Interface/AddOns/ForeverGuide/`
3. Launch World of Warcraft and ensure **Forever Guide** is checked in your AddOns menu.

---

## 🛠️ Development & Building

The addon's catalog is compiled directly from the master `wow_forever.db` database using Python:

```bash
# 1. Compile database into optimized Lua tables
python3 scripts/export_catalog_to_lua.py

# 2. Package into a CurseForge release zip
python3 scripts/package_addon.py
```

The resulting zip archive is stored in `dist/ForeverGuide-v<version>.zip` ready for direct upload to the CurseForge Author Portal.

---

## ⚖️ Legal & Blizzard Policy Compliance

*Forever Guide* strictly adheres to Blizzard Entertainment's official [World of Warcraft UI and Add-on Development Policy](https://blizzard.com):
- 100% Free and open-source (MIT License).
- Zero monetization, paywalls, or premium tiers.
- Does not make out-of-game network or HTTP requests during gameplay.
- Does not automate gameplay or make combat decisions (strictly informational).
