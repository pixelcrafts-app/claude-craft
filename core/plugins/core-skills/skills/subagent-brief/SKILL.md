---
name: subagent-brief
description: Apply whenever you are about to delegate work to a subagent via the Agent / Task tool. Claude Code's default stance is "don't spawn agents unless the user asks" — this skill does not change that stance, it governs the *how* once delegation is warranted. Enforces brief-writing discipline so the subagent starts warm instead of cold. A subagent that has to "figure out" the repo burns 3–10× the tokens of one given specific paths, line numbers, and known facts.
---

# Subagent Brief Discipline

A subagent is a fresh Claude instance with no memory of your conversation. It re-derives context you already have — that's the expensive path. This skill makes sure you brief it like a colleague who just walked in, not a detective solving a mystery.

**Scope boundary:** this skill does not tell you *whether* to spawn — your system prompt, user request, and any custom agent definitions already govern that. Claude Code's default is *do not spawn unless the user asks*. This skill governs *how* to brief well on the occasions delegation does happen.

## Why this matters

Without discipline, a subagent spawn can burn multiples of what the inline equivalent would cost — it re-reads files you already know about, re-runs searches you already ran, and returns a dump instead of the fact you needed. A tight brief often makes the spawn no more expensive than doing the work yourself, and sometimes cheaper if the task is genuinely wide. The difference is almost entirely in the prompt you hand it.

The rule: **never delegate understanding. Delegate lookups, searches, or narrow-scope execution.**

## Before you spawn — sanity check

You've already decided delegation is appropriate (user asked, or a skill like `verify-changes` is explicitly delegating a well-scoped batch). Run these final sanity checks before writing the prompt:

1. **Can I answer this inline with one Grep or Read?** → cancel the spawn, do it inline.
2. **Do I already know the file I need to touch?** → cancel; use Edit directly.
3. **Is the task still open-ended?** → rewrite the brief before spawning — an open-ended brief wastes the spawn.
4. **Will the result need to inform my next tool call immediately?** → round-trip overhead may exceed the saving; reconsider.

If you clear all four, write the brief using the template below. If you don't clear them, either rewrite the task into a shape that does, or don't delegate.

## The brief template

Every Agent prompt should contain all of:

```
GOAL
  <one sentence: what do I actually need back>

CONTEXT (what's already known — don't rediscover)
  - <file path:line>  — <what it contains / why relevant>
  - <fact>            — <source>
  - <ruled out>       — <don't investigate these paths>

SCOPE (hard walls)
  - Only these files / paths / patterns
  - Do NOT: <explicit out-of-scope items>

TASK
  <concrete verb-first instruction: "find X", "verify Y", "list Z">

OUTPUT SHAPE
  <what the return message should look like — under N words, bullet list, table, etc.>

BUDGET (optional, useful for Explore/general)
  <e.g. "3 Grep + 2 Read max" or "under 200 words response">
```

## Examples

### Bad (cold, vague, no scope)

> "Audit the codebase for design violations."

Result: subagent reads tens of unrelated files, returns a long narrative report, and costs several multiples of what one targeted Grep would have — because nothing in the brief tells it where to stop.

### Good (warm, scoped, shaped)

```
GOAL: Count design-system token drift in the shared/ folder only.

CONTEXT:
- Tokens live in lib/shared/design_tokens.dart (AppColors, AppSpacing classes)
- Drift patterns: Color(0xFF...), EdgeInsets.all(<number>), TextStyle() inline

SCOPE: lib/shared/ only. Skip lib/features/.

TASK: grep for each drift pattern, count by file, top 10.

OUTPUT SHAPE: Table — file | pattern | count. Under 30 lines.

BUDGET: 4 Grep calls max, no Read.
```

Result: a predictable, deterministic, reusable response — the subagent runs the grep pattern you specified and returns the shape you asked for.

## Specific anti-patterns

### 1. "Based on your findings, fix it"
Pushes understanding onto the subagent. The subagent doesn't know your context; it guesses. Instead: subagent returns findings → you decide → you (or a second, narrowly-briefed subagent) fixes.

### 2. "Check if everything is fine"
No goal, no scope, no output shape. The subagent will invent all three. Define before spawning.

### 3. "Figure out how this works"
The subagent will read 30 files. Instead: "Read these 3 specific files and summarize the data flow between them in under 100 words."

### 4. Spawning for a task you could do in 2 Grep calls
Round-trip overhead + cold start + return message cost > doing it inline.

### 5. Parallel subagents with overlapping scope
Two subagents both asked to "audit frontend components" will duplicate 80% of their work. Either partition scope explicitly or spawn one.

### 6. Spawning and then re-verifying the result manually
If you'll read the same files again anyway, you didn't delegate — you doubled the cost.

## Specific patterns that win

### Parallel lookups with hard boundaries
```
Agent 1: "Find all usages of `@riverpod` annotation in lib/features/auth/"
Agent 2: "Find all usages of `@riverpod` annotation in lib/features/feed/"
```
Parallel, disjoint scope, same output shape. Clean win.

### Audit-by-dimension (not audit-everything)
Instead of one agent auditing all 17 craft-guide sections, spawn 3 agents:
- Agent 1: color + typography rules
- Agent 2: motion + state rules
- Agent 3: a11y + theme rules

Each gets a narrower brief, fewer rules to hold in attention, cleaner output.

### Pre-warmed with exact file set
```
"Read these 4 files in order: [list]. Return a diff between file 1's API and file 2's consumer. Under 200 words."
```
The subagent never has to search. Cold-start tax drops to near-zero.

## When a subagent returns

- If the return message is longer than 500 words and you only needed 3 facts — your brief was under-shaped. Fix next time.
- If the subagent asks you clarifying questions — your brief was underspecified. Don't re-spawn; answer inline.
- If the subagent says "I also did X beyond your scope" — push back: that's scope creep + token waste.

## Budget reality

Rough relative cost by task type — anchored to what doing the same task inline would cost, not absolute tokens:

| Task | Spawn cost vs. doing it inline |
|---|---|
| Narrow lookup (find X) | Similar to inline; savings mostly in avoiding context pollution in the main thread |
| Scoped audit (one dimension, one folder) | Often cheaper than inline if the audit would force many Reads into the main context |
| Cross-cutting research | Nearly always cheaper than inline — this is the spawn's best case |
| "Explain this module" | Comparable; go inline unless the explanation would itself be long |
| Open-ended ("figure it out") | Always worse — rewrite the brief before spawning |

If a spawn reliably spends more than the inline equivalent would, the brief is wrong, not the tool.

## Final rule

Before calling Agent, write the prompt. Then read it. If you couldn't succeed at the task with only the information in that prompt — neither can the subagent. Add what's missing before spawning, not after.
