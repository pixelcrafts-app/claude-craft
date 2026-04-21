---
name: pre-ship
description: Full quality gate before marking any web feature complete — delegates to the cross-stack audit engine with every installed web standard as a dimension.
disable-model-invocation: true
argument-hint: [optional: path or "task" for just-touched files]
---

# Pre-Ship Quality Gate — Web

Run before declaring any web feature or task complete. This is the widest scope of the audit engine: every installed web standard becomes a dimension; consumers of changed files get checked too.

This command is a thin wrapper. The engine (`core-skills:verify-changes`) owns iteration, batching, metadata, and reporting. This command picks the dimensions and the depth.

## How this runs

1. **Pre-flight: lint.** Before delegating, run the project's lint command if one exists (`npm run lint` / `pnpm lint` / `yarn lint`). A lint failure halts the gate — fix lint errors / warnings first, then rerun `pre-ship`. Lint is cheap and catches mechanical issues the rule walk won't.

2. Parse `$ARGUMENTS`:
   - A path / folder → that's the scope.
   - `"task"` or empty → scope defaults to `"uncommitted working tree"` (the engine will interpret).

3. Emit the brief and delegate:

   ```
   verify-changes brief:
     scope: $ARGUMENTS                 # or "uncommitted working tree" if empty
     dimensions: [ALL web-standards]   # every auto-invoke skill in the pack:
                                       # nextjs, production-readiness, craft-guide
     depth: direct+consumers           # catches breakage in files that import changed code
     fix: no                           # pre-ship reports; it does not auto-fix
     source: web-standards:pre-ship
   ```

4. Stop. The engine runs discovery → plan → batched rule walk → consolidated report. On finish:

   - If the scope includes `.md` / version-bump changes, the engine emits a follow-up line: *"Next: running docs-sync for drift check."* Let `docs-sync` run.
   - If the verdict is SAFE TO COMMIT with zero critical failures, the feature is ready.

5. **If the verdict is SAFE TO COMMIT and enforcement mode is active** (the project has `.claude/enforcement.json` listing `web-standards` as mandatory), mark the gate passed in the session ledger so the Stop hook lifts its block:

   ```bash
   bash "${CLAUDE_PLUGIN_ROOT_core_hooks:-$HOME/.claude/plugins/pixelcrafts/core-hooks}/hooks/session-ledger.sh" mark-pass web-standards
   ```

   On FAIL, do **not** mark the ledger — the Stop hook should stay firm until the feature actually passes.

## What you get back

- Per-dimension PASS / FAIL counts across every installed web standard.
- Critical failures grouped and listed first (hardcoded secrets, missing auth checks, broken contracts, failed prod-readiness R1–R10 items).
- Polish failures listed second (craft-guide §1–§15 violations that ship-unfinished).
- Consumer-impact section: any file that imports a changed file and now fails a rule because of the change (e.g. a renamed export still referenced).

## Scope boundaries

This command is a gate, not a fix loop. It reports. If you want the engine to apply fixes, use `premium-check --fix` (craft-only) or invoke `verify-changes` directly with `fix: yes`. Pre-ship stays read-only so the gate's verdict is reproducible.

## Relationship to other skills

- `pre-ship` → **before merge**, widest scope, every installed standard.
- `premium-check` → craft-only audit with optional fix loop.
- `theme-audit` → craft-guide §13 subset.
- `verify-changes` called directly → multi-file dependency-aware verification (same engine, custom dimensions).
