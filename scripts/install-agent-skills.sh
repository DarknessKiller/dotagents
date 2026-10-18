#!/usr/bin/env bash
set -euo pipefail

log() {
  printf '[agent-skills] %s\n' "$1"
}

if ! command -v npx >/dev/null 2>&1; then
  log "npx not found; skipped Agent Skills installs"
  exit 0
fi

# Caveman skills.
if npx -y skills@latest add https://github.com/juliusbrussee/caveman \
  -g \
  -y \
  --full-depth; then
  log "Caveman skills installed"
else
  log "Caveman skills skipped"
fi

# Atlas skills.
if npx -y skills@latest add https://github.com/darknesskiller/skills \
  -g \
  -y \
  --full-depth; then
  log "Atlas skills installed"
else
  log "Atlas skills skipped"
fi

# Matt Pocock skills.
if npx -y skills@latest add mattpocock/skills \
  -g \
  -s grill-with-docs grill-me grilling handoff teach wait-what \
  writing-for-agents code-review codebase-design domain-modeling \
  tdd implement improve-codebase-architecture retro \
  -y \
  --full-depth; then
  log "Matt Pocock skills installed"
else
  log "Matt Pocock skills skipped"
fi

# Pstack skills.
if npx -y skills@latest add https://github.com/cursor/plugins/tree/main/pstack \
  -g \
  -s unslop technical-writing \
  -y \
  --full-depth; then
  log "Pstack skills installed"
else
  log "Pstack skills skipped"
fi

# i-have-adhd skill.
if npx -y skills@latest add ayghri/i-have-adhd \
  -g \
  -y; then
  log "i-have-adhd skill installed"
else
  log "i-have-adhd skill skipped"
fi

log "Finished processing skill installs"
