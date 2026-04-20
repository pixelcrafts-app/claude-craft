# Pixelcrafts Standards

**Production-grade software standards for AI coding agents — across stacks, across tools.**

One marketplace. 15 plugins. Three stack packs ship today — **Flutter**, **API (NestJS + Prisma)**, **Web (Next.js)** — plus a cross-stack `core-hooks` safety plugin. Works natively in Claude Code; exports to Cursor + Antigravity + AGENTS.md-consumers (Codex, Aider, OpenAI SWE) via one script. A **Database** pack is next; see [docs/roadmap.md](docs/roadmap.md).

**Zero CLAUDE.md edits.** Rules ship as auto-invoke skills — Claude loads them itself when you touch matching code.

---

## In 30 seconds (Claude Code, Flutter)

```
/plugin marketplace add nandamashokkumar/pixelcrafts
/plugin install flutter-standards@pixelcrafts
/plugin install core-hooks@pixelcrafts
```

Done. Open a `.dart` file and Claude starts applying craft, engineering, widget, a11y, perf, and testing standards. Slash commands (`/flutter-standards:pre-ship`, `/flutter-standards:scaffold-feature`, …) are immediately available.

Full zero-config install (no commands) in [docs/quickstart.md](docs/quickstart.md).

---

## What ships today

Three stack packs in v0.1.0 plus a cross-stack safety plugin — **Flutter**, **API (NestJS + Prisma)**, **Web (Next.js + Tailwind + shadcn)**, and **core-hooks**. The Flutter pack is the most complete (9 auto-invoke standards + 8 audit/scaffold skills + 3 agents); API and Web are focused initial releases extracted from production work across the pixelcrafts portfolio.

Catalog below is the Flutter pack. For API + Web, see [docs/skills.md](docs/skills.md).

## Flutter pack

### 9 auto-invoke standards skills

No imports, no configuration — each skill auto-loads when Claude sees matching work (e.g. editing a `.dart` widget triggers `craft-guide` + `widget-rules` + `accessibility`).

- **craft-guide** — typography, spacing, motion, state clarity, visual weight
- **engineering** — DRY, SSOT, Surgeon Principle, AI-Assisted Definition of Done
- **widget-rules** — widget discipline, animations, text resilience
- **api-data** — mappers, models, repositories, API client contract
- **testing** — pyramid, mocking, coverage, CI gates
- **accessibility** — Semantics, contrast, touch targets, RTL
- **performance** — frame budgets, cold start, images, isolates
- **forms** — field anatomy, validation, keyboard, autofill
- **observability** — logging, crash reports, analytics, PII

### 8 audit / scaffold skills — explicit slash commands

- **`/flutter-standards:pre-ship`** — full quality gate before merging
- **`/flutter-standards:premium-check`** — craft review of a single screen
- **`/flutter-standards:verify-screens`** — trace data source → screen
- **`/flutter-standards:find-hardcoded`** — scan `lib/` for design-system violations
- **`/flutter-standards:find-duplicates`** — scan `lib/` for DRY violations
- **`/flutter-standards:accessibility-audit`** — scan `lib/` for a11y violations (10 patterns)
- **`/flutter-standards:scaffold-screen`** — generate a screen with 4 states wired
- **`/flutter-standards:scaffold-feature`** — generate a full feature folder (model / mapper / repo / providers / screen / tests)

Each audit/scaffold skill is also published as a standalone slice plugin if you want it without the full bundle (`flutter-pre-ship@pixelcrafts`, etc.).

See [docs/skills.md](docs/skills.md) for what each one outputs.

---

## Why use it

| Pain | Fix |
|------|-----|
| Every new feature starts with a stub screen that grows half-built | `/scaffold-feature` generates 4 states + data layer in seconds |
| Reviewers catch the same a11y/perf/craft issues every PR | `/pre-ship` catches them before the PR opens |
| Design system drifts — hex colors creep back in | `/find-hardcoded` + CI gate keeps tokens enforced |
| Two widgets do the same thing under different names | `/find-duplicates` surfaces the groups to collapse |
| "Our standards live in a Notion page from 8 months ago" | Rules live in this repo; one `git pull` updates every consumer |

Longer argument in [docs/why.md](docs/why.md). Philosophy in [docs/craft.md](docs/craft.md).

---

## Install

### Option A — Zero-config (recommended for teams)

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

Every teammate opening the project in Claude Code auto-installs the marketplace + plugins on first session. No commands to run. No onboarding doc. Swap `flutter-standards` for `api-standards` or `web-standards` per project.

### Option B — Slash commands (one-off install)

```
/plugin marketplace add nandamashokkumar/pixelcrafts
/plugin install flutter-standards@pixelcrafts
/plugin install core-hooks@pixelcrafts
```

To update later: `/plugin marketplace update pixelcrafts`.

### Option C — Single-skill slice install

```
/plugin install flutter-find-hardcoded@pixelcrafts
/plugin install flutter-accessibility-audit@pixelcrafts
/plugin install flutter-scaffold-feature@pixelcrafts
```

