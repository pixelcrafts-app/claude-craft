---
name: premium-check
description: Premium craft audit — iterates through every rule in craft-guide against a component or page, outputs PASS / FAIL / N_A per rule, loops until zero failures. Use when a surface must actually be premium, not just look it.
disable-model-invocation: true
argument-hint: [component-file-path]
---

# Premium Craft Audit — Web

Audit `$ARGUMENTS` against the **17-section premium web craft standard**. This is not a spot-check — it iterates every rule, one at a time, with explicit pass/fail and evidence, until zero rules fail.

## Why iteration-loop, not sweep

A single-pass "check everything" audit drops long-tail rules silently. This audit walks each rule explicitly, names the rule, evaluates, records result. Attention cannot skip what the structure forces you to visit.

---

## Step 0 — Load context

1. Read the file (or every file if directory) at `$ARGUMENTS`
2. Glob `**/web-standards/skills/*/SKILL.md` — load **every** standards skill in the pack as review criteria, not just `craft-guide`
3. Identify:
   - The app's detected **aesthetic** (from §9 — ask user if ambiguous; don't guess)
   - The app's detected **density target** (from §8 — app type)
   - The user's design tokens (colors, spacing scale, type scale, radius scale, shadow scale) — read from `tailwind.config.*`, `app/globals.css`, `components/ui/*`, or `CLAUDE.md`

If any of these are unknown, **ask the user** before proceeding. Running the audit without aesthetic and density is guessing.

---

## Step 1 — Rule-by-rule audit

Walk **every section of `craft-guide`** (17 sections). For each section, walk **every rule**. For each rule, output one record.

**Record format:**

```
[SECTION.RULE] <rule name>
  Evidence: <quote from file: line_number or "no occurrence">
  Result: PASS | FAIL | N_A
  Fix (if FAIL): <concrete, minimal suggestion>
```

`N_A` is allowed only with reason — e.g. "no interactive elements in this file, so focus-ring rule does not apply."

### Rules to iterate (mirror of craft-guide structure)

For each rule below, output the record. Do not skip. Do not collapse multiple rules into one record.

**§1 Color**
1.1 Contrast — body ≥ 4.5:1 (measure for every fg/bg pair used)
1.2 Contrast — large text ≥ 3:1
1.3 Contrast — non-text UI ≥ 3:1
1.4 Contrast — placeholder text ≥ 4.5:1
1.5 Contrast verified in dark mode (separate check)
1.6 APCA Lc ≥ 75 for body (premium tier)
1.7 Single color-harmony relationship (not mixed)
1.8 60-30-10 distribution honored
1.9 UI primary derived from brand color (not raw brand color on surfaces)
1.10 Neutrals are hue-tinted, not pure gray
1.11 Gradients — ≤ 3 stops, not complementary
1.12 Pure black/white only if OLED-dark or brutalist
1.13 No hardcoded hex/rgb in source — tokens only
1.14 ≤ 3 accent colors per screen
1.15 Color never sole signal (icon + label pair with state color)

**§2 Spacing**
2.1 Single base unit (4 or 8) — every value on scale
2.2 No arbitrary Tailwind values (`p-[13px]`, `mt-[7]`)
2.3 Same scale for margin / padding / gap
2.4 Touch targets ≥ 44px (≥ 48px premium)
2.5 ≥ 8px gap between adjacent targets
2.6 Gap used inside flex/grid (not margin)

**§3 Typography**
3.1 Every size on the modular scale
3.2 rem for font-size (not px)
3.3 ≤ 2 typefaces
3.4 Heading hierarchy — no skipped levels
3.5 Line-height matches size band
3.6 Letter-spacing rules (negative display, positive all-caps)
3.7 Body measure 45–75ch
3.8 `font-display: swap` on custom fonts
3.9 `<link rel="preload">` on above-fold fonts
3.10 Fallback metrics matched (`size-adjust` / `ascent-override`)
3.11 `font-variant-numeric: tabular-nums` on numeric tables/money/time
3.12 UGC text protected with line-clamp / max-lines

**§4 Shadow & Elevation**
4.1 Every shadow from named scale
4.2 Multi-layer shadow (not single-layer)
4.3 Dark-mode shadow adapted (not same as light)

**§5 Border Radius**
5.1 Every radius from named scale
5.2 Consistent per role (all buttons same, all cards same)
5.3 Nested radius math (inner = outer − padding)
5.4 Radius scale matches aesthetic (brutalist=0, claymorphism=XL, etc.)

**§6 Motion**
6.1 Durations within range (micro 150–250, macro 300–500, page 500–800)
6.2 Exit faster than entry
6.3 Entry = ease-out, exit = ease-in
6.4 No default `ease`
6.5 Only `transform` + `opacity` animated (no `width`/`height`/`top`/`left`)
6.6 `prefers-reduced-motion` respected
6.7 3-layer stack — not everything animating at once

**§7 State Design**
7.1 Loading state (skeleton matching layout, not spinner)
7.2 Skeleton skipped under 200ms
7.3 Empty state (icon + invite + single CTA)
7.4 Error state (specific + retry, no "Error occurred")
7.5 Content state
7.6 Offline state (if app is data-driven)
7.7 Stale / background-refresh state
7.8 Partial / progressive state (if parallel data)
7.9 Pending state (optimistic UI where appropriate + rollback)
7.10 Rate-limited state (if rate-limited APIs)
7.11 Permission-denied state
7.12 Success state (inline small, full-screen milestone)
7.13 Destructive actions confirmed or undo-able
7.14 Disabled state (opacity + cursor + tooltip reason)

