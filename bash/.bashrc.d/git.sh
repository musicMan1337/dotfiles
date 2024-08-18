function squashsavepoints() {
  count=$(git branch -r | grep -c '^ *origin/squash!')

  if [ $count -gt 0 ]; then
    echo "Squashing savepoints..."
    r_count=$(git rev-list --count --grep='squash!' HEAD)
    git rebase -i --autosquash HEAD~$r_count

    while git status | grep -q "rebase in progress"; do
      echo "Waiting for rebase to finish..."
      sleep 1
    done

    squashsavepoints
  else
    echo "No savepoints to squash."
  fi
}
