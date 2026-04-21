<div align="center">

# Claude Craft

**Standards your AI actually follows.**

Install a plugin → Claude starts writing code the way your team wants it, on every file, in every project.
No `CLAUDE.md` edits. No onboarding wiki. No drift.

[Quickstart](docs/quickstart.md) · [See it in action](docs/before-after.md) · [Skills](docs/skills.md) · [Roadmap](ROADMAP.md)

![version](https://img.shields.io/badge/version-0.10.0-blue) ![license](https://img.shields.io/badge/license-MIT-green) ![plugins](https://img.shields.io/badge/plugins-4-orange) ![stack](https://img.shields.io/badge/stack-flutter%20%7C%20api%20%7C%20web-purple)

</div>

---

## ⚡ What is this?

A **plugin marketplace for Claude Code** packed with production-grade standards for three stacks:

- 📱 **Flutter** — Dart, widgets, state, design-system discipline, accessibility, performance
- 🔌 **API** — NestJS + Prisma, controllers / services / repositories, security, operational readiness
- 🌐 **Web** — Next.js + Tailwind + shadcn, Server Components, React Query, CSP, Core Web Vitals

Claude reads the right rules automatically when it sees matching files. No manual invocation.

```
You open my-app/ in Claude Code
   │
   ├─ editing a .dart file  →  Flutter pack fires: craft, widget, a11y, perf...
   ├─ editing a .ts file    →  API pack fires: nestjs, code-quality...
   └─ editing a .tsx file   →  Web pack fires: nextjs, production-readiness...
```

The same standards export to **Cursor**, **Antigravity**, **Codex**, and **Aider** — one repo, every AI tool.

---

## 🚀 Install in 30 seconds

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

Swap `flutter-standards` for `api-standards` or `web-standards`. Commit the file. Every teammate who opens the repo in Claude Code auto-installs on first session — zero shell commands.

<details>
<summary><strong>Prefer slash commands? One-off install</strong></summary>

```
/plugin marketplace add pixelcrafts-app/claude-craft
/plugin install flutter-standards@pixelcrafts
/plugin install core-hooks@pixelcrafts
```

Update later with `/plugin marketplace update pixelcrafts`.
</details>

---

## 📦 The packs

<table>
<tr>
<td width="33%">

### 📱 `flutter-standards`

Flutter + Dart.

10 auto-invoke standards, 8 audit + scaffold skills.

**Killer feature:** `/flutter-standards:scaffold-feature` — full vertical slice (model, mapper, repository, data sources, providers, screen with 4 states, tests) in under a minute.

</td>
<td width="33%">

### 🔌 `api-standards`

NestJS + Prisma.

2 auto-invoke standards + 11-check smart production audit, sync-migrate workflow.

**Killer feature:** `code-quality` runs Detect → Check → Suggest on rate limits, idempotency, webhooks, pool sizing — never blindly enforces.

</td>
<td width="33%">

### 🌐 `web-standards`

Next.js + Tailwind + shadcn.

3 auto-invoke standards (nextjs, production-readiness, craft-guide — now with stable `§N.M` rule IDs) + 5 explicit commands (pre-ship, premium-check, extract-tokens, theme-audit, aesthetic-coherence). Every audit command is a thin wrapper: iteration, batching, and the fix loop live once in the cross-stack engine (`core-skills:verify-changes`).

**Killer feature:** `craft-guide` enforces universal design formulas (contrast math, harmony, 60-30-10, aesthetic coherence) without ever picking brand values. Every rule has a stable ID — commands scope to subsets (`theme-audit` → `§13` only) or run the full set (`premium-check` → `§1 – §15`). One iteration-loop implementation, not one per command.

</td>
</tr>
</table>

Plus two cross-stack plugins — the default companion to any stack pack. Both self-gate, so install cost when unused is zero:

**`core-hooks`** — hooks only, deterministic enforcement:
- 🔒 **PreToolUse hooks** — block edits to `.env` / secrets (every project); block `rm -rf`, `git reset --hard`, and other destructive shell (every project); block raw design values **only** in projects with a detected token system
- 🧭 **SessionStart hook** — surfaces plugin-hook mechanics to Claude (e.g. hooks don't fire inside subagent writes — brief accordingly)
- 🛡️ **Enforcement mode (v0.10.0, opt-in)** — commit `.claude/enforcement.json` listing mandatory packs → SessionStart pins a mandatory-skills preamble, PreToolUse hard-blocks per-pack rule violations, Stop hook blocks turn-end until each pack's gate command has passed. One-file opt-in, three-tier config, zero change to existing installs if you don't create the file. Full guide: [docs/enforcement.md](docs/enforcement.md)

**`core-skills`** — three auto-invoke skills, pure prompts:
- 📝 **`docs-sync`** — fires at end-of-task only when docs exist to drift from. Silent on projects without a README/CHANGELOG to maintain
- ✅ **`verify-changes`** — fires only on "verify my changes" / "cross-check" intent. Asks scope + dimensions + depth, walks a dependency graph of the changeset, runs batched rule-by-rule audits using whichever standards packs you have installed. Stack-agnostic
- 🎯 **`subagent-brief`** — fires only when Claude is about to delegate. Enforces GOAL / CONTEXT / SCOPE / TASK / OUTPUT SHAPE / BUDGET so the spawn starts warm instead of re-discovering context

---

## 🧠 How it works

**Auto-invoke standards.** Each skill carries a description like *"apply to NestJS + Prisma code — thin controllers, DTO validation, repository pattern..."*. Claude matches skill descriptions against what it's editing and loads the relevant ones automatically.

- Edit a `.dart` widget → craft, engineering, widgets, a11y, performance kick in
- Edit a NestJS controller → nestjs + code-quality (now with 11-check production audit) kick in
- Edit a Next.js route → nextjs + production-readiness + craft-guide kick in

You don't import, enable, or remember anything. [See the catalog →](docs/skills.md)

**Smart, not rigid.** Contextual concerns (rate limiting, retries, CSP, offline sync, deep links) follow **Detect → Check → Suggest**:

```
  Detect  →  Does the codebase already handle this?        (grep + read)
  Check   →  If yes, is it done well?                      (depth audit)
  Suggest →  If no, propose options with tradeoffs         (user decides)
```

The skill never rewrites your app to add a rate limiter. It tells you the gap, shows you the options, and you pick.

**Explicit skills via slash commands** — for audits and scaffolds you trigger on demand:

```
/flutter-standards:pre-ship           Full quality gate before merge
/flutter-standards:scaffold-feature   Vertical slice in under a minute
/flutter-standards:find-hardcoded     Scan lib/ for design-system violations
/api-standards:sync-migrate           Prisma schema workflow + downstream sync
/web-standards:premium-check          Craft review of a single component
```

---

## 🎬 See it in action

A full before/after gallery with real snippets from each pack lives at [docs/before-after.md](docs/before-after.md).

**Taste 1 — the smart API audit:**

```
You:  Claude, is this API ready for production?

Claude:
  Detect → Check → Suggest — Rate limiting (J1)
    Status: NOT DETECTED
    Risk:   /users/search is unauthenticated and DB-backed. Scraper
            abuse will pin a DB connection per request.
    Options:
      (a) @nestjs/throttler — per-route decorators, in-process
      (b) Redis-backed limiter — shared across instances
      (c) Handle upstream at the gateway (Cloudflare / Fly)
    Recommendation: (a) for single-instance, (b) for HA.
                    Will not install without your approval.
```

**Detect the gap. Audit depth if present. Suggest with tradeoffs. Let you decide.** No app-rewriting behind your back.

**Taste 2 — `verify-changes` catching a consumer break before the PR:**

```
You:  I renamed <Button /> and touched 8 files. Verify before I commit.

Claude (verify-changes):
  Scope: 10 uncommitted files. Dimensions: SMART. Depth: direct + consumers.
  Dependency graph: Button.tsx → 12 consumers (3 via barrel file).
  Plan: 34 tasks in 5 batches. Proceed? [y]

  ... batches run, summaries posted to task metadata ...

  Verdict: BLOCK — 2 consumer breaks + 1 polish.
    ✗  app/checkout/page.tsx:42    imports old name `Button`, renamed to `PrimaryButton`
    ✗  app/settings/form.tsx:18    barrel `components/index.ts` not updated
    ·  components/hero.tsx:7       button label "Click here" — generic (polish)

  Say "fix" to apply suggested patches, or commit at your own risk.
```

That's the pattern. **Diff → graph → batched audit → verdict with evidence.** Consumer breakage gets caught *before* it ships, not after the hotfix.

---

## 🎨 Use with Cursor, Antigravity, Codex, Aider

One script exports the same standards to every tool's native format:

```bash
git clone https://github.com/pixelcrafts-app/claude-craft
./claude-craft/scripts/export.sh /path/to/your-project flutter
```

Generates:

- `.cursor/rules/*.mdc` — Cursor Rules v2, scoped globs per skill
- `AGENTS.md` — concatenated standards for Antigravity / Codex / Aider / OpenAI SWE

Packs: `flutter`, `api`, `web`. Regenerate anytime to pull latest.

---

## 👤 Who this is for

- **Solo devs / vibe coders** — you want Claude to stop writing inconsistent code across projects. Install a pack. Done.
- **Small teams** — you want shared standards that actually get followed, not a wiki page nobody reads. Commit `.claude/settings.json`. Everyone gets the same rules on day one.
- **Larger orgs** — you want to fork, customise, and point your team's config at your own marketplace. The repo structure is the template.

Don't need a pack for your stack yet? Fork the repo — each plugin is a self-contained folder. Pattern is easy to extend.

---

## 🤔 Why this exists

Teams shipping multiple apps in the same stack hit the same problem: every project grows its own "shared" rules, every copy drifts. A year later you have four answers to "what padding goes on a card?" — one per project, none authoritative.

Copy-paste drifts. Git submodules rot. Notion docs decay. The durable fix is to put the standards in a **plugin marketplace** — install once, update with one command, and the rules your AI collaborator follows are the rules you actually wrote.

Longer argument: [docs/why.md](docs/why.md). Philosophy: [docs/craft.md](docs/craft.md).

---

## 📚 Docs

| You want to... | Read |
|---|---|
| Install it in a project | [docs/quickstart.md](docs/quickstart.md) |
| See before / after examples | [docs/before-after.md](docs/before-after.md) |
| Browse every skill | [docs/skills.md](docs/skills.md) |
| Understand the philosophy | [docs/craft.md](docs/craft.md) |
| Understand why it exists | [docs/why.md](docs/why.md) |
| Contribute a pack or rule | [docs/contributing.md](docs/contributing.md) |
| See what's next | [ROADMAP.md](ROADMAP.md) |
| See release history | [docs/changelog.md](docs/changelog.md) |
| Enforce rules so Claude can't bypass them | [docs/enforcement.md](docs/enforcement.md) |
| Report a security issue | [SECURITY.md](SECURITY.md) |

---

## 🗂️ Project layout

```
claude-craft/
├── .claude-plugin/marketplace.json      4 plugins registered
├── flutter/skills/flutter-standards/    Flutter pack — 10 standards + 8 skills + 3 agents
├── api/skills/api-standards/            NestJS + Prisma pack — 2 standards + sync-migrate
├── web/skills/web-standards/            Next.js pack — 3 standards + pre-ship, premium-check, extract-tokens, theme-audit, aesthetic-coherence
├── core/plugins/core-hooks/             Hooks — secret/shell/token-value blocks + SessionStart mechanics
├── core/plugins/core-skills/            Cross-stack skills — docs-sync, verify-changes, subagent-brief
├── scripts/export.sh                    Cursor + AGENTS.md export
├── docs/                                Guides, philosophy, before/after, changelog
├── ROADMAP.md                           What's shipping next
└── SECURITY.md                          Vulnerability reporting
```

---

## 🛣️ Status

**v0.10.0** — Enforcement mode. Commit `.claude/enforcement.json` → SessionStart pins a mandatory-skills preamble, PreToolUse hard-blocks per-pack rule violations (regex-level), Stop hook refuses turn-end until each pack's gate command passes. Generic runner + per-pack declarative rule registries; new packs ship rules by dropping one JSON file. Fully opt-in — existing installs see zero change until they create the config.

**v0.9.0** — Thin-wrapper architecture. Audit commands become ≤50-line scope + dimension pickers; iteration, batching, and the fix loop live once in `core-skills:verify-changes`. `craft-guide` (§1–§15) and `production-readiness` (§R1–§R10) gain stable rule IDs so commands can scope to subsets. `aesthetic-coherence` becomes hybrid (signal detection + engine-driven §9 compliance). `accessibility-audit` → `audit-a11y-patterns` to match what it actually is.

**v0.8.0** — Isolated ownership cleanup. Split `core-hooks` into two plugins: `core-hooks` (hooks only) and `core-skills` (the three cross-stack skills `docs-sync`, `verify-changes`, `subagent-brief`). Removed invented skip-paths, magic-comment escape hatch, and the pre-defined review-agent personas.

**v0.6.0** — `verify-changes` skill lands in `core-hooks`. Generic cross-stack verification — asks scope + dimensions + depth, walks a dependency graph of the changeset, runs batched rule-by-rule audits using whatever SKILL.md files are installed, records results in task metadata to preserve context on large changesets. Pure prompt, no hooks, no MCPs, no indexing. Also ships `subagent-brief` — warm-brief discipline on Agent / Task / Explore delegation.

**v0.5.0** — Web design pack. New auto-invoke `craft-guide` (17-section universal design formulas — color + harmony + contrast, spacing, type + font loading, shadow/radius scales, motion, all state variants, 14 aesthetics with "never mix two" rule, iconography, chrome, a11y, theme, microcopy, brand moments). 4 new explicit skills: iteration-loop `premium-check`, `extract-tokens`, `theme-audit`, `aesthetic-coherence`. Universal formulas enforced; brand values from user.

Prior releases: [docs/changelog.md](docs/changelog.md). What's next: [ROADMAP.md](ROADMAP.md).

## 🤝 Contributing

PRs welcome — from typo fixes to new packs. See [docs/contributing.md](docs/contributing.md).

## 📝 License

MIT — [LICENSE](LICENSE).

---

<div align="center">

Built by [pixelcrafts](https://github.com/pixelcrafts-app) · Keep your standards in one place · Let Claude do the rest.

</div>
