#!/bin/bash
# plan-required.sh — PreToolUse hook for Edit / Write / MultiEdit.
#
# Blocks multi-file work without a `<!-- craft:plan` block in the conversation
# transcript. Plan format and content are defined by `core-standards:planning`.
# This hook does not invent a format — it only enforces presence.
#
# Opt-in via .claude/enforcement.json:
#   { "plan_required": true,     "plan_threshold": 3 }     # presence-only
#   { "plan_required": "strict", "plan_threshold": 3 }     # presence + shape
#
# Default threshold (3): the third unique non-trivial file modified in a
# session triggers the gate. Trivial files (*.md, *.json, lockfiles, tests,
# generated dirs) do not count toward the threshold.
#
# Modes:
#   true     — plan-presence check only. Once any <!-- craft:plan block
#              exists in the transcript, gate clears for the session.
#   "strict" — plan-presence + plan-shape check. A plan with ≥ 3
#              deliverables MUST also include a routing decision
#              (a "Routing:" line in the assistant text OR a routing:
#              field inside the plan block). Plans missing the routing
#              line for 3+ deliverables continue to block until fixed.
#              Plans with 1-2 deliverables don't need routing.
#
# Exit 2 → block, stderr instructs Claude to write a plan first.
# Fail-open: any error / missing jq / missing config → exit 0. A bug in this
# hook can never strand the user.

set +e

command -v jq >/dev/null 2>&1 || exit 0

# ── Setup ────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
. "$SCRIPT_DIR/session-ledger.sh"

INPUT=$(cat 2>/dev/null)
[ -z "$INPUT" ] && exit 0

# ── Parse the tool call ─────────────────────────────────────────────────────
FILE=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
[ -z "$FILE" ] && exit 0

