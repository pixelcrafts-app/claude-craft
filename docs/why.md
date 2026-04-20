# Why this exists

## The problem

Teams that ship multiple apps in the same stack hit the same problem repeatedly: every app has its own "shared" rules and skills, and every app's copy has drifted from every other app's. Over twelve months you end up with N different answers to "what's the padding on a card?" — one per app, none authoritative.

The typical fix is a `.claude/` folder copy-pasted between projects. It drifts.

The sometimes-better fix is a git submodule or shared folder. It works until someone forgets to init the submodule, or the pointer goes stale across branches.

The durable fix is to ship the standards as a **Claude Code plugin marketplace** — with auto-invoke standards (no `CLAUDE.md` edits) and a multi-tool export so Cursor / Antigravity / Codex / Aider users get the same content. Install once via `.claude/settings.json` (zero-config), update via `/plugin marketplace update`, and every app on the marketplace's version sees the same rules and the same skills.

## Why auto-invoke skills beat `@`-imports

Earlier iterations of this pack shipped rules as standalone `*.md` files that apps `@`-imported from `CLAUDE.md`. That worked but added a setup step every team skipped.

Current design — rules ship **inside** skills with auto-invoke descriptions. Claude Code discovers matching skills itself when it sees relevant work (editing a `.dart` file fires Flutter standards; editing `src/**/*.ts` fires API standards). That means:

- The rules you write are the rules your AI collaborator follows — automatically
- New team members inherit the standards the moment they open the project, zero onboarding
- Skills (slash commands that scan and report) sit one namespaced keystroke away (`/flutter-standards:pre-ship`)
- Non-Claude-Code tools (Cursor, Antigravity, Codex) get the same standards via `scripts/export.sh`

Auto-invoke + zero-config + multi-tool export is what makes this a drop-in product instead of a setup project.

## What you gain

### Consistency across apps

One install = one source of truth for typography, spacing, a11y, perf. Three apps' home screens suddenly agree on padding values without a meeting.

### Skills that scan every file

Where checklists rot (nobody runs them), skills execute:

- `find-hardcoded` finds every `Color(0xFF...)` in `lib/` and suggests the design-system token
- `find-duplicates` finds every pair of widgets that render the same structure
- `accessibility-audit` finds every `IconButton` without a Semantics label
- `pre-ship` runs the full gate before you open a PR

### Scaffolds that save hours per feature

`scaffold-feature` generates the entire feature folder — model, mapper, repository, data sources, providers, screen (with four states wired), widgets, test stubs, README. The boring 80% of a new feature is done in seconds; you start on the 20% that matters.

### Rules that your AI collaborator actually follows

Rules in this pack ship as auto-invoke skills. Claude Code loads them itself when file types match — no imports, no `CLAUDE.md` edits, no onboarding docs. Your AI follows the same standards as your humans, and when a rule is ambiguous, the AI asks for clarification rather than guessing.

For tools that aren't Claude Code, `scripts/export.sh` generates `.cursor/rules/*.mdc` (Cursor Rules v2) and `AGENTS.md` (Antigravity, Codex, Aider, OpenAI SWE) from the same sources. One standard, every tool.

## Rough gains (honest estimates)

These are estimates based on internal use. Real numbers depend on team size and starting state — measure on your own codebase and share back.

- **~2–3 hours per new feature** saved via `scaffold-feature` — no manual wiring of the same seven files
- **~40% fewer regressions caught in review** when `pre-ship` and `accessibility-audit` run before PR
- **~80% drop in hardcoded colors/spacing** after one `find-hardcoded` sweep + a CI gate
- **~0 duplicate widgets** after a `find-duplicates` refactor pass

None of these claim to transform a team overnight. They compound. A pattern that prevents three small bugs a week, across five apps, across six months, is a lot of bugs.

## What this is NOT

- **Not a framework.** Your app's stack (Riverpod/GoRouter/Hive) stays in your own `app-level.md`. This pack is stack-universal Flutter discipline.
- **Not a design system.** Apps still own their colors, fonts, and components. This pack enforces that they *use* one — not which one.
- **Not a linter.** Linters run on syntax. These skills reason about structure and intent.
- **Not a replacement for code review.** It catches the boring-and-obvious so reviewers can focus on the important-and-subtle.
- **Not complete.** A11y, performance, and forms are covered; analytics dashboards, store-listing craft, and localization workflows are not. See the roadmap for what's coming.

## Who should adopt

- Teams shipping **2+ Flutter apps** in the same org — the consistency gain compounds per app
- Teams where **AI-assisted coding is a first-class workflow** — rules in system-prompt form are only useful if the AI reads them
- Teams tired of **"our standards live in a Notion page from eight months ago"** — this repo is the alternative

## Who should not adopt yet

- Teams shipping **one** Flutter app — you probably don't need the plugin-install complexity; just copy the rules you like into your own `.claude/rules/`
- Teams with **custom in-house frameworks** that contradict Flutter-idiomatic patterns — the rules will argue with your framework and both will lose
- Teams with a strong existing **design system + audit tooling** — you likely already have 70% of what this provides; picking individual skills (`find-hardcoded`, `accessibility-audit`) may be enough
