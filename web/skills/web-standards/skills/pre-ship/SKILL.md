---
name: pre-ship
description: Full quality gate before merge — lint then all installed web standards
argument-hint: [optional-path]
---

Run the project lint command first (`npm run lint` / `pnpm lint`). Stop on any error — fix before proceeding.

```
verify-changes brief:
  scope: $ARGUMENTS or "uncommitted working tree"
  dimensions: [nextjs, production-readiness, craft-guide]
  depth: direct+consumers
  fix: no
  source: web-standards:pre-ship
```
