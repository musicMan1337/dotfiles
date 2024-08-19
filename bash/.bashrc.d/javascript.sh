#~ ESLint and Prettier (pnpm)
alias prettierLintG='pnpm install -global \
  prettier \
  eslint \
  eslint-plugin-prettier \
  eslint-config-prettier \
  @typescript-eslint/eslint-plugin \
  @typescript-eslint/parser'

alias prettierLint='pnpm install -D \
  prettier \
  eslint \
  eslint-plugin-prettier \
  eslint-config-prettier \
  @typescript-eslint/eslint-plugin \
  @typescript-eslint/parser'

# Use this in a new project to initialize prettier/eslint
prettierLintInit() {
  # check if we're in an npm project (package.json exists)
  if [[ ! -f "package.json" ]]; then
    echo "Not in an npm project. Skipping prettier/eslint init."
    return
  fi

  local DIR=$(pwd)

  # rename existing config files
  if [[ -f "$DIR"/.eslintrc.json ]]; then
    mv "$DIR"/.eslintrc.json "$DIR"/.eslintrc.json.bak
  fi

  if [[ -f "$DIR"/.prettierrc.json ]]; then
    mv "$DIR"/.prettierrc.json "$DIR"/.prettierrc.json.bak
  fi

  # copy new config files
  cp "$HOME"/dotfiles/language-configs/javascript/.eslintrc.json "$DIR"/.eslintrc.json
  cp "$HOME"/dotfiles/language-configs/javascript/.prettierrc.json "$DIR"/.prettierrc.json
}
