#!/usr/bin/env bash
set -euo pipefail

# 公式インストーラー取得に curl が必要なので事前確認する。
if ! command -v curl >/dev/null 2>&1; then
  printf 'curl is required. Run run_once_install-apt-packages.sh first.\n' >&2
  exit 1
fi

# mise が未導入のときだけ公式インストーラーを実行する。
if [[ ! -x "${HOME}/.local/bin/mise" ]] && ! command -v mise >/dev/null 2>&1; then
  curl https://mise.run | sh
fi

# 今のシェルでもすぐ使えるように PATH を通す。
export PATH="${HOME}/.local/bin:${PATH}"

# インストール後も見つからなければ、以降の処理を止める。
if ! command -v mise >/dev/null 2>&1; then
  printf 'mise installation completed but the binary is not on PATH yet.\n' >&2
  exit 1
fi

# 設定ファイルに書かれたランタイムと CLI をまとめて入れる。
mise install