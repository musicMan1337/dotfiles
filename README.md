# Dotfiles Repository

This repository manages dotfiles for both Windows and macOS environments. The dotfiles included span configuration for shell environments (ZSH, Bash), Git, language-specific settings (JavaScript, C#), and more. Below, you'll find a guide on installing and setting up this repository on your machine.

## Structure

- `bash/`: Contains Bash-specific configuration files.
- `zsh/`: Contains ZSH-specific configuration files.
- `git/`: Contains Git configuration files.
- `hereDocs/`: Contains template files for various utilities.
- `language-configs/`: Contains settings/config files for different languages.
- `_windows/`: Contains scripts and configurations specific to Windows.
- `_mac/`: Contains scripts and configurations specific to macOS.

## Setup Guide

### Installation

1. **Clone the repository:**

  You MUST clone into your home/dotfiles directory!

   ```bash
   git clone <repository-url> ~/dotfiles
   ```

2. **Navigate to the repository:**

   ```bash
   cd ~/dotfiles
   ```

### Windows Setup

1. **Set up symbolic links:**

   Run the `symlinks.cmd` script to create necessary symbolic links:

   ```bash
   npm run windows_symlinks
   ```

2. **Elevate permissions for package handling:**

   If `elevate` is not installed, the above command will prompt you to install it:

   ```cmd
   choco install elevate -y
   ```

   ...and then run the above command from step 1 again.

### macOS Setup

1. **Add permissions to run scripts:**

   ```bash
   chmod +x _mac/symlinks.sh
   ```

2. **Run symlinks script:**

   ```bash
   npm run mac_symlinks
   ```

---

The repo will now have it's files symlinked into your home directory in the proper locations!

---

### Shell Configuration

#### ZSH

1. **Install Oh My Zsh:**

   ```bash
   sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
   ```

2. **Install Powerline Fonts:**

   ```bash
  # clone
  git clone https://github.com/powerline/fonts.git --depth=1
  # install
  cd fonts
  ./install.sh
  # clean-up a bit
  cd ..
  rm -rf fonts
   ```

3. **Source the ZSH configuration:**

   ```bash
   source ~/.zshrc
   ```

#### Bash

1. **Copy Bash configurations:**

   ```bash
   cp ~/dotfiles/bash/.bashrc ~/.bashrc
   cp -r ~/dotfiles/bash/.bashrc.d ~/.bashrc.d
   ```

2. **Source the Bash configuration:**

   ```bash
   source ~/.bashrc
   ```

### Additional Configuration

#### Git

1. **Copy Git configurations:**

   ```bash
   cp ~/dotfiles/git/.gitconfig ~/.gitconfig
   cp ~/dotfiles/git/.gitattributes ~/.gitattributes
   ```

#### Editors and IDEs

- **JavaScript:**

  Configuration files for ESLint and Prettier are located under `language-configs/javascript`. Copy them to your project directory if needed:

  ```bash
  cp ~/dotfiles/language-configs/javascript/.eslintrc.json .
  cp ~/dotfiles/language-configs/javascript/.prettierrc.json .
  ```

- **C#:**

  EditorConfig for C# projects is located under `language-configs/csharp`. Ensure your projects reference these files:

  ```bash
  cp ~/dotfiles/language-configs/csharp/.editorconfig .
  cp ~/dotfiles/language-configs/csharp/Directory.Build.props .
  cp ~/dotfiles/language-configs/csharp/Directory.Packages.props .
  cp ~/dotfiles/language-configs/csharp/global.json .
  cp ~/dotfiles/language-configs/csharp/NuGet.config .
  ```

### Summary

This repository aims to simplify the management of dotfiles across different environments by providing a standardized setup. Ensure you follow the provided steps to correctly set up your environment whether you are on Windows or macOS.
