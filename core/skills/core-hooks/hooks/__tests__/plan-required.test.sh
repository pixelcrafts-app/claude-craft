#!/bin/bash
# Unit tests for plan-required.sh.
# Run with: bash core/skills/core-hooks/hooks/__tests__/plan-required.test.sh
#
# Exit 0 = all tests passed. Exit 1 = at least one failure (printed to stderr).

set +e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOOK="$ROOT/plan-required.sh"

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
    FAIL_LOG="$FAIL_LOG\n  ✗ $desc — expected exit=$expected, got exit=$actual"
    printf '  ✗ %s — expected exit=%s, got exit=%s\n' "$desc" "$expected" "$actual"
  fi
}

# ── Isolated test environment ────────────────────────────────────────────────
TESTDIR=$(mktemp -d)
trap 'rm -rf "$TESTDIR"' EXIT
export CLAUDE_PROJECT_DIR="$TESTDIR"

# Each test runs with a unique ledger session so state doesn't leak.
fresh_session() {
  export CLAUDE_SESSION_ID="plan-required-test-$RANDOM-$RANDOM"
}

mk_enforcement_on() {
  mkdir -p "$TESTDIR/.claude"
  cat > "$TESTDIR/.claude/enforcement.json" <<EOF
{ "plan_required": true, "plan_threshold": 3 }
EOF
}

mk_enforcement_off() {
  mkdir -p "$TESTDIR/.claude"
  cat > "$TESTDIR/.claude/enforcement.json" <<EOF
{ "plan_required": false }
EOF
}

rm_enforcement() {
  rm -f "$TESTDIR/.claude/enforcement.json"
}

mk_transcript_with_plan() {
  TRANSCRIPT="$TESTDIR/transcript-with-plan.jsonl"
  cat > "$TRANSCRIPT" <<'EOF'
{"role":"assistant","content":[{"type":"text","text":"Here is the plan.\n\n<!-- craft:plan\ndeliverables:\n  - id: D1\n    files: [src/foo.ts]\n-->\n"}]}
EOF
  printf '%s' "$TRANSCRIPT"
}

mk_transcript_no_plan() {
  TRANSCRIPT="$TESTDIR/transcript-no-plan.jsonl"
  cat > "$TRANSCRIPT" <<'EOF'
{"role":"assistant","content":[{"type":"text","text":"No plan here yet."}]}
EOF
  printf '%s' "$TRANSCRIPT"
}

# Plan with N deliverables, optional routing line. Builds real newlines
# (not literal '\n') by writing to a content file and using jq --rawfile.
# Usage: mk_transcript_strict <count> <with_routing: yes|no>
mk_transcript_strict() {
  local count="$1" with_routing="$2"
  local file="$TESTDIR/transcript-strict-$RANDOM.jsonl"
  local content_file="$TESTDIR/content-$RANDOM.txt"
  {
    if [ "$with_routing" = "yes" ]; then
      printf 'Routing: 2 parallel agents — reason: independent modules.\n\n'
    fi
    printf '<!-- craft:plan\ndeliverables:\n'
    local i=1
    while [ "$i" -le "$count" ]; do
      printf '  - id: D%d\n    files: [src/x%d.ts]\n    verification: "tsc"\n' "$i" "$i"
      i=$((i + 1))
    done
    printf 'scope_boundary: "x"\n-->\n'
  } > "$content_file"

  jq -cn --rawfile text "$content_file" \
    '{role:"assistant",content:[{type:"text",text:$text}]}' > "$file"
  printf '%s' "$file"
}

call_hook() {
  local file="$1" transcript="$2"
  local payload
  if [ -n "$transcript" ]; then
    payload=$(jq -cn --arg f "$file" --arg t "$transcript" \
      '{tool_name:"Edit",tool_input:{file_path:$f},transcript_path:$t}')
  else
    payload=$(jq -cn --arg f "$file" \
      '{tool_name:"Edit",tool_input:{file_path:$f}}')
  fi
  printf '%s' "$payload" | bash "$HOOK" 2>/dev/null
  echo $?
}

# ── Tests ────────────────────────────────────────────────────────────────────

echo "=== plan-required.sh tests ==="

# T1: opt-out (no enforcement.json) → always exit 0
echo "T1: opt-out — no enforcement.json"
rm_enforcement
fresh_session
assert_exit "no config → exit 0 on first file" "0" "$(call_hook /tmp/proj/src/a.ts)"
assert_exit "no config → exit 0 on second file" "0" "$(call_hook /tmp/proj/src/b.ts)"
assert_exit "no config → exit 0 on third file"  "0" "$(call_hook /tmp/proj/src/c.ts)"

# T2: explicit opt-out (plan_required: false) → always exit 0
echo "T2: explicit opt-out — plan_required: false"
mk_enforcement_off
fresh_session
assert_exit "plan_required=false → exit 0 (1st)" "0" "$(call_hook /tmp/proj/src/a.ts)"
assert_exit "plan_required=false → exit 0 (2nd)" "0" "$(call_hook /tmp/proj/src/b.ts)"
assert_exit "plan_required=false → exit 0 (3rd)" "0" "$(call_hook /tmp/proj/src/c.ts)"

# T3: trivial files don't count (markdown, json, lockfiles, tests)
echo "T3: trivial files don't count toward threshold"
mk_enforcement_on
fresh_session
assert_exit ".md never blocks"           "0" "$(call_hook /tmp/proj/README.md)"
assert_exit ".json never blocks"         "0" "$(call_hook /tmp/proj/package.json)"
assert_exit ".test.ts never blocks"      "0" "$(call_hook /tmp/proj/src/x.test.ts)"
assert_exit "/test/ dir never blocks"    "0" "$(call_hook /tmp/proj/test/y.ts)"
assert_exit ".claude/ dir never blocks"  "0" "$(call_hook /tmp/proj/.claude/x.json)"
assert_exit "node_modules never blocks"  "0" "$(call_hook /tmp/proj/node_modules/x.ts)"

# T4: enforcement on, below threshold → allow
echo "T4: enforcement on, below threshold (2 of 3) → allow"
mk_enforcement_on
fresh_session
assert_exit "1st file → exit 0" "0" "$(call_hook /tmp/proj/src/a.ts)"
assert_exit "2nd file → exit 0" "0" "$(call_hook /tmp/proj/src/b.ts)"

# T5: enforcement on, at threshold, no plan → block
echo "T5: enforcement on, at threshold (3 of 3), no plan → block"
mk_enforcement_on
fresh_session
assert_exit "1st file → exit 0"             "0" "$(call_hook /tmp/proj/src/a.ts)"
assert_exit "2nd file → exit 0"             "0" "$(call_hook /tmp/proj/src/b.ts)"
TRANSCRIPT_NO_PLAN=$(mk_transcript_no_plan)
assert_exit "3rd file, no plan → exit 2"    "2" "$(call_hook /tmp/proj/src/c.ts "$TRANSCRIPT_NO_PLAN")"

# T6: enforcement on, threshold reached but plan exists → allow
echo "T6: enforcement on, threshold reached but plan in transcript → allow"
mk_enforcement_on
fresh_session
TRANSCRIPT_WITH_PLAN=$(mk_transcript_with_plan)
assert_exit "1st file → exit 0" "0" "$(call_hook /tmp/proj/src/a.ts "$TRANSCRIPT_WITH_PLAN")"
assert_exit "2nd file → exit 0" "0" "$(call_hook /tmp/proj/src/b.ts "$TRANSCRIPT_WITH_PLAN")"
assert_exit "3rd file w/plan → exit 0" "0" "$(call_hook /tmp/proj/src/c.ts "$TRANSCRIPT_WITH_PLAN")"
assert_exit "4th file w/plan → exit 0 (ledger cached)" "0" "$(call_hook /tmp/proj/src/d.ts)"

# T7: same file edited twice doesn't double-count
echo "T7: same file twice counts as one"
mk_enforcement_on
fresh_session
assert_exit "1st file → exit 0"          "0" "$(call_hook /tmp/proj/src/a.ts)"
assert_exit "same file again → exit 0"   "0" "$(call_hook /tmp/proj/src/a.ts)"
assert_exit "different 2nd file → exit 0" "0" "$(call_hook /tmp/proj/src/b.ts)"
TRANSCRIPT_NO_PLAN=$(mk_transcript_no_plan)
assert_exit "3rd unique file → exit 2"   "2" "$(call_hook /tmp/proj/src/c.ts "$TRANSCRIPT_NO_PLAN")"

# T8: custom threshold honored
echo "T8: custom threshold (plan_threshold: 5)"
mkdir -p "$TESTDIR/.claude"
cat > "$TESTDIR/.claude/enforcement.json" <<'EOF'
{ "plan_required": true, "plan_threshold": 5 }
EOF
fresh_session
assert_exit "1st file → exit 0" "0" "$(call_hook /tmp/proj/src/a.ts)"
assert_exit "2nd file → exit 0" "0" "$(call_hook /tmp/proj/src/b.ts)"
assert_exit "3rd file → exit 0" "0" "$(call_hook /tmp/proj/src/c.ts)"
assert_exit "4th file → exit 0" "0" "$(call_hook /tmp/proj/src/d.ts)"
TRANSCRIPT_NO_PLAN=$(mk_transcript_no_plan)
assert_exit "5th file no plan → exit 2" "2" "$(call_hook /tmp/proj/src/e.ts "$TRANSCRIPT_NO_PLAN")"

