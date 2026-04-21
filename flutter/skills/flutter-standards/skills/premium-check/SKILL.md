---
name: premium-check
description: Audit a screen or widget against the premium mobile craft standard — walks craft, widget, accessibility, and performance rules rule-by-rule and records PASS / FAIL / N_A with evidence.
disable-model-invocation: true
argument-hint: [screen-file-path]
---

# Premium Craft Audit — Flutter

Audit `$ARGUMENTS` against the premium mobile standard. This is a focused visual + interaction-quality review — wider than `find-hardcoded` (which scans a single concern) and narrower than `pre-ship` (which runs the whole pack).

This command is a thin wrapper. Iteration, batching, report format, and the optional fix loop live in `core-skills:verify-changes`. This command supplies the scope and the dimensions.

## How this runs

1. Parse `$ARGUMENTS`:
   - A Dart file / folder → that's the scope.
   - If empty, scope defaults to `"uncommitted working tree"` — the engine will take it from there.
   - `--fix` in the user message → `fix: yes`; otherwise `fix: no`.

2. Emit the brief and delegate:

   ```
   verify-changes brief:
     scope: $ARGUMENTS                 # or "uncommitted working tree" if empty
     dimensions:
       - craft-guide                   # premium mobile craft — color, typography, motion, state, density
       - widget-rules                  # widget discipline — keys, const, rebuilds, lifecycle
       - accessibility                 # semantic labels, contrast, reduced motion, color-alone
       - performance                   # list virtualization, image progressive loading, disposal
     depth: direct
     fix: <yes | no>
     source: flutter-standards:premium-check
   ```

3. Stop. The engine walks each rule in those four dimensions, records PASS / FAIL / N_A with file:line evidence, and emits the consolidated report (plus the fix loop if requested).

## What you get back

- Per-rule verdict across the four dimensions.
- Critical failures first: data-pipeline gaps, missing empty / error / loading states, touch targets < 48px, accessibility violations, obvious perf bombs (un-virtualized large lists, missing dispose).
- Polish failures second: design-system drift (hardcoded colors / spacing / radii), inconsistent motion, visual hierarchy misses.
- Verdict: `SHIP` / `NEEDS WORK`. If `fix: yes`, the engine applies minimal fixes, reruns the fixed rules, and reports the final state with a stuck-rule list for anything that oscillated.

## Scope boundaries

This command enforces discipline — it does not impose aesthetic choices. Colors, typography, motion values come from the user's design system; the audit checks that whatever the user chose is applied consistently. `find-hardcoded` and `find-duplicates` remain available standalone for focused scans of those single concerns.

## Relationship to other skills

- `premium-check` → focused craft / widget / a11y / perf audit, optional fix.
- `pre-ship` → widest scope, every installed Flutter standard, report only.
- `verify-screens` → data-pipeline trace (screen → data source) as a narrower scope.
- `find-hardcoded` / `find-duplicates` → regex-based standalone scans.
