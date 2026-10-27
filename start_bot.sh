#!/usr/bin/env bash
# Launcher script for World of Warcraft: Forever Discord Bot
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

echo "=========================================================="
echo "  ⚔️  Starting Foreverbot (WoW: Forever Companion)..."
echo "  📂 Directory: $DIR"
echo "  🛑 Press Ctrl+C at any time to stop the bot."
echo "=========================================================="

# Auto-create virtual environment & install dependencies on first run
if [ ! -x "$DIR/.venv/bin/python3" ]; then
    echo "📦 First-time setup: Creating Python virtual environment (.venv)..."
    python3 -m venv "$DIR/.venv"
    "$DIR/.venv/bin/pip" install --upgrade pip -q
    echo "📥 Installing required packages from requirements.txt..."
    "$DIR/.venv/bin/pip" install -r "$DIR/requirements.txt"
fi

# Verify .env exists
if [ ! -f "$DIR/.env" ]; then
    cp "$DIR/.env.example" "$DIR/.env"
    echo "⚠️  Created .env from .env.example."
    echo "👉 Please open .env, paste your DISCORD_BOT_TOKEN, and run ./start_bot.sh again!"
    exit 1
fi

# Stop any existing bot.py instances so they don't conflict
pkill -f "python3.*bot.py" 2>/dev/null || true

exec "$DIR/.venv/bin/python3" "$DIR/bot.py"
