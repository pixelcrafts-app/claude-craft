# Claude Craft

Software standards that live inside Claude Code. You install a plugin, Claude starts applying the standards. No `CLAUDE.md` edits, no onboarding doc, no drift between projects.

Three packs ship today:

| Pack | Stack | What you get |
|---|---|---|
| **flutter-standards** | Flutter + Dart | 9 auto-invoke standards · 8 audit/scaffold skills · 3 review agents |
| **api-standards** | NestJS + Prisma | 2 auto-invoke standards · sync-migrate workflow · 2 review agents |
| **web-standards** | Next.js + Tailwind + shadcn | 1 auto-invoke standard · pre-ship + premium-check audits |

Plus **`core-hooks`** — cross-stack safety that blocks edits to `.env`/secrets and dangerous shell commands (`rm -rf`, `git reset --hard`).

---

## Install in 30 seconds

Drop this into `.claude/settings.json` in your project:

```json
{
  "extraKnownMarketplaces": {
    "pixelcrafts": {
      "source": { "source": "github", "repo": "pixelcrafts-app/claude-craft" }
    }
  },
  "enabledPlugins": {
    "flutter-standards@pixelcrafts": true,
    "core-hooks@pixelcrafts": true
  }
}
```

Swap `flutter-standards` for `api-standards` or `web-standards` depending on the project. Commit it. Every teammate who opens the project in Claude Code auto-installs on first session.

Prefer slash commands? Run once:

```
/plugin marketplace add pixelcrafts-app/claude-craft
/plugin install flutter-standards@pixelcrafts
/plugin install core-hooks@pixelcrafts
```

Update later with `/plugin marketplace update pixelcrafts`.

---

## How it works

**Auto-invoke standards.** Skills inside each pack carry descriptions like "apply to NestJS + Prisma code". Claude matches them against what it's editing and loads the relevant standards automatically. Edit a `.dart` widget → craft, engineering, widget, and a11y rules kick in. Edit a NestJS controller → nestjs + code-quality kick in. You don't import, enable, or remember anything.

**Explicit skills via slash commands.** For audits and scaffolds you trigger on demand:

```
/flutter-standards:pre-ship           Full quality gate before merging
/flutter-standards:scaffold-feature   Generate a feature with 4 states + data layer wired
/flutter-standards:find-hardcoded     Scan lib/ for design-system violations
/api-standards:sync-migrate           Prisma schema change workflow + downstream consumer reminders
/web-standards:premium-check          Craft review of a single component
```

Full list: [docs/skills.md](docs/skills.md).

**Review agents.** Invoke on a branch:

```
use agent api-standards:security-reviewer to audit auth changes on this branch
use agent flutter-standards:flutter-reviewer to review src/features/checkout/
```

Agents load their pack's standards before reviewing, so the review applies the full standard — not a generic checklist.

---

## Use with Cursor, Antigravity, Codex, Aider

One script exports the same standards to every AI tool's native format:

```bash
git clone https://github.com/pixelcrafts-app/claude-craft
./claude-craft/scripts/export.sh /path/to/your-project flutter
```

Generates:
- `.cursor/rules/*.mdc` — Cursor Rules v2, globbed to the right files
- `AGENTS.md` — concatenated standards for Antigravity / Codex / Aider / OpenAI SWE

Packs: `flutter`, `api`, `web`. Regenerate anytime to pull the latest.

---

## Why this exists

Teams shipping multiple apps in the same stack hit the same problem: every project grows its own "shared" rules, and every copy drifts. A year later you have four answers to "what's the padding on a card?" — one per project, none authoritative.

Copy-paste between projects drifts. Git submodules rot. Notion docs decay. The durable fix is to put the standards in a **plugin marketplace** — install once, update with one command, and the rules your AI collaborator follows are the rules you actually wrote.

Longer argument in [docs/why.md](docs/why.md). Philosophy in [docs/craft.md](docs/craft.md).

---

## Docs

| Audience | Start here |
|---|---|
| Adopting for your team | [docs/why.md](docs/why.md) → [docs/craft.md](docs/craft.md) |
| Setting up in a project | [docs/quickstart.md](docs/quickstart.md) |
| Browsing what each skill does | [docs/skills.md](docs/skills.md) |
| Contributing | [docs/contributing.md](docs/contributing.md) |
| What's next | [ROADMAP.md](ROADMAP.md) |

---

## Project layout

```
claude-craft/
├── .claude-plugin/marketplace.json      4 plugins
├── flutter/skills/flutter-standards/    Flutter pack
├── api/skills/api-standards/            NestJS + Prisma pack
├── web/skills/web-standards/            Next.js pack
├── core/plugins/core-hooks/             Cross-stack safety hooks
├── scripts/export.sh                    Cursor + AGENTS.md export
├── docs/                                Guides, philosophy, changelog
├── ROADMAP.md
└── README.md
```

---

## Status

**v0.2.0** — packs consolidated, standalone per-skill plugins removed. One bundle per stack is now the only shape; every skill is still accessible via slash commands (`/flutter-standards:pre-ship`, etc.).

See [docs/changelog.md](docs/changelog.md) for the release history.

## Contributing

PRs welcome. See [docs/contributing.md](docs/contributing.md).

## License

MIT — [LICENSE](LICENSE).
