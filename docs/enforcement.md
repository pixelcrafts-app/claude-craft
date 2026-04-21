# Enforcement mode

**Auto-invoke skills are advisory. Enforcement mode makes them mandatory.**

By default, claude-craft skills fire on description match — Claude decides when to load them. Enforcement mode (shipped in `core-hooks` v0.10.0) turns that advisory discipline into a hard contract: required skills, deterministic rule blocks, and a gate check before any turn ends.

---

## When to use it

- Your team wants **rules that cannot be quietly skipped**, not just "Claude usually follows them."
- You want a **single opt-in flag per project**, not a setup script.
- You're happy with the tradeoff: sometimes Claude will be blocked and has to fix something before continuing. That is the point.

If your team is fine with today's auto-invoke model, you don't need this — nothing changes, existing installs keep working exactly as they do.

---

## How it works (one diagram)

```
┌─ .claude/enforcement.json ──────────┐
│  { "mandatory": ["flutter-standards"] }
└─────────────┬───────────────────────┘
              │ read by
              ▼
┌─ core-hooks ────────────────────────────────────────────────────┐
│                                                                 │
│  SessionStart  →  inject "mandatory skills" preamble            │
│                                                                 │
│  PreToolUse    →  for each Edit/Write, run every mandatory      │
│                   pack's rule registry against the content.     │
│                   Violation → exit 2 (hard block).              │
│                   Also marks `<pack>.touched` in ledger.        │
│                                                                 │
│  Stop (turn-end) → check `<pack>.touched` && `<pack>.gate_passed`.
│                    Touched but not passed → exit 2 with message.│
│                    Claude cannot say "done" until gate passes.  │
└─────────────────────────────────────────────────────────────────┘
                            ▲
                            │ marks ledger on PASS
                            │
                   /pack:pre-ship  (or whatever gate command the pack ships)
```

Three hooks, one small config file. The ledger is a scratch directory under `/tmp/claude-craft-session-$SESSION_ID/` — auto-cleaned on reboot, no manual cleanup needed.

---

## Global install — how to use

You install `core-hooks` the same way as before. Enforcement mode is **project-scoped**, so there's no global switch — you opt in per project by committing one file.

```json
// .claude/settings.json — same as before
{
  "extraKnownMarketplaces": {
    "pixelcrafts": {
      "source": { "source": "github", "repo": "pixelcrafts-app/claude-craft" }
    }
  },
  "enabledPlugins": {
    "flutter-standards@pixelcrafts": true,
    "core-hooks@pixelcrafts": true,
    "core-skills@pixelcrafts": true
  }
}
```

If you've been running claude-craft before v0.10.0, you already have `core-hooks` installed — no changes needed. Enforcement is strictly additive: if you don't create `.claude/enforcement.json`, your project sees no change.

---

## Project-level setup — the one file

