#!/bin/bash
# Shared helper — session-scoped ledger for enforcement gates.
#
# Other enforcement hooks source this file to read/write per-pack flags.
# A flag is a zero-byte file at $LEDGER_DIR/<pack>.<flag>. Presence means true.
#
# Session scoping: we use $CLAUDE_SESSION_ID when Claude Code passes it.
# Fallback: parent-process-group ID, which stays stable for the life of the
# Claude Code session. Either way, one directory per session, auto-cleaned on
# reboot (tmpfs) — no manual cleanup required.

_ledger_session_id() {
  if [ -n "$CLAUDE_SESSION_ID" ]; then
    printf '%s' "$CLAUDE_SESSION_ID"
    return
  fi
  # Fallback: parent PID. Stable for the Claude Code process lifetime.
  printf '%s' "${PPID:-unknown}"
}

ledger_dir() {
  local sid
  sid=$(_ledger_session_id)
  printf '/tmp/claude-craft-session-%s' "$sid"
}

ledger_init() {
  mkdir -p "$(ledger_dir)" 2>/dev/null || true
}

# ledger_set <pack> <flag>
ledger_set() {
  ledger_init
  : > "$(ledger_dir)/$1.$2" 2>/dev/null || true
}

# ledger_has <pack> <flag> — returns 0 if flag present, 1 otherwise
ledger_has() {
  [ -f "$(ledger_dir)/$1.$2" ]
}

# ledger_clear <pack> <flag>
ledger_clear() {
  rm -f "$(ledger_dir)/$1.$2" 2>/dev/null || true
}

# ledger_mark_touched <pack> — called by enforce-rules when a tracked file was
# about to be edited (we allowed the edit; pack now has unverified work).
ledger_mark_touched() {
  ledger_init
  : > "$(ledger_dir)/$1.touched" 2>/dev/null || true
  ledger_clear "$1" "gate_passed"
}

# Direct-CLI mode: `session-ledger.sh mark-pass <pack>` so gate commands
# (pre-ship) can mark PASS without sourcing. Any other invocation is a no-op
# and keeps dot-source usage working.
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  case "$1" in
    mark-pass)
      [ -n "$2" ] && ledger_set "$2" "gate_passed"
      ;;
    mark-touched)
      [ -n "$2" ] && ledger_mark_touched "$2"
      ;;
    has-touched)
      [ -n "$2" ] && ledger_has "$2" "touched" && exit 0 || exit 1
      ;;
    *)
      : # silent no-op
      ;;
  esac
fi
