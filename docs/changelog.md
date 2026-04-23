# Changelog

All notable changes are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/). Versions follow [SemVer](https://semver.org/).

---

## [0.12.0] — 2026-04-22

Three-layer architecture finalised. `core-skills` retired; `core-standards` replaces it as the single cross-stack plugin. Stack skills trimmed to remove universal content that now lives in `core-standards:rules`.

### Added — `core-standards` plugin

- New plugin replacing `core-skills`.
- Moved from `core-skills`: `verify-changes`, `docs-sync`, `subagent-brief`.
- New universal skills: `principles`, `planning`, `agents`, `rules` (§1–§5), `verification`, `mcp-integration`.

### Changed — `verify-changes`

- Removed: concrete examples, Anti-patterns section, stack-specific dependency patterns from Phase 2.2.
- Added: six verdict types — `PASS`, `FAIL`, `N_A`, `INFO`, `REVIEW`, `CONFLICT` — with precedence rules and Rules vs Guides distinction.

### Changed — `subagent-brief`

- Added `## RULE — enforced by hook` section: non-advisory, names required sections.
- Added `## GUIDE — advisory judgment calls` section header before the decision trees.

### Changed — `protect-files` and `protect-bash` hooks

- Both read `allowed_files` / `allowed_commands` from `.claude/enforcement.json` (walk-up up to 20 hops). Fail-open.

### Changed — `flutter-standards` stack trimming

- `engineering`: removed universal DRY/security concepts. Added reference to `core-standards:rules §1–§4`.
- `observability`: removed generic logging rules. Kept Firebase-specific patterns.
- `testing`: removed pyramid/coverage/CI concepts. Kept Flutter-specific widget/integration/golden patterns.
- `find-hardcoded`, `find-duplicates`, `audit-a11y-patterns`: trimmed to scan-command only — grep table, ignore list, report format. Rules delegated to owning standards skills.
- `performance`: added motion cross-reference to `craft-guide`.

### Changed — `api-standards` and `web-standards`

- `code-quality`: removed A3/A4 (covered by `rules §4`). Added preamble reference.
- `production-readiness`: added preamble reference to `core-standards:rules`.

### Versions

- Marketplace: `0.11.0` → `0.12.0`; `core-hooks`: `0.11.0` → `0.12.0`; `core-standards` (new): `0.1.0`

---

## [0.11.0] — 2026-04-22

Delegation quality system. The `subagent-brief` skill existed but was advisory — sessions forgot it and kept burning tokens on cold Task/Agent spawns that re-read everything the parent already had. This release turns delegation quality into a three-layer system: skill teaches scope judgment, hook enforces a floor, SessionStart preamble keeps it top-of-context.

### Added — skill rewrite (`core-skills:subagent-brief`)

- Rewritten around three explicit decisions (in order):
  1. **Spawn or inline?** — decision table with kill-questions and positive signals. Hardest rule: "never delegate understanding."
  2. **How many agents?** — count cheat-sheet (1 / N-disjoint / don't) with rules for parallel vs serial delegation. Explicit call-out: the hook *cannot* cap agent count — that's model judgment, this skill owns it.
  3. **What goes in the prompt?** — warmth-signal breakdown that matches the hook's scoring (labeled sections + code fence + file paths). Brief template with annotated bad→good example. Explicit "paste excerpts, not file names" guidance with before/after.
- Anti-patterns and winning patterns kept from v0.9.0, reorganized.
- New section naming the hook as the backstop, explaining the hook is the floor and the skill is the ceiling.

### Added — `enforce-subagent-brief.sh` (PreToolUse hook)

- Matches `Task|Agent`. Inspects `tool_input.prompt` and exits 2 when the warmth score falls below the scope-scaled bar.
- **Warmth signals** (summed):
  - Labeled section header (1 each) — `GOAL:`, `**Goal**:`, `## Goal`, `## Goal:`, with case-insensitive match. Markers: `GOAL`, `CONTEXT`, `SCOPE`, `TASK`, `OUTPUT`, `DELIVERABLE`, `BUDGET`. End-of-label matches `:` OR end-of-line so heading-only form works.
  - Code fence (```) — 1 point if any triple-backtick block appears. Presence of a pasted excerpt is the strongest warmth signal.
  - File paths with a known extension (1 each, capped at 2) — e.g. `src/auth.ts`, `lib/foo.dart:42`. Cap prevents a long path list from dominating.
- **Scope bar** (proxy: prompt length):
  - `<400` chars — trivial lookup, passes through (0 required)
  - `400–1500` — medium, requires score ≥ 2
  - `≥1500` — heavy, requires score ≥ 3
- **Error message** names the score, the breakdown, and the three ways to add warmth. Explicit nudge: *paste the excerpt instead of the file name*.
- Project-level escape hatch: `.claude/enforcement.json` → `"warm_brief_required": false`. Walks up to 20 parent dirs so multi-project session roots still find the config.
- Fail-open on every internal error path (missing jq, missing input, grep failure). A bug here cannot strand a session.

### Added — SessionStart preamble nudge

- `rules-discipline.sh` now appends one paragraph pointing Claude at `core-skills:subagent-brief` before calling Task or Agent. Keeps the skill top-of-context so the first spawn is warm without needing a block-and-retry round trip.

### Changed

- `core-hooks` bumped to 0.11.0; marketplace metadata bumped to 0.11.0.
- `core-hooks` plugin description updated to name the new hook + preamble nudge.
- `docs/enforcement.md` gains a new `## Delegation quality (v0.11.0)` section covering the three-layer system, warmth scoring, scope bar, escape hatch, and "what the hook does NOT do."

### Fixed

- **Escape-hatch flags in `.claude/enforcement.json` now actually disable enforcement.** Both `enforce-subagent-brief.sh` and `stop-gate.sh` read their opt-out flags (`warm_brief_required`, `gate_required`) through `jq -r '.x // true'`. jq's `//` alternative operator treats both `null` and `false` as "absent", so an explicit `"x": false` in the config was silently replaced by `true` — the flag read back as on regardless of the user's intent. Fixed by dropping the `// true` fallback and relying on a direct string comparison: a missing key now emits `"null"` (preserves default-on), while an explicit `false` is respected. Surfaced during v0.11.0 smoke testing of the delegation-quality hook.

### Motivation

Recorded failure mode: a session at `lavamgam/` (parent of four sub-projects) spawned an Explore agent with a one-line prompt. The agent burned ~71k tokens re-reading files the parent already had in context. `subagent-brief` described the fix but didn't force it — next session, Claude forgot and did the same thing. Plugin-level enforcement is the only mechanism that persists across sessions without per-project memory discipline. The hook is deliberately scope-scaled (trivial lookups pass) so ceremony doesn't get in the way of small work, and deliberately does *not* cap agent count — that judgment lives in the skill where the model can reason about it.

---

## [0.10.0] — 2026-04-22

Enforcement mode. Auto-invoke skills are advisory — Claude decides when to load them. Teams who want hard guarantees (rules that cannot be quietly skipped, gates that cannot be bypassed) now opt in by committing one file. Existing installs are unaffected; enforcement is strictly additive.

### Added — opt-in enforcement mode

**Project config — `.claude/enforcement.json`** (new file; commit it):

```json
{
  "mandatory": ["flutter-standards"],
  "disabled_rules": ["flutter.perf.listview-unbounded"],
  "gate_required": true
}
```

Three knobs — flat JSON, no DSL:

- `mandatory` — packs to enforce (reads each pack's default from `core-hooks/enforcement/<pack>.json`)
- `disabled_rules` — rule IDs to skip (for project-specific exceptions)
- `gate_required` — set `false` for advisory-only (PreToolUse still blocks, Stop hook becomes a nudge)

**New hooks — `core-hooks`**

- `enforcement-preamble.sh` (SessionStart, startup + compact matcher) — when the project has opted in, injects a pinned preamble listing each mandatory pack's required skills, deterministic rule IDs, and gate command. Re-injects after context compaction.
- `enforce-rules.sh` (PreToolUse, Edit|Write|MultiEdit) — reads each mandatory pack's rule registry, runs every rule's regex against tool content, exit 2 with message on any violation. Also marks `<pack>.touched` in the session ledger so the Stop hook can enforce the gate.
- `stop-gate.sh` (Stop) — if any mandatory pack is `touched` but not `gate_passed`, exit 2 with a message telling Claude to run the pack's gate command. Stop hook exit 2 keeps the turn open; Claude cannot say "done" until the ledger flips.
- `session-ledger.sh` — shared helper. Session-scoped flags under `/tmp/claude-craft-session-$CLAUDE_SESSION_ID/<pack>.<flag>`. CLI mode: `mark-pass`, `mark-touched`, `has-touched`.

**Default rule registries — one JSON file per pack**

- `core-hooks/enforcement/flutter-standards.json` — mandatory skills: craft-guide, widget-rules, accessibility, performance. Gate: `/flutter-standards:pre-ship`. Rules: IconButton without a11y label, `print()` in `lib/**`, un-virtualized ListView.
- `core-hooks/enforcement/web-standards.json` — mandatory skills: nextjs, craft-guide, production-readiness. Gate: `/web-standards:pre-ship`. Rules: raw `<img>` without alt, `console.log` in source, `dangerouslySetInnerHTML`.
- `core-hooks/enforcement/api-standards.json` — mandatory skills: nestjs, code-quality. No gate (audit-only pack). Rules: empty `catch { }`, `console.log` in `src/**`, Prisma `$queryRawUnsafe` / `$executeRawUnsafe`.

Rule count is deliberately small at v0.10.0 — rules must be deterministic (regex-level) to avoid false positives. Craft / aesthetic / architecture concerns stay in standards skills and get enforced at the gate stage via the engine.

**Gate commands write the ledger**

`pre-ship` SKILL.md (Flutter + Web) instructs Claude to run `session-ledger.sh mark-pass <pack>` on SAFE TO COMMIT. On FAIL, the ledger is not touched — Stop hook stays firm.

### Design rationale — generic runner, declarative config

Before v0.10.0, enforcement was limited to the hardcoded token/secret blocks in `enforce-tokens.sh` + `protect-files.sh` + `protect-bash.sh`. Adding a new rule meant editing bash. v0.10.0 inverts that:

- Core-hooks ships a **generic rule runner** — `enforce-rules.sh` reads JSON, runs regex, blocks.
- Each pack ships a **declarative rule registry** — `enforcement/<pack>.json`.
- Adding a rule = one JSON entry. No bash changes in `core-hooks`.
- Adding a new pack's enforcement = one JSON file. Core-hooks discovers it via the `mandatory` array.

This matches the claude-craft pattern: generic infrastructure in `core-*`, per-pack content owned by the pack.

### Limitations — honest, not hidden

- **Hooks don't fire inside subagents.** Work delegated via `Agent` / `Task` bypasses enforcement. Mitigation: `subagent-brief` should carry the pack's contract; brief the delegate explicitly.
- **PostToolUse cannot undo writes.** The block happens at PreToolUse or not at all. Rules that need post-write validation (lint errors, type errors) belong in the gate, not the rule registry.
- **Rule authoring is regex-only.** AST-level checks (unused variables, control-flow analysis) are not supported in v0.10.0 — use existing tooling (`flutter analyze`, `npm run lint`, `prisma validate`) via the gate's pre-flight step.
- **Claude can ignore preambles.** SessionStart `additionalContext` is text, not enforcement. The hard guarantees come from PreToolUse (blocks) and Stop (gate). Preambles tell Claude *what* to do; blocks + gates enforce *that* it did.

### Infrastructure

- `core-hooks` bumped to `0.10.0`.
- Marketplace metadata version bumped to `0.10.0`.
- Other plugins unchanged (`flutter-standards` `0.9.0`, `web-standards` `0.9.0`, `core-skills` `0.9.0`, `api-standards` `0.5.0`).
- New doc: `docs/enforcement.md` — global + project setup, rule authoring, rollout pattern.
- `README.md`, `docs/skills.md`, `docs/contributing.md`, `ROADMAP.md` updated.

---

## [0.9.0] — 2026-04-21

Thin-wrapper architecture. Audit commands become ≤50-line scope + dimension pickers; iteration, batching, and the fix loop live once in the engine. Rules stay in standards skills. Hooks stay deterministic. Three owners, one architecture.

### Changed — isolated ownership

Every audit slash command now parses `$ARGUMENTS`, optionally runs a stack-specific pre-flight (`npm run lint`, `flutter analyze`), emits a structured brief to `core-skills:verify-changes`, and stops. The engine owns the dependency walk, the batched rule-by-rule iteration, the PASS / FAIL / N_A accounting, the 3-retry oscillation detection, and the optional fix loop. One iteration implementation instead of seven drifting copies.

**Web pack (`web-standards`)** — thin-wrapped:
- `/web-standards:pre-ship` — dimensions: every web-standards skill. Depth: direct+consumers. Pre-flight: `npm run lint`.
- `/web-standards:premium-check` — dimensions: `craft-guide §1 – §15`. Depth: direct. Asks aesthetic + density if ambiguous before delegating.
- `/web-standards:theme-audit` — dimensions: `craft-guide §13 + §1.5 + §11.3 + §11.5 + §12.7–§12.9`. Pre-flight: halts if `design-tokens.md` missing, suggesting `extract-tokens` first.
- `/web-standards:aesthetic-coherence` — hybrid. Keeps its own signal-detection + classification pass (Steps 1–3, no engine equivalent), then delegates `craft-guide §9` compliance to the engine. Fix loop stays manual-confirmation — aesthetic is a taste call, not rule-driven.

**Flutter pack (`flutter-standards`)** — thin-wrapped:
- `/flutter-standards:pre-ship` — dimensions: every flutter-standards skill. Depth: direct+consumers. Pre-flight: `flutter analyze`.
- `/flutter-standards:premium-check` — dimensions: `[craft-guide, widget-rules, accessibility, performance]`. Depth: direct.
- `/flutter-standards:verify-screens` — dimensions: `[api-data, widget-rules, craft-guide]`. Depth: full-ripple (follows screen → provider → repository → data source).

**Flutter pack — rename:**
- `accessibility-audit` → **`audit-a11y-patterns`**. The old name implied it was THE a11y audit; it's actually a fast Flutter-specific regex sweep for 10 recurring bugs. The engine-walked `accessibility` auto-invoke skill is the comprehensive audit. The rename reflects what the skill actually does.

### Added — rule IDs

- `craft-guide` (web) now has a canonical Rule Index at the top (§1.1 – §15.5) listing every rule with stable IDs grouped by section. Commands scope to subsets (`theme-audit` → `§13`) instead of duplicating iteration. §16 and §17 flagged as summary sections, not iteration targets.
- `production-readiness` (web) now has a §R1 – §R10 Rule Index for its 10 readiness concerns.
- Flutter standards keep whole-skill scoping (no fine §N.M IDs added) — thin-wrappers pass skill names as dimensions.

### Added — engine + contributing

- `core-skills:verify-changes` gains an **Invocation — interactive vs delegated** section defining the structured brief format (`scope`, `dimensions`, `depth`, `fix`, `source`, optional `context`) that thin-wrappers emit.
- **Iteration-loop discipline** inlined into `verify-changes` Phase 4.1 (previously backref'd to premium-check): record per (rule × file) with rule ID + evidence (path:line or "no occurrence") + PASS/FAIL/N_A verdict (N_A requires reason) + suggested fix on FAIL; never skip, never collapse; 3-retry cap on (rule × file) fix attempts.
- **`docs/contributing.md`** gains an "Adding an audit slash command — the thin-wrapper pattern" section with a skeleton template, dimension-picking examples, guidance on when NOT to thin-wrap (detection-only passes, scaffolds that generate files), and a "Rule IDs in standards skills" subsection.

### Design rationale — three owners

Before v0.9.0, audit commands mixed ownership: each one defined its own iteration loop, batching strategy, and fix-retry policy. When one command improved (e.g., 3-retry oscillation cap) the others drifted. Thin-wrappers solve this by isolating responsibilities:

- **Standards skills** own *rules* (content: what "correct" means, with stable IDs).
- **Core engine** owns *orchestration* (iteration, batching, graph walk, fix loop).
- **Core hooks** own *deterministic enforcement* (regex-level blocks that don't need reasoning).

Each owner has one reason to change. Adding a rule doesn't touch orchestration; adding a new stack pack doesn't touch the fix loop.

### Infrastructure

- `web-standards`, `flutter-standards`, `core-skills` bumped to `0.9.0`.
- `api-standards` stays at `0.5.0` and `core-hooks` stays at `0.8.0` (no behavior change; marketplace allows plugin versions to drift independently).
- Marketplace metadata version bumped to `0.9.0`.
- `docs/skills.md`, `README.md`, `ROADMAP.md` updated to describe the thin-wrapper shape.

---

## [Pre-0.9.0] — foundation (2026-04-20 → 2026-04-21)

Initial authoring, collapsed from nine point releases. Per-version detail is in the git history.

- **0.1.0 – 0.2.0** — three stack packs (`flutter-standards`, `api-standards`, `web-standards`) + `core-hooks`, multi-tool export to Cursor / `AGENTS.md`. Public release moved the repo to `pixelcrafts-app/claude-craft` and consolidated 15 standalone per-skill plugins into one bundle per stack; namespaced slash commands (`/<pack>:<command>`) replaced the per-skill plugins.
- **0.2.1 – 0.3.0** — "verify, don't guess" cross-boundary contract rule added to every pack. Smart production-readiness audits landed: `api-standards:code-quality` gained 11 operational checks (J1–J11), Flutter and Web gained new `production-readiness` skills (R1–R9 / R1–R10). Contextual concerns follow Detect → Check → Suggest — the skill never rewrites the app.
- **0.4.0** — `docs-sync` skill (end-of-task drift check between code and docs). Pre-ship gates include a docs-sync step.
- **0.5.0** — Web design pack. New `craft-guide` auto-invoke standard covering contrast, harmony, spacing, type, shadow/radius, motion, state variants, density, 14 named aesthetics, chrome, a11y, theme, microcopy, brand moments. New explicit skills: `premium-check` (iteration-loop), `extract-tokens`, `theme-audit`, `aesthetic-coherence`. Universal formulas enforced; brand values always from the user.
- **0.6.0** — `verify-changes` (cross-stack, dependency-aware audit engine, pure prompt — no MCPs, no indexing) and `subagent-brief` (warm-brief delegation discipline) shipped.
- **0.8.0** — isolated-ownership cleanup. Split `core-hooks` into two plugins: `core-hooks` (hooks only) and `core-skills` (the three cross-stack skills). Removed the pre-defined review-agent personas — the project does not own when Claude spawns agents.
