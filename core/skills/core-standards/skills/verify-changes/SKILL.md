---
name: verify-changes
description: Generic cross-stack verification workflow. Apply whenever the user says "verify my changes", "cross-check before confirming", "audit what I did", or ends a non-trivial chunk of work. Works on web, mobile, API, DB — reads whatever SKILL.md standards files are installed and applies them. Asks scope, builds a dependency-aware TODO tree, verifies in batches to preserve context, reports per-dimension pass/fail. Pure prompt — no hooks, no external tools, no indexing infrastructure. Uses built-in Read / Grep / Glob / Edit plus TaskCreate for persistence.
---

# Verify Changes — Generic Cross-Stack Workflow

## When this fires

- User asks: "verify my changes", "cross-check before confirming", "audit what I did", "is everything fine?"
- End of a feature branch before PR
- After a batch of edits across multiple files
- Before user says "commit" / "push" / "ship"

**Don't run for:**
- Single-line fixes — **unless** the line touches an exported symbol, a shared type, an env var reference, a schema/migration, or a public API contract. One line changing `export function foo(a, b)` to `(a, b, c)` is a full-run case.
- Pure doc edits (no dependency graph — `docs-sync` is the right tool)
- Throwaway experiments

## The phases

Five phases always run in order. Phase 6 (fix loop) is optional and only runs if the user asked to fix, not just verify.

---

## Invocation — interactive vs delegated

This skill runs in one of two modes, distinguished by how it was invoked:

### Interactive mode (default)

User said "verify my changes" or similar. Run **Phase 1** to ask scope / dimensions / depth. This is the normal flow.

### Delegated mode — called by another skill or slash command

A stack command (e.g. `/web-standards:premium-check`, `/flutter-standards:pre-ship`) or another skill invokes this engine with a pre-filled scope. In that case, Phase 1 is **skipped** — the caller supplies a structured brief at the top of the request, in this shape:

```
verify-changes brief:
  scope: <file | folder | "uncommitted" | "last N commits" | "$ARGUMENTS">
  dimensions: [<skill-name>, <skill-name>, ...]   # e.g. [craft-guide], [craft-guide §13], [ALL web]
  depth: <direct | direct+consumers | full-ripple>
  fix: <yes | no>          # if yes, Phase 6 runs; if no, stop after Phase 5
  source: <caller name>    # e.g. "web-standards:premium-check"
```

Treat every field as authoritative. Do not re-prompt. Echo the brief back once as the audit trail ("Running verify-changes delegated by <source>: scope=…, dimensions=…, depth=…") then jump straight to Phase 2.

If the brief is malformed (missing a required field, unknown dimension name), fall back to interactive mode — ask the user to fix or clarify. Don't guess.

**Dimension scoping.** A dimension may be a whole skill (`craft-guide`) or a subset (`craft-guide §13`, `craft-guide §9.1-§9.5`). When scoped, iterate only the matching rule IDs from that skill's SKILL.md — not the whole file. This is how `theme-audit` becomes "craft-guide §13 only" without duplicating §13's rules.

---

## Phase 0 — State initialization

Before any other phase, manage `.claude/verify-state.json`.

### 0.1 — Check for existing state

Read `.claude/verify-state.json` if it exists.

- If `run_id` matches the current session AND `status` is `in_progress`: **resume** from where it left off. Echo: "Resuming verification run `<run_id>` — `<N>` batches already completed." Skip Phase 1 and jump to the first incomplete batch in Phase 4.
- If `run_id` does not match OR `status` is `completed`: **start fresh** — overwrite the file.
- If the file does not exist: create it.

### 0.2 — Initialize fresh state

Write `.claude/verify-state.json`:

```json
{
  "run_id": "<session-id or timestamp>",
  "started_at": "<ISO timestamp>",
  "status": "in_progress",
  "scope": null,
  "dimensions": [],
  "batches": [],
  "findings": []
}
```

`scope` and `dimensions` are filled in after Phase 1. `batches` and `findings` are populated during Phase 4.

