#!/bin/bash
# Combined statusline badge: ponytail + caveman modes.
#
# Usage in ~/.claude/settings.json:
#   "statusLine": { "type": "command", "command": "bash /home/igy/.claude/statusline.sh" }
#
# Each plugin ships its own statusline script; this combines both so the
# status bar shows either badge without one plugin clobbering the other.

CFG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

# --- ponytail badge -------------------------------------------------------
# ponytail writes a single flag; "full" renders as bare [PONYTAIL].
PFLAG="$CFG/.ponytail-active"
if [ -f "$PFLAG" ] && [ ! -L "$PFLAG" ]; then
  PMODE=$(head -c 64 "$PFLAG" 2>/dev/null | tr -d '\n\r')
  case "$PMODE" in
    lite|ultra|full|off)
      printf '\033[38;5;108m[PONYTAIL:%s]\033[0m ' "$(printf '%s' "$PMODE" | tr '[:lower:]' '[:upper:]')"
      ;;
  esac
fi

# --- caveman badge --------------------------------------------------------
# Reads the per-session mode file so this window's mode shows, falling back to
# the legacy mirror flag. "full" renders as bare [CAVEMAN]; off = nothing.
SESSION_ID=""
if [ ! -t 0 ]; then
  IFS= read -r -d '' -t 1 CAVEMAN_STDIN
  SESSION_ID=$(printf '%s' "$CAVEMAN_STDIN" \
    | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' \
    | head -1 \
    | sed -e 's/.*:[[:space:]]*"//' -e 's/"$//')
fi
case "$SESSION_ID" in
  ''|*[!A-Za-z0-9_-]*) SESSION_ID="" ;;
esac
[ "${#SESSION_ID}" -gt 128 ] && SESSION_ID=""

CFLAG="$CFG/.caveman-active"
if [ -n "$SESSION_ID" ] && [ -f "$CFG/.caveman-sessions/$SESSION_ID.mode" ]; then
  CFLAG="$CFG/.caveman-sessions/$SESSION_ID.mode"
fi

if [ -f "$CFLAG" ] && [ ! -L "$CFLAG" ]; then
  CMODE=$(head -c 64 "$CFLAG" 2>/dev/null | tr -d '\n\r' | tr '[:lower:]' '[:upper:]')
  case "$CMODE" in
    ''|*[!A-Za-z_-]*) ;;
    *) printf '\033[38;5;172m[CAVEMAN:%s]\033[0m ' "$CMODE" ;;
  esac
fi

# Always exit 0 — a non-zero exit hides the whole status bar.
exit 0