# T9: malformed input → fail-open
echo "T9: malformed input → fail-open (exit 0)"
mk_enforcement_on
fresh_session
empty_actual=$(echo "" | bash "$HOOK" 2>/dev/null; echo $?)
assert_exit "empty stdin → exit 0" "0" "$empty_actual"
bad_actual=$(echo "{not json}" | bash "$HOOK" 2>/dev/null; echo $?)
assert_exit "invalid JSON → exit 0" "0" "$bad_actual"
nofile_actual=$(echo '{"tool_name":"Edit","tool_input":{}}' | bash "$HOOK" 2>/dev/null; echo $?)
assert_exit "no file_path → exit 0" "0" "$nofile_actual"

# T10: strict mode — plan with 2 deliverables, no routing → passes (shape only enforced ≥3)
echo "T10: strict mode, 2 deliverables, no routing → exit 0"
mkdir -p "$TESTDIR/.claude"
cat > "$TESTDIR/.claude/enforcement.json" <<'EOF'
{ "plan_required": "strict", "plan_threshold": 3 }
EOF
fresh_session
TR=$(mk_transcript_strict 2 no)
assert_exit "1st file → exit 0"            "0" "$(call_hook /tmp/proj/src/a.ts "$TR")"
assert_exit "2nd file → exit 0"            "0" "$(call_hook /tmp/proj/src/b.ts "$TR")"
assert_exit "3rd file, 2-deliv plan no routing → exit 0 (shape ok)" "0" "$(call_hook /tmp/proj/src/c.ts "$TR")"

# T11: strict mode — plan with 3 deliverables, NO routing → BLOCK from the 1st edit
# (shape check runs whenever a plan is detected, not only past threshold)
echo "T11: strict mode, 3 deliverables, NO routing → exit 2 from 1st edit"
fresh_session
TR=$(mk_transcript_strict 3 no)
assert_exit "1st file, 3-deliv no routing → exit 2" "2" "$(call_hook /tmp/proj/src/a.ts "$TR")"
assert_exit "2nd file (still bad shape) → exit 2"   "2" "$(call_hook /tmp/proj/src/b.ts "$TR")"

# T12: strict mode — plan with 3 deliverables, WITH routing → passes
echo "T12: strict mode, 3 deliverables, WITH Routing line → exit 0"
fresh_session
TR=$(mk_transcript_strict 3 yes)
assert_exit "1st file, 3-deliv + routing → exit 0" "0" "$(call_hook /tmp/proj/src/a.ts "$TR")"
assert_exit "2nd file → exit 0"                    "0" "$(call_hook /tmp/proj/src/b.ts "$TR")"
assert_exit "3rd file → exit 0"                    "0" "$(call_hook /tmp/proj/src/c.ts "$TR")"

# T13: strict mode — 5 deliverables, no routing → block immediately
echo "T13: strict mode, 5 deliverables, no routing → exit 2"
fresh_session
TR=$(mk_transcript_strict 5 no)
assert_exit "1st file, 5-deliv no routing → exit 2" "2" "$(call_hook /tmp/proj/src/a.ts "$TR")"

# T14: presence-only mode (true, not strict) — 3 deliverables no routing → still passes
echo "T14: presence-only mode (plan_required: true) — shape NOT enforced"
mkdir -p "$TESTDIR/.claude"
cat > "$TESTDIR/.claude/enforcement.json" <<'EOF'
{ "plan_required": true, "plan_threshold": 3 }
EOF
fresh_session
TR=$(mk_transcript_strict 3 no)
assert_exit "1st file → exit 0" "0" "$(call_hook /tmp/proj/src/a.ts "$TR")"
assert_exit "2nd file → exit 0" "0" "$(call_hook /tmp/proj/src/b.ts "$TR")"
assert_exit "3rd file, 3-deliv plan no routing, mode=true → exit 0 (shape not enforced)" "0" "$(call_hook /tmp/proj/src/c.ts "$TR")"

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "=== Results: ${PASS} passed, ${FAIL} failed ==="
[ "$FAIL" -gt 0 ] && { printf '%b\n' "$FAIL_LOG" >&2; exit 1; }
exit 0
