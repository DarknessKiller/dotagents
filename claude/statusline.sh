#!/bin/bash
# Statusline badges: ponytail + caveman mode.
#
# Usage in ~/.claude/settings.json:
#   "statusLine": { "type": "command", "command": "bash /home/igy/.claude/statusline.sh" }
#
# Claude Code pipes session JSON on stdin. Both plugins' hooks write mode files;
# we read the per-project (ponytail) and per-session (caveman) files so each
# window shows its own mode, not whichever window wrote the shared flag last.

CFG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

IN=""
[ ! -t 0 ] && IFS= read -r -d '' -t 1 IN
SESSION_ID=$(printf '%s' "$IN" | jq -r '.session_id // empty' 2>/dev/null)
PROJECT_DIR=$(printf '%s' "$IN" | jq -r '.workspace.project_dir // .cwd // empty' 2>/dev/null)
case "$SESSION_ID" in ''|*[!A-Za-z0-9_-]*) SESSION_ID="" ;; esac

# Disabled plugin = its hooks don't run, so its flag files are stale.
enabled() {
  [ "$(jq -r --arg p "$1" '.enabledPlugins[$p] // false' "$CFG/settings.json" 2>/dev/null)" = "true" ]
}

# First line of a regular (non-symlink) file, sanitized to [a-z0-9-].
readflag() {
  [ -f "$1" ] && [ ! -L "$1" ] || return 1
  head -c 64 "$1" | head -n1 | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9-'
}

# --- ponytail badge -------------------------------------------------------
# Live mode is keyed by sha256(project dir); shared flag is the fallback.
if enabled "ponytail@ponytail"; then
  PFLAG="$CFG/.ponytail-active"
  if [ -n "$PROJECT_DIR" ]; then
    H=$(printf '%s' "$PROJECT_DIR" | sha256sum | cut -d' ' -f1)
    [ -f "$CFG/ponytail-modes/$H" ] && PFLAG="$CFG/ponytail-modes/$H"
  fi
  case "$(readflag "$PFLAG")" in
    lite)  printf '\033[38;5;108m[PONYTAIL:LITE]\033[0m ' ;;
    full)  printf '\033[38;5;108m[PONYTAIL:FULL]\033[0m ' ;;
    ultra) printf '\033[38;5;173m[PONYTAIL:ULTRA]\033[0m ' ;;
  esac
fi

# --- caveman badge --------------------------------------------------------
# Per-session file first, legacy shared flag as fallback. "off" = no badge.
if enabled "caveman@caveman"; then
  CFLAG="$CFG/.caveman-active"
  [ -n "$SESSION_ID" ] && [ -f "$CFG/.caveman-sessions/$SESSION_ID.mode" ] \
    && CFLAG="$CFG/.caveman-sessions/$SESSION_ID.mode"
  # caveman 4.x writes caveman/ultracave/megacave; lite/full/ultra/wenyan* are
  # legacy values still found in old flag files.
  case "$(readflag "$CFLAG")" in
    lite)              printf '\033[38;5;172m[CAVEMAN:LITE]\033[0m ' ;;
    caveman|full)      printf '\033[38;5;172m[CAVEMAN:FULL]\033[0m ' ;;
    ultracave|ultra)   printf '\033[38;5;173m[CAVEMAN:ULTRACAVE]\033[0m ' ;;
    megacave|wenyan*)  printf '\033[38;5;172m[CAVEMAN:MEGACAVE]\033[0m ' ;;
  esac
fi

# Always exit 0 — a non-zero exit hides the whole status bar.
exit 0
