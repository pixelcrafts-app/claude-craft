---
name: strategic-compact
description: Self-monitoring skill that suggests /compact at logical phase transitions. Prevents mid-task context loss from arbitrary auto-compaction.
origin: ECC
---

# Strategic Compact

Auto-compaction fires at arbitrary points — often mid-task — discarding critical context. This skill monitors session depth and suggests `/compact` only at logical boundaries.

## Triggers

- Long sessions approaching context limits (200K+ tokens)
- Multi-phase work (research → plan → implement → test)
- Switching to an unrelated task
- After completing a major milestone
- Responses degrading in coherence (context pressure signal)

## Self-Monitoring Rules

After ~50 tool calls: suggest `/compact` at the next logical phase break.
Every ~25 calls after that: re-suggest if not yet compacted.
Never suggest mid-implementation — context loss mid-task is worse than context pressure.

## Compaction Decision Table

| Phase Transition | Compact? | Reason |
|-----------------|----------|--------|
| Research → Planning | Yes | Research context is bulky; plan is the distilled output |
| Planning → Implementation | Yes | Plan is in tasks or a file; free the context for code |
| Implementation → Testing | Maybe | Keep if tests reference recent code; compact if switching focus |
| Debugging → Next feature | Yes | Debug traces pollute context for unrelated work |
| Mid-implementation | No | Losing file paths, variable names, and partial state is costly |
| After a failed approach | Yes | Clear dead-end reasoning before a new direction |

## What Survives Compaction

| Persists | Lost |
|----------|------|
| CLAUDE.md instructions | Intermediate reasoning and analysis |
| Task list | File contents you previously read |
| Memory files (`~/.claude/memory/`) | Multi-step conversation context |
| Git state (commits, branches) | Tool call history |
| Files on disk | Verbal preferences not saved to memory |

## Compact with Intent

```
/compact Focus on implementing auth middleware next
/compact Research phase complete — implementing the plan from tasks
```

Always write critical context to files or memory **before** compacting.

## Context Composition Signals

| Source | Cost | Action if bloated |
|--------|------|------------------|
| CLAUDE.md chain | Always loaded | Keep lean — move details to rules |
| Loaded skills | 1–5K tokens each | On-demand load only needed skills |
| Conversation history | Grows every turn | Compact at phase boundaries |
| Tool results (file reads, searches) | High bulk | Compact after extraction phase |
| Duplicate instructions | Wasted overhead | Same rule in CLAUDE.md + rules = redundant |

## Related

- `context-budget` — audit exact token overhead per component before and after compaction
- `~/.claude/memory/` — persist decisions and preferences that must survive compaction
