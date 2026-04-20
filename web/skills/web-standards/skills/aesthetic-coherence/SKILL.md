---
name: aesthetic-coherence
description: Detect aesthetic mixing — a screen committing to two design languages at once (glassmorphism + neumorphism, bento + brutalist, AI-native + editorial) is the #1 "assembled, not designed" tell. This skill identifies the signals of each aesthetic, flags mixed signatures, and recommends a single aesthetic commitment. Use on any surface that feels "off" but passes token and contrast audits.
disable-model-invocation: true
argument-hint: [component-file-path | page-path | "app"]
---

# Aesthetic Coherence Audit — Web

An app with perfect tokens, perfect contrast, perfect motion — and two aesthetics fighting — still reads as amateur. This skill catches that.

---

## Step 0 — Load inputs

1. Read `$ARGUMENTS` (file, page, or whole app)
2. If whole app, enumerate public routes under `app/` (App Router) or `pages/` (Pages Router)
3. Read `design-tokens.md` if present — check for a declared aesthetic
4. Load `craft-guide` §9 (Aesthetic Coherence) as the authoritative list

---

## Step 1 — Detect aesthetic signals per file

Every aesthetic has a fingerprint — a combination of CSS patterns, component shapes, and motion/color choices. For each file, score presence of each aesthetic:

### Minimalist — signals
- `backdrop-filter` usage = 0
- Shadow tokens used ≤ 2 levels
- ≤ 2 brand colors active on-screen
- Whitespace ratio visibly high (heuristic: ≤ 40% of viewport has non-neutral pixels)
- Border-radius small-to-medium (4–12px)
- No decorative gradients

### Flat — signals
- Shadow count = 0 (across all visible elements)
- Solid color fills everywhere
- Borders present (1px, token-color)
- No decorative effects

### Material — signals
- Multi-level shadow scale used (≥ 3 levels)
- Solid colors + elevation
- Ripple / wave interaction motions
- `fab` / floating-action-button patterns

### Utility-brutalist (Linear / Vercel / Railway) — signals
- Monospace in metadata (`font-mono` or `font-family: *mono*`)
- Horizontal-rule-heavy tables
- Dark-first (default `.dark` with light as alternate)
- Single accent hue (purple / pink / blue)
- Minimal motion (`transition: none` or `0ms` common)
- Subtle borders + tinted neutrals

### Glassmorphism — signals
- `backdrop-filter: blur(...)` present
- `background-color` with alpha 0.1–0.3
- Subtle white/black 0.05–0.15 alpha borders
- Layered translucent surfaces

### Neumorphism — signals
- Dual box-shadow on same-surface-color elements (one light offset + one dark offset)
- Same background between container and element (no border, no distinct fill)
- Primarily on interactive elements (buttons, cards)

### Claymorphism — signals
- Border-radius > 16px on most surfaces
- Saturated-but-soft fills
- Multi-layer inner + outer shadow
- Playful / consumer-app vocabulary

### Liquid Glass (Apple iOS 26) — signals
- `backdrop-filter` + animated specular highlights (moving gradient overlays)
- Spring-motion everywhere (`transition-timing-function: cubic-bezier(0.5, 1.25, ...)` spring approximations)
- Translucent chrome with fluid shape morphing

### Bento grid — signals
- CSS Grid with `col-span` / `row-span` varying per child
- Uniform border-radius (16–24px) across tiles
- Per-tile hover micro-interaction (scale, glow, reveal)
- ≤ 4 tile-size classes

### Editorial — signals
- Type ratio ≥ 1.5 (detected from declared scale)
- Serif in display OR two-sans contrast pair
- Body measure capped 55–70ch (`max-w-prose` or similar)
- Visible or implied grid

### Brutalist — signals
- Pure `#000` / `#fff` used
- System / monospace font families
- Border-radius = 0 everywhere
- Shadow = 0 everywhere
- Deliberate asymmetric layouts

### Dark-cinematic — signals
- True `#000` or near-black background
- Heavy color grading (saturated accents with desaturated base)
- Glow / bloom effects
- Hero-image or video-forward compositions

### AI-native — signals
- Animated mesh gradients (CSS `@property` + animated gradient stops, or Canvas/WebGL)
- 3D orb elements
- Soft particle motion
- Dark with bright accent bloom

### Retro / Y2K — signals
- Chrome / metallic gradients
- Pixel fonts or pixel-style borders
- Skeuomorphic iconography

---

## Step 2 — Classify dominant signature

Per file, pick top 2 aesthetic scores. If the gap between #1 and #2 is **large**, the file commits — healthy.

If the gap is **small** (≤ 30% difference), the file is **mixed** — a FAIL.

Output:

```
File: <path>
  Dominant: <aesthetic> (score X)
  Secondary: <aesthetic> (score Y)
  Gap: Z%
  Verdict: COMMITTED | MIXED | UNCLEAR
  Evidence:
    - <aesthetic A>: <signal found at file:line>
    - <aesthetic B>: <signal found at file:line>
```

