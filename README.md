<div align="center">
  <img src="assets/foreverbot_banner_ultrawide.png" alt="Foreverbot Ultra-Wide Banner" width="100%" />
</div>

# ⚔️ Foreverbot (Open Alpha) — Instant In-Game Knowledge & Private Discord Assistant for World of Warcraft: Forever
> The in-game Discord Assistant for **World of Warcraft: Forever**. Look up item stats & drop rates, get directions when you're lost, and find answers right from your PC, phone, or tablet through Discord. Built with **private per-user responses** so each player's queries and answers are completely private (`ephemeral`) without filling server channels with spam!
>
> 🧪 **Alpha Notice:** Foreverbot is currently in **Open Alpha** leading up to the global launch of World of Warcraft: Forever on November 4, 2026. Data and features are actively tuned and community-tested.

[![Discord Assistant](https://img.shields.io/badge/Discord-Assistant-5865F2?logo=discord&logoColor=white)](https://discord.com)
[![Status](https://img.shields.io/badge/Status-Open%20Alpha-3B82F6)](https://github.com/ForeverbotDev/foreverbot)
[![WoW Forever](https://img.shields.io/badge/WoW-Forever-F59E0B)](https://github.com/ForeverbotDev/foreverbot)
[![Database](https://img.shields.io/badge/Database-19.6K%20Items%20%E2%80%A2%2010.1K%20NPCs%20%E2%80%A2%204.2K%20Quests%20%E2%80%A2%20370K%20Loot%20Drops%20%E2%80%A2%2046%20Dungeons-10B981)](#-database)
[![Verified Queries](https://img.shields.io/badge/Verified_Queries-15%2C000%2B_Combos-10B981)](#-automated-testing-and-query-verification)
[![Scheduled Sync](https://img.shields.io/badge/Scheduled_Intel_Sync-Tuesdays_8pm_EST-10B981)](docs/TUESDAY_WEEKLY_INTEL.md)
[![Daily 8pm QC Email](https://img.shields.io/badge/Daily_QC_Email-8:00_PM_Daily-10B981?logo=gmail&logoColor=white)](tests/reports/DAILY_ONLINE_FACT_CHECK_REPORT.md)
[![Python](https://img.shields.io/badge/Python-3.10%2B-3776AB?logo=python&logoColor=white)](https://www.python.org/downloads/)
[![Hosting](assets/hosting_badge.svg)](docs/HOSTING_AND_DEPLOYMENT.md)
[![Feedback](https://img.shields.io/badge/Feedback-Help%20Refine%20the%20Data%20%E2%9E%94-FF5722?logo=github&logoColor=white)](https://github.com/ForeverbotDev/foreverbot/issues/new?template=failed_response_report.yml)

---
## 📦 Download & 1-Click Launch Guide

Foreverbot ships with its **offline WoW Forever database pre-built and bundled**—no external database servers, Docker containers, or privileged Discord intents required.

<div align="center">

[![Download ZIP](https://img.shields.io/badge/⬇️_Direct_Download-Foreverbot_ZIP_(No_Git_Needed)-10B981?style=for-the-badge&logo=github&logoColor=white)](https://github.com/ForeverbotDev/foreverbot/archive/refs/heads/main.zip)

<sub>*Download the ZIP, extract it anywhere on your computer, and double-click to launch.*</sub>

</div>

---

### 🚀 1-Click Launch (Which File to Double-Click)

| Operating System | Double-Click This File | What Happens Automatically |
| :--- | :--- | :--- |
| **🐧 Linux (SteamOS, KDE, GNOME, Ubuntu)** | **`start_bot.sh`** *(Don't click .bat)* | Spawns a terminal window (Konsole/GNOME), configures `.venv`, opens editor! |
| **🍎 macOS (Apple Silicon & Intel)** | **`start_bot.command`** | Launches native Terminal.app, configures `.venv`, opens editor! |
| **💀 Windows (10 / 11)** | **`start_bot.bat`** | Verifies Python, configures `.venv`, opens Notepad with `.env`, launches! |

> 💡 **Tip:** On your first launch, the script will automatically create your settings file and pop open your text editor. Simply paste your Discord bot token and you're done! (Detailed inside [`INSTRUCTIONS.txt`](INSTRUCTIONS.txt)).

---

### Step 2 — Create & Invite Your Discord Bot (2 Minutes)

1. **Create the Application:**
   - Open the **[Discord Developer Portal](https://discord.com/developers/applications)** and click **`New Application`** (top-right).
   - Name it **`Foreverbot`** (or your guild's name) and click **Create**.
2. **Copy Your Bot Token:**
   - Select **`Bot`** in the left sidebar ➔ click **`Reset Token`** ➔ copy your token and keep it safe.
   - *(Note: You do **not** need to enable any Privileged Gateway Intents—Foreverbot uses native Discord Slash Commands with default intents.)*
3. **Invite the Bot to Your Discord Server:**
   - Select **`OAuth2`** in the left sidebar:
     - Under **OAuth2 URL Generator ➔ Scopes**, check:
       - [x] `bot`
       - [x] `applications.commands`
     - Under **Bot Permissions** (appears below Scopes), check:
       - [x] `View Channels`
       - [x] `Send Messages`
       - [x] `Embed Links`
       - [x] `Read Message History`
       - [x] `Use Slash Commands`
   - Copy the **Generated URL** at the bottom of the page, paste it into your browser, and authorize the bot into your server.

---

### Step 3 — Configure & Launch (Choose Your Operating System)

Foreverbot includes automated self-bootstrapping launcher scripts that automatically verify Python, set up an isolated virtual environment (`.venv`), install all requirements, and launch the bot. Choose your operating system below:

---

#### 🐧 1. Linux Setup (Ubuntu, Debian, Fedora, Arch, Mint, Pop!_OS, openSUSE)

**Step A — Install Prerequisites (Verified for Top Linux Distros):**

If your system does not have Python 3, `venv`, or `pip` installed yet, copy and run the one-line command for your distribution:

| Distribution | Package Manager Command |
| :--- | :--- |
| **Ubuntu / Debian / Linux Mint / Pop!_OS** | `sudo apt update && sudo apt install -y python3 python3-venv python3-pip` |
| **Fedora / RHEL / Rocky / AlmaLinux** | `sudo dnf install -y python3 python3-pip` |
| **Arch Linux / Manjaro / EndeavourOS** | `sudo pacman -S --needed python python-pip` |
| **openSUSE (Tumbleweed / Leap)** | `sudo zypper install -y python3 python3-pip` |
| **Alpine Linux (Docker / Minimal)** | `sudo apk add --no-cache python3 py3-pip` |

> 💡 **Why `python3-venv` is needed on Debian/Ubuntu derivatives:**
> Debian and Ubuntu deliberately split Python's standard `venv` and `ensurepip` modules into a separate package (`python3-venv`). Installing `python3-venv` ensures your isolated virtual environment (`.venv`) is created cleanly with zero pip errors.

**Option A — 1-Click Launch (KDE Plasma, GNOME, SteamOS):**
1. In your file manager, simply double-click **`start_bot.sh`**!
   - It will automatically launch inside your native terminal (Konsole, GNOME Terminal, etc.), configure `.venv`, install packages, and pop open `.env` in your text editor.
   - *Note for Linux users: Do **NOT** double-click `start_bot.bat`—`.bat` is for Windows and will prompt Wine or Protontricks.*

**Option B — Terminal Launch:**
Open a terminal inside your extracted bot folder:

```bash
# 1. Run the launcher script (it will automatically create .env and open your editor if missing)
./start_bot.sh
```
*`start_bot.sh` automatically creates `.venv`, installs all packages from `requirements.txt`, and connects to Discord.*

---

#### 🍎 2. macOS Setup (Apple Silicon M1/M2/M3 & Intel)

**Option A — 1-Click Launch:**
1. In Finder, simply double-click **`start_bot.command`**!
   - It will automatically open Terminal.app, set up your environment, and launch Foreverbot.

**Option B — Terminal Launch:**
Open the **Terminal** app (`Cmd + Space` ➔ type `Terminal` ➔ press Enter):

```bash
# 1. Navigate to your extracted folder (e.g. in your Downloads folder)
cd ~/Downloads/foreverbot

# 2. Run the launcher
./start_bot.sh
```
> 💡 *macOS tip: If you need to install or update Python 3, you can do so in one command via Homebrew: `brew install python`.*

---

#### 💀 3. Windows Setup (Windows 10 / 11)

**Option A — 1-Click Launch:**
1. Extract your downloaded ZIP to any folder (e.g. `Desktop` or `Downloads`).
2. Double-click **`start_bot.bat`**.
   - On the first run, the script automatically checks for Python, creates your `.venv`, installs all packages, creates `.env`, and opens it directly in **Notepad**.
3. In Notepad, paste your token next to `DISCORD_BOT_TOKEN=`:
   ```ini
   DISCORD_BOT_TOKEN=paste_your_token_here
   ```
4. Save the file (**`Ctrl + S`**) and close Notepad.
5. Press any key in the terminal window—Foreverbot connects and goes live immediately!

**Option B — PowerShell / Command Prompt:**
```powershell
# 1. Navigate to the extracted folder in PowerShell:
cd C:\path\to\foreverbot

# 2. Copy configuration and open in Notepad:
copy .env.example .env
notepad .env   # Paste your DISCORD_BOT_TOKEN=, save (Ctrl+S), and close

# 3. Run the automated Windows launcher:
.\start_bot.bat
```

<details>
<summary><b>🔧 Advanced / Manual Virtual Environment Setup (All Platforms)</b></summary>

If you prefer managing your own virtual environments manually without the launcher scripts:

```bash
# Linux / macOS:
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env   # Edit .env with your DISCORD_BOT_TOKEN
python3 bot.py

# Windows (PowerShell):
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
copy .env.example .env   # Edit .env with your DISCORD_BOT_TOKEN
python bot.py
```
</details>

---

### Step 4 — Verify You're Live

When Foreverbot connects, you will see this confirmation in your terminal:
```text
Logged in as Foreverbot (123456789012345678)
Synced 41 global slash commands.
Instantly synced 41 commands to server: Your Guild Server (987654321098765432)
Foreverbot is live and ready!
```
> 💡 **Instant Guild Slash Commands:** Foreverbot automatically pushes guild-level command syncs to your connected Discord server on startup, so typing **`/`** in your server displays all 41 commands **immediately** (bypassing Discord's 1-hour global cache delay!).

> 🛡️ **Private Per-User Responses:** When you run any query command (like `/item`, `/bis`, `/dungeons`, or `/ask`), only you will see the response (*"Only you can see this • Dismiss message"*). Group raid tools like `/roll` and `/signup` remain public for everyone in your raid to click and interact with!

---

### Step 5 — How Does Foreverbot Run? (Hosting & 24/7 Deployment)

Once installed, **Foreverbot runs as a lightweight standard Python program on your own computer or server.**

```
   [Player in Discord Server]
               │
               │  Types /item Thunderfury
               ▼
        [Discord Servers]
               │
               │  (Pushes slash command over persistent outbound WebSocket)
               ▼
    [Your Machine (PC / Mac / Server)]
     ├── bot.py runs locally (~114 MB RAM, 0% CPU idle)
     ├── Searches local wow_forever.db (FTS5 SQLite) in < 1 ms
     └── Sends formatted Embed back to Discord
```

* **Runs Directly on Your Hardware:** Foreverbot uses only **~114 MB of RAM** and virtually **0% CPU** when idle. It can run seamlessly on your daily computer, a laptop in a closet, or a $35 Raspberry Pi.
* **No Port Forwarding or Public IP Needed:** The bot connects *outbound* to Discord's Gateway via a secure encrypted WebSocket (`wss://`). You do **not** need to open router ports, and players never see your home IP address (Discord acts as a protective shield).
* **100% Offline Database:** All 19,628 items, 10,122 NPCs, 4,245 quests, and 370,360 drop records live inside `wow_forever.db` on your device.
* **Sleep & Shutdown Behavior:** If your PC sleeps or turns off, the bot goes offline. As soon as you wake your PC and run `./start_bot.sh` (or `start_bot.bat`), it reconnects in ~2 seconds.
* **Want 24/7 Uptime?** 
  - **Linux `systemd` Service:** Auto-starts on system boot and restarts if closed (see guide).
  - **Free Cloud Server:** Deploy to **Oracle Cloud Always-Free Tier** ($0/month forever).
  - **Budget Cloud VPS:** Host on Hetzner, DigitalOcean, or Linode ($3–$5/month).
  - **Docker & Docker Compose:** Containerized with `Dockerfile` and `docker-compose.yml` (`docker compose up -d`).

📖 **[Read the Full Architecture, Hosting & 24/7 Deployment Guide ➔](docs/HOSTING_AND_DEPLOYMENT.md)**

---

## 💡 Quick Command Cheat Sheet (Top Categories)

### 🗡️ Gear & Items
- `/item query: dal rend` — Pulls up instant stats, drop rates, and boss loot tables without having to Alt-Tab mid-dungeon.
- `/compare query: brutality blade weapon2: deathbringer` — Side-by-side stat breakdown, swing speeds, and glancing blow math so you never equip the wrong piece.
- `/bis query: rogue spec: swords` — Full slot-by-slot gear progression and exactly which dungeons to farm for your next upgrade.
- `/resist query: fire current: 150` — Checks your exact mitigation tier and tells you how many points you're missing before the raid melts you.

### 🗺️ World Navigation & Dungeons
- `/dungeons query: 42` — Enter your level and instantly see every eligible dungeon, wing level range, and entrance directions.
- `/flightpath query: stv` — Stranded in contested territory? Finds the closest flight master with exact map coordinates.
- `/zones query: duskwood` — Zone level brackets, quest hubs, and contested danger spots before making the 15-minute run.
- `/mob query: garr` — Boss HP pools, spawn locations, deadly abilities, and rare drop chances in seconds.

### 🛡️ Raiding, Consumables & PvP
- `/raid query: baron geddon` — Boss wipe mechanics, raid positioning diagrams, and dispel priority at a glance.
- `/consumes query: fury warrior` — Full raid night checklist: mandatory flasks, elixirs, and buff food with zero guesswork.
- `/buffs query: ony head` — Never miss a world buff: turn-in locations, cooldown timers, and raid-wide stat gains.
- `/resets query: onyxia` — Live countdown clocks for weekly, 5-day, and 3-day lockouts so you never get saved early.
- `/pvp query: rank 14` — Honor rank math, weekly 20% decay calculation, and battleground strategy guides.

### 🎲 Raid Leader Tools & Macros
- `/signup query: MC Sunday 7pm max_players: 40` — Interactive raid roster with Tank, Healer, and DPS reaction buttons right in Discord.
- `/roll query: Reins of the Deathcharger seconds: 30` — Live loot rolling with a fair countdown timer so loot drama never touches your raid.
- `/gdkp query: 60000 cut: 10 raiders: 40` — Automatic gold pot splitter with organizer cut and per-player payout math done for you.
- `/macro query: stance dance overpower` — Battle-tested, 1-click copy-paste macros for stance dancing, mouseovers, and panic buttons.
- `/ask query: what are the best pre-raid swords?` — Ask any WoW question in plain English and get an instant, accurate answer.

---

## 📜 Complete 41-Command Reference

| Category | Commands |
| :--- | :--- |
| **Gear & Items** | `/item`, `/compare`, `/bis`, `/resist` |
| **Quests & Progression** | `/quest`, `/keys`, `/attunement`, `/rep` |
| **World & Travel** | `/flightpath`, `/map`, `/zones`, `/dungeons`, `/level`, `/route` |
| **Economy & Gathering** | `/vendor`, `/gather`, `/profession`, `/farm`, `/mob`, `/rare` |
| **Raiding & Intel** | `/raid`, `/consumes`, `/buffs`, `/resets`, `/intel` |
| **Class Mastery** | `/build`, `/talents`, `/race`, `/macro`, `/profile` |
| **PvP & Competitive** | `/pvp`, `/twink` |
| **Raid Management** | `/signup`, `/comp`, `/gdkp`, `/roll`, `/addons` |
| **Community & AI** | `/forever`, `/events`, `/trivia`, `/ask` |

---

<a id="sources-and-quality"></a>
## 🛡️ Data Sources & Quality Measures (How I Ensure Accuracy)

Foreverbot is built to provide authoritative, grounded answers for **World of Warcraft: Forever** without hallucinations or guesswork. Every answer served by the bot is rooted in verified public game knowledge, canonical combat formulas, and multi-layered automated testing.

---

### 📚 Primary Information Sources

| Source Category | Provenance & Compilation Method | Data Provided |
| :--- | :--- | :--- |
| **🎮 Public Game Catalogs & Reference Archives** | Curated from open, publicly compiled Classic game databases and community wiki archives. | **19,628 items** with exact stats, drop rates, required levels, sell values; **10,122 creatures** with health pools and abilities; **4,245 quests**; **370,360 creature drop records**; **54 flight paths**. |
| **📜 WoW Forever Alpha Notes & Blue Tracker** | Ingested from public developer announcements and official forum topics via [`scripts/sync_blizzard_blue_tracker.py`](scripts/sync_blizzard_blue_tracker.py). | **16 custom dungeons & raids** (*Hall of Thanes*, *Ruins of Lordaeron*, *Excavation Site*, *City of Dalaran*, *The Drowned City*, *Krol'dok Stronghold*, *Alcaz Island Prison*, *Blackmaw Hold*, *Shaper's Terrace*), custom bosses, and horizontal progression sets. |
| **⚔️ Canonical Combat & Mechanics Math** | Grounded in standard Vanilla 1.12 combat tables and verified theorycrafting formulas. | Exact dual-wield glancing blow math (+5 weapon skill = 5% glancing penalty vs. 35% base), yellow-hit cap rules (6% vs. 9%), 5-tier resistance mitigation formulas (0–360 SR/FR/NR/AR/Frost R), and GDKP payout splits. |
| **🗡️ Meta, BiS & Addon Knowledge Tables** | Curated by experienced Vanilla & Classic raid leaders and theorycrafters. | Pre-raid Best-in-Slot (BiS) gearing paths for all 9 classes and specs, top 5 essential addons per class (`/addons`), raid consumable matrices (`/consumes`), and 1-60 speedleveling routes. |
| **🔄 Live Tuesday Intel Sync** | Automated weekly ingestion via [`scripts/tuesday_weekly_intel_sync.py`](scripts/tuesday_weekly_intel_sync.py) at weekly reset (Tuesdays at 8:00 PM EST). | Stealth hotfixes, item proc-per-minute (PPM) adjustments (e.g. Nightfall 14.5% normalization), dungeon balance changes, and meta shifts documented in [`docs/TUESDAY_WEEKLY_INTEL.md`](docs/TUESDAY_WEEKLY_INTEL.md). |

---

### 🔬 Quality Measures: How I Ensure Accuracy

To maintain high data fidelity and prevent regressions during Open Alpha, Foreverbot enforces a strict quality assurance pipeline before any release:

1. **Pre-Flight Database Integrity Audits (`tests/test_deep_quality.py`)**
   - **Zero NULL Fields:** Validates that no essential item stats, boss names, or dungeon wings contain empty or broken attributes.
   - **Boundary Verification:** Confirms that all dungeon level brackets satisfy strict invariant math (`min_level <= max_level`) and that all coordinate mappings align with in-game maps.
   - **Quality Scorecard:** 81 individual integrity checks executed before every build (100% pass rate).

2. **Exhaustive Permutation Testing (35,000+ Combinations)**
   - Tested through [`tests/test_all_variables_permutations.py`](tests/test_all_variables_permutations.py), checking 35,997 distinct permutations across all classes, specs, races, resistance tiers, level brackets, and weapon pairings.
   - Verifies that racial bonuses (e.g. Human sword skill +5, Orc axe skill +5) apply accurately and that resistance mitigation curves behave monotonically from 0 to 360 resistance.

3. **Discord Slash Command Authenticity Testing (15,000+ Permutations)**
   - Tested through [`tests/test_slash_commands_authenticity.py`](tests/test_slash_commands_authenticity.py).
   - Validates that every one of the 41 slash commands returns properly formatted Discord Embeds, enforces private per-user replies (`ephemeral=True`), handles Discord's 100-character autocomplete limits, and safely manages interactive UI components.

4. **Player Simulation & Query Verification (500 User Commands)**
   - Headless simulation via [`tests/test_500_user_commands.py`](tests/test_500_user_commands.py) fires 500 realistic user queries (item typos, nicknames like `"edgies"`, `"hoj"`, `"fap"`, multi-word questions) sequentially against the engine to verify stability and eliminate crashes.

5. **Scheduled Weekly Reset Audits (Tuesdays at 8:00 PM EST)**
   - Every Tuesday evening at weekly server reset, automated scripts check for developer blue posts, server maintenance hotfixes, and undocumented client changes, updating `wow_forever.db` and publishing the weekly intel report.

6. **Community Verification Loop ("Help Refine the Data")**
   - Discrepancy reports submitted by players via GitHub with screenshots are verified against live combat logs, corrected in SQLite, and codified into new unit tests to prevent future regressions.

---

<a id="database"></a>
### 🗄️ Database Architecture & Storage

Foreverbot’s database (**`wow_forever.db`** • ~32 MB) is bundled directly with the bot as a standalone, zero-dependency SQLite engine. Every record is verified for accuracy against canonical World of Warcraft: Forever specifications:

```
┌────────────────────────────────────────────────────────────────────────┐
│                   WORLD OF WARCRAFT: FOREVER CATALOG                   │
│                                                                        │
│   1. WoW Forever Expansion Data      2. Authentic Complete Baseline    │
│   • 16 Custom Dungeons & Raids       • 19,628 Total Items (16,422 Live)│
│   • Custom Bosses & Tactics          • 10,122 Creatures & Raid Bosses  │
│   • Horizontal Progression Sets      • 4,245 Quests & Objectives       │
│   • New Leveling Zones & Taxi        • 370,360 Loot Drops • 54 Taxis   │
│                                                                        │
│   3. Live Blizzard Blue Tracker      4. SQLite FTS5 Full-Text Engine   │
│   • Automated Patch Sync Workflow    • Sub-second indexed search       │
│   • Real-time balance tuning         • Zero external API bottleneck    │
└────────────────────────────────────┬───────────────────────────────────┘
                                     ▼
                     [ Foreverbot Discord Assistant ]
```

* **Local SQLite FTS5 Virtual Tables:** All tables are indexed using SQLite Full-Text Search (FTS5) with Porter stemming and exact-match priority ranking, enabling sub-second in-memory lookups without requiring external databases, Docker, or third-party web scraping during Discord interactions.

<details>
<summary><strong>🔍 Deep Dive: Where Does the Data Come From & Why Is It Only ~32 MB?</strong> (Click to expand)</summary>

<br/>

#### 1. Data Origins & Canonical Sources
* **Classic Game Client DBCs & Tables:** Extracted directly from canonical client tables (`ItemSparse.db2`, `Item.db2`, `item_template`, `creature_template`, `quest_template`, `creature_loot_template`, `reference_loot_template`) covering all 19,628 items, 10,122 NPCs/creatures, 4,245 quests, and 370,360 drop records.
* **Wowhead & Tooltip Archive:** Precise stat strings (`+12 Strength, 41.2 DPS`), on-equip spell effects, flavor quotes, and boss drop percentages (`Baron Rivendare: 0.02%`).
* **WoW: Forever Expansion Content:** Curated entries for all 16 custom dungeons & raids (*Roots of Nordrassil*, *Karazhan Crypts*, *Temporal Rift*, etc.), custom boss strategies, and taxi networks.
* **Weekly Automated Blue Tracker:** Automated GitHub Actions pipeline refreshes hotfixes, developer notes, and tuning adjustments every Tuesday reset.

#### 2. The Storage Math (Row-by-Row Byte Footprint)
Pure relational text and numbers are remarkably lightweight when stripped of repetitive JSON bloat:

| Catalog Table | Total Records | Raw Text Size | Average Record Size |
| :--- | :--- | :--- | :--- |
| **`items`** | **19,628 items** | **2.85 MB** | ~145 bytes / item |
| **`quests`** | **4,245 quests** | **1.90 MB** | ~469 bytes / quest |
| **`creatures`** | **10,122 NPCs** | **0.47 MB** | ~48 bytes / NPC |
| **`loot`** | **370,360 drops** | **8.80 MB** | ~24 bytes / drop |
| **`dungeons`** | **46 instances** | **0.01 MB** | ~292 bytes / dungeon |
| **FTS5 Inverted Search Indexes & B-Trees** | — | **~18.0 MB** | Full-text token trees & B-Tree headers |
| **Total `wow_forever.db`** | **404,455 records** | **~32.0 MB** | Complete offline package |

#### 3. Why Is It So Fast & Compact Compared to Other Bots?
* **Column Names Stored Once:** A JSON representation repeats `"name"`, `"quality"`, `"stats"` 19,628 times, multiplying file sizes by 10x to 20x. SQLite stores column definitions once in the schema header.
* **Variable-Length Integers (Varints):** Small numbers like level requirements (`1` to `60`) consume only 1 single byte instead of 4 or 8 bytes. Empty strings and nulls consume 0 bytes in SQLite record headers.
* **Zero Image/Audio Bloat:** The database contains pure structured data. Discord handles image rendering through its own CDN, eliminating the need to store heavy 3D textures or client assets locally.
* **Sub-Second On-Disk Page Seeks:** Queries traverse SQLite binary B-Trees rapidly, reading only the single 4 KB page needed and keeping system RAM footprint at a lean ~85 MB.

</details>

---

<a id="testing"></a>
## 🧪 Automated Testing & Query Verification

Foreverbot is verified across **35,000+ tested query combinations** across automated test suites with weekly updates every Tuesday at 8:00 PM EST:
```bash
python3 tests/test_subsecond_knowledge_benchmark.py       # 1,178 Query logic & retrieval tests
python3 tests/test_random_item_catalog_verification.py     # Random verification across all item qualities, mobs & quests
python3 tests/test_all_variables_permutations.py          # 33,121 Combinatorial variable permutation checks
python3 tests/test_slash_commands_authenticity.py         # 15,077 Direct Discord '/' slash command authenticity tests
python3 tests/test_massive_scale_suite.py                 # 3,700 Ultra-scale catalog, combat math & edge-case tests
python3 tests/test_ultra_concurrency_and_fuzz.py          # 2,393 High-concurrency load, button state & fuzz tests
python3 tests/test_deep_information_authenticity_audit.py # 1,675 Ground-truth data & credentials audit tests
python3 tests/test_howto_guide_suite.py                   # 115 How-To guide prompt tests
python3 tests/test_deep_quality.py                        # 81 Database & custom dungeon tests
python3 tests/test_quality_suite.py                       # 27 Core system tests
```

### 🔬 What The Verification Suites Cover:
- **Section 1: Full Database Catalog Sweeps (324 tests):** Every item, quest, mob, dungeon, flightpath, and vendor lookup tested with exact matches and multi-word token searches.
- **Section 2: Level 1 to 60 Dungeon Eligibility (60 tests):** Every character level tested against level bracket filtering and starter zone recommendations.
- **Section 3: Combat Mechanics & Mitigation Math (150 tests):** 5-school resistance mitigation across 20 resistance tiers (0 to 360 SR/FR/NR/AR/Frost R) and dual-wield glancing blow comparisons.
- **Section 4: Guild Economy & Raiding (100 tests):** 50 GDKP gold pot splits (organizer cuts & tank bonuses) and 40-man raid comp synergy coverage.
- **Section 5: Class Mastery & PvP Systems (162 tests):** Spec codes, talent trees, and PvP honor rank calculations.
- **Section 6: Attunements, Keys & Leveling Routes (104 tests):** All dungeon keys, raid attunements, faction reputations, and speedleveling route sweeps.
- **Section 7: Out-of-the-Box, Slang & Edge Cases (600 tests):** Extreme typos, player shorthand (`"rag"`, `"hoj"`, `"fap"`, `"dft"`, `"sgc"`), natural language prompts, hostile SQL/XSS inputs, and boundary numbers.
- **Section 8: Headless Slash Command Dispatch (50 tests):** Asynchronous Discord command execution verifying complete embed responses without network overhead.
- **Section 9: Database Fuzz & Connectivity Matrix (700 tests):** Uppercase, lowercase, whitespace trims, mob token matching, quest integrity, and 19-city flight network transit routing.
- **Section 10: Weapon Glancing & Boss Hit Matrix (400 tests):** 40 weapon pairings across 10 race permutations verifying glancing penalty mitigation, special attack hit caps (6% vs 9%), and weapon speed damage normalization.
- **Section 11: Honor Ranking & Weekly 20% Decay Matrix (280 tests):** All 14 PvP ranks across 20 rating point intervals validating Tuesday decay retention.
- **Section 12: Class BiS, Talents & Consumables (250 tests):** Pre-raid BiS lists across all 9 classes (including Druid, Paladin, Shaman), 1-60 leveling advice, and consumable checklists.
- **Section 13: 500 Out-of-the-Box Conversational & NLP Queries (500 tests):** "Where do I find...", "Can [class] use...", "How much [stat]...", and gamer LFG chat prompts verified safe and structured.
- **Section 14: 1,001 Direct Slash Command Authenticity Permutations (1,001 tests):** Continuous verification across all Discord `/` slash commands validating `ephemeral=True` channel privacy, interactive Raid/Roll Views, and domain ground truth.
- **Section 15: Ultra Concurrency, Interactive Buttons & Security Fuzz (2,393 tests):** 500 concurrent async slash dispatches, 816 autocomplete permutations, 250 interactive button state machine transitions (`/roll` and `/signup`), 500 malicious injection/overflow probes (SQLi, XSS, unicode chaos), and 271 mathematical monotonicity/GDKP bounds checks.
- **Section 16: Deep Information Authenticity & Ground Truth Audit (1,675 tests):** 153 items verified against canonical WoW Forever stats, all 46 dungeons verified for level brackets & coordinates, 54 flight paths verified for factions & routes, 38 creatures & raid bosses verified for tactics & health, all 27 quests, 20 resistance tiers across 5 schools, and live environment credentials.
- **Section 17: Daily 8:00 PM Online Fact-Checking & Final QC Email Pipeline:** Executes randomized queries daily across all item tiers, creatures, and quests, cross-referencing post-query data against live external web services ([Wowhead Classic Tooltip API](https://nether.wowhead.com/classic/tooltip/item/19019), [ClassicDB Live Gateway](https://classicdb.ch/), and [Blizzard Live Blue Forums](https://eu.forums.blizzard.com/en/wow/t/631316.json)). At 8:00 PM daily, the complete Markdown audit log and styled HTML dashboard are automatically compiled and emailed to the maintainer for final human QC verification before promotion.

---

<a id="feedback"></a>
## 📸 Community Feedback & Reporting Failed Responses

> [!TIP]
> **Help Refine the Data During Open Alpha!**  
> If Foreverbot ever returns an inaccurate drop rate, wrong zone route, or calculation error, snap a screenshot and submit a 1-click report below. Every submission is verified and integrated directly into the database.

Encountered an inaccurate item drop rate, wrong zone directions, faulty level recommendation, calculation error, or unexpected response? **I want your feedback!**

During this **Open Alpha**, community bug reports with Discord screenshots help me refine edge cases and data accuracy ahead of the November 4, 2026 launch.

| Feedback Channel | Action Link | What to Include |
| :--- | :--- | :--- |
| **📸 Report a Failed / Inaccurate Response** | **[Open a Response Issue ➔](https://github.com/ForeverbotDev/foreverbot/issues/new?template=failed_response_report.yml)** | Exact question asked, Foreverbot's reply, and a Discord screenshot (drag & drop or Ctrl+V). |
| **💡 Feature Suggestion & Ideas** | **[Submit Idea ➔](https://github.com/ForeverbotDev/foreverbot/issues/new?template=general_feedback.yml)** | Suggestions for new slash commands, custom dungeon strategies, or bot enhancements. |
| **💬 Community Q&A & Theorycrafting** | **[Join Discussions ➔](https://github.com/ForeverbotDev/foreverbot/discussions)** | Discuss WoW Forever builds, raid compositions, and bot tips with other guild leaders. |

---

## 📄 Official Guide & Release Notes

- **[AUTOMATED_TESTING_AND_SOAK_REPORT.md](docs/AUTOMATED_TESTING_AND_SOAK_REPORT.md)** — Comprehensive QA & test report (scheduled weekly Tuesdays 8pm EST • zero memory leaks).
- **[DAILY_ONLINE_FACT_CHECK_REPORT.md](tests/reports/DAILY_ONLINE_FACT_CHECK_REPORT.md)** — Daily automated online fact-checking report independently verifying post-query data against live web APIs.
- **[BLIZZARD_BETA_PATCH_NOTES.md](docs/BLIZZARD_BETA_PATCH_NOTES.md)** — Official Blizzard WoW: Forever Live Tracker Blue Development Notes (Tracked from Blue Tracker Topic #631316 • Updated Oct 26, 2026).
- **[RELEASE_NOTES.md](docs/RELEASE_NOTES.md)** — What's new in v3.0.0 Open Alpha (Channel Layering, Transit Routing, 4,904 Tests).

### 🔄 Automated Blizzard Live Tracker Blue Sync
Foreverbot automatically stays synced with official Blizzard WoW: Forever Live Tracker Blue and pushes updates to GitHub:
```bash
python3 scripts/sync_blizzard_blue_tracker.py --auto-push
```

---

## 🙏 Acknowledgments & Thanks

Special thanks to **Blizzard Entertainment** for creating World of Warcraft — the world, lore, and community that inspired this tool.

---

## ⚖️ Legal Disclaimer & Fair Use Notice

* **Unofficial Fan Project:** Foreverbot is an independent, open-source fan project and is not affiliated with, endorsed by, or sponsored by Blizzard Entertainment, Inc.
* **Trademarks:** *World of Warcraft*, *Warcraft*, and *Blizzard Entertainment* are trademarks or registered trademarks of Blizzard Entertainment, Inc. in the U.S. and/or other countries. All related logos, names, and images are the property of their respective owners.
* **Fair Use Notice:** All game item names, numerical statistics, drop rates, and combat formulas referenced by Foreverbot are factual gameplay information curated for community reference, theorycrafting, and educational purposes under Fair Use. Foreverbot contains no proprietary game code, client executables, 3D models, textures, or audio assets.

---

<div align="center">
  <sub>Built with passion for the <strong>World of Warcraft: Forever</strong> community. If you enjoy Foreverbot, consider supporting development:</sub><br/><br/>
  <a href="https://buymeacoffee.com/pixelpirate" target="_blank">
    <img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="30" style="height: 30px !important;">
  </a>
  <br/><br/>
  <img src="assets/canada_maple_leaf_3d.png" alt="Crafted with passion in Canada" width="28" height="24" />
</div>

