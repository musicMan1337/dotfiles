#!/bin/bash

# Run this before running the script:
#   chmod +x _mac/symlinks.sh

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

  for TARGET in "$SOURCE_DIR"/*; do
    local LINK="$HOME/$(basename "$TARGET")"

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

auto_directory_link "$HOME/dotfiles/hereDocs"
auto_directory_link "$HOME/dotfiles/language-configs"

echo =======================================================================
echo
echo "Symlinks created!"
