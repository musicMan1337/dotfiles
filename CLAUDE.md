# Dotfiles Repository

Personal dotfiles managed by Derek Nellis (musicMan1337) for cross-platform shell environments (macOS and Windows).

## Repo Structure

- `bash/` - Bash config files (`.bashrc`, `.bashrc.d/` with aliases, functions, JS helpers)
- `zsh/` - Zsh config (`.zshrc` with Oh My Zsh + Powerlevel10k, `.zshrc.d/` for sourced scripts)
- `git/` - Global `.gitconfig` (custom aliases like `ac`, `acp`, `cob`, `bdone`, `upbranch`) and `.gitattributes`
- `fonts/` - Powerline/Nerd fonts (FiraCode, DejaVu, DroidSans, etc.) with install script
- `language-configs/` - Per-language editor configs (JavaScript ESLint/Prettier, C# EditorConfig)
- `hereDocs/` - Template files and ASCII art (terminal load messages)
- `_mac/` - macOS symlink setup script
- `_windows/` - Windows symlink setup (PowerShell) and package checks

## How It Works

The repo is cloned to `~/dotfiles`. Symlink scripts (`_mac/symlinks.sh` or `_windows/symlinks.ps1`) create symlinks from `$HOME` pointing into this repo, so config files are version-controlled here but appear in the expected home directory locations.

Key symlinked paths: `bash/*`, `zsh/*`, `git/*`, `hereDocs/`, `language-configs/`.

## Scripts (via pnpm)

- `pnpm run mac_symlinks` - Create macOS symlinks
- `pnpm run windows_symlinks` - Create Windows symlinks (requires `elevate`)
- `pnpm run install_fonts` - Install bundled Powerline/Nerd fonts

## Shell Setup

- **Zsh (macOS primary)**: Oh My Zsh + Powerlevel10k theme, plugins include zsh-autosuggestions, zsh-syntax-highlighting, docker, node, dotnet
- **Bash**: Starship prompt, modular `.bashrc.d/` sourcing (aliases, functions, JS tooling)
- Both shells source `*.sh` files from their respective `.d/` directories for modularity

## Conventions

- Config is split into small sourced files under `.bashrc.d/` and `.zshrc.d/` rather than one monolithic rc file
- Git aliases favor short commands (`ac` = add+commit, `acp` = add+commit+push, `cob` = checkout+branch+push)
- The repo assumes `~/dotfiles` as the clone location — symlink scripts depend on this path
