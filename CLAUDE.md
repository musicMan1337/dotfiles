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
- The repo assumes `~/dotfiles` as the clone location; symlink scripts depend on this path

## Harness Engineering Conventions (`claude/` dir)

Bitter Lesson discipline for every rule, skill, hook, or agent added under `claude/`. Master question first: is this (a) an environment fact the model cannot infer, (b) an authority boundary, or (c) an encoding of how a human thinks the task should be done? Keep (a) and (b) freely. (c) is scaffolding: it must name the model weakness or cost fact it patches, dated, with a re-test trigger, or it doesn't go in.

- Greppable annotation for scaffolding: `(scaffold: patches <weakness or cost fact>; added <YYYY-MM>; retest <trigger>)`. Larger techniques get a "Dated premise" paragraph instead (see `claude/commands/research/orderings.md` for the shape).
- Prefer goals + constraints over step recipes; encode facts, not knowledge the model already has; point at ground truth rather than copying it (copies drift).
- Model tier policy lives in `claude/TIERS.md`, one place only. Enforcement belongs in hooks (subagent-gate, check-hook-wiring), not in emphatic prose.
- After each model upgrade, run `/harness:model-upgrade` to re-test dated scaffolding and delete what the new model has internalized. The harness should shrink as models improve.
