#!/usr/bin/env bash
# Sync each skill's SKILL.md (and supporting files) from a stack's bundle plugin
# (<stack>/skills/<stack>-standards/skills/<name>/) to its slice plugin
# (<stack>/skills/<stack>-<name>/skills/<name>/).
#
# The bundle is canonical. Edit the bundle version; run this to mirror to slices.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# stack:skill1,skill2,...
PACKS=(
  "flutter:pre-ship,premium-check,verify-screens,find-hardcoded,find-duplicates,accessibility-audit,scaffold-screen,scaffold-feature"
  "api:sync-migrate"
  "web:pre-ship,premium-check"
)

for pack in "${PACKS[@]}"; do
  stack="${pack%%:*}"
  skills="${pack#*:}"
  bundle="$ROOT/$stack/skills/$stack-standards/skills"
  IFS=',' read -ra list <<< "$skills"
  for s in "${list[@]}"; do
    src="$bundle/$s"
    dst="$ROOT/$stack/skills/$stack-$s/skills/$s"
    if [[ ! -d "$src" ]]; then
      echo "skip: $stack/$s (no bundle source)"
      continue
    fi
    mkdir -p "$dst"
    rsync -a --delete "$src/" "$dst/"
    echo "synced: $stack/$s"
  done
done

echo "done."
