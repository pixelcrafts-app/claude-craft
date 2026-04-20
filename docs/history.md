# History — How this pack came to be

This document records the provenance of each rule and skill so future contributors understand the intent behind the content.

## Origin

Before this pack existed, a portfolio of Flutter apps (internal to the maintainers) each kept their own `.claude/rules/` and `.claude/skills/` folders. Every app's copy had drifted from every other app's. When a decision was improved in one app, the other apps rarely picked it up.

Merging the copies into one authoritative source required:

1. Reading every variant of every file across the apps
2. Picking a canonical version per file based on which had the clearest/freshest content
3. Genericizing names, paths, and examples so the result works for any Flutter app — not just the portfolio
4. Filling gaps — adding rules and skills that no app had but that every app needed

## Canonical sources — version picked per file

| File | Canonical source | Why it won |
|------|------------------|------------|
| `craft-guide.md` | Daypilot (325 lines) | Newer creative additions: "Each Mode Is Independently Designed", "Visual Weight Balance", "Transition Continuity", "Sparse States", "Screen Density Identity", "Contextual Awareness", "Data Continuity Across Screens". Other variants were 284 lines (missing half) and 217 lines (stalest). |
| `engineering.md` | FluentPro base + Daypilot's AI-DoD section | FluentPro had the structural "CORE PRINCIPLES" (DRY, SSOT, No Hardcoded Values, Centralize, Consistent Error Handling, Security). Daypilot added "AI-Assisted Definition of Done". Merged and genericized. |
| `flutter.md` | Daypilot | Has "Prototype Exception", "Text Resilience", image scrim guidance. Frontmatter `paths:` stripped — paths wire in each app's own `CLAUDE.md`. |
| `api-data.md` | Daypilot | Cleaner "screens never touch API client" phrasing. Frontmatter stripped. |
| `pre-ship` skill | Daypilot | Adds "skeleton, not spinner", "maxLines + overflow protection", "no unrequested features". Portfolio-specific paths stripped. |
| `premium-check` skill | Daypilot | 1-line improvement: skeleton/shimmer instead of placeholder language. |
| `verify-screens` skill | Daypilot | Adds text overflow + touch target checks. Portfolio-specific paths stripped. |
| `testing.md` | Newly authored | No app had a dedicated testing rule. Covers pyramid, unit/widget/integration split, mocktail, golden tests, Riverpod/Provider patterns, CI gates, coverage targets. |
| `accessibility.md` | Newly authored | Previously 4 lines inside `flutter.md`. Broken out into a full rule covering Semantics, contrast ratios, touch targets, color-alone rule, text scaling, bold text, reduced motion, screen readers, keyboard/focus, forms, RTL, seizure safety. |
| `find-hardcoded` skill | Newly authored | Scans hex colors, magic `EdgeInsets`, inline `TextStyle`, magic `BorderRadius`, uncommon `Duration`s, hardcoded `FontWeight`, repeated alpha values. Reports `file:line` with suggested token. |
| `scaffold-screen` skill | Newly authored | Generates a screen with all 4 states wired, design tokens referenced, state-management pattern detected. First generative skill in the set. |
| `performance.md` | Newly authored | Frame budgets (16ms/8ms), cold start with bad/good `main()` examples, lists/scroll, image decode-at-display-size, isolates, memory, profiling. |
| `forms.md` | Newly authored | Field anatomy, keyboard + autofill hints table, validation timing, error messages, submit button, specialized inputs, destructive action flow. |
| `observability.md` | Newly authored | Three pillars (logging/crash/analytics), log levels + structure, crash hooks, event naming convention, PII classification, consent/opt-out, retention, trace + session IDs. |
| `find-duplicates` skill | Newly authored | Widget skeleton matches, helper overlap, provider duplication, mapper duplication, copy-pasted card/button code, overlapping services. |
| `accessibility-audit` skill | Newly authored | Missing Semantics, color-alone signals, tiny touch targets, placeholder-only fields, missing autofill hints, fixed heights breaking text scaling, RTL violations, motion-preference gaps. |
| `scaffold-feature` skill | Newly authored | Full feature folder: model, mapper, repository, data sources, providers, screen, widgets, test stubs, README. Detects state mgmt, design-system prefix, folder layout, mapper style, test framework. |

## Post-extraction genericization

After canonicalizing, `engineering.md` still carried portfolio-specific class names (`FluentProColors`, `FluentProSpacing`, etc.), file paths (`lib/shared/...`), and Firebase-coupled auth checks. The SSOT table, code examples, Centralize table, Error Handling, and Security sections were genericized to describe the **contract** (one class, one source), not any app's specific naming.

Apps name their own classes (`AppColors`, `FluentProColors`, `DaypilotColors`) — the rule is one class per concern, not the prefix. This made the rule reusable across any Flutter app.

Later passes stripped the remaining portfolio-specific references from the other rule files, so the published pack contains no internal names or paths.

## Packaging history

Initial structure (v0.0.x, internal): `rules/` + `skills/` at the repo root, consumed via symlinks into each app's `.claude/` folder.

Problems with symlink consumption:
- Depth varies per app (`../../../../` depends on where the app lives)
- Doesn't work across machines (absolute paths) or CI
- No version pinning — every app gets HEAD, including mid-refactor states

Migration to plugin marketplace (v0.1.0, public): each explicit skill became its own slice plugin plus a bundle plugin containing all skills. The marketplace at the repo root lets users install either the bundle or individual skills via `/plugin install` — or zero-config via `.claude/settings.json`.

Late in v0.1.0 the repo settled at its final name `claude-craft` (after earlier internal names `pixelcrafts-mobile-standards` and `pixelcrafts-standards`). The layout briefly explored a skills-first shape (flat `skills/` + `rules/<stack>/`) and a rules-as-separate-markdown shape (`flutter/rules/*.md` @-imported from app `CLAUDE.md`). Both were dropped. The final shape landed at **stack-first, rules-inside-skills**: each stack gets its own folder (`flutter/skills/<stack>-standards/skills/<name>/SKILL.md`) and rules live inside `SKILL.md` bodies as auto-invoke skills. Claude loads them itself when file types match — no `CLAUDE.md` edits, no @-imports. A `core-hooks` cross-stack safety plugin was added as the 15th plugin. `scripts/export.sh` generates Cursor Rules + AGENTS.md from the same SKILL.md sources so non-Claude-Code tools consume the same standards. Plugin names keep the `flutter-` prefix so they don't collide with future stacks; slash commands are namespaced per bundle (`/flutter-standards:pre-ship`) for unambiguous dispatch. The marketplace name was set to `pixelcrafts` so install commands are brand-forward: `/plugin install flutter-standards@pixelcrafts`.

## Lessons from the extraction

- **Drift starts fast.** Two apps copying the same rule file diverge within a sprint.
- **Names leak faster than content.** Genericizing class/file names was more work than genericizing concepts — the concepts were already universal.
- **Gaps are invisible until you list them.** No app had a dedicated `accessibility.md` or `testing.md`; all 5 apps had the gap, none flagged it.
- **Audit skills beat audit checklists.** Teams don't run checklists. They do run `/pre-ship`.
- **Scaffold skills beat starter templates.** Templates go stale. Scaffolds detect the current state of the target app and match it.
