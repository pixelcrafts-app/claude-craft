# Contributing

Thanks for considering a contribution. This is a short guide — edit flow, naming, review checklist.

## Repo layout

```
flutter/skills/flutter-standards/     Flutter pack — bundle plugin
api/skills/api-standards/             API pack — bundle plugin
web/skills/web-standards/             Web pack — bundle plugin
core/plugins/core-hooks/              Cross-stack hooks plugin (enforcement only)
core/plugins/core-skills/             Cross-stack skills plugin (docs-sync, verify-changes, subagent-brief)
scripts/export.sh                     Export to Cursor / AGENTS.md
.claude-plugin/marketplace.json       Marketplace index (5 plugins)
```

Rules live **inside** `SKILL.md` bodies — not as separate `*.md` files. The frontmatter `description:` on a standards skill drives auto-invocation; the body is what Claude reads.

## Naming

- **Marketplace source** — `pixelcrafts-app/claude-craft`
- **Plugin per stack** — `<stack>-standards` (`flutter-standards`, `api-standards`, `web-standards`)
- **Cross-stack** — `core-hooks` (hooks only) and `core-skills` (skills only); neither has a stack prefix — both apply to every language
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

## Adding an audit slash command — the thin-wrapper pattern

**Audit commands do not reimplement the engine.** If the command's job is "walk the rules, report pass/fail, maybe fix" (e.g. `premium-check`, `pre-ship`, `theme-audit`), it must delegate to `core-skills:verify-changes`. Reimplementing iteration loops, batching, task metadata, or report formatting is a correctness regression — keep that in one place.

A thin-wrapper audit command is ~20-40 lines. The body:

```markdown
---
name: <command-name>
description: <one-line — what this command audits>
disable-model-invocation: true
argument-hint: [path or file to audit]
---

# <Command Title>

<One-paragraph purpose — who runs this, when, what they get>

## How to run

This command delegates to `core-skills:verify-changes` (the cross-stack audit engine) with a pre-filled brief. Emit the brief and hand off:

    verify-changes brief:
      scope: $ARGUMENTS                        # or a sensible default if $ARGUMENTS is empty
      dimensions: [<skills this command covers>]
      depth: <direct | direct+consumers>
      fix: <yes | no>
      source: <stack>-standards:<command-name>

Then stop. The engine runs Phases 2-6.

## What you get back

<2-3 bullet points describing the report shape the user will see — the engine's Phase 5 report, scoped to the dimensions above>
```

**Picking dimensions.** The wrapper's one real responsibility. Examples:

- `web-standards:premium-check` → `dimensions: [craft-guide]`, `depth: direct`, `fix: no`
- `web-standards:theme-audit` → `dimensions: [craft-guide §13]`, `depth: direct`, `fix: no`
- `web-standards:pre-ship` → `dimensions: [ALL web-standards skills]`, `depth: direct+consumers`, `fix: no`
- `flutter-standards:premium-check` → `dimensions: [craft-guide, widget-rules, accessibility, performance]`

When a command audits a **subset** of a skill, use the rule-ID notation (`craft-guide §13`, `craft-guide §9.1-§9.5`). Add or confirm those rule IDs in the skill's SKILL.md — see the "Rule IDs" section below.

**When NOT to thin-wrap.** If the command does something the engine can't express — setup workflows (`extract-tokens`), generative scaffolds (`scaffold-feature`), stack-specific regex scans that don't map to rule IDs (`find-hardcoded`, `find-duplicates`), cross-signal classification (`aesthetic-coherence`) — keep the command standalone. The wrapper pattern is for rule-walking audits, not for everything.

## Rule IDs in standards skills

Auto-invoke standards skills that are referenced as dimensions (notably `craft-guide`, `production-readiness`, `widget-rules`) should number their rules `§N.M` where N is the section and M is the sub-rule. This lets audit commands scope to a subset (`craft-guide §13`) and lets the engine iterate each rule individually without guessing boundaries.

When adding rules to these skills, pick the next unused `§N.M` and keep numbering dense (no gaps). When splitting a rule, use `§N.M.a`, `§N.M.b` rather than renumbering (stable IDs outlive single PRs).

## Adding an enforcement rule (deterministic block)

Enforcement rules block Edit / Write / MultiEdit at the PreToolUse layer when a project has opted in via `.claude/enforcement.json`. They must be deterministic — regex-level checks on file content. Subjective rules (craft, aesthetic, architecture) stay inside standards skills and are enforced at the gate stage, not here.

Per-pack default registries live at `core/plugins/core-hooks/enforcement/<pack>.json`. Add a rule to the `rules` array:

```json
{
  "id": "web.sec.no-target-blank-without-rel",
  "pattern": "target=\"_blank\"(?![^>]*rel=\"[^\"]*noopener)",
  "message": "<a target=\"_blank\"> without rel=\"noopener noreferrer\" — tab-napping risk.",
  "applies_to": "*.tsx,*.jsx"
}
```

- `id` — unique within the pack. Convention `<pack-shortcut>.<category>.<slug>` (shortcuts: `flutter`, `web`, `api`). Used by projects in `disabled_rules` overrides — changing the ID breaks overrides, so pick a good one up front.
- `pattern` — bash grep ERE regex. Escape `\`, `$`, `"` per JSON rules.
- `message` — one line, action-oriented. Shown to Claude in the block stderr.
- `applies_to` — comma-separated file globs. Matched against both full path and basename.

Test locally:

```bash
echo '{"tool_name":"Write","tool_input":{"file_path":"/tmp/test.tsx","content":"<a target=\"_blank\">x</a>"}}' \
  | CLAUDE_PLUGIN_ROOT=/abs/path/to/core-hooks \
    CLAUDE_PROJECT_DIR=/tmp/fake-project \
    bash /abs/path/to/core-hooks/hooks/enforce-rules.sh
```

With `.claude/enforcement.json` containing `{"mandatory":["web-standards"]}` in `/tmp/fake-project`, this should exit 2 with the message on stderr.

No code changes in `core-hooks/hooks/enforce-rules.sh` are needed — rules load automatically from the JSON registry. User-facing doc: [docs/enforcement.md](enforcement.md).

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
- [ ] README / ROADMAP reflect any user-facing change (run `core-skills:docs-sync` if unsure)
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
