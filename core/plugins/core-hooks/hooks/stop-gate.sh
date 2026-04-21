#!/bin/bash
# Stop hook — blocks the turn-end if a mandatory pack has uncommitted
# enforcement work. A pack is "touched" when a tracked file was about to be
# edited; it becomes "gate_passed" when the pack's gate command (e.g.
# /flutter-standards:pre-ship) reports SAFE TO COMMIT and writes the ledger.
#
# Exit 2 keeps Claude's turn open with the emitted stderr message. Fail-open
# on any error so a bug in this hook can't strand the user.
#
# Respects project config: gate_required: false → advisory only, hook doesn't
# block.

set +e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
. "$SCRIPT_DIR/session-ledger.sh"

command -v jq >/dev/null 2>&1 || exit 0

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

PACKS=$(jq -r '.mandatory // [] | .[]' "$CONFIG" 2>/dev/null)
[ -z "$PACKS" ] && exit 0

GATE_REQUIRED=$(jq -r '.gate_required // true' "$CONFIG" 2>/dev/null)
# Treat any non-"false" as required.
[ "$GATE_REQUIRED" = "false" ] && exit 0

DEFAULTS_DIR="${CLAUDE_PLUGIN_ROOT}/enforcement"
[ ! -d "$DEFAULTS_DIR" ] && exit 0

MISSING=""

while IFS= read -r PACK; do
  [ -z "$PACK" ] && continue
  PACK_FILE="$DEFAULTS_DIR/$PACK.json"
  [ ! -f "$PACK_FILE" ] && continue

  GATE_CMD=$(jq -r '.gate_command // ""' "$PACK_FILE" 2>/dev/null)
  [ -z "$GATE_CMD" ] || [ "$GATE_CMD" = "null" ] && continue

  if ledger_has "$PACK" "touched" && ! ledger_has "$PACK" "gate_passed"; then
    MISSING="${MISSING}- [$PACK] Files were edited this session but \`$GATE_CMD\` has not passed. Run it now and return with the verdict.\n"
  fi
done <<< "$PACKS"

if [ -n "$MISSING" ]; then
  {
    printf 'Cannot end turn — mandatory gates unmet:\n\n'
    printf '%b' "$MISSING"
    printf '\nOnce each gate reports SAFE TO COMMIT, the Stop block lifts automatically.\n'
    printf 'To make gates advisory (non-blocking), set `"gate_required": false` in `.claude/enforcement.json`.\n'
  } >&2
  exit 2
fi

exit 0
