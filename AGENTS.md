# Atlas

## Git Commits

Always use `git commit --no-gpg-sign`. Do not change repository or global Git signing configuration.

## Terminal tools

- Content: `rg pattern path` — scope with `-t py`, reach ignored files with `-uu`.
- Names: `fd pattern` — scope with `-e py`, batch-act with `-x cmd`.
- JSON: `jq -r .field file` — chain with `.[] | select(.ok) | .name`.

## File editing

Use hashline for file reads and edits: `mcp__hashline__read` gets anchors, `mcp__hashline__patch` applies `SWAP`/`DEL`/`INS.*`. Anchors survive nearby edits and stale reads are rejected. Use the built-in `Edit` only when hashline is unavailable; use `Write` for new or fully replaced files.

