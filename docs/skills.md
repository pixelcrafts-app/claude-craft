# Skills Catalog

15 plugins ship in v0.1.0 — three stack packs plus cross-stack safety. Every standard and every audit/scaffold skill is listed below.

**Two kinds of skill:**
- **Auto-invoke standards** — no slash command; Claude loads them automatically when it sees matching work (editing `.dart` triggers Flutter standards; editing `src/**/*.ts` triggers API standards).
- **Explicit skills** — you invoke them via `/pack-name:skill` when you want an audit, scaffold, or workflow.

## Flutter pack

### 9 auto-invoke standards (inside `flutter-standards`)

| Skill | Fires on | Enforces |
|---|---|---|
| craft-guide | `.dart` UI work | Typography, spacing, motion, state clarity, visual weight |
| engineering | `.dart` | DRY, SSOT, Surgeon Principle, AI-DoD |
| widget-rules | `.dart` widgets | `const`, stateful/stateless choice, animation scope, text resilience |
| api-data | Repository/provider edits | Mappers, models, repositories, API client contract |
| testing | `test/**/*.dart` | Pyramid, mocktail, goldens, Riverpod test patterns, CI gates |
| accessibility | `.dart` UI | Semantics, contrast, touch targets, color-alone, RTL |
| performance | `.dart` | Frame budgets, cold start, image decode-at-size, isolates |
| forms | Form widgets | Field anatomy, keyboard/autofill, validation timing |
| observability | Logging/analytics code | One logger, structured events, PII classification |

### 8 explicit skills (slash commands)

