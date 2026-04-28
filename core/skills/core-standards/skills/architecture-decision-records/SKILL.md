---
name: architecture-decision-records
description: Detect architectural decisions in conversation and capture them as structured ADRs. Auto-triggers on trade-off comparisons, "we decided to" statements, and explicit "ADR this" requests.
origin: ECC
---

# Architecture Decision Records

## Trigger Signals

**Auto-capture (confirm before writing):**
- User picks between frameworks, databases, libraries, or patterns
- "We decided to…" / "The reason we're doing X instead of Y…"
- Trade-off analysis that reaches a conclusion

**Explicit capture:**
- "ADR this" / "record this decision" → write immediately after confirmation

**Read mode:**
- "Why did we choose X?" → scan `docs/adr/README.md` index, return Context + Decision sections

## ADR Format

```markdown
# ADR-NNNN: [Decision Title]

**Date**: YYYY-MM-DD
**Status**: proposed | accepted | deprecated | superseded by ADR-NNNN
**Deciders**: [names or roles]

## Context
[Constraint or force driving this decision — 2-4 sentences max]

## Decision
[The choice made, stated in present tense: "We use X"]

## Alternatives Considered

### [Alternative Name]
- **Pros**: …
- **Cons**: …
- **Rejected because**: …

## Consequences
**Gains**: …
**Trade-offs**: …
**Risks**: …
```

## Capture Workflow

1. Extract the core choice from conversation
2. Identify constraints that ruled out alternatives
3. Draft ADR — present to user before writing any file
4. On approval: scan `docs/adr/` for next number → write `docs/adr/NNNN-title.md` → append row to `docs/adr/README.md`
5. On rejection: discard, no files written

**First time only:** if `docs/adr/` doesn't exist, ask before creating it.

## Directory Structure

```
docs/adr/
  README.md          ← index table
  0001-use-nextjs.md
  0002-postgres.md
  template.md        ← blank for manual use
```

## Index Format (`README.md`)

```markdown
| ADR | Title | Status | Date |
|-----|-------|--------|------|
| [0001](0001-use-nextjs.md) | Use Next.js | accepted | 2026-01-15 |
```

## Rules

| Signal | Rule |
|--------|------|
| Decision magnitude | Record: frameworks, databases, patterns, auth strategy, infra. Skip: naming, formatting |
| Specificity | "Use Prisma ORM" not "use an ORM" |
| Rationale | Why matters more than what — never omit alternatives |
| Length | Context ≤ 8 lines. If longer, it's two decisions |
| Tense | Present: "We use X" not "We will use X" |
| Superseded | Always link replacement ADR — never delete |

## ADR Lifecycle

```
proposed → accepted → deprecated | superseded by ADR-NNNN
```

## Decision Categories

| Category | Examples |
|----------|---------|
| Technology | Framework, language, database, cloud |
| Architecture | Monolith vs microservices, event-driven, CQRS |
| API | REST vs GraphQL, versioning, auth mechanism |
| Data | Schema design, caching strategy |
| Infrastructure | CI/CD, deployment model, monitoring |
| Security | Auth strategy, secret management |
| Testing | Framework, coverage targets, E2E vs integration split |
