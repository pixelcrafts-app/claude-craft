#!/bin/bash
# Blocks edits to sensitive files. Exit 2 = block with feedback.
INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

PROTECTED=(".env" ".env.local" ".env.production" ".env.staging" "credentials" "secrets" "service-account" ".pem" ".key" ".p12")

for pattern in "${PROTECTED[@]}"; do
  if [[ "$FILE" == *"$pattern"* ]]; then
    echo "Protected file: $FILE — do not edit directly. Ask the user first." >&2
    exit 2
  fi
done

exit 0
