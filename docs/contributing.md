# Contributing

Thanks for considering a contribution. This is a short guide — edit flow, naming, review checklist.

## Repo layout

```
flutter/skills/flutter-standards/     Flutter pack — bundle plugin
api/skills/api-standards/             API pack — bundle plugin
web/skills/web-standards/             Web pack — bundle plugin
core/plugins/core-hooks/              Cross-stack hooks — secret/shell/token-value blocks, enforcement-mode gate, delegation warmth check, session-start mechanics
core/plugins/core-standards/             Engine + universal skills — verify-changes, principles, planning, agents, rules, verification, mcp-integration, docs-sync, subagent-brief
scripts/export.sh                     Export to Cursor / AGENTS.md
.claude-plugin/marketplace.json       Marketplace index (5 plugins)
```

Rules live **inside** `SKILL.md` bodies — not as separate `*.md` files. The frontmatter `description:` on a standards skill drives auto-invocation; the body is what Claude reads.

## Naming

- **Marketplace source** — `pixelcrafts-app/claude-craft`
- **Plugin per stack** — `<stack>-standards` (`flutter-standards`, `api-standards`, `web-standards`)
- **Cross-stack** — `core-hooks` (hooks only) and `core-standards` (skills only); neither has a stack prefix — both apply to every language
- **Slash commands** — namespaced per pack: `/flutter-standards:pre-ship`, `/api-standards:sync-migrate`, `/web-standards:premium-check`

## Editing a skill

One copy. No build step. Edit and commit:

1. Edit the skill file — the path depends on which plugin owns it:
   - Stack pack: `<stack>/skills/<stack>-standards/skills/<name>/SKILL.md`
   - Cross-stack skill: `core/plugins/core-standards/skills/<name>/SKILL.md`
   - Cross-stack hook: `core/plugins/core-hooks/hooks/<name>.sh` (plus registration in `core/plugins/core-hooks/.claude-plugin/plugin.json`)
2. Bump `version` in:
   - The owning plugin's `.claude-plugin/plugin.json`
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

**Audit commands do not reimplement the engine.** If the command's job is "walk the rules, report pass/fail, maybe fix" (e.g. `premium-check`, `pre-ship`, `theme-audit`), it must delegate to `core-standards:verify-changes`. Reimplementing iteration loops, batching, task metadata, or report formatting is a correctness regression — keep that in one place.

A thin-wrapper audit command is ~20-40 lines. The body:

```markdown
---
name: <command-name>
description: <one-line — what this command audits>
argument-hint: [path or file to audit]
---

# <Command Title>

<One-paragraph purpose — who runs this, when, what they get>

## How to run

This command delegates to `core-standards:verify-changes` (the cross-stack audit engine) with a pre-filled brief. Emit the brief and hand off:

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
  "id": "web.sec.no-dangerous-html",
  "pattern": "dangerouslySetInnerHTML",
  "message": "dangerouslySetInnerHTML is an XSS vector — sanitize input upstream or render safely.",
  "applies_to": "*.tsx,*.jsx"
}
```

- `id` — unique within the pack. Convention `<pack-shortcut>.<category>.<slug>` (shortcuts: `flutter`, `web`, `api`). Used by projects in `disabled_rules` overrides — changing the ID breaks overrides, so pick a good one up front.
- `pattern` — bash grep ERE regex. Escape `\`, `$`, `"` per JSON rules. ERE does not support lookaround — rules requiring "X without Y" context cannot be expressed here; keep those in standards skills.
- `message` — one line, action-oriented. Shown to Claude in the block stderr.
- `applies_to` — comma-separated file globs. Matched against both full path and basename.

Test locally:

```bash
echo '{"tool_name":"Write","tool_input":{"file_path":"/tmp/test.tsx","content":"<div dangerouslySetInnerHTML={{__html:x}} />"}}' \
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
argument-hint: [optional-arg]
---
```

Keep the description narrow and explicit so it does not fire on ambient context — these skills are user-invoked via `/<stack>-standards:<name>`.

Then: add a card to `docs/skills.md`, bump versions, add a changelog line.

## Adding a new pack

A new pack is a new top-level folder (`database/`, `rust/`, etc.) mirroring the `flutter/`, `api/`, `web/` layout:

1. Create `<stack>/skills/<stack>-standards/` with standards + explicit skills
2. Add the plugin to `.claude-plugin/marketplace.json`
3. Add a case to `scripts/export.sh` so Cursor/Antigravity consumers can generate tool-native files
4. Document the pack in `docs/skills.md`
5. Bump minor version, add a changelog entry

Before duplicating universal content (DRY, testing pyramid, observability, security) into a new pack, check if it should be extracted to a shared cross-stack plugin first. A `core-standards` plugin is planned for this purpose — see [ROADMAP](../ROADMAP.md). Until it exists, flag the duplication in the PR so it can be lifted in one pass later.

## Design principles

- **Pack-universal** — a rule belongs in a pack only if every project using that stack would reasonably want it. Anything narrower (one client's style, one app's workflow) belongs in the consumer project's `CLAUDE.md`, not here.
- **Non-destructive by default** — a standards skill reports and suggests, it does not silently rewrite. Follow Detect → Check → Suggest: name the gap, show options with tradeoffs, let the user decide. Skills that *do* mutate code (scaffolds, fix passes) must be explicit slash commands with narrow descriptions — never auto-invoke standards. Control invocation scope through description design, not flags.
- **Principle-first** — state the rule abstractly enough that a capable reader can apply it to any codebase in the pack's stack. Reach for a concrete example only when the abstraction alone is genuinely ambiguous; default is no example. Avoid "Bad: X / Good: Y" dialogs, named-API illustrations, and scenario narratives — they bias readers toward the illustrated case and read as condescending.
- **Description as trigger** — an auto-invoke skill's `description` frontmatter is what Claude matches against to load the skill. Write it as a condition Claude can recognise from file type or task intent ("Apply when editing …", "Use when …"), not as marketing copy. If the description can't be phrased as a matcher, the skill probably wants to be an explicit slash command instead.
- **Self-contained** — a SKILL.md must stand alone. Do not assume other skills are installed, and do not cross-reference skill internals by `§N.M` from outside the owning skill unless that ID is explicitly documented as stable.
- **No PII, no downstream-consumer names** — this is a public repo. The marketplace owner (`pixelcrafts`) is part of the repo identity and fine to use. What must never appear: real client names, internal product codenames, names/emails of real users, or any data that could be traced to a specific consumer project.
- **One concern per skill** — if a standards skill reads like two rulebooks glued together, split it. A skill's `description` should be expressible in one sentence without an "and".

## Review checklist

- [ ] Version bumped (plugin.json + marketplace.json)
- [ ] Changelog entry added
- [ ] `docs/skills.md` updated if behavior changed
- [ ] README / ROADMAP reflect any user-facing change (run `core-standards:docs-sync` if unsure)
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
