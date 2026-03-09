---
model: haiku
description: Opens a repository workspace in VS Code fullscreen
---
# open-repo

The user will provide a repo name (e.g. "dotfiles", "Viper", "ui-dev").

If the repo name was not provided, ask the user "Which repo?" as a plain open-ended question (do not use AskUserQuestion with multiple choice options).

## Detect OS

Run the following to detect the OS:

```bash
uname -r
```

- If the output contains `microsoft` or `WSL` (case-insensitive) → **WSL**
- Otherwise if `uname -s` returns `Darwin` → **macOS**
- Otherwise → **Windows**

## Find the repo

Search for the repo directory in this order:
1. `~`
2. `~/code`
3. `~/eBacon`

Use the first match found. If no matching directory is found in any of the search paths, tell the user.

## Run the script

Based on the detected OS, run the corresponding script:

| OS    | Script                                  |
|-------|-----------------------------------------|
| macOS | `~/.claude/scripts/open-repo-mac.sh`   |
| WSL   | `~/.claude/scripts/open-repo-wsl.sh`   |
| Windows | `~/.claude/scripts/open-repo-windows.ps1` |

Pass the full resolved path as the only argument. For example, if the repo resolves to `~/dotfiles` on macOS:

```bash
~/.claude/scripts/open-repo-mac.sh /Users/derek/dotfiles
```

If the OS-specific script does not exist, tell the user it hasn't been implemented yet for their platform.