### 0.3 — State schema (reference)

```json
{
  "run_id": "string",
  "started_at": "ISO string",
  "status": "in_progress | completed | blocked",
  "scope": "string — what was verified",
  "dimensions": ["skill-name", ...],
  "batches": [
    {
      "batch_id": "number",
      "dimension": "string",
      "files": ["path", ...],
      "status": "completed | skipped | stuck",
      "pass_count": "number",
      "fail_count": "number",
      "findings": [
        {
          "rule": "string — e.g. craft-guide §4.2",
          "file": "path",
          "line": "number | null",
          "verdict": "PASS | FAIL | N_A | INFO | REVIEW | CONFLICT",
          "evidence": "string — direct quote or 'no occurrence'",
          "fix": "string | null — only on FAIL"
        }
      ]
    }
  ],
  "findings": "flattened array — union of all batch findings for fast cross-agent lookup"
}
```

The `findings` top-level array is a flat union of every finding across all batches. It exists so any subsequent agent or phase can query "has rule X been checked against file Y?" without walking all batches.

---

## Phase 1 — Scope dialogue

(Interactive mode only. Skip if running delegated — see Invocation above.)

Before planning or doing anything, ask the user three specific questions. Don't guess; asking is cheaper than redoing.

### 1.1 — Scope of changes

```
Which changes do I verify?

  a) Uncommitted working tree (git status)
  b) Last N commits on this branch (specify N)
  c) A specific file or folder (specify path)
  d) A feature / named area (specify)
  e) All of the above
```

Default to (a) if user says "just go."

### 1.2 — Dimensions to cover

Auto-detect which standards packs are installed. Sources, in order of trust:

1. **The available-skills list in the current system reminder** — authoritative. Skill names like `web-standards:premium-check`, `flutter-standards:pre-ship`, `api-standards:code-quality`, `core-hooks:docs-sync`.
2. **Fallback glob** (only if the list is unavailable) — check both the working tree and the installed-plugin root:
   - `**/{flutter,api,web}-standards/skills/*/SKILL.md`
   - `**/core-hooks/skills/*/SKILL.md`
   - `~/.claude/plugins/**/SKILL.md` (if globbable in your environment)

If zero packs are detected, tell the user: *"No standards packs detected — I can still verify generic things like unused imports and obvious breakage, but I won't have pack-specific rules to apply."* Ask whether to proceed generically or stop.

Then ask:

```
Based on detected packs <list>, which dimensions?

  a) ALL — every installed standard
  b) Specific dimensions (list: craft, engineering, a11y, perf, testing, security, production-readiness, docs-sync, ...)
  c) SMART — auto-pick based on what changed
    - .dart changes → flutter standards
    - .ts/.tsx changes → web / api standards per path
    - schema.prisma → api + migration checks
    - .md changes → docs-sync only
```

Default to SMART if user says "just go."

### 1.3 — Depth

```
How deep?

  a) Direct only — verify the changed files against standards
  b) Direct + consumers — verify the files that import / depend on what changed
  c) Full ripple — direct + consumers + consumers-of-consumers (slow, thorough)
```

Default to (b) — direct + consumers — if user says "just go."

If the user says "just go" / "use defaults" / "you pick", don't silently proceed. Emit one short message echoing the three defaults you're using:

```
Going with defaults:
  Scope: uncommitted working tree
  Dimensions: SMART (auto-pick based on file types changed)
  Depth: direct + consumers

Starting Phase 2. Say "stop" anytime to adjust.
```

Then continue to Phase 2 without waiting for another confirmation. The echo is the audit trail — it's not a question.

---

## Phase 2 — Discovery + dependency graph

Walk from the scope outward. Use only built-in tools.

### 2.1 — List changed files

- Uncommitted: `git status --short` (shows status codes) + `git diff --name-status`
- Last N commits: `git log -n <N> --name-status --pretty=format:`
- Specific path: Glob
- **No git repo:** if `git status` errors ("not a git repository"), ask the user which files changed and treat their list as the scope. Skip any "uncommitted" shortcut.

