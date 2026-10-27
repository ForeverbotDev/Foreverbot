# ⚔️ Foreverbot // World of Warcraft: Forever Discord Co-Pilot
> The in-game Discord companion for **World of Warcraft: Forever**. Look up item stats, get directions when you're lost, and find answers right from your PC, phone, or tablet.

[![Discord Bot](https://img.shields.io/badge/Discord-Companion%20Bot-5865F2?logo=discord&logoColor=white)](https://discord.com)
[![WoW Forever](https://img.shields.io/badge/WoW-Forever-F59E0B)](https://github.com/s1l3ntHub/wow-foreverbot)
[![Tests Passing](https://img.shields.io/badge/Tests-223%20%2F%20223%20Passed-10B981)](#-automated-testing)

---

## 🚀 Quickstart (How to Download & Run)

### 1. Download the Project
- **Easiest:** Click the green **`<> Code`** button at the top of this page ➔ click **Download ZIP**, then unzip it.
- **Git:** `git clone https://github.com/s1l3ntHub/wow-foreverbot.git`

### 2. Get Your Discord Bot Token
1. Create an application at the [Discord Developer Portal](https://discord.com/developers/applications) and copy your **Bot Token** (under the **Bot** tab).
2. Under **OAuth2 ➔ URL Generator**, check `bot` + `applications.commands`, then open the generated link to invite the bot to your server.

### 3. Run Foreverbot (3 Commands)
Open a terminal in your unzipped bot folder and run:
```bash
# 1. Install required packages
pip install -r requirements.txt

# 2. Add your token
cp .env.example .env          # Open .env in any text editor & paste your DISCORD_TOKEN

# 3. Launch the bot!
python3 bot.py
```
*Once online, just type `/` in any Discord channel to start using commands!*

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

Foreverbot includes 3 verification suites (**223 / 223 automated tests passing**):
```bash
python3 tests/test_quality_suite.py     # 27 Core system tests
python3 tests/test_deep_quality.py      # 81 Database & custom dungeon tests
python3 tests/test_howto_guide_suite.py # 115 How-To guide prompt tests
```

---

## 📄 Official Guide

- **[Your-Azeroth-Companion-Bot-Command-Guide.pdf](docs/Your-Azeroth-Companion-Bot-Command-Guide.pdf)** — Visual slide guide & command companion deck.
