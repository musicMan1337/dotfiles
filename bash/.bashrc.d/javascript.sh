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

prettierLintInit() {
  # check if dir was passed in
  local DIR="$1"
  if [[ "$DIR" == "" ]]; then
    DIR=$(pwd)
  fi

  # check .eslintrc.json
  if [[ ! -f "$DIR"/.eslintrc.json ]]; then
    cp "$HOME"/dotfiles/language-configs/javascript/.eslintrc.json "$DIR"/.eslintrc.json
  fi

  # check .prettierrc.json
  if [[ ! -f "$DIR"/.prettierrc.json ]]; then
    cp "$HOME"/dotfiles/language-configs/javascript/.prettierrc.json "$DIR"/.prettierrc.json
  fi
}