**Interpret git status codes:**
- `M <path>` — modified. Read it, check against dimensions.
- `A <path>` — added (new file). Same, but no prior version to diff against — check it as a fresh file.
- `D <path>` — deleted. Don't try to `Read` it. Instead, search the codebase for any remaining reference to the deleted path / exported symbols — **every reference is a break**. Treat deletion as automatically high-blast-radius.
- `R<score> <old> -> <new>` — renamed. Treat as `D <old>` (find references to the old path + symbols) **plus** `A <new>` (verify new file). Renames are automatically high-blast-radius.
- `??` — untracked. Include if user said scope = uncommitted.

Record the list. Classify by stack (file extension + path).

**Filter out before building the graph** — consult the installed stack skill for stack-specific generated/build folder patterns. Universal excludes: `node_modules/`, `dist/`, `build/`, `out/`, `coverage/`, lockfiles, binary assets, IDE clutter (`.DS_Store`, `.idea/`).

If a lockfile change is surprising (e.g., pnpm-lock changed without package.json), flag it but don't treat it as a verifiable unit against standards.

### 2.2 — Build the dependency graph

For each changed file, find its direct consumers using the stack's import/reference patterns. Consult the installed stack skill's dependency-patterns section for the correct import syntax to grep for. Union results across multiple passes.

Do not grep for files in: `node_modules/`, `.next/`, `dist/`, `build/`, `coverage/`, `.turbo/`, generated folders.

Record the graph as:
```
<changed-file>
  → consumer-1
  → consumer-2
    → consumer-of-consumer (only if depth = "full ripple")
```

### 2.3 — Identify "high-blast-radius" changes

Flag any change that:
- Removed or renamed an exported symbol
- Changed a function signature (added/removed/reordered params)
- Changed an ORM schema model
- Changed an environment variable name
- Modified a shared type (schema, DTO, shared interface)
- Touched a public API route path or method

These require **every** consumer verified, not a sample.

---

## Phase 3 — Plan via TaskCreate

Build a dependency-aware task tree. One task per (file × dimension) pair, with dependencies explicitly wired so Task blockers enforce order.

### 3.1 — Task structure

**Important:** `TaskCreate` only accepts `subject / description / activeForm / metadata`. Dependencies (`addBlockedBy`, `addBlocks`) are set with a follow-up `TaskUpdate` call. Never inline them in `TaskCreate`.

**Step A — create every task first** (no deps yet):

```
TaskCreate
  subject: "Verify <file> × <dimension>"
  description: "Read file, apply rules from <standards-skill>, record PASS/FAIL in metadata"
  metadata: { file, dimension, stack, type: "direct" | "consumer" | "contract", parent_file? }
```

**Step B — wire dependencies** with `TaskUpdate` once IDs are known:

```
TaskUpdate
  taskId: <consumer-task-id>
  addBlockedBy: [<direct-verify-task-id>]
```

For high-blast-radius changes: create an extra `Verify API contract: <file>` task, then `TaskUpdate` it with `addBlockedBy: [all consumer task IDs]`.

### 3.2 — Batching rule

Tasks are grouped into **batches of 5–10** by stack + dimension. Each batch:
- Fits in one verification round without re-loading full context
- Has a single clear goal (one stack × one dimension)
- Produces one mini-report before moving to the next batch

Batch ordering: direct tasks first → consumers after → high-blast-radius last (because they need all direct verifications first).

Record the batch plan with a summary message:

```
Plan: <N> tasks in <M> batches.
  Batch 1: <stack> × <dimension> — <file count> files
  Batch 2: ...
```

Use file count and batch count as proxies — do not claim exact token budgets.

Show the plan, then ask *"Proceed?"* The user may adjust scope, drop dimensions, or approve. Don't start Batch 1 without a confirmation — the plan is where the user catches misread scope before it costs 20 tool calls to discover.

---

## Phase 4 — Batch execution

**The key discipline: between batches, write progress to task metadata (via `TaskUpdate`), not into the running conversation.** Findings that later phases need must live in task metadata, not as quoted evidence in intermediate messages.

