#~ ESLint and Prettier (pnpm)
alias prettierLintG='pnpm install -global \
  prettier \
  eslint \
  eslint-plugin-prettier \
  eslint-config-prettier \
  @typescript-eslint/eslint-plugin \
  @typescript-eslint/parser'

alias prettierLint='pnpm install -global \
  prettier \
  eslint \
  eslint-plugin-prettier \
  eslint-config-prettier \
  @typescript-eslint/eslint-plugin \
  @typescript-eslint/parser'

prettierLintInit() {
  # check is dir was passed in
  local DIR="$1"
  if [[ "$DIR" == "" ]]; then
    DIR=$(pwd)
  fi

  touch "$DIR"/.eslintrc.json
  touch "$DIR"/.prettierrc

  echo '{' >"$DIR"/.eslintrc.json
  echo '  "extends": [' >>"$DIR"/.eslintrc.json
  echo '    "eslint:recommended",' >>"$DIR"/.eslintrc.json
  echo '    "plugin:@typescript-eslint/recommended",' >>"$DIR"/.eslintrc.json
  echo '    "plugin:prettier/recommended"' >>"$DIR"/.eslintrc.json
  echo '  ],' >>"$DIR"/.eslintrc.json
  echo '  "parser": "@typescript-eslint/parser",' >>"$DIR"/.eslintrc.json
  echo '  "plugins": ["@typescript-eslint"],' >>"$DIR"/.eslintrc.json
  echo '  "rules": {' >>"$DIR"/.eslintrc.json
  echo '    "prettier/prettier": "error"' >>"$DIR"/.eslintrc.json
  echo '  }' >>"$DIR"/.eslintrc.json
  echo '}' >>"$DIR"/.eslintrc.json

  echo '{' >"$DIR"/.prettierrc
  echo '  "printWidth": 80,' >>"$DIR"/.prettierrc
  echo '  "tabWidth": 2,' >>"$DIR"/.prettierrc
  echo '  "semi": true,' >>"$DIR"/.prettierrc
  echo '  "singleQuote": true,' >>"$DIR"/.prettierrc
  echo '  "trailingComma": "all",' >>"$DIR"/.prettierrc
  echo '  "bracketSpacing": true,' >>"$DIR"/.prettierrc
  echo '  "arrowParens": "always"' >>"$DIR"/.prettierrc
  echo '}' >>"$DIR"/.prettierrc
}
