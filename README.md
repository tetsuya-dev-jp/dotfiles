# tetsuya.dev dotfiles

chezmoi + Bitwarden で管理するドットファイル。

## セットアップ（新マシン）

### リポジトリ構成

- `dot_*` / `dot_config/` - 平文で管理する dotfiles
- `dot_agents/` - エージェント向け設定・スキル定義
- `run_once_*.sh` - 初回セットアップ時にだけ走るスクリプト
- `.chezmoiignore` - 生成物やマシン固有ファイルの除外設定

### 1. ワンライナーセットアップ

```bash
sh -c "$(curl -fsSL https://get.chezmoi.io/lb)" -- init --apply https://github.com/tetsuya-dev-jp/dotfiles.git
```

これで以下が自動で行われます：

- apt パッケージのインストール（zsh, git, curl, jq, wslu 等）
- デフォルトシェルの zsh への変更
- mise 経由でツール群をインストール（node, bun, eza, starship, gh, bitwarden, delta, nvim 等）
- 平文 dotfiles の配置
- 対話式の初回セットアップ
  - Bitwarden ログインと secret 復元
  - `gh auth login`
  - SSH 鍵の生成と GitHub への登録

初回セットアップ用スクリプトは、以下の順番で実行されます。

1. `run_once_10-install-apt-packages.sh`
2. `run_once_20-install-mise.sh`
3. `run_once_30-setup-personal-machine.sh`

### 2. Bitwarden アイテムの準備

初回セットアップでは、以下の secure note を Bitwarden に置いておきます。

- `dotfiles: ~/.config/shell/.env.local`
- `dotfiles: ~/.npmrc`
- `dotfiles: ~/.config/opencode/opencode.jsonc`

各アイテムの note に、そのままファイルの中身を保存します。

### 3. 初回セットアップ中に入力するもの

- `sudo` パスワード
- Bitwarden のログイン情報と必要なら MFA
- GitHub CLI 認証（WSL から Windows 側ブラウザを利用）

### 4. 復元・生成される主なファイル

- `~/.config/shell/.env.local` — Bitwarden から生成
- `~/.npmrc` — Bitwarden から生成
- `~/.config/opencode/opencode.jsonc` — Bitwarden から生成
- `~/.ssh/id_ed25519` — 初回セットアップで新規生成
- `~/.config/gh/hosts.yml` — `gh auth login` で生成

### 5. SSH 鍵のパーミッション設定

```bash
chmod 600 ~/.ssh/id_ed25519
```

## 管理している主なファイル

| ファイル | 管理方式 |
|---|---|
| `.zshrc`, `.bashrc`, `.gitconfig` | 平文 |
| `.agents/` | 平文 |
| `.config/starship.toml`, `.config/zellij/`, `.config/nvim/` | 平文 |
| `.config/mise/config.toml`, `.config/gh/config.yml` | 平文 |
| `.ssh/id_ed25519`, `.ssh/id_ed25519.pub`, `.config/gh/hosts.yml` | 初回セットアップ時に生成 |
| `.npmrc`, `.config/shell/.env.local`, `.config/opencode/opencode.jsonc` | Bitwarden から生成 |

## コマンド

```bash
# 差分確認
chezmoi diff

# ファイル更新をソースに反映
chezmoi add ~/.zshrc

# Bitwarden の secret を更新したあとに反映
chezmoi apply

# ソースの変更をホームに適用
chezmoi apply
```
