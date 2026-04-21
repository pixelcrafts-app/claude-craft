---
name: verify-screens
description: Verify Flutter screens render real content end-to-end — traces the full pipeline from data source to UI and audits state coverage plus design-system compliance for every screen in scope.
disable-model-invocation: true
argument-hint: [optional-screen-path]
---

# Screen Verification Audit — Flutter

Verify the app renders real content end-to-end: data source → repository → provider → screen, plus the four required states and design-system compliance. If a screen path is given, audit that screen; otherwise, audit all screens in the scope.

This command is a thin wrapper. The engine (`core-skills:verify-changes`) is already dependency-aware — its Phase 2 graph walk is the right tool for "screen → provider → repo → data source" tracing. This command supplies the dimensions that matter and asks the engine to walk consumers, not just direct files.

## How this runs

1. Parse `$ARGUMENTS`:
   - A screen file → scope is that file.
   - A folder (e.g. `lib/features/onboarding`) → scope is that folder.
   - Empty → scope is `"all screens under lib/features/**"` (or the project's convention — engine infers).

2. Emit the brief and delegate:

   ```
   verify-changes brief:
     scope: $ARGUMENTS                 # or "lib/features/**" if empty
     dimensions:
       - api-data                      # data pipeline — source exists, mapper matches response, models match
       - widget-rules                  # screen renders real data (no placeholder strings, builders wired to providers)
       - craft-guide                   # state coverage (loading / empty / error / content), design-system discipline
     depth: full-ripple                # follow screen → provider → repo → data source
     fix: no                           # verify-screens reports; does not modify code
     source: flutter-standards:verify-screens
   ```

3. Stop. The engine's dependency graph walks the pipeline (screen imports provider, provider imports repo, repo imports data source) and checks each layer against the relevant dimension. The consolidated report groups findings per screen, not per file.

## What you get back

- Per-screen verdict: `PASS` / `FAIL` with file:line evidence.
- Per-screen pipeline trace: which provider, repo, data source feed this screen; where the chain breaks if it does.
- Content-rendering check: flags placeholder strings ("Coming soon", "No data", "Lorem ipsum") that leaked into a shipped screen.
- State-coverage check: loading / empty / error / content present per screen.
- Design-system compliance: hardcoded colors, spacings, radii, text styles — one-by-one.

## Scope boundaries

- Reports only — does not modify screens or add missing states. For fixes, use `premium-check --fix` on a single screen or apply manually.
- Does not execute the app. Static audit only. Runtime bugs (slow providers, race conditions) need manual smoke testing.
- Does not validate whether the source data is correct — only that the pipeline is wired and the screen renders it. Incorrect data at the source is outside this command's scope.

## Relationship to other skills

- `verify-screens` → pipeline + state coverage per screen.
- `premium-check` → focused craft + widget + a11y + perf on a single screen, with optional fix.
- `pre-ship` → widest scope before merge.
- `find-hardcoded` / `find-duplicates` → standalone regex scans for design-system drift and DRY violations.
