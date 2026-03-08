---
description: Opens a repository workspace in VS Code fullscreen
---
# open-repo

The user will provide a repo name (e.g. "dotfiles", "Viper", "ui-dev").

Search for the repo directory in this order:
1. `~` (`/Users/derek`)
2. `~/code` (`/Users/derek/code`)
3. `~/eBacon` (`/Users/derek/eBacon`)

Use the first match found. Then run:

```bash
~/.local/bin/open-repo <full-path>
```

For example, if the user says "dotfiles" and `/Users/derek/dotfiles` exists, run:

```bash
~/.local/bin/open-repo /Users/derek/dotfiles
```

If the repo name was not provided, ask the user "Which repo?" as a plain open-ended question (do not use AskUserQuestion with multiple choice options).

If no matching directory is found in any of the search paths, tell the user.
