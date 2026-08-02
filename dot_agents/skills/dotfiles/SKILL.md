---
name: dotfiles
description: 現在のホームディレクトリ環境を chezmoi dotfiles に反映する。ユーザーが環境を dotfiles として保持・反映したい、または「〜も管理対象に追加して」と管理対象の追加を求めたときに使用する。
---

# dotfiles

現在のホームディレクトリの状態を chezmoi ソース（`~/.local/share/chezmoi`）に反映する。ホームが正であり、ソースが追従する。`apply` はしない（ホームを上書きしない）。

## Steps

### 1. 差分を洗い出す

`chezmoi status` を実行し、各行を第1文字で分類する（第2文字は apply 時の挙動を示すだけで無視してよい）。

| 第1文字 | 意味 | 対応 |
|---|---|---|
| `M` | ホームで変更済み | `chezmoi add` で再取り込み |
| `D` | ホームから削除済み | `chezmoi forget` で管理対象から外す |
| `A` / `R` / その他 | 特殊状態（スクリプト等） | ユーザーに提示し、自動では操作しない |

なお、第1文字が空白で第2文字が `R` の行は実行待ちの run_onchange スクリプトを示し、操作は不要である（スクリプトも status に現れうる）。

あわせて新規ファイルを検出する。**深さ1のエントリ単位**で列挙し、ディレクトリ配下のファイルは展開しない（ディレクトリは1項目として扱う）。

- 管理対象ディレクトリ（`.agents` / `.config` / `.pi`）直下の新規エントリ:
  `comm -13 <(chezmoi managed | sort) <(for d in .agents .config .pi; do ls -A "$d" | sed "s|^|$d/|"; done | sort)`
  cwd を `$HOME` にして実行する。管理対象の第1階層は `chezmoi managed | cut -d/ -f1 | sort -u` から `[ -d "$HOME/$d" ]` を満たすディレクトリのみを抽出する（スクリプト名等が混ざるため）。さらに `chezmoi ignored` に載っているパスは候補から除外する。
- ホーム直下の新規ドットエントリ: `comm -23 <(ls -A ~ | sort) <(chezmoi managed | cut -d/ -f1 | sort -u)` のうちドットで始まるもの。
- 両スキャン共通で、名前から明らかにキャッシュ・履歴・セッション・認証・ツール生成物と分かるものは候補から除外する。代表例: `.cache`, `.local`, `.cargo`, `.rustup`, `.npm`, `.bun`, `.texlive*`, `.vscode*`, `.zed_server`, `.dotnet`, `*_cache`, `.bash_history`, `.python_history`, `.zcompdump`, `.viminfo`, `.lesshst`, `.wget-hsts`, `.ssh`, `.gnupg`, `.mcp-auth`, `.claude`, `.codex`, `.copilot`, `.semgrep`, `.pi-subagents`, `.plannotator`, `dotfiles-review.md`, `dotfiles-review-result.json` 等。それ以外（トークンを含みうるもの）も候補として提示し、注記を添えてユーザーに判断させる。

**完了条件**: 変更・削除・新規の3リストが漏れなく揃い、それぞれの件数が把握できている。

### 2. レビュー用 Markdown レポートを生成し、Plannotator で確認を得る

