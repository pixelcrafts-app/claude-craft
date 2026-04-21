---
name: craft-guide
description: Apply when designing, reviewing, or polishing web UI — color + contrast + harmony, spacing rhythm, type scale, font loading, shadow and radius scales, motion choreography, state design (all variants), responsive density by app type, safe-area handling, aesthetic coherence, iconography, chrome details, theme discipline, microcopy, brand moments. Auto-invoke whenever generating or evaluating Next.js / React / Tailwind / shadcn UI for craft quality. Enforces universal formulas — never imposes brand values.
---

# Premium Web Craft Guide

> Universal principles for Next.js + React + Tailwind + shadcn. Adaptable to any brand.
> **Formulas are universal. Values come from the user.** We enforce discipline, not aesthetics.

---

## THE PROMISE

Premium isn't a feeling added at the end. It's the absence of errors the user would only notice subconsciously: a misaligned pixel, a gray that's too dead, a focus ring that went missing, a `#FF0000` error that shouts. This guide is how we earn the verdict before the user realizes they're giving it.

---

## THE ONLY REAL RULE

**Design formulas are universal — brand values are yours.**

We enforce *whatever you chose is applied consistently*. If a rule fights your brand, your brand wins. But "it fights our brand" is not the same as "we skipped the discipline."

---

## Rule Index (§1.1 – §15.5)

This is the canonical enumeration of every enforceable rule in this guide. Each rule has a stable `§N.M` ID. Audit skills (e.g. `verify-changes`, `pre-ship`) iterate this list. Prose sections below carry the full context — the index is the machine-readable entrypoint. When a rule is split, use `§N.M.a` / `§N.M.b` rather than renumbering; IDs are stable.

**§1 Color**
- §1.1 Contrast — body text ≥ 4.5:1
- §1.2 Contrast — large text (18pt+ regular / 14pt+ bold) ≥ 3:1
- §1.3 Contrast — non-text UI (icons, borders, focus rings, inputs) ≥ 3:1
- §1.4 Contrast — placeholder text ≥ 4.5:1
- §1.5 Contrast verified in dark mode (separate check — light-pass ≠ dark-pass)
- §1.6 APCA Lc ≥ 75 for body text (premium tier)
- §1.7 Single color-harmony relationship committed (not mixed)
- §1.8 60-30-10 distribution honored (dominant / secondary / accent)
- §1.9 UI primary derived from brand color (not raw brand color on surfaces)
- §1.10 Neutrals are hue-tinted (5–15% saturation of chosen hue), not pure gray
- §1.11 Gradients ≤ 3 stops, not complementary pairs
- §1.12 Pure black / pure white only in OLED-dark or brutalist aesthetics
- §1.13 No hardcoded hex / rgb in source — tokens only
- §1.14 ≤ 3 accent colors per screen
- §1.15 Color never sole signal (pair with icon or label for state)

**§2 Spacing**
- §2.1 Single base unit (4 or 8) — every value on scale
- §2.2 No arbitrary Tailwind values (`p-[13px]`, `mt-[7]`)
- §2.3 Same scale for margin / padding / gap
- §2.4 Touch targets ≥ 44px (≥ 48px premium)
- §2.5 ≥ 8px gap between adjacent targets
- §2.6 Gap used inside flex / grid (not margin for layout)

**§3 Typography**
- §3.1 Every font-size on the modular scale
- §3.2 rem for font-size (not px)
- §3.3 ≤ 2 typefaces (display + body, or one variable font)
- §3.4 Heading hierarchy — no skipped levels (H2 → H4 breaks outline)
- §3.5 Line-height matches size band (body 1.5–1.7, display 1.0–1.1)
- §3.6 Letter-spacing rules (negative on display, positive on all-caps / small labels)
- §3.7 Body measure 45–75ch
- §3.8 `font-display: swap` on custom fonts
- §3.9 `<link rel="preload">` on above-fold fonts
- §3.10 Fallback metrics matched (`size-adjust` / `ascent-override`) to prevent CLS
- §3.11 `font-variant-numeric: tabular-nums` on numeric tables / money / time
- §3.12 UGC text protected with line-clamp / max-lines

**§4 Shadow & Elevation**
- §4.1 Every shadow from named scale (3–5 levels)
- §4.2 Multi-layer shadow composition (not single-layer)
- §4.3 Dark-mode shadow adapted (not same as light)

**§5 Border Radius**
- §5.1 Every radius from named scale
- §5.2 Consistent per role (all buttons same, all cards same)
- §5.3 Nested radius math honored (inner = outer − padding)
- §5.4 Radius scale matches aesthetic (brutalist = 0, claymorphism = XL, etc.)

**§6 Motion**
- §6.1 Durations within range (micro 150–250 / macro 300–500 / page 500–800ms)
- §6.2 Exit slightly faster than entry
- §6.3 Entry = ease-out, exit = ease-in
- §6.4 No default `ease` curve
- §6.5 Only `transform` + `opacity` animated (no width / height / top / left)
- §6.6 `prefers-reduced-motion` respected
- §6.7 3-layer stack — not everything animating at once

**§7 State Design**
- §7.1 Loading state (skeleton matching layout, not spinner)
- §7.2 Skeleton skipped under 200ms
- §7.3 Empty state (icon / illustration + invite + single CTA)
- §7.4 Error state — specific + actionable + retry (no "Error occurred")
- §7.5 Content state designed (happy path)
- §7.6 Offline state (if app is data-driven)
- §7.7 Stale / background-refresh state
- §7.8 Partial / progressive state (if parallel data)
- §7.9 Pending state (optimistic UI where appropriate + rollback)
- §7.10 Rate-limited state (if rate-limited APIs exist)
- §7.11 Permission-denied state (distinct from generic error)
- §7.12 Success state (inline small, full-screen for milestones)
- §7.13 Destructive actions confirmed or undo-able
- §7.14 Disabled state (opacity ≥ 0.4 + cursor:not-allowed + tooltip reason)

