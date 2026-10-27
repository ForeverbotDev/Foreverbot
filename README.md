# ⚔️ Foreverbot: Epic Edition (Open Beta) // World of Warcraft: Forever Discord Co-Pilot
> The in-game Discord companion for **World of Warcraft: Forever**. Look up item stats & drop rates, get directions when you're lost, and find answers right from your PC, phone, or tablet without leaving the game. Built with **Zero-Clutter Channel Layering** so each player's queries and answers are completely private (`ephemeral`) without filling server channels with spam!
>
> 🧪 **Beta Notice:** Foreverbot is currently in **Open Beta** leading up to the global launch of World of Warcraft: Forever on November 4, 2026. Data and features are actively tuned and community-tested.

[![Discord Bot](https://img.shields.io/badge/Discord-Companion%20Bot-5865F2?logo=discord&logoColor=white)](https://discord.com)
[![Status](https://img.shields.io/badge/Status-Open%20Beta-3B82F6)](https://github.com/s1l3ntHub/wow-foreverbot)
[![WoW Forever](https://img.shields.io/badge/WoW-Forever-F59E0B)](https://github.com/s1l3ntHub/wow-foreverbot)
[![Edition](https://img.shields.io/badge/Edition-Epic%20v3.0.0%20Beta-9333EA)](docs/EPIC_EDITION_RELEASE_NOTES.md)
[![Tests Passing](https://img.shields.io/badge/Tests-4%2C904%20%2F%204%2C904%20Passed-10B981)](#-automated-testing)

[![Python](https://img.shields.io/badge/Python-3.10%2B-3776AB?logo=python&logoColor=white)](https://www.python.org/downloads/)

---

## 📦 Download & Installation Guide

Foreverbot ships with its complete **Classic & Classic+ SQLite database (`wow_forever.db`) pre-built and bundled**—no external database servers, Docker containers, or privileged Discord intents required.

### Step 1 — Download Foreverbot

| Method | Instructions |
| :--- | :--- |
| **🟢 Download ZIP *(Easiest)*** | Click the green **`<> Code`** button at the top-right of this page ➔ click **[Download ZIP](https://github.com/s1l3ntHub/wow-foreverbot/archive/refs/heads/main.zip)**, and extract the folder anywhere on your computer. |
| **🏷️ Beta Release Archive** | Download the tagged **`v3.0.0-beta`** release directly from the **[Releases / Tags](https://github.com/s1l3ntHub/wow-foreverbot/tags)** page. |
| **💻 Git Clone *(Recommended for Updates)*** | Run `git clone https://github.com/s1l3ntHub/wow-foreverbot.git && cd wow-foreverbot` in your terminal. |

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

### Step 3 — Configure & Launch

#### 🐧 Linux & 🍎 macOS (1-Command Auto-Setup)
Open a terminal inside your `wow-foreverbot` folder:
```bash
# 1. Create your .env configuration file
cp .env.example .env
```
Open `.env` in any text editor and paste your token next to `DISCORD_BOT_TOKEN=`:
```ini
DISCORD_BOT_TOKEN=your_discord_bot_token_here

# Optional: Add a free Google Gemini API key (https://aistudio.google.com/)
# for open-ended AI theorycrafting in /ask. All 40 commands & DB lookups work 100% without it!
GEMINI_API_KEY=
```
Then run the self-bootstrapping launcher script (it automatically creates `.venv`, installs `requirements.txt`, and starts the bot):
```bash
./start_bot.sh
```

<details>
<summary><b>🪟 Windows (PowerShell / Command Prompt) Instructions</b></summary>

```powershell
# 1. Create and activate a virtual environment
python -m venv .venv
.\.venv\Scripts\Activate.ps1

# 2. Install required dependencies
pip install -r requirements.txt

# 3. Create your .env file and paste your DISCORD_BOT_TOKEN inside
copy .env.example .env
notepad .env

# 4. Launch Foreverbot!
python bot.py
```
</details>

<details>
<summary><b>🔧 Manual Python Virtual Environment Setup (Linux / macOS)</b></summary>

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env   # Paste your DISCORD_BOT_TOKEN inside .env
python3 bot.py
```
</details>

---

### Step 4 — Verify You're Live
When `bot.py` connects, you will see this confirmation in your terminal:
```text
Logged in as Foreverbot (123456789012345678)
Synced 40 global slash commands.
Instantly synced 40 commands to server: Your Guild Server (987654321098765432)
Foreverbot is live and ready!
```
> 💡 **Instant Slash Commands:** Foreverbot automatically pushes guild-level command syncs on startup, so typing **`/`** in your Discord server displays all 40 commands **immediately** (no 1-hour global Discord cache wait!).

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

## 📜 Complete 40-Command Reference

| Category | Commands |
| :--- | :--- |
| **Gear & Items** | `/item`, `/compare`, `/bis`, `/resist` |
| **Quests & Progression** | `/quest`, `/keys`, `/attunement`, `/rep` |
| **World & Travel** | `/flightpath`, `/map`, `/zones`, `/dungeons`, `/level`, `/route` |
| **Economy & Gathering** | `/vendor`, `/gather`, `/profession`, `/farm`, `/mob`, `/rare` |
| **Raiding & Buffs** | `/raid`, `/consumes`, `/buffs`, `/resets` |
| **Class Mastery** | `/build`, `/talents`, `/race`, `/macro`, `/profile` |
| **PvP & Competitive** | `/pvp`, `/twink`, `/duels` |
| **Raid Management** | `/signup`, `/comp`, `/gdkp`, `/roll`, `/addons` |
| **Community & AI** | `/forever`, `/events`, `/trivia`, `/ask` |

---

## 🧪 Automated Testing

Foreverbot is backed by an industry-leading **4,904 / 4,904 automated tests** across 5 verification suites (plus an overnight continuous endurance daemon) ensuring 100% accuracy, instant sub-second response times, and bulletproof resilience against typos, player slang, and hostile inputs:
```bash
python3 tests/test_quality_suite.py               # 27 Core system tests
python3 tests/test_deep_quality.py                # 81 Database & custom dungeon tests
python3 tests/test_howto_guide_suite.py           # 115 How-To guide prompt tests
python3 tests/test_massive_scale_suite.py         # 3,680 Ultra-scale catalog, combat math & edge-case tests
python3 tests/test_slash_commands_authenticity.py # 1,001 Direct Discord '/' slash command authenticity tests
```

### 🔬 What The Verification Suites Cover:
- **Section 1: Full Database Catalog Sweeps (324 tests):** Every item, quest, mob, dungeon, flightpath, and vendor lookup tested with exact matches and multi-word token searches.
- **Section 2: Level 1 to 60 Dungeon Eligibility (60 tests):** Every character level tested against level bracket filtering and starter zone recommendations.
- **Section 3: Combat Mechanics & Mitigation Math (150 tests):** 5-school resistance mitigation across 20 resistance tiers (0 to 360 SR/FR/NR/AR/Frost R) and dual-wield glancing blow comparisons.
- **Section 4: Guild Economy & Raiding (100 tests):** 50 GDKP gold pot splits (organizer cuts & tank bonuses) and 40-man raid comp synergy coverage.
- **Section 5: Class Mastery & 9x9 PvP Matrix (162 tests):** Spec codes, talent trees, and 81 cross-class duel matchups.
- **Section 6: Attunements, Keys & Leveling Routes (104 tests):** All dungeon keys, raid attunements, faction reputations, and speedleveling route sweeps.
- **Section 7: Out-of-the-Box, Slang & Edge Cases (600 tests):** Extreme typos, player shorthand (`"rag"`, `"hoj"`, `"fap"`, `"dft"`, `"sgc"`), natural language prompts, hostile SQL/XSS inputs, and boundary numbers.
- **Section 8: Headless Slash Command Dispatch (50 tests):** Asynchronous Discord command execution verifying complete embed responses without network overhead.
- **Section 9: Database Fuzz & Connectivity Matrix (700 tests):** Uppercase, lowercase, whitespace trims, mob token matching, quest integrity, and 19-city flight network transit routing.
- **Section 10: Weapon Glancing & Boss Hit Matrix (400 tests):** 40 weapon pairings across 10 race permutations verifying glancing penalty mitigation, special attack hit caps (6% vs 9%), and weapon speed damage normalization.
- **Section 11: Honor Ranking & Weekly 20% Decay Matrix (280 tests):** All 14 PvP ranks across 20 rating point intervals validating Tuesday decay retention.
- **Section 12: Class BiS, Talents & Consumables (250 tests):** Pre-raid BiS lists across all 9 classes (including Druid, Paladin, Shaman), 1-60 leveling advice, and consumable checklists.
- **Section 13: 500 Out-of-the-Box Conversational & NLP Queries (500 tests):** "Where do I find...", "Can [class] use...", "How much [stat]...", and gamer LFG chat prompts verified safe and structured.
- **Section 14: 1,001 Direct Slash Command Authenticity Permutations (1,001 tests):** Continuous verification across all Discord `/` slash commands validating `ephemeral=True` channel privacy, interactive Raid/Roll Views, and domain ground truth.

---

## 📄 Official Guide & Release Notes

- **[BLIZZARD_BETA_PATCH_NOTES.md](docs/BLIZZARD_BETA_PATCH_NOTES.md)** — Official Blizzard WoW: Forever Beta Development Notes (Tracked from Blue Tracker Topic #631316 • Updated Oct 26, 2026).
- **[EPIC_EDITION_RELEASE_NOTES.md](docs/EPIC_EDITION_RELEASE_NOTES.md)** — What's new in v3.0.0 Open Beta (Channel Layering, Transit Routing, 4,904 Tests).
- **[Your-Azeroth-Companion-Bot-Command-Guide.pdf](docs/Your-Azeroth-Companion-Bot-Command-Guide.pdf)** — Visual slide guide & command companion deck (Open Beta).

### 🔄 Automated Blizzard Blue Tracker Sync
Foreverbot automatically stays synced with official Blizzard WoW: Forever Beta development builds and pushes updates to GitHub:
```bash
python3 scripts/sync_blizzard_blue_tracker.py --auto-push
```
