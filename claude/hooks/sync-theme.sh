#!/usr/bin/env bash
# Sync Claude Code theme with macOS appearance at session start.
# Reads AppleInterfaceStyle (set to "Dark" when dark mode is on,
# absent when light mode is on) and updates ~/.claude.json to match.

CONFIG="$HOME/.claude.json"

if [[ ! -f "$CONFIG" ]]; then
  exit 0
fi

if defaults read -g AppleInterfaceStyle &>/dev/null 2>&1; then
  THEME="dark"
else
  THEME="light"
fi

# Only write if the theme actually changed
CURRENT=$(plutil -extract theme raw "$CONFIG" 2>/dev/null)
if [[ "$CURRENT" != "$THEME" ]]; then
  plutil -replace theme -string "$THEME" "$CONFIG"
fi
