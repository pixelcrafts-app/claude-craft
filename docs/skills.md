# Skills Catalog

Four plugins ship. Every standard, audit, scaffold, and agent is listed here with what it does and when it fires.

**Two kinds of skill:**
- **Auto-invoke standards** — no slash command. Claude loads them when it sees matching work (a `.dart` file triggers Flutter standards; `src/**/*.ts` triggers API standards).
- **Explicit skills** — invoked via `/pack-name:skill` when you want an audit, scaffold, or workflow.

---

## Flutter pack (`flutter-standards`)

Install: `/plugin install flutter-standards@pixelcrafts` — or enable in `.claude/settings.json`.

### 10 auto-invoke standards

| Skill | Fires on | Enforces |
|---|---|---|
| craft-guide | `.dart` UI | Typography, spacing, motion, state clarity, visual weight |
| engineering | `.dart` | DRY, single source of truth, Surgeon Principle, AI-assisted Definition of Done, verify-don't-guess cross-boundary contracts |
| widget-rules | `.dart` widgets | `const`, stateful/stateless choice, animation scope, text resilience |
| api-data | Repositories, providers | Mappers, models, repository contracts, API client shape |
| testing | `test/**/*.dart` | Pyramid, mocktail, goldens, Riverpod test patterns, CI gates |
| accessibility | `.dart` UI | Semantics, contrast, touch targets, color-alone, RTL |
| performance | `.dart` | Frame budgets, cold start, image decode-at-size, isolates |
| forms | Form widgets | Field anatomy, keyboard, autofill, validation timing |
| observability | Logging / analytics | One logger, structured events, PII classification |
| production-readiness | App wiring / service layer | Smart Detect→Check→Suggest audit: retry, lifecycle, deep links, push UX, force-update, secure storage, locale/RTL, offline, env-logging |

### 8 explicit skills

