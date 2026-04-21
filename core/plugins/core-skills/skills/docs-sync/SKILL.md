---
name: docs-sync
description: Apply at the end of a full task (not mid-work) to catch drift between code and docs. Auto-invokes when signals of task completion appear — version bumped, new skill folder created, plugin.json / marketplace.json edited, user says "ship / done / release / complete", pre-ship runs, or a v*.*.* commit message is drafted. Never blocks — flags deltas the user decides on.
---

# Docs Sync — End-of-Task Discipline

When you finish a *full task* — a release, a feature, a shipped chunk of work — code and docs should land together. Claude forgets this. This skill is the guardrail.

## When this fires

Only at natural task-end moments. Not after every edit.

**Strong signals (run the audit):**
- Version bumped in any `plugin.json` or `marketplace.json`
- A new skill folder created (`skills/<name>/SKILL.md`)
- A plugin added or removed from `marketplace.json`
- A hook added or removed from any `plugin.json`
- The user says "ship it", "done", "task complete", "release it", "push it"
- A commit message starts with `v` followed by a semver (`v0.3.1`, `v1.0.0`)
- A pre-ship skill is invoked

**Weak signals (offer to run, don't auto-run):**
- A batch of 5+ file edits closes out
- A subfolder gets a new top-level file (e.g., `core/plugins/docs-sync/`)
- README or CHANGELOG was itself modified (cross-check the rest)

**Do NOT fire on:**
- Single-file edits inside an in-progress task
- Refactors with no user-facing surface change
- Internal tests / CI config changes that don't alter behaviour

If you're unsure: err on not running. The user can invoke explicitly.

---

## What to check

Walk this list. Flag each gap clearly — don't auto-fix prose, don't rewrite voice.

### 1. Version coherence

- Every `plugin.json` version matches what it should be for the changes made.
- `marketplace.json` top-level `metadata.version` matches the highest plugin version.
- Each plugin's entry in `marketplace.json` matches the plugin's own `plugin.json`.
- Commit message / tag matches the version in the code.

### 2. README sync

For the repo's main `README.md`:

- Plugin count line ("Four packs ship") reflects actual plugin count.
- Install snippet uses the current default plugins and current marketplace name/repo.
- Any feature section that references a capability still exists in the code.
- Example slash commands match the actual skill names in each pack.
- Links to files / docs resolve (no dead links to moved/renamed files).
- No references to removed plugins or deprecated flags.

### 3. Changelog

- An entry exists for the current version.
- Date is today, not stale.
- `### Added / Changed / Removed / Breaking` sections match reality (not a copy-paste from prior release).
- Breaking-change items are front-loaded; users should not discover breakage by surprise.
- The prior-version entry is not accidentally duplicated or shifted.

### 4. Roadmap

- If a shipped item was in "Next up" or "Under consideration", move it to "Shipped".
- If a new initiative came up during the task, add it to the right column with context.
- Don't leave phantom items — something listed as done but not actually shipped is worse than missing it.

### 5. docs/skills.md (or equivalent catalog)

- Every skill folder on disk has an entry.
- Every entry in the catalog maps to a skill folder on disk.
- Auto-invoke count matches reality ("9 auto-invoke standards" is wrong if you just added a tenth).
- Slash command rows reference skills that exist — delete rows for removed skills.

### 6. Per-plugin README (if the plugin has one)

- Mirrors the changes relevant to that plugin.
- No cross-references to plugins that no longer exist in the marketplace.

### 7. Descriptions on skills and plugins

The skill `description` field drives Claude's auto-invoke matcher. After adding a new concern:

- The skill's own `description` mentions the new concern (so it actually auto-invokes when relevant).
- The plugin's `description` in `plugin.json` and `marketplace.json` reflects what the plugin now does.
- Stale descriptions = skills that silently never fire on the right work.

### 8. Cross-boundary references

- Quickstart, contributing, security, and any other doc that names a plugin, skill, or command gets the same treatment as README.
- Search for literal repo / org names (old + new) across all `.md` files — broken renames are the top source of stale docs.

---

## How to report

Produce a short report, not a rewrite. Group by severity:

```
Docs sync report — <task summary>

Critical (blocks release)
  - marketplace.json says "9 standards" but flutter pack now has 10
  - CHANGELOG missing entry for v0.4.0
  - README install snippet references old repo name

Minor (should fix before next release)
  - ROADMAP "core-hooks audit" still listed under Next Up, was shipped in v0.3.0
  - docs/skills.md doesn't list production-readiness in web pack

OK (verified in sync)
  - All plugin versions match
  - All slash commands resolve to existing skills
  - No dead internal links
```

Then let the user decide what to fix. **Do not silently rewrite their README or changelog.** Prose is theirs.

---

## Scope boundaries

This skill is about *sync*, not quality. It does not:

- Rewrite prose to sound better
- Reorder sections
- Enforce a particular doc structure
- Add emojis, badges, or branding
- Fix typos (a separate pass; the user may want that explicitly)

Those are editorial calls. Sync is factual: does the doc match the code?

## Example: what "full task" looks like

**Full task (fire):** "Ship v0.4.0 with the docs-sync skill and README rewrite."
→ All 8 checks above apply.

**Intermediate task (skip):** "Fix the typo in the Flutter pre-ship heading."
→ No sync audit needed. The typo is the task.

**Ambiguous (ask the user):** "Add rate-limit detection to the API skill." — is that the final change, or one of several? If unsure, finish the work, then ask "is this the task complete? I can run the docs-sync audit now."
