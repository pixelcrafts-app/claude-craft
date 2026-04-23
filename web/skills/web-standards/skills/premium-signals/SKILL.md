---
name: premium-signals
description: Apply when building or reviewing web UI for premium polish — exact shadow formulas, border opacity, dark mode gray calibration, easing curves, typography precision, empty state formula, skeleton shimmer, glassmorphism constraints. Overlays craft-guide foundations with market-sourced precise values from Linear, Vercel, Superhuman, Arc, Raycast. Auto-invoke on any new component or page that must feel handcrafted, not template-generated.
---

# Web Premium Signals

Rules derived from auditing Linear, Vercel, Superhuman, Arc Browser, Raycast, Stripe, Things 3. Every value below was found in a shipped product — not generated from design theory.

Craft-guide provides the foundation rules. This skill provides the precise values that separate premium from template within those rules.

---

## SHADOW & DEPTH

### Two-Layer Shadow Formula
Never a single `box-shadow`. Layer two: one ambient + one key-light, both tinted to the surface's background hue (not pure black).

```css
/* Light surface */
box-shadow:
  0 1px 2px rgba(0, 0, 0, 0.05),  /* ambient */
  0 4px 12px rgba(0, 0, 0, 0.08); /* key-light */

/* Dark surface */
box-shadow:
  0 1px 2px rgba(0, 0, 0, 0.20),
  0 4px 12px rgba(0, 0, 0, 0.30);
```

Shadow hue must match the surface's color temperature. Warm-toned surface → warm-tinted shadow (add 3–8% red channel). Cool surface → cool shadow. Pure-black shadows on warm surfaces read as pasted-on.

### Border as Structural Signal
Vercel dark: `border: 1px solid rgba(255, 255, 255, 0.08)` — exactly 8%. Enough to read structure, not enough to add visual weight. Light dashboards: `border-color: var(--gray-200)` (never `#ccc`). The border separates; it does not decorate.

### Elevation via Warmth Shift
Elevated surfaces gain perceived depth through a 3–5% warmer hue shift, not just a lightness change. Too warm = muddy. Too cool = clinical. Apply on card hover states and dropdown surfaces.

### Sidebar Dimming
Non-active navigation items: `opacity: 0.65`. Main content: full opacity. This makes the active work area the visual priority without removing the sidebar from the layout.

---

## COLOR & DARK MODE

### Dark Mode: 5-Step Gray Scale
Five distinct gray levels — not 2–3. Nearer surfaces = lighter gray (more ambient light). Map:

| Level | OKLCH approx | HSL approx | Use |
|---|---|---|---|
| Base | L 0.10 | hsl(240 5% 6%) | Page background |
| Raised | L 0.13 | hsl(240 5% 8%) | Cards |
| Elevated | L 0.16 | hsl(240 5% 10%) | Dropdowns, popovers |
| Overlay | L 0.19 | hsl(240 5% 12%) | Modals |
| Top | L 0.22 | hsl(240 5% 14%) | Tooltips, command palette |

### Dark Mode Contrast Compensation
Secondary text in light mode at `black @ 60%` → dark mode at `white @ 65%` (not 60%). Human eyes perceive less contrast in low-light. Calibrate each text role individually — body, secondary, muted, placeholder — rather than applying a single inversion formula.

### Brand Accent Recalibration
Light-mode accent ≠ dark-mode accent. A purple at `oklch(55% 0.22 270)` in light mode reads as too bright in dark mode — darken by approximately L −5% to L −8%. Copy-pasting the same accent hex into dark mode produces garish results on 5+ of 10 accent colors.

### Accent Restraint Rule
One accent color in the UI. One place on screen. Used for the primary CTA only — not hover states, not focus rings, not borders. Every additional use of the accent dilutes its signal. The accent earns its impact through scarcity.

### Eliminate Default Blue
`#0070f3` or `#0000EE` on interactive elements is the fastest signal that a UI was not designed. Choose a non-default accent. Apply it to exactly one element class (primary buttons). All other interactive states use neutral shifts.

### OKLCH for Color Tokens
Use OKLCH for all token definitions — perceptually uniform (a +10% lightness change looks the same across hues), supports Display P3, used by shadcn/ui, Vercel Geist, Radix Colors.

```css
--primary: oklch(55% 0.22 262);        /* purple */
--primary-hover: oklch(60% 0.22 262);  /* +5% L */
--primary-muted: oklch(55% 0.22 262 / 0.15);
```

