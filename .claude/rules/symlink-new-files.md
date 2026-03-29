---
globs:
  - "bash/**"
  - "zsh/**"
  - "git/**"
  - "language-configs/**"
  - "hereDocs/**"
  - "ghostty/**"
  - "claude/**"
---

When creating a new file in any of these directories that would need to be symlinked to the home directory (following the patterns in `_mac/symlinks.sh` or `_windows/symlinks.ps1`), always ask the user if they want to create the symlink manually right now. Provide the exact symlink command they would need to run.
