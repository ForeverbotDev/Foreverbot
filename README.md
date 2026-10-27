# ⚔️ Foreverbot // World of Warcraft: Forever Discord Co-Pilot
> The second-screen companion for **World of Warcraft: Forever**. Never Alt-Tab again.

[![Discord Bot](https://img.shields.io/badge/Discord-Companion%20Bot-5865F2?logo=discord&logoColor=white)](https://discord.com)
[![WoW Forever](https://img.shields.io/badge/WoW-Forever-F59E0B)](https://github.com/s1l3ntHub/wow-foreverbot)
[![Tests Passing](https://img.shields.io/badge/Tests-223%20%2F%20223%20Passed-10B981)](#-automated-testing)

---

## 🚀 How to Install & Add to Discord

### Step 1: Create & Invite the Bot
1. Open the [Discord Developer Portal](https://discord.com/developers/applications) and click **New Application**.
2. Go to the **Bot** tab:
   - Click **Reset Token** (or **Copy**) to save your **Bot Token**.
   - Under **Privileged Gateway Intents**, enable **Message Content Intent**.
3. Go to the **OAuth2 > URL Generator** tab:
   - Select scopes: `bot` and `applications.commands`.
   - Select bot permissions: `Send Messages`, `Embed Links`, `Attach Files`, `Use Slash Commands`.
   - Copy the generated URL and open it in your browser to add the bot to your Discord server.

### Step 2: Install & Launch
```bash
# 1. Clone repository
git clone git@github.com:s1l3ntHub/wow-foreverbot.git
cd wow-foreverbot

# 2. Install dependencies
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# 3. Add your Bot Token to .env
cp .env.example .env
# Edit .env and paste: DISCORD_TOKEN=your_token_here

# 4. Start Foreverbot
python3 bot.py
```

### Step 3: Use Commands in Discord
Once the bot is online, simply press `/` in any channel to browse and use any command.

---

## 💡 Quick Command Cheat Sheet (Top Categories)

### 🗡️ Gear & Items
- `/item query: dal rend` — View stats, drop rates, and boss loot tables.
- `/compare query: brutality blade weapon2: deathbringer` — Side-by-side stat delta & glancing blow math.
- `/bis query: rogue spec: swords` — Slot-by-slot Pre-Raid and Phase BiS checklist.
- `/resist query: fire current: 150` — Mitigation tiers and points to reach the 315 cap.

### 🗺️ World Navigation & Dungeons
- `/dungeons query: 42` — Eligible dungeons for your level bracket, wing levels, and entrances.
- `/flightpath query: stv` — Nearest flight masters, map coordinates, and routes.
- `/zones query: duskwood` — Zone level brackets, faction hubs, and danger notes.
- `/mob query: garr` — Boss HP pools, spawn locations, abilities, and loot percentages.

### 🛡️ Raiding, Consumables & PvP
- `/raid query: baron geddon` — Boss wipe prevention, positioning diagrams, and dispel alerts.
- `/consumes query: fury warrior` — Mandatory flasks, elixirs, and buff food checklists.
- `/buffs query: ony head` — World buff turn-in locations, cooldowns, and raid stat increases.
- `/resets query: onyxia` — Live countdowns to weekly, 5-day (Onyxia), and 3-day (ZG) resets.
- `/pvp query: rank 14` — Honor rank math, weekly 20% decay, and battleground guides.

### 🎲 Raid Leader Tools & Macros
- `/signup query: MC Sunday 7pm max_players: 40` — Interactive raid roster with Tank/Healer/DPS buttons.
- `/roll query: Reins of the Deathcharger seconds: 30` — Raid loot roll engine with live countdown timer.
- `/gdkp query: 60000 cut: 10 raiders: 40` — Automatic pot splitter, organizer cut, and raider payout.
- `/macro query: stance dance overpower` — Ready-to-use copy-pasteable in-game macros.
- `/ask query: what are the best pre-raid swords?` — Plain English AI assistant for any WoW question.

---

## 📜 Complete 42-Command Reference

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
| **Voice & Community** | `/forever`, `/sound`, `/ambience`, `/events`, `/trivia`, `/ask` |

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
