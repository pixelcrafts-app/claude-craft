---
name: premium-check
description: Craft audit for a component or page — walks all craft-guide §1–§15 rules with optional fix
disable-model-invocation: true
argument-hint: [component-file-path] [--fix]
---

Resolve aesthetic and density from `tailwind.config.*`, `app/globals.css`, or ask the user — do not guess.

```
verify-changes brief:
  scope: $ARGUMENTS or "uncommitted working tree"
  dimensions: [craft-guide §1–§15]
  depth: direct
  fix: yes if --fix, else no
  source: web-standards:premium-check
  context:
    aesthetic: <detected or user-supplied>
    density: <detected or user-supplied>
```
