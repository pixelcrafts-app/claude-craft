# Changelog

All notable changes are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/). Versions follow [SemVer](https://semver.org/).

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
