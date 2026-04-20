# Quickstart

From zero to running in under 2 minutes. Works in Claude Code natively; exports to Cursor / Antigravity / AGENTS.md tools.

## Prerequisites

- [Claude Code](https://claude.com/claude-code) (CLI, desktop, web, or IDE extension), OR Cursor / Antigravity / any AGENTS.md-aware tool
- A project on your machine — Flutter, NestJS + Prisma API, or Next.js web app

---

## Path 1 — Claude Code, zero-config (recommended for teams)

Commit `.claude/settings.json` to your project:

```json
{
  "extraKnownMarketplaces": {
    "pixelcrafts": {
      "source": { "source": "github", "repo": "nandamashokkumar/pixelcrafts" }
    }
  },
  "enabledPlugins": {
    "flutter-standards@pixelcrafts": true,
    "core-hooks@pixelcrafts": true
  }
}
```

Every teammate who opens the project in Claude Code auto-installs the marketplace + plugins on first session. Nothing else to run. Swap the bundle per project:

| Project type | Bundle |
|---|---|
| Flutter | `flutter-standards@pixelcrafts` |
| NestJS + Prisma API | `api-standards@pixelcrafts` |
| Next.js web | `web-standards@pixelcrafts` |

Always include `core-hooks@pixelcrafts` — cross-stack safety (blocks secret edits, dangerous shell).

## Path 2 — Claude Code, slash commands (one-off install)

```
/plugin marketplace add nandamashokkumar/pixelcrafts
/plugin install flutter-standards@pixelcrafts
/plugin install core-hooks@pixelcrafts
```

To update later: `/plugin marketplace update pixelcrafts`.

## Path 3 — Single skill, à la carte

```
/plugin install flutter-find-hardcoded@pixelcrafts
/plugin install flutter-accessibility-audit@pixelcrafts
/plugin install flutter-scaffold-feature@pixelcrafts
```

Each audit/scaffold skill ships as an independent slice plugin.

---

## Path 4 — Cursor / Antigravity / Codex / Aider

Generate tool-native rule files from the same source:

```bash
git clone https://github.com/nandamashokkumar/pixelcrafts
./claude-craft/scripts/export.sh /path/to/your-project flutter
```

Outputs:
- `.cursor/rules/flutter-*.mdc` — Cursor Rules v2 (one per standards skill, scoped to `lib/**/*.dart`)
- `AGENTS.md` — concatenated standards (Antigravity, Codex, Aider, OpenAI SWE)

Packs available: `flutter`, `api`, `web`. Re-run anytime to pull the latest.

---

## First action — auto-invoke

Once installed (any path above), open a file matching your pack (`.dart` for Flutter, `src/**/*.ts` for API, `app/**/*.tsx` for Web) and ask Claude to build or review something. The standards skills fire automatically — Claude will write to them without you citing anything.

No `@`-imports. No `CLAUDE.md` edits. Auto-invoke is the whole point.

## First audit (30 seconds, Flutter)

```
/flutter-standards:find-hardcoded
```

Sample output:

```
# Design System Violations
Scope: lib/   Scanned: 127 files   Violations: 184

## Colors (73)
  lib/features/home/widgets/card.dart:24
    Color(0xFF3A6FE0) → AppColors.primary

## Spacing (48)
  lib/features/onboarding/welcome.dart:32
    EdgeInsets.all(16) → EdgeInsets.all(AppSpacing.md)
```

## First scaffold (1 minute, Flutter)

```
/flutter-standards:scaffold-feature bookmarks --with-api --with-persistence
```

Generates model, mapper, repository, remote + local data sources, providers, screen with 4 states wired, widgets, test stubs, feature README. Detects your state management, design-system prefix, folder layout.

## First pre-ship gate

```
/flutter-standards:pre-ship
```

Audits changed files for all 4 states, design tokens, Semantics labels, touch targets ≥48dp, no `print()`, test presence. Fix critical items before the PR.

---

## Per-pack install matrix

### Flutter (9 auto-invoke standards + 8 audit/scaffold skills + 3 agents)

```
/plugin install flutter-standards@pixelcrafts
```

Slash commands: `/flutter-standards:pre-ship`, `/flutter-standards:premium-check`, `/flutter-standards:verify-screens`, `/flutter-standards:find-hardcoded`, `/flutter-standards:find-duplicates`, `/flutter-standards:accessibility-audit`, `/flutter-standards:scaffold-screen`, `/flutter-standards:scaffold-feature`.

Agents: `flutter-reviewer`, `test-writer`, `security-reviewer`.

### API (2 auto-invoke standards + 1 workflow skill + 2 agents)

```
/plugin install api-standards@pixelcrafts
```

Slash command: `/api-standards:sync-migrate`. Agents: `api-documenter`, `security-reviewer`.

### Web (1 auto-invoke standard + 2 audit skills)

```
/plugin install web-standards@pixelcrafts
```

Slash commands: `/web-standards:pre-ship`, `/web-standards:premium-check`.

### Core safety (cross-stack)

```
/plugin install core-hooks@pixelcrafts
```

Registers PreToolUse hooks that block edits to secrets (`.env`, keys, credentials) and dangerous shell (`rm -rf`, `git reset --hard`). No commands — runs automatically.

---

## Common gotchas

### "Plugin not found"

Confirm the marketplace was added: `/plugin marketplace list` should show `pixelcrafts`. If using zero-config (Path 1), run `/reload-plugins` to trigger install.

### Standards aren't firing

Auto-invoke triggers on matching file types. If you're editing a `.md` file or chatting without opening a source file, the standards won't load — that's correct. Open a matching source file and they fire.

### Skill suggests a token that doesn't exist

The skills detect your design-system class names by grepping `lib/shared/` (Flutter) or `components/` (Web). If they can't find them, they fall back to generic names (`AppColors`, `AppSpacing`). Add a project `CLAUDE.md` note telling Claude your actual class names.

### Cursor/Antigravity don't pick up changes

Re-run `scripts/export.sh` after pulling the latest `claude-craft` — the tool-native files are generated artifacts, not live imports.

---

## Next steps

- [`docs/skills.md`](skills.md) — full per-skill catalog with sample outputs
- [`docs/craft.md`](craft.md) — the philosophy behind the standards
- [`docs/roadmap.md`](roadmap.md) — Database pack next, Core extraction after
- [`docs/contributing.md`](contributing.md) — if you want to add rules or skills
