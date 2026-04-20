# Changelog

All notable changes to this repo are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/). Versions follow [SemVer](https://semver.org/).

---

## [0.1.1] — 2026-04-20

### Changed

- **Agents now load companion standards on invocation.** All 5 agents (`api-standards`: security-reviewer, api-documenter; `flutter-standards`: flutter-reviewer, security-reviewer, test-writer) prepend a Standards Context block instructing Claude to Glob + Read the companion `SKILL.md` files before auditing. Previous behavior: agents ran with only their own checklist and didn't reference the auto-invoke standards in the same plugin. This fixes "agent invoked claude-craft but ignored most of it."

### Infrastructure

- Marketplace + bundle versions bumped to 0.1.1 (flutter-standards, api-standards). Slice plugins unchanged.

---

## [0.1.0] — 2026-04-20

First public release. Three stack packs plus cross-stack safety, with multi-tool export.

### Repo model

- One repo (`claude-craft`), one marketplace at `.claude-plugin/marketplace.json`, stack packs as top-level folders (`flutter/`, `api/`, `web/`, `core/`, `database/` planned)
- Stack-prefixed plugin names (`flutter-<skill>`, `api-<skill>`, `web-<skill>`) so stacks don't collide
- Namespaced slash commands (`/flutter-standards:pre-ship`, `/api-standards:sync-migrate`) — unambiguous per pack
- **Rules ship as auto-invoke skills**, not separate markdown files. Claude Code loads them itself when file types match — zero `CLAUDE.md` edits
- **Zero-config install** via `.claude/settings.json` (`extraKnownMarketplaces` + `enabledPlugins`) — commit once, team auto-installs on first session
- **Multi-tool export** via `scripts/export.sh` — generates `.cursor/rules/*.mdc` (Cursor) + `AGENTS.md` (Antigravity, Codex, Aider, OpenAI SWE)

### Flutter pack — `flutter-standards@pixelcrafts`

9 auto-invoke standards skills:
- **craft-guide** — typography, spacing, motion, state clarity, visual weight
- **engineering** — DRY, SSOT, Surgeon Principle, No Hardcoded Values, Centralize, Error Handling, Security, AI-DoD
- **widget-rules** — widget discipline, `const` use, animations, text resilience, image handling
- **api-data** — mappers, models, repositories, API client contract
- **testing** — pyramid, mocktail, golden tests, Riverpod/Provider patterns, CI gates, coverage
- **accessibility** — Semantics, contrast, touch targets, color-alone, text scaling, reduced motion, RTL
- **performance** — 16ms/8ms frame budgets, cold start, decode-at-display-size, isolates
- **forms** — field anatomy, keyboard + autofill, validation timing, error messages
- **observability** — three pillars, PII classification, consent, retention, trace + session IDs

8 explicit audit/scaffold skills (each also installable as a slice plugin):
- `flutter-pre-ship` — full quality gate (`/flutter-standards:pre-ship`)
- `flutter-premium-check` — single-screen craft audit
- `flutter-verify-screens` — data source → screen trace
- `flutter-find-hardcoded` — design-system violation scan
- `flutter-find-duplicates` — DRY violation scan
- `flutter-accessibility-audit` — 10-pattern a11y scan
- `flutter-scaffold-screen` — generate screen with 4 states
- `flutter-scaffold-feature` — generate full vertical slice

3 agents (bundled):
- **flutter-reviewer** — review a diff against all Flutter standards
- **test-writer** — generate widget + unit tests matching the project's framework
- **security-reviewer** — flag PII/secret leaks, insecure storage, unsafe deep links

### API pack — `api-standards@pixelcrafts`

2 auto-invoke standards:
- **nestjs** — module/controller/service/repository split, DTO validation, Prisma patterns, error shapes
- **code-quality** — endpoint hygiene, auth guards, type safety, test coverage

1 explicit workflow skill:
- `api-sync-migrate` — Prisma schema change workflow (`/api-standards:sync-migrate`)

2 agents:
- **api-documenter** — OpenAPI-style docs from controllers
- **security-reviewer** — endpoint/service review for auth/validation/PII gaps

### Web pack — `web-standards@pixelcrafts`

1 auto-invoke standard:
- **nextjs** — app router, server/client boundaries, Tailwind tokens, shadcn patterns, React Query, React Hook Form + Zod, a11y, TypeScript discipline

2 explicit skills:
- `web-pre-ship` — quality gate (`/web-standards:pre-ship`)
- `web-premium-check` — single-component craft audit

### Core safety — `core-hooks@pixelcrafts`

Cross-stack PreToolUse hooks:
- `protect-files.sh` — blocks edits to `.env`, `*.key`, `*.pem`, `credentials.json`
- `protect-bash.sh` — blocks `rm -rf /`, `git reset --hard`, protected-branch force-push
- Registered via `plugin.json` using `${CLAUDE_PLUGIN_ROOT}` — no app-level wiring

### Marketplace

- 15 plugins total: 3 bundles + 8 Flutter slices + 1 API slice + 2 Web slices + core-hooks
- `scripts/sync.sh` — mirrors bundle → slices for explicit skills
- `scripts/export.sh` — exports to Cursor Rules v2 + AGENTS.md
