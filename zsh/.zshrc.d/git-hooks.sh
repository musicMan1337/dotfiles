# Re-assert the global git hooks; a `lefthook install` in any repo overwrites
# core.hooksPath. Silent unless it actually restores something.
[ -x "$HOME/dotfiles/git/hooks/_integrity.sh" ] && "$HOME/dotfiles/git/hooks/_integrity.sh" repair