### 3-Layer Token Architecture
```
Layer 1 — Primitives: raw scale (--violet-50 through --violet-950)
Layer 2 — Semantic: 35–50 tokens (--color-bg, --color-text-primary, --color-border-subtle)
Layer 3 — Component: scoped overrides (--button-bg, --card-surface) only when semantic layer can't express it
```
Never write component styles against Layer 1 tokens. Never invent Layer 3 tokens when a semantic token exists.

### Hue-Shift State Technique
State changes (hover, active, error, focus) shift hue, not just lightness, for perceived richness:
- Error state: shift hue −10° toward red (not just lightness change)
- Success state: shift +20° toward green

---

## MOTION & MICRO-INTERACTIONS

### Primary Easing Curve
Linear's motion system: `cubic-bezier(0.16, 1, 0.3, 1)` (expo-out). Starts fast, decelerates sharply. Feels snappy without bouncing. Use for all UI transitions (panel open/close, tooltip appear, card entrance).

Spring physics and bouncy easings (`bounce`, overshoot) are appropriate for consumer/playful apps. Productivity tools use expo-out.

### Timing Hierarchy
Three tiers only:
- `200ms` — hover states, button press, toggle
- `300ms` — standard state transitions (panel open/close, tooltip)
- `600ms` — entrance animations (modals, page transitions)

Never the same duration for everything. The difference between 200ms and 300ms is detectable and meaningful to perceived responsiveness.

### Sub-100ms Interaction Guarantee
Every interactive element must produce a visual response in ≤100ms perceived time. This is architecture, not animation. Optimistic updates for all non-destructive user actions. The UI responds before the server confirms.

### Hover Displacement Cap
Maximum hover displacement: `8px`. Translate or scale — not both. More than 8px of movement draws eye away from content rather than signaling interactivity.

### Skeleton Shimmer Exact Values
Shimmer gradient: three stops at `0.1 / 0.3 / 0.4` opacity, moving horizontally, `duration: 1.5s`, `easing: ease-in-out`. Static skeleton is lazy skeleton — if it doesn't shimmer, it reads as a broken loading state.

Skeleton shapes match the exact dimensions and line-count of incoming content — not three generic gray bars.

### Task Completion as Ceremony
Meaningful task completion (form submit, purchase, first completion) gets a dedicated animation window of 200–300ms with a delayed exit (50ms hold before dismiss). Animations for low-value actions (toggle, bookmark) complete in ≤150ms with no ceremony.

---

## TYPOGRAPHY

### Body Size for Dense Tools
Power-user tools (dashboards, admin, productivity apps): default body at `14px / line-height 1.5`. At 14px with 1.5 line-height, text reads comfortably with more content density. Consumer/marketing: 16px.

### Display Tracking
Headlines at 48px+: `letter-spacing: -0.04em`, `line-height: 1.15`. No default type scale produces this — it must be set explicitly. Zero tracking on display type above 40px reads unfinished.

### Monospaced Register for Data
Timestamps, IDs, numbers in tables, metrics, code snippets: monospaced font. The visual register switch (proportional → mono) marks content as "data to be read carefully." Geist Mono for Vercel stack, `font-mono` for others.

### Tabular Numerals — Hard Requirement
`font-variant-numeric: tabular-nums` on any number that:
- Animates or updates in place
- Sits in a column with other numbers
- Represents time, currency, or metrics

Without it, column values jump horizontally as digit widths change. One CSS property; always missing from template UIs.

### Letter-Spacing by Size Band

| Size band | Letter-spacing |
|---|---|
| Labels, all-caps, small UI text | `+0.02em` to `+0.04em` |
| Body (14–18px) | `0` |
| Subheadings (20–32px) | `−0.01em` |
| Display (40–64px) | `−0.025em` to `−0.04em` |
| Hero (64px+) | `−0.04em` to `−0.05em` |

### Font Selection by Context

| Context | Font | Reason |
|---|---|---|
| SaaS dashboard / productivity | Inter | Dominant at 70%+ of premium SaaS — humanist, legible at 14px |
| Developer tools, Vercel ecosystem | Geist | Variable, purpose-built for dense UI, optical sizes |
| Marketing / brand | Söhne | Neutral geometric, high-end brand weight |
| Editorial / content-led | DM Serif Display + Inter | Serif headline + sans body contrast |
| Data / technical | Berkeley Mono or Geist Mono | Premium monospaced for numbers and code |

Never use a system fallback font in a primary display role. Never mix two similar sans-serif families.

---

## LAYOUT & GRID

### 4px Base Grid
The 4px grid (not 8px) allows half-steps (`4, 8, 12, 16, 24, 32, 48`) without visual gaps that appear on strict 8px grids. All margin, padding, gap, icon sizing, and border-radius choices are multiples of 4.