1. `~/dotfiles-review.md` に Markdown レポートを生成する（毎回上書き）。構成:
   - 見出しと生成日時、件数概要（変更 n / 削除 n / 新規候補 n）。
   - **変更ファイル**: 番号付きで、各ファイルの `chezmoi diff --reverse <target>` を ```diff コードブロックに埋め込む（`--reverse` でホームを新しい状態として表示する: `+`（緑）がホームで追加された内容、`-`（赤）がホームで削除された内容）。diff が巨大なファイル（目安: 50行超）は、変更の要約（何が追加/削除されたか）と差分行数のみ記載し、完全な diff はユーザーが指定したら個別に提示する。
   - **削除ファイル**: 番号付き一覧と、`chezmoi cat <target>` の先頭数行。
   - **新規候補**: 番号付きテーブル（パス / 種別 / 警告）。ステップ1で検出した深さ1のエントリをそのまま1行ずつ載せる（配下のファイルは展開しない）。トークンや鍵を含みうるもの（`.config/gh` 等）は ⚠ を付ける。`.config/gh` 等のトークン系はリポジトリの CI（`$HOME/.config/gh/hosts.yml` が存在すると失敗する）と衝突するため、CI 側の期待も同時に更新しない限り却下が想定される旨を注記する。
   - 末尾に確認方法の説明: 「各項目の扱いをコメントで指示してください（例: 『却下』『修正: <内容>』『apply 希望』）。問題なければ Approve を押してください」。
2. `plannotator annotate ~/dotfiles-review.md --gate --json --require-approval --result-file ~/dotfiles-review-result.json` を実行し、ブラウザのレビュー完了を待つ（`--gate` で Approve ボタンが付く。未インストールならユーザーに確認して `curl -fsSL https://plannotator.ai/install.sh | bash` で入れる）。終了コード: 0 = 承認、1 = 却下（手順2-4のチャットレビューにフォールバックする）、2 = 使い方エラー（コマンドを確認して再実行し、それでも失敗する場合は手順2-4へ）。セッションがタイムアウトやフィードバックなしで閉じた場合も手順2-4のチャットレビューにフォールバックする。
3. フィードバックを各項目の扱いに反映する。デフォルトの解釈:
   - **変更ファイル**: 指摘なし → 承認（add の対象）。「却下」「やめて」等の否定の指摘 → 却下（add の対象から除外し、ホームの変更はそのまま残す）。具体的な修正指示 → 指示どおり修正して承認。
   - **削除ファイル**: 同様。指摘なし → 承認（forget の対象）。否定の指摘 → forget の対象から除外。修正指示 → 反映。
   - **新規候補**: 指摘なし → 対象外（追加しない）。「追加して」等の指示や具体的指摘 → 反映して追加。
   - 承認にメモが付いていても、ガイダンスとして読み、文書の修正はしない。「ホームも戻す」指示があれば `chezmoi apply <target>` を実行する。
   - 対象が曖昧な場合や質問事項がある場合は、ユーザーに確認してから進める。
4. Plannotator が使えない場合（未インストール・ブラウザ不可等）は、チャットで番号付き一覧を提示し、ユーザーの指示（承認/却下/修正/apply）を番号で受け付ける。

**完了条件**: レポートが生成され、全項目の扱い（承認/却下/修正/apply）が確定している。

### 3. 反映する

- 変更分: `chezmoi add <target>...`
- 削除分: `chezmoi forget <target>...`
- 承認された新規分: `chezmoi add -r <path>...`
- ユーザーが明示的にパスを指定した場合は、検出結果と無関係にそのパスを `add -r` する。
- `.agents/skills/` 配下の新規スキルを追加した場合は、同時に `dot_agents/dot_skill-lock.json` の `skills` にディレクトリ名のエントリ（例: `"dotfiles": {"source": "local"}`）を追加する。CI の一致チェックを通すため。
- `chezmoi add` がシークレット警告を出したら、その対象をユーザーに確認してから進める。

**完了条件**: すべてのコマンドがエラーなく完了している。失敗した対象は1回リトライし、再失敗したら中断して途中経過をユーザーに報告する。

### 4. 検証する

`chezmoi status` を再実行し、ステップ1で「その他」と分類した行以外が残っていないことを確認する。

**完了条件**: 予告済みの行以外はゼロ。

### 5. README を更新し、ブランチを切り、コミットし、PR を作る

main は保護されているため、ローカルの main には直接コミットしない。以下の順で進める。

