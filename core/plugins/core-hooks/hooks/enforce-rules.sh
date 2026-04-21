#!/bin/bash
# PreToolUse hook — applies each mandatory pack's deterministic rule registry
# to Edit / Write / MultiEdit targets. Exit 2 on block, exit 0 otherwise.
#
# This is the generic enforcement layer: core-hooks ships pack defaults under
# $CLAUDE_PLUGIN_ROOT/enforcement/<pack>.json, the project opts into them via
# .claude/enforcement.json, and this hook runs the rules.
#
# Fail-open: any error / missing jq / missing config → exit 0.
# This hook also marks the pack as "touched" in the session ledger so the
# Stop-gate hook can enforce "did you run the gate?" at turn-end.

set +e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
. "$SCRIPT_DIR/session-ledger.sh"

command -v jq >/dev/null 2>&1 || exit 0

INPUT=$(cat 2>/dev/null)
[ -z "$INPUT" ] && exit 0

TOOL=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
FILE=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
[ -z "$FILE" ] && exit 0

CONTENT=$(printf '%s' "$INPUT" | jq -r '
  [
    (.tool_input.content // empty),
    (.tool_input.new_string // empty),
    ((.tool_input.edits // []) | map(.new_string // empty) | join("\n"))
  ] | join("\n")
' 2>/dev/null)

# Build artifacts — never scan.
case "$FILE" in
  */node_modules/*|*/.next/*|*/.turbo/*|*/dist/*|*/build/*|*/out/*|*/.git/*) exit 0 ;;
esac

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

DISABLED=$(jq -r '.disabled_rules // [] | .[]' "$CONFIG" 2>/dev/null)

DEFAULTS_DIR="${CLAUDE_PLUGIN_ROOT}/enforcement"
[ ! -d "$DEFAULTS_DIR" ] && exit 0

# Helper: glob match. Comma-separated globs. For each glob:
#   - basename patterns (no "/") match the file's basename
#   - path patterns (with "/") match anywhere in the path suffix:
#       ** → .*   *  → [^/]*   ?  → .
_glob_match() {
  local file="$1" globs="$2"
  local IFS=','
  # shellcheck disable=SC2086
  for g in $globs; do
    g=$(printf '%s' "$g" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    [ -z "$g" ] && continue
    case "$g" in
      */*)
        # Glob → ERE. Escape regex metachars, then translate wildcards.
        # /**/  → /(.*/)?   (zero or more path segments)
        # **    → .*        (across segments)
        # *     → [^/]*     (within one segment)
        # ?     → .
        local re
        re=$(printf '%s' "$g" \
          | sed -e 's/\./\\./g' \
                -e 's/\^/\\^/g' \
                -e 's/\$/\\$/g' \
                -e 's/+/\\+/g' \
                -e 's/(/\\(/g' \
                -e 's/)/\\)/g' \
                -e 's/{/\\{/g' \
                -e 's/}/\\}/g' \
                -e 's/|/\\|/g' \
                -e 's|/\*\*/|/__GS__|g' \
                -e 's|\*\*|__GG__|g' \
                -e 's|\*|[^/]*|g' \
                -e 's|?|.|g' \
                -e 's|__GS__|(.*/)?|g' \
                -e 's|__GG__|.*|g')
        if printf '%s' "$file" | grep -qE "(^|/)${re}$"; then
          return 0
        fi
        ;;
      *)
        case "$(basename "$file")" in
          $g) return 0 ;;
        esac
        ;;
    esac
  done
  return 1
}

VIOLATIONS=""

while IFS= read -r PACK; do
  [ -z "$PACK" ] && continue
  PACK_FILE="$DEFAULTS_DIR/$PACK.json"
  [ ! -f "$PACK_FILE" ] && continue

  TOUCHED_GLOB=$(jq -r '.file_glob_touched // ""' "$PACK_FILE" 2>/dev/null)
  if [ -n "$TOUCHED_GLOB" ] && _glob_match "$FILE" "$TOUCHED_GLOB"; then
    ledger_mark_touched "$PACK"
  fi

  [ -z "$CONTENT" ] && continue

  RULE_COUNT=$(jq -r '.rules | length' "$PACK_FILE" 2>/dev/null)
  [ -z "$RULE_COUNT" ] && continue
  [ "$RULE_COUNT" -eq 0 ] && continue

  i=0
  while [ "$i" -lt "$RULE_COUNT" ]; do
    RID=$(jq -r ".rules[$i].id // empty" "$PACK_FILE" 2>/dev/null)
    RPAT=$(jq -r ".rules[$i].pattern // empty" "$PACK_FILE" 2>/dev/null)
    RMSG=$(jq -r ".rules[$i].message // empty" "$PACK_FILE" 2>/dev/null)
    RGLOB=$(jq -r ".rules[$i].applies_to // empty" "$PACK_FILE" 2>/dev/null)
    i=$((i + 1))
    [ -z "$RID" ] || [ -z "$RPAT" ] && continue

    # Honor project-disabled rule IDs.
    if [ -n "$DISABLED" ]; then
      DISABLED_HIT=0
      while IFS= read -r D; do
        [ "$D" = "$RID" ] && DISABLED_HIT=1 && break
      done <<< "$DISABLED"
      [ "$DISABLED_HIT" -eq 1 ] && continue
    fi

    # File-glob scope (per-rule).
    if [ -n "$RGLOB" ] && ! _glob_match "$FILE" "$RGLOB"; then
      continue
    fi

    if printf '%s' "$CONTENT" | grep -qE "$RPAT" 2>/dev/null; then
      VIOLATIONS="${VIOLATIONS}- [$PACK :: $RID] $RMSG\n"
    fi
  done
done <<< "$PACKS"

if [ -n "$VIOLATIONS" ]; then
  {
    printf 'Mandatory-rule violations in %s:\n\n' "$FILE"
    printf '%b' "$VIOLATIONS"
    printf '\nFix the flagged pattern(s) and retry the edit.\n'
    printf 'To disable a rule for this project, add its ID to `disabled_rules` in `.claude/enforcement.json`.\n'
  } >&2
  exit 2
fi

exit 0
