# claude-craft

Standards your Claude Code follows — automatically. Install a pack, Claude applies the rules on every file, plans before coding, verifies its own output, and guards against mistakes. No `CLAUDE.md` edits.

![version](https://img.shields.io/badge/version-0.12.0-blue) ![license](https://img.shields.io/badge/license-MIT-green) ![plugins](https://img.shields.io/badge/plugins-5-orange)

---

## Architecture

Three layers. Clean separation. Engine owns orchestration only — all knowledge lives in skills.

```
USER ASK
    │
    ▼
┌──────────────────────────────────────────────────────┐
│  CORE-HOOKS  (bash — fires before every tool use)    │
│  protect-files · protect-bash · enforce-tokens       │
│  enforce-rules · enforce-subagent-brief · stop-gate  │
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
│  principles · planning · rules · verification        │
│  auth-flows · craft-config · agents                  │
│  mcp-integration · docs-sync · subagent-brief        │
└───────────┬──────────────────────┬───────────────────┘
            │                      │
            ▼                      ▼
┌───────────────────┐  ┌───────────────────────────────┐
│  STACK PACKS      │  │  PROJECT CONFIG               │
│  flutter          │  │  .claude/craft.json           │
│  web (+i18n,      │  │  stacks · features · disabled │
│   premium-signals)│  │  (conversational verification)│
│  api (+cross-     │  │                               │
│   stack, websocks)│  │  .claude/enforcement.json     │
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
2. **Skills own all knowledge.** Principles, rules, planning, agents contract — all in SKILL.md. Nothing in bash.
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
| `enforce-tokens` | Every file edit | Blocks hardcoded design values in token-managed projects |
| `enforce-rules` | Every file edit | Runs pack rule registry (opt-in per project) |
| `enforce-subagent-brief` | Every Task/Agent spawn | Blocks cold spawns below warmth threshold |
| `stop-gate` | Every turn end | Blocks until mandatory gate passes (opt-in) |
| Stack skills | Relevant file edits | Flutter/web/api rules loaded automatically by file type |
| `principles` | Every non-trivial task | Detect→Check→Suggest, non-destructive reasoning |
| `planning` | Every delivery task | Dependencies, edge cases, verification steps before starting |
| `agents` | Every delegation | Warm brief contract, trust boundary, cross-check required |

### On demand — user invokes

| Trigger | What fires | Result |
|---|---|---|
| `"verify my changes"` | `verify-changes` | Audit with dependency graph, PASS/FAIL per rule with evidence |
| `/flutter-standards:pre-ship` | thin wrapper → `verify-changes` | Pre-commit flutter audit |
| `/web-standards:pre-ship` | thin wrapper → `verify-changes` | Pre-commit web audit |
| `/web-standards:premium-check` | thin wrapper → `verify-changes` | UI craft quality check |
| `/web-standards:theme-audit` | thin wrapper → `verify-changes` | Theme consistency check |

---

## Packs

| Pack | Stack | Content |
|---|---|---|
| `core-hooks` | All | 8 bash enforcement hooks |
| `core-standards` | All | Engine skill + 8 universal skills |
| `flutter-standards` | Flutter/Dart | 10 auto-invoke standards + audit commands |
| `web-standards` | Next.js/Tailwind/shadcn | 3 auto-invoke standards + 5 audit commands |
| `api-standards` | NestJS/Prisma | 2 auto-invoke standards + sync-migrate |

---

## Install

```
/plugin marketplace add pixelcrafts-app/claude-craft
/plugin install core-hooks@pixelcrafts
/plugin install core-standards@pixelcrafts
/plugin install flutter-standards@pixelcrafts   # or web-standards / api-standards
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
  "warm_brief_required": true,
  "allowed_files": [".env.example"],
  "allowed_commands": ["rm -rf dist/"]
}
```

---

## Layout

```
.claude-plugin/marketplace.json          plugin registry
core/plugins/core-hooks/                 bash enforcement hooks
  hooks/                                 8 hook scripts
  enforcement/                           per-pack rule registries (JSON)
core/plugins/core-standards/             engine + universal skills
  skills/verify-changes/                 audit + delivery engine
  skills/principles/                     always-load behavioral rules
  skills/planning/                       pre-delivery planning procedure
  skills/agents/                         delegation contract
  skills/rules/                          universal §N.M rules
  skills/verification/                   cross-check procedure
  skills/mcp-integration/                MCP config reference
  skills/docs-sync/                      post-audit doc drift check
flutter/skills/flutter-standards/        10 standards + 8 commands
api/skills/api-standards/               2 standards + sync-migrate
web/skills/web-standards/               3 standards + 5 commands
docs/                                    contributing · changelog · skills · enforcement
scripts/export.sh                        export to Cursor / AGENTS.md
```

---

## Docs

| | |
|---|---|
| [docs/skills.md](docs/skills.md) | Skill catalog |
| [docs/enforcement.md](docs/enforcement.md) | Enforcement + delegation setup |
| [docs/contributing.md](docs/contributing.md) | Adding packs, skills, rules |
| [docs/changelog.md](docs/changelog.md) | Release history |
| [ROADMAP.md](ROADMAP.md) | What ships next |

---

**v0.12.0** · MIT · PRs welcome → [docs/contributing.md](docs/contributing.md)