1. コミット前に、変更内容に合わせてソースリポジトリの `README.md` を更新する（インストールされるツール一覧、管理対象ファイルの説明など、変更のあった箇所。実ファイルと突き合わせて古い記述を直す）。
2. `git -C ~/.local/share/chezmoi fetch origin` で最新を取得する。
3. 事前確認（preflight）: ローカルが main にいてツリーがクリーンであること、`~/.local/bin/mise exec gh -- gh pr list --head chore/sync-dotfiles-*` が空であること、残存する `chore/sync-dotfiles-*` ブランチがないことを確認する。残存ブランチや PR があれば再利用するか削除してから進む。
4. `git -C ~/.local/share/chezmoi switch -c chore/sync-dotfiles-<日時> origin/main` で origin/main から feature ブランチを切る。
5. `git -C ~/.local/share/chezmoi status --porcelain` でコミット対象のファイル群を確認してから、`git -C ~/.local/share/chezmoi add -A` し、`commit -m "chore: sync dotfiles (M:n A:n D:n)"` のように実際に反映した件数をメッセージに含めてコミットする。
6. `~/.local/bin/mise exec gh -- git push -u origin HEAD` で push する（credential helper の `!gh` を確実に解決するため、mise exec gh 経由で実行する。gh が PATH にない環境でも動く）。
7. `~/.local/bin/mise exec gh -- gh pr create --title "chore: sync dotfiles (M:n A:n D:n)" --body <変更の要点>` で PR を作成する。
8. PR の URL をユーザーに提示する。

**完了条件**: README に更新すべき箇所があれば更新され（なければ更新不要）、PR が作成され、その URL がユーザーに提示されている。

### 6. レビューと CI 確認のループ

PR 作成後、以下をレビューが通り CI が成功するまで繰り返す。パス条件: レビュアーが blocker も fix-worth-doing もなしと報告し、かつ CI が成功した時点でループを抜ける。ラウンド上限は3回とし、超えたら残件をユーザーに提示して止める。

1. pi の `reviewer` subagent を `model: openai-codex/gpt-5.6-sol` で呼び、PR の差分をレビューさせる。
2. レビューの指摘に対して完全に信用を置かず、実際のファイルと突き合わせて事実確認を行い、修正すべきものだけをブランチにコミット → push する。事実に基づかない指摘や不要な修正は行わない。
3. `~/.local/bin/mise exec gh -- gh pr checks <PR番号> --watch` で CI の完了を待つ。失敗した場合、`~/.local/bin/mise exec gh -- gh run view <失敗したrun-id> --log-failed` で失敗ログを確認し、原因を修正してコミット → push し、再び待つ。
4. レビューが通り、CI が成功した時点で PR の作成は完了と判断し、その旨をユーザーに報告する。CI 失敗の原因判定の前に、origin/main の CI が既に失敗していないか確認する（main 起因の失敗を PR のせいにしない）。

このリポジトリの CI（`.github/workflows/ci.yml`）の主な失敗原因: skill-lock 不一致（`dot_agents/dot_skill-lock.json` の skills キーと実ディレクトリが一致しない。新規スキル追加時に発生しうる。修正は不足ディレクトリ名のエントリを lock の skills に追加する。チェックはキー名の一致のみを見るため最小エントリで通る）、markdownlint（全 `.md` が対象）、shellcheck / shfmt（`run_*.sh`）、秘密スキャン（OpenSSH 秘密鍵のヘッダ行、`gho_`, `npm_` 等のパターン）。秘密スキャンで落ちた場合は、該当ファイルをブランチから除去し、`git push --force-with-lease` でブランチ履歴からも消してから再 push し、ユーザーにクレデンシャルのローテーションを促す。

**完了条件**: レビューが通り、全チェックが成功し、その旨をユーザーに報告している。

### 7. obsidian のメモを更新する

PR の完了後、`~/obsidian/Knowledge/Dev/dotfiles.md` を現状の実装に合わせて更新する。リポジトリ構造・管理対象ファイル・ワークフロー・セットアップ手順など、実際のファイルと突き合わせて古い記述を直す。

**完了条件**: obsidian メモが現状の実装と一致し、更新内容をユーザーに報告している。

## 注記

- テンプレート化（`.tmpl`）はユーザーが明示的に指示したときだけ行う。既存の `.tmpl` は触らない。
- スクリプト（`run_once_*` 等）はソースディレクトリを直接編集するもので、実行後の run_once は `chezmoi status` に現れない。スクリプトの編集はソースディレクトリで行い、コミットで拾われる。