Create `.claude/enforcement.json` in your project root (commit it — it's shared config, not per-developer):

```json
{
  "mandatory": ["flutter-standards"]
}
```

That's the minimum. On the next Claude Code session, you'll see:

1. A `SessionStart` preamble listing `flutter-standards`' mandatory skills and rule IDs.
2. Every `.dart` edit gets run through the pack's rule registry (e.g. `IconButton` without `Semantics` is hard-blocked).
3. If a `.dart` file was edited, the turn cannot end until `/flutter-standards:pre-ship` reports SAFE TO COMMIT.

### Multiple packs

A web project using Flutter for the companion mobile app:

```json
{
  "mandatory": ["flutter-standards", "web-standards"]
}
```

Each pack's ledger is tracked independently — the Stop hook blocks only on packs whose files were actually touched.

### Turn off specific rules

A rule that doesn't fit your project — add it to `disabled_rules`:

```json
{
  "mandatory": ["flutter-standards"],
  "disabled_rules": ["flutter.perf.listview-unbounded"]
}
```

Rule IDs come from each pack's default config — see "What rules ship by default" below. `disabled_rules` is a flat list: any matching ID is skipped by `PreToolUse`.

### Advisory mode (no hard block at turn-end)

To keep the PreToolUse rule blocks but make the Stop-hook gate advisory (nudge, not block):

```json
{
  "mandatory": ["flutter-standards"],
  "gate_required": false
}
```

With this, the preamble still announces the gate, and the PreToolUse rules still block, but Claude can end the turn without running `pre-ship`. Useful during an adoption ramp — turn gate enforcement back on once the codebase catches up.

---

## What rules ship by default

Each pack ships a default rule registry at `core-hooks/enforcement/<pack>.json`. v0.10.0 starts small on purpose — rules have to be deterministic (regex-level) so false positives don't wedge your workflow.

**`flutter-standards`** — mandatory skills: `craft-guide`, `widget-rules`, `accessibility`, `performance`. Gate: `/flutter-standards:pre-ship`.
- `flutter.a11y.icon-button` — `IconButton(icon: Icon(...))` (confirm `tooltip:` / `semanticLabel:` is set)
- `flutter.obs.print` — `print()` in `lib/**`
- `flutter.perf.listview-unbounded` — `ListView(children: [...])` (eagerly-built list; use `.builder` for large collections)

**`web-standards`** — mandatory skills: `nextjs`, `craft-guide`, `production-readiness`. Gate: `/web-standards:pre-ship`.
- `web.a11y.raw-img` — raw `<img>` tag (prefer `next/image`; if using `<img>`, confirm `alt=` is set, `alt=""` for decorative)
- `web.obs.console-log` — `console.log` in `app/`, `components/`, `lib/`, `src/`
- `web.sec.dangerously-set-inner-html` — `dangerouslySetInnerHTML` usage

**`api-standards`** — mandatory skills: `nestjs`, `code-quality`. No gate (audit-only pack — use `verify-changes` directly).
- `api.err.empty-catch` — `catch { }` with an empty body
- `api.obs.console-log` — `console.log` in `src/**`
- `api.sec.raw-sql` — `$queryRawUnsafe` / `$executeRawUnsafe`

These live in the plugin and update when you run `/plugin marketplace update pixelcrafts`.

---

## Authoring a new rule

**Prerequisite:** the rule must be expressible as a regex against file content. Craft-level rules (aesthetic coherence, layout polish) stay advisory — the engine handles them during `pre-ship`.

Each pack's default lives at `core/plugins/core-hooks/enforcement/<pack>.json`. Add an entry:

```json
{
  "id": "web.sec.no-target-blank-without-rel",
  "pattern": "target=\"_blank\"(?![^>]*rel=\"[^\"]*noopener)",
  "message": "<a target=\"_blank\"> without rel=\"noopener noreferrer\" — tab-napping risk.",
  "applies_to": "*.tsx,*.jsx"
}
```

Fields:
- `id` — unique within the pack. Convention: `<pack-shortcut>.<category>.<slug>`. Used by `disabled_rules` for overrides.
- `pattern` — bash-compatible ERE regex (GNU grep flavor). Escape `\`, `$`, `"` as needed.
- `message` — one-line description of what's wrong and how to fix. Shown in the block stderr.
- `applies_to` — comma-separated file globs. Matched against both the full path and the basename.

Rules load automatically — no code changes in `core-hooks/hooks/enforce-rules.sh`.

### Testing a rule locally

```bash
# Simulate the PreToolUse hook call.
echo '{"tool_name":"Write","tool_input":{"file_path":"/tmp/test.tsx","content":"<a target=\"_blank\">hi</a>"}}' \
  | CLAUDE_PLUGIN_ROOT=/path/to/core-hooks \
    CLAUDE_PROJECT_DIR=/tmp/fake-project \
    bash /path/to/core-hooks/hooks/enforce-rules.sh
# Exit 2 and a stderr message means the rule blocks. Exit 0 means no match.
```

---

## Project-level config reference

```json
{
  "mandatory": ["<pack-name>", ...],
  "disabled_rules": ["<rule-id>", ...],
  "gate_required": true
}
```

| Field | Type | Default | Meaning |
|---|---|---|---|
| `mandatory` | `string[]` | `[]` | Packs to enforce. Missing → enforcement off entirely |
| `disabled_rules` | `string[]` | `[]` | Rule IDs to skip in PreToolUse |
| `gate_required` | `boolean` | `true` | `false` → Stop hook doesn't block turn-end |

Nothing else is supported. Unknown fields are ignored (fail-open).

---

## Troubleshooting

**Hook didn't fire** — Hooks run at `SessionStart`, `PreToolUse`, and `Stop`. If you edited before a session rebuild, nothing fires — reload the plugin (`/reload-plugins`) or start a new session. For the `Stop` hook specifically: hooks do **not** fire inside subagents, so work delegated via `Agent` won't be gated.

**The preamble isn't showing up in Claude's context** — Check `.claude/enforcement.json` exists in the project root and that `mandatory` is a non-empty array. Run `bash core-hooks/hooks/enforcement-preamble.sh` directly to debug — if it prints nothing, the config wasn't found.

**A rule is blocking something I actually want** — add its `id` to `disabled_rules`. If the rule is wrong more generally, open a PR against the pack's `enforcement/<pack>.json` with the fix and a test case.

**I want to commit without running pre-ship** — Either set `"gate_required": false` (advisory mode) or run the gate and accept the verdict. Bypassing intentionally is the anti-pattern we're preventing.

**`jq` not found** — all enforcement hooks fail-open if `jq` is missing. Install with your OS package manager (`brew install jq`, `apt install jq`, etc.). Without `jq`, enforcement is silently disabled.

---

## What enforcement mode does NOT do

- **Does not verify Claude's reasoning.** The PreToolUse block catches the *output* (file content violates a pattern). It doesn't verify Claude "thought about" the skill. Hard-block on output is the actual guarantee.
- **Does not force skill invocation.** Auto-invoke is still heuristic. Enforcement works by making output compliance mandatory instead.
- **Does not work inside subagents.** Claude Code hooks run in the main session only. Delegated work bypasses the hooks. If enforcement is critical, include it in the `subagent-brief` template so the delegate knows the contract.
- **Does not replace human review.** The rule registry catches the obvious-and-boring. Craft, architecture, product fit — still on you.

---

## Rollout pattern for teams

1. **Week 1 — install with advisory mode.** Commit `.claude/enforcement.json` with `"gate_required": false`. Team sees preambles and PreToolUse blocks but gates are nudges, not hard blocks. Collect rule-false-positive feedback.
2. **Week 2 — flip gates to blocking.** Remove `"gate_required": false`. Gates now hard-block turn-end. False positives already disabled via `disabled_rules`.
3. **Ongoing — tighten the registry.** As patterns surface in review, add them to the pack's `enforcement/<pack>.json` via PR to claude-craft (or a fork).

Enforcement mode is not a big-bang flag — it's a ramp. Start loose, tighten.
