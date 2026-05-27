---
name: "zotero-cli"
description: "Use when working with the user's Zotero library from the terminal via `zotero-cli`: searching papers, fetching metadata/full text/BibTeX, managing notes/annotations/collections/tags, adding items, checking duplicates, or maintaining the semantic search database."
---

# Zotero CLI Skill

Use `zotero-cli` for direct terminal access to Zotero. It is the standalone CLI from `zotero-mcp-server` and uses the same configuration created by `zotero-mcp setup`.

## When to use
- Search the Zotero library by keyword, tag, citation key, notes, advanced conditions, or semantic meaning.
- Retrieve item metadata, BibTeX, full text, child attachments/notes, collections, tags, recent items, feeds, or libraries.
- Create/list/update/delete notes, list/create annotations, or get PDF outlines.
- Add items by DOI, URL, or local file.
- Edit item metadata, tags, collections, or identifiers.
- Find/merge duplicates or update/check the semantic search database.

## Preconditions
1. Verify the command exists:
   ```bash
   command -v zotero-cli
   zotero-cli --help
   ```
2. If missing, install/configure:
   ```bash
   uv tool install zotero-mcp-server
   zotero-mcp setup
   ```
   Alternatives: `pip install zotero-mcp-server` or `pipx install zotero-mcp-server`.
3. For local mode/full-text access, Zotero should be running. Use `zotero-cli config` to inspect configuration; do not expose secrets unless explicitly requested.

## Safety rules
- Treat Zotero write operations as persistent changes. Before `edit`, `add`, `notes create/update/delete`, `annotations create`, `collections manage`, `tags`, or `duplicates merge`, explain the intended change and prefer a read/search command first to confirm keys.
- For duplicate merges, use dry run first:
  ```bash
  zotero-cli duplicates merge --keeper-key KEEP --duplicate-keys DUP1,DUP2 --dry-run
  ```
- Never print API keys or secrets. Avoid `zotero-cli config --show-secrets` unless the user explicitly asks.
- Prefer item keys over ambiguous titles for write operations.
- Quote queries and metadata values to avoid shell parsing issues.

## Core commands

### Search
```bash
zotero-cli search "machine learning"
zotero-cli s "neural networks" --limit 5
zotero-cli search --mode tag "important,reviewed"
zotero-cli search --mode citekey "Smith2020"
zotero-cli search --mode semantic "attention mechanisms"
zotero-cli search --mode notes "highlight text"
zotero-cli search --mode advanced --conditions '[{"field":"title","operator":"contains","value":"climate"}]'
```
Useful options: `--qmode titleCreatorYear|everything`, `--collection KEY`, `--limit N`, `--join-mode all|any`, `--sort-by FIELD`, `--sort-direction asc|desc`, `--filters JSON`.

### Get library data
```bash
zotero-cli get metadata ITEM_KEY
zotero-cli g metadata ITEM_KEY --output-format bibtex
zotero-cli get bibtex ITEM_KEY
zotero-cli get fulltext ITEM_KEY
zotero-cli get children ITEM_KEY
zotero-cli get collections --limit 500
zotero-cli get collection-items COLLECTION_KEY --detail summary --limit 50
zotero-cli get tags --limit 500
zotero-cli get recent --limit 20
zotero-cli get libraries
zotero-cli get feeds
```

### Notes and annotations
```bash
zotero-cli notes list --item-key ITEM_KEY --limit 20 --full
zotero-cli notes create --item-key ITEM_KEY --title "Note title" --text "Note body" --tags "idea,review"
zotero-cli notes create --item-key ITEM_KEY --text -    # read from stdin
zotero-cli notes update --item-key NOTE_KEY --text -
zotero-cli notes delete --item-key NOTE_KEY

zotero-cli ann list --item-key ITEM_KEY --limit 100
zotero-cli annotations list --item-key ITEM_KEY --pdf-extraction
zotero-cli annotations create --attachment-key ATTACHMENT_KEY --page 3 --text "Highlighted text" --comment "Comment" --color "#ffd400"
zotero-cli outline ITEM_KEY
```

### Add and edit items
```bash
zotero-cli add doi 10.1038/s41586-021-03819-2 --tags "to-read,important"
zotero-cli add url https://arxiv.org/abs/2301.00001 --collections COLLECTION_KEY
zotero-cli add file --filepath /path/to/paper.pdf --parent-key ITEM_KEY

zotero-cli edit ITEM_KEY --title "New Title"
zotero-cli edit ITEM_KEY --add-tags "reviewed,important" --date "2024"
zotero-cli edit ITEM_KEY --remove-tags "todo"
zotero-cli edit ITEM_KEY --doi "10.xxxx/example" --url "https://example.com"
```
Common edit fields: `--title`, `--creators` (JSON array), `--date`, `--publication-title`, `--abstract`, `--tags`, `--add-tags`, `--remove-tags`, `--collections`, `--collection-names`, `--doi`, `--url`, `--extra`, `--volume`, `--issue`, `--pages`, `--publisher`, `--issn`, `--language`, `--short-title`, `--edition`, `--isbn`, `--book-title`.

### Collections, tags, duplicates, database
```bash
zotero-cli coll create "Collection Name"
zotero-cli coll search "PhD Research"
zotero-cli collections manage --item-keys ITEM1,ITEM2 --add-to COLLECTION_KEY
zotero-cli tags --query "CRISPR" --add reviewed --limit 50

zotero-cli duplicates find --method both --limit 50
zotero-cli duplicates merge --keeper-key KEEP --duplicate-keys DUP1,DUP2 --dry-run

zotero-cli db update
zotero-cli db update --fulltext --force-rebuild
zotero-cli db status
zotero-cli db inspect --limit 20 --stats
```

### Library selection and diagnostics
```bash
zotero-cli library list
zotero-cli library switch --library-id GROUP_ID --library-type group
zotero-cli library reset
zotero-cli -v search "CRISPR"
zotero-cli config
```

## Workflow patterns

### Find a paper and cite it
1. `zotero-cli search "author year title" --limit 5`
2. `zotero-cli get metadata ITEM_KEY`
3. `zotero-cli get bibtex ITEM_KEY` or `zotero-cli get metadata ITEM_KEY --output-format bibtex`

### Inspect an item's available text and notes
1. `zotero-cli get children ITEM_KEY`
2. `zotero-cli get fulltext ITEM_KEY`
3. `zotero-cli ann list --item-key ITEM_KEY`
4. `zotero-cli notes list --item-key ITEM_KEY --full`

### Add a paper safely
1. Search first to avoid duplicates: `zotero-cli search "title or DOI" --limit 10`
2. Add by DOI/URL/file.
3. Confirm result with `zotero-cli get recent --limit 5` or `zotero-cli search "title"`.

## Troubleshooting
- If local/full-text reads fail, ensure Zotero is open and the local API is enabled/configured.
- If semantic search fails, run `zotero-cli db status`; update with `zotero-cli db update` or rebuild with `--force-rebuild` if embeddings/config changed.
- Add `-v` for progress and API diagnostics.
- Use `zotero-cli <command> --help` or `zotero-cli <command> <subcommand> --help` for exact options.
