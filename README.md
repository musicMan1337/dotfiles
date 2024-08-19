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

### Node Setup

1. **Install Node.js (fnm):**

   Windows (PowerShell):

   ```bash
   # installs fnm (Fast Node Manager)
   winget install Schniz.fnm

   # configure fnm environment (may need to restart terminal)
   fnm env --use-on-cd | Out-String | Invoke-Expression
   ```

   macOS:

   ```bash
   # installs fnm (Fast Node Manager)
   curl -fsSL https://fnm.vercel.app/install | bash

   # activate fnm
   source ~/.bashrc
   ```

   Both:

   ```bash
   # download and install Node.js (current LTS - this will change!)
   fnm install --lts

   # switch to the LTS version
   fnm use 20 # or whatever version you installed (Node v20.16.0 would be '20')

   # verifies the right Node.js version is in the environment
   node -v

   # verifies the right npm version is in the environment
   npm -v
   ```

2. **Install pnpm:**

   ```bash
   npm install -g pnpm
   ```

3. **Init global JS packages:**

   ```bash
   # installs prettier and eslint globally
   prettierLintG
   ```

### Windows Setup

1. **Set up symbolic links:**

   Run the `symlinks.cmd` script to create necessary symbolic links:

   ```bash
   pnpm run windows_symlinks
   ```

   If `elevate` is not installed, the above command will prompt you to install it:

   ```cmd
   choco install elevate -y
   ```

   ...and then run the the command again.

### macOS Setup

1. **Add permissions to run scripts:**

   ```bash
   chmod +x _mac/symlinks.sh
   ```

2. **Run symlinks script:**

   ```bash
   pnpm run mac_symlinks
   ```

The repo will now have it's files symlinked into your home directory in the proper locations!

---

### Shell Configuration

#### Fonts

1. **Install Powerline/Nerd Fonts:**

   ```bash
   pnpm run install_fonts
   ```

#### ZSH

1. **Install Oh My Zsh:**

   ```bash
   sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
   ```

#### Bash

1. **Install Bash:**

   ```bash
   brew install bash
   ```

### Additional Configuration

#### Editors and IDEs

- **JavaScript:**

  Configuration files for ESLint and Prettier are located under `language-configs/javascript`.
  Copy them to your project directory if needed:

  ```bash
  cp ~/language-configs/javascript/.eslintrc.json .
  cp ~/language-configs/javascript/.prettierrc.json .
  ```

  ...or init them along with their packages:

  ```bash
  prettierLintInit
  ```

- **C#:**

  EditorConfig for C# projects is located under `language-configs/csharp`. Ensure your projects reference these files:

  ```bash
  cp ~/language-configs/csharp/.editorconfig .
  cp ~/language-configs/csharp/global.json .
  cp ~/language-configs/csharp/Directory.Build.props .
  cp ~/language-configs/csharp/Directory.Packages.props .
  cp ~/language-configs/csharp/NuGet.config .
  ```

### Summary

This repository aims to simplify the management of dotfiles across different environments by providing a standardized setup.
Ensure you follow the provided steps to correctly set up your environment whether you are on Windows or macOS.
