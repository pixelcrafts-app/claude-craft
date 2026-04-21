#!/bin/bash
# SessionStart hook — tells Claude ONLY how to work with the hooks this plugin
# installs. Skills (if installed) are Claude Code's own concern; this block
# says nothing about them. This block also says nothing about what the hooks
# check for — the hook's own stderr teaches Claude that when it fires.

cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "## core-hooks notes\n\nThis plugin installs hooks that enforce constraints deterministically on your actions. When a hook blocks something, its stderr names the specific problem and the fix — read it and adjust. Do not retry the same action; the block will fire again.\n\nOne mechanic that isn't obvious from the platform: **hooks run in the main session only, not inside subagents.** If you delegate file-writing work to a subagent, these hooks do NOT fire on the subagent's writes. For work that must satisfy enforced constraints, prefer inline execution; if delegation is necessary, include the constraints explicitly in the subagent's brief."
  }
}
EOF
exit 0