**§8 Responsive + Density**
8.1 Mobile-first CSS order
8.2 No horizontal overflow at 320px
8.3 Safe-area insets honored (fixed bars, full-bleed, modals)
8.4 `dvh` used where keyboard can open
8.5 Density matches detected app type
8.6 Tablet not treated as "bigger mobile"
8.7 Primary actions in thumb zone (mobile)
8.8 Wide-screen content width constrained (≤ 1920px)

**§9 Aesthetic Coherence**
9.1 Single aesthetic committed (not mixed)
9.2 Aesthetic-specific specs honored (per the chosen aesthetic's sub-list)
9.3 If glassmorphism — text legibility strategy present (solid layer OR opacity ≥ 0.5)
9.4 If glassmorphism — `prefers-reduced-transparency` fallback

**§10 Iconography**
10.1 One icon family app-wide
10.2 Consistent style (all stroke OR all fill)
10.3 Stroke weight matches body text weight
10.4 Icons on size scale (16/20/24/32)
10.5 Icons use `currentColor` (not hardcoded)

**§11 Chrome & Details**
11.1 Focus ring visible + custom (not default, not `outline: none`)
11.2 `:focus-visible` (not `:focus`)
11.3 `::selection` customized
11.4 Scrollbar styled where visible
11.5 `caret-color` set for inputs
11.6 `cursor: pointer` on all clickable non-links
11.7 Inline loading (button spinner, in-field validation) not full-page
11.8 `-webkit-font-smoothing: antialiased` on body
11.9 Images: fixed aspect ratios, lazy-loaded, blur-up placeholder

**§12 Accessibility**
12.1 Semantic HTML (no `<div onClick>` where `<button>` fits)
12.2 One `<h1>` per page, no skipped levels
12.3 Modal focus trap works (Tab cycles, Esc closes, returns to trigger)
12.4 Logical tab order matches visual order
12.5 `role="status"` / `role="alert"` on dynamic regions
12.6 Images have meaningful `alt` or `alt=""`
12.7 `color-scheme` CSS property set
12.8 `forced-colors` mode honored
12.9 `prefers-reduced-transparency` honored
12.10 `<html lang>` set
12.11 Color-blind safe (icon or label pairs with color signal)

**§13 Theme**
13.1 Every themeable value from CSS var / `@theme`
13.2 Token names are semantic (not `--blue-500`)
13.3 Light and dark independently designed
13.4 SSR hydration flash prevented (blocking script / cookie)
13.5 `color-scheme` set per theme class

**§14 Content & Microcopy**
14.1 Button labels are verbs
14.2 Error messages explain + suggest
14.3 Empty states invite
14.4 Confirmations name the action
14.5 Success is understated
14.6 Loading text, when shown, is specific
14.7 No jargon leaked (HTTP codes, stack traces)
14.8 Numbers / dates / currency localized
14.9 Labels above fields for forms > 3 fields
14.10 Placeholder is example, not label

**§15 Brand Moments** (scope: whole-app, not per-file — only audit if the page is 404, 500, splash, offline, first-run, or update-available)
15.1 404 on-brand + useful actions
15.2 500 apologetic + retry + support
15.3 Splash branded (not generic spinner)
15.4 Offline branded (not browser error)
15.5 First-run empty state designed as moment

---

## Step 2 — Aggregate

After every rule has a record, produce the summary:

```
Audit: <file path>
Aesthetic: <detected>
Density: <detected>

Total rules: <count>
  PASS: <count>
  FAIL: <count>
  N_A: <count with one-line reasons grouped>

Critical failures (must fix): <count>
  [list of 1.1, 1.5, 7.1–7.5, 12.x items that are FAIL]

Polish failures (fix for premium tier): <count>
  [list of remaining FAILs]

Verdict:
  - if FAIL count is 0 → SHIP
  - if only polish failures → SHIPS-BUT-UNFINISHED
  - if any critical failure → BLOCK
```

---

## Step 3 — Fix loop (only if user asked to fix, not just audit)

If `$ARGUMENTS` or user message included `--fix` or equivalent intent:

1. Fix every FAIL — smallest minimal change per rule
2. Re-run Step 1 from the top
3. If new FAILs appear (a fix introduced a new violation), fix those
4. Loop until PASS for every rule
5. Report final summary + list of changes made

Never claim "fixed" without rerunning the audit. A fix that introduces a regression is not a fix.

---

## Disadvantages (read before running on large surfaces)

- **Token cost scales linearly with rule count** — ~150 rules × record overhead per rule. Expensive on big codebases. Scope to one file at a time.
- **Long output** — summary is the signal; the per-rule records are the evidence trail, not the thing to read end-to-end.
- **Over-reporting** — rules that genuinely don't apply still need `N_A` records. Tolerable cost for the guarantee.
- **Not a replacement for a browser** — contrast math and motion timing need the real render to confirm. This catches most misses; the final mile is visual.
- **Doesn't catch novel categories** — rules-based audit only finds what rules describe. New aesthetic failure modes (e.g. tomorrow's design trend) still need human eyes.

---

## Scope boundaries

This audit **enforces discipline**. It does not:

- Impose colors, fonts, aesthetics — those come from the user / design system
- Rewrite the brand
- Refactor beyond the rules that FAILed
- Block on user-chosen deviations (e.g. pure black acceptable if aesthetic is Brutalist or app is OLED-dark)

When aesthetic or tokens are unknown, ask the user — don't guess, don't impose defaults.
