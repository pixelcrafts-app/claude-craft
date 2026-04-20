# The Craft Bar

This pack encodes a philosophy. Understanding the philosophy matters more than memorizing any single rule.

## Three principles

### 1. Standards beat taste

Good taste drifts. Three senior engineers on the same team will pick different padding values for cards, different animation durations for transitions, different error-message phrasings. All of those choices are defensible in isolation. In aggregate they make the product feel inconsistent — and inconsistency is what users read as "unfinished".

Standards freeze the decision once. After that, attention goes to harder problems than "what padding should this card have?".

### 2. Skills beat checklists

A written checklist decays. Nobody runs it consistently; some items become outdated; new team members inherit it without context. A year in, the checklist is aspirational.

A skill is executable. You type `/pre-ship` and it runs every check every time. There's no "I ran most of it." It ran, or it didn't. Skills turn discipline into reflex — and reflex is the only form of discipline that survives contact with shipping deadlines.

### 3. One source of truth beats N copies

Every multi-app team we've worked with had drifted from their own "shared" rules. The rules were in a Notion page that was 8 months stale, or a Google Doc that half the team had never opened, or a `.claude/` folder copy-pasted between projects that now disagreed.

The only durable fix is to centralize once and import everywhere, so updates propagate without copy-paste. That's what this repo is: the single source of truth, distributed via the plugin marketplace.

## What the skills do that checklists don't

- They **scan** the codebase — every file, not just the ones you remember
- They **suggest** replacements, not just flag violations
- They **group** findings by severity — fix critical first, nice-to-have later
- They **pair** with each other — `find-hardcoded` + `find-duplicates` cover complementary gaps
- They **explain** — each finding cites the rule and why it matters

A human with a checklist does maybe 60% of what a skill does, and only on the files they thought to check.

## What the rules do that code comments don't

- They capture the **why** — the edge case that caused the rule, the cost of ignoring it
- They stay **one document per concern** — not N comments scattered across N files
- They **are the system prompt** — Claude Code reads them, agents act on them, humans reference them

A rule file is the document you wish had existed when you were onboarding.

## Where taste still matters

Rules set the **floor**, not the ceiling. After you meet the rules, craft comes from:

- **Visual weight balance** — knowing when a heavier title earns the screen
- **Transition continuity** — the path the eye takes from screen A to screen B
- **Tone of empty-state copy** — "No items" vs. "Nothing here yet — tap + to add your first one"
- **Knowing when to break a rule** — because the specific case earns it

Rules prevent regressions. Taste drives excellence. Both are required. This pack handles the floor so your team can spend taste on the ceiling.

## How to extend without diluting

When adding a rule, ask: will **every** app need this, or only some? If only some, it belongs in the app's own `app-level.md`, not here. The pack is only valuable if every rule applies to every consumer.

When adding a skill, ask: will it save **>15 min per run**? If not, it's a script, not a skill.

When deprecating content, ask: is the rule wrong, or is the team frustrated with enforcement? Frustration is not a reason to remove a rule — it's a reason to make the skill catch it earlier.

## The measurement trap

It's tempting to demand metrics before adopting standards: "prove that pre-ship reduces regressions by X%." Don't fall for it.

Most of what standards buy you is **not measurable in advance**. You measure "bugs caught before review" when the standards exist and the skills run. Before that, the baseline is itself unmeasured — you don't know how many bugs shipped because nobody looked.

Adopt the standards. Run the skills. **Then** measure. The order matters.
