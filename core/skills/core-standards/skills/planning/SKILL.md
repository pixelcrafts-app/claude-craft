---
name: planning
description: Apply when starting any delivery task — feature, fix, migration, or refactor. Runs before any code is written.
---

# Planning

## The purpose of a plan

A plan is a working hypothesis — not a commitment. It updates as you learn. Confirming a plan is permission to start, not permission to ignore what you discover during implementation. When implementation reveals the plan was wrong, update the plan and surface the change before continuing.

## Before planning, understand

If the ask references code you haven't read, read the relevant files first. You cannot plan changes to code you don't understand. A plan written before reading the code is a guess with formatting.

## Starting from scratch (no files read yet)

When no files have been read — new session, new task, autonomous mode — run discovery before planning:

1. Identify the entry point for the task (the screen, route, service, or model the task touches)
2. Read that file and the files it directly imports
3. Identify the stack (Dart/Flutter, TypeScript/Next.js, TypeScript/NestJS, other) from file extensions and imports
4. Locate the relevant pattern the task fits (existing screen, existing endpoint, existing service) and read one working example of that pattern
5. Check for `.claude/craft.json` at the project root. If absent: detect stacks from file extensions and package manifests, generate a draft craft.json, and note it in the plan block. Do not block work if the user skips config setup.
6. Only after steps 1–5: proceed to the planning steps below

Without completing discovery, any plan produced is fabrication.

## Steps

1. **Restate the ask in one sentence.** If ambiguous — or if reading the code changes your understanding of what was asked — resolve the ambiguity before continuing. Do not proceed with a misunderstood task.

2. **Read the relevant files.** Only after reading: list what will change in each file and what contracts or exports those changes affect. Do not list files you have not read — mark unread files as TBD.

3. **Walk dependencies.** What imports the changed files? If a contract changes, what breaks? Use grep or search to find consumers — do not guess. Flag any high-blast-radius change (exported symbol removed or renamed, function signature changed, DTO field added/removed, route path or method changed).

4. **Name the unknowns.** List things you will only discover during implementation. Mark them TBD. These are the points where the plan is most likely to need revision — surface them before starting, not after the user reports a problem.

5. **List verification criteria.** What must be observable or tool-verifiable after the task is complete? Each criterion must be checkable with a specific tool call (Read, Bash, grep) — not prose like "the screen renders" or "it works."

6. **Identify parallel work.** If agents are appropriate, state which work is parallel-safe and which must be sequential. State the dependency explicitly.

7. **Present the plan and wait for confirmation.** This is the only question asked up front. After confirmation, begin — and update the plan as you learn.

## Plan Block (required for all non-trivial tasks)

After the user confirms the plan, emit a structured plan block at the end of your planning response. Verification reads this block in Phase 1 — not re-inferred prose.

```
<!-- craft:plan
deliverables:
  - id: D1
    description: "Short statement of what will exist when this is done"
    files:
      - path/to/file.ts
    verification: "grep -n 'LoadingState' path/to/file.ts"
  - id: D2
    description: "..."
    files:
      - path/to/other.ts
    verification: "Bash: flutter test test/screens/profile_test.dart | grep '0 failed'"
scope_boundary: "loading state only — auth layer not in scope for this task"
-->
```

Rules for the plan block:
- Every deliverable must have a `verification:` field containing a runnable tool command — Bash, grep, or Read with a specific pattern to match. If a verification command cannot be written, the deliverable is too vague — split or restate it first.
- `scope_boundary` must state what is explicitly NOT in scope. "Everything else" is not a boundary — name the specific areas excluded.
- The plan block is the contract Phase 1 uses. Do not restate it in prose after emitting it.

## Trivial-task bypass

Single-file change that touches no exported symbols and no contracts. Exempt from the plan block requirement. To qualify:
- Run grep for the changed symbol across the codebase — confirm zero consumers outside the file
- Run grep for the file path being imported anywhere — confirm zero imports

A declaration that a change is trivial is not sufficient. The grep results are the qualification. If either search returns hits, the change is not trivial and the full plan process applies.

Trivial tasks skip Phase 1 (no plan block to check). Phase 2 skill rules and Tier 1 ALWAYS-MANDATORY security rules still apply.

## During implementation

- When you discover something the plan didn't account for: state it, revise the plan block, and continue. Do not silently deviate from the plan or silently follow a wrong plan.
- When a step turns out to be harder or different than expected: say so before spending more time on it.
- When implementation is complete: run `core-standards:verification` before reporting done. Do not compress implementation and verification into one response — they are separate phases.
