# Quickstart

From zero to standards-applied in under two minutes.

## What you need

- A project — Flutter, NestJS + Prisma API, or Next.js web
- [Claude Code](https://claude.com/claude-code) (any form — CLI, desktop, IDE extension). Or Cursor, Antigravity, Codex, Aider — the [export script](#use-with-cursor-antigravity-codex-aider) covers them.

---

## Path 1 — Zero-config (recommended for teams)

Commit `.claude/settings.json` to your project:

```json
{
  "extraKnownMarketplaces": {
    "pixelcrafts": {
      "source": { "source": "github", "repo": "pixelcrafts-app/claude-craft" }
    }
  },
  "enabledPlugins": {
    "flutter-standards@pixelcrafts": true,
    "core-hooks@pixelcrafts": true,
    "core-skills@pixelcrafts": true
  }
}
```

Teammates who open the project in Claude Code auto-install on first session — no commands, no onboarding doc.

Swap the pack to match the project:

| Project | `enabledPlugins` entry |
|---|---|
| Flutter | `flutter-standards@pixelcrafts` |
| NestJS + Prisma | `api-standards@pixelcrafts` |
| Next.js | `web-standards@pixelcrafts` |

Two cross-stack plugins to include:
- `core-hooks@pixelcrafts` — hooks only. Blocks secret-file edits and dangerous shell in every project; blocks raw design values only when the project has a detected token system (self-gates on stack + tokens-file presence).
- `core-skills@pixelcrafts` — three auto-invoke skills that self-gate: `docs-sync` (fires only when docs exist to drift from), `verify-changes` (fires only on "verify my changes" intent), `subagent-brief` (fires only when Claude is about to delegate). Install cost when unused is zero.

---

## Path 2 — Slash commands (one-off install)

```
/plugin marketplace add pixelcrafts-app/claude-craft
/plugin install flutter-standards@pixelcrafts
/plugin install core-hooks@pixelcrafts
/plugin install core-skills@pixelcrafts
```

To pull later updates: `/plugin marketplace update pixelcrafts`.

---

## First run — see it work

Once installed, open a file matching your pack:
- Flutter → any `.dart` in `lib/`
- API → any `.ts` in `src/`
- Web → any `.tsx` in `app/` or `components/`

Ask Claude to build or review something in that file. The auto-invoke standards fire on their own — you don't cite, import, or enable anything.

**Try an audit (Flutter):**
```
/flutter-standards:find-hardcoded
```

Sample output:
```
Design System Violations
Scope: lib/   Scanned: 127 files   Violations: 184

Colors (73)
  lib/features/home/card.dart:24
    Color(0xFF3A6FE0) → AppColors.primary

Spacing (48)
  lib/features/onboarding/welcome.dart:32
    EdgeInsets.all(16) → EdgeInsets.all(AppSpacing.md)
```

**Try a scaffold:**
```
/flutter-standards:scaffold-feature bookmarks --with-api --with-persistence
```

Generates model, mapper, repository, remote + local data sources, providers, screen with loading / empty / error / content states wired, widgets, test stubs, and a feature README.

**Run the full quality gate before merging:**
```
/flutter-standards:pre-ship
```

---

## What each pack gives you

### Flutter (`flutter-standards`)

10 auto-invoke standards (craft-guide, engineering, widget-rules, api-data, testing, accessibility, performance, forms, observability, production-readiness).

Audit slash commands (**thin wrappers** — delegate iteration to `core-skills:verify-changes`):
- `/flutter-standards:pre-ship` — full quality gate before merge. Dimensions: every flutter-standards skill. Runs `flutter analyze` as pre-flight.
- `/flutter-standards:premium-check` — craft review of a screen. Dimensions: `[craft-guide, widget-rules, accessibility, performance]`. Depth: direct.
- `/flutter-standards:verify-screens` — trace data source → UI. Dimensions: `[api-data, widget-rules, craft-guide]`. Depth: full-ripple.
- `/flutter-standards:audit-a11y-patterns` — fast Flutter-specific regex scan for 10 recurring a11y bugs (regex sweep, not engine-driven).

Scan + scaffold slash commands (standalone — no engine delegation):
- `/flutter-standards:find-hardcoded` — scan for design-system violations
- `/flutter-standards:find-duplicates` — scan for DRY violations
- `/flutter-standards:scaffold-screen` — generate screen with 4 states
- `/flutter-standards:scaffold-feature` — generate feature folder

### API (`api-standards`)

Auto-invoke: `nestjs`, `code-quality`.

Slash command: `/api-standards:sync-migrate` — Prisma schema change workflow, reminds you to sync downstream consumers.

### Web (`web-standards`)

Auto-invoke: `nextjs`, `production-readiness` (10 readiness concerns, numbered `§R1–§R10`), `craft-guide` (17-section universal design formulas with stable `§N.M` rule IDs — color, spacing, type, shadow/radius, motion, state, responsive, aesthetic coherence, iconography, chrome, a11y, theme, microcopy, brand moments; enforces discipline, never picks brand values).

Slash commands (**all are thin wrappers** — they pick scope + dimensions, then delegate to `core-skills:verify-changes` for iteration, batching, and the fix loop):
- `/web-standards:pre-ship` — quality gate before merge. Dimensions: every web-standards skill. Depth: direct+consumers.
- `/web-standards:premium-check` — craft audit of a screen. Dimensions: `craft-guide §1 – §15`. Depth: direct. Rule-by-rule PASS/FAIL/N_A.
- `/web-standards:extract-tokens` — establish `design-tokens.md` as single source of truth (not an audit — this one writes).
- `/web-standards:theme-audit` — dimensions: `craft-guide §13` + related light/dark rules. Depth: direct.
- `/web-standards:aesthetic-coherence` — hybrid: runs its own signal-detection pass, then delegates `craft-guide §9` compliance to the engine.

### Hooks (`core-hooks`)

- PreToolUse blocks edits to `.env`/secret files and dangerous shell commands (`rm -rf`, `git reset --hard`). Runs on every edit.
- PreToolUse blocks raw design values in projects with a token system. Deterministic regex, not advisory.
- SessionStart surfaces plugin-hook mechanics to Claude (notably: hooks don't fire inside subagent writes).
- **Enforcement mode (v0.10.0, opt-in)** — when a project commits `.claude/enforcement.json`, SessionStart pins a mandatory-skills preamble, PreToolUse runs the packs' rule registries as hard blocks, and Stop hook blocks turn-end until each pack's gate command has passed. See [docs/enforcement.md](enforcement.md).

### Cross-stack skills (`core-skills`)

- Auto-invoke `docs-sync` — catches drift between code and docs at end-of-task moments. Flags deltas; never rewrites prose; never blocks.
- Auto-invoke `verify-changes` — generic cross-stack verification. Fires on "verify my changes" / "cross-check" / end of a non-trivial branch. Asks scope + dimensions + depth, walks a dependency graph, runs batched rule-by-rule audits using whichever SKILL.md standards packs are installed. Pure prompt — no external tools.
- Auto-invoke `subagent-brief` — warm-brief discipline on Agent / Task / Explore delegation. Enforces GOAL / CONTEXT / SCOPE / TASK / OUTPUT SHAPE / BUDGET.

---

## Make standards mandatory (opt-in)

By default, auto-invoke skills are advisory — Claude follows them because the descriptions match. If you want **hard enforcement** (blocked edits on rule violations, can't end a turn without running the gate), commit one file:

```json
// .claude/enforcement.json
{
  "mandatory": ["flutter-standards"]
}
```

That's the whole setup. On the next session, Claude Code:

1. Loads a pinned preamble listing the mandatory skills and rule IDs.
2. Hard-blocks any edit that violates a pack-registered rule (e.g. `IconButton` missing a semantic label on a Flutter project).
3. Refuses to end the turn until `/flutter-standards:pre-ship` reports SAFE TO COMMIT.

Three knobs, all optional:

```json
{
  "mandatory": ["flutter-standards", "web-standards"],
  "disabled_rules": ["flutter.perf.listview-unbounded"],
  "gate_required": true
}
```

Full guide including rule authoring and rollout pattern: [docs/enforcement.md](enforcement.md).

---

## Use with Cursor, Antigravity, Codex, Aider

```bash
git clone https://github.com/pixelcrafts-app/claude-craft
./claude-craft/scripts/export.sh /path/to/your-project flutter
```

Generates:
- `.cursor/rules/flutter-*.mdc` — Cursor Rules v2 (one per standards skill, scoped to `lib/**/*.dart`)
- `AGENTS.md` — concatenated standards for Antigravity, Codex, Aider, OpenAI SWE

Packs: `flutter`, `api`, `web`. Re-run when you want the latest.

---

## Multi-project / monorepo sessions

If you work across several projects that live under one parent folder (e.g. `my-org/api`, `my-org/web`, `my-org/mobile`), open Claude Code from the **parent folder** — not from a child — if you want cross-project edits to honor every pack's standards and hooks.

**Why:** Claude Code loads `.claude/settings.json` from the directory it's opened in. Plugins and hooks are bound to that scope. `--add-dir` grants file access to a sibling project but does **not** merge that project's `.claude/settings.json`. So editing a `.dart` file from a session rooted in your web project won't auto-invoke Flutter standards or run the dart-format hook.

**Pattern that works:**

1. Commit a parent-level `./.claude/settings.json` that enables every pack you need and declares path-aware hooks (dispatch by file extension). Example:

```json
{
  "extraKnownMarketplaces": {
    "pixelcrafts": {
      "source": { "source": "github", "repo": "pixelcrafts-app/claude-craft" }
    }
  },
  "enabledPlugins": {
    "flutter-standards@pixelcrafts": true,
    "api-standards@pixelcrafts": true,
    "web-standards@pixelcrafts": true,
    "core-hooks@pixelcrafts": true,
    "core-skills@pixelcrafts": true
  },
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [{
          "type": "command",
          "command": "filepath=$(jq -r '.tool_response.filePath // .tool_input.file_path // empty'); case \"$filepath\" in *.ts|*.tsx|*.js|*.jsx|*.json|*.md) dir=$(dirname \"$filepath\"); while [ \"$dir\" != \"/\" ] && [ ! -f \"$dir/package.json\" ]; do dir=$(dirname \"$dir\"); done; [ -x \"$dir/node_modules/.bin/prettier\" ] && \"$dir/node_modules/.bin/prettier\" --write \"$filepath\" >/dev/null 2>&1 || true ;; *.dart) dart format \"$filepath\" >/dev/null 2>&1 || true ;; esac; exit 0"
        }]
      }
    ]
  }
}
```

2. Keep each child's own `.claude/settings.json` for single-project sessions (only that pack loaded, project-specific permissions).

**Rule of thumb:**
- Cross-project work → open from parent.
- Single-project work → open from child.
- `--add-dir` is for *reading* a sibling (e.g. "check the API controller"), not for editing it under its own rules.

---

## Troubleshooting

**"Plugin not found"** — run `/plugin marketplace list`. If `pixelcrafts` isn't listed, the marketplace didn't register. For zero-config setups, try `/reload-plugins`.

**Standards aren't firing** — auto-invoke needs a matching file open. Editing a `.md` or just chatting won't trigger Flutter standards. Open a `.dart` file and try again.

**Skill names tokens that don't exist** — the skills detect your design-system class names by grepping `lib/shared/` (Flutter) or `components/` (Web). If they can't find them, they default to generic names (`AppColors`, `AppSpacing`). Drop a project `CLAUDE.md` line telling Claude your actual class names.

**Cursor / Antigravity changes don't appear** — the generated files are artifacts, not live imports. Re-run `scripts/export.sh` after pulling latest.

---

## What's next

- [docs/skills.md](skills.md) — every skill with sample output
- [docs/craft.md](craft.md) — the philosophy
- [ROADMAP.md](../ROADMAP.md) — what's shipping next
- [docs/contributing.md](contributing.md) — add rules or skills
