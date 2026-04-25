#!/usr/bin/env bash
# compile-agents.sh — reads every spec.yaml and generates harness-specific surfaces.
# Outputs:
#   <skill-dir>/agents/openai.yaml   — OpenAI Agents SDK surface
#   agent.yaml                       — root discovery manifest (gitagent format)
#
# Usage: bash scripts/compile-agents.sh [--dry-run]

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

# Collect all spec.yaml files (exclude test/)
SPECS=$(find "$ROOT" -name "spec.yaml" \
  ! -path "*/test/*" \
  ! -path "*/.git/*" \
  | sort)

if [[ -z "$SPECS" ]]; then
  echo "No spec.yaml files found." && exit 0
fi

MANIFEST_SKILLS=""

for SPEC in $SPECS; do
  SKILL_DIR="$(dirname "$SPEC")"
  AGENTS_DIR="$SKILL_DIR/agents"

  # Parse fields using grep (no yq dependency)
  NAME=$(grep    '^name:'          "$SPEC" | head -1 | sed 's/name:[[:space:]]*//')
  DISPLAY=$(grep '^display_name:'  "$SPEC" | head -1 | sed "s/display_name:[[:space:]]*//;s/['\"]//g")
  DESC=$(grep    '^description:'   "$SPEC" | head -1 | sed "s/description:[[:space:]]*//;s/['\"]//g")
  PROMPT=$(grep  '^default_prompt:' "$SPEC" | head -1 | sed "s/default_prompt:[[:space:]]*//;s/['\"]//g")
  IMPLICIT=$(grep 'implicit:' "$SPEC" | head -1 | sed 's/.*implicit:[[:space:]]*//')

  ALLOW_IMPLICIT="false"
  [[ "$IMPLICIT" == "true" ]] && ALLOW_IMPLICIT="true"

  # ── openai.yaml ──────────────────────────────────────────
  OPENAI_FILE="$AGENTS_DIR/openai.yaml"
  OPENAI_CONTENT="interface:
  display_name: \"$DISPLAY\"
  short_description: \"$DESC\"
  default_prompt: \"$PROMPT\"
policy:
  allow_implicit_invocation: $ALLOW_IMPLICIT
"

  if [[ "$DRY_RUN" == "true" ]]; then
    echo "[dry-run] would write: $OPENAI_FILE"
  else
    mkdir -p "$AGENTS_DIR"
    echo "$OPENAI_CONTENT" > "$OPENAI_FILE"
    echo "  ✓ $NAME → agents/openai.yaml"
  fi

  # Accumulate manifest skill list
  MANIFEST_SKILLS="${MANIFEST_SKILLS}  - ${NAME}"$'\n'
done

# ── root agent.yaml ──────────────────────────────────────────
MANIFEST_FILE="$ROOT/agent.yaml"
MANIFEST_CONTENT="spec_version: \"0.1.0\"
name: claude-craft
version: $(grep '^version' "$ROOT/core/plugins/core-hooks/.claude-plugin/plugin.json" 2>/dev/null | head -1 | grep -o '[0-9.]*' || echo "0.1.0")
description: \"Harness-agnostic skill and agent system for AI-assisted development. Works with Claude Code, OpenAI Agents SDK, Cursor, and any agentic harness.\"
author: pixelcrafts
license: MIT
skills:
${MANIFEST_SKILLS}"

if [[ "$DRY_RUN" == "true" ]]; then
  echo "[dry-run] would write: $MANIFEST_FILE"
  echo "$MANIFEST_CONTENT"
else
  echo "$MANIFEST_CONTENT" > "$MANIFEST_FILE"
  echo ""
  echo "✓ agent.yaml updated with $(echo "$SPECS" | wc -l | tr -d ' ') skill(s)"
fi
