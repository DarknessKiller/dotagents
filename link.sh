#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_OF_TRUTH="$(cd "$REPO_DIR" && pwd)/AGENTS.md"
BACKUP_SUFFIX=".before-dotagents.$(date +%Y%m%d%H%M%S)"

link_config() {
  local source="$1"
  local target="$2"

  [ -e "$source" ] || { printf 'missing source: %s\n' "$source" >&2; exit 1; }
  mkdir -p "$(dirname "$target")"

  if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
    printf 'ok: %s\n' "$target"
    return
  fi

  if [ -L "$target" ]; then
    rm "$target"
  elif [ -e "$target" ]; then
    mv "$target" "$target$BACKUP_SUFFIX"
    printf 'backed up: %s\n' "$target$BACKUP_SUFFIX"
  fi

  ln -s "$source" "$target"
  printf 'linked: %s -> %s\n' "$target" "$source"
}

# One shared agent-instructions source for all agents.
link_config "$SOURCE_OF_TRUTH" "$HOME/.pi/agent/AGENTS.md"
link_config "$SOURCE_OF_TRUTH" "$HOME/.config/opencode/AGENTS.md"
link_config "$SOURCE_OF_TRUTH" "$HOME/.claude/CLAUDE.md"

# Pi global configuration.
link_config "$REPO_DIR/pi/agent/settings.json" "$HOME/.pi/agent/settings.json"
link_config "$REPO_DIR/pi/agent/mcp.json" "$HOME/.pi/agent/mcp.json"
link_config "$REPO_DIR/pi/agent/hide-providers.json" "$HOME/.pi/agent/hide-providers.json"
link_config "$REPO_DIR/pi/agent/extensions/context-cap.json" "$HOME/.pi/agent/extensions/context-cap.json"
link_config "$REPO_DIR/pi/agent/subagents-lite.json" "$HOME/.pi/agent/subagents-lite.json"

# OpenCode global configuration.
link_config "$REPO_DIR/opencode/opencode.jsonc" "$HOME/.config/opencode/opencode.jsonc"

# Claude Code global configuration.
link_config "$REPO_DIR/claude/settings.json" "$HOME/.claude/settings.json"
link_config "$REPO_DIR/claude/statusline.sh" "$HOME/.claude/statusline.sh"
