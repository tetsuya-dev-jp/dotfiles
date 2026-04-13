export EDITOR=nvim
export VISUAL=nvim

export OPENCODE_DISABLE_CLAUDE_CODE=1
export OPENCODE_ENABLE_EXA=1

if command -v wslview >/dev/null 2>&1; then
  export BROWSER=wslview
elif command -v xdg-open >/dev/null 2>&1; then
  export BROWSER=xdg-open
fi

[[ -f "$HOME/.config/shell/.env.local" ]] && source "$HOME/.config/shell/.env.local"
