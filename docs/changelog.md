# Changelog

All notable changes are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/). Versions follow [SemVer](https://semver.org/).

---

## [0.6.0] — 2026-04-21

### Added — core-hooks

- **`subagent-brief` skill** — auto-invoke skill that enforces warm-brief discipline when delegating to Agent / Task / Explore / Plan / general-purpose subagents. A subagent is a fresh Claude instance with no memory of the current conversation; handing it an open-ended task causes it to re-discover context already in hand, burning 3–10× the tokens of a precise brief. Provides a concrete brief template (GOAL / CONTEXT / SCOPE / TASK / OUTPUT SHAPE / BUDGET), named anti-patterns, patterns that win, reasonable token-spend bands.
- **`verify-changes` skill** — generic cross-stack verification workflow. Fires when the user asks "verify my changes" / "cross-check" / "audit what I did" or ends a non-trivial chunk of work. Six phases: scope dialogue (what to cover, which dimensions, how deep), discovery + dependency graph (rg-based consumer detection), TaskCreate plan (dependency-aware task tree, batches of 5–10), batch execution (iterate rule-by-rule per batch, record results in task metadata to preserve context), consolidated report (critical / polish / consumer-break verdict), optional fix loop. Stack-agnostic — reads whichever SKILL.md files are installed. Pure prompt — no hooks, no MCPs, no indexing infrastructure. Replaces the "install indexing MCP" path: generic, robust, works on any repo size without external dependencies.

### Design rationale

Indexing MCPs (serena, claude-context, Graphiti) all require per-stack or infrastructure dependencies (LSPs, embedding models, vector DBs). `verify-changes` achieves the core benefit — dependency-aware, context-preserving verification of a changeset — using only built-in Claude Code tools (Read / Grep / Glob / Edit / TaskCreate). No per-stack setup, no install ceremony, works on Flutter / API / Web / future stacks identically.

### Infrastructure

- `core-hooks` bumped to `0.6.0`.
- Marketplace metadata version bumped to `0.6.0` to reflect the new skill.
- Other plugins unchanged at `0.5.0`.

---

## [0.5.1] — 2026-04-21

(Superseded by 0.6.0 — `subagent-brief` shipped as part of the 0.6.0 bundle.)

---

## [0.5.0] — 2026-04-21

Web design pack. The web standards move from "covers Next.js patterns" to "covers premium visual craft end-to-end," with a strict separation: **universal formulas enforced, brand values from the user.** Never imposes colors, fonts, or aesthetics.

### Added — Web pack (`web-standards`)

**Auto-invoke standard — `craft-guide` (new)**

17-section universal design guide covering color + contrast + harmony (WCAG AA 4.5:1 floor, AAA 7:1 premium, APCA awareness, color harmony commitment, 60-30-10 distribution, brand → UI derivation, tinted neutrals), spacing rhythm, modular type scale + font loading discipline, shadow & elevation scale, border radius scale + nested-radius math, motion choreography (3-layer stack, exit-faster-than-entry, `prefers-reduced-motion`), all state variants (4 primary + 8 edge states including offline, stale, partial, pending, rate-limited, permission-denied, success, rollback), responsive + density matched to app type (safe-area insets, `dvh`, thumb zone, tablet-as-its-own), 14 named aesthetics with per-aesthetic specs (minimalist, flat, material, utility-brutalist, glassmorphism, neumorphism, claymorphism, liquid glass 2026, bento, editorial, brutalist, dark-cinematic, AI-native, retro/Y2K) + "never mix two" rule, iconography, chrome & details (focus rings, selection, scrollbar, caret, cursor, text rendering, image treatments), accessibility as craft (`color-scheme`, forced-colors, reduced-transparency, focus trap, lang), theme discipline (SSR hydration flash, light/dark parity, multi-theme), microcopy rules, brand moments (404, 500, splash, offline, first-run, update).

Every section has an "enforce / provide" table — what the skill requires from any brand vs. what the brand itself supplies.

**4 explicit skills**

- `/web-standards:premium-check` (rewritten) — iteration-loop craft audit. Walks every rule across 17 sections one at a time, records PASS / FAIL / N_A with evidence, loops fix-then-audit until zero FAILs. Replaces the single-pass 6-category sweep.
- `/web-standards:extract-tokens` (new) — reads Tailwind config / `@theme` / CSS vars / shadcn setup, OR parses user-provided brand input (paste, Figma export, image, PDF), normalizes into six-dimension token map, writes `design-tokens.md` as single source of truth.
- `/web-standards:theme-audit` (new) — verifies theme completeness: token discipline, semantic naming, light/dark parity (detects computed-invert), `color-scheme`, SSR hydration flash, switch coverage across every route, multi-theme readiness.
- `/web-standards:aesthetic-coherence` (new) — scores 14 aesthetic signatures per file, flags files with top-2 scores within 30% (mixed aesthetic — the #1 "assembled, not designed" tell), flags cross-file outliers, proposes fixes per file with user confirmation.

### Design principle — universal formulas only

Every rule categorized as **enforce** (math / structure — WCAG contrast, 60-30-10 distribution, single modular scale, safe-area insets) or **provide** (brand values — chosen hues, chosen aesthetic, density target). The skills never pick brand values; they enforce discipline over whatever the user chose.

### Infrastructure

- All four plugins bumped to `0.5.0` in lockstep.
- Marketplace + plugin descriptions updated.
- `docs/skills.md` updated — web pack now lists 3 auto-invoke + 5 explicit skills.

---

## [0.4.0] — 2026-04-20

### Added — cross-stack

- **`docs-sync` skill in `core-hooks`** — catches drift between code and docs at end-of-task moments. Auto-invokes on version bumps, plugin add/remove, new skill folders, pre-ship runs, `v*.*.*` commit messages, or when the user signals task completion ("ship / done / release"). Cross-checks README, CHANGELOG, ROADMAP, `docs/skills.md`, and plugin/skill descriptions. Flags gaps. Never rewrites prose. Never blocks.
- **Pre-ship gates (Flutter + Web)** now include an end-of-task docs-sync step — skipped for single-file fixes and internal refactors, runs on feature/release completion.

### Changed

- **README rewrite** — hero section, visual architecture diagram, before/after callout, pack cards, Detect→Check→Suggest example output, audience section. Aims to be the pitch itself, not a manifest.
- **`docs/before-after.md`** — new template for real before/after snippets per pack. Empty scaffolds; fill in over time.
- **`core-hooks` plugin** — now hosts both safety hooks and the `docs-sync` skill. Description updated in `plugin.json` and `marketplace.json`.

### Infrastructure

- All four plugins bumped to `0.4.0` in lockstep.

---

## [0.3.0] — 2026-04-20

Smart production-readiness audits land in all three packs. Rigid "you must have X" rules are reserved for binary requirements (auth guards, no PII in logs, etc.). Contextual concerns — anything that depends on scale, audience, or infra — now follow **Detect → Check → Suggest**: the skill detects whether it's already addressed, audits depth if yes, and proposes options with tradeoffs if no. The user decides — the skill never rewrites the app.

### Added — API pack (`api-standards`)

11 new production operational checks in `code-quality` (section J):

- J1. Rate limiting / throttling
- J2. Idempotency keys on mutations
- J3. Retry + backoff on upstream calls
- J4. Webhook signature verification
- J5. Graceful shutdown (SIGTERM + drain)
- J6. Health + readiness endpoints (liveness vs readiness)
- J7. Correlation IDs / request tracing
- J8. Soft-delete vs hard-delete policy
- J9. Audit logs for sensitive mutations
- J10. DB connection pool + query timeouts
- J11. Environment-aware logging (level / format / redaction / sampling per env)

### Added — Flutter pack (`flutter-standards`)

New auto-invoke skill `production-readiness` with 9 smart checks:

- R1. Retry + backoff on network calls
- R2. App lifecycle handling (pause / resume / detached)
- R3. Deep linking / universal links
- R4. Push notification permission UX (pre-prompt rationale)
- R5. App version / force-update gate
- R6. Secure storage for sensitive data
- R7. Locale + RTL support
- R8. Offline support + sync queue
- R9. Env-aware logging and observability

### Added — Web pack (`web-standards`)

New auto-invoke skill `production-readiness` with 10 smart checks:

- R1. Error boundaries scoped per route
- R2. Suspense boundaries for streaming
- R3. Optimistic updates + rollback on failure
- R4. Image optimization (`next/image`, sizes, priority, remote patterns)
- R5. Metadata / OG / Twitter cards
- R6. Sitemap + robots.txt
- R7. CSP + security headers
- R8. Analytics consent / cookie handling (EU/UK/CA)
- R9. Core Web Vitals budgets (LCP / INP / CLS)
- R10. Env-aware logging (server-side)

### Infrastructure

- All four plugins bumped to `0.3.0` in lockstep.
- Marketplace and plugin descriptions updated to reflect the new audits.

---

## [0.2.1] — 2026-04-20

### Added

- **Verify, don't guess — cross-boundary contracts.** New discipline rule across all three packs: when code crosses a boundary (API call, env var, third-party SDK, DB column, shared type), read the source of truth before assuming its shape. Never invent field names or response types from context. If the source isn't readable, ask the user a concrete question. Surface unverified assumptions at the end of each response.
  - Flutter: added to `engineering` standard.
  - API: added to `code-quality` audit (checks V1–V6).
  - Web: added to `nextjs` standard.
  - Pre-ship gates (Flutter + Web) now include a cross-boundary contract step.

---

## [0.2.0] — 2026-04-20

First public release. Repo moved to `pixelcrafts-app/claude-craft`.

### Breaking

- **Standalone per-skill plugins removed.** Previous versions shipped every audit/scaffold/workflow skill twice — once inside the stack bundle and once as its own plugin (`flutter-pre-ship`, `flutter-scaffold-feature`, `web-premium-check`, `api-sync-migrate`, etc.). Every skill is still available via its namespaced slash command (`/flutter-standards:pre-ship`, `/api-standards:sync-migrate`) — just install the bundle. If you had a standalone plugin enabled, replace it with the bundle:
  - `flutter-pre-ship@pixelcrafts` → `flutter-standards@pixelcrafts`
  - `api-sync-migrate@pixelcrafts` → `api-standards@pixelcrafts`
  - `web-premium-check@pixelcrafts` → `web-standards@pixelcrafts`
- **Marketplace shrinks from 15 plugins to 4.** One pack per stack plus `core-hooks`.

### Changed

- Repo renamed to `claude-craft` and moved to the `pixelcrafts-app` org. Old URL `nandamashokkumar/pixelcrafts` replaced across all files.
- `scripts/sync.sh` removed — no longer needed without standalone plugins.
- `core/hooks/` (dead duplicate) removed. Real hooks live in `core/plugins/core-hooks/hooks/`.
- `docs/history.md` removed — internal provenance not useful for public consumers.

### Infrastructure

- All plugin versions bumped to `0.2.0` in lockstep.
- README rewritten for public launch.
- Quickstart, skills, contributing docs rewritten.

---

## [0.1.1] — 2026-04-20

### Changed

- **Agents now load companion standards on invocation.** All 5 agents (`api-standards`: security-reviewer, api-documenter; `flutter-standards`: flutter-reviewer, security-reviewer, test-writer) prepend a Standards Context block instructing Claude to Glob + Read the companion `SKILL.md` files before auditing. Previous behavior: agents ran with only their own checklist and didn't reference the auto-invoke standards in the same plugin.

---

## [0.1.0] — 2026-04-20

Initial internal release. Three stack packs plus cross-stack safety, with multi-tool export.

### Flutter pack — `flutter-standards`

9 auto-invoke standards (craft-guide, engineering, widget-rules, api-data, testing, accessibility, performance, forms, observability).

8 explicit audit/scaffold skills accessible via `/flutter-standards:<skill>`:
- pre-ship, premium-check, verify-screens, find-hardcoded, find-duplicates, accessibility-audit, scaffold-screen, scaffold-feature

3 agents: flutter-reviewer, test-writer, security-reviewer.

### API pack — `api-standards`

2 auto-invoke standards: nestjs, code-quality.

1 explicit workflow: `/api-standards:sync-migrate`.

2 agents: api-documenter, security-reviewer.

### Web pack — `web-standards`

1 auto-invoke standard: nextjs.

2 explicit skills: `/web-standards:pre-ship`, `/web-standards:premium-check`.

### Safety — `core-hooks`

Cross-stack PreToolUse hooks (`protect-files.sh`, `protect-bash.sh`).

### Distribution

- Zero-config install via `.claude/settings.json`
- Multi-tool export via `scripts/export.sh` for Cursor + AGENTS.md consumers
