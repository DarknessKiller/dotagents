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
SOURCE_OF_TRUTH="$REPO_DIR/AGENTS.md"
BACKUP_SUFFIX=".before-dotagents.$(date +%Y%m%d%H%M%S)"

link_config() {
  local source="$1"
  if [ ! -e "$source" ] && [ ! -L "$source" ]; then
    printf 'skipped (missing source): %s\n' "$source"
    return 0
  fi

  mkdir -p "$(dirname "$target")"

  if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
    printf 'ok: %s\n' "$target"
    return 0
  fi

  if [ -L "$target" ]; then
    rm "$target"
  elif [ -e "$target" ]; then
    mv "$target" "$target$BACKUP_SUFFIX"
    printf 'backed up: %s\n' "$target$BACKUP_SUFFIX"
  fi

  ln -s "$source" "$target"
  printf 'linked: %s -> %s\n' "$target" "$source"
  # Pi configuration.
if command -v pi >/dev/null 2>&1; then
  printf '\n== Pi ==\n'

  link_config "$SOURCE_OF_TRUTH" "$HOME/.pi/agent/AGENTS.md"
  link_config "$REPO_DIR/pi/agent/agents" "$HOME/.pi/agent/agents"
  link_config "$REPO_DIR/pi/agent/settings.json" "$HOME/.pi/agent/settings.json"
  link_config "$REPO_DIR/pi/agent/extensions/context-cap.json" "$HOME/.pi/agent/extensions/context-cap.json"
  link_config "$REPO_DIR/pi/agent/subagents-lite.json" "$HOME/.pi/agent/subagents-lite.json"
else
  printf 'skipped: pi is not installed\n'
fi

# OpenCode configuration.
if command -v opencode >/dev/null 2>&1; then
  printf '\n== OpenCode ==\n'

  link_config "$SOURCE_OF_TRUTH" "$HOME/.config/opencode/AGENTS.md"
  link_config "$REPO_DIR/opencode/opencode.jsonc" "$HOME/.config/opencode/opencode.jsonc"
else
  printf 'skipped: opencode is not installed\n'
fi

# Claude Code configuration.
if command -v claude >/dev/null 2>&1; then
  printf '\n== Claude Code ==\n'

  link_config "$SOURCE_OF_TRUTH" "$HOME/.claude/CLAUDE.md"
  link_config "$REPO_DIR/claude/settings.json" "$HOME/.claude/settings.json"
  link_config "$REPO_DIR/claude/statusline.sh" "$HOME/.claude/statusline.sh"
else
  printf 'skipped: claude is not installed\n'
fi

# Install agent skills (no symlink).
SKILLS_INSTALLER="$REPO_DIR/scripts/install-agent-skills.sh"

if [ -f "$SKILLS_INSTALLER" ]; then
  if command -v npx >/dev/null 2>&1; then
    printf '\n== Agent Skills ==\n'
    bash "$SKILLS_INSTALLER"
  else
    printf 'skipped: npx is not installed\n'
  fi
else
  printf 'skipped: skills installer not found: %s\n' "$SKILLS_INSTALLER"
fi

printf '\nSetup complete.\n'
