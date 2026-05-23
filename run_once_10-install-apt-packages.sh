#!/usr/bin/env bash
set -euo pipefail

# ツール個別のセットアップ前に必要な基本パッケージを入れる。
packages=(
  build-essential
  ca-certificates
  cmake
  curl
  docker.io
  docker-compose-v2
  ffmpeg
  git
  imagemagick
  lsof
  make
  net-tools
  openssh-client
  poppler-utils
  unzip
  wslu
  xdg-utils
  zsh
  7zip
)

# デフォルトシェルを変更する対象ユーザーを決める。
target_user="${SUDO_USER:-${USER:-$(id -un)}}"
zsh_path="/usr/bin/zsh"

# apt と chsh に sudo が必要なので、使えない場合はここで止める。
if ! command -v sudo >/dev/null 2>&1; then
  printf 'sudo is required but was not found.\n' >&2
  exit 1
fi

# パッケージがすべて既に入っていればスキップする。
needed=()
for pkg in "${packages[@]}"; do
  if ! dpkg -s "${pkg}" >/dev/null 2>&1; then
    needed+=("${pkg}")
  fi
done

if [[ ${#needed[@]} -gt 0 ]]; then
  # apt のパッケージ情報を更新して、必要な一覧をまとめて入れる。
  sudo apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${needed[@]}"
else
  printf 'All apt packages are already installed.\n'
fi

# chsh で使う zsh の実体が想定パスにあることを確認する。
if [[ ! -x "${zsh_path}" ]]; then
  printf 'zsh was installed but not found at %s\n' "${zsh_path}" >&2
  exit 1
fi

# 必要な場合だけ、ログイン時のデフォルトシェルを zsh に切り替える。
if [[ "${target_user}" != "root" ]]; then
  current_shell="$(getent passwd "${target_user}" | cut -d: -f7)"
  if [[ "${current_shell}" != "${zsh_path}" ]]; then
    sudo chsh -s "${zsh_path}" "${target_user}"
    printf 'Changed default shell to zsh for %s\n' "${target_user}"
  else
    printf 'Default shell is already zsh for %s\n' "${target_user}"
  fi
fi