| Skill | Install slice | Type | Slash command |
|---|---|---|---|
| [pre-ship](#pre-ship) | `flutter-pre-ship` | Audit | `/flutter-standards:pre-ship` |
| [premium-check](#premium-check) | `flutter-premium-check` | Audit | `/flutter-standards:premium-check` |
| [verify-screens](#verify-screens) | `flutter-verify-screens` | Audit | `/flutter-standards:verify-screens` |
| [find-hardcoded](#find-hardcoded) | `flutter-find-hardcoded` | Audit | `/flutter-standards:find-hardcoded` |
| [find-duplicates](#find-duplicates) | `flutter-find-duplicates` | Audit | `/flutter-standards:find-duplicates` |
| [accessibility-audit](#accessibility-audit) | `flutter-accessibility-audit` | Audit | `/flutter-standards:accessibility-audit` |
| [scaffold-screen](#scaffold-screen) | `flutter-scaffold-screen` | Generative | `/flutter-standards:scaffold-screen` |
| [scaffold-feature](#scaffold-feature) | `flutter-scaffold-feature` | Generative | `/flutter-standards:scaffold-feature` |

### 3 agents (inside `flutter-standards`)

- **flutter-reviewer** — reviews a diff against all Flutter standards
- **test-writer** — generates widget + unit tests matching the project's framework
- **security-reviewer** — flags PII/secret leaks, insecure storage, unsafe deep links

Install all 17 Flutter skills + 3 agents in one shot:

```
/plugin install flutter-standards@pixelcrafts
```

## API pack (NestJS + Prisma)

### 2 auto-invoke standards (inside `api-standards`)

| Skill | Fires on | Enforces |
|---|---|---|
| nestjs | `src/**/*.ts`, `prisma/schema.prisma` | Module/controller/service/repository split, DTO validation, error shapes |
| code-quality | `src/**/*.ts` | Endpoint hygiene, auth guards, type safety, test coverage |

### 1 explicit workflow skill

| Skill | Install slice | Slash command |
|---|---|---|
| [sync-migrate](#sync-migrate) | `api-sync-migrate` | `/api-standards:sync-migrate` |

### 2 agents

- **api-documenter** — generates OpenAPI-style docs from controllers
- **security-reviewer** — reviews endpoint/service for auth/validation/PII gaps

Install: `/plugin install api-standards@pixelcrafts`.

## Web pack (Next.js + Tailwind + shadcn)

### 1 auto-invoke standard (inside `web-standards`)

| Skill | Fires on | Enforces |
|---|---|---|
| nextjs | `app/**`, `components/**`, `**/*.tsx` | App router, server/client boundaries, Tailwind tokens, shadcn patterns, React Query, React Hook Form + Zod |

### 2 explicit skills

| Skill | Install slice | Slash command |
|---|---|---|
| [pre-ship (web)](#pre-ship-web) | `web-pre-ship` | `/web-standards:pre-ship` |
| [premium-check (web)](#premium-check-web) | `web-premium-check` | `/web-standards:premium-check` |

Install: `/plugin install web-standards@pixelcrafts`.

## Core safety pack

### core-hooks (cross-stack)

Registers PreToolUse hooks that run on every Edit / Write / Bash:
- `protect-files.sh` — blocks edits to `.env`, `*.key`, `*.pem`, `credentials.json`, etc.
- `protect-bash.sh` — blocks `rm -rf /`, `git reset --hard`, force-push to protected branches, etc.

No slash command — runs automatically. Install alongside any pack:

```
/plugin install core-hooks@pixelcrafts
```

---

## Use without Claude Code

Cursor, Antigravity, Codex, Aider, OpenAI SWE — export tool-native files from the same sources:

```bash
git clone https://github.com/nandamashokkumar/pixelcrafts
./claude-craft/scripts/export.sh /path/to/your-project <flutter|api|web>
```

Outputs:
- `.cursor/rules/<pack>-<skill>.mdc` — Cursor Rules v2 (YAML frontmatter, scoped globs)
- `AGENTS.md` — concatenated standards for Antigravity / Codex / Aider / OpenAI SWE

Re-run anytime to pull the latest standards.

---

## pre-ship

**Slash command:** `/flutter-standards:pre-ship`

**Solves:** the gap between "I wrote the code" and "it's ready to merge". Catches craft, engineering, a11y, perf, and test gaps in one pass.

**Checks:**
- All 4 states wired (loading, empty, error, content)
- Design tokens used (no hex, no magic spacing, no inline TextStyle)
- `Semantics` labels on interactive elements
- Touch targets ≥48dp
- No `print()` in feature code
- No unrequested features ("scope discipline")
- `maxLines` + overflow protection on user-generated text
- Tests present for core flows
- No TODO/FIXME added in this change

**Sample:**
```
## Critical
  lib/features/profile/screen.dart
    - Error state missing — shows only loading and content
    - IconButton at line 42 has no Semantics label
    - Color(0xFF1E88E5) at line 18 — use AppColors.primary

## Nice-to-have
  lib/features/profile/widgets/avatar.dart
    - Image.network has no cacheWidth — decodes at source resolution
```

**Gain:** catches 3-8 issues on a typical feature before review.

---

## premium-check

**Slash command:** `/flutter-standards:premium-check <screen-file>`

**Solves:** craft regressions — screens that technically work but feel off.

**Checks:** typography scale adherence, spacing rhythm (4/8/12/16/24), motion timing, state transitions (skeleton not spinner), empty-state CTAs, error-state actionability, interactive feedback within 100ms.

**Pairs with:** `accessibility-audit`.

---

## verify-screens

**Slash command:** `/flutter-standards:verify-screens <feature>`

**Solves:** the mock-data-leftover bug. A screen looks fine in dev but breaks in prod because it still reads from a fixture.

**Checks:**
- Every widget traces back to a real provider / repository
- No `fake`, `mock`, `fixture`, `dummy` imports in production paths
- API calls flow through the repository layer, not directly from UI
- Loading/error states map to real async sources, not timers
- No hardcoded data (user names, sample IDs) in screen files

**Pairs with:** `scaffold-feature` — after scaffolding, verify end-to-end wiring.

---

## find-hardcoded

**Slash command:** `/flutter-standards:find-hardcoded`

**Solves:** design-system drift. Hex colors, magic spacing, inline TextStyles that bypass tokens.

**Scans:** hex colors, magic `EdgeInsets`, inline `TextStyle`, magic `BorderRadius`, uncommon `Duration`, hardcoded `FontWeight`, repeated alpha values.

**Gain:** typically 50-200 violations on first run; ~30 min to fix with grep-and-replace.

---

## find-duplicates

**Slash command:** `/flutter-standards:find-duplicates`

**Solves:** DRY violations. Widgets, helpers, providers, mappers doing the same thing under different names.

**Scans:** widget skeletons, helper functions, providers exposing the same data, mappers parsing the same shape, inline card/button code, overlapping services.

**Gain:** typically 3-10 duplicate groups per mid-size app; 5-15% LoC reduction.

---

## accessibility-audit

**Slash command:** `/flutter-standards:accessibility-audit`

**Solves:** a11y gaps breaking the app for screen reader, large-text, motor-impaired, and RTL users.

**Scans (10 pattern categories):** missing Semantics, color-alone indicators, sub-48dp touch targets, placeholder-only fields, missing autofill hints, fixed heights clipping scaled text, missing focus indicators, unannounced state changes, hardcoded left/right (breaks RTL), animations without motion-preference check.

**Gain:** WCAG compliance before legal flag. EAA (EU) + ADA (US) risk reduction.

---

## scaffold-screen

**Slash command:** `/flutter-standards:scaffold-screen <name>`

**Generates:** one screen with all 4 states (loading, empty, error, content), design tokens referenced, starter provider stub, error boundary with retry. Detects state management (Riverpod / Provider / Bloc), design-system prefix, folder convention, router.

**Gain:** 20-40 min of manual wiring in 30 seconds — always with 4 states.

---

## scaffold-feature

**Slash command:** `/flutter-standards:scaffold-feature <name> [--with-api] [--with-persistence]`

**Generates:** full vertical slice — model (Freezed if detected), mapper, repository, data sources, providers, screen (via scaffold-screen), widgets, test stubs (mapper/repo/provider/screen), feature README with data-flow diagram.

**Detects:** state management, design-system prefix, folder layout, mapper style, test framework (mocktail vs mockito), persistence (Hive / SharedPreferences / Isar).

**Gain:** 2-3 hours of boilerplate in under a minute.

---

## sync-migrate

**Slash command:** `/api-standards:sync-migrate`

**Solves:** the "I edited schema.prisma and forgot one of the four follow-up steps" bug. Schema changes touch the generated client, migrations, downstream services, and type checks.

**Walks through:**
1. Edit `prisma/schema.prisma`
2. `npx prisma generate`
3. `npx prisma migrate dev --name <descriptive>`
4. `npx tsc --noEmit` + lint
5. Update TypeScript interfaces / services / repositories
6. Remind to sync downstream consumers

**Gain:** removes the four-step dance from human memory.

---

## pre-ship (web)

**Slash command:** `/web-standards:pre-ship`

**Solves:** "I finished the component" vs "ready to ship". Catches lint warnings, broken data pipelines, missing states, broken dark mode, broken responsive — in one pass.

**Checks:** lint (zero errors + warnings), data pipeline traced API → hook → component, 4 states per data-driven component, design tokens (no hex, no `p-[13px]`), responsive 320-1440px, dark mode independently designed, a11y basics (semantic HTML, alt text, keyboard focus).

**Gain:** 3-10 issues per feature before review.

---

## premium-check (web)

**Slash command:** `/web-standards:premium-check <component-file>`

**Solves:** craft regressions in individual components — components that technically work but feel off in isolation.

**Checks:** tokens (zero hardcoded colors/fonts/spacing/radii), interaction quality (hover, focus, loading, confirms, ≥44px targets), state design (skeleton, CTA, actionable error), visual polish (hierarchy, alignment, dark mode independence), responsive, a11y.

**Pairs with:** `pre-ship` for the full feature gate.
