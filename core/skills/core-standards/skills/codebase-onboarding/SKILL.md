---
name: codebase-onboarding
description: Analyze an unfamiliar codebase and produce an architecture map, key entry points, conventions, and a starter CLAUDE.md. Triggers on "onboard me", "walk me through this repo", or "generate a CLAUDE.md".
origin: ECC
---

# Codebase Onboarding

## Triggers

- "Onboard me" / "walk me through this repo" → full 4-phase + CLAUDE.md
- "Generate a CLAUDE.md" → phases 1–3, CLAUDE.md only
- "Update the CLAUDE.md with current conventions" → read existing first, merge new findings

## Phase 1: Reconnaissance (parallel)

```
Package manifests   → package.json, go.mod, Cargo.toml, pyproject.toml, pubspec.yaml
Framework signals   → next.config.*, vite.config.*, angular.json, fastapi, rails config
Entry points        → main.*, index.*, app.*, server.*, cmd/
Directory snapshot  → top 2 levels (skip node_modules, .git, dist, .next, __pycache__)
Tooling             → .eslintrc*, tsconfig.json, Dockerfile, .github/workflows/, .env.example
Tests               → tests/, __tests__/, *.spec.ts, *_test.go, jest.config.*, vitest.config.*
```

## Phase 2: Architecture Mapping

Identify from reconnaissance data:
- **Stack**: language + version, framework, database + ORM, bundler, CI/CD
- **Pattern**: monolith | monorepo | microservices | serverless; frontend/backend split; REST | GraphQL | gRPC
- **Directory map**: top-level dir → purpose (only non-obvious directories)
- **Request trace**: entry point → validation → business logic → persistence → response

## Phase 3: Convention Detection

- **File naming**: kebab-case | camelCase | PascalCase | snake_case
- **Error handling**: try/catch | Result types | error codes
- **Async pattern**: callbacks | promises | async/await | channels
- **Git**: branch naming from `git branch -r`, commit style from `git log --oneline -10`, PR workflow
- If git history is shallow or absent: skip git section, note it

## Phase 4: Output

### Onboarding Guide

```markdown
# Onboarding: [Project Name]

## Stack
| Layer | Technology | Version |
|-------|-----------|---------|

## Architecture
[mermaid diagram or 3-line description]

## Entry Points
- [path] — [what happens here]

## Directory Map
[dir → purpose, non-obvious only]

## Request Lifecycle
[entry → validation → logic → db → response, 1 sentence per step]

## Conventions
- File naming: …
- Error handling: …
- Test pattern: …
- Commit style: …

## Common Commands
- Dev: `…`  Tests: `…`  Lint: `…`  Build: `…`

## Where to Look
| Task | Location |
|------|----------|
```

### CLAUDE.md (starter or update)

If `CLAUDE.md` exists: read it first, enhance only — preserve existing instructions, mark additions clearly.

```markdown
# Project Instructions

## Stack
[detected summary]

## Commands
- Dev: `…`  Build: `…`  Lint: `…`  Test: `…`

## Code Style
- [naming convention]
- [error handling pattern]

## Project Structure
[key dir → purpose]

## Conventions
- [commit style]
- [test file pattern]
```

## Rules

- Use Glob and Grep for reconnaissance — Read selectively only on ambiguous signals
- Trust code over config when they conflict
- CLAUDE.md: max 100 lines, no listing every dependency, no describing obvious dirs like `src/`
- Unknown convention: state "Could not detect" — never guess
