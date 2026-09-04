#!/bin/bash
# Statusline badge: ponytail mode.
#
# Usage in ~/.claude/settings.json:
#   "statusLine": { "type": "command", "command": "bash /home/igy/.claude/statusline.sh" }
#
# ponytail writes a single flag; "full" renders as bare [PONYTAIL].

CFG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

# --- ponytail badge -------------------------------------------------------
# ponytail writes the mode to a single flag file. "full" renders as bare
# [PONYTAIL]; off renders as nothing. Matches upstream ponytail-statusline.sh.
PFLAG="$CFG/.ponytail-active"
if [ -f "$PFLAG" ] && [ ! -L "$PFLAG" ]; then
  PMODE=$(head -n1 "$PFLAG" | tr -d '[:space:]')
  case "$PMODE" in
    lite|full|ultra)
      if [ "$PMODE" = "full" ]; then
        printf '\033[38;5;108m[PONYTAIL]\033[0m '
      else
        COLOR=108; [ "$PMODE" = "ultra" ] && COLOR=173
        printf '\033[38;5;%sm[PONYTAIL:%s]\033[0m ' "$COLOR" "$(printf '%s' "$PMODE" | tr '[:lower:]' '[:upper:]')"
      fi
      ;;
  esac
fi

# Always exit 0 — a non-zero exit hides the whole status bar.
exit 0
