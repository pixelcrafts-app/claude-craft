#!/bin/bash
# SessionStart hook — inject a pinned mandatory-skills preamble.
#
# Reads the project's .claude/enforcement.json. If absent, exits silently
# (existing non-enforced installs see no change). If present and lists packs,
# reads each pack's default config from $CLAUDE_PLUGIN_ROOT/enforcement/
# and emits a combined additionalContext block telling Claude which skills
# are mandatory, which rules block deterministically, and which gate to run.
#
# Fail-open: any error → exit 0 (existing behavior preserved).

set +e

command -v jq >/dev/null 2>&1 || exit 0

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
CONFIG="$PROJECT_DIR/.claude/enforcement.json"

# Walk up if not at $CLAUDE_PROJECT_DIR.
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

[ ! -f "$CONFIG" ] && exit 0

PACKS=$(jq -r '.mandatory // [] | .[]' "$CONFIG" 2>/dev/null)
[ -z "$PACKS" ] && exit 0

DEFAULTS_DIR="${CLAUDE_PLUGIN_ROOT}/enforcement"
[ ! -d "$DEFAULTS_DIR" ] && exit 0

BODY=""
BODY="${BODY}## Mandatory standards — this project enforces them\n\n"
BODY="${BODY}The project at \`$PROJECT_DIR\` has committed to a **mandatory-skills enforcement mode** (\`.claude/enforcement.json\`). The following rules apply to every edit you make this session:\n\n"

PACK_COUNT=0
while IFS= read -r PACK; do
  [ -z "$PACK" ] && continue
  PACK_FILE="$DEFAULTS_DIR/$PACK.json"
  [ ! -f "$PACK_FILE" ] && continue
  PACK_COUNT=$((PACK_COUNT + 1))

  GATE=$(jq -r '.gate_command // ""' "$PACK_FILE" 2>/dev/null)
  SKILLS=$(jq -r '.mandatory_skills // [] | map("  - " + .) | join("\n")' "$PACK_FILE" 2>/dev/null)
  RULES=$(jq -r '.rules // [] | map("  - `" + .id + "` — " + .message) | join("\n")' "$PACK_FILE" 2>/dev/null)
  TOUCHED=$(jq -r '.file_glob_touched // ""' "$PACK_FILE" 2>/dev/null)

  BODY="${BODY}### \`$PACK\`\n\n"
  BODY="${BODY}**Mandatory skills you MUST apply:**\n${SKILLS}\n\n"
  BODY="${BODY}**Deterministic blocks (PreToolUse — will reject your edit if triggered):**\n${RULES}\n\n"
  if [ -n "$GATE" ] && [ "$GATE" != "null" ]; then
    BODY="${BODY}**Gate:** After edits to \`$TOUCHED\`, you MUST run \`$GATE\` before the turn ends. The Stop hook will block \"done\" until the gate passes. The gate runs the engine (\`core-standards:verify-changes\`) across every rule in this pack and reports PASS / FAIL with evidence.\n\n"
  fi
done <<< "$PACKS"

[ "$PACK_COUNT" -eq 0 ] && exit 0

BODY="${BODY}**What this means practically:**\n"
BODY="${BODY}- Write code that complies with these skills from the first edit. Fix suggestions, don't retry past a block.\n"
BODY="${BODY}- End-of-task: run each pack's gate command. Do not say \"done\" or \"ready to commit\" without them.\n"
BODY="${BODY}- Project override: see \`.claude/enforcement.json\` — users can disable specific rules by ID or turn the gate from blocking to advisory.\n"

# Emit Claude Code SessionStart additionalContext.
printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":%s}}\n' \
  "$(printf '%b' "$BODY" | jq -Rs .)"

exit 0
