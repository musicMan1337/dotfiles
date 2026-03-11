#!/bin/bash

# Run this before running the script:
#   chmod +x _mac/symlinks.sh

# Note: ln -s expects the arg order to be "target" (existing file/dir) then "link" (new file/dir)

###############
## Functions ##
###############
function check_and_create_directory_link() {
  check_and_create_link "$1" "$2" true
}

function check_and_create_link() {
  local LINK="$1"
  local TARGET="$2"
  local IS_DIR="$3"

  if [ -z "$LINK" ]; then
    echo "Link is missing!"
    exit 1
  fi

  if [ -z "$TARGET" ]; then
    echo "Target is missing!"
    exit 1
  fi

  if [ -L "$LINK" ] && [ "$(readlink "$LINK")" == "$TARGET" ]; then
    # The link already exists and points to the correct target
    if [ "$IS_DIR" == "true" ]; then
      echo "Linked directory already exists:"
    else
      echo "Linked file already exists:"
    fi

    echo "    $LINK <==> $TARGET"
  else
    # Remove the existing link or file/directory
    if [ -e "$LINK" ] || [ -L "$LINK" ]; then
      echo "Deleting $LINK"
      rm -rf "$LINK"
    fi

    # Create the new symlink
    echo "Creating new symlink..."
    ln -s "$TARGET" "$LINK"
  fi

  echo ""
}

function create_links() {
  local SOURCE_DIR="$1"

  # Enable globbing
  shopt -s nullglob dotglob
  for TARGET in $SOURCE_DIR/*; do
    # Ensure target is not "*"
    local BASENAME=$(basename "$TARGET")
    local LINK="$HOME/$BASENAME" # Add a dot prefix to the link name

    echo "Creating link for $BASENAME..."

    if [ -d "$TARGET" ]; then
      check_and_create_directory_link "$LINK" "$TARGET"
    elif [ -f "$TARGET" ]; then
      check_and_create_link "$LINK" "$TARGET"
    fi
  done
}

function auto_directory_link() {
  local TARGET="$1"
  local LINK="${TARGET#*$HOME/dotfiles}"
  LINK="$HOME$LINK"

  check_and_create_directory_link "$LINK" "$TARGET"
}

function auto_link() {
  local TARGET="$1"
  local LINK="${TARGET#*$HOME/dotfiles}"
  LINK="$HOME$LINK"

  check_and_create_link "$LINK" "$TARGET"
}

###############
## Run Links ##
###############
create_links "$HOME/dotfiles/bash"
create_links "$HOME/dotfiles/zsh"
create_links "$HOME/dotfiles/git"

check_and_create_link "$HOME/.eslintrc.json" "$HOME/dotfiles/language-configs/javascript/.eslintrc.json"

auto_directory_link "$HOME/dotfiles/hereDocs"
auto_directory_link "$HOME/dotfiles/language-configs"

[ ! -d "$HOME/.config/ghostty" ] && mkdir -p "$HOME/.config/ghostty"
check_and_create_link "$HOME/.config/ghostty/config" "$HOME/dotfiles/ghostty/config"

check_and_create_link "$HOME/.claude/settings.json" "$HOME/dotfiles/claude/settings.json"

[ ! -d "$HOME/.claude/scripts" ] && mkdir "$HOME/.claude/scripts"
shopt -s nullglob
for TARGET in "$HOME/dotfiles/claude/scripts"/*; do
  BASENAME=$(basename "$TARGET")
  check_and_create_link "$HOME/.claude/scripts/$BASENAME" "$TARGET"
done

[ ! -d "$HOME/.claude/hooks" ] && mkdir "$HOME/.claude/hooks"
shopt -s nullglob
for TARGET in "$HOME/dotfiles/claude/hooks"/*; do
  BASENAME=$(basename "$TARGET")
  check_and_create_link "$HOME/.claude/hooks/$BASENAME" "$TARGET"
done

[ ! -d "$HOME/.claude/commands" ] && mkdir "$HOME/.claude/commands"
shopt -s nullglob
for TARGET in "$HOME/dotfiles/claude/commands"/*; do
  BASENAME=$(basename "$TARGET")
  check_and_create_link "$HOME/.claude/commands/$BASENAME" "$TARGET"
done

echo =======================================================================
echo
echo "Symlinks created!"
