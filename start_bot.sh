#!/usr/bin/env bash
# Launcher script for World of Warcraft: Forever Discord Bot
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

# 1. If launched from a graphical file manager (double-click without interactive TTY),
# automatically spawn a native terminal window (Konsole, GNOME Terminal, etc.)
if [ -z "$FOREVERBOT_TERMINAL_SPAWNED" ]; then
    if [ ! -t 0 ] || [ ! -t 1 ]; then
        for TERM_BIN in konsole gnome-terminal ptyxis xfce4-terminal x-terminal-emulator alacritty kitty foot wezterm xterm; do
            if command -v "$TERM_BIN" >/dev/null 2>&1; then
                if [ "$TERM_BIN" = "konsole" ]; then
                    exec konsole --workdir "$DIR" -e env FOREVERBOT_TERMINAL_SPAWNED=1 bash "$0" "$@"
                elif [ "$TERM_BIN" = "gnome-terminal" ]; then
                    exec gnome-terminal --working-directory="$DIR" -- env FOREVERBOT_TERMINAL_SPAWNED=1 bash "$0" "$@"
                elif [ "$TERM_BIN" = "ptyxis" ]; then
                    exec ptyxis --working-directory="$DIR" -- env FOREVERBOT_TERMINAL_SPAWNED=1 bash "$0" "$@"
                elif [ "$TERM_BIN" = "xfce4-terminal" ]; then
                    exec xfce4-terminal --working-directory="$DIR" -e "env FOREVERBOT_TERMINAL_SPAWNED=1 bash '$0' $*"
                else
                    exec "$TERM_BIN" -e bash -c "cd '$DIR' && env FOREVERBOT_TERMINAL_SPAWNED=1 bash '$0' '$*'"
                fi
            fi
        done
    fi
fi

# Pause helper when running in a graphical terminal so window doesn't instantly close on exit
cleanup_pause() {
    EXIT_CODE=$?
    if [ -n "$FOREVERBOT_TERMINAL_SPAWNED" ] && [ "$EXIT_CODE" -ne 0 ]; then
        echo ""
        echo "🛑 Foreverbot stopped. Press [Enter] to close this window..."
        read -r || true
    fi
}
trap cleanup_pause EXIT

echo "=========================================================="
echo "  ⚔️  Starting Foreverbot (WoW: Forever Companion)..."
echo "  📂 Directory: $DIR"
echo "  🛑 Press Ctrl+C at any time to stop the bot."
echo "=========================================================="

# 2. Check Python installation
if ! command -v python3 >/dev/null 2>&1; then
    if command -v python >/dev/null 2>&1; then
        PY="python"
    else
        echo "❌ Python 3 was not found on your system."
        echo "👉 Install Python 3 using your distribution's package manager:"
        echo "   • Ubuntu / Debian / Mint / Pop!_OS:  sudo apt update && sudo apt install -y python3 python3-venv python3-pip"
        echo "   • Fedora / RHEL / Rocky / Alma:      sudo dnf install -y python3 python3-pip"
        echo "   • Arch Linux / Manjaro:              sudo pacman -S --needed python python-pip"
        echo "   • openSUSE (Tumbleweed / Leap):      sudo zypper install -y python3 python3-pip"
        echo "   • macOS (Homebrew):                  brew install python"
        exit 1
    fi
else
    PY="python3"
fi

# 3. Auto-create virtual environment & install dependencies on first run
if [ ! -x "$DIR/.venv/bin/python3" ]; then
    echo "📦 First-time setup: Creating Python virtual environment (.venv)..."

    # Compatibility check for venv & ensurepip (Debian/Ubuntu/Mint/Pop!_OS require python3-venv)
    if ! "$PY" -c "import venv, ensurepip" >/dev/null 2>&1; then
        echo ""
        echo "❌ Python virtual environment module ('venv') or 'ensurepip' is missing."
        echo "👉 Run the one-line install command for your distribution:"
        echo ""
        echo "   • Ubuntu / Debian / Mint / Pop!_OS:  sudo apt update && sudo apt install -y python3 python3-venv python3-pip"
        echo "   • Fedora / RHEL / Rocky / Alma:      sudo dnf install -y python3 python3-pip"
        echo "   • Arch Linux / Manjaro:              sudo pacman -S --needed python python-pip"
        echo "   • openSUSE (Tumbleweed / Leap):      sudo zypper install -y python3 python3-pip"
        echo "   • Alpine Linux:                      sudo apk add --no-cache python3 py3-pip"
        echo ""
        exit 1
    fi

    "$PY" -m venv "$DIR/.venv"
    "$DIR/.venv/bin/pip" install --upgrade pip -q
    echo "📥 Installing required packages from requirements.txt..."
    "$DIR/.venv/bin/pip" install -r "$DIR/requirements.txt"
fi

# 4. Verify .env exists and has token configured
if [ ! -f "$DIR/.env" ]; then
    cp "$DIR/.env.example" "$DIR/.env"
    echo ""
    echo "=========================================================="
    echo "⚠️  Created .env file from .env.example!"
    echo "👉 Opening .env in your text editor..."
    echo "👉 Paste your DISCORD_BOT_TOKEN next to DISCORD_BOT_TOKEN= and save!"
    echo "👉 Then run start_bot.sh again to launch."
    echo "=========================================================="
    echo ""
    (xdg-open "$DIR/.env" 2>/dev/null || open "$DIR/.env" 2>/dev/null || kate "$DIR/.env" 2>/dev/null || gedit "$DIR/.env" 2>/dev/null || true) &
    if [ -n "$FOREVERBOT_TERMINAL_SPAWNED" ]; then
        echo "Press [Enter] to exit..."
        read -r || true
    fi
    exit 0
fi

# Check if token is still placeholder
if grep -q "YOUR_DISCORD_BOT_TOKEN_HERE" "$DIR/.env" || ! grep -q "DISCORD_BOT_TOKEN=." "$DIR/.env"; then
    echo ""
    echo "=========================================================="
    echo "⚠️  DISCORD_BOT_TOKEN is still not configured in .env!"
    echo "👉 Opening .env in your text editor..."
    echo "👉 Paste your Discord bot token next to DISCORD_BOT_TOKEN= and save."
    echo "👉 Get a free bot token at: https://discord.com/developers/applications"
    echo "=========================================================="
    echo ""
    (xdg-open "$DIR/.env" 2>/dev/null || open "$DIR/.env" 2>/dev/null || kate "$DIR/.env" 2>/dev/null || gedit "$DIR/.env" 2>/dev/null || true) &
    if [ -n "$FOREVERBOT_TERMINAL_SPAWNED" ]; then
        echo "Press [Enter] to exit..."
        read -r || true
    fi
    exit 1
fi

# 5. Stop any conflicting local bot.py instances
pkill -f "python3.*bot.py" 2>/dev/null || true

# 6. Launch Foreverbot
exec "$DIR/.venv/bin/python3" "$DIR/bot.py"