### Border Radius Hierarchy — Tiered, Not Global
One global `border-radius` value is the #1 template tell.

| Element | Radius |
|---|---|
| Inputs, chips, small components | `4–6px` |
| Buttons | `8px` |
| Cards, dropdowns, modals | `12px` |
| Large surfaces, sheets, hero | `16px` |
| Badges, pills | `9999px` |

The smallest interactive elements get the smallest radius. Larger containers get larger radius.

### Hit Target Generosity with Visual Restraint
Controls can look 28px tall while having 44px of click area via internal padding. Compact visual appearance + generous hit area. Never match hit target to visual size exactly on controls that look tight.

---

## AESTHETIC PRECISION VALUES

### Glassmorphism — Overlay Only
`backdrop-filter: blur(12–20px)` with `background: rgba(255, 255, 255, 0.06–0.12)`.

Applied to: overlays, popovers, tooltips, floating panels, navigation drawers.

Never as a primary card style — destroys readability on varied backgrounds. Text on glass requires a solid layer behind it OR background opacity ≥ 0.5.

### SVG Noise on Gradient Surfaces
Gradient backgrounds feel digitally flat without texture. Apply 3–5% opacity SVG noise overlay via `feTurbulence` SVG filter or PNG overlay at `opacity: 0.03–0.05`. Prevents banding. Makes gradients read as printed, not rendered.

```css
.gradient-surface {
  background: linear-gradient(...);
  position: relative;
}
.gradient-surface::after {
  content: '';
  position: absolute;
  inset: 0;
  background-image: url("data:image/svg+xml,..."); /* feTurbulence noise */
  opacity: 0.04;
  pointer-events: none;
}
```

### Bento Grid Exact Values
- `grid-auto-rows: 90px` base row unit
- Gap: `12–20px`
- Tile corner radius: `16–24px`
- Per-tile hover: scale `1.02` + `box-shadow` depth increase, `200ms expo-out`
- Tile size classes: ≤ 4 variants (1×1, 2×1, 1×2, 2×2)

### Minimalist Exact Constraints
- ≤ 2 brand colors + neutral scale + 4 semantic colors
- Whitespace: ≥ 40% of viewport at rest (non-neutral pixels < 60%)
- ≤ 3 type weights app-wide
- One signature design detail per screen maximum — not zero, not three

### Utility-Brutalist (Linear / Vercel) Exact Values
- Dark-first, with light as alternate theme
- Single accent hue (purple, pink, or near-black with undertone)
- Monospace for metadata: timestamps, IDs, version numbers, build info
- Minimal motion: `transition: background 150ms, border-color 150ms` — no entrance animations on data rows
- Border as elevation: `1px solid rgba(255, 255, 255, 0.08)` in dark mode

### Dark Luxury (Premium Dark UI)
- Background: `#0D0D0D` or `#111111` — not `#000`
- Section padding: `64px` vertical
- Single metallic accent (gold `oklch(75% 0.12 80)` or silver `oklch(80% 0.02 240)`)
- Accent used in exactly one role: primary CTA or data highlight only

---

## STATE DESIGN PRECISION

### Empty State Formula
Three parts — all required:
1. One small illustration (monochrome, stroke weight matched to icon system)
2. One sentence: names what's missing + implies benefit of having it
3. One CTA: specific verb + object (not "Get started")

The illustration is never stock SVG, never 3D, never AI-generated clipart. Stroke weight matches the app's icon library stroke weight. If the icon library is 1.5px stroke, the illustration is 1.5px stroke.

### Command Palette Design
- Trigger: `Cmd+K` / `Ctrl+K`
- Dark background modal, `60–70%` viewport width
- Monospaced result metadata (timestamps, keyboard shortcuts)
- Highlighted match characters in accent color
- Recent actions shown before query
- Executes without confirmation steps

---

## WHAT BREAKS THE HANDCRAFTED FEEL

These patterns are detectable at a glance as template-generated:

- **Single `box-shadow`** on cards — single-layer shadow reads as CSS default
- **`border-radius: 8px` everywhere** — one global value with no role hierarchy
- **`#0070f3` interactive elements** — Next.js / React default blue untouched
- **No `font-variant-numeric: tabular-nums`** on dashboard numbers
- **`letter-spacing: 0` on display type** above 40px
- **Three generic gray bars for skeleton** — not shaped like the incoming content
- **Same accent color on hover, focus ring, AND primary button** — accent overuse kills impact
- **Glassmorphism as card style** — readable only as overlay
- **Pure black (`#000`) shadows** on warm surfaces — looks pasted
- **2–3 dark grays** instead of 5-step elevation scale — everything flattens
