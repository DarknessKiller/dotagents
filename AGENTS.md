# Atlas

## Git Commits

Always use `git commit --no-gpg-sign`. Do not change repository or global Git signing configuration.

## Terminal tools

- Content: `rg pattern path` — scope with `-t py`, reach ignored files with `-uu`.
- `rg` `-r` replaces matches in output: pass a replacement only when rewriting, plain search uses no `-r`.
- Names: `fd pattern` — scope with `-e py`, batch-act with `-x cmd`.
- JSON: `jq -r .field file` — chain with `.[] | select(.ok) | .name`.

