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

# Stop any existing bot.py instances so they don't conflict
pkill -f "python3 bot.py" 2>/dev/null || true

exec "$DIR/.venv/bin/python3" "$DIR/bot.py"
