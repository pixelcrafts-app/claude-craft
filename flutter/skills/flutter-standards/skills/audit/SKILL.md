---
name: audit
description: "Run full Flutter app audit: pre-ship checks, craft quality, screen states. Explicit command only."
disable-model-invocation: true
argument-hint: [optional-path] [--fix]
---

Run `flutter analyze` first. Stop on any error or warning — fix all analyzer output before proceeding.

```
verify-changes brief:
  scope: $ARGUMENTS or "uncommitted working tree"
  dimensions:
    - engineering correctness      # rules: flutter-standards:engineering
    - craft quality                # rules: mobile-standards:craft-guide (states, hierarchy, motion)
    - screen completeness          # loading / empty / error / content states
    - production readiness         # rules: mobile-standards:production-readiness
    - accessibility                # rules: flutter-standards:accessibility
    - performance                  # rules: flutter-standards:performance
  depth: full-ripple
  fix: yes if --fix, else no
  source: flutter-standards:audit
```