Each audit/scaffold skill ships as an independent plugin. Every Flutter plugin is namespaced `flutter-<skill>` so stacks (`api-<skill>`, `web-<skill>`, `db-<skill>`) don't collide.

---

## Use with other AI tools

Cursor, Antigravity, Codex, Aider, and any tool that reads `AGENTS.md` can consume the same standards via the export script:

```bash
git clone https://github.com/nandamashokkumar/pixelcrafts
./claude-craft/scripts/export.sh /path/to/your-project flutter
```

It generates:
- `.cursor/rules/<pack>-<skill>.mdc` — Cursor Rules v2 format, one per standards skill, scoped to the right file globs
- `AGENTS.md` — concatenated standards for Antigravity, Codex, Aider, OpenAI SWE

Packs available: `flutter`, `api`, `web`. Regenerate anytime to pull the latest standards. One source of truth across every AI tool your team uses.

---

## What's inside

```
claude-craft/
├── .claude-plugin/
│   └── marketplace.json              15 plugins listed (Flutter + API + Web + core-hooks)
├── flutter/                          Flutter pack
│   └── skills/
│       ├── flutter-standards/        bundle — 9 auto-invoke standards + 8 audit/scaffold skills + 3 agents
│       ├── flutter-pre-ship/         slice — 1 skill
│       ├── flutter-premium-check/
│       ├── flutter-verify-screens/
│       ├── flutter-find-hardcoded/
│       ├── flutter-find-duplicates/
│       ├── flutter-accessibility-audit/
│       ├── flutter-scaffold-screen/
│       └── flutter-scaffold-feature/
├── api/                              API pack (NestJS + Prisma)
│   └── skills/
│       ├── api-standards/            bundle — 2 auto-invoke standards + sync-migrate workflow + 2 agents
│       └── api-sync-migrate/         slice — Prisma schema change workflow
├── web/                              Web pack (Next.js + Tailwind + shadcn)
│   └── skills/
│       ├── web-standards/            bundle — 1 auto-invoke standard + pre-ship + premium-check
│       ├── web-pre-ship/             slice — quality gate
│       └── web-premium-check/        slice — single-component craft audit
├── core/
│   ├── hooks/                        protect-files.sh, protect-bash.sh (source)
│   └── plugins/
│       └── core-hooks/               cross-stack safety plugin (registers PreToolUse hooks)
├── database/                         (planned) — same shape: database/skills/
├── scripts/
│   ├── sync.sh                       mirrors bundle edits → slice copies (all packs)
│   └── export.sh                     generates .cursor/rules + AGENTS.md for non-Claude-Code tools
├── docs/
│   ├── why.md                        problem + solution narrative
│   ├── quickstart.md                 5-min install walkthrough
│   ├── skills.md                     per-skill cards
│   ├── rules.md                      per-rule cards
│   ├── craft.md                      the philosophy
│   ├── contributing.md               edit / add / version / ship
│   ├── roadmap.md                    Database pack, Core extraction
│   ├── changelog.md                  release history
│   └── history.md                    how each pack was assembled
├── LICENSE                           MIT
└── README.md                         this file
```

---

## Documentation

| Audience | Start here |
|----------|------------|
| Tech lead deciding to adopt | [docs/why.md](docs/why.md) → [docs/craft.md](docs/craft.md) |
| Developer setting it up | [docs/quickstart.md](docs/quickstart.md) → [docs/skills.md](docs/skills.md) |
| Developer using it day-to-day | [docs/skills.md](docs/skills.md) → [docs/quickstart.md](docs/quickstart.md) |
| Contributor | [docs/contributing.md](docs/contributing.md) → [docs/history.md](docs/history.md) |

---

## Status & roadmap

- **Flutter pack — v0.1.0 shipped** (`flutter/`) — 9 auto-invoke standards, 8 audit/scaffold skills, 3 agents
- **API pack — v0.1.0 shipped** (`api/`) — NestJS + Prisma, 2 auto-invoke standards, 1 workflow skill, 2 agents
- **Web pack — v0.1.0 shipped** (`web/`) — Next.js + Tailwind + shadcn, 1 auto-invoke standard, 2 audit skills
- **core-hooks — v0.1.0 shipped** (`core/plugins/core-hooks/`) — cross-stack PreToolUse safety hooks
- **Multi-tool export — v0.1.0 shipped** (`scripts/export.sh`) — Cursor, Antigravity, Codex, Aider
- **Database pack** — planned. Postgres-first with MySQL notes. Will land at `database/` with plugins prefixed `db-<skill>`.
- **Core extraction** — with three packs now live, universal content (DRY, testing pyramid, observability, security) is the next extraction target. Will land as a shared `core-<skill>` pack referenced by the others.

See [docs/roadmap.md](docs/roadmap.md) for detail.

---

## Contributing

See [docs/contributing.md](docs/contributing.md). TL;DR: edit the Flutter bundle plugin, run `./scripts/sync.sh`, bump versions, tag, open PR.

## License

MIT — see [LICENSE](LICENSE).
