---
name: subagent-brief
description: Read this BEFORE calling the Task or Agent tool. Governs three decisions — should I spawn at all, how many agents, what goes in the prompt. Defines the warm-brief format and warmth scoring that determines whether a spawn is allowed.
---

# Subagent Brief Discipline

## RULE

Every Task/Agent prompt must contain labeled sections covering GOAL, CONTEXT, SCOPE, and OUTPUT. Prompts missing these must not be spawned.

---

## GUIDE — advisory judgment calls

Everything below is judgment. Claude decides.

---

## Decision 1 — Spawn or inline?

Before writing a prompt, answer these. The first **yes** kills the spawn.

| Question | If yes → | Why |
|---|---|---|
| Can this be answered with at most a couple of inline searches or reads? | Inline | Round-trip and cold-start costs exceed the direct calls |
| Is the target file already known? | Inline | Edit directly; spawning to "find it" when you already know is waste |
| Will the result inform the very next tool call? | Inline | Round-trip latency exceeds the saving |
| Is the task open-ended or exploratory with no shape? | **Reshape first** | Open-ended briefs waste the spawn |
| Will the parent re-read the same files to verify the subagent's output? | Inline | That's not delegation; that's paying twice |

### Positive signals — when spawning is the right call

- The work spans many files across a subsystem not yet in the parent's context.
- The work is a **scoped audit** on one dimension of one folder, and would otherwise pollute the main thread with many Reads.
- The work is **genuinely cross-cutting research** where the answer is a summary, not an edit.
- The work can be **stated as a specific question** with a bounded output shape.

If none apply, go inline.

### The hardest rule

**Never delegate understanding.** A subagent without understanding will invent it and return prose that sounds correct. Delegate *lookups*, *scoped audits*, and *narrow-scope execution*. Understanding stays with the parent.

---

## Decision 2 — How many agents?

### The default is one

Fan out only when all three hold:

1. **Independent work** — one agent's findings do not alter another's scope.
2. **Disjoint scope** — no two agents search the same files or patterns. Overlap pays twice.
3. **Uniform output shape** — results combine without a reconciliation step.

Any failure of the three: one agent, or go inline.

### Count guidance

| Work shape | Agents |
|---|---|
| Find one fact | 1 (usually inline) |
| Scoped audit on one dimension of one folder | 1 |
| Audit across many dimensions | N, where each agent owns a disjoint partition of dimensions |
| Identical lookup across N disjoint folders | N (diminishing returns above ~4) |
| Research across a dependency graph where each finding narrows the next question | 1 (serial) |
| "Verify everything is fine" | 0 — not delegable; reshape into specifics or abandon |

Beyond ~4 parallel agents, the coordination tax (merging heterogeneous outputs) usually outweighs the parallelism gain.

### Serial, not parallel — common miss

Work is serial whenever a later agent's scope depends on an earlier agent's output. Mapping then auditing, discovering then verifying, surveying then deep-diving — these are sequences, not fan-outs. Running them in parallel just means both agents guess.

---

## Decision 3 — What goes in the prompt?

A prompt is warm when a fresh instance could answer it using only what is in the prompt. The warmth scoring below defines what counts.

### Warmth signals

| Signal | Value | Form |
|---|---|---|
| Labeled section | 1 each | A marker keyword as a section label, with or without trailing colon; heading, bold, or plain form all accepted. Keywords: `GOAL`, `CONTEXT`, `SCOPE`, `TASK`, `OUTPUT`, `DELIVERABLE`, `BUDGET`. |
| Code fence | 1 | Any triple-backtick block. Presence of pasted content is the strongest warmth signal. |
| File path reference | 1 each (cap 2) | Any `dir/file.ext` pattern with optional `:line`. Language-agnostic. Must contain `/` so bare dotted names do not count. |

### The scope-scaled bar

| Prompt length | Required score | Meaning |
|---|---|---|
| `<400` | 0 | Trivial lookup — no ceremony |
| `400–1500` | 2 | Medium spawn — any mix of labels and pasted context |
| `≥1500` | 3 | Heavy spawn — full warm brief expected |

These signals are proxies for a real test: could a fresh instance answer from the prompt alone? If not, neither can the subagent.

### The brief template

```
GOAL
  <one sentence: the specific answer required>

CONTEXT (what the parent already has — do not rediscover)
  - <path/file:line> — <pasted excerpt or one-line summary>
  - <fact> — <source>
  - <exclusions> — <paths the subagent must not investigate>

SCOPE
  - In:  <paths or patterns>
  - Out: <explicit exclusions>

TASK
  <verb-first instruction>

OUTPUT
  <return shape — table, bullet list, word budget, line-ref list, etc.>

BUDGET  (optional — set when capping spend matters)
  <e.g. tool-call cap>
```

### The highest-leverage habit

Paste the excerpt the parent already has into the prompt, rather than naming the file. Naming the file makes the subagent re-read what the parent already loaded — the exact failure this skill exists to prevent. Pasting transfers the cost from the subagent to a handful of tokens in the prompt.

---

## Anti-patterns

1. **Delegating understanding.** Spawn for findings; decide inline; edit (or spawn narrowly) for the fix.
2. **Unbounded brief.** A prompt with no goal, no scope, and no output shape causes the subagent to invent all three.
3. **Exploration without reshaping.** Replace open-ended exploration prompts with a specific enumerated read set and a shaped summary output.
4. **Spawn for trivial work.** Round-trip plus cold start costs more than a direct inline call.
5. **Overlapping parallel agents.** Agents with intersecting scope duplicate their work.
6. **Spawn then re-verify manually.** Re-reading the same files the subagent read is paying twice, not delegating.
7. **Name-drop brief.** Referring to a file by path instead of pasting the relevant excerpt forces the subagent to re-read context the parent already has.

---

## When a subagent returns

- Response much longer than needed → output shape was underspecified; tighten it next time.
- Subagent asks clarifying questions → brief was underspecified; answer inline, do not respawn.
- Subagent reports work beyond the brief → scope creep; push back.

---

## Budget reality

Cost anchored to the inline equivalent, not absolute tokens:

| Task | Spawn vs inline |
|---|---|
| Narrow lookup | Roughly equal; savings are in avoiding main-thread context pollution |
| Scoped single-dimension audit | Often cheaper when inline would force many Reads into the main thread |
| Cross-cutting research | Nearly always cheaper — the spawn's best case |
| Explain-this-module | Comparable; go inline unless the explanation itself would be long |
| Open-ended | Always worse — reshape or do not spawn |

A spawn that spends more than the inline equivalent indicates a bad brief, not a bad tool.

---

## Final rule

Before calling Task or Agent: write the prompt, then read it. If the task cannot be completed using only what is in that prompt, neither can the subagent. Add what is missing before spawning — not after.
