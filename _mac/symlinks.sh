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
  ##########
  ## Bash ##
  ##########
  local LINK="$HOME/.bashrc"
  local TARGET="$HOME/dotfiles/bash/.bashrc"
  check_and_create_link "$LINK" "$TARGET"

  local LINK="$HOME/.bashrc.d"
  local TARGET="$HOME/dotfiles/bash/.bashrc.d"
  check_and_create_directory_link "$LINK" "$TARGET"

  local LINK="$HOME/.config"
  local TARGET="$HOME/dotfiles/bash/.config"
  check_and_create_directory_link "$LINK" "$TARGET"

  #########
  ## Git ##
  #########
  local LINK="$HOME/.gitconfig"
  local TARGET="$HOME/dotfiles/git/.gitconfig"
  check_and_create_link "$LINK" "$TARGET"

  local LINK="$HOME/.gitattributes"
  local TARGET="$HOME/dotfiles/git/.gitattributes"
  check_and_create_link "$LINK" "$TARGET"

  ###############
  ## Languages ##
  ###############
  local LINK="$HOME/language-configs"
  local TARGET="$HOME/dotfiles/language-configs"
  check_and_create_directory_link "$LINK" "$TARGET"

  ##########
  ## Misc ##
  ##########
  local LINK="$HOME/hereDocs"
  local TARGET="$HOME/dotfiles/hereDocs"
  check_and_create_directory_link "$LINK" "$TARGET"
}

create_links

echo =======================================================================
echo
echo "Symlinks created!"