`UNCLEAR` means no aesthetic signals strong enough to classify — often the file is plain-enough that any aesthetic could drop in. Not necessarily a FAIL.

---

## Step 3 — Cross-file coherence

If `$ARGUMENTS` was `app` or a directory, aggregate per-file verdicts:

```
App-wide aesthetic: <pick of most-committed files>
Outliers (committed to different aesthetic than app):
  - <file> committed to <aesthetic> while app commits to <aesthetic>
Mixed files:
  - <file> with gap <Z%>
```

Cross-file mixing is worse than in-file mixing. A modal in glassmorphism inside a brutalist app reads broken.

---

## Step 4 — Check per-aesthetic specs (from craft-guide §9)

For the **declared** or **detected** app-level aesthetic, iterate the sub-spec list and output PASS / FAIL per rule:

### If Minimalist
- [ ] ≤ 2 brand colors + neutrals
- [ ] Whitespace ≥ 40%
- [ ] ≤ 3 type weights app-wide
- [ ] No ornamental elements
- [ ] ≤ 1 signature detail per screen

### If Glassmorphism
- [ ] `backdrop-blur` 8–24px
- [ ] Background opacity 0.1–0.3
- [ ] Subtle border 0.05–0.15 alpha
- [ ] Text legibility — solid layer behind OR opacity ≥ 0.5
- [ ] `prefers-reduced-transparency` fallback
- [ ] ≤ 3 blur elevation tiers

### If Neumorphism
- [ ] Dual shadow on interactive elements only
- [ ] Never on text
- [ ] Contrast audit pass (primary failure mode)

### If Bento
- [ ] Radius 16–24px
- [ ] ≤ 4 tile-size classes
- [ ] Per-tile hover interaction
- [ ] Consistent internal padding

### If Editorial
- [ ] Type ratio ≥ 1.5
- [ ] Body measure 55–70ch
- [ ] Serif + sans or two contrasting sans

### If Brutalist
- [ ] Pure black/white OR near-black/white allowed
- [ ] System / mono fonts
- [ ] Radius = 0
- [ ] Shadow = 0
- [ ] Deliberate asymmetry

### If Utility-brutalist
- [ ] Monochromatic + single accent
- [ ] Monospace for metadata
- [ ] Dense tables with horizontal rules
- [ ] Minimal motion
- [ ] Dark-first

### If Liquid Glass
- [ ] `backdrop-filter` present
- [ ] Specular highlight motion
- [ ] Spring motion throughout

### If AI-native
- [ ] Mesh gradient present
- [ ] Content surface still readable over gradient (contrast check)
- [ ] Over-decoration guard (≤ 2 decorative layers per surface)

---

## Step 5 — Aggregate

```
Aesthetic audit — <scope>

Detected app aesthetic: <X> (from <count> committed files)
Declared (if any): <Y — from design-tokens.md>
Match: YES | NO — if NO, which wins? (ask user)

Mixed files: <count>
  [list with signal breakdown]

Outlier files: <count>
  [list of files committed to off-brand aesthetic]

Per-aesthetic spec: X PASS / Y FAIL
  [list of failing specs with file:line]

Verdict:
  - 0 mixed + 0 outliers + 0 spec FAIL → COHERENT
  - any mixed or outliers → FRAGMENTED
  - only spec FAILs → COMMITTED-BUT-UNFINISHED
```

---

## Step 6 — Fix loop (if `--fix`)

Aesthetic fixes are **high-blast-radius** — converting a screen from glassmorphism to minimalist touches most elements. This skill proposes; user approves; only then writes.

1. For each mixed file, propose which aesthetic to keep (strongest signal wins by default; user overrides)
2. List the exact removals / changes per file
3. Wait for user confirmation per file
4. Apply only confirmed changes
5. Re-run Step 1 — confirm no new mixing introduced

**Do not** rewrite components the user didn't confirm. Aesthetic is a taste call; this skill flags, user decides.

---

## Scope boundaries

- Does **not** pick an aesthetic for the user
- Does **not** rewrite files without per-file confirmation
- Does **not** block a deliberately-chosen "signature mix" if the user documents it (e.g. "editorial body + bento hero is intentional for this landing page")
- Does **not** impose the taste of any one aesthetic (no "minimalist is better than bento")

Aesthetics are equal. Coherence within a chosen one is the standard.

---

## Tradeoffs

- **Signal detection is heuristic** — a single `backdrop-filter` doesn't prove glassmorphism. Low-signal files return `UNCLEAR`, not a forced classification.
- **Aesthetic labels drift** — "AI-native" in 2026 will likely rename by 2028. The signals outlive the labels.
- **Cross-file signal requires reading many files** — expensive on large apps. Scope to `components/ui` or a feature folder for faster runs.
- **Spec-list is opinionated but not exhaustive** — each aesthetic has deeper communities of practice; this audit catches the 80% giveaways, not every nuance.
- **Fix loop is manual-confirmation** — unlike token or contrast fixes, aesthetic rewrites need designer judgment. This skill will not auto-rewrite.
