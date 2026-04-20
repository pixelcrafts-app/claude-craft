---
name: extract-tokens
description: Extract the user's design tokens (colors, type scale, spacing, radius, shadow, motion) from their codebase or design inputs and write them into a single source-of-truth file. Use before any craft audit — the audit needs the user's tokens to check against. Never imposes values.
disable-model-invocation: true
argument-hint: [optional: path-to-design-input | "from-codebase" | "from-figma-url"]
---

# Extract Tokens — Web

The craft audit needs tokens to check against. This skill establishes them.

Three modes. Pick whichever matches what the user provides.

---

## Mode 1 — From existing codebase

Default. No arguments.

### Step 1.1 — Scan sources of truth

Look, in this order, for what the project already declares:

1. **Tailwind config** — `tailwind.config.{js,ts,cjs,mjs}` → `theme.extend.{colors, fontFamily, fontSize, spacing, borderRadius, boxShadow}`
2. **CSS @theme** — `app/globals.css`, `src/styles/globals.css` — Tailwind v4 `@theme { --color-*, --spacing-*, --font-*, ... }`
3. **CSS custom properties** — `:root { --primary: ... }` and `.dark { --primary: ... }`
4. **shadcn-style `components/ui/*`** — token usages hint at scale
5. **Figma export JSON / Tokens Studio** — if committed under `tokens/` or `design-tokens/`
6. **CLAUDE.md** — project may declare aliases, prefixes, ratios

Read each. Do not infer. If Tailwind v4 `@theme` is used, that's the source; ignore defaults.

### Step 1.2 — Categorize

Produce a normalized token map across six dimensions:

```
Colors
  Brand hue(s)              — raw values from user
  UI primary                — derived or same as brand
  Neutrals                  — full ladder (50 → 950), tint-hue
  Semantic                  — success / warning / error / info
  Surfaces                  — background / card / elevated / muted
  Borders                   — default / subtle / strong
  Text                      — foreground / muted / disabled

Typography
  Font families             — display, body, mono
  Size scale                — raw values + detected ratio
  Weight scale              — weights in use
  Line-height bands         — by size band

Spacing
  Base unit                 — detected (4 or 8)
  Scale                     — all declared steps
  Container max-widths      — per breakpoint

Radius
  Scale                     — none / sm / md / lg / xl / full

Shadow
  Elevation scale           — none / sm / md / lg / xl
  Multi-layer?              — detect if shadows stack

Motion
  Duration tokens           — micro / macro / page
  Easing tokens             — entry / exit / spring / linear
```

### Step 1.3 — Detect missing dimensions

For each category, flag what's **missing**:

- No shadow scale declared → app probably hardcodes `shadow` per-component
- No motion tokens declared → timings probably scattered across files
- No semantic color tokens → errors probably hardcoded `#FF0000`

Missing dimensions become candidates for new tokens — but never invent values. Ask the user.

### Step 1.4 — Detect violations

Grep the codebase for values that should have come from tokens:

```
rg "hsl\([0-9 ,.]+ *\)"            — inline HSL outside theme
rg "#[0-9a-fA-F]{3,8}"             — inline hex in *.tsx / *.css
rg "\[[0-9]+px\]"                  — arbitrary Tailwind (`p-[13px]`)
rg "rgba?\("                       — inline rgba
rg "box-shadow:" --type css        — non-token shadows
rg "transition-duration: *[0-9]"   — inline motion values
```

Each match is a **token-drift hit** — count per category, list top 10 per category with file:line.

---

## Mode 2 — From user-provided design input

Trigger: user passes a file path, an image, a Figma export, a brand guide PDF, or pastes token values.

### Step 2.1 — Parse the input

