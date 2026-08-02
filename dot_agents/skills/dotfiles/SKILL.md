---
name: dotfiles
description: 現在のホームディレクトリ環境を chezmoi dotfiles に反映する。ユーザーが「今の環境を dotfiles として保持/保存して」「dotfiles に反映/同期して」「環境をスナップショットして」「〜も管理対象に追加して」等の要望を出したときに使用する。変更・削除・新規ファイルの検出から add/forget、コミット、PR 作成、CI 成功確認まで一貫して行う。
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

あわせて新規ファイルを検出する。

- 管理対象ディレクトリ内の新規ファイル:
  `comm -13 <(chezmoi managed | sort) <(find <管理対象の第1階層ディレクトリ> -type f -not -path '*/node_modules/*' -not -path '*/.git/*' | sed 's|^\./||' | sort)`
  管理対象の第1階層は `chezmoi managed | cut -d/ -f1 | sort -u` からディレクトリのみ抽出する。
- ホーム直下の新規ドットファイル: `ls -A ~` のうち管理対象外のもの。`.ssh` と `.gnupg` は常に候補から除外する。それ以外（キャッシュ・トークンを含みうるもの）も候補として提示し、注記を添えてユーザーに判断させる。

**完了条件**: 変更・削除・新規の3リストが漏れなく揃い、それぞれの件数が把握できている。

### 2. レビュー用 Markdown レポートを生成し、Plannotator で確認を得る

1. `~/dotfiles-review.md` に Markdown レポートを生成する（毎回上書き）。構成:
   - 見出しと生成日時、件数概要（変更 n / 削除 n / 新規候補 n）。
   - **変更ファイル**: 番号付きで、各ファイルの `chezmoi diff --reverse <target>` を ```diff コードブロックに埋め込む（`--reverse` でホームを新しい状態として表示する: `+`（緑）がホームで追加された内容、`-`（赤）がホームで削除された内容）。diff が巨大なファイル（目安: 50行超）は、変更の要約（何が追加/削除されたか）と差分行数のみ記載し、完全な diff はユーザーが指定したら個別に提示する。
   - **削除ファイル**: 番号付き一覧と、`chezmoi cat <target>` の先頭数行。
   - **新規候補**: 番号付きテーブル（パス / 種別 / 警告）。トークンや鍵を含みうるもの（`.config/gh` 等）は ⚠ を付ける。
   - 末尾に確認方法の説明: 「各項目の扱いをコメントで指示してください（例: 『却下』『修正: <内容>』『apply 希望』）。問題なければ Approve を押してください」。
2. `plannotator annotate ~/dotfiles-review.md --gate` を実行し、ブラウザのレビュー完了を待つ（`--gate` で Approve ボタンが付く。未インストールならユーザーに確認して `curl -fsSL https://plannotator.ai/install.sh | bash` で入れる）。
3. フィードバックを各項目の扱いに反映する:
   - **承認**（decision: approved）: そのまま反映する。承認にメモが付いていても、ガイダンスとして読み、文書の修正はしない。
   - **コメント（修正指示）**: 指示された内容に直してから反映する。
   - **コメント（却下）**: add / forget の対象から除外する（ホームの変更はそのまま残る）。「ホームも戻す」指示があれば `chezmoi apply <target>` を実行する。
   - 対象が曖昧な場合は確認する。
4. Plannotator が使えない場合（未インストール・ブラウザ不可等）は、チャットで番号付き一覧を提示し、ユーザーの指示（承認/却下/修正/apply）を番号で受け付ける。

**完了条件**: レポートが生成され、全項目の扱い（承認/却下/修正/apply）が確定している。

### 3. 反映する

- 変更分: `chezmoi add <target>...`
- 削除分: `chezmoi forget <target>...`
- 承認された新規分: `chezmoi add -r <path>...`
- ユーザーが明示的にパスを指定した場合は、検出結果と無関係にそのパスを `add -r` する。
- `.agents/skills/` 配下の新規スキルを追加した場合は、同時に `dot_agents/dot_skill-lock.json` の `skills` にディレクトリ名のエントリ（例: `"dotfiles": {"source": "local"}`）を追加する。CI の一致チェックを通すため。
- `chezmoi add` がシークレット警告を出したら、その対象をユーザーに確認してから進める。

**完了条件**: すべてのコマンドがエラーなく完了している。

### 4. 検証する

`chezmoi status` を再実行し、ステップ1で「その他」と分類した行以外が残っていないことを確認する。

**完了条件**: 予告済みの行以外はゼロ。

### 5. ブランチを切り、コミットし、PR を作る

main は保護されているため、ローカルの main には直接コミットしない。以下の順で進める。

1. `git -C ~/.local/share/chezmoi fetch origin` で最新を取得する。
2. `git -C ~/.local/share/chezmoi switch -c chore/sync-dotfiles-<日時> origin/main` で origin/main から feature ブランチを切る。
3. `git -C ~/.local/share/chezmoi add -A` し、`commit -m "chore: sync dotfiles (M:n A:n D:n)"` のように件数概要をメッセージに含めてコミットする。
4. `~/.local/bin/mise exec gh -- git push -u origin HEAD` で push する（credential helper の `!gh` を確実に解決するため、素の git ではなく mise exec gh 経由で実行する）。
5. `~/.local/bin/mise exec gh -- gh pr create --title "chore: sync dotfiles (M:n A:n D:n)" --body <変更の要点>` で PR を作成する。gh は PATH にないため必ず mise exec 経由で呼ぶ。
6. PR の URL をユーザーに提示する。

**完了条件**: PR が作成され、その URL がユーザーに提示されている。

### 6. CI の成功を確認し、失敗したら修正する

1. `~/.local/bin/mise exec gh -- gh pr checks <PR番号> --watch` で全チェックの完了を待つ（PR番号はステップ5の出力から取得する）。
2. 失敗した場合、`~/.local/bin/mise exec gh -- gh run view <失敗したrun-id> --log-failed` で失敗ログを確認し、原因を修正してブランチにコミット → push し、再び `gh pr checks` で待つ。成功するまで繰り返す。
3. 全チェック成功をユーザーに報告して終了する。

このリポジトリの CI（`.github/workflows/ci.yml`）の主な失敗原因: skill-lock 不一致（`dot_agents/dot_skill-lock.json` の skills キーと実ディレクトリが一致しない。新規スキル追加時に発生しうる。修正は不足ディレクトリ名のエントリを lock の skills に追加する。チェックはキー名の一致のみを見るため最小エントリで通る）、markdownlint（全 `.md` が対象）、shellcheck / shfmt（`run_*.sh`）、秘密スキャン（OpenSSH 秘密鍵のヘッダ行、`gho_`, `npm_` 等のパターン）。

**完了条件**: 全チェックが成功し、その旨をユーザーに報告している。

## 注記

- テンプレート化（`.tmpl`）はユーザーが明示的に指示したときだけ行う。既存の `.tmpl` は触らない。
- スクリプト（`run_once_*` 等）はソースディレクトリを直接編集するもので、`chezmoi status` に現れない。変更があればコミットで拾われる。
