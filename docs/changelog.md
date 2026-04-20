# Changelog

All notable changes are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/). Versions follow [SemVer](https://semver.org/).

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