- **Image / screenshot** — extract dominant colors (k-means, 5–7 colors), identify type-like text blocks, measure spacing gaps. Propose these as *candidate* tokens; never assert final.
- **Figma export JSON / Tokens Studio / Style Dictionary** — normalize keys to this pack's categories.
- **Brand PDF** — pull hex values, typography specs, spacing rules if stated.
- **Pasted list** — normalize whatever the user gave into the six-dimension map above.

### Step 2.2 — Reconcile with codebase

If project already has tokens, diff the user's input against the existing:

```
Conflict: Primary color
  Existing (tailwind.config.ts):  hsl(222 80% 55%)
  Provided (brand.pdf page 3):    #3A6FE0  →  hsl(220 75% 56%)
  Recommendation: close enough to unify; ask user which wins
```

Never silently overwrite.

---

## Mode 3 — From Figma URL

If the user gives a Figma link:

- The Figma MCP is not part of this pack — check `.claude/settings.json` for any `figma-*` MCP
- If present, use it to pull styles + variables
- If not, ask the user to export styles as JSON (`Tokens Studio → Export`) and use Mode 2
- Never scrape rendered Figma pages

---

## Output — single source-of-truth file

Write to `design-tokens.md` at the project root (or `docs/design-tokens.md` if `docs/` exists):

```markdown
# Design Tokens

Source of truth for the craft audit. Generated YYYY-MM-DD by /web-standards:extract-tokens from <source>.

## Aesthetic
<detected-or-user-declared>

## Density target
<detected-or-user-declared — from §8 craft-guide>

## Color

### Brand
- primary (brand): <value> → used in <where>
- primary (UI derived): <value> → used in <where>

### Neutrals (tint hue: <hue>)
50 / 100 / 200 / ... / 950 — <values>

### Semantic
- success / warning / error / info — <values>

### Surfaces
- background / card / elevated / muted — <values>

### Light mode / Dark mode pairs
| Token | Light | Dark |
|---|---|---|

## Typography
- Display family: <value>
- Body family: <value>
- Mono family: <value>
- Size scale: base <value>, ratio <value>, steps [...]
- Weights in use: [...]
- Line-heights: body <value>, large <value>, display <value>

## Spacing
- Base unit: <4 or 8>
- Scale: [...]
- Container max: mobile / tablet / desktop / wide — <values>

## Radius
- none / sm / md / lg / xl / full — <values>
- Role map: buttons=<value>, cards=<value>, modals=<value>, avatars=full

## Shadow (elevation)
- none / sm / md / lg / xl — <multi-layer CSS per token>

## Motion
- Duration: micro <value>, macro <value>, page <value>
- Easing: entry <value>, exit <value>, spring <value>

---

## Drift report (findings, not enforcement)

Missing: <dimensions the project has no tokens for>
Inline violations: <count per category, top 10 per category with file:line>

## Verification
- [ ] User confirmed the primary / neutral hue choices
- [ ] User confirmed the aesthetic + density
- [ ] User confirmed missing-dimension defaults (or declined — documented)
```

After writing, `/web-standards:craft-guide` and `/web-standards:premium-check` auto-invoke will read this file when present.

---

## What this skill refuses to do

- Pick colors the user didn't give (brand hue, UI primary, neutrals)
- Pick an aesthetic — detection only, with "tell me" when ambiguous
- Pick a density — ask app type
- Rewrite `tailwind.config` or `globals.css`
- Overwrite user-declared tokens without asking

If the user explicitly asks to pick defaults — proceed but surface each default as "I chose X because Y — say so if wrong." Never silent defaults.

---

## Tradeoffs

- **Heuristic color extraction from images is approximate** — k-means colors are a starting point, not final. Always pass through user confirmation.
- **Tailwind v4 vs v3 token shapes differ** — this skill reads both but normalizes to one schema; if the project is on v4, prefer `@theme` as the authoritative source.
- **Figma parity requires the MCP** — without it, user must export. Not auto-pulled.
- **One-shot artifact** — `design-tokens.md` is generated once then human-maintained. Re-run when brand/theme changes materially; don't run per-commit.
