# Contributing

Thanks for considering a contribution. This is a short guide — edit flow, naming, review checklist.

## Repo layout

```
flutter/skills/flutter-standards/     Flutter pack — bundle plugin
api/skills/api-standards/             API pack — bundle plugin
web/skills/web-standards/             Web pack — bundle plugin
core/plugins/core-hooks/              Cross-stack safety plugin
scripts/export.sh                     Export to Cursor / AGENTS.md
.claude-plugin/marketplace.json       Marketplace index (4 plugins)
```

Rules live **inside** `SKILL.md` bodies — not as separate `*.md` files. The frontmatter `description:` on a standards skill drives auto-invocation; the body is what Claude reads.

## Naming

- **Marketplace source** — `pixelcrafts-app/claude-craft`
- **Plugin per stack** — `<stack>-standards` (`flutter-standards`, `api-standards`, `web-standards`)
- **Cross-stack** — `core-hooks` (no stack prefix — applies to every language)
- **Slash commands** — namespaced per pack: `/flutter-standards:pre-ship`, `/api-standards:sync-migrate`, `/web-standards:premium-check`

## Editing a skill

One copy. No build step. Edit and commit:

1. Edit `<stack>/skills/<stack>-standards/skills/<name>/SKILL.md`
2. Bump `version` in:
   - `<stack>/skills/<stack>-standards/.claude-plugin/plugin.json`
   - `.claude-plugin/marketplace.json` (both `metadata.version` and the plugin entry)
3. Add a line to [docs/changelog.md](changelog.md)
4. Update the skill row in [docs/skills.md](skills.md) if behavior changed
5. Open a PR

## Adding a standards skill (auto-invoke)

Create `<stack>/skills/<stack>-standards/skills/<name>/SKILL.md`:

```yaml
---
name: <name>
description: One-line description that drives auto-invocation. Start with "Apply when…" or "Use when…" and list the triggering contexts clearly.
---
```

Do **not** set `disable-model-invocation: true` — auto-invoke is the whole point of standards skills.

Then: add a row to `docs/skills.md`, bump versions, add a changelog line.

## Adding an explicit skill (slash command)

Same file location. Frontmatter:

```yaml
---
name: <name>
description: <one-line description>
disable-model-invocation: true
argument-hint: [optional-arg]
---
```

`disable-model-invocation: true` keeps it explicit — users invoke via `/<stack>-standards:<name>`.

Then: add a card to `docs/skills.md`, bump versions, add a changelog line.

## Adding a new pack

A new pack is a new top-level folder (`database/`, `rust/`, etc.) mirroring the `flutter/`, `api/`, `web/` layout:

1. Create `<stack>/skills/<stack>-standards/` with standards + explicit skills
2. Add the plugin to `.claude-plugin/marketplace.json`
3. Add a case to `scripts/export.sh` so Cursor/Antigravity consumers can generate tool-native files
4. Document the pack in `docs/skills.md`
5. Bump minor version, add a changelog entry

Before duplicating universal content (DRY, testing pyramid, observability, security) into a new pack, check if it should be extracted to a shared `core-standards` plugin first.

## Design principles

- **Universally applicable within its pack** — if a rule only applies to some apps, it belongs in the consumer app's `CLAUDE.md`, not here
- **Actionable** — cite patterns with good/bad examples, not vague principles
- **Self-contained** — a SKILL.md must stand alone; don't rely on other skills being installed
- **No PII, no company-specific names** — this is a public repo
- **One concern per skill** — if a standards skill feels like two, split it

## Review checklist

- [ ] Version bumped (plugin.json + marketplace.json)
- [ ] Changelog entry added
- [ ] `docs/skills.md` updated if behavior changed
- [ ] README / ROADMAP reflect any user-facing change (run `core-hooks:docs-sync` if unsure)
- [ ] No project-specific names leaked into content
- [ ] Slash command (if new) works end-to-end in a test project

## Versioning

- **Patch** (`0.x.Y`) — doc fixes, typos, clarifications that don't change behavior
- **Minor** (`0.Y.0`) — new skill, new pack, expanded content
- **Major** (`Y.0.0`) — breaking change to a skill's output format, slash command namespace, or marketplace layout

Tag every release as `v<marketplace-version>` so `/plugin marketplace update pixelcrafts` resolves cleanly.

## Reporting issues

- Bug in a skill (wrong output, crash) → open an issue with the input that triggered it
- Disagreement with a standard → open a discussion, not an issue. Standards are opinionated by design; changing them is a policy decision.
- Security issue → see [SECURITY.md](../SECURITY.md)
