---
name: premium-check
description: Premium craft audit — iterates every rule in craft-guide against a component or page, records PASS / FAIL / N_A per rule, loops until zero failures. Use when a surface must actually be premium, not just look it.
disable-model-invocation: true
argument-hint: [component-file-path]
---

# Premium Craft Audit — Web

Audit `$ARGUMENTS` against the **17-section premium web craft standard** (rule IDs §1.1 – §15.5 in `craft-guide`). This is not a spot-check — it walks every rule, records PASS / FAIL / N_A with evidence, and loops until zero fail.

This command is a thin wrapper. The audit engine lives in `core-skills:verify-changes`; this command pre-fills the brief so the engine runs with the right scope and dimensions. That keeps one iteration-loop implementation in the codebase instead of a drifting copy per stack.

## How this runs

1. Parse `$ARGUMENTS`:
   - If a path is given, that's the scope.
   - If empty, default scope is "uncommitted working tree" and the engine prompts before starting.
   - If the user message contains `--fix` or equivalent intent, set `fix: yes`; otherwise `fix: no`.

2. Before delegating, resolve the two context items the engine can't resolve on its own:
   - **Detected aesthetic** (from `craft-guide §9` — Minimalist, Glassmorphism, Bento, Utility-brutalist, etc.). Read `tailwind.config.*`, `app/globals.css`, `components/ui/*`, project `CLAUDE.md`. If ambiguous, ask the user — **do not guess**.
   - **Detected density target** (from `craft-guide §8.5` — content-heavy / tool / consumption / marketing / forms). Same sources.
   
   If either is unknown, ask the user before emitting the brief. Running premium-check without them is guessing.

3. Emit the brief and delegate:

   ```
   verify-changes brief:
     scope: $ARGUMENTS                 # or "uncommitted working tree" if empty
     dimensions: [craft-guide §1 – §15]
     depth: direct
     fix: <yes | no>                   # from --fix intent
     source: web-standards:premium-check
     context:
       aesthetic: <detected or user-supplied>
       density: <detected or user-supplied>
   ```

4. Stop. The engine runs Phases 2–6 (discovery → plan → batched rule walk → consolidated report → optional fix loop). §16 (Premium Checklist) and §17 (Ultimate Test) from `craft-guide` are summary sections — the engine uses them as final-verdict prompts, not as iteration targets.

## What you get back

- A rule-by-rule record: rule ID + evidence (file:line or "no occurrence") + PASS / FAIL / N_A with reason.
- Critical failures (§1.1, §1.5, §7.1–§7.5, §12.x when FAIL) listed separately from polish failures.
- Verdict: `SHIP` (zero fail) / `SHIPS-BUT-UNFINISHED` (polish only) / `BLOCK` (any critical fail).
- If `fix: yes` — the engine applies minimal fixes, reruns the fixed rules, and reports the final state with a "stuck after 3 attempts" section for any rule that oscillated.

## Scope boundaries

This audit enforces discipline — it does **not** impose colors, fonts, or aesthetics. Those come from the user and the design system. When aesthetic or density is unknown, the command asks instead of guessing. When a rule conflicts with a documented brand choice, the brand wins — the rule FAIL becomes N_A with reason (the engine accepts that).

## Relationship to other skills

- `premium-check` is the craft-dimension audit. `pre-ship` (web) is broader: it runs every installed web standard, not just craft-guide. Use `premium-check` for focused visual-craft review; `pre-ship` before merge.
- `theme-audit` is a narrower scope of this same engine (craft-guide §13 only).
- `verify-changes` called directly is the multi-file, dependency-aware version. Use it when changes span more than one component.