| Slash command | What it does |
|---|---|
| [/flutter-standards:pre-ship](#pre-ship) | Full quality gate before merge |
| [/flutter-standards:premium-check](#premium-check) | Craft review of a single screen |
| [/flutter-standards:verify-screens](#verify-screens) | Trace data source → UI |
| [/flutter-standards:find-hardcoded](#find-hardcoded) | Scan for design-system violations |
| [/flutter-standards:find-duplicates](#find-duplicates) | Scan for DRY violations |
| [/flutter-standards:audit-a11y-patterns](#audit-a11y-patterns) | 10 Flutter-specific a11y patterns scanned (regex sweep) |
| [/flutter-standards:scaffold-screen](#scaffold-screen) | Generate a screen with 4 states |
| [/flutter-standards:scaffold-feature](#scaffold-feature) | Generate a feature folder |

---

## API pack (`api-standards`) — NestJS + Prisma

Install: `/plugin install api-standards@pixelcrafts`.

### 4 auto-invoke standards

| Skill | Fires on | Enforces |
|---|---|---|
| nestjs | `src/**/*.ts`, `prisma/schema.prisma` | Module/controller/service/repository split, DTO validation, error shapes |
| code-quality | `src/**/*.ts` | Endpoint hygiene, auth guards, type safety, test coverage, verify-don't-guess cross-boundary contracts, smart Detect→Check→Suggest audit for rate limiting, idempotency, retries, webhooks, graceful shutdown, health/readiness, correlation IDs, soft delete, audit logs, DB pool, env-logging |
| cross-stack-contracts | API boundaries when `craft.json stacks[]` has 2+ entries | Unified error shape `{code, message, details}`, cursor pagination only, `Authorization: Bearer` standard, versioned routes for breaking changes, generated OpenAPI spec committed |
| websockets | When socket.io/ws + WebSocket usage pattern detected, or `craft.json features.realtime: true` | Auth on connection event, exponential backoff reconnect (1s/2s/4s, max 3 retries), event names in shared enum, versioned event schema on connect, room authorization |

### 1 explicit workflow

| Slash command | What it does |
|---|---|
| [/api-standards:sync-migrate](#sync-migrate) | Prisma schema change workflow — generate, migrate, type-check, sync consumers |

---

## Web pack (`web-standards`) — Next.js + Tailwind + shadcn

Install: `/plugin install web-standards@pixelcrafts`.

### 5 auto-invoke standards

| Skill | Fires on | Enforces |
|---|---|---|
| nextjs | `app/**`, `components/**`, `**/*.tsx` | App router, server/client boundaries, Tailwind tokens, shadcn patterns, React Query, React Hook Form + Zod, verify-don't-guess cross-boundary contracts |
| production-readiness | App-level wiring, middleware, `next.config.js` | Smart Detect→Check→Suggest audit: error boundaries, Suspense, optimistic UI, image optimization, metadata/OG, sitemap, CSP, analytics consent, Core Web Vitals, env-logging |
| craft-guide | Any `.tsx` / `.css` under `app/` / `components/` | 17 universal design formulas — color + contrast + harmony, spacing rhythm, type scale, font loading, shadow + radius scales, motion choreography, all state variants, density by app type, safe-area, aesthetic coherence, iconography, chrome details, a11y as craft, theme discipline, microcopy, brand moments. Universal formulas enforced; brand values come from user. |
| premium-signals | Any `.tsx` / `.css` under `app/` / `components/` | Market-sourced precision values — 2-layer shadow formula, 5-step dark gray scale, expo-out easing `cubic-bezier(0.16,1,0.3,1)`, tabular-nums hard requirement, display letter-spacing `−0.04em`, font selection by context (Inter/Geist/Söhne), glassmorphism overlay-only rule, SVG noise on gradients, bento/brutalist/luxury exact values |
| i18n | When `next-i18next`/`react-i18next`/`i18next` in deps or `locales/` dir, or `craft.json features.i18n: true` | All user-visible strings via translation keys, library plural rules (no manual conditionals), RTL layout tested, Next.js locale routing wired |

### 5 explicit skills

| Slash command | What it does |
|---|---|
| [/web-standards:pre-ship](#pre-ship-web) | Quality gate before merge |
| [/web-standards:premium-check](#premium-check-web) | Craft audit — delegates `craft-guide §1 – §15` to the engine; rule-by-rule PASS/FAIL, optional fix loop |
| [/web-standards:extract-tokens](#extract-tokens) | Extract design tokens from codebase or input; write `design-tokens.md` single source of truth |
| [/web-standards:theme-audit](#theme-audit) | Verify theme completeness — light/dark parity, hydration flash, `color-scheme`, switch coverage |
| [/web-standards:aesthetic-coherence](#aesthetic-coherence) | Detect aesthetic mixing — flag screens committing to two design languages at once |

---

## Hooks plugin (`core-hooks`) — cross-stack

Install: `/plugin install core-hooks@pixelcrafts`.

### PreToolUse hooks

Run on every Edit / Write / Bash:

- `protect-files.sh` — blocks edits to `.env`, `*.key`, `*.pem`, `credentials.json`, and similar secret files
- `protect-bash.sh` — blocks destructive shell commands (`rm -rf /`, `git reset --hard`, force-push to protected branches, etc.)
- `enforce-tokens.sh` — blocks raw design values in projects with a token system. Rules live in the stack skill packs; this hook enforces deterministically.
- `enforce-rules.sh` — **enforcement mode (opt-in)**. When a project commits `.claude/enforcement.json` listing mandatory packs, this hook runs each pack's rule registry against every Edit / Write / MultiEdit and hard-blocks on violation. See [docs/enforcement.md](enforcement.md).

### SessionStart hook

- `rules-discipline.sh` — surfaces plugin-hook mechanics to Claude. Notably: hooks run in the main session only, not inside subagent writes.
- `enforcement-preamble.sh` — when enforcement mode is active, injects a pinned preamble listing mandatory skills, rule IDs, and the gate command per pack.

### Stop hook (v0.10.0)

- `stop-gate.sh` — when enforcement mode is active, blocks turn-end if a mandatory pack's files were edited but the pack's gate command (e.g. `/flutter-standards:pre-ship`) has not passed. Claude cannot say "done" until each gate reports SAFE TO COMMIT.

No slash commands. Runs automatically.

---

## Cross-stack skills plugin (`core-standards`)

Install: `/plugin install core-standards@pixelcrafts`.

| Skill | Fires on | Does |
|---|---|---|
| principles | Every non-trivial task | Detect→Check→Suggest discipline. Evidence required for every verdict. Plan/Execute/Verify as separate phases — compressing them into one response means one wasn't done. Adversarial verifier mindset: find what's wrong, not confirm what's right. |
| planning | Every delivery task before code is written | Discovery protocol for cold start. Structured `<!-- craft:plan -->` block with measurable deliverables — each requires a runnable verification command (grep/Bash/Read). `scope_boundary` field. Trivial bypass requires grep evidence. Generates draft `.claude/craft.json` on first run if absent. |
| rules | Every code file edit | Universal standards: §1 Security (ALWAYS-MANDATORY — no opt-out), §2 Testing, §3 Observability, §4 Engineering, §5 Design tokens. §1 applies to every touched file regardless of scope boundary or project config. |
| verification | After every delivery task | Adversarial framing. Step 0 reads `.claude/craft.json`. 4-tier detection: ALWAYS-MANDATORY / PROJECT-MANDATORY / TASK-SCOPED / FLAGGED-NOT-ENFORCED. Phase 1 reads plan block — DONE requires named tool call, prose = MISSED. After any fix: restart from Phase 1 item 1. INFO for gap zones (does not block READY). |
| auth-flows | When `craft.json features.auth` non-false, or auth patterns detected | Auth guard + permission guard both required (not auth alone). Refresh token rotation on every use. Server-side logout revocation. Access token ≤15min. OAuth PKCE. Auth error non-enumeration. Rate limiting on auth endpoints. |
| craft-config | When `.claude/craft.json` is absent and needs generation | Documents `.claude/craft.json` schema: `stacks[]`, `features{}`, `disabled_rules[]`. Auto-generates draft from file detection. Disabled rules surfaced with reasons in every verification report. |
| docs-sync | End-of-task signals (version bump, plugin added/removed, "ship / done / release", pre-ship runs, `v*.*.*` commit) | Cross-checks code vs README / CHANGELOG / ROADMAP / `docs/skills.md` / plugin descriptions. Flags deltas. Never rewrites prose. Never blocks. |
| subagent-brief | Any time the model considers delegating to Agent / Task / Explore / Plan / general-purpose subagent | Enforces warm-brief discipline: goal + known context (paths + lines) + hard scope + output shape + budget. A subagent given "figure it out" burns 3–10× the tokens of one given specifics. |
| verify-changes | User says "verify my changes" / "cross-check" / "audit what I did" / ends a non-trivial chunk of work | Generic cross-stack verification workflow. Asks scope + dimensions + depth. Builds a dependency graph. Verifies rule-by-rule from whichever SKILL.md files are installed. Emits critical / polish / consumer-break verdict. Pure prompt — no hooks, no external tools. |

Install either / both alongside any pack — they apply regardless of stack.

---

## Use without Claude Code

Cursor, Antigravity, Codex, Aider, OpenAI SWE — export tool-native files from the same source:

```bash
git clone https://github.com/pixelcrafts-app/claude-craft
./claude-craft/scripts/export.sh /path/to/your-project <flutter|api|web>
```

Outputs:
- `.cursor/rules/<pack>-<skill>.mdc` — Cursor Rules v2 (YAML frontmatter, scoped globs)
- `AGENTS.md` — concatenated standards for Antigravity, Codex, Aider, OpenAI SWE

Re-run anytime to refresh.

---

## Skill details

### pre-ship

`/flutter-standards:pre-ship`

Closes the gap between "I wrote the code" and "ready to merge". Thin wrapper: runs `flutter analyze` as a pre-check, then delegates the audit to `core-standards:verify-changes` with every installed Flutter standard as a dimension and `depth: direct+consumers`. Reports only — no auto-fix.

**Covers:** craft, engineering, widget discipline, api-data pipeline, testing, accessibility, performance, forms, observability, production-readiness. One engine, every rule, consumer-break detection in one run.

**Sample output:**
```
Critical
  lib/features/profile/screen.dart
    - Error state missing — shows only loading and content
    - IconButton at line 42 has no Semantics label
    - Color(0xFF1E88E5) at line 18 — use AppColors.primary

Polish
  lib/features/profile/widgets/avatar.dart
    - Image.network has no cacheWidth — decodes at source resolution

Consumer impact
  lib/features/profile/provider.dart → lib/features/profile/screen.dart:18
    - rename of `fetchUser` → `loadUser` broke the consumer import
```

Catches 3–8 issues per feature before review, plus any consumer breakage from renames or signature changes.

---

### premium-check

`/flutter-standards:premium-check <screen-file>`

Focused craft + widget + a11y + perf audit on a single screen. Thin wrapper: delegates to `core-standards:verify-changes` with `dimensions: [craft-guide, widget-rules, accessibility, performance]`, `depth: direct`. Optional fix loop with `--fix`.

Catches screens that technically work but feel off. Typography scale adherence, spacing rhythm (4/8/12/16/24), motion timing, state transitions (skeleton, not spinner), empty-state CTAs, error-state actionability, interactive feedback within 100ms.

Pairs with `audit-a11y-patterns` for the quick Dart-specific regex sweep.

---

### verify-screens

`/flutter-standards:verify-screens <feature>`

Finds the mock-data-leftover bug — a screen that looks fine in dev because it still reads from a fixture. Thin wrapper: delegates to `core-standards:verify-changes` with `dimensions: [api-data, widget-rules, craft-guide]` and `depth: full-ripple` so the engine walks screen → provider → repo → data source.

**Checks:** every widget traces back to a real provider / repository, no `fake` / `mock` / `fixture` imports in production paths, API calls flow through the repository layer, loading / error states map to real async sources, no hardcoded data in screen files.

Pairs with `scaffold-feature` — after scaffolding, verify end-to-end wiring.

---

### find-hardcoded

`/flutter-standards:find-hardcoded`

Finds design-system drift. Hex colors, magic `EdgeInsets`, inline `TextStyle`, magic `BorderRadius`, uncommon `Duration`, hardcoded `FontWeight`, repeated alpha values.

First run on a mid-size app typically surfaces 50–200 violations. ~30 minutes of grep-and-replace to clear.

---

### find-duplicates

`/flutter-standards:find-duplicates`

Finds DRY violations. Widgets, helpers, providers, mappers doing the same thing under different names.

**Scans:** widget skeletons, helper functions, providers exposing the same data, mappers parsing the same shape, inline card/button code, overlapping services.

Typically 3–10 duplicate groups per mid-size app. 5–15% LoC reduction is common.

---

### audit-a11y-patterns

`/flutter-standards:audit-a11y-patterns`

Fast Flutter-specific regex scan covering 10 pattern categories: missing `Semantics`, color-alone indicators, sub-48dp touch targets, placeholder-only fields, missing autofill hints, fixed heights clipping scaled text, missing focus indicators, unannounced state changes, hardcoded left/right (breaks RTL), animations without motion-preference check.

This is the *pattern scanner*, not THE accessibility audit. The full rule-by-rule a11y audit runs inside `premium-check` / `pre-ship` / `verify-changes` as the `accessibility` dimension. Use this command for a quick Dart-specific sweep; use `premium-check` for the complete walk with fix loop.

WCAG compliance work. EAA (EU) + ADA (US) risk reduction.

---

### scaffold-screen

`/flutter-standards:scaffold-screen <name>`

One screen with all 4 states wired (loading / empty / error / content), design tokens referenced, starter provider stub, error boundary with retry.

**Detects:** state management (Riverpod / Provider / Bloc), design-system prefix, folder convention, router.

20–40 minutes of manual wiring in 30 seconds — always with 4 states.

---

### scaffold-feature

`/flutter-standards:scaffold-feature <name> [--with-api] [--with-persistence]`

Full vertical slice — model (Freezed if detected), mapper, repository, remote + local data sources, providers, screen (via scaffold-screen), widgets, test stubs, feature README with data-flow diagram.

**Detects:** state management, design-system prefix, folder layout, mapper style, test framework, persistence (Hive / SharedPreferences / Isar).

2–3 hours of boilerplate in under a minute.

---

### sync-migrate

`/api-standards:sync-migrate`

Closes the "I edited `schema.prisma` and forgot one of the four follow-up steps" bug. Walks through:

1. Edit `prisma/schema.prisma`
2. `npx prisma generate`
3. `npx prisma migrate dev --name <descriptive>`
4. `npx tsc --noEmit` + lint
5. Update TypeScript interfaces / services / repositories
6. Remind to sync downstream consumers (mobile, web, other APIs)

Removes the four-step dance from human memory.

---

### pre-ship (web)

`/web-standards:pre-ship`

Closes the gap between "I finished the component" and "ready to ship". Thin wrapper: runs `npm run lint` as a pre-check, then delegates to `core-standards:verify-changes` with every installed web standard (`nextjs`, `production-readiness`, `craft-guide`) as a dimension and `depth: direct+consumers`. Reports only — no auto-fix.

**Covers:** lint pre-check, data pipeline traced API → hook → component, state coverage per data-driven component, design-token discipline, responsive 320–1440px, dark mode independently designed, a11y, production-readiness R1–R10 (error boundaries, Suspense, optimistic UI, images, OG, sitemap, CSP, consent, CWV, logging).

3–10 issues per feature before review, plus any consumer breakage from renames or contract changes.

---

### premium-check (web)

`/web-standards:premium-check <component-file>`

Walks every rule in `craft-guide §1 – §15` against a single file. Thin wrapper: delegates to `core-standards:verify-changes` with `dimensions: [craft-guide §1 – §15]`, `depth: direct`. Before delegating, detects the app's aesthetic (§9) and density target (§8.5) — asks the user when ambiguous rather than guessing. With `--fix`, the engine loops: fix → re-audit → fix → re-audit until zero FAILs (or a rule hits the 3-retry stuck cap).

Catches long-tail craft rules that single-pass audits skip. Expensive per-file — scope to one component or page at a time.

Pairs with `pre-ship` for the full feature gate, with `extract-tokens` to establish what to audit against, with `theme-audit` + `aesthetic-coherence` for app-level coherence.

---

### extract-tokens

`/web-standards:extract-tokens [optional-input-path]`

Before auditing craft, you need to know the user's tokens. Three modes:

1. **From codebase** — scans `tailwind.config`, `@theme`, CSS vars, shadcn setup
2. **From user input** — parses paste, Figma export, screenshot, brand PDF
3. **From Figma URL** — if Figma MCP is installed

Normalizes into six dimensions (color / typography / spacing / radius / shadow / motion). Detects missing dimensions. Counts token-drift (inline hex, arbitrary Tailwind, inline rgba). Writes `design-tokens.md` as single source of truth — craft-guide + premium-check auto-read it when present.

Never invents brand values. Asks the user when ambiguous.

---

### theme-audit

`/web-standards:theme-audit [optional-scope]`

Thin wrapper: delegates to `core-standards:verify-changes` with the theme subset of craft rules — `craft-guide §13` (tokens, semantic naming, parity, hydration, color-scheme) plus `§1.5` (dark-mode contrast), `§11.3` (::selection), `§11.5` (caret-color), `§12.7` (color-scheme), `§12.8` (forced-colors), `§12.9` (reduced-transparency). Pre-flight: checks tokens exist (`design-tokens.md` or Tailwind / CSS var scan); if neither theme has tokens, halts and asks for `extract-tokens` first.

Catches theme completeness issues the full craft audit would catch too — faster because scope is narrower.

Pairs with `extract-tokens` — re-run after tokens land.

---

### aesthetic-coherence

`/web-standards:aesthetic-coherence [file | directory | "app"]`

Detects the #1 "assembled, not designed" tell: mixing two design languages in one surface (glassmorphism + neumorphism, bento + brutalist, AI-native + editorial).

Hybrid pattern: runs **detection itself** (scoring 14 aesthetic signatures per file, flagging MIXED / OUTLIER / UNCLEAR) because that's a signal-scoring task, not a rule walk. After classification, delegates **spec compliance** to `core-standards:verify-changes` with `dimensions: [craft-guide §9]` — the engine walks §9.1 (single aesthetic), §9.2 (per-aesthetic specs), §9.3 / §9.4 (glass-specific legibility + reduced-transparency), §9.5 (numeric specs).

Cross-file: detects outlier screens committed to a different aesthetic than the app.

Fix loop is **manual-confirmation** — aesthetic rewrites are taste calls, not automatic. This skill flags and proposes; user approves per file. Never invokes the engine with `fix: yes`.
