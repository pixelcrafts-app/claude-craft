# Skills Catalog

Four plugins ship. Every standard, audit, scaffold, and agent is listed here with what it does and when it fires.

**Two kinds of skill:**
- **Auto-invoke standards** — no slash command. Claude loads them when it sees matching work (a `.dart` file triggers Flutter standards; `src/**/*.ts` triggers API standards).
- **Explicit skills** — invoked via `/pack-name:skill` when you want an audit, scaffold, or workflow.

---

## Flutter pack (`flutter-standards`)

Install: `/plugin install flutter-standards@pixelcrafts` — or enable in `.claude/settings.json`.

### 9 auto-invoke standards

| Skill | Fires on | Enforces |
|---|---|---|
| craft-guide | `.dart` UI | Typography, spacing, motion, state clarity, visual weight |
| engineering | `.dart` | DRY, single source of truth, Surgeon Principle, AI-assisted Definition of Done |
| widget-rules | `.dart` widgets | `const`, stateful/stateless choice, animation scope, text resilience |
| api-data | Repositories, providers | Mappers, models, repository contracts, API client shape |
| testing | `test/**/*.dart` | Pyramid, mocktail, goldens, Riverpod test patterns, CI gates |
| accessibility | `.dart` UI | Semantics, contrast, touch targets, color-alone, RTL |
| performance | `.dart` | Frame budgets, cold start, image decode-at-size, isolates |
| forms | Form widgets | Field anatomy, keyboard, autofill, validation timing |
| observability | Logging / analytics | One logger, structured events, PII classification |

### 8 explicit skills

| Slash command | What it does |
|---|---|
| [/flutter-standards:pre-ship](#pre-ship) | Full quality gate before merge |
| [/flutter-standards:premium-check](#premium-check) | Craft review of a single screen |
| [/flutter-standards:verify-screens](#verify-screens) | Trace data source → UI |
| [/flutter-standards:find-hardcoded](#find-hardcoded) | Scan for design-system violations |
| [/flutter-standards:find-duplicates](#find-duplicates) | Scan for DRY violations |
| [/flutter-standards:accessibility-audit](#accessibility-audit) | 10 a11y patterns scanned |
| [/flutter-standards:scaffold-screen](#scaffold-screen) | Generate a screen with 4 states |
| [/flutter-standards:scaffold-feature](#scaffold-feature) | Generate a feature folder |

### 3 agents

- **flutter-reviewer** — reviews a diff against every Flutter standard
- **test-writer** — generates widget + unit tests matching the project's framework
- **security-reviewer** — flags PII/secret leaks, insecure storage, unsafe deep links

---

## API pack (`api-standards`) — NestJS + Prisma

Install: `/plugin install api-standards@pixelcrafts`.

### 2 auto-invoke standards

| Skill | Fires on | Enforces |
|---|---|---|
| nestjs | `src/**/*.ts`, `prisma/schema.prisma` | Module/controller/service/repository split, DTO validation, error shapes |
| code-quality | `src/**/*.ts` | Endpoint hygiene, auth guards, type safety, test coverage |

### 1 explicit workflow

| Slash command | What it does |
|---|---|
| [/api-standards:sync-migrate](#sync-migrate) | Prisma schema change workflow — generate, migrate, type-check, sync consumers |

### 2 agents

- **api-documenter** — generates OpenAPI-style docs from controllers
- **security-reviewer** — reviews endpoints/services for auth, validation, PII gaps

---

## Web pack (`web-standards`) — Next.js + Tailwind + shadcn

Install: `/plugin install web-standards@pixelcrafts`.

### 1 auto-invoke standard

| Skill | Fires on | Enforces |
|---|---|---|
| nextjs | `app/**`, `components/**`, `**/*.tsx` | App router, server/client boundaries, Tailwind tokens, shadcn patterns, React Query, React Hook Form + Zod |

### 2 explicit skills

| Slash command | What it does |
|---|---|
| [/web-standards:pre-ship](#pre-ship-web) | Quality gate before merge |
| [/web-standards:premium-check](#premium-check-web) | Craft review of a component |

---

## Safety pack (`core-hooks`) — cross-stack

Install: `/plugin install core-hooks@pixelcrafts`.

Registers `PreToolUse` hooks that run on every Edit / Write / Bash:

- `protect-files.sh` — blocks edits to `.env`, `*.key`, `*.pem`, `credentials.json`, and similar secret files
- `protect-bash.sh` — blocks `rm -rf /`, `git reset --hard`, force-push to protected branches, and similar destructive commands

No slash command. Runs automatically. Install it alongside any pack.

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

Closes the gap between "I wrote the code" and "ready to merge". Catches craft, engineering, a11y, perf, and test gaps in one pass.

**Checks:** all 4 states wired (loading / empty / error / content), design tokens used (no hex, no magic spacing, no inline TextStyle), `Semantics` labels on interactive elements, touch targets ≥ 48dp, no `print()`, no unrequested features, `maxLines` + overflow protection on user-generated text, tests present for core flows, no new TODO/FIXME.

**Sample output:**
```
Critical
  lib/features/profile/screen.dart
    - Error state missing — shows only loading and content
    - IconButton at line 42 has no Semantics label
    - Color(0xFF1E88E5) at line 18 — use AppColors.primary

Nice-to-have
  lib/features/profile/widgets/avatar.dart
    - Image.network has no cacheWidth — decodes at source resolution
```

Catches 3–8 issues on a typical feature before review.

---

### premium-check

`/flutter-standards:premium-check <screen-file>`

Catches screens that technically work but feel off. Typography scale adherence, spacing rhythm (4/8/12/16/24), motion timing, state transitions (skeleton, not spinner), empty-state CTAs, error-state actionability, interactive feedback within 100ms.

Pairs with `accessibility-audit`.

---

### verify-screens

`/flutter-standards:verify-screens <feature>`

Finds the mock-data-leftover bug — a screen that looks fine in dev because it still reads from a fixture.

**Checks:** every widget traces back to a real provider/repository, no `fake`/`mock`/`fixture` imports in production paths, API calls flow through the repository layer, loading/error states map to real async sources, no hardcoded data in screen files.

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

### accessibility-audit

`/flutter-standards:accessibility-audit`

10 pattern categories: missing `Semantics`, color-alone indicators, sub-48dp touch targets, placeholder-only fields, missing autofill hints, fixed heights clipping scaled text, missing focus indicators, unannounced state changes, hardcoded left/right (breaks RTL), animations without motion-preference check.

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

Closes the gap between "I finished the component" and "ready to ship". Catches lint warnings, broken data pipelines, missing states, broken dark mode, broken responsive — in one pass.

**Checks:** lint (zero errors + warnings), data pipeline traced API → hook → component, 4 states per data-driven component, design tokens (no hex, no `p-[13px]`), responsive 320–1440px, dark mode independently designed, a11y basics (semantic HTML, alt text, keyboard focus).

3–10 issues per feature before review.

---

### premium-check (web)

`/web-standards:premium-check <component-file>`

Finds craft regressions in individual components. Tokens (zero hardcoded colors/fonts/spacing/radii), interaction quality (hover, focus, loading, confirms, ≥ 44px targets), state design (skeleton, CTA, actionable error), visual polish (hierarchy, alignment, dark mode independence), responsive, a11y.

Pairs with `pre-ship` for the full feature gate.
