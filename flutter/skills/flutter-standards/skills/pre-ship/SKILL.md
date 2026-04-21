---
name: pre-ship
description: Full quality gate before marking any Flutter feature complete — runs `flutter analyze` then delegates to the cross-stack audit engine with every installed Flutter standard as a dimension.
disable-model-invocation: true
argument-hint: [optional: path or "task" for just-touched files]
---

# Pre-Ship Quality Gate — Flutter

Run before declaring any feature or task complete. Widest scope of the audit engine: every installed Flutter standard becomes a dimension; consumers of changed files get checked too.

This command is a thin wrapper over the cross-stack audit engine (`core-skills:verify-changes`). It adds a Flutter-specific pre-check (`flutter analyze`) and picks dimensions / depth. Iteration, batching, report format — all owned by the engine.

## How this runs

1. **Pre-flight: `flutter analyze`.** Run in the project root before delegating. The gate halts on any error **or** warning — the iteration loop doesn't start while the analyzer is unhappy. Fix analyzer output first, then rerun `pre-ship`.

2. Parse `$ARGUMENTS`:
   - A path / folder → that's the scope.
   - `"task"` or empty → scope defaults to `"uncommitted working tree"`.

3. Emit the brief and delegate:

   ```
   verify-changes brief:
     scope: $ARGUMENTS                       # or "uncommitted working tree" if empty
     dimensions: [ALL flutter-standards]     # every auto-invoke skill in the pack:
                                             # craft-guide, engineering, widget-rules,
                                             # api-data, testing, accessibility,
                                             # performance, forms, observability,
                                             # production-readiness
     depth: direct+consumers                 # catches breakage in files that import changed code
     fix: no                                 # pre-ship reports; it does not auto-fix
     source: flutter-standards:pre-ship
   ```

4. Stop. The engine runs discovery → plan → batched rule walk → consolidated report. On finish:

   - If the scope includes `.md` / version-bump changes, the engine hands off to `docs-sync` for drift check.
   - Verdict `SAFE TO COMMIT` with zero critical failures → feature is ready.

5. **If the verdict is SAFE TO COMMIT and enforcement mode is active** (the project has `.claude/enforcement.json` listing `flutter-standards` as mandatory), mark the gate passed in the session ledger so the Stop hook lifts its block:

   ```bash
   bash "${CLAUDE_PLUGIN_ROOT_core_hooks:-$HOME/.claude/plugins/pixelcrafts/core-hooks}/hooks/session-ledger.sh" mark-pass flutter-standards
   ```

   On FAIL, do **not** mark the ledger — the Stop hook should stay firm until the feature actually passes.

## What you get back

- Per-dimension PASS / FAIL counts across every installed Flutter standard.
- Critical failures listed first (hardcoded secrets, missing analyzer fixes before gate ran, failed data-pipeline contract checks, cross-boundary contract guesses).
- Polish failures listed second (craft-guide violations, accessibility misses, performance hints, test coverage gaps).
- Consumer-impact section: any Dart file that imports a changed file and now fails a rule because of the change.

## Scope boundaries

- Reports only — does not auto-fix. For focused craft fixes, use `flutter-standards:premium-check` (with fix intent) instead.
- `flutter analyze` is the only stack-specific tool invoked. Everything else is the generic engine reading installed Flutter SKILL.md files.
- Integration / widget tests are not executed by this gate. If the project has a test command (`flutter test`), run it separately — or bundle it into the project's CI.

## Relationship to other skills

- `pre-ship` → **before merge**, widest scope, every installed standard, reports only.
- `premium-check` → craft-focused audit with optional fix loop.
- `verify-screens` → data-pipeline trace (screen → provider → repo → data source → API) as a narrower scope.
- `find-hardcoded` / `find-duplicates` → stack-specific regex scans, run standalone.
