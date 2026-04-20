# Roadmap

## Repo model

The pixelcrafts Standards family ships as **one repo, one marketplace, stack packs as top-level folders**. Teams install the packs they need via one marketplace install and one plugin install per desired skill.

```
claude-craft/                 ← one repo
├── .claude-plugin/marketplace.json    ← one marketplace, 15 plugins
├── flutter/                           ← pack 1 (shipped)
├── api/                               ← pack 2 (shipped)
├── web/                               ← pack 3 (shipped)
├── core/                              ← cross-stack safety (shipped — core-hooks)
├── database/                          ← pack 5 (planned)
└── scripts/
    ├── sync.sh                        ← bundle → slice mirror
    └── export.sh                      ← Cursor + AGENTS.md exporter
```

Plugins are namespaced per stack (`flutter-<skill>`, `api-<skill>`, `web-<skill>`, `db-<skill>`) so installs don't collide. Slash commands are namespaced per bundle (`/flutter-standards:pre-ship`, `/api-standards:sync-migrate`) — unambiguous across packs.

## Packs

| Pack | Status | Covers | Install prefix |
|------|--------|--------|----------------|
| **flutter** | Shipped — v0.1.0 | Widgets, state, lists, forms, a11y, perf, observability | `flutter-<skill>` |
| **api** | Shipped — v0.1.0 | NestJS + Prisma: schema workflow, controller/service/repo discipline, validation, error shapes, code-quality audit | `api-<skill>` |
| **web** | Shipped — v0.1.0 | Next.js + Tailwind + shadcn: app router, state, data fetching, responsive, dark mode, a11y | `web-<skill>` |
| **core-hooks** | Shipped — v0.1.0 | Cross-stack PreToolUse safety: block secret edits, dangerous shell | `core-hooks` |
| **database** | Planned | Schema design, migrations, indexing, query patterns, transactions — Postgres-first with MySQL notes | `db-<skill>` |
| **core-standards** | Next extraction target | Universal auto-invoke standards shared across packs (engineering, testing pyramid, observability, security basics) | `core-<skill>` |

## What's universal vs stack-specific

With three packs now shipping (Flutter, API, Web), the universal content is visible in multiple places:

- **Universal (~40%)** — DRY, SSOT, verification, testing pyramid, observability three-pillars, PII classification, security basics, AI-assisted DoD
- **Stack-specific (~60%)** — widget/animation rules (Flutter), controller/service/Prisma rules (API), app-router/Tailwind/shadcn rules (Web), schema/index rules (DB, planned)

Core extraction is now the natural next step — each pack currently carries its own copy of the universal rules inside its standards skills, and the duplication is visible. The extracted **core-standards** pack will ship auto-invoke skills consumed alongside any stack pack (no `CLAUDE.md` edits needed — Claude loads them itself).

## Design decisions so far

- **One repo, stacks as folders** — simpler than multi-repo, keeps universal extraction in-tree when we're ready, single tag/release cadence
- **One marketplace across stacks** — one `/plugin marketplace add` covers every pack; users install only the plugins they care about
- **Stack-prefixed plugin names** — `flutter-pre-ship`, not `pre-ship`, so `api-pre-ship` and `db-pre-ship` can exist without collision
- **Namespaced slash commands** — `/flutter-standards:pre-ship`, `/api-standards:sync-migrate`; unambiguous across installed packs
- **Rules ship as auto-invoke skills** — Claude Code loads them itself when file types match; zero `CLAUDE.md` edits, zero `@`-imports
- **Zero-config install** — commit `.claude/settings.json` with `extraKnownMarketplaces` + `enabledPlugins`; team auto-installs on first session
- **Bundle + slice plugins per pack** — `<stack>-standards` bundle installs everything; individual slice plugins let teams adopt incrementally
- **Multi-tool export** — `scripts/export.sh` generates Cursor Rules + AGENTS.md from the same sources, so Cursor / Antigravity / Codex users get the same standards

## What's NOT on the roadmap (yet)

- **Vue/Svelte/Angular frontend packs** — Next.js covers the pixelcrafts portfolio; other frameworks when demand shows up
- **Desktop pack** — Electron/Tauri; low priority
- **Infra pack** — Terraform/Pulumi/CDK; separate domain, separate team probably owns it
- **Mobile native packs** (SwiftUI, Jetpack Compose) — when demand shows up

## Next milestones

1. Internal testing across the pixelcrafts portfolio (4 projects: api-core, api-news, web app, mobile) — gather real numbers on regression reduction, time saved per feature, token violation counts
2. Extract `core-standards` from the three shipped packs — DRY, testing pyramid, observability, security basics; ships as auto-invoke skills alongside stack packs
3. Add a Database pack at `database/` with `db-<skill>` plugins
4. Expand API pack beyond NestJS + Prisma if another backend stack lands in the portfolio
5. Expand `scripts/export.sh` as new AI-tool rule formats stabilize (Windsurf, Zed AI, etc.)
