# ⚔️ World of Warcraft: Forever — Discord Companion Bot

A high-performance Discord lookup bot and gaming companion built for the launch of **World of Warcraft: Forever** (Classic+).

Query items, quests, mobs, boss loot tables, vendors, and flight paths directly from Discord on your second monitor or mobile device while playing!

---

## 🌟 Key Features

* **Classic Foundation + Forever Classic+ Additions**: Preloaded with classic baseline data plus datamined content for *WoW: Forever* (Mount Hyjal, Zephras Isle, Riverglades, Skyborne Elves, new dungeons, and horizontal level 60 tier gear).
* **Instant Full-Text Search (FTS5)**: Fast local SQLite database queries with zero lag.
* **WoW-Themed Embeds**: Items are color-coded to match in-game quality (Poor, Common, Uncommon, Rare, Epic, Legendary).
* **Slash Commands**:
  * `/item <name>` — Displays item tooltip, stats, required level, and source/drop info.
  * `/quest <title>` — Shows quest objectives, starting NPC & coordinates, rewards, and zone.
  * `/mob <name>` — Displays level, classification (Elite/Boss), zone, location, and notable loot drops with drop percentages.
  * `/vendor <item_name>` — Finds which vendor sells the item, coordinates, and exact gold/silver/copper price.
  * `/flightpath <query>` — Shows flight masters and flight path connections.
  * `/forever` — Summary card of WoW: Forever features, release date (Nov 4), new zones, and dungeons.
  * `/ask <question>` — Natural language question answering. Searches the database and synthesizes a direct answer (with optional Gemini AI integration).

---

## 🚀 Quick Setup Guide

### 1. Create Your Discord Bot in 2 Minutes

1. Go to the [Discord Developer Portal](https://discord.com/developers/applications).
2. Click **New Application**, give it a name (e.g. `WoW Forever Bot`), and click **Create**.
3. Go to the **Bot** tab on the left:
   * Click **Reset Token** (or **Copy**) to get your **Bot Token**. Save this for step 3.
   * Under **Privileged Gateway Intents**, turn on **Message Content Intent**.
4. Go to the **Installation** or **OAuth2 > URL Generator** tab:
   * Select scopes: `bot` and `applications.commands`.
   * Under **Bot Permissions**, select: `Send Messages`, `Embed Links`, `Read Messages/View Channels`.
   * Copy the generated invite link, open it in your browser, and add the bot to your Discord server.

---

### 2. Install Dependencies

Open a terminal in the project directory:

```bash
cd /home/s1l3nt/.gemini/antigravity/scratch/wow-forever-bot
pip install -r requirements.txt
```

---

### 3. Configure Your Environment

Copy `.env.example` to `.env`:

```bash
cp .env.example .env
```

Open `.env` and paste your Discord bot token:

```env
DISCORD_BOT_TOKEN=your_token_here

# (Optional) Add a Gemini API key if you want AI-generated conversational answers for /ask:
GEMINI_API_KEY=
```

---

### 4. Seed the Database

The database comes pre-configured, but you can initialize and re-seed it anytime:

```bash
python3 seed_data.py
```

---

### 5. Run the Bot

Start the bot:

```bash
python3 bot.py
```

Once running, type `/` in any channel on your Discord server where the bot was invited to see the registered slash commands!

---

## 📂 Project Structure

```
wow-forever-bot/
├── bot.py           # Discord bot client with all slash commands & rich embeds
├── database.py      # SQLite database manager with full-text search (FTS5)
├── seed_data.py     # Initial data seed (Classic baseline + WoW Forever additions)
├── ingest_csv.py    # Helper script to bulk import datamined CSVs
├── test_query.py    # Local test script for query verification
├── requirements.txt # Python dependencies
├── .env.example     # Environment variables template
└── wow_forever.db   # Local SQLite database
```

---

## 🔄 Adding More Datamined Data

As the *WoW: Forever* beta updates or when the live servers launch on November 4, you can import new item tables directly:

```bash
python3 ingest_csv.py path/to/datamined_items.csv
```
The CSV should contain headers: `id,name,quality,item_level,req_level,slot,item_type,stats,description,source,is_forever_content`.
