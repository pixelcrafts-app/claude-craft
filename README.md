# claude-craft

Standards your Claude Code follows — automatically. Install a pack, Claude applies the rules on every file, plans before coding, verifies its own output, and guards against mistakes. No `CLAUDE.md` edits.

![version](https://img.shields.io/badge/version-0.13.0-blue) ![license](https://img.shields.io/badge/license-MIT-green) ![plugins](https://img.shields.io/badge/plugins-7-orange)

---

## Architecture

Three layers. Clean separation. Engine owns orchestration only — all knowledge lives in skills.

```
USER ASK
    │
    ▼
┌──────────────────────────────────────────────────────┐
│  CORE-HOOKS  (bash — fires before every tool use)    │
│  protect-files · protect-bash · enforce-rules        │
│  enforcement-preamble · stop-gate · session-ledger   │
│  (configurable via .claude/enforcement.json)         │
└──────────────────────┬───────────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────────┐
│  CORE-STANDARDS  (pure instructions — no bash)       │
│                                                      │
│  ENGINE SKILL                                        │
│  verify-changes: plan → delegate → cross-check       │
│                  → fix (3-retry cap) → report        │
│                                                      │
│  UNIVERSAL SKILLS (auto-load by task type)           │
│  work-principles · planning · universal-rules        │
│  verification · auth-flows · craft-config            │
│  subagent-brief · mcp-integration · docs-sync        │
└───────────┬──────────────────────┬───────────────────┘
            │                      │
            ▼                      ▼
┌───────────────────┐  ┌───────────────────────────────┐
│  STACK PACKS      │  │  PROJECT CONFIG               │
│  api              │  │  .claude/craft.json           │
│  web              │  │  stacks · features · disabled │
│  mobile           │  │  (conversational verification)│
│  flutter          │  │                               │
│  design           │  │  .claude/enforcement.json     │
└───────────────────┘  │  mandatory · gate rules       │
                       │  (hook enforcement — pre-tool)│
                       └───────────────────────────────┘
            │
            ▼
    OUTPUT: verdict + evidence per rule + suggested fixes
```

---

## Core Principles

1. **Engine owns orchestration only.** No stack knowledge, no content in the engine. Plan → delegate → cross-check → report.
2. **Skills own all knowledge.** work-principles, universal-rules, planning, subagent-brief — all in SKILL.md. Nothing in bash.
3. **Hooks own deterministic enforcement.** Regex-level checks (secrets, dangerous commands, hardcoded tokens) belong in hooks. Judgment belongs in skills.
4. **Non-destructive by default.** Detect → Check → Suggest. Skills report and suggest. Only hooks block. Only explicit slash commands fix.
5. **Evidence required.** Every verdict cites `file:line`. No opinions, no summaries without grounded evidence.
6. **Cross-check before report.** Agent verifies plan was completed. Gaps are fixed (3-retry cap). Nothing ships unverified.
7. **Configurable, not opinionated about your project.** Protected files, blocked commands, enforcement rules — all overridable in `.claude/enforcement.json`.

---

## What You Get

### Automatic — zero user action

| Hook / Skill | Fires on | Behavior |
|---|---|---|
| `protect-files` | Every file edit | Blocks `.env`, credentials, lockfiles (configurable) |
| `protect-bash` | Every shell command | Blocks `rm -rf`, force push, destructive ops (configurable) |
| `enforce-rules` | Every file edit | Runs pack rule registry (opt-in per project) |
| `stop-gate` | Every turn end | Blocks until mandatory gate passes (opt-in) |
| Stack skills | Relevant file edits | Flutter/web/api rules loaded automatically by file type |
| `work-principles` | Every non-trivial task | Detect→Check→Suggest, non-destructive reasoning |
| `planning` | Every delivery task | Dependencies, edge cases, verification steps before starting |
| `subagent-brief` | Every Task/Agent spawn | Warm brief contract (GOAL/CONTEXT/SCOPE/OUTPUT), trust boundary |

### On demand — user invokes

| Trigger | What fires | Result |
|---|---|---|
| `"verify my changes"` | `verify-changes` | Audit with dependency graph, PASS/FAIL per rule with evidence |
| `/flutter-standards:app-audit` | app-audit → `verify-changes` | Full Flutter audit: pre-ship + craft + screen states |
| `/web-standards:pre-ship` | thin wrapper → `verify-changes` | Pre-commit web audit |
| `/web-standards:premium-check` | thin wrapper → `verify-changes` | UI craft quality check |
| `/web-standards:theme-audit` | thin wrapper → `verify-changes` | Theme consistency check |

---

## Packs

| Pack | Stack | Skills |
|---|---|---|
| `core-hooks` | All | 5 bash enforcement hooks |
| `core-standards` | All | Engine + 12 universal skills |
| `design-standards` | Web + iOS + Android | 6 platform-agnostic design skills |
| `web-standards` | Next.js / Tailwind / shadcn | 11 skills — craft, audit, performance, i18n, taste |
| `api-standards` | NestJS / Prisma | 6 skills — api-design, nestjs, db-migrations, websockets |
| `mobile-standards` | Flutter / RN / SwiftUI / Compose | 6 universal mobile skills |
| `flutter-standards` | Flutter / Dart | 5 Flutter-specific skills — engineering, audit, scaffold, scan |

---

## Install

```
/plugin marketplace add pixelcrafts-app/claude-craft
/plugin install core-hooks@pixelcrafts
/plugin install core-standards@pixelcrafts
/plugin install web-standards@pixelcrafts      # web projects
/plugin install api-standards@pixelcrafts      # API/backend projects
/plugin install design-standards@pixelcrafts   # any UI work
/plugin install mobile-standards@pixelcrafts   # mobile projects
/plugin install flutter-standards@pixelcrafts  # Flutter projects (pair with mobile-standards)
```

**Team install** — commit `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "pixelcrafts": { "source": { "source": "github", "repo": "pixelcrafts-app/claude-craft" } }
  },
  "enabledPlugins": {
    "core-hooks@pixelcrafts": true,
    "core-standards@pixelcrafts": true,
    "web-standards@pixelcrafts": true
  }
}
```

**Enforcement mode** — commit `.claude/enforcement.json` to opt in:

```json
{
  "mandatory": ["web-standards"],
  "gate_required": true,
  "allowed_files": [".env.example"],
  "allowed_commands": ["rm -rf dist/"]
}
```

---

## Layout

```
.claude-plugin/marketplace.json

core/skills/
  core-hooks/                    bash enforcement hooks
    hooks/                       protect-files · protect-bash · enforce-rules · stop-gate · session-ledger
    enforcement/                 per-pack rule registries (JSON)
  core-standards/                engine + universal skills
    skills/verify-changes/       audit + delivery engine
    skills/work-principles/      always-load behavioral rules
    skills/planning/             pre-delivery planning procedure
    skills/universal-rules/      universal §N.M rules
    skills/verification/         cross-check procedure
    skills/subagent-brief/       delegation contract
    skills/mcp-integration/      MCP config reference
    skills/docs-sync/            post-audit doc drift check

design/skills/design-standards/  platform-agnostic design (Web + iOS + Android)
    skills/accessibility/        WCAG 2.2 + Swift traits + Compose semantics
    skills/design-laws/          color strategy, anti-AI-slop, absolute bans
    skills/brand-research/       fact verification + asset collection protocol
    skills/creative-direction/   memorable vs functional UI signals
    skills/aesthetic-coherence/  mixed design language detection
    skills/information-architecture/

web/skills/web-standards/        Next.js / Tailwind / shadcn
    skills/craft-guide/          §1–§15 premium craft rules
    skills/premium-signals/      Linear/Vercel/Arc precise values
    skills/taste/                metric dials (variance, motion, density)
    skills/nextjs/ · performance/ · i18n/ · extract-tokens/
    skills/pre-ship/ · premium-check/ · theme-audit/

api/skills/api-standards/        NestJS / Prisma
    skills/api-design/           REST resource naming, status codes, pagination
    skills/nestjs/               NestJS patterns and enforcement
    skills/db-migrations/        Prisma schema → migration → client regeneration
    skills/code-quality/ · websockets/ · cross-stack-contracts/

mobile/skills/
  mobile-standards/              universal mobile (Flutter / RN / SwiftUI / Compose)
    skills/craft-guide/ · production-readiness/ · forms/
    skills/observability/ · premium-signals/ · design-tokens/
  flutter-standards/             Flutter / Dart specific
    skills/engineering/          Dart, widget rules, data layer
    skills/accessibility/        Semantics, screen readers, 48dp targets
    skills/performance/          DevTools, frame budget, const widgets
    skills/app-audit/            full Flutter audit command
    skills/scaffold/             feature + screen file structure generator
    skills/scan/                 hardcoded values, duplicates, a11y scan

docs/                            contributing · changelog · skills · enforcement
scripts/                         compile agents, export utilities
```

---

## Docs

| | |
|---|---|
| [docs/skills.md](docs/skills.md) | Skill catalog |
| [docs/enforcement.md](docs/enforcement.md) | Enforcement + delegation setup |
| [docs/contributing.md](docs/contributing.md) | Adding packs, skills, rules |
| [docs/changelog.md](docs/changelog.md) | Release history |

---

**v0.13.0** · MIT · PRs welcome → [docs/contributing.md](docs/contributing.md)
