#!/bin/bash

DIR="${1:-}"

if [ -z "$DIR" ]; then
    echo "Usage: open-repo <path>"
    exit 1
fi

# Open VS Code in the specified directory
open -na "Visual Studio Code" --args --new-window "$DIR"

# Fullscreen VS Code as soon as the new window is accessible
for i in $(seq 1 20); do
    osascript -e '
        tell application "System Events"
            tell process "Code"
                set value of attribute "AXFullScreen" of window 1 to true
            end tell
        end tell' 2>/dev/null && break
    sleep 0.1
done

# Open Warp in the specified directory
ENCODED=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$DIR")
open "warp://action/new_window?path=${ENCODED}"

# Activate Warp and fullscreen it as soon as the window is accessible
osascript -e 'tell application "Warp" to activate'
for i in $(seq 1 20); do
    osascript -e '
        tell application "System Events"
            tell process "Warp"
                set value of attribute "AXFullScreen" of window 1 to true
            end tell
        end tell' 2>/dev/null && break
    sleep 0.1
done

# Type "claude" + Enter to launch Claude in Warp
osascript -e '
    tell application "Warp" to activate
    tell application "System Events"
        tell process "Warp"
            keystroke "claude"
            key code 36
        end tell
    end tell'
