#!/usr/bin/env bash
set -euo pipefail

readonly BW_SECURE_NOTES=(
  'dotfiles: ~/.config/shell/.env.local|~/.config/shell/.env.local|600'
  'dotfiles: ~/.npmrc|~/.npmrc|600'
)

if [[ -n "${CI:-}" || ! -t 0 || ! -t 1 ]]; then
  printf 'Skipping interactive personal setup in non-interactive environment.\n'
  exit 0
fi

export PATH="${HOME}/.local/bin:${PATH}"
if [[ -x "${HOME}/.local/bin/mise" ]]; then
  eval "$("${HOME}/.local/bin/mise" activate bash)"
fi

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf '%s is required but was not found on PATH.\n' "$1" >&2
    exit 1
  fi
}

preferred_browser() {
  if command -v wslview >/dev/null 2>&1; then
    printf 'wslview\n'
    return 0
  fi

  if command -v xdg-open >/dev/null 2>&1; then
    printf 'xdg-open\n'
    return 0
  fi

  return 1
}

prompt_yes_no() {
  local prompt="$1"
  local default_answer="$2"
  local answer=""

  while true; do
    if [[ "${default_answer}" == "Y" ]]; then
      read -r -p "${prompt} [Y/n] " answer
      answer="${answer:-Y}"
    else
      read -r -p "${prompt} [y/N] " answer
      answer="${answer:-N}"
    fi

    case "${answer}" in
      Y|y) return 0 ;;
      N|n) return 1 ;;
    esac
  done
}

ensure_bitwarden_session() {
  local status

  require_command bw
  require_command jq

  status="$(bw status | jq -r '.status')"
  if [[ "${status}" == "unauthenticated" ]]; then
    printf 'Signing in to Bitwarden...\n'
    bw login
  fi

  printf 'Unlocking Bitwarden vault...\n'
  BW_SESSION="$(bw unlock --raw)"
  export BW_SESSION
  bw sync --session "${BW_SESSION}" >/dev/null
}

bitwarden_item_id() {
  local item_name="$1"

  bw list items --search "${item_name}" --session "${BW_SESSION}" \
    | jq -re --arg name "${item_name}" '
        map(select(.name == $name))
        | if length == 1 then .[0].id else empty end
      '
}

materialize_bitwarden_note() {
  local item_name="$1"
  local destination="$2"
  local mode="$3"
  local item_id

  item_id="$(bitwarden_item_id "${item_name}")" || {
    printf 'Bitwarden item "%s" was not found.\n' "${item_name}" >&2
    exit 1
  }

  mkdir -p "$(dirname "${destination}")"
  bw get item "${item_id}" --session "${BW_SESSION}" \
    | jq -er '.notes // empty' > "${destination}"
  chmod "${mode}" "${destination}"
  printf 'Wrote %s from Bitwarden.\n' "${destination}"
}

materialize_bitwarden_secure_notes() {
  local note_spec
  local item_name
  local destination
  local mode

  for note_spec in "${BW_SECURE_NOTES[@]}"; do
    IFS='|' read -r item_name destination mode <<< "${note_spec}"
    materialize_bitwarden_note "${item_name}" "${HOME}/${destination#~/}" "${mode}"
  done
}

validate_env_local() {
  local env_file="${HOME}/.config/shell/.env.local"

  if ! grep -Eq '(^|[[:space:]])CONTEXT7_API_KEY=' "${env_file}"; then
    printf '%s is missing CONTEXT7_API_KEY. Update the Bitwarden secure note and rerun chezmoi apply.\n' "${env_file}" >&2
    exit 1
  fi
}

setup_bitwarden_backed_files() {
  if ! prompt_yes_no 'Fetch Bitwarden-backed files now? (~/.config/shell/.env.local, ~/.npmrc)' 'Y'; then
    printf 'Skipped Bitwarden-backed secret setup.\n'
    return
  fi

  ensure_bitwarden_session
  materialize_bitwarden_secure_notes
  validate_env_local
  bw lock >/dev/null
  unset BW_SESSION
}

setup_github_cli() {
  local browser

  require_command gh

  if gh auth status >/dev/null 2>&1; then
    printf 'GitHub CLI is already authenticated.\n'
    return
  fi

  if prompt_yes_no 'Authenticate GitHub CLI now?' 'Y'; then
    if browser="$(preferred_browser)"; then
      BROWSER="${browser}" gh auth login --git-protocol https --web
    else
      printf 'No browser launcher was found. The login URL will be printed so you can open it in Windows manually.\n'
      BROWSER="echo" gh auth login --git-protocol https --web
    fi
  else
    printf 'Skipped GitHub CLI authentication.\n'
  fi
}

setup_ssh_key() {
  local key_path="${HOME}/.ssh/id_ed25519"
  local key_title

  if [[ -f "${key_path}" ]]; then
    printf 'SSH key already exists at %s\n' "${key_path}"
    return
  fi

  if ! prompt_yes_no 'Create a new SSH key for this machine?' 'Y'; then
    printf 'Skipped SSH key generation.\n'
    return
  fi

  mkdir -p "${HOME}/.ssh"
  chmod 700 "${HOME}/.ssh"
  ssh-keygen -t ed25519 -C "${USER}@$(hostname)" -f "${key_path}" -N ''

  if ! gh auth status >/dev/null 2>&1; then
    printf 'GitHub CLI is not authenticated, so SSH key upload was skipped.\n'
    return
  fi

  if prompt_yes_no 'Upload the new SSH public key to GitHub now?' 'Y'; then
    key_title="$(hostname)-wsl-$(date +%Y%m%d)"
    gh ssh-key add "${key_path}.pub" --title "${key_title}"
  else
    printf 'Skipped GitHub SSH key upload.\n'
  fi
}

setup_bitwarden_backed_files
setup_github_cli
setup_ssh_key

printf 'Interactive personal setup completed. Start a new shell to load fresh environment variables.\n'
