# dotfiles

WSL 向けの dotfiles。chezmoi で管理しています。

## クイックスタート

このセットアップは chezmoi の run scripts により、apt パッケージのインストール、zsh への shell 変更、
mise によるツール導入、GitHub CLI 認証確認を行います。

事前に差分を確認する場合は、以下を使ってください。

```bash
chezmoi init https://github.com/tetsuya-dev-jp/dotfiles.git
chezmoi diff
chezmoi apply
```

## インストールされるもの

### apt パッケージ

| パッケージ | 用途 |
|---|---|
| zsh | デフォルトシェル |
| git | バージョン管理 |
| curl | ダウンロード・API 呼び出し |
| wslu | WSL と Windows の連携（ブラウザ起動等） |
| xdg-utils | `xdg-open` によるブラウザ・ファイル関連付け |
| build-essential, cmake, make | C/C++ ビルドツールチェーン |
| ca-certificates | SSL 証明書 |
| ffmpeg | 動画・音声処理 |
| imagemagick | 画像処理 |
| lsof | ポート調査（`kill-port` で使用） |
| net-tools | ネットワークユーティリティ |
| openssh-client | SSH |
| poppler-utils | PDF 処理 |
| docker.io | Docker エンジン |
| docker-compose-v2 | Docker Compose プラグイン |
| unzip, 7zip | アーカイブ |

### mise で管理するツール

| ツール | 用途 |
|---|---|
| node (LTS) | JavaScript ランタイム |
| bun | JavaScript ランタイム・パッケージマネージャ |
| python (3.13) | Python ランタイム |
| rust | Rust ツールチェーン |
| uv | Python パッケージ管理 |
| starship | プロンプト |
| gh | GitHub CLI |
| bat | `cat` 代替 |
| fd | `find` 代替 |
| jq | JSON プロセッサー |
| ripgrep | `grep` 代替 |
| eza | `ls` 代替 |
| opencode | AI コーディングエージェント |
| claude | Claude Code CLI |
| codex | Codex CLI |
| yq | YAML/JSON/XML プロセッサー |

### 対話セットアップで生成されるもの

| ファイル | 内容 |
|---|---|
| `~/.config/gh/hosts.yml` | GitHub CLI 認証情報 |

## セットアップの流れ

```
1. apt インストール + zsh をデフォルトシェルに変更
2. mise インストール + ツール一覧を導入（設定変更で再実行される）
3. 対話セットアップ（GitHub 認証）
```

各ステップは `run_once_10-`、`run_onchange_after_20-`、`run_once_30-` の順で実行されます。
`mise` の設定ファイル（`config.toml` / `mise.lock`）を変更すると `run_onchange_after_20-` が再実行されます。

## コマンド

```bash
chezmoi diff       # 差分確認
chezmoi add ~/.zshrc  # ファイル更新をソースに反映
chezmoi apply      # ソースの変更をホームに適用
```
