#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   notify.sh <kind>
# where <kind> is one of:
#   stop | permission_prompt | idle_prompt | elicitation_dialog | auth_success
#
# Claude Code also pipes JSON to stdin for Notification events that includes:
#   message, notification_type, cwd, transcript_path, etc. :contentReference[oaicite:1]{index=1}

KIND_ARG="${1:-}"

payload="$(cat || true)"

# tiny helper to read JSON fields with jq if present, else python3 fallback
json_get() {
  local key="$1"
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$payload" | jq -r "$key // empty" 2>/dev/null || true
  else
    python3 - <<'PY' "$payload" "$key" 2>/dev/null || true
import json,sys
raw=sys.argv[1]
expr=sys.argv[2]
try:
    obj=json.loads(raw) if raw.strip() else {}
except Exception:
    obj={}
# very small parser for expressions like ".message" or ".cwd" (no nesting needed here)
k=expr.strip().lstrip('.').split()[0]
val=obj.get(k,"")
if val is None: val=""
print(val)
PY
  fi
}

notification_type="$(json_get '.notification_type')"
message="$(json_get '.message')"
cwd="$(json_get '.cwd')"

kind="${KIND_ARG:-$notification_type}"

# Include repo/folder name if we can
repo=""
if [[ -n "${cwd:-}" ]]; then
  repo="$(basename "$cwd" 2>/dev/null || true)"
fi

title="Claude Code"
[[ -n "$repo" ]] && title="Claude Code — $repo"

subtitle=""
body=""

case "$kind" in
  stop)
    subtitle="Done"
    body="Claude finished."
    ;;
  permission_prompt)
    subtitle="Permission needed"
    body="${message:-Claude needs your permission.}"
    ;;
  idle_prompt)
    subtitle="Waiting"
    body="${message:-Claude is waiting for your input.}"
    ;;
  elicitation_dialog)
    subtitle="Needs input"
    body="${message:-Claude needs MCP/tool input.}"
    ;;
  auth_success)
    subtitle="Authenticated"
    body="${message:-Claude Code auth succeeded.}"
    ;;
  *)
    # Don’t spam unknown notifications
    exit 0
    ;;
esac

# AppleScript supports: with title, subtitle, sound name. :contentReference[oaicite:2]{index=2}
# Set CLAUDE_NOTIFY_SOUND="" to disable sound.
SOUND_NAME="${CLAUDE_NOTIFY_SOUND:-Glass}"

# Escape for AppleScript string literals
esc() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

t="$(esc "$title")"
s="$(esc "$subtitle")"
b="$(esc "$body")"

if [[ -n "$SOUND_NAME" ]]; then
  snd="$(esc "$SOUND_NAME")"
  /usr/bin/osascript -e "display notification \"${b}\" with title \"${t}\" subtitle \"${s}\" sound name \"${snd}\"" >/dev/null
else
  /usr/bin/osascript -e "display notification \"${b}\" with title \"${t}\" subtitle \"${s}\"" >/dev/null
fi

