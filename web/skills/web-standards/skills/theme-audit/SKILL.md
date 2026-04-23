---
name: theme-audit
description: Verify theme completeness — every themeable value uses tokens, light and dark independently designed, no hardcoded bleed-through, SSR hydration flash prevented
argument-hint: [optional: scope — "app" | "components" | path]
---

Check that design tokens exist first — read `design-tokens.md`, or scan `tailwind.config.*` and `:root` + `.dark` CSS vars. If no tokens found, stop and tell the user to run `/web-standards:extract-tokens` first.

```
verify-changes brief:
  scope: $ARGUMENTS or "app/ + components/"
  dimensions: [craft-guide §13, craft-guide §1.5, craft-guide §11.3, craft-guide §11.5, craft-guide §12.7, craft-guide §12.8, craft-guide §12.9]
  depth: direct
  fix: yes if --fix, else no
  source: web-standards:theme-audit
```
