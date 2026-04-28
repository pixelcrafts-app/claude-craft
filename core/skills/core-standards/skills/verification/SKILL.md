---
name: verification
description: Apply after completing any delivery task — Flutter, web, API, or any stack. Verifies two things before reporting done: (1) the plan was executed completely, (2) the result follows all applicable installed skill guidelines. Universal — not stack-specific.
---

# Verification

**You are an adversarial verifier. You did not write this code. Your job is to find what is wrong with it — not to confirm what is right. Assume problems exist until tool-call evidence proves otherwise. The implementing mindset expects success. The verifying mindset expects failure. Run them separately.**

Run after completing any task, before reporting done. Two phases — both must pass.

**A PASS verdict means a rule was met — not that the work is good.** After rules pass, apply judgment: is this the right solution, or just a compliant one? If something feels wrong even though all rules pass, surface it — it means a rule is missing or the rules don't cover this situation.

---

## Step 0 — Read Project Config

Before detecting skills, read `.claude/craft.json` if it exists at the project root.

- `stacks[]` — which skill domains are PROJECT-MANDATORY for this codebase
- `features{}` — which conditional skills are active (`auth`, `realtime`, `i18n`, etc.)
- `disabled_rules[]` — rules explicitly opted out (each entry must have a reason; surfaced as INFO in every report)

If `.claude/craft.json` is absent: auto-detect stacks from file extensions and package manifests. Emit once: `INFO: no craft.json found — active skills inferred from file types. This may be incomplete. Consider running craft-config to generate one.` Never hard-fail on missing config.

---

## Phase 1 — Plan Compliance

Read the `<!-- craft:plan -->` block from the conversation. If no plan block exists (trivial task, old session): ask the user to restate what was planned before proceeding. Do not re-infer the plan from the code — read what was stated.

For each deliverable in the plan block:

- **DONE** — run the `verification:` command from the plan block. The tool call result is the evidence. No other form of evidence counts.
- **MISSED** — the verification command failed or was not run
- **PARTIAL** — the command partially passed; explain what is there vs what is missing

Rules:
- Every MISSED or PARTIAL item: attempt to fix it now if within scope. Re-check after fixing.
- If the same item fails 3 times: stop, surface it to the user with the reason and blocker. Do not loop.
- Only continue to Phase 2 when all plan items are DONE. PARTIAL counts as MISSED for the READY verdict.
- **After any fix, restart verification from Phase 1 item 1.** Do not continue from where you left off. The fix may have introduced new issues. Partial re-check is not a full re-check.

---

## Phase 2 — Skill Rule Compliance

### Detect Active Skills

Use the 4-tier model. Apply tiers in order.

**Tier 1 — ALWAYS-MANDATORY**
These apply to every task on every file touched, regardless of craft.json, scope boundary, or what was planned. No opt-out.
- `core-standards:rules §1` — Security (hardcoded secrets, input validation, auth error suppression)
- Phase 1 plan compliance

**Tier 2 — PROJECT-MANDATORY**
Skills declared in `craft.json stacks[]` apply to their file types. Features declared non-false in `craft.json features{}` activate their gap-zone skills.
- `stacks: ["web"]` → web-standards skills apply to web files
- `features: { auth: "jwt-refresh" }` → auth-flows skill is active
- `features: { realtime: true }` → websockets skill is active

**Tier 3 — TASK-SCOPED**
Rules that apply only if the task actually modified files in their domain. Detection uses: (a) files directly changed, (b) files imported by changed files (one level of dependency tracing).

Do not apply rules from a skill domain if no changed file touches that domain — even if the project uses it.

**Tier 4 — FLAGGED-NOT-ENFORCED**
Gap zones not declared in craft.json but whose trigger conditions exist in changed code. Emit as `INFO`, not `FAIL`. Do not block READY.
- Auth patterns found but `features.auth` not declared → `INFO: auth pattern detected, not declared in craft.json`
- WebSocket packages found but `features.realtime` not declared → `INFO: WebSocket dependency found, not declared`
- i18n packages found but `features.i18n` not declared → `INFO: i18n dependency found, not declared`

**Scope boundary rule:** The `scope_boundary` field from the plan block narrows which Tier 3 rules are evaluated. It does not suppress rules for files that were actually modified. If fixing a loading state also touched the auth guard file — auth rules apply to that file regardless of scope boundary.

### Detect Active Skills — Reasoning Questions

