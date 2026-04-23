#!/bin/bash
# Blocks Bash commands that write to sensitive files. Exit 2 = block with feedback.
# Fail-open on any internal error so a bug here can't strand the user.

set +e

INPUT=$(cat 2>/dev/null)
[ -z "$INPUT" ] && exit 0

COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -z "$COMMAND" ] && exit 0

# ── allowed_commands check ───────────────────────────────────────────────────
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
    ALLOWED_COMMANDS=$(jq -r '(.allowed_commands // []) | .[]' "$CONFIG" 2>/dev/null)
    if [ -n "$ALLOWED_COMMANDS" ]; then
      while IFS= read -r pattern; do
        [ -z "$pattern" ] && continue
        if printf '%s' "$COMMAND" | grep -qF "$pattern"; then
          ALLOWED_EXEMPT=1
          break
        fi
      done <<< "$ALLOWED_COMMANDS"
    fi
  fi
fi

[ "$ALLOWED_EXEMPT" -eq 1 ] && exit 0

# ── hardcoded protected patterns (defaults) ───────────────────────────────────
PROTECTED=(".env" ".env.local" ".env.production" "credentials" "secrets")

for pattern in "${PROTECTED[@]}"; do
  # Check if command writes/redirects/moves to a protected file
  if printf '%s' "$COMMAND" | grep -qE "(>|>>|mv|cp|tee|echo.*>).*${pattern}"; then
    printf "Blocked: Bash command targets protected file pattern '%s'. Ask the user first.\n" "$pattern" >&2
    exit 2
  fi
done

exit 0