# ── Skip trivial files (don't count toward threshold) ───────────────────────
case "$FILE" in
  *.md|*.json|*.yaml|*.yml|*.txt|*.lock|*.gitignore|*.toml) exit 0 ;;
  */.claude/*|*/node_modules/*|*/.git/*|*/build/*|*/dist/*|*/.next/*|*/out/*|*/.dart_tool/*|*/.turbo/*) exit 0 ;;
  *_test.dart|*.test.ts|*.test.js|*.test.tsx|*.spec.ts|*.spec.js|*.spec.tsx|*_test.go|*_test.py|test_*.py) exit 0 ;;
  */test/*|*/tests/*|*/spec/*|*/__tests__/*) exit 0 ;;
esac

# ── Locate enforcement.json (opt-in mechanism) ──────────────────────────────
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
CONFIG="$PROJECT_DIR/.claude/enforcement.json"
if [ ! -f "$CONFIG" ]; then
  DIR="$PWD"
  HOPS=0
  while [ "$DIR" != "/" ] && [ "$DIR" != "." ] && [ -n "$DIR" ] && [ $HOPS -lt 20 ]; do
    if [ -f "$DIR/.claude/enforcement.json" ]; then
      CONFIG="$DIR/.claude/enforcement.json"
      PROJECT_DIR="$DIR"
      break
    fi
    DIR=$(dirname "$DIR")
    HOPS=$((HOPS + 1))
  done
fi
[ ! -f "$CONFIG" ] && exit 0

PLAN_REQUIRED=$(jq -r '.plan_required // false' "$CONFIG" 2>/dev/null)
case "$PLAN_REQUIRED" in
  true|strict) ;;
  *) exit 0 ;;
esac

THRESHOLD=$(jq -r '.plan_threshold // 3' "$CONFIG" 2>/dev/null)
# Sanity: threshold must be a positive integer.
case "$THRESHOLD" in ''|*[!0-9]*) THRESHOLD=3 ;; esac
[ "$THRESHOLD" -lt 1 ] && THRESHOLD=3

# ── Plan-presence checks (clear the gate if satisfied) ──────────────────────
# (1) Ledger flag set earlier this session → clear.
if ledger_has "plan-required" "satisfied"; then
  exit 0
fi

# (2) Transcript contains a plan marker → check presence (and shape in strict mode).
TRANSCRIPT="${CLAUDE_TRANSCRIPT_PATH:-}"
[ -z "$TRANSCRIPT" ] && TRANSCRIPT=$(printf '%s' "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)

if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
  ASSISTANT_TEXT=$(jq -r 'select(.role=="assistant") | .content[]? | select(.type=="text") | .text' "$TRANSCRIPT" 2>/dev/null)

  if printf '%s' "$ASSISTANT_TEXT" | grep -q '<!-- craft:plan'; then
    # Plan exists. In strict mode, also validate shape before clearing.
    if [ "$PLAN_REQUIRED" = "strict" ]; then
      PLAN_BLOCK=$(printf '%s' "$ASSISTANT_TEXT" | awk '/<!-- craft:plan/,/-->/')
      DELIVERABLE_COUNT=$(printf '%s' "$PLAN_BLOCK" | grep -cE '^[[:space:]]*-[[:space:]]+id:')
      case "$DELIVERABLE_COUNT" in ''|*[!0-9]*) DELIVERABLE_COUNT=0 ;; esac

      if [ "$DELIVERABLE_COUNT" -ge 3 ]; then
        # 3+ deliverables — routing decision is required.
        # Routing line acceptable anywhere in assistant text (prose before
        # the block) OR as a `routing:` field inside the YAML block.
        HAS_ROUTING=$(printf '%s' "$ASSISTANT_TEXT" | grep -cE '(^|[[:space:]])[Rr]outing:')
        case "$HAS_ROUTING" in ''|*[!0-9]*) HAS_ROUTING=0 ;; esac

        if [ "$HAS_ROUTING" -eq 0 ]; then
          cat >&2 <<EOF
[plan-required:strict] Plan has ${DELIVERABLE_COUNT} deliverables but no Routing decision.

A plan with 3+ deliverables must include a routing decision per
core-standards:planning Step 0 — inline vs parallel agents vs sequential agents.

Add a Routing line BEFORE the <!-- craft:plan block (or as a top-level
\`routing:\` field inside the block):

  Routing: <N> parallel agents / sequential — reason: <why inline is insufficient>
  Agent 1: <scope>
  Agent 2: <scope>
  Dependency: <independent | agent 2 waits for agent 1>

Inline by reflex on this scope is the failure mode this gate exists to prevent.

To soften to presence-only: change 'plan_required: "strict"' to 'plan_required: true'
in .claude/enforcement.json.
EOF
          exit 2
        fi
      fi
    fi

    # Plan present (and shape valid if strict) → clear the gate.
    ledger_init
    ledger_set "plan-required" "satisfied"
    exit 0
  fi
fi

# ── Track unique files touched this session ─────────────────────────────────
ledger_init
FILE_LIST="$(ledger_dir)/plan-required.files"
touch "$FILE_LIST" 2>/dev/null

if ! grep -qxF -- "$FILE" "$FILE_LIST" 2>/dev/null; then
  printf '%s\n' "$FILE" >> "$FILE_LIST"
fi

COUNT=$(wc -l < "$FILE_LIST" 2>/dev/null | tr -d ' ')
case "$COUNT" in ''|*[!0-9]*) exit 0 ;; esac

# Below threshold → allow
[ "$COUNT" -lt "$THRESHOLD" ] && exit 0

# ── Block: significant work without a plan ──────────────────────────────────
cat >&2 <<EOF
[plan-required] Blocked: about to touch file #${COUNT} this session without a plan block.

Threshold is ${THRESHOLD} non-trivial files. Significant multi-file work
requires a craft:plan block in the conversation first
(see core-standards:planning for the full format).

Minimal block — write in your next response BEFORE any further Edit/Write:

  <!-- craft:plan
  deliverables:
    - id: D1
      description: "what will exist when this is done"
      files: [path/to/file.ext]
      verification: "Bash: <compile or test command>"
    - id: D2
      description: "..."
      files: [...]
      verification: "..."
  scope_boundary: "what is explicitly NOT in scope"
  -->

Once any plan marker appears in the conversation, this gate clears for the
session — no need to re-emit it for subsequent edits.

Opt-out for this project: set 'plan_required: false' in .claude/enforcement.json
EOF
exit 2
