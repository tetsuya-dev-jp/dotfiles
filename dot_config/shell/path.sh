path_prepend() {
  case ":${PATH}:" in
    *":$1:"*) ;;
    *) PATH="$1${PATH:+:${PATH}}" ;;
  esac
}

export BUN_INSTALL="$HOME/.bun"

path_prepend "$HOME/.opencode/bin"
path_prepend "$BUN_INSTALL/bin"
path_prepend "$HOME/.local/bin"

export PATH
