#!/bin/bash
# PreToolUse hook — blocks Task/Agent spawns whose prompt fails the
# warmth check, so the subagent starts warm instead of cold.
#
# The "warmth score" is a proxy for: "could a fresh Claude answer
# this using only what's in the prompt?" Higher score = warmer brief.
#
# Signals (summed):
#   1. Labeled section headers (GOAL/CONTEXT/SCOPE/TASK/OUTPUT/
#      DELIVERABLE/BUDGET) — 1 point each. Accepts "GOAL:", "**Goal**:",
#      "## Goal", "## Goal:", etc. Must appear as a section label,
#      not mid-sentence.
#   2. Triple-backtick code fence — 1 point if present at all. Code
#      pasted into the prompt is strong evidence the parent is
#      handing over context, not asking the subagent to rediscover it.
#   3. File path references (any "dir/file.ext" pattern) — 1 point each,
#      capped at 2. Language-agnostic: no extension allowlist, any path
#      containing a slash and ending in .ext counts.
#
# Scope proxy: prompt length.
#   <400 chars   → trivial lookup, pass through (0 required)
#   400–1500     → medium, require score ≥ 2
#   ≥1500        → heavy, require score ≥ 3
#
# Escape hatch — `.claude/enforcement.json`:
#   { "warm_brief_required": false }
#
# Fail-open on any internal error so a bug here can't strand the user.

set +e

command -v jq >/dev/null 2>&1 || exit 0

INPUT=$(cat 2>/dev/null)
[ -z "$INPUT" ] && exit 0

TOOL=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
case "$TOOL" in
  Task|Agent) : ;;
  *) exit 0 ;;
esac

PROMPT=$(printf '%s' "$INPUT" | jq -r '.tool_input.prompt // empty' 2>/dev/null)
[ -z "$PROMPT" ] && exit 0

# Project-level escape hatch. Walk up parents to find .claude/enforcement.json
# so multi-project session roots still find the right config.
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
  # Read the raw value. jq's `// alt` treats both null and false as "absent",
  # so using `// true` would silently ignore an explicit `false`. Instead,
  # a missing key emits "null" (which does not match "false" below), so the
  # default-on behaviour is preserved without the `//` trap.
  REQUIRED=$(jq -r '.warm_brief_required' "$CONFIG" 2>/dev/null)
  [ "$REQUIRED" = "false" ] && exit 0
fi

PROMPT_LEN=${#PROMPT}

# Trivial prompts pass through — no ceremony required for a short lookup.
if [ "$PROMPT_LEN" -lt 400 ]; then
  exit 0
fi

# Scale the bar by scope.
if [ "$PROMPT_LEN" -ge 1500 ]; then
  REQUIRED_SCORE=3
  SCOPE_LABEL="heavy"
else
  REQUIRED_SCORE=2
  SCOPE_LABEL="medium"
fi

# Signal 1: labeled section headers.
# Accepts "GOAL:" / "**Goal**:" / "## Goal" / "## Goal:" etc.
# End-of-label matches either `:` (inline label) or end-of-line (heading form).
# -o emits each match on its own line; wc -l counts occurrences, not lines.
MARKER_COUNT=$(printf '%s' "$PROMPT" \
  | grep -oiE '(^|[[:space:]*#>-])(goal|context|scope|task|output|deliverable|budget)([[:space:]]*:|[[:space:]]*$)' \
  | wc -l | tr -d ' ')

# Signal 2: triple-backtick code fence (pasted context).
FENCE_PRESENT=0
if printf '%s' "$PROMPT" | grep -q '```'; then
  FENCE_PRESENT=1
fi

# Signal 3: file path references. Language-agnostic — must contain a `/`
# (to exclude bare dotted names) and end in ".ext" where ext is any
# 1–6 char word. The plugin never names specific languages; any stack
# works. Capped at 2 so a long pasted file list can't dominate.
PATH_COUNT=$(printf '%s' "$PROMPT" \
  | grep -oiE '\b[a-z_][a-z0-9_.-]*/[a-z0-9_/.-]*\.[a-z][a-z0-9]{0,6}(:[0-9]+)?\b' \
  | wc -l | tr -d ' ')
[ "$PATH_COUNT" -gt 2 ] && PATH_COUNT=2

SCORE=$((MARKER_COUNT + FENCE_PRESENT + PATH_COUNT))

if [ "$SCORE" -lt "$REQUIRED_SCORE" ]; then
  {
    printf 'Refused to spawn — %s-scope prompt (%d chars) failed the warmth check.\n' "$SCOPE_LABEL" "$PROMPT_LEN"
    printf '  warmth score: %d  (required: %d)\n' "$SCORE" "$REQUIRED_SCORE"
    printf '    labeled sections:   %d\n' "$MARKER_COUNT"
    printf '    code fence present: %d\n' "$FENCE_PRESENT"
    printf '    file paths (cap 2): %d\n\n' "$PATH_COUNT"
    printf 'A cold spawn re-reads files the parent already has, burning\n'
    printf 'tokens and producing shallower work. Add any of:\n\n'
    printf '  * Labeled sections — GOAL / CONTEXT / SCOPE / TASK / OUTPUT\n'
    printf '    / DELIVERABLE / BUDGET (each worth 1 point). Accepts\n'
    printf '    "GOAL:", "**Goal**:", "## Goal".\n'
    printf '  * Code fence — paste the relevant excerpt in a ``` block\n'
    printf '    (worth 1 point — strong warmth signal).\n'
    printf '  * File path references — any "dir/file.ext" pattern, e.g.\n'
    printf '    "path/to/module.ext" or "dir/file.ext:42" (1 each, cap 2).\n\n'
    printf 'Scope thresholds: <400 chars pass through, 400-1500 need 2,\n'
    printf 'equal or greater than 1500 need 3. The highest-leverage fix is\n'
    printf 'almost always pasting the excerpt instead of naming the file.\n\n'
    printf 'See core-standards:subagent-brief for the decision trees and\n'
    printf 'brief template. To disable this check for a project, set\n'
    printf '`"warm_brief_required": false` in .claude/enforcement.json.\n'
  } >&2
  exit 2
fi

exit 0
