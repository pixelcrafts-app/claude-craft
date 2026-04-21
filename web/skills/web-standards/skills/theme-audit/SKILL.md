---
name: theme-audit
description: Verify theme completeness — every themeable value uses tokens, light and dark are independently designed, no hardcoded values bleed through, SSR hydration flash prevented, `color-scheme` set, every screen works in both themes. Use before shipping any theme-related change.
disable-model-invocation: true
argument-hint: [optional: scope — "app" | "components" | "<directory>"]
---

# Theme Audit — Web

Premium apps don't have "light mode" and "dark mode tolerable." They have two themes, each independently designed, each verified.

This command is a thin wrapper. It's the theme subset of the craft audit — everything under `craft-guide §13` (plus the theme-adjacent rules §1.5, §11.3, §11.5, §12.7, §12.8, §12.9). The iteration-loop and fix-loop live in `core-skills:verify-changes`; this command supplies the scope and the rule subset.

## How this runs

1. Parse `$ARGUMENTS`:
   - If a path / directory is given, that's the scope.
   - If empty, scope defaults to the app's `app/` and `components/` roots.
   - `--fix` intent in the user message → `fix: yes`; otherwise `fix: no`.

2. Pre-flight — check tokens exist:
   - Read `design-tokens.md` if present (written by `/web-standards:extract-tokens`).
   - Otherwise scan `tailwind.config.*`, `app/globals.css`, and CSS vars in `:root` + `.dark`.
   - If neither theme has any tokens, **stop and tell the user** to run `/web-standards:extract-tokens` first. Do not delegate — there's nothing to audit against.

3. Emit the brief and delegate:

   ```
   verify-changes brief:
     scope: $ARGUMENTS                 # or "app/ + components/" if empty
     dimensions:
       - craft-guide §13               # theme tokens, semantic naming, parity, hydration, color-scheme
       - craft-guide §1.5              # dark-mode contrast verified separately
       - craft-guide §11.3             # ::selection customized (theme-aware)
       - craft-guide §11.5             # caret-color set per theme
       - craft-guide §12.7             # color-scheme CSS property set
       - craft-guide §12.8             # forced-colors mode honored
       - craft-guide §12.9             # prefers-reduced-transparency honored
     depth: direct
     fix: <yes | no>
     source: web-standards:theme-audit
   ```

4. Stop. The engine runs discovery → plan → rule walk → report → optional fix loop. The report groups results by craft-guide rule ID.

## What you get back

- Per-rule verdict for the theme dimensions above (PASS / FAIL / N_A with evidence).
- Critical failures highlighted: hydration-flash present, contrast miss in dark mode, computed-invert dark mode (heuristic).
- Polish failures: forced-colors, reduced-transparency, third-party embeds without theme prop.
- Verdict: `THEMES SHIP` (zero critical) / `BLOCK` (any critical).

## Scope boundaries

This command does **not** decide which colors go in dark mode — independent theme design is the user's job. It flags computed-invert patterns; it never rewrites them. It never invents token values. If a hardcoded color should become a token but the token doesn't exist, the engine records `NEEDS_USER_INPUT` rather than picking a value.

## Tradeoffs

- **Slow on large codebases** — grep passes across every `.tsx` / `.css` file. Scope with the argument (`theme-audit components/ui` is faster than full repo).
- **Contrast check is heuristic** — token pairing is inferred from usage; borderline cases need axe / Lighthouse in a real browser.
- **Switch coverage needs live screens** — static audit catches most, but hydration bugs and layout shifts often only surface at runtime. Run this static audit first, then toggle the app in a browser.
