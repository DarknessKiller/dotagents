#!/bin/bash
# Statusline badges: ponytail + caveman mode, plus rows of skills used in this chat.
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

# --- skills used this session (own rows) ---------------------------------
# Skill tool calls (Claude) and slash commands (you) in this chat, counted.
# Rows wrap at the terminal width so nothing is cut off.
TRANSCRIPT=$(printf '%s' "$IN" | jq -r '.transcript_path // empty' 2>/dev/null)
if [ -f "$TRANSCRIPT" ]; then
  # "name<TAB>count" per skill, first-use order; plugin prefix dropped (ponytail:x -> x).
  counted() { sed 's/^.*://' | awk 'NF && !($0 in n){o[++k]=$0} NF{n[$0]++} END{for(i=1;i<=k;i++) print o[i] "\t" n[o[i]]}'; }
  # Real events only: Claude's Skill tool calls and prompts you typed as /command,
  # main chat (no subagents). Parsed incrementally: only bytes added since the last
  # refresh are read. Cache file: line 1 = byte offset read so far, then events.
  CACHE="$CFG/.statusline-skills"; mkdir -p "$CACHE"
  find "$CACHE" -type f -mtime +14 -delete 2>/dev/null
  EV="$CACHE/$(basename "$TRANSCRIPT" .jsonl).ev"
  # One open fd = one snapshot of offset + events, even if another refresh replaces the file.
  { exec 3< "$EV"; } 2>/dev/null || exec 3< /dev/null
  read -r OFF <&3; SIZE=$(wc -c < "$TRANSCRIPT" | tr -d ' ')
  case "$OFF" in ''|*[!0-9]*) OFF=0 ;; esac
  [ "$SIZE" -lt "$OFF" ] && OFF=0   # transcript rewritten: start over
  if [ "$SIZE" -gt "$OFF" ]; then
    # Read exactly the measured range; bytes Claude appends meanwhile wait for next refresh.
    CHUNK=$(mktemp "$CACHE/chunk.XXXXXX"); NEW=$(mktemp "$CACHE/ev.XXXXXX")
    tail -c +$((OFF + 1)) "$TRANSCRIPT" | head -c $((SIZE - OFF)) > "$CHUNK"
    # A line still being written is left for the next refresh.
    PART=0; [ -n "$(tail -c 1 "$CHUNK")" ] && PART=$(tail -n 1 "$CHUNK" | wc -c | tr -d ' ')
    {
      echo $((SIZE - PART))
      [ "$OFF" -gt 0 ] && cat <&3
      # Complete lines only: a finished JSON line still missing its newline is counted next time.
      [ $((SIZE - OFF - PART)) -gt 0 ] && head -c $((SIZE - OFF - PART)) "$CHUNK" |
        grep -E '"name":"Skill"|command-name>' | jq -Rr '
        fromjson? | select(.isSidechain != true) | select(.type == "assistant" or .type == "user") |
        if .type == "assistant" then
          .message.content[]? | select(.type? == "tool_use" and .name == "Skill") | "claude " + .input.skill
        else
          # Typed skills start with <command-message>; built-ins (/model, /clear...) do not.
          .message.content | strings |
          if startswith("<command-name>/clear</command-name>") then "CLEAR"
          else capture("^<command-message>[^<]*</command-message>\\s*<command-name>/?(?<c>[^<]+)</command-name>")? | "you " + .c end
        end' 2>/dev/null
    } > "$NEW"
    # Atomic replace: overlapping refreshes write the same content, never append twice.
    mv -f "$NEW" "$EV"; rm -f "$CHUNK"
  fi
  exec 3<&-
  # Only what came after the last /clear.
  EVENTS=$(tail -n +2 "$EV" 2>/dev/null | awk '/^CLEAR$/{n=0; next} {l[++n]=$0} END{for(i=1;i<=n;i++) print l[i]}')
  CLAUDE=$(printf '%s\n' "$EVENTS" | sed -n 's/^claude //p' | counted)
  TYPED=$(printf '%s\n' "$EVENTS" | sed -n 's/^you //p' | counted)
  COLS=${COLUMNS:-80}   # Claude Code sets COLUMNS for the status line command
  [ "$COLS" -gt 20 ] 2>/dev/null || COLS=80
  # label, list: own row(s). Label column fixed, items wrap under the first item.
  # Width counts visible text only; colour is added after.
  row() {
    [ -n "$2" ] || return 0
    printf '%s\n' "$2" | awk -F'\t' -v label="$1" -v w="$COLS" '
      BEGIN { pad = 8; D = "\033[38;5;245m"; N = "\033[38;5;110m"; R = "\033[0m"; SEP = " · " }
      { name[NR] = $1; cnt[NR] = $2 }
      END {
        out = D sprintf("%-" pad "s", label) R; used = pad; first = 1
        for (i = 1; i <= NR; i++) {
          vis = name[i] (cnt[i] > 1 ? " ×" cnt[i] : "")
          txt = N name[i] R (cnt[i] > 1 ? D " ×" cnt[i] R : "")
          need = (first ? 0 : 3) + length(vis)
          if (!first && used + need > w - 1) {
            out = out "\n" sprintf("%" pad "s", ""); used = pad; first = 1; need = length(vis)
          }
          out = out (first ? "" : D SEP R) txt; used += need; first = 0
        }
        printf "\n%s", out
      }'
  }
  row "Claude:" "$CLAUDE"
  row "User:" "$TYPED"
fi

# Always exit 0 — a non-zero exit hides the whole status bar.
exit 0