**§8 Responsive + Density**
- §8.1 Mobile-first CSS order
- §8.2 No horizontal overflow at 320px
- §8.3 Safe-area insets honored (fixed bars, full-bleed, modals)
- §8.4 `dvh` used where keyboard can open the viewport
- §8.5 Density matches detected app type
- §8.6 Tablet not treated as "bigger mobile"
- §8.7 Primary actions in thumb zone (mobile)
- §8.8 Wide-screen content width constrained (≤ 1920px)

**§9 Aesthetic Coherence**
- §9.1 Single aesthetic committed (not mixed)
- §9.2 Aesthetic-specific specs honored (per the chosen aesthetic's sub-list below)
- §9.3 If glassmorphism — text legibility strategy present (solid layer OR opacity ≥ 0.5)
- §9.4 If glassmorphism — `prefers-reduced-transparency` fallback
- §9.5 Per-aesthetic numeric specs within range (blur, opacity, radius) — see section 9 prose

**§10 Iconography**
- §10.1 One icon family app-wide
- §10.2 Consistent style (all stroke OR all fill)
- §10.3 Stroke weight matches body text weight
- §10.4 Icons on a fixed size scale (16 / 20 / 24 / 32)
- §10.5 Icons use `currentColor` (not hardcoded colors)

**§11 Chrome & Details**
- §11.1 Focus ring visible + custom (not default, not `outline: none`)
- §11.2 `:focus-visible` (not `:focus`)
- §11.3 `::selection` customized
- §11.4 Scrollbar styled where visible
- §11.5 `caret-color` set for inputs
- §11.6 `cursor: pointer` on all clickable non-links
- §11.7 Inline loading (button spinner / in-field) not full-page
- §11.8 `-webkit-font-smoothing: antialiased` on body
- §11.9 Images — fixed aspect ratios, lazy-loaded, blur-up placeholder

**§12 Accessibility**
- §12.1 Semantic HTML (no `<div onClick>` where `<button>` fits)
- §12.2 One `<h1>` per page, no skipped levels
- §12.3 Modal focus trap works (Tab cycles, Esc closes, focus returns)
- §12.4 Logical tab order matches visual order
- §12.5 `role="status"` / `role="alert"` on dynamic regions
- §12.6 Images have meaningful `alt` or `alt=""`
- §12.7 `color-scheme` CSS property set
- §12.8 `forced-colors` mode honored
- §12.9 `prefers-reduced-transparency` honored
- §12.10 `<html lang>` set
- §12.11 Color-blind safe (icon or label pairs with color signal)

**§13 Theme**
- §13.1 Every themeable value from CSS var / `@theme`
- §13.2 Token names are semantic (role-based, not `--blue-500`)
- §13.3 Light and dark independently designed (not computed invert)
- §13.4 SSR hydration flash prevented (blocking script / cookie)
- §13.5 `color-scheme` set per theme class

**§14 Content & Microcopy**
- §14.1 Button labels are verbs
- §14.2 Error messages explain + suggest
- §14.3 Empty states invite
- §14.4 Confirmations name the action
- §14.5 Success is understated
- §14.6 Loading text, when shown, is specific
- §14.7 No jargon leaked (HTTP codes, stack traces) into UI
- §14.8 Numbers / dates / currency localized
- §14.9 Labels above fields for forms > 3 fields
- §14.10 Placeholder is example, not label

**§15 Brand Moments** — scope: whole-app, not per-file. Only audit on 404, 500, splash, offline, first-run, or update-available surfaces.
- §15.1 404 on-brand + useful actions
- §15.2 500 apologetic + retry + support
- §15.3 Splash branded (not generic spinner)
- §15.4 Offline branded (not browser error)
- §15.5 First-run empty state designed as moment

§16 (Premium Checklist) and §17 (Ultimate Test) are summary / verdict sections — they do not introduce new rules. Don't iterate them as rules; use them as final-verdict prompts after §1–§15 pass.

---

## 1. COLOR

### Contrast

- **Body text vs background: ≥ 4.5:1** (WCAG AA). Premium tier targets **7:1** (AAA) where brand allows.
- **Large text** (18pt+ regular / 14pt+ bold): ≥ 3:1
- **Non-text UI** (icons, borders, focus rings, form inputs): ≥ 3:1
- **Disabled text**: no contrast requirement, but make the disabled state unambiguous (opacity ≥ 0.4 + cursor:not-allowed + no hover state)
- **Placeholder text**: ≥ 4.5:1 — commonly fails; placeholders are not decorative
- **Test dark mode separately.** A color that passes on white can fail on near-black.

**APCA awareness.** WCAG 2 contrast math is perceptually inaccurate (it under-penalizes dark-on-dark and over-penalizes mid-tones). WCAG 3 / APCA is replacing it. For new design systems, check both — pass WCAG 2 as the floor, aim for APCA Lc 75+ for body text.

### Harmony (pick one relationship, commit)

A screen uses exactly one color-harmony relationship. Mixing two is the most common amateur tell.

- **Complementary** (opposite hues) — high-energy CTAs; exhausting if overused
- **Analogous** (adjacent hues) — content-heavy sites, reading apps; low visual tension
- **Triadic** (three equidistant hues) — playful brands, illustration-heavy
- **Split-complementary** (one hue + two flanking its opposite) — safer than pure complementary
- **Monochromatic** (one hue, varied lightness/saturation) — hardest to execute; most premium when done

Document the choice in the design system. Audit new screens against it.

### Distribution (60-30-10 structure)

- **Dominant** — backgrounds, large surfaces (~60%)
- **Secondary** — cards, elevated surfaces, borders (~30%)
- **Accent** — CTAs, highlights, brand moments (~10%). *Precious; overuse destroys impact.*

Exact percentages flex — the structure is mandatory. If three colors compete for attention, none wins.

### Brand color ≠ UI primary

The brand's signature color is often too saturated / too narrow-contrast to serve as `--primary`. Derive a UI-safe variant:

- Pull saturation back 10–20% to avoid electric shimmer on large surfaces
- Generate a lightness ladder (hover = base 10% lighter/darker; pressed = 15%; focus ring = base with 40% alpha)
- Verify every shade hits contrast requirements against all surfaces it will pair with

The brand color lives in the logo and hero. The UI primary lives everywhere else.

### Neutrals are never pure gray

Pure `hsl(0 0% 50%)` reads as dead. Premium grays are **single-hue tinted** — 5–15% saturation of a chosen hue (usually the primary or a muted neighbor). This is the largest pixel-level premium/amateur split at the neutral level.

```
Amateur neutral:  hsl(0 0% 50%)      dead gray
Premium neutral:  hsl(222 10% 50%)   tinted gray — same hue family as brand
```

All neutrals (from background to border to muted text) share one underlying hue with varied lightness.

### State through temperature (one convention, not law)

A common convention — adapt to brand:

- **Neutral / inactive** → cool tones
- **Active / selected** → warm shift toward primary
- **Error** → desaturated red (disappointment, not alarm). Pure `#FF0000` is amateur.
- **Success** → brief warm pulse, then settle
- **Warning** → amber, not yellow (yellow on white fails contrast)

### Gradients (when used)

- 2–3 stops maximum. More = muddy.
- Same hue, different lightness — cleanest
- Analogous hues — safe
- **Never complementary** — generates muddy midpoint
- Match the gradient color space to theme color space (both OKLCH or both HSL) — prevents banding

### Chart / data-viz palettes

Different math from UI colors. Categorical (distinct, equal-weight), sequential (single-hue lightness ladder), diverging (two-hue ladder through neutral). Don't reuse brand accents for data — they carry semantic weight. Audit separately (see a dedicated data-viz skill when it ships).

### Pure black / pure white exceptions

- **OLED dark-media apps** (video, streaming, reading) — `#000` is actively better (pixel-off, battery, true contrast)
- **Brutalist aesthetic** — pure black/white is the point
- Everywhere else — use tinted near-black and near-white

### Discipline

- Never hardcode hex/RGB in components. Tokens only (`var(--foreground)`, Tailwind theme values).
- Max three accent colors per screen
- Dark mode is independently designed (see §9 Theme)
- Colorblind safe — don't rely on color alone for meaning (pair red/green error/success with an icon or label; 8% of men have red-green CVD)

### What we enforce / what you provide

| Enforce | Provide |
|---|---|
| Contrast math (AA + AAA awareness + APCA) | Brand hue(s) |
| Harmony coherence | Palette values |
| 60-30-10 distribution | Which color is dominant / accent |
| Neutrals must be hue-tinted | Chosen neutral hue |
| Brand → UI derivation rules | Brand color |
| Semantic token naming | Token values |

---

## 2. SPACING

### One base unit

Pick **4** or **8**. Derive the whole scale. Never mix.

```
4-base: 4, 8, 12, 16, 24, 32, 48, 64, 96
8-base: 8, 16, 24, 32, 48, 64, 96, 128
```

Tailwind is 4-based by default. Using 8-base means overriding `theme.extend.spacing` and disabling the 2/3/5/7/etc rungs — non-trivial; pick deliberately.

### Rhythm

- Same unit for margin / padding / gap — no independent spacing dialects per component
- Vertical rhythm: equal gap between sibling sections of the same type
- Section padding: one consistent page-level value (e.g. `py-16 lg:py-24`) — don't reinvent per page
- Responsive spacing scales: `gap-4 lg:gap-8` or fluid `clamp()`-based — spacing breathes with viewport

### Gap vs padding

- **Gap** — between siblings inside a container
- **Padding** — inside a container, between container-edge and content
- Never use margin for layout spacing inside flex/grid containers (breaks gap semantics)

### Touch targets

- **≥ 44px (2.75rem)** — Apple minimum
- **≥ 48px (3rem)** — Material guideline; premium target
- Spacing between adjacent targets ≥ 8px (prevents mis-tap)

### Optical vs mathematical

Occasionally optical alignment trumps the grid — an icon paired with text may need 1-2px optical nudge. Use sparingly; document when done. "The math says 16px but the eye says 14px" is a real thing, but treat it as exception, not rule.

### Negative space

Whitespace is composition. If removing an element leaves the screen still working, it shouldn't have been there.

### Enforce / provide

| Enforce | Provide |
|---|---|
| Single base unit discipline | 4 or 8 |
| All values on scale (no `p-[13px]`) | Exposed token values |
| ≥ 44px touch targets (≥ 48px premium) | Container max-width |
| Gap vs padding semantics | — |

---

## 3. TYPOGRAPHY

### Modular scale (pick one ratio)

Every font-size derives from one ratio from base.

| Ratio | Feels | Good for |
|---|---|---|
| 1.125 | Compact, data-dense | Dashboards, admin |
| 1.25 | Balanced default | Most apps |
| 1.333 | Expressive | Consumer apps |
| 1.5 | Bold | Editorial, marketing |
| 1.618 (golden) | Dramatic | Hero-driven landing |

Example — base 16, ratio 1.25: `12.8 → 16 → 20 → 25 → 31.25 → 39 → 48.8 → 61`.

**Bonus:** match type-scale ratio to spacing-scale ratio (both 1.25, or both 1.5) for mathematical harmony across both axes.

### Units

- Use **rem** for font-size (respects user font-size preference for accessibility)
- `px` for borders, single-pixel details
- `em` for local proportions (badge padding scaling with font-size)

### Hierarchy

- **Weight before size.** Differentiate heading from body via weight first, size second. Size jumps feel clunky; weight shifts feel refined.
- **Max 2 typefaces** — display + body, or one variable font with weight variation. Three = noise.
- **Heading hierarchy** — never skip levels (H2 → H4 breaks screen-reader outline)

### Line-height (inverse to size)

| Size | Line-height |
|---|---|
| Body 14–18px | 1.5–1.7 |
| Large 20–32px | 1.2–1.4 |
| Display 40px+ | 1.0–1.1 |

### Letter-spacing

| Context | Value |
|---|---|
| Large headlines | slightly negative (`-0.02em`) |
| Body | default (`0`) |
| ALL CAPS / small labels | positive (`0.05–0.1em`) |

### Measure (line length)

45–75 characters for body prose. Constrain via `max-w-prose` or `max-w-2xl` for long-form text. Measure shorter on tablet, longer on wide screens — not fixed.

### Fluid typography

```css
/* Formula: clamp(min-size, base + scaling, max-size) */
font-size: clamp(1rem, 0.5rem + 2vw, 1.5rem);
```

Use for display headlines; body text stays stepped at breakpoints for reading consistency.

### Font loading (critical for perceived premium)

- `font-display: swap` on all custom fonts — prevents invisible text during load
- `<link rel="preload" as="font" crossorigin>` on the one or two fonts above the fold
- Subset fonts to used glyphs (Latin-only can save 50-80% weight)
- Prefer **variable fonts** — one file handles all weights; smaller payload, animatable weight
- Self-host via `next/font/local` or Google via `next/font/google` — never unoptimized `<link>` to fonts.googleapis.com in production
- Fallback stack matches metrics of primary (size-adjust, ascent-override in `@font-face`) — prevents CLS on swap

### Variable font tricks (premium tier)

- Animate weight on hover (`font-weight: 400 → 550`) for a subtle, premium interaction
- Use optical-size axis where the font has it — display usage differs from body usage

### OpenType features

- **Tabular nums** (`font-variant-numeric: tabular-nums`) for tables, time, money — prevents number jitter
- **Oldstyle nums** for body prose in editorial aesthetics
- **Ligatures on, discretionary ligatures off** — default
- **Stylistic sets** — use deliberately; document when

### Font pairing

Contrast over similarity. Serif + sans, or two distinctly-different sans (geometric + humanist, e.g.). Never two similar sans — reads as mistake.

### The squint test

Blur your eyes. H1 → H2 → body → caption should form a clear staircase. If everything blends, hierarchy failed.

### User-generated text

- Always `max-lines` + `ellipsis` or `line-clamp` — never let UGC break the layout
- Test with pathological input: 500-char no-space string, emoji run, RTL mixed with LTR

### Enforce / provide

| Enforce | Provide |
|---|---|
| Single modular scale | Ratio choice |
| rem for font-size | Font family |
| font-display: swap + preload discipline | Display vs body typeface |
| Line-height / letter-spacing formulas | Base size |
| Max 2 typefaces | — |
| UGC overflow protection | — |

---

## 4. SHADOW & ELEVATION

### Named elevation scale (3–5 levels)

Every app has a finite elevation vocabulary. More than 5 = chaos.

```
shadow-none     — flush with surface
shadow-sm       — barely raised (hover on flat card)
shadow-md       — lifted (dropdowns, popovers)
shadow-lg       — floating (modals, command palette)
shadow-xl       — prominent overlay (toasts, top-layer)
```

### Shadow shape

Premium shadows are **multi-layered** (stacked shadows with different blur/offset). Single-layer shadows look cheap.

```css
/* Cheap */
box-shadow: 0 2px 4px rgba(0,0,0,0.1);

/* Premium */
box-shadow:
  0 1px 2px rgba(0,0,0,0.04),
  0 4px 12px rgba(0,0,0,0.08);
```

- Soft shadows on light surfaces (low alpha, wide blur)
- **Darker, tinted shadows on dark surfaces** — dark-mode shadows need more alpha or switch to luminance-based depth (inner glow, border-highlight) since shadows disappear into dark backgrounds
- **Tint shadow with ambient color** where appropriate (shadows in a warm-toned app lean warm)

### Alternatives to shadow for depth

- **Layered opacity** — translucent surfaces stacked
- **Subtle borders** — 1px `hsl(var(--border))` does work shadow used to
- **Background-blur** — glassmorphism territory
- **Color temperature shift** — warmer = closer, cooler = further

Shadows feel dated in many 2026 aesthetics — use deliberately.

---

## 5. BORDER RADIUS

### Named radius scale (3–5 values)

```
radius-none  — 0  (brutalist, data tables)
radius-sm    — 4  (inputs, small chips)
radius-md    — 8  (buttons, cards)
radius-lg    — 16 (modals, hero images)
radius-xl    — 24 (bento tiles, marketing surfaces)
radius-full  — 9999 (avatars, pills)
```

### Discipline

- **One scale across the app** — mixing 6px, 10px, 14px, 18px in the same UI is an amateur tell
- **Consistent per role** — all buttons same radius; all cards same radius; don't let a designer pick per-component
- **Nested radius math** — inner radius = outer radius − padding. A card with `radius-lg` (16px) and `p-4` (16px) containing an image → image gets `radius-none`. Breaking this creates visible gap corners.

### Per-aesthetic
- Brutalist — 0
- Flat — small (4–8px)
- Material — medium (8–12px)
- Claymorphism / Bento — exaggerated (16–32px)
- Glassmorphism — medium-large (12–20px)

---

## 6. MOTION

### Timing

| Interaction | Duration |
|---|---|
| Micro (hover, focus, toggle) | 150–250ms |
| Macro (modal, sheet, menu) | 300–500ms |
| Page / storytelling | 500–800ms |
| Never without narrative reason | > 800ms |

**Exit is slightly faster than entry** (exit 200ms / entry 300ms) — feels responsive; prevents "laggy" perception.

### Easing

| Case | Curve |
|---|---|
| Entry | `ease-out` |
| Exit | `ease-in` |
| User-driven (drag, scroll) | spring |
| Continuous (progress, loading) | linear |

Never default `ease` (equivalent to `ease-in-out`) — looks robotic. Pick intentionally.

### The 3-layer stack

Never animate everything at once. Choreograph:

1. **Container** — position, size (50–100ms)
2. **Content** — opacity, scale, staggered children (100–200ms after)
3. **Details** — icons, badges (after content settles)

### 60fps floor

16.6ms per frame budget. **Animate only `transform` and `opacity`** on the main thread. Animating `width` / `height` / `top` / `left` triggers layout — janky. Use `transform: translate() scale()` instead.

### Interruption handling

User taps during animation → preserve velocity, don't snap. Framer Motion / React Spring handle this natively; CSS transitions do not — use JS animation for interactive surfaces.

### Specific patterns

- **Entry on mount** — CSS `@starting-style` (modern) or Framer Motion `initial` / `animate`
- **Skeleton shimmer** — subtle opacity pulse (0.6 → 1.0 over 1.5s) or linear-gradient sweep. Static skeleton = lazy skeleton.
- **Error shake on invalid input** — 3 oscillations, 400ms total, ±4px translateX
- **Success celebration** — sparingly. Confetti / bounce for meaningful wins (first purchase, streak milestone). Never for "email sent."
- **Page transitions** — Next.js View Transitions API (`unstable_ViewTransition`) for app-router apps

### Reduced motion

`@media (prefers-reduced-motion: reduce)` — respect universally. Strip the travel, keep the state change. Reduced state still feels *designed*, not broken.

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```

### Enforce / provide

| Enforce | Provide |
|---|---|
| Duration ranges per type | Exact cubic-bezier |
| `prefers-reduced-motion` respect | Signature motion moments |
| transform/opacity only | Spring constants |
| 3-layer stack discipline | Skeleton style |
| No default `ease` | — |

---

## 7. STATE DESIGN

Every data-driven surface renders these states. Missing any is a bug, not "not a priority."

### The four primary states

**Loading**
- Skeleton matches final layout shape and approximate size — not a spinner
- Skip skeleton under 200ms wait (flash is worse than wait)
- Long waits (> 3s) — add value: tip, preview, progress with ETA

**Empty**
- Illustration / icon + inviting message + single clear action
- *Wrong:* "No items found"
- *Right:* "Your collection is ready for its first addition" + `[Add item]`

**Error**
- Specific + actionable + retry
- *Wrong:* "Error occurred"
- *Right:* "Can't reach the server. Check your connection and try again." + `[Retry]`
- Never blame user. Never vague. Never dead-end.

**Content**
- The happy path. Most-designed state but cannot exist without the other three.

### The edge states (premium tier)

Most apps ship without these. Premium apps cover them.

**Sparse (1–3 items on a screen built for 20)**
- Don't center a lonely card in a vast void — abandoned, not minimal
- Anchor content to the top; let whitespace breathe below
- If the screen supports creation, subtly encourage more — "great start" energy

**Offline** (different from error)
- Explicit offline indicator (banner or state-per-item)
- Queue user actions; sync when back online
- Cached content still readable — don't black-screen offline
- Distinct message: "You're offline. Changes will sync when you reconnect."

**Stale / background refresh**
- Show cached content + subtle "refreshing" indicator (not a blocking spinner)
- Swap-in new data with a micro-animation, not a jarring jump

**Partial / progressive**
- Some items loaded, some loading — render what's here, skeleton the rest (don't block the whole view on the slowest request)

**Pending** (between user action and server response)
- Optimistic UI for non-critical (like, bookmark, reorder) — update instantly, rollback silently on fail
- For critical ops — button → loading-spinner-in-button + disabled, never the whole page

**Rate-limited**
- Explicit: "You've made too many requests. Try again in 30s." with countdown
- Never a generic error

**Permission-denied** (different from error)
- Clear: "You need admin access to view this." + [Request access] or [Go back]
- Never 403-as-error-state

**Success**
- Inline for small actions (checkmark swap, toast) — duration 2-3s, dismissable
- Full-screen for milestone actions (first purchase) — intentional celebration
- Never a permanent green banner

### Rollback UX

When optimistic update fails:
- Revert the UI change with a 300ms animation (not instant snap)
- Toast the failure with context + [Retry]
- Never silent failure

### Disabled state

- Opacity ≥ 0.4 + cursor:not-allowed + no hover style
- Ideally a tooltip explaining *why* it's disabled (premium touch)

### Destructive-action confirmation

Always confirmation for delete, cancel subscription, leave team, discard draft. Undo is better than confirmation where possible (Gmail's "undo send" pattern).

---

## 8. RESPONSIVE + DENSITY PER APP TYPE

### Universal

- **Mobile-first** — base styles mobile, `sm:` / `md:` / `lg:` add desktop complexity
- **Breakpoints follow content** — break where layout actually breaks, not at device-name rituals
- **Container queries** (`@container` in Tailwind v4) for component responsiveness — more accurate than viewport queries
- **No horizontal overflow at 320px** — ever. Test at 320 first, then scale.
- **Wide screens (≥ 1920px)** — constrain to `max-w-screen-xl` or similar; don't let content stretch to 2560px line width

### Safe-area insets (iOS, modern Android)

```css
padding-top: env(safe-area-inset-top);
padding-bottom: env(safe-area-inset-bottom);
```

- Fixed bottom bars — honor `safe-area-inset-bottom` (home indicator)
- Full-bleed content — honor top inset (notch, Dynamic Island)
- Modal sheets — respect both
- Missing safe-area = content under notch / clipped by home bar

### Keyboard-open viewport (mobile)

iOS Safari changes viewport height when keyboard opens. Use `dvh` (dynamic viewport height) instead of `vh` for layouts that must adapt:

```css
min-height: 100dvh;  /* not 100vh */
```

### Density signature by app type

| App type | Example | Mobile density | Whitespace |
|---|---|---|---|
| Content-heavy | Social feed, news, ecommerce grid | High — 4–6 items on fold | Tight |
| Tool / dashboard | Admin, analytics, IDE-like | Medium — data + affordance | Moderate |
| Content consumption | Reader, video, podcast | Low — minimal chrome, content dominates | Generous |
| Brand / marketing | Landing, product page | Low — hero-driven, one message per screen | Luxurious |
| Forms / admin | Settings, onboarding | High — compact, efficient, no decoration | Minimal |

**Detect heuristic:**
1. What does the user come to do? (consume / operate / buy / learn / configure)
2. Would they trade whitespace for more content? (if yes → high density)
3. How long is a typical session? (shorter → higher density OK; longer → prioritize focus)

### Tablet (768–1024px)

Not "bigger mobile." Tablet often has more width than mobile but one-handed thumb zone differs from desktop mouse precision. Treat as its own density:

- Use more columns than mobile, less than desktop
- Touch-first (≥ 44px targets still apply)
- Split-view possible (nav left + content right)

### Landscape mobile

- Rare but real — most users hold phones portrait for apps
- Don't design landscape-first; test it doesn't break
- Media apps (video, games) may invert this

### Thumb zone (mobile)

- Primary actions in bottom 40% of screen — thumb-reachable
- Destructive actions NOT in thumb zone — deliberate effort required
- Back/close: top-left standard on both platforms

### Print styles

Premium sites have `@media print` CSS: strip nav/footer, respect page breaks, black on white for ink economy. Niche but noticed.

### Enforce / provide

| Enforce | Provide |
|---|---|
| Mobile-first CSS | Breakpoint values |
| Safe-area inset handling | Max content widths per breakpoint |
| `dvh` over `vh` for viewport-dependent heights | App-type density choice |
| No horizontal overflow at 320px | — |
| Density matches detected app type | — |

---

## 9. AESTHETIC COHERENCE

Every app belongs to an aesthetic family. Premium apps commit to one. Amateur apps mix two or three without realizing.

### Named aesthetics (pick ONE as identity)

**Modern baseline**
- **Minimalist** — whitespace, 1-2 colors, ≤ 3 type weights, no ornament. *Linear, Notion, Apple.*
- **Flat** — solid colors, no shadow, mostly borderless. Precursor to Material.
- **Material** — Google's system; solid colors + shadow-elevation hierarchy. Safest large-app default.
- **Utility-brutalist** — minimal chrome + dense data + monospace accents + high contrast. *Linear, Vercel, Railway.* Modern favorite.

**Decorative**
- **Glassmorphism** — translucent surfaces, backdrop-blur, subtle borders. *Apple macOS / visionOS, Stripe modals.*
- **Neumorphism** — same-surface color, dual shadow (light + dark). *Risky — contrast fails often.*
- **Claymorphism** — 3D puffy surfaces, soft-saturated colors, playful. *Kids apps, consumer fintech.*
- **Liquid Glass (2026)** — Apple iOS 26 language; glass + fluid motion + specular highlights. Premium Apple-ecosystem apps.

**Structural**
- **Bento grid** — card-based with varying tile sizes, exaggerated radius, per-tile micro-interactions. *Apple product pages, Vercel marketing.*
- **Editorial** — typography-first, serif/sans mix, visible grid. *Stripe Press, Medium, The Verge.*

**Expressive**
- **Brutalist** — raw, monospace, high-contrast, deliberate "ugliness." *Hacker News evolved.*
- **Dark-cinematic** — deep (often true) black, film-grade color, purposeful glow. *Streaming, media consumption.*
- **AI-native** — 3D gradients, orbs, blurred shapes, meshy backgrounds. *Perplexity, ChatGPT canvas, many 2025-26 AI products.*
- **Retro / Y2K** — era cues: chrome, glow, pixel, skeuomorphic iconography.

### The universal rule

**Never mix two aesthetics in one UI.** Glassmorphism + neumorphism. Bento + brutalist. AI-native + editorial. This is the #1 "assembled, not designed" tell.

### Per-aesthetic enforceable specs

**Minimalist**
- ≤ 2 brand colors + neutrals (+ semantic state)
- Whitespace ≥ 40% of viewport at rest
- ≤ 3 type weights app-wide
- No ornamental elements (dividers OK, flourishes banned)
- One signature detail per screen maximum

**Glassmorphism**
- `backdrop-blur: 8–24px` on translucent surfaces
- Background opacity `0.1–0.3`
- Subtle border `rgba(255,255,255,0.08–0.15)` in dark; `rgba(0,0,0,0.05–0.1)` in light
- **Critical:** text on glass requires either a solid layer behind the text OR backdrop opacity ≥ 0.5 (lower fails contrast on varied backgrounds). Most glass designs fail here.
- Respect `prefers-reduced-transparency` — fall back to opaque surfaces
- Layer blur strengths: 2-3 elevation tiers max

**Neumorphism**
- Dual shadow (light top-left + dark bottom-right) on same-surface color
- Applied ONLY to interactive elements — never whole page
- Ruthless contrast audit — primary failure mode
- Never on text — always containers

**Bento grid**
- CSS Grid with varying `col-span` / `row-span`
- Corner radius 16–24px
- Per-tile micro-interaction on hover (scale, glow, content-reveal)
- 2-4 tile-size classes maximum
- Consistent internal padding across tiles

**Editorial**
- Type scale ratio ≥ 1.5
- Body measure strictly 55–70 chars
- Serif + sans pair, or two contrasting sans — never same-family variations
- Grid visible or implied (8 or 12 col), not ad-hoc

**Brutalist**
- Near-black on near-white or inverse (pure black/white acceptable here)
- System / mono fonts
- No rounded corners, no shadows
- Deliberate asymmetry, not accidental

**Utility-brutalist (Linear / Vercel)**
- Monochromatic + single accent hue (purple, pink, or blue typical)
- Monospace accents for metadata (timestamps, IDs, code)
- Dense data tables with strong horizontal rules
- Minimal motion, instant feedback
- Dark-first design

**AI-native**
- Animated meshy gradients (CSS / Three.js / Canvas)
- Soft 3D orbs, subtle particle motion
- Glow accents (not neon, softer)
- Often dark with bright accent bloom
- Risk: easy to over-decorate; ensure content surface is readable

### Enforce / provide

| Enforce | Provide |
|---|---|
| Single aesthetic commitment | Which aesthetic |
| Per-aesthetic specs | Exact values in spec range |
| "Never mix two" audit | — |
| Contrast enforcement within glass / neumorphism | — |

---

## 10. ICONOGRAPHY

### Consistency rules

- **One icon family app-wide** — Lucide, Tabler, Phosphor, Heroicons. Never two libraries mixed.
- **Consistent style** — all stroke (most common) or all fill. Not both.
- **Stroke weight matches body text weight** — 1.5px stroke for 400-weight body typical; 2px for 600-weight body; never a 1px icon next to 600-weight text
- **Consistent sizing** — icons live on a scale (16 / 20 / 24 / 32). Pick 2-3 sizes; use per role
- **Color from type-color tokens** — icons use `currentColor` so they inherit text color. Never hardcoded icon colors.

### Pairing with text

- Icon + text: vertical alignment is **optical**, not mathematical (the text's x-height rarely aligns to icon's geometric center)
- Consistent spacing: `gap-2` (8px) for buttons, `gap-3` (12px) for list items

### Illustrative vs iconic

Icons and spot-illustrations are different languages. If the app uses both, they live in different roles:
- Icons — functional (navigation, buttons, inline semantics)
- Illustrations — emotional (empty states, onboarding, marketing)

Don't stylize icons into illustrations (oversized, colored) — picks wrong vocabulary.

---

## 11. CHROME & DETAILS

The edges nobody thinks about until they look wrong.

### Focus rings

- **Always visible** for keyboard users — never `outline: none` without replacement
- High contrast against all surface colors (≥ 3:1)
- Consistent style app-wide — one ring design, not one per component
- **Two-layer ring** for premium (inner solid + outer offset) — reads better on complex backgrounds:

```css
outline: 2px solid var(--ring);
outline-offset: 2px;
```

- `:focus-visible` (not `:focus`) — only shows for keyboard, not mouse clicks

### Selection highlight

Custom `::selection` to match brand:
```css
::selection {
  background: hsl(var(--primary) / 0.25);
  color: hsl(var(--primary-foreground));
}
```
Default blue selection clashes with warm brand palettes. Premium detail.

### Scrollbar

- Custom scrollbar styling (`scrollbar-width: thin` + `scrollbar-color`) — match neutral palette
- Never hide scrollbars that indicate overflow — accessibility regression
- On macOS/iOS, scrollbars auto-hide — don't force always-visible unless overflow is non-obvious

### Caret

- `caret-color: hsl(var(--primary))` — brand-colored caret in inputs is a premium touch
- Default black caret on dark themes is hard to see — always set explicitly

### Cursor

- `cursor: pointer` on all clickable non-links — button-looking divs often miss this
- `cursor: not-allowed` on disabled
- `cursor: grab` / `grabbing` on draggable
- Custom cursors sparingly — fun but accessibility risk

### Loading indicators in place

- Inline loading > full-page loading wherever possible
- Button's own spinner replaces button content, not page-level spinner
- Input validation indicators in-field (checkmark, x), not toast

### Text rendering

- `-webkit-font-smoothing: antialiased; -moz-osx-font-smoothing: grayscale;` on body — premium rendering on macOS
- `text-rendering: optimizeLegibility;` for headlines only (expensive on body text)

### Image treatments

- Aspect ratios from a fixed scale (1:1, 4:3, 16:9, 3:2, 2:1, 21:9) — don't use arbitrary
- Lazy-load everything below fold (`loading="lazy"` or `next/image`)
- Blur-up (`placeholder="blur"`) for hero images
- `object-fit: cover` + art-directed crop via `object-position` — never stretch

---

## 12. ACCESSIBILITY AS CRAFT

Not compliance — competence.

### Semantic HTML

- `<nav>`, `<main>`, `<article>`, `<section>`, `<aside>`, `<button>`, `<a>` — use for meaning
- Not `<div onClick>` where `<button>` fits
- Multiple landmarks of same type get `aria-label` ("Primary nav", "Footer nav")

### Headings

- One `<h1>` per page
- Don't skip levels (H2 → H4 breaks outline)
- Headings reflect document structure, not visual size

### Focus management

- `:focus-visible` for keyboard-only focus ring
- **Modal focus trap** — Tab cycles within modal; Escape closes; focus returns to trigger on close. Radix / shadcn Dialog handles this — verify it's not overridden.
- Logical tab order — matches visual order, not DOM order if they differ (fix with reorder, not `tabindex`)

### Dynamic announcements

- Toasts / alerts — `role="status"` (polite) or `role="alert"` (assertive) via `aria-live`
- Form validation — inline error associated via `aria-describedby`
- Loading state — `aria-busy="true"` on the region being loaded

### Images / media

- Meaningful `alt` or `alt=""` — never omit
- Auto-play video muted + has pause control (WCAG 2.2)
- Captions / transcripts on meaningful video
- No auto-playing carousels without pause (WCAG 2.2)

### Color signals

- Color never the only signal — error has icon + text, success has checkmark + text
- Test with colorblind simulators — red/green still readable?

### `color-scheme` property

**Critical.** Without it, UA form elements (checkbox, radio, date picker, scrollbar) flash light UI even in dark mode:

```css
:root { color-scheme: light; }
.dark { color-scheme: dark; }
/* or */
html { color-scheme: light dark; }
```

### Forced-colors mode (Windows High Contrast)

Premium sites honor it:

```css
@media (forced-colors: active) {
  /* use system colors */
  button { border: 1px solid ButtonText; }
}
```

### Reduced transparency (iOS preference)

Respect `prefers-reduced-transparency: reduce` — fall glassmorphism back to opaque.

### `lang` attribute

`<html lang="en">` minimum — screen readers pronounce correctly

### Screen-reader verification

Can a VoiceOver / NVDA user complete every core task? If unknown, you haven't verified accessibility.

### Cognitive accessibility

- Consistent patterns across pages (nav in same place, buttons labeled same way)
- Plain language where brand allows
- Error messages in human voice, not system voice
- Avoid time-pressure UI (countdown to submit) without clear reason

---

## 13. THEME SUPPORT

### Single source of truth

Every themeable value from CSS custom properties or Tailwind `@theme`:

```css
/* right */
color: var(--foreground);
background: var(--surface-1);

/* wrong */
color: #1a1a1a;
background: hsl(0 0% 98%);
```

### Semantic naming

Token names describe **role**, not value.

```
✓ --primary
✓ --surface-muted
✓ --border-subtle

✗ --blue-500
✗ --gray-100
```

Role names survive a rebrand.

### Color space

- **OKLCH** — best for perceptual uniformity. Modern browsers (Chrome 111+, Safari 15.4+, Firefox 113+). Recommended for new systems.
- **HSL** — wider support, easier reasoning. Acceptable.
- **Hex / RGB** — fine for storage; convert to HSL/OKLCH for programmatic variation.

### Light / dark parity

- Same token names, different values per theme
- Each theme independently designed — never computed pure-invert
- Test every screen in both — "correct in one, tolerable in the other" is a bug

### SSR / hydration flash (Next.js)

Without handling, user sees a light-mode flash before JS hydrates the stored theme. Pattern:

- Use `next-themes` for App Router
- Set `suppressHydrationWarning` on `<html>`
- Apply theme class via inline blocking script in `<head>` before first paint
- Store theme in cookie for server-rendered initial theme

### `color-scheme` property (repeat from a11y — critical for theme)

```css
:root { color-scheme: light; }
.dark { color-scheme: dark; }
```

Without this, every native form control flashes light.

### Multi-theme support (beyond light/dark)

- High-contrast theme
- Sepia / reading theme
- Seasonal / event themes

All via the same token structure — different values, same roles.

### Theme-switchable tokens beyond color

Radius, shadow, and sometimes type can theme too (high-contrast theme often has thicker borders, smaller radii).

### Theme switch coverage audit

Toggle theme, scroll every screen. Look for:
- Unchanged backgrounds (forgot to use token)
- Hardcoded borders
- Images with baked-in dark/light contrast
- Third-party embeds (iframes) not theming

---

## 14. CONTENT & MICROCOPY

Premium apps obsess over words. Users read UI — UI should be worth reading.

### Voice and tone

- **Voice** (who you are) — consistent app-wide
- **Tone** (how you're feeling) — shifts with context (celebratory on success, apologetic on error, direct in admin)

### Rules

- **Button labels are verbs** — "Save changes", "Delete account", "Send invitation". Not "OK" / "Submit".
- **Error messages explain + suggest** — "We couldn't process that card. Check the number or try another card."
- **Empty states are invitations** — "Your first habit is one tap away."
- **Confirmations name the action** — "Delete 3 items?" not "Are you sure?"
- **Success is understated** — "Saved." Not "🎉 Your changes have been successfully saved!"
- **Loading text, when shown, is specific** — "Generating report…" beats "Loading…"
- **No jargon the user didn't opt into** — "Sync failed" instead of "HTTP 503 upstream"
- **Sentence case over Title Case** — sentence case reads conversational; title case feels corporate. Pick one and commit.
- **Title case in nav + button labels is fine** — sentence case everywhere else reads more naturally

### Numbers and dates

- Format numbers for locale (`Intl.NumberFormat`)
- Relative times for recent ("3 min ago"), absolute for old ("Apr 12")
- Never raw timestamps visible to users (`2026-04-21T14:32:00Z`)
- Currency: symbol matches locale; decimal precision per currency convention

### Labels

- Labels above fields (not floating, not beside) for forms > 3 fields — research-backed
- Placeholder is example, not label
- Required fields indicated visually (asterisk + "required" in aria-label)

---

## 15. BRAND MOMENTS

The surfaces nobody thinks are craft opportunities — until you notice a premium app got them right.

### 404 / Not Found

- On-brand illustration or image
- Voice matches the app (playful, professional, whatever)
- Useful: search + recent pages + return home
- Never: "404 Error: Not Found."

### 500 / Server Error

- Apologetic + honest
- "Something broke on our side. We're looking at it." + retry + support contact
- Never blame user

### Splash / loading identity

- Logo reveal or branded loading pattern — not a generic spinner on cold starts
- Next.js `loading.tsx` is this opportunity
- Should take < 1.5s typical; > 3s needs ETA

### Empty brand states

- First-run screens before any data
- Onboarding stages
- Freshly-signed-up account

These are moments of **first impression** — not edge cases. Premium apps design them as carefully as the home screen.

### Offline screen

- Branded, not a browser error
- Cached content visible if available
- Clear reconnect indication

### Update / version available

- Non-blocking banner: "New version available. Reload to update."
- Never force-reload without user action

---

## 16. THE PREMIUM CHECKLIST

Before declaring any surface done:

**Tokens & Scale**
- Every color traces to a token? (no raw hex/rgb)
- Every spacing value on the base scale? (no `p-[13px]`)
- Every font-size from the modular scale?
- Every radius from the named scale?
- Every shadow from the elevation scale?
- Every icon from the one icon family?

**Contrast & Accessibility**
- Body text ≥ 4.5:1, UI ≥ 3:1, dark mode verified?
- Focus visible on every interactive element?
- Keyboard completes every flow?
- `prefers-reduced-motion` leaves screen intentional?
- `color-scheme` property set?
- Touch targets ≥ 44px?
- Colorblind-safe (not color-alone signaling)?

**State Coverage**
- All 4 primary states (loading, empty, error, content)?
- Edge states where relevant (offline, stale, partial, pending, rate-limited, permission-denied, success)?
- Sparse state (1-3 items) feels composed, not abandoned?
- Destructive actions confirmed or undo-able?

**Cohesion**
- One color harmony (not mixed)?
- One aesthetic (not mixed)?
- One base spacing unit?
- One modular type scale?
- Max 2 typefaces?

**Responsive**
- Works at 320px without horizontal overflow?
- Works at 1440px and 2560px?
- Safe-area insets honored (iOS)?
- Density matches detected app type?
- `dvh` used where viewport can change (mobile keyboard)?

**Motion**
- 3-layer stack respected (not everything animating at once)?
- transform / opacity only (no layout-triggering)?
- Durations within ranges?
- Exit slightly faster than entry?

**Chrome & Details**
- Focus ring styled (not default)?
- Selection highlight customized?
- Scrollbar styled where visible?
- Caret color set for inputs?
- Cursor signals interactivity?

**Content**
- Button labels are verbs?
- Errors explain + suggest?
- Empty states invite?
- No jargon leaked into UI?
- Numbers / dates / currency localized?

**Brand Moments**
- 404 / 500 on-brand?
- Splash / cold-start branded?
- Offline screen designed?
- First-run empty states designed?

**Signature**
- Is there one moment only this app does?
- Would someone screenshot this and share it?

If any answer is "no" or "not sure" — the surface is unfinished.

---

## 17. THE ULTIMATE TEST

1. Would someone **pay** for this?
2. Would someone **show** this to a friend?
3. Would someone **remember** this tomorrow?
4. Would someone **feel** something using this?
5. Would someone **miss** this if it disappeared?

---

## SCOPE BOUNDARIES

This skill enforces craft discipline, not brand identity. It does not:

- Pick colors, fonts, or aesthetics — user picks, we recognize
- Impose named themes
- Rewrite components without consent
- Replace your design system — it audits against the one you have

It flags:
- Values that don't trace to tokens
- Mixing of harmonies or aesthetics
- Missing states, failed contrast, broken rhythm
- Ad-hoc values, inline styles, hardcoded hex
- Missing brand-moment surfaces
- Untested edge cases

When in doubt — surface the gap with a recommendation. User decides.