### 4.1 — Per-batch loop

For each batch:

1. **Check verify-state.json before starting** — read the flat `findings` array. If any `(rule, file)` pair in this batch is already recorded with a non-`in_progress` verdict, skip it and record `N_A: already verified in batch <id>`. This prevents duplicate work when batches overlap or when resuming a run.
2. **Mark batch tasks in_progress** via TaskUpdate
3. **Load only what's needed** — read the files in this batch, load only the standards skill relevant to this batch's dimension. Don't pre-load the whole pack.
4. **Iterate rule-by-rule** — for every rule in the loaded dimension's SKILL.md, produce one record per (rule × file):
   - **Rule ID or heading** — the section/rule identifier from the skill (e.g. `craft-guide §4.2` or `nestjs — controller split`). Never collapse multiple rules into one record.
   - **Evidence** — a direct quote from the file with `path:line`, or the literal string `no occurrence` if the rule does not apply to anything in this file.
   - **Verdict** — exactly one of `PASS`, `FAIL`, `N_A`, `INFO`, `REVIEW`, or `CONFLICT` — see the Verdict types section for definitions. `N_A` **requires** a one-line reason (e.g. "file has no color tokens — rule about color harmony doesn't apply"). Bare `N_A` without reason is invalid and must be re-run.
   - **Suggested fix** — only on `FAIL`. One line. The minimum change that resolves the rule.
   
   Walk every rule in order. Never skip a rule because it "seems unrelated" — record `N_A` with reason instead. Never stop mid-dimension on the first FAIL; collect them all.
5. **Record results in task metadata**:
   ```
   TaskUpdate: status=completed, metadata={ pass_count, fail_count, fails: [{ rule, file, line, evidence, suggested_fix }] }
   ```
6. **Write results to verify-state.json** — append the completed batch and merge findings into the flat `findings` array:
   ```json
   batch: { batch_id, dimension, files, status: "completed", pass_count, fail_count, findings: [...] }
   findings: [...existing..., ...new findings from this batch]
   ```
   Write atomically — update the full file, not a partial append. This is the shared truth layer: any subsequent agent, phase, or resumed session reads it as authoritative.
7. **Emit a compact batch summary** (under 100 words): "Batch N done. X PASS, Y FAIL. Top failures: ..."
8. **Move on** — don't re-quote Batch N's full records into the next message. They are in task metadata and verify-state.json; Phase 5 reads them back.

### 4.2 — When spawning a dimension agent

If verify-changes delegates a dimension to a subagent (per `subagent-brief` rules), the brief **must** include the current verify-state.json context:

```
CONTEXT
  verify-state.json — read .claude/verify-state.json before starting.
  Already verified (do not re-check):
    <list of (rule, file) pairs already in the flat findings array>
  Trust boundary: record raw findings with file:line evidence.
  Do not summarize — the cross-check phase reads your raw output.

OUTPUT
  Write your batch findings to verify-state.json before returning.
  Return a compact summary only: batch_id, pass_count, fail_count, top 3 failures.
```

This makes the state file the trust layer between agents — not the conversation thread. The parent does not need to re-verify the subagent's findings; it reads the evidence directly from the state file.

### 4.2 — Task metadata schema

Each task's metadata stores:
- `fails` (array of specific failures — if >15 per task, store top 15 + total count)
- `suggested_fixes` (for fix phase)
- `blockers_resolved` (did this task unblock any others?)

### 4.3 — Stop conditions

Stop and report mid-run if:
- A **CRITICAL** failure is found — concretely: a hardcoded secret committed, a removed-auth-check on a protected route, an env-var reference that no longer exists, a migration containing `DROP COLUMN` / `DROP TABLE` / a new `NOT NULL` without default, a breaking change to an exported public signature. These need user attention before any more audit time is spent.
- A consumer verification reveals the change will definitely break production — a renamed export is still imported by name, a removed Prisma field is still read, a Zod schema no longer matches the route's request shape.
- You've completed more batches than originally planned and are still finding new dependencies to check — checkpoint and ask whether to continue or stop.

