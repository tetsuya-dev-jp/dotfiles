# tetsuya.dev dotfiles

WSL 向けの dotfiles。chezmoi + Bitwarden で管理しています。

## クイックスタート

```bash
sh -c "$(curl -fsSL https://get.chezmoi.io/lb)" -- init --apply https://github.com/tetsuya-dev-jp/dotfiles.git
```

### 前提

Bitwarden に以下の secure note を作成しておきます。

| アイテム名 | 内容 |
|---|---|
| `dotfiles: ~/.config/shell/.env.local` | 環境変数ファイル（`CONTEXT7_API_KEY` など） |
| `dotfiles: ~/.npmrc` | npm 設定（レジストリ認証など） |

note の本文にファイルの中身をそのまま保存してください。

`CONTEXT7_API_KEY` は `opencode.jsonc` には直書きせず、`.env.local` に入れます。

```bash
export CONTEXT7_API_KEY="<your-context7-key>"
```

### セットアップ中に入力するもの

- sudo パスワード
- Bitwarden のログイン情報（必要なら MFA）
- GitHub CLI 認証（`wslview` 経由で Windows 側ブラウザが開きます）

## インストールされるもの

### apt パッケージ

| パッケージ | 用途 |
|---|---|
| zsh | デフォルトシェル |
| git | バージョン管理 |
| curl | ダウンロード・API 呼び出し |
| jq | JSON 処理 |
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
| bitwarden | パスワードマネージャー CLI |
| bat | `cat` 代替 |
| fd | `find` 代替 |
| fzf | ファジーファインダー |
| ripgrep | `grep` 代替 |
| zoxide | `cd` 代替 |
| eza | `ls` 代替 |
| delta | Git diff ビューアー |
| dust | ディスク使用量ビューアー |
| zellij | ターミナルマルチプレクサー |
| neovim | エディタ |
| opencode | AI コーディングエージェント |
| btop | システムモニター |
| gcloud | Google Cloud CLI |
| yq | YAML/JSON/XML プロセッサー |
| yazi | ターミナルファイルマネージャー |

### 対話セットアップで生成されるもの

| ファイル | 内容 |
|---|---|
| `~/.ssh/id_ed25519` | SSH 鍵（新規生成・GitHub 登録） |
| `~/.config/gh/hosts.yml` | GitHub CLI 認証情報 |
| `~/.config/shell/.env.local` | Bitwarden から復元される環境変数 |
| `~/.npmrc` | Bitwarden から復元される npm 設定 |
| `~/.config/opencode/node_modules/` | `npm ci` で自動導入されるプラグイン依存 |

## セットアップの流れ

```
1. apt インストール + zsh をデフォルトシェルに変更
2. mise インストール + ツール一覧を導入
3. opencode プラグイン依存を npm ci で導入
4. 対話セットアップ（Bitwarden 復元 → GitHub 認証 → SSH 鍵生成）
```

各ステップは `run_once_10-`, `run_once_20-`, `run_onchange_after_25-`, `run_once_30-` の順で実行されます。

## コマンド

```bash
chezmoi diff       # 差分確認
chezmoi add ~/.zshrc  # ファイル更新をソースに反映
chezmoi apply      # ソースの変更をホームに適用
```