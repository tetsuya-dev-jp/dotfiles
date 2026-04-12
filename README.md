# tetsuya.dev dotfiles

chezmoi + age で管理するドットファイル。

## セットアップ（新マシン）

### 1. ワンライナーセットアップ

```bash
sh -c "$(curl -fsSL https://get.chezmoi.io/lb)" -- init --apply https://github.com/tetsuya-dev-jp/dotfiles.git
```

これで以下が自動で行われます：

- apt パッケージのインストール（age, zsh, git, curl 等）
- デフォルトシェルの zsh への変更
- mise 経由でツール群をインストール（node, bun, starship, gh, delta, nvim 等）
- 暗号化ファイル**以外**のドットファイルが配置される

### 2. age 鍵の配置

暗号化ファイルを復号するには、age 秘密鍵が必要です。

```bash
mkdir -p ~/.config/chezmoi/key
# 別マシンから鍵をコピー:
# scp ~/.config/chezmoi/key/age.key <new-host>:~/.config/chezmoi/key/age.key
chmod 600 ~/.config/chezmoi/key/age.key
```

### 3. 暗号化ファイルの復元

鍵を配置したあと、暗号化ファイルを復元します。

```bash
chezmoi apply
```

以下のファイルが復元されます：

- `~/.ssh/id_ed25519` — SSH 秘密鍵
- `~/.npmrc` — npm 認証トークン
- `~/.config/gh/hosts.yml` — GitHub CLI 認証
- `~/.config/shell/.env.local` — 環境変数（API キー等）
- `~/.config/opencode/opencode.jsonc` — OpenCode 設定

### 4. SSH 鍵のパーミッション設定

```bash
chmod 600 ~/.ssh/id_ed25519
```

## 管理している主なファイル

| ファイル | 管理方式 |
|---|---|
| `.zshrc`, `.bashrc`, `.gitconfig` | 平文 |
| `.config/starship.toml`, `.config/zellij/`, `.config/nvim/` | 平文 |
| `.config/mise/config.toml` | 平文 |
| `.ssh/id_ed25519.pub`, `.config/gh/config.yml` | 平文 |
| `.ssh/id_ed25519`, `.npmrc`, `.config/gh/hosts.yml` | age 暗号化 |
| `.config/shell/.env.local`, `.config/opencode/opencode.jsonc` | age 暗号化 |

## セットアップ後の手動作業

- [ ] GitHub CLI で `gh auth login` を実行（認証トークンの更新）
- [ ] Homebrew のインストール（Linux の場合）

## コマンド

```bash
# 差分確認
chezmoi diff

# ファイル更新をソースに反映
chezmoi add ~/.zshrc

# 暗号化ファイルの編集
chezmoi edit ~/.ssh/id_ed25519

# ソースの変更をホームに適用
chezmoi apply
```