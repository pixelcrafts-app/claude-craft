#!/bin/bash
# PreToolUse enforcer — blocks Edit/Write/MultiEdit that embed raw design values
# in projects that have a token system. The specific patterns blocked are
# defined by the regex rules below (web = Tailwind, flutter = Dart) and belong
# to the stack skill packs, not this hook — this file only enforces them.
#
# Fail-open: any error, missing jq, undetected stack → exit 0 (never block
# because of a hook bug). Exit 2 only on concrete violations.

set +e

INPUT=$(cat 2>/dev/null)
[ -z "$INPUT" ] && exit 0

command -v jq >/dev/null 2>&1 || exit 0

TOOL=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
FILE=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

# Aggregate content being written across Write/Edit/MultiEdit shapes.
CONTENT=$(printf '%s' "$INPUT" | jq -r '
  [
    (.tool_input.content // empty),
    (.tool_input.new_string // empty),
    ((.tool_input.edits // []) | map(.new_string // empty) | join("\n"))
  ] | join("\n")
' 2>/dev/null)

[ -z "$FILE" ] && exit 0
[ -z "$CONTENT" ] && exit 0

# Build artifacts — not user-authored production code. Never scan.
case "$FILE" in
  */node_modules/*|*/.next/*|*/.turbo/*|*/dist/*|*/build/*|*/out/*|*/.git/*) exit 0 ;;
esac

# --- Detect project stack by walking up from FILE ---
DIR=$(dirname "$FILE")
STACK=""
HOPS=0
while [ "$DIR" != "/" ] && [ "$DIR" != "." ] && [ -n "$DIR" ] && [ $HOPS -lt 20 ]; do
  if [ -f "$DIR/pubspec.yaml" ]; then STACK="flutter"; break; fi
  if [ -f "$DIR/package.json" ]; then
    if grep -q '"tailwindcss"' "$DIR/package.json" 2>/dev/null; then
      STACK="web"
      break
    fi
    STACK="_node_no_tailwind"  # node project without tailwind — don't enforce
    break
  fi
  DIR=$(dirname "$DIR")
  HOPS=$((HOPS + 1))
done

[ -z "$STACK" ] && exit 0
[ "$STACK" = "_node_no_tailwind" ] && exit 0

VIOLATIONS=""

if [ "$STACK" = "web" ]; then
  case "$FILE" in
    *.tsx|*.jsx|*.ts|*.js|*.mjs|*.cjs) ;;
    *) exit 0 ;;
  esac

  HEX=$(printf '%s' "$CONTENT" | grep -oE '#[0-9a-fA-F]{6}\b' | sort -u | head -5)
  [ -n "$HEX" ] && VIOLATIONS="${VIOLATIONS}- Hex colors ($(printf '%s' "$HEX" | tr '\n' ' ')) — use a Tailwind theme color class or a CSS variable from globals.css.\n"

  ARB=$(printf '%s' "$CONTENT" | grep -oE '\b(p|m|px|py|pt|pb|pl|pr|mx|my|mt|mb|ml|mr|w|h|min-w|min-h|max-w|max-h|gap|gap-x|gap-y|text|bg|border|border-[tlbr]|rounded|rounded-[tlbr]|shadow|leading|tracking|top|bottom|left|right|inset|z|ring|ring-offset|space-x|space-y|divide-x|divide-y)-\[[^]]+\]' | sort -u | head -5)
  [ -n "$ARB" ] && VIOLATIONS="${VIOLATIONS}- Arbitrary Tailwind values ($(printf '%s' "$ARB" | tr '\n' ' ')) — use a token class or extend tailwind.config.\n"

  RGBHSL=$(printf '%s' "$CONTENT" | grep -oE '\b(rgb|hsl)a?\([^)]*[0-9][^)]*\)' | sort -u | head -3)
  [ -n "$RGBHSL" ] && VIOLATIONS="${VIOLATIONS}- Raw rgb()/hsl() literals — use the theme color or a CSS variable.\n"

elif [ "$STACK" = "flutter" ]; then
  case "$FILE" in *.dart) ;; *) exit 0 ;; esac

  COLR=$(printf '%s' "$CONTENT" | grep -oE 'Color\(0x[0-9a-fA-F]{6,8}\)' | sort -u | head -5)
  [ -n "$COLR" ] && VIOLATIONS="${VIOLATIONS}- Raw Color(0x…) literals ($(printf '%s' "$COLR" | tr '\n' ' ')) — use AppColors.* from your shared color tokens.\n"

  EI=$(printf '%s' "$CONTENT" | grep -oE 'EdgeInsets\.(all|only|symmetric|fromLTRB)\([^)]*[0-9][^)]*\)' | sort -u | head -5)
  [ -n "$EI" ] && VIOLATIONS="${VIOLATIONS}- EdgeInsets with raw pixel values — use AppSpacing.* tokens.\n"

  SB=$(printf '%s' "$CONTENT" | grep -oE 'SizedBox\([^)]*(width|height):\s*[0-9]+' | sort -u | head -5)
  [ -n "$SB" ] && VIOLATIONS="${VIOLATIONS}- SizedBox with raw pixel values — use AppSpacing.* or Gap/Spacer widgets.\n"

  FS=$(printf '%s' "$CONTENT" | grep -oE 'fontSize:\s*[0-9]+' | sort -u | head -5)
  [ -n "$FS" ] && VIOLATIONS="${VIOLATIONS}- Raw fontSize values — use Theme.of(context).textTheme.* or AppTextStyles.*.\n"
fi

if [ -n "$VIOLATIONS" ]; then
  {
    printf 'Design-token violations in %s — do not write raw design values.\n\n' "$FILE"
    printf '%b' "$VIOLATIONS"
    printf '\nFix: use the project'"'"'s token aliases.\n'
  } >&2
  exit 2
fi

exit 0
