#!/bin/bash
# parallel-hint.sh — UserPromptSubmit hook.
#
# Detects multi-file / multi-domain wording in the user's task and injects
# additionalContext that surfaces planning:Step 0 (route inline vs agents)
# and subagent-brief. This is a NUDGE — it never blocks and never spawns.
# The actual decision to spawn agents stays with Claude per subagent-brief.
#
# Solves the user-facing concern "agents are not spawning automatically":
# the system can't force a spawn, but it can make sure Claude is reminded
# of the parallel-agent path before deciding to go inline by reflex.
#
# Default: ON (low friction, non-blocking).
# Opt-out: .claude/enforcement.json { "parallel_hint": false }
#
# Fail-open: any error → exit 0. Never blocks or alters the user's prompt.

set +e

command -v jq >/dev/null 2>&1 || exit 0

INPUT=$(cat 2>/dev/null)
[ -z "$INPUT" ] && exit 0

PROMPT=$(printf '%s' "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)
[ -z "$PROMPT" ] && exit 0

# ── Honor opt-out ───────────────────────────────────────────────────────────
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
  # jq // gotcha: false is treated as null. Use has() + tostring for true-default.
  ENABLED=$(jq -r 'if has("parallel_hint") then (.parallel_hint | tostring) else "true" end' "$CONFIG" 2>/dev/null)
  [ "$ENABLED" = "false" ] && exit 0
fi

# ── Heuristic: words that suggest multi-file / multi-domain scope ───────────
# These are deliberately broad — false positives just add a one-line reminder
# to context; false negatives are the real cost (the user wanted parallel
# agents and didn't get them).
#
# Patterns are case-insensitive and matched against the raw prompt.

PROMPT_LC=$(printf '%s' "$PROMPT" | tr '[:upper:]' '[:lower:]')

# Multi-file verbs
PATTERN_VERBS='audit|refactor|migrate|sweep|rename|scaffold|generate|rewrite|restructure|reorganize'
# Cross-scope quantifiers
PATTERN_SCOPE='all files|every file|across (the |all |each )|whole (project|codebase|app|repo)|entire (project|codebase|app|repo)|each module|all modules'
# Compound work signals
PATTERN_COMPOUND='create .{1,40} and (also |then )?(implement|add|wire|integrate)|implement .{1,40} and (also |then )?(test|verify|deploy)'
# Multi-domain
PATTERN_DOMAIN='web and (api|backend|server)|frontend and backend|mobile and (api|web|server)|client and server'

MATCHED=0
for PAT in "$PATTERN_VERBS" "$PATTERN_SCOPE" "$PATTERN_COMPOUND" "$PATTERN_DOMAIN"; do
  if printf '%s' "$PROMPT_LC" | grep -qE -- "$PAT"; then
    MATCHED=1
    break
  fi
done

[ "$MATCHED" = "0" ] && exit 0

# ── Inject reminder via additionalContext ───────────────────────────────────
cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "[parallel-hint] The task wording suggests multi-file or multi-domain scope. Before starting inline work, consult core-standards:planning Step 0 (the routing decision: inline vs parallel agents vs sequential agents). If the route is agents, write the warm briefs per core-standards:subagent-brief BEFORE any Edit/Write — agent briefs first, then spawn, then inline continues with their findings. Going inline by reflex on a task this wide is the failure mode this hint exists to prevent."
  }
}
EOF
exit 0
