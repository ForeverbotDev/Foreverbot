#!/usr/bin/env bash
# 1-Click Launch Wrapper for macOS (Double-clickable in Finder)
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"
exec bash "$DIR/start_bot.sh" "$@"
