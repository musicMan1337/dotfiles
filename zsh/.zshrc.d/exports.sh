# fnm
eval "$(fnm env)"

# pnpm
export PNPM_HOME="/Users/derek/Library/pnpm"
case ":$PATH:" in
*":$PNPM_HOME:"*) ;;
*) export PATH="$PNPM_HOME:$PATH" ;;
esac

# php overrides
export PATH="/opt/homebrew/opt/php@7.2/bin:$PATH"
export PATH="/opt/homebrew/opt/php@7.2/sbin:$PATH"
export LDFLAGS="-L/opt/homebrew/opt/php@7.2/lib"
export CPPFLAGS="-I/opt/homebrew/opt/php@7.2/include"
