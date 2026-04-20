#!/usr/bin/env bash
# Export pixelcrafts standards to non-Claude-Code AI tools.
#
# Generates:
#   <target>/.cursor/rules/*.mdc   (Cursor Rules v2 — one file per standards skill)
#   <target>/AGENTS.md             (Antigravity / Codex / Aider / OpenAI SWE)
#
# Usage:
#   ./scripts/export.sh <target-project-path> <pack>
#   pack: flutter | api | web
#
# Example:
#   ./scripts/export.sh ~/work/my-flutter-app flutter

set -euo pipefail

TARGET="${1:?usage: export.sh <target-project-path> <flutter|api|web>}"
PACK="${2:?usage: export.sh <target-project-path> <flutter|api|web>}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [[ ! -d "$TARGET" ]]; then
  echo "target project does not exist: $TARGET" >&2
  exit 1
fi

case "$PACK" in
  flutter)
    BUNDLE="$ROOT/flutter/skills/flutter-standards/skills"
    STANDARDS=(craft-guide engineering widget-rules api-data testing accessibility performance forms observability)
    GLOBS="lib/**/*.dart,test/**/*.dart"
    ;;
  api)
    BUNDLE="$ROOT/api/skills/api-standards/skills"
    STANDARDS=(nestjs code-quality)
    GLOBS="src/**/*.ts,prisma/schema.prisma"
    ;;
  web)
    BUNDLE="$ROOT/web/skills/web-standards/skills"
    STANDARDS=(nextjs)
    GLOBS="app/**,components/**,lib/**,**/*.tsx"
    ;;
  *)
    echo "unknown pack: $PACK (expected flutter|api|web)" >&2
    exit 1
    ;;
esac

extract_body() {
  awk 'BEGIN{f=0} /^---[[:space:]]*$/{f++;next} f>=2{print}' "$1"
}

extract_desc() {
  awk 'BEGIN{f=0}
       /^---[[:space:]]*$/{f++;next}
       f==1 && /^description:/{sub(/^description:[[:space:]]*/,""); gsub(/^"|"$/,""); print; exit}' "$1"
}

mkdir -p "$TARGET/.cursor/rules"

echo "→ exporting $PACK pack from $ROOT"
echo "→ target: $TARGET"
echo

# 1. Cursor Rules v2 — one .mdc per standards skill
for skill in "${STANDARDS[@]}"; do
  src="$BUNDLE/$skill/SKILL.md"
  if [[ ! -f "$src" ]]; then
    echo "  skip (missing): $src" >&2
    continue
  fi
  body="$(extract_body "$src")"
  desc="$(extract_desc "$src")"
  out="$TARGET/.cursor/rules/${PACK}-${skill}.mdc"
  {
    printf -- '---\n'
    printf 'description: %s\n' "${desc:-$skill standard}"
    printf 'globs: %s\n' "$GLOBS"
    printf 'alwaysApply: false\n'
    printf -- '---\n\n'
    printf '%s\n' "$body"
  } > "$out"
  echo "  wrote .cursor/rules/${PACK}-${skill}.mdc"
done

# 2. AGENTS.md — single concatenated file (Antigravity, Codex, Aider, OpenAI SWE)
agents="$TARGET/AGENTS.md"
{
  printf '# Agent Standards — %s pack\n\n' "$PACK"
  printf 'Auto-generated from `pixelcrafts-app/claude-craft`. Do not edit — regenerate via `scripts/export.sh`.\n\n'
  printf 'Source: https://github.com/pixelcrafts-app/claude-craft\n\n'
  printf -- '---\n\n'
  for skill in "${STANDARDS[@]}"; do
    src="$BUNDLE/$skill/SKILL.md"
    [[ -f "$src" ]] || continue
    printf '## %s\n\n' "$skill"
    extract_body "$src"
    printf '\n---\n\n'
  done
} > "$agents"
echo "  wrote AGENTS.md"

echo
echo "✓ done. ${#STANDARDS[@]} skills exported."
