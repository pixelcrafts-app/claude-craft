# claude-craft

Standards your Claude Code follows — automatically. Install a pack, Claude applies the rules on every file, plans before coding, verifies its own output, and guards against mistakes. No `CLAUDE.md` edits.

![version](https://img.shields.io/badge/version-0.16.0-blue) ![license](https://img.shields.io/badge/license-MIT-green) ![plugins](https://img.shields.io/badge/plugins-7-orange)

---

## Architecture

Three layers. Clean separation. Engine owns orchestration only — all knowledge lives in skills.

```
USER ASK
    │
    ▼
┌──────────────────────────────────────────────────────────────┐
│  CORE-HOOKS  (bash — fires at every relevant event)          │
│                                                              │
│  SessionStart      rules-discipline · enforcement-preamble   │
│  UserPromptSubmit  parallel-hint                             │
│                    (nudges toward agent fan-out on broad     │
│                     multi-file / multi-domain wording)       │
│  PreToolUse        protect-files · protect-bash ·            │
│                    enforce-rules · plan-required ·           │
│                    agent-traffic (pre on Agent|Task)         │
│                    (plan-required: blocks Nth file edit      │
│                     until craft:plan block exists — opt-in)  │
│  PostToolUse       post-test (auto-runs fast tests) ·        │
│                    agent-traffic (post on Agent|Task)        │
│  Stop              stop-gate · cite-or-read ·                │
│                    post-edit-verify                          │
│                    (cite-or-read: WARN default, BLOCK opt-in │
│                     post-edit-verify: nudge or block strict) │
│                                                              │
│  All bash hooks fail-open. 96 hook tests in __tests__/.      │
│  Configurable via .claude/enforcement.json (opt-in).         │
└─────────────────────────┬────────────────────────────────────┘
                          │
                          ▼
┌──────────────────────────────────────────────────────────────┐
│  CORE-STANDARDS  (pure instructions — no bash)               │
│                                                              │
│  ENGINE SKILL                                                │
│  verify-changes: plan → delegate → cross-check               │
│                  → fix (3-retry cap) → report                │
│                                                              │
│  UNIVERSAL SKILLS (auto-load by task type)                   │
│  work-principles · planning · universal-rules                │
│  verification · auth-flows · craft-config                    │
│  subagent-brief · mcp-integration · docs-sync                │
│  codebase-index (audit cache — git blob hash keys)           │
│  honesty (no unsourced claims, evidence before done)         │
│  state-files (glossary of .claude/* state file ownership)    │
│                                                              │
│  AUTONOMOUS PIPELINE (production — single prompt)            │
│  spec-validator · contracts · challenger                     │
│  contract-tests · integration · full-setup                   │
│  Commands: /full-setup · /spec                               │
└───────────┬──────────────────────┬───────────────────────────┘
            │                      │
            ▼                      ▼
┌───────────────────┐  ┌───────────────────────────────────────┐
│  STACK PACKS      │  │  PROJECT CONFIG                       │
│  api              │  │  .claude/craft.json                   │
│  web              │  │    stacks · features · disabled_rules │
│  mobile           │  │    features.aesthetic.<name>.{         │
│  flutter          │  │      enforced_guides[],               │
│  design           │  │      enforced_signals[],              │
│  (3-tier design:  │  │      bans[]                           │
│   invariants /    │  │    }  (Tier 3 taste opt-in)           │
│   contract /      │  │                                       │
│   taste)          │  │  .claude/enforcement.json             │
└───────────────────┘  │    mandatory · gate_required          │
                       │    plan_required · plan_threshold     │
                       │    honesty_blocking                   │
                       │    verify_required · verify_threshold │
                       │    agent_traffic_log · parallel_hint  │
                       │    (hook enforcement — pre/post tool) │
                       └───────────────────────────────────────┘
            │
            ▼
    OUTPUT: verdict + evidence per rule + suggested fixes
            + .claude/agent-traffic.log + .claude/verify-state.json
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

### Automatic — zero user action (always-on observability + safety)

| Hook / Skill | Fires on | Behavior |
|---|---|---|
| `protect-files` | Every file edit | Blocks `.env`, credentials, lockfiles (configurable) |
| `protect-bash` | Every shell command | Blocks `rm -rf`, force push, destructive ops (configurable) |
| `enforce-rules` | Every file edit | Runs pack rule registry (opt-in per project) |
| `post-test` | Every Write/Edit/MultiEdit | Detects stack, runs related fast tests; exit 2 on failure forces fix |
| `agent-traffic` | Every Agent/Task spawn + return | Logs SPAWN/RETURN to `.claude/agent-traffic.log` + live stderr summary so inter-agent comms are observable |
| `cite-or-read` | Every turn end (Stop) | Scans the final assistant message for file references; unsourced claims about files not Read/Grep'd this turn → non-blocking WARN (opt-in BLOCK via `honesty_blocking: true`) |
| `honesty` (skill) | Every response | Forbids unsourced claims about code, requires "I don't know — checking" when no source was read, requires evidence before "done" |
| `stop-gate` | Every turn end | Blocks until mandatory pack gate passes (opt-in) |
| Stack skills | Relevant file edits | Flutter/web/api rules loaded automatically by file type |
| `work-principles` | Every non-trivial task | Detect→Check→Suggest, non-destructive reasoning |
| `planning` | Every delivery task | Dependencies, edge cases, verification steps before starting |
| `subagent-brief` | Every Task/Agent spawn | Warm brief contract (GOAL/CONTEXT/SCOPE/OUTPUT), trust-state-files-not-prose |

### Opt-in gates (set in `.claude/enforcement.json`)

These are off by default. Turn them on to upgrade nudges to deterministic blocks.

| Setting | Hook | Behavior when enabled |
|---|---|---|
| `parallel_hint: true` (default) | `parallel-hint` (UserPromptSubmit) | Injects a planning:Step 0 + `/parallelize` reminder when task wording is multi-file/multi-domain. Opt-out only — defaults to enabled. |
| `plan_required: true` | `plan-required` (PreToolUse) | Blocks the Nth unique non-trivial file edit per session (default N=3) until a `<!-- craft:plan` block exists in the conversation |
| `plan_required: "strict"` | `plan-required` (PreToolUse) | Same + validates plan SHAPE — plans with 3+ deliverables must include a `Routing:` decision (inline vs parallel agents). Plans missing routing continue to block until fixed. |
| `honesty_blocking: true` | `cite-or-read` (Stop) | Unsourced claims about files block turn-end (exit 2) instead of WARN. Claude must Read the file or remove the claim. |
| `verify_required: true` | `post-edit-verify` (Stop) | Nudge — if N+ non-trivial files edited this turn without a verification pass, emit reminder to run `/verify-changes`. |
| `verify_required: "strict"` | `post-edit-verify` (Stop) | Block — same condition exits 2; turn can't Stop until verification artifacts appear in transcript. |
| `agent_traffic_log: false` | `agent-traffic` (Pre/Post Agent) | Silences the log + stderr summary. Default is on. |

### On demand — user invokes

| Trigger | What fires | Result |
|---|---|---|
| `"verify my changes"` | `verify-changes` | Audit with dependency graph, PASS/FAIL per rule with evidence. Now honors `verdict_mode: INFO_ONLY` skill frontmatter + `craft.json features.aesthetic` opt-in promotions. |
| `/parallelize <task>` | `core-standards:commands/parallelize` | Partition + warm-brief + batched-spawn protocol — one keystroke fan-out for broad multi-file / multi-domain tasks. Refuses non-parallelizable tasks per planning:Step 0. |
| `/full-setup` | `core-standards:full-setup` | Detects stack, generates project layer (CLAUDE.md, `.claude/rules/`, agent files), wires `craft.json` + `enforcement.json` + hooks. One-shot setup for any project — new or existing. |
| `/spec` | `core-standards:spec-validator` | Validates and locks spec; emits `acceptance-tests.md` as the objective definition of done before any implementation begins. |
| `/flutter-standards:app-audit` | app-audit → `verify-changes` | Full Flutter audit: pre-ship + craft + screen states |
| `/web-standards:pre-ship` | thin wrapper → `verify-changes` | Pre-commit web audit |
| `/web-standards:premium-check` | thin wrapper → `verify-changes` | UI craft quality check |
| `/web-standards:theme-audit` | thin wrapper → `verify-changes` | Theme consistency check |

---

## Packs

| Pack | Stack | Skills |
|---|---|---|
| `core-hooks` | All | 13 bash hooks across SessionStart / UserPromptSubmit / PreToolUse / PostToolUse / Stop. 96 unit tests in `__tests__/`. All fail-open. |
| `core-standards` | All | Engine + universal skills (work-principles, planning, verification, verify-changes, subagent-brief, honesty, codebase-index, state-files, craft-config) + autonomous pipeline (spec-validator, contracts, challenger, contract-tests, integration, full-setup) |
| `design-standards` | Web + iOS + Android | 6 platform-agnostic design skills — `design-laws` split into RULES (universals) + GUIDES (taste, INFO-only) |
| `web-standards` | Cross-framework (Next.js, Remix, SvelteKit, Astro, Nuxt) | 12 skills — `craft-invariants` (Tier 1 cited universals), `craft-guide` (Tier 2 project contract), `premium-signals` (Tier 3 reference catalog, INFO-only), audit + performance + i18n + taste |
| `api-standards` | NestJS / Prisma | 6 skills — api-design, nestjs, db-migrations, websockets |
| `mobile-standards` | Flutter / RN / SwiftUI / Compose | 7 cross-framework mobile skills — `craft-invariants` (Tier 1 HIG + Material + WCAG), `craft-guide` (Tier 2), `design-tokens` (cross-framework adapter patterns), `premium-signals` (Tier 3 reference) |
| `flutter-standards` | Flutter / Dart | 5 Flutter-specific skills — engineering, audit, scaffold, scan |

### The three-tier design architecture

Design / craft skills follow Tier 1 / Tier 2 / Tier 3 verdict semantics, consumed by `verify-changes` Phase 4:

| Tier | Where | What it enforces | Verdict |
|---|---|---|---|
| **1 — Invariants** | `*/craft-invariants` | Industry standards — WCAG, Apple HIG, Material Design, CSS specs, Bringhurst typography, frame budget. Universal across every project. | PASS / FAIL / N_A |
| **2 — Contract** | `*/craft-guide` | The project's design system — declared base unit, scales, tokens. Enforces *declaration + adherence*; specific values are the project's call. | PASS / FAIL / N_A |
| **3 — Taste** | `*/premium-signals` + `design-laws` GUIDES + aesthetic recipes | Aesthetic specifics (Linear / Vercel / soft-clay / Material You values). | INFO unless promoted via `craft.json features.aesthetic.<name>.enforced_signals[]` / `enforced_guides[]` / `bans[]` |

A project on Material Design 3 no longer gets false FAILs from Linear-flavored premium-signals values. A project committed to a specific aesthetic promotes those values back to enforced. Default install: no taste rules block.

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
  "allowed_commands": ["rm -rf dist/"],

  "plan_required": "strict",
  "plan_threshold": 3,

  "honesty_blocking": true,

  "verify_required": "strict",
  "verify_threshold": 3,

  "agent_traffic_log": true,
  "parallel_hint": true
}
```

| Block | Effect when present |
|---|---|
| `mandatory` + `gate_required` | Stop hook blocks turn-end until each mandatory pack's gate command (`/web-standards:pre-ship` etc.) reports SAFE TO COMMIT |
| `allowed_files` / `allowed_commands` | Exempts paths / shell prefixes from `protect-files` / `protect-bash` blocks |
| `plan_required: true` | The 3rd unique non-trivial file edit per session blocks until a `<!-- craft:plan` block exists in the transcript |
| `plan_required: "strict"` | Same, plus plans with 3+ deliverables must include a `Routing:` decision (inline vs parallel agents) |
| `honesty_blocking: true` | `cite-or-read` blocks turn-end on unsourced file claims instead of WARN |
| `verify_required: true` | `post-edit-verify` warns on multi-file edits without verification |
| `verify_required: "strict"` | Same, but blocks turn-end (exit 2) until verify-changes runs |

**Aesthetic enforcement** (Tier 3 opt-in) — commit to `.claude/craft.json`:

```json
{
  "features": {
    "aesthetic": {
      "active": "soft-clay",
      "definitions": {
        "soft-clay": {
          "enforced_guides": ["design-laws:G3", "design-laws:G6.modal-as-first-thought"],
          "enforced_signals": ["mobile/premium-signals:soft-clay-radius"],
          "bans": ["gradient-text", "neon-accents"]
        }
      }
    }
  }
}
```

Promotes specific Tier 3 entries to enforced rules for *this* project. The default skill behavior (every Tier 3 rule INFO-only) is preserved for projects that don't declare an active aesthetic.

---

## Layout

```
.claude-plugin/marketplace.json

core/skills/
  core-hooks/                    bash enforcement hooks (13 hooks, 96 tests)
    hooks/                       protect-files · protect-bash · enforce-rules · stop-gate
                                 session-ledger · post-test · cite-or-read (BLOCK opt-in)
                                 plan-required · post-edit-verify · agent-traffic
                                 parallel-hint · rules-discipline · enforcement-preamble
    hooks/__tests__/             one .test.sh per testable hook — 96 tests total
    enforcement/                 per-pack rule registries (JSON)
  core-standards/                engine + universal skills + autonomous pipeline
    commands/                    /full-setup · /spec · /parallelize slash commands
    skills/verify-changes/       audit + delivery engine (consumes verdict_mode + features.aesthetic)
    skills/work-principles/      always-load behavioral rules
    skills/planning/             pre-delivery planning procedure (Step 0 routing matrix)
    skills/universal-rules/      universal rules (security/testing/observability/engineering)
    skills/verification/         cross-check procedure
    skills/subagent-brief/       delegation contract (trust-state-files-not-prose)
    skills/mcp-integration/      MCP config reference
    skills/docs-sync/            post-audit doc drift check
    skills/codebase-index/       persistent audit cache keyed by git blob hash
    skills/state-files/          glossary of .claude/* state file ownership + lifecycle
    skills/craft-config/         .claude/craft.json schema (stacks/features/aesthetic)
    skills/honesty/              no unsourced claims; evidence before declaring done
    skills/spec-validator/       challenges spec for gaps; locks acceptance-tests.md
    skills/contracts/            architect-defined contracts; locked before implementation
    skills/challenger/           adversarial review with fresh context (3-round cap)
    skills/contract-tests/       tests generated from contracts; implementer cannot modify
    skills/integration/          wires implementations; runs acceptance tests; 5-attempt fix loop
    skills/full-setup/           project-layer generator: CLAUDE.md, .claude/rules/, agent files

design/skills/design-standards/  platform-agnostic design (Web + iOS + Android)
    skills/accessibility/        WCAG 2.2 + Swift traits + Compose semantics
    skills/design-laws/          RULES (6 universals) + GUIDES (9 taste items, INFO-only)
    skills/brand-research/       fact verification + asset collection protocol
    skills/creative-direction/   memorable vs functional UI signals
    skills/aesthetic-coherence/  mixed design language detection
    skills/information-architecture/

web/skills/web-standards/        cross-framework web (Next.js / Remix / SvelteKit / Astro / Nuxt)
    skills/craft-invariants/     Tier 1 — 15 industry-cited universals (WCAG, CSS, Bringhurst)
    skills/craft-guide/          Tier 2 — project contract (declared base unit, scales, tokens)
    skills/premium-signals/      Tier 3 — reference catalog (Linear/Vercel/Arc, INFO_ONLY)
    skills/taste/                metric dials (variance, motion, density)
    skills/nextjs/ · performance/ · i18n/ · extract-tokens/
    skills/pre-ship/ · premium-check/ · theme-audit/

api/skills/api-standards/        NestJS / Prisma
    skills/api-design/           REST resource naming, status codes, pagination
    skills/nestjs/               NestJS patterns and enforcement
    skills/db-migrations/        Prisma schema → migration → client regeneration
    skills/code-quality/ · websockets/ · cross-stack-contracts/

mobile/skills/
  mobile-standards/              cross-framework mobile (Flutter / RN / SwiftUI / Compose)
    skills/craft-invariants/     Tier 1 — 15 universals (Apple HIG + Material + WCAG + 60fps)
    skills/craft-guide/          Tier 2 — project contract
    skills/design-tokens/        token completeness + per-framework adapter patterns
    skills/premium-signals/      Tier 3 — reference catalog (iOS 26, Material You, INFO_ONLY)
    skills/production-readiness/ · forms/ · observability/
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

**v0.16.0** · MIT · PRs welcome → [docs/contributing.md](docs/contributing.md)
