#!/bin/bash
# Unit tests for parallel-hint.sh.
# Run with: bash core/skills/core-hooks/hooks/__tests__/parallel-hint.test.sh

set +e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOOK="$ROOT/parallel-hint.sh"
[ ! -x "$HOOK" ] && chmod +x "$HOOK" 2>/dev/null
[ ! -x "$HOOK" ] && { echo "ERROR: hook not executable: $HOOK" >&2; exit 1; }

PASS=0
FAIL=0
FAIL_LOG=""

assert_exit() {
  local desc="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    PASS=$((PASS + 1))
    printf '  ✓ %s\n' "$desc"
  else
    FAIL=$((FAIL + 1))
    FAIL_LOG="$FAIL_LOG\n  ✗ $desc — expected=$expected, got=$actual"
    printf '  ✗ %s — expected=%s, got=%s\n' "$desc" "$expected" "$actual"
  fi
}

assert_contains() {
  local desc="$1" needle="$2" haystack="$3"
  if printf '%s' "$haystack" | grep -qF -- "$needle"; then
    PASS=$((PASS + 1))
    printf '  ✓ %s\n' "$desc"
  else
    FAIL=$((FAIL + 1))
    FAIL_LOG="$FAIL_LOG\n  ✗ $desc — missing: $needle"
    printf '  ✗ %s — missing: %s\n' "$desc" "$needle"
  fi
}

assert_empty() {
  local desc="$1" haystack="$2"
  if [ -z "$haystack" ]; then
    PASS=$((PASS + 1))
    printf '  ✓ %s\n' "$desc"
  else
    FAIL=$((FAIL + 1))
    FAIL_LOG="$FAIL_LOG\n  ✗ $desc — got non-empty stdout"
    printf '  ✗ %s — got: %s\n' "$desc" "$haystack"
  fi
}

TESTDIR=$(mktemp -d)
trap 'rm -rf "$TESTDIR"' EXIT
export CLAUDE_PROJECT_DIR="$TESTDIR"

mk_config() {
  mkdir -p "$TESTDIR/.claude"
  printf '%s' "$1" > "$TESTDIR/.claude/enforcement.json"
}
rm_config() { rm -f "$TESTDIR/.claude/enforcement.json"; }

call_hook() {
  jq -cn --arg p "$1" '{prompt:$p}' | bash "$HOOK" 2>/dev/null
}

# ── Tests ────────────────────────────────────────────────────────────────────
echo "=== parallel-hint.sh tests ==="

# T1: trivial prompts → no hint
echo "T1: trivial prompts → silent"
rm_config
assert_empty "single-line typo fix → silent"   "$(call_hook 'fix the typo in README')"
assert_empty "what time is it → silent"        "$(call_hook 'what time is it')"
assert_empty "add a button → silent"           "$(call_hook 'add a Save button to the login screen')"

# T2: multi-file verbs trigger hint
echo "T2: multi-file verbs trigger hint"
rm_config
assert_contains "audit → hint" "parallel-hint" "$(call_hook 'audit the auth module for security issues')"
assert_contains "refactor → hint" "parallel-hint" "$(call_hook 'refactor the user service to use Repository pattern')"
assert_contains "migrate → hint" "parallel-hint" "$(call_hook 'migrate from React 18 to React 19')"
assert_contains "rename → hint" "parallel-hint" "$(call_hook 'rename UserService to AccountService')"
assert_contains "scaffold → hint" "parallel-hint" "$(call_hook 'scaffold a new payments module')"

# T3: cross-scope quantifiers trigger
echo "T3: cross-scope quantifiers trigger hint"
rm_config
assert_contains "all files → hint" "parallel-hint" "$(call_hook 'update all files using the old api')"
assert_contains "across the codebase → hint" "parallel-hint" "$(call_hook 'find references across the codebase')"
assert_contains "entire app → hint" "parallel-hint" "$(call_hook 'check the entire app for accessibility issues')"

# T4: multi-domain triggers
echo "T4: multi-domain wording triggers hint"
rm_config
assert_contains "web and api → hint" "parallel-hint" "$(call_hook 'update web and api to use the new auth')"
assert_contains "frontend and backend → hint" "parallel-hint" "$(call_hook 'add this feature to frontend and backend')"

# T5: opt-out → silent
echo "T5: parallel_hint: false → silent"
mk_config '{"parallel_hint": false}'
assert_empty "audit + opt-out → silent" "$(call_hook 'audit the entire codebase')"
assert_empty "refactor + opt-out → silent" "$(call_hook 'refactor all services')"

# T6: malformed input → fail-open
echo "T6: malformed input → exit 0 silent"
rm_config
empty_actual=$(echo "" | bash "$HOOK" 2>/dev/null; echo $?)
assert_exit "empty stdin → exit 0" "0" "$empty_actual"
bad_actual=$(echo "{not json}" | bash "$HOOK" 2>/dev/null; echo $?)
assert_exit "invalid JSON → exit 0" "0" "$bad_actual"
noprompt_actual=$(echo '{"foo":"bar"}' | bash "$HOOK" 2>/dev/null; echo $?)
assert_exit "no prompt field → exit 0" "0" "$noprompt_actual"

# T7: output is valid JSON
echo "T7: when triggered, output is valid JSON"
rm_config
OUT=$(call_hook 'audit the auth module')
echo "$OUT" | jq -e '.hookSpecificOutput.additionalContext' >/dev/null 2>&1
parse_actual=$?
assert_exit "output parses as JSON" "0" "$parse_actual"

echo ""
echo "=== Results: ${PASS} passed, ${FAIL} failed ==="
[ "$FAIL" -gt 0 ] && { printf '%b\n' "$FAIL_LOG" >&2; exit 1; }
exit 0
