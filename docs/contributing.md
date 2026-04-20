# Contributing

Thanks for considering a contribution. This guide covers the edit flow, review criteria, and maintenance scripts.

## Repo layout

```
<stack>/skills/<stack>-standards/skills/<name>/SKILL.md       Bundle skill — CANONICAL
<stack>/skills/<stack>-<name>/skills/<name>/SKILL.md          Slice skill — MIRROR (auto-synced)
core/plugins/core-hooks/hooks/*.sh                            Cross-stack safety hooks
scripts/sync.sh                                               Mirrors bundle → slices (all packs)
scripts/export.sh                                             Exports to Cursor / AGENTS.md
.claude-plugin/marketplace.json                               Marketplace index (15 plugins)
```

Rules live **inside** `SKILL.md` bodies — not as separate `*.md` files. Each standards skill's frontmatter `description:` field drives auto-invocation; the body is the rule Claude reads.

## Naming conventions

- **Marketplace source:** `nandamashokkumar/pixelcrafts` (one, covers every pack)
- **Plugin names:** stack-prefixed — `flutter-<skill>`, `api-<skill>`, `web-<skill>`, future `db-<skill>`
- **Bundle per pack:** `<stack>-standards` (`flutter-standards`, `api-standards`, `web-standards`)
- **Cross-stack:** `core-hooks` (no stack prefix — applies to every language)
- **Slash commands:** namespaced — `/flutter-standards:pre-ship`, `/api-standards:sync-migrate`, `/web-standards:premium-check`

## Editing a standards skill (auto-invoke)

The bundle copy is canonical. No slice copies exist for standards skills (they only live inside the bundle).

1. Edit `<stack>/skills/<stack>-standards/skills/<name>/SKILL.md`
2. Verify the frontmatter: `name`, `description` (auto-invoke discovery text), no `disable-model-invocation: true`
3. Bump `version` in `<stack>/skills/<stack>-standards/.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` (both the repo-level `metadata.version` and the bundle's entry)
4. Add a `docs/changelog.md` entry
5. Open a PR

## Editing an explicit (audit/scaffold/workflow) skill

The bundle copy is canonical. Slice copies are mirrors produced by `sync.sh`.

1. Edit `<stack>/skills/<stack>-standards/skills/<name>/SKILL.md`
2. Run `./scripts/sync.sh` — mirrors to the slice plugin
3. Bump `version` in:
   - `<stack>/skills/<stack>-standards/.claude-plugin/plugin.json` (bundle)
   - `<stack>/skills/<stack>-<name>/.claude-plugin/plugin.json` (slice)
   - `.claude-plugin/marketplace.json` (repo-level `metadata.version` + both plugin entries)
4. Update the skill's card in [`docs/skills.md`](skills.md) if behavior changed
5. Add a `docs/changelog.md` entry
6. Open a PR

Never edit slice copies directly — `sync.sh` overwrites them.

## Adding a new standards skill

1. Create `<stack>/skills/<stack>-standards/skills/<name>/SKILL.md` with:
   ```yaml
   ---
   name: <name>
   description: One-line description that drives auto-invocation. Start with "Apply when…" or "Use when…" and list the triggering contexts clearly.
   ---
   ```
   Do NOT set `disable-model-invocation: true` on standards skills — auto-invoke is the whole point.
2. Add a row to `docs/skills.md` under the pack's auto-invoke table
3. Add a `docs/changelog.md` entry
4. Bump the bundle + marketplace versions

No slice plugin for standards skills — they only ship inside the bundle.

## Adding a new explicit skill

1. Create the bundle copy: `<stack>/skills/<stack>-standards/skills/<name>/SKILL.md` with frontmatter:
   ```yaml
   ---
   name: <name>
   description: <one-line description>
   disable-model-invocation: true
   argument-hint: [optional-arg]
   ---
   ```
   `disable-model-invocation: true` keeps it explicit — users invoke via `/<stack>-standards:<name>`.
2. Create the slice plugin folder: `<stack>/skills/<stack>-<name>/.claude-plugin/plugin.json` (follow an existing slice as template)
3. Add `<name>` to `scripts/sync.sh`'s `PACKS` array under the right stack
4. Run `./scripts/sync.sh` to populate the slice
5. Add the slice to `.claude-plugin/marketplace.json`
6. Add a card to `docs/skills.md`
7. Add a `docs/changelog.md` entry
8. Bump versions

## Adding a new pack (Database, future stacks)

A new pack is a new top-level folder (`database/`, `mobile-native/`, etc.) mirroring the Flutter/API/Web layout:

1. Create `<stack>/skills/<stack>-standards/` with standards + explicit skills underneath
2. Decide the slice naming — `db-<skill>` for Database, etc.
3. Add the bundle + each slice to `.claude-plugin/marketplace.json`
4. Add an entry to `scripts/sync.sh` PACKS array
5. Add a pack to `scripts/export.sh` case statement (so Cursor/Antigravity consumers can generate tool-native files)
6. Document the pack in `docs/skills.md` (new section)
7. Cut a minor release and update `docs/roadmap.md`

If you're adding a second pack beyond API/Web/Flutter, consider whether universal content (DRY, testing pyramid, observability, security) should be extracted to `core-standards` before duplicating it.

## Maintaining `scripts/sync.sh`

Keeps bundle ↔ slice copies in sync for explicit skills. Run after editing any bundle-side `SKILL.md`. Runs rsync with `--delete`, so stale slice files are removed.

## Maintaining `scripts/export.sh`

Generates `.cursor/rules/*.mdc` + `AGENTS.md` for non-Claude-Code tools. Pulls from the same bundle SKILL.md sources. Add new standards skills to the `STANDARDS=(…)` array for the relevant pack.

## Design principles for contributions

- **Universally applicable within its pack** — if a rule/skill only applies to some apps, it doesn't belong here. Put it in the consumer app's `CLAUDE.md`.
- **Actionable** — rules must cite a pattern with good/bad examples, not vague principles.
- **Self-contained** — a `SKILL.md` must stand alone; don't rely on other skills being installed.
- **No PII, no company-specific names** — public repo. App names go in `docs/history.md` as provenance, never in skill content.
- **One concern per skill** — if a standards skill feels like two, split it.

## Review checklist

- [ ] `./scripts/sync.sh` run if any explicit skill was edited
- [ ] Changelog entry added
- [ ] Version bumps applied (bundle + slice + marketplace)
- [ ] Docs card updated in `docs/skills.md`
- [ ] Linked to any related issue
- [ ] No pixelcrafts-internal names leaked into content
- [ ] Confirmed which pack the content belongs to

## Versioning

- **Patch** (`0.1.x`) — doc fixes, typos, clarifications that don't change behavior
- **Minor** (`0.x.0`) — new skill, new pack, expanded content
- **Major** (`x.0.0`) — breaking change to a skill's output format, slash command namespace, or marketplace layout

Tag every release as `v<marketplace-version>` so `/plugin marketplace update pixelcrafts` resolves cleanly.

## Reporting issues

- Bug in a skill (wrong output, crash) — open an issue with the input that triggered it
- Disagreement with a standard — open a discussion, not an issue. Standards are opinionated by design; changing them is a policy decision.
- Security issue — email the maintainer listed in the repo's security policy; do not open a public issue.
