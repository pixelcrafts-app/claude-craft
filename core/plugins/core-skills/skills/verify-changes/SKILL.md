---
name: verify-changes
description: Generic cross-stack verification workflow. Apply whenever the user says "verify my changes", "cross-check before confirming", "audit what I did", or ends a non-trivial chunk of work. Works on web, mobile, API, DB — reads whatever SKILL.md standards files are installed and applies them. Asks scope, builds a dependency-aware TODO tree, verifies in batches to preserve context, reports per-dimension pass/fail. Pure prompt — no hooks, no external tools, no indexing infrastructure. Uses built-in Read / Grep / Glob / Edit plus TaskCreate for persistence.
---

# Verify Changes — Generic Cross-Stack Workflow

A diff is more than the lines it touches. A change to a shared type ripples into every consumer. A renamed function breaks call sites. A new column breaks migrations downstream. This skill catches the ripple — not just the diff — and does it in a way that doesn't blow the context window on large changesets.

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

**Filter out before building the graph** — these files should never count as "changed files to verify":

- Build output: `.next/`, `dist/`, `build/`, `out/`, `.turbo/`, `coverage/`
- Dependency trees: `node_modules/`, `ios/Pods/`, `android/build/`, `.gradle/`
- Generated code: `prisma/generated/`, `*.g.dart`, `*.freezed.dart`, `*.gen.ts`, `*.pb.go`, `__generated__/`
- Lockfiles: `*.lock`, `*.lockb`, `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `pubspec.lock`, `Podfile.lock`
- Binary assets: images (`*.png`, `*.jpg`, `*.webp`, `*.svg` if huge), fonts (`*.ttf`, `*.woff*`), `*.pdf`, `*.mp4`
- IDE / OS clutter: `.DS_Store`, `.idea/`, `.vscode/` (usually), `*.tmp`

If a lockfile change is surprising (e.g., pnpm-lock changed without package.json), flag it but don't treat it as a verifiable unit against standards.

**Next.js routing note:** `app/api/**/route.ts` is backend code even in a web repo. Classify it under API dimensions (validation, error shapes, auth) not frontend dimensions (craft-guide, theme). Same for `pages/api/**`.

### 2.2 — Build the dependency graph

For each changed file, find its direct consumers. A single regex won't catch every case — run several passes per file and union the results.

**TypeScript / TSX (Next.js and NestJS):**
- Relative imports: search for `from ['"].*<filename-without-ext>['"]` and `require\(['"].*<filename-without-ext>['"]\)`
- Dynamic imports: `import\(['"].*<filename-without-ext>['"]\)`
- Re-exports: `export \*? from ['"].*<filename-without-ext>['"]` and `export \{[^}]*\} from ['"].*<filename-without-ext>['"]`
- Path-aliased imports: read `tsconfig.json` → `compilerOptions.paths`. For each alias that maps to a folder containing the changed file, also grep for `from ['"]<alias>`
- Barrel files: if the changed file's parent folder has an `index.ts(x)`, check whether the barrel re-exports this file; if yes, also find consumers of the barrel

**Dart (Flutter):**
- `import ['"].*<filename>['"]` — absolute + relative
- `package:<app-name>/.../<filename>` — package-style

**Shared types / DTOs:** don't grep the bare type name (too noisy — `User`, `Config`, `Item` match everywhere). Instead grep for the **import site**: `import.*<TypeName>.*from` or `import type.*<TypeName>`. Follow to usage from there.

**Prisma schema:** if a model `Foo` changed, grep for `prisma\.foo\.` (camelCase) and `from '@prisma/client'` to find the consumer surface, then narrow by model field.

**API contracts:** if an endpoint path or DTO changed, grep for the path **string literal** (e.g. `'/api/users/'`) across both the caller repo and mobile/web clients in the workspace.

**Do not grep for files in these paths:** `node_modules/`, `.next/`, `dist/`, `build/`, `coverage/`, `.turbo/`, `ios/Pods/`, `android/build/`, `*.lock`, `*.lockb`, generated folders (`prisma/generated/`, `*.g.dart`, `*.freezed.dart`).

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
- Changed a Prisma schema model
- Changed an environment variable name
- Modified a shared type (Zod schema, DTO, Prisma model, shared interface)
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
- Has a single clear goal ("verify craft rules on 6 web files")
- Produces one mini-report before moving to the next batch

Batch ordering: direct tasks first → consumers after → high-blast-radius last (because they need all direct verifications first).

Record the batch plan with a summary message:

```
Plan: <N> tasks in <M> batches.
  Batch 1: <stack> × <dimension> — <file count> files
  Batch 2: ...
```

Don't claim exact token budgets — you can't introspect them. File count and batch count are the honest proxies.

Show the plan, then ask *"Proceed?"* The user may adjust scope, drop dimensions, or approve. Don't start Batch 1 without a confirmation — the plan is where the user catches misread scope before it costs 20 tool calls to discover.

---

## Phase 4 — Batch execution

**The key discipline: between batches, write progress to task metadata (via `TaskUpdate`), not into the running conversation.** Findings that later phases need must live in task metadata, not as quoted evidence in intermediate messages.

### 4.1 — Per-batch loop

For each batch:

1. **Mark batch tasks in_progress** via TaskUpdate
2. **Load only what's needed** — read the files in this batch, load only the standards skill relevant to this batch's dimension. Don't pre-load the whole pack.
3. **Iterate rule-by-rule** — for every rule in the loaded dimension's SKILL.md, produce one record per (rule × file):
   - **Rule ID or heading** — the section/rule identifier from the skill (e.g. `craft-guide §4.2` or `nestjs — controller split`). Never collapse multiple rules into one record.
   - **Evidence** — a direct quote from the file with `path:line`, or the literal string `no occurrence` if the rule does not apply to anything in this file.
   - **Verdict** — exactly one of `PASS`, `FAIL`, `N_A`. `N_A` **requires** a one-line reason (e.g. "file has no color tokens — rule about color harmony doesn't apply"). Bare `N_A` without reason is invalid and must be re-run.
   - **Suggested fix** — only on `FAIL`. One line. The minimum change that resolves the rule.
   
   Walk every rule in order. Never skip a rule because it "seems unrelated" — record `N_A` with reason instead. Never stop mid-dimension on the first FAIL; collect them all.
4. **Record results in task metadata**:
   ```
   TaskUpdate: status=completed, metadata={ pass_count, fail_count, fails: [{ rule, file, line, evidence, suggested_fix }] }
   ```
5. **Emit a compact batch summary** (under 100 words): "Batch N done. X PASS, Y FAIL. Top failures: ..."
6. **Move on** — don't re-quote Batch N's full records into the next message. They're in task metadata; Phase 5 reads them back. The conversation context still carries prior tool output, but you control what you re-emit — keep subsequent messages lean.

### 4.2 — Why metadata-first works

Each task's metadata stores:
- `fails` (array of specific failures — if >15 per task, store top 15 + total count to keep metadata readable)
- `suggested_fixes` (for later fix phase)
- `blockers_resolved` (did this task unblock any others?)

Phase 5 reads task metadata selectively (critical + consumer tasks in full, the rest via `TaskList` counts). Prior tool output still sits in the conversation — you can't delete it — but you control what you re-quote. Lean batch summaries + rich task metadata is the combination that keeps attention focused without losing recoverable detail.

### 4.3 — Stop conditions

Stop and report mid-run if:
- A **CRITICAL** failure is found — concretely: a hardcoded secret committed, a removed-auth-check on a protected route, an env-var reference that no longer exists, a migration containing `DROP COLUMN` / `DROP TABLE` / a new `NOT NULL` without default, a breaking change to an exported public signature. These need user attention before any more audit time is spent.
- A consumer verification reveals the change will definitely break production — a renamed export is still imported by name, a removed Prisma field is still read, a Zod schema no longer matches the route's request shape.
- You've completed more batches than originally planned and are still finding new dependencies to check — checkpoint and ask whether to continue or stop.

(Don't try to detect "context usage percent" — you can't. Use batch count and elapsed tool calls as the proxy.)

---

## Phase 5 — Consolidated report

After all batches complete (or stopped):

1. Call `TaskList` once — this gives summaries, not full metadata, so it's cheap.
2. For each task whose summary indicates `status: completed` with failures recorded, call `TaskGet` **only if** the task's batch summary you emitted earlier doesn't already cover it. Re-read is expensive; the batch summaries you already emitted are often enough.
3. **Don't `TaskGet` every task.** On a 200-task run, reading all metadata reintroduces exactly the context bloat batching was designed to avoid. Prefer: read only critical / consumer-break tasks in full; fold the rest via counts from `TaskList`.

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
  [any consumer task that FAILed because of a direct change — e.g. "auth.ts's rename broke login.tsx:24"]

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
7. Before re-emitting the final report, check: is any file now being edited by this skill that's protected by `core-hooks`' `protect-files.sh` (e.g., `.env`, credentials, lockfiles)? If so, hooks will block the edit — don't retry, surface the intent and let the user decide.
8. Re-emit the final report with a new section: `Stuck after 3 attempts` listing the (rule, file) pairs the user needs to resolve manually.

---

## For plugin authors — the thin-wrapper pattern

Stack-specific audit commands (`premium-check`, `pre-ship`, `theme-audit`, `verify-screens`, etc.) should **not** reimplement the iterate-rule-by-rule loop, the batching logic, the task metadata discipline, or the PASS/FAIL report format. All of that lives here.

A stack command is a thin wrapper that:

1. Parses its slash-command `$ARGUMENTS` (or defaults to "uncommitted working tree").
2. Emits the structured brief shown in the Invocation section above, pre-filling:
   - `scope` — from `$ARGUMENTS` or the command's natural default
   - `dimensions` — the subset of installed skills this command cares about (e.g. premium-check → `[craft-guide]`; theme-audit → `[craft-guide §13]`; pre-ship → `[ALL stack pack]`)
   - `depth` — usually `direct` for focused audits, `direct+consumers` for pre-ship
   - `fix` — `yes` if the command is named with "fix" in the intent; `no` otherwise
3. Delegates to this skill.

That's the whole wrapper. Stack commands add value by **picking the right dimensions** for their audience — not by reimplementing the engine. See `contributing.md` for the full pattern and examples.

---

## Principles

**Generic over specific.** This skill does not care whether the stack is Flutter, NestJS, Next.js, or anything else. It reads whatever SKILL.md files are installed and applies them. Adding a new stack requires no change to this skill.

**Dependency-aware over file-scoped.** A per-file audit misses "this change broke something that imports it." The graph walk is the main value-add over `pre-ship`.

**Batched over single-pass.** Big changesets blow context in one pass. Batches of 5–10 tasks with checkpointed metadata keep the model focused and the run resumable.

**Ask over assume.** Scope, dimensions, and depth are three decisions that change the run's cost 10×. Ask up front — answers are cheap.

**Pure prompt, no infrastructure.** Uses only Read / Grep / Glob / Edit / TaskCreate / TaskUpdate. No hooks, no MCPs, no indexing, no vector DBs, no external models. Works on any machine with Claude Code installed.

---

## Relationship to other skills — precedence rules

Several skills auto-invoke on similar triggers. Collisions and double-runs waste tokens. Use these rules:

- **Stack-pack audit commands delegate to this skill.** `/web-standards:pre-ship`, `/web-standards:premium-check`, `/web-standards:theme-audit`, `/web-standards:aesthetic-coherence`, `/flutter-standards:pre-ship`, `/flutter-standards:premium-check`, `/flutter-standards:verify-screens` are thin wrappers that pick a scope + dimensions + depth and invoke this skill. They do not re-implement iteration, batching, or fix loops. If a user runs one of those commands, treat it as a `verify-changes` invocation with the brief that command supplied — don't re-run either side.
- **When invoked directly** (user says "verify my changes" / "cross-check" without a pack-specific command), run the interactive-mode Phase 1 scope dialogue.
- **`docs-sync` runs *after* this skill completes**, not as a dimension inside it. When `verify-changes` finishes and the scope included `.md` edits or a version bump, emit a line at the end of Phase 5: *"Next: running docs-sync for drift check."* Let `docs-sync` handle it — don't duplicate.
- **`subagent-brief`** is not a trigger peer — it governs delegation discipline. If, and only if, this skill delegates a batch to a subagent, the Agent prompt follows `subagent-brief`'s template.

If the user explicitly invokes a specific skill by name, respect that — don't override their choice with this skill.

---

## Anti-patterns

- **"Just audit everything"** — no scope, no dimensions, no depth. Always at least echo defaults back and confirm.
- **Skipping the dependency graph** — "I'll just check the changed files" misses the whole point of the skill. If the user said "direct only," that's their choice; don't skip it silently.
- **Stuffing all results in one message** — use task metadata; emit batch summaries, not full dumps.
- **Ignoring CRITICAL stops** — if auth is broken mid-run, halt and surface. Continuing to audit motion timing while a prod-breaking change sits unfixed is malpractice.
- **Reverifying unchanged rules after a fix** — only re-run the rule × file that was fixed, not the whole batch.

---

## Concrete example — a mid-size Next.js change

Scope: uncommitted working tree. SMART dimensions. Depth: direct + consumers.

```
Discovered: 8 changed files (components/ui/Button.tsx renamed + 2 new routes + 5 call sites updated).

Graph:
  components/ui/Button.tsx → 12 consumers (rg found them)
  app/dashboard/page.tsx → 2 consumers
  ...

Plan: 34 tasks in 5 batches.
  Batch 1: web × craft-guide — 8 direct files
  Batch 2: web × nextjs — 8 direct files
  Batch 3: web × production-readiness — 2 new route files
  Batch 4: consumers × nextjs (breakage check) — 12 consumer files
  Batch 5: docs-sync handoff — CHANGELOG / README drift

Proceed? (y/n)
```

User says yes. Each batch runs, emits a short summary, records results in task metadata. At the end, Phase 5 reads only critical / consumer-break tasks in full, folds the rest via `TaskList` counts, emits the consolidated report.

The win over a single-pass "audit everything" isn't a specific token count — it's that consumer breakage gets caught at all (single-pass per-file audits miss it), and large changesets don't collapse the run halfway through from lost attention.
