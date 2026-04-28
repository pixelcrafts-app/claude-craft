#!/bin/bash
# Blocks edits to sensitive files. Exit 2 = block with feedback.
# Fail-open on any internal error so a bug here can't strand the user.

set +e

INPUT=$(cat 2>/dev/null)
[ -z "$INPUT" ] && exit 0

FILE=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
[ -z "$FILE" ] && exit 0

# ── allowed_files check ──────────────────────────────────────────────────────
# Walk up parents to find .claude/enforcement.json (same pattern as
# enforce-subagent-brief.sh and stop-gate.sh — max 20 hops).
ALLOWED_EXEMPT=0
if command -v jq >/dev/null 2>&1; then
  PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
  CONFIG="$PROJECT_DIR/.claude/enforcement.json"
  if [ ! -f "$CONFIG" ]; then
    DIR="$PWD"
    HOPS=0
    while [ "$DIR" != "/" ] && [ "$DIR" != "." ] && [ -n "$DIR" ] && [ $HOPS -lt 20 ]; do
      if [ -f "$DIR/.claude/enforcement.json" ]; then
        CONFIG="$DIR/.claude/enforcement.json"
        break
      fi
      DIR=$(dirname "$DIR")
      HOPS=$((HOPS + 1))
    done
  fi

  if [ -f "$CONFIG" ]; then
    ALLOWED_FILES=$(jq -r '(.allowed_files // []) | .[]' "$CONFIG" 2>/dev/null)
    if [ -n "$ALLOWED_FILES" ]; then
      while IFS= read -r pattern; do
        [ -z "$pattern" ] && continue
        if [[ "$FILE" == *"$pattern"* ]]; then
          ALLOWED_EXEMPT=1
          break
        fi
      done <<< "$ALLOWED_FILES"
    fi
  fi
fi

[ "$ALLOWED_EXEMPT" -eq 1 ] && exit 0

# ── hardcoded protected patterns (defaults) ───────────────────────────────────
PROTECTED=(".env" ".env.local" ".env.production" ".env.staging" "credentials" "secrets" "service-account" ".pem" ".key" ".p12")

for pattern in "${PROTECTED[@]}"; do
  if [[ "$FILE" == *"$pattern"* ]]; then
    printf 'Protected file: %s — do not edit directly. Ask the user first.\n' "$FILE" >&2
    exit 2
  fi
done

exit 0
