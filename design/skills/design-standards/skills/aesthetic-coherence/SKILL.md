---
name: aesthetic-coherence
description: Detect aesthetic mixing — a screen committing to two design languages at once (glassmorphism + neumorphism, bento + brutalist, AI-native + editorial) is the #1 "assembled, not designed" tell. This skill identifies the signals of each aesthetic, flags mixed signatures, and then hands the per-aesthetic spec walk to the audit engine. Use on any surface that feels "off" but passes token and contrast audits.
argument-hint: [component-file-path | page-path | "app"]
---

# Aesthetic Coherence Audit — Web

Detection is a signal-scoring pass (Steps 1–3) — no rule-by-rule equivalent, runs here. Spec compliance (does the detected aesthetic meet `craft-guide §9.x`?) delegates to `core-standards:verify-changes` (Step 4).

---

## Step 0 — Load inputs

1. Read `$ARGUMENTS` (file, page, or whole app).
2. If whole app, enumerate public routes under `app/` (App Router) or `pages/` (Pages Router).
3. Read `design-tokens.md` if present — check for a declared aesthetic.
4. Load `craft-guide` (the §9 Rule Index is the canonical aesthetic list).

---

## Step 1 — Detect aesthetic signals per file

Every aesthetic has a fingerprint — a combination of CSS patterns, component shapes, and motion / color choices. For each file, score presence of each aesthetic. The goal is **classification**, not compliance.

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
- Animated mesh gradients (CSS `@property` + animated gradient stops, or Canvas / WebGL)
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

If the gap is **small** (≤ 30% difference), the file is **mixed** — a FAIL against `craft-guide §9.1` (single aesthetic committed).

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

`UNCLEAR` = no aesthetic signals strong enough to classify — often the file is plain-enough that any aesthetic could drop in. Not necessarily a FAIL.

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

Cross-file mixing is worse than in-file mixing. A modal in glassmorphism inside a brutalist app reads broken — still a FAIL against `craft-guide §9.1`.

---

## Step 4 — Delegate spec compliance to the engine

Once the dominant aesthetic is classified (Step 2 per file, Step 3 cross-file), hand spec compliance to the engine. The rule index at the top of `craft-guide` numbers every §9.x rule, and the per-aesthetic specs live in §9 prose — the engine reads both.

```
verify-changes brief:
  scope: <files classified COMMITTED or MIXED from Steps 1–3>
  dimensions: [craft-guide §9]
  depth: direct
  fix: no
  source: web-standards:aesthetic-coherence
  context:
    aesthetic: <dominant detected or user-confirmed>
```

The engine walks §9.1 (single aesthetic), §9.2 (per-aesthetic specs for the declared aesthetic), §9.3 / §9.4 (glass-specific legibility and reduced-transparency), and §9.5 (per-aesthetic numeric specs) rule-by-rule and reports PASS / FAIL / N_A against the committed aesthetic.

**Critical:** aesthetic choice is user taste — don't invoke the engine with an undetermined aesthetic. If Step 2 leaves the app UNCLEAR or classifications conflict, surface the ambiguity to the user and ask before delegating. Running §9 compliance against a guessed aesthetic is noise.

---

## Step 5 — Aggregate

After detection (Steps 1–3) and compliance (Step 4), produce one combined report:

```
Aesthetic audit — <scope>

DETECTION (Steps 1–3)
  App aesthetic (detected): <X> (from <count> committed files)
  Declared (if any): <Y — from design-tokens.md>
  Match: YES | NO — if NO, which wins? (ask user)

  Mixed files (§9.1 FAIL): <count>
    [list with signal breakdown]

  Outlier files: <count>
    [list of files committed to off-brand aesthetic]

COMPLIANCE (from verify-changes §9 walk)
  [engine's per-rule PASS / FAIL / N_A output]

Verdict:
  - 0 mixed + 0 outliers + 0 §9 FAIL → COHERENT
  - any mixed or outliers → FRAGMENTED
  - only §9 FAILs → COMMITTED-BUT-UNFINISHED
```

---

## Step 6 — Fix loop (never automatic)

Aesthetic fixes are **high-blast-radius** — converting a screen from glassmorphism to minimalist touches most elements. This skill proposes; user approves; only then writes.

1. For each mixed file, propose which aesthetic to keep (strongest signal wins by default; user overrides).
2. List the exact removals / changes per file.
3. Wait for user confirmation per file.
4. Apply only confirmed changes.
5. Re-run Steps 1–3 — confirm no new mixing introduced.

Do **not** invoke the engine with `fix: yes` for this command. Aesthetic is a taste call; rule-driven auto-fix is the wrong loop for this shape of decision.

