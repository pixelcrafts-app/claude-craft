---
name: context-budget
description: Audit token consumption across agents, skills, MCP servers, and CLAUDE.md. Identifies bloat and ranks optimizations by token savings. Backs the /context-budget command.
origin: ECC
---

# Context Budget

## Triggers

- Session output quality degrading or responses slowing
- After adding agents, skills, or MCP servers
- Before adding more components — check headroom first
- `/context-budget` or `/context-budget --verbose`

## Phase 1: Inventory

**Token estimation:** prose → `words × 1.3`, code → `chars / 4`

| Component | What to scan | Flag threshold |
|-----------|-------------|---------------|
| Agents | `agents/*.md` — lines + description frontmatter | >200 lines or description >30 words |
| Skills | `skills/*/SKILL.md` | >400 lines |
| Rules | `rules/**/*.md` | >100 lines, content overlap with other rules |
| MCP tools | `.mcp.json` — count tools × ~500 tokens each | >10 servers, any server wrapping `gh`/`git`/`npm` CLI |
| CLAUDE.md | Full chain (project + user-level) | combined >300 lines |

## Phase 2: Classify

| Bucket | Criteria | Action |
|--------|----------|--------|
| Always needed | Referenced in CLAUDE.md, backs an active command, or matches project stack | Keep |
| Sometimes needed | Domain-specific, not referenced in CLAUDE.md | On-demand activation |
| Rarely needed | No command reference, duplicate content, no project match | Remove or lazy-load |

## Phase 3: Detect Issues

- **Bloated agent descriptions** — >30 words loads into every Task tool invocation even when agent is never called
- **Heavy agents** — >200 lines inflate Task tool context on every spawn
- **Redundant components** — skill duplicates agent logic; rule duplicates CLAUDE.md
- **MCP over-subscription** — server wraps a CLI tool that can run free with Bash
- **CLAUDE.md bloat** — verbose explanations, outdated sections, instructions that belong in rules

## Phase 4: Report

```
Context Budget Report
═══════════════════════════════════════

Total estimated overhead: ~XX,XXX tokens
Context window: 200K  |  Available: ~XXX,XXX tokens (XX%)

Component Breakdown:
┌─────────────────┬────────┬───────────┐
│ Component       │ Count  │ Tokens    │
├─────────────────┼────────┼───────────┤
│ Agents          │ N      │ ~X,XXX    │
│ Skills          │ N      │ ~X,XXX    │
│ Rules           │ N      │ ~X,XXX    │
│ MCP tools       │ N      │ ~XX,XXX   │
│ CLAUDE.md       │ N      │ ~X,XXX    │
└─────────────────┴────────┴───────────┘

Issues Found (N) — ranked by savings:
1. [action] → save ~X,XXX tokens
2. [action] → save ~X,XXX tokens
3. [action] → save ~X,XXX tokens

Potential savings: ~XX,XXX tokens (XX% overhead reduction)
```

`--verbose`: adds per-file token counts, heaviest file line breakdown, side-by-side duplicated lines, MCP per-tool schema sizes.

## Key Leverage Points

- **MCP is the biggest lever** — one 30-tool server costs more tokens than all your skills combined
- **Agent descriptions load always** — description field is present in every Task call, even if agent is never invoked
- **Audit after every addition** — token creep is invisible until quality degrades

## Example

```
/context-budget
→ 16 agents (12,400), 28 skills (6,200), 87 MCP tools (43,500), 2 CLAUDE.md (1,200)
  Flag: 3 CLI-replaceable MCP servers
  Top save: remove those 3 servers → -27,500 tokens (47% overhead reduction)
```
