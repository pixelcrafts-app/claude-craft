#!/bin/bash
# Blocks Bash commands that write to sensitive files. Exit 2 = block with feedback.
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

PROTECTED=(".env" ".env.local" ".env.production" "credentials" "secrets")

for pattern in "${PROTECTED[@]}"; do
  # Check if command writes/redirects/moves to a protected file
  if echo "$COMMAND" | grep -qE "(>|>>|mv|cp|tee|echo.*>).*${pattern}"; then
    echo "Blocked: Bash command targets protected file pattern '$pattern'. Ask the user first." >&2
    exit 2
  fi
done

exit 0
