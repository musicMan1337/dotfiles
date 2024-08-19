# The intended use of these functions is to be called from a git alias in .gitconfig

# Lists local branches starting with a specified term (default "Derek/")
function git_b() {
  local term="$1"

  if [[ "$term" == "" ]]; then
    term="Derek/"
  fi

  git branch | grep Derek/
}

# Create a new branch and push it to origin
function git_cob() {
  if [[ "$1" == "" ]]; then
    echo "Usage: git_cob <branch name>"
    return
  fi

  git checkout -b "$1"
  git push -u origin "$1"
}

# Add and commit
function git_ac() {
  if [[ "$1" == "" ]]; then
    echo "Usage: git ac '<commit message>'"
    return
  fi

  git add -A
  git commit -m "$1"
}

# Add, commit, and push
function git_acp() {
  if [[ "$1" == "" ]]; then
    echo "Usage: git acp '<commit message>'"
    return
  fi

  git_ac "$1"
  git push
}

# Merges a specified branch (default "master") into the current branch
function git_upbranch() {
  local branch="$1"

  if [[ "$branch" == "" ]]; then
    branch = "master"
  fi

  git checkout "$branch"
  git pull
  git checkout -
  git merge "$branch"
}

# General local repo cleanup
# Checkout and pull a specified branch (default "master") and delete merged branches
function git_bdone() {
  local branch="$1"

  if [[ "$branch" == "" ]]; then
    branch = "master"
  fi

  git checkout "$branch"
  git pull -p
  git branch -vv | grep ': gone]' | grep -v '\*' | awk '{ print $1; }' | xargs -r git branch -d
}