---

## Phase 5 — Consolidated report

After all batches complete (or stopped):

1. **Read `.claude/verify-state.json` first** — this is the authoritative evidence trail. All batch findings with `file:line` evidence are here. Use this as the primary source for the report.
2. Call `TaskList` to cross-reference completion status. If any task shows `completed` but has no corresponding batch in verify-state.json — flag it as `unverified: state file missing` in the report.
3. For critical or consumer-break failures: `TaskGet` to confirm the failure details match what is in verify-state.json. Discrepancies between task metadata and the state file indicate a write failure — surface it: `WARN: task <id> metadata conflicts with verify-state.json — manual review required`.
4. **Mark verify-state.json as completed**: update `status` to `completed` and `completed_at` to ISO timestamp. This prevents Phase 0 from resuming a finished run.

Then produce:

```
Verification report — <date>
Scope: <what was covered>
Dimensions: <which standards>
Depth: <direct | direct+consumers | full ripple>

Totals
  Files verified: X
  Tasks completed: Y / Z
  PASS: ...   FAIL: ...

Critical failures (MUST FIX):
  [list — grouped by file, each with rule + line + evidence + suggested fix]

Polish failures (SHOULD FIX):
  [list]

Consumer impact:
  [any consumer task that FAILed because of a direct change — file:line of the break]

Unverified / skipped:
  [any task that could not be run + reason]

Verdict:
  - 0 critical + 0 consumer-break → SAFE TO COMMIT
  - polish only → COMMIT IF DELIBERATE
  - any critical or consumer break → BLOCK
```

---

## Phase 6 (optional) — Fix loop

If user said "verify and fix" rather than "just verify":

1. Walk the FAIL list in priority order (critical first, then consumer-breaks, then polish).
2. For each: apply the smallest minimal fix.
3. After each fix, re-verify **only that rule × file** (not the whole batch).
4. Update task metadata with `fixed: true` + `fix_description`.
5. If fix creates a new FAIL elsewhere, add a task for the new issue — but track cycles:
   - Maintain a counter per `(rule, file)` pair. Increment each time you retry that pair.
   - If any pair hits **3 retries**, stop the loop on that pair, mark it `status: in_progress` with metadata `{ stuck: true, reason }`, and surface it to the user. Don't keep retrying — three attempts means the fix is oscillating or the rule conflicts with another rule.
6. Loop until all critical + consumer tasks are `PASS` **or** stuck.
7. Before re-emitting the final report, check: is any file being edited that is protected (`.env`, credentials, lockfiles)? If so, do not edit it — surface the intent and let the user decide.
8. Re-emit the final report with a new section: `Stuck after 3 attempts` listing the (rule, file) pairs the user needs to resolve manually.

---

## Verdict types

Every rule evaluation produces exactly one verdict:

| Verdict | Meaning | When to use |
|---|---|---|
| `PASS` | Rule met | Evidence cited (file:line confirms compliance) |
| `FAIL` | Rule violated | Evidence cited, suggested fix provided |
| `N_A` | Rule does not apply | Condition not met, or user declared intentional exception. Reason required — bare N_A is invalid. |
| `INFO` | Guide noted | Content is advisory (GUIDES section of skill). Never blocks. No fix required. |
| `REVIEW` | Judgment required | Rule requires human decision — Claude cannot determine PASS or FAIL objectively. Surface with question. |
| `CONFLICT` | Two rules contradict | State both rules, state the conflict. Do not resolve silently. User decides. |

**Precedence when rules conflict:** stack-specific rules override universal rules for stack-specific matters. Universal rules (core-standards:rules §1 Security, §1.3 auth errors) override stack rules when the conflict involves security or secrets.

**Guides vs Rules:** rules in a skill's `RULES` section produce PASS/FAIL/N_A. Content in a skill's `GUIDES` section produces INFO only — never FAIL. Content in a skill's `SUGGESTIONS` section is never audited.