- Is this UI work? → apply the craft-guide for the stack
- Is this Flutter/Dart? → apply flutter-standards:engineering and flutter-standards:accessibility
- Is this a web frontend? → apply web-standards:craft-guide and web-standards:nextjs (if Next.js)
- Is this API or backend? → apply api-standards:nestjs and api-standards:code-quality
- Does it touch performance-critical paths? → apply the relevant performance skill
- Is this any code at all? → apply core-standards:rules always (Tier 1)

For each skill considered as N/A: the exclusion must cite a tool call (grep, Read, file list) showing the skill's domain is not present in the changed files.

### Verdict Per Rule

- **PASS** — tool-call evidence required: file:line or grep result confirming compliance
- **FAIL** — file:line, rule violated, fix required
- **N/A** — the rule genuinely does not apply. Requires grep or Read result confirming the domain is absent — not a prose claim

**DONE evidence rule:** Prose assertion without a named tool call is MISSED, not DONE. "I added the loading state" is not evidence. A Read result showing the component contains the loading state is evidence. No exceptions. This applies to both Phase 1 deliverables and Phase 2 rule verdicts.

### Universal Minimums — UI work (web, mobile, any stack)

- All 4 states present: loading, empty, error, content
- Loading: meaningful placeholder matching the final layout — not a blank screen or spinner in a void
- Empty: invites action — not "No data found"
- Error: names the specific failure and gives a concrete next step — not "Something went wrong"
- Zero hardcoded color, spacing, radius, typography, or duration values — all from named tokens or constants
- Every interactive element labeled for assistive technology — action described, not element type
- No color as the sole signal for any state
- Contrast meets minimum thresholds (4.5:1 body, 3:1 UI elements) — verified in all themes

### Universal Minimums — API/backend work (any language)

- Every inbound payload has DTO/schema validation — no raw, unvalidated input reaches business logic
- Every protected endpoint has both authentication AND authorization checked (auth guard + role/policy guard — authentication alone is not sufficient)
- Multi-step mutations use transactions — side effects (emails, events, queues) placed outside transaction boundaries are a bug
- Schema change accompanied by a migration — no model change without a corresponding migration file
- No N+1 queries — any query inside a loop or over a collection requires explicit verification that it is not repeated per-item

### Universal Minimums — all code, all stacks

- No duplicate logic — same operation in two places is one operation that needs extracting
- Errors surfaced, not swallowed — no silent catches, no generic error strings
- No auth or authorization bypasses
- Resources released — connections, streams, subscriptions, timers, open file handles closed when done
- No business logic in the rendering or transport layer
- Every fact lives in one place — duplicated sources of truth are a bug waiting to happen

### After a Fix

When a rule fails and a fix is applied:
1. Re-run the exact failed rule against the modified file using a tool call
2. A description of the fix is not a PASS — the re-evaluation result is the PASS
3. **Then restart from Phase 1 item 1.** The full loop reruns. Not just the failed rule.

---

## Known Gaps

These areas have no dedicated skill. When the task touches them, apply judgment and surface gaps explicitly:

- **Auth flows** — active when `craft.json features.auth` is declared; see `core-standards:auth-flows`. When not declared: emit INFO, do not enforce.
- **Cross-stack contracts** — active when `craft.json stacks[]` contains 2+ entries; see `api-standards:cross-stack-contracts`.
- **Real-time / WebSockets** — active when `craft.json features.realtime` is true; see `api-standards:websockets`. When not declared but trigger detected: emit INFO.
- **CI/CD and environment config** — no skill. Flag explicitly: "This task touched deployment config — verify secrets are stage-scoped and not hardcoded. No skill enforces this."
- **Web i18n / localization** — active when `craft.json features.i18n` is true; see `web-standards:i18n`. When not declared but trigger detected: emit INFO.

---

## Report

```
Step 0 — Config
  craft.json: FOUND | ABSENT (inferred from: ...)
  Active stacks: [...]
  Active features: [...]
  Disabled rules: [...] (reason required per entry)

Phase 1 — Plan
  DONE: [item — verification command run, result]
  MISSED/PARTIAL: [item — reason]

Phase 2 — Skill Rules
  FAIL: [file:line — rule — fix required]
  INFO: [gap zone detected but not declared in craft.json]
  (No FAIL entry = all rules passed with tool-call evidence)

Known gaps touched by this task:
  [list any unowned areas the task touched]

Verdict:
  READY  — all plan items DONE (tool-verified), zero rule FAILs, zero PARTIAL
  BLOCK  — [specific plan items or rule failures preventing completion]
```

Never report READY with any MISSED or PARTIAL plan item, any FAIL, or any universal minimum asserted without tool-call evidence. INFO items do not block READY — they inform.
