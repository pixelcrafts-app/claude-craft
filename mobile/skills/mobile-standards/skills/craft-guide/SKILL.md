---
name: craft-guide
description: Apply when designing, reviewing, or polishing mobile UI — typography, spacing, motion, state design, visual weight, transitions, information architecture. Auto-invoke whenever generating or evaluating mobile screens or widgets for craft quality.
---

# Premium Mobile Craft Guide

> For any mobile framework. Flutter, React Native, SwiftUI, Kotlin/Jetpack Compose.
> For any app type. Principles are universal — adapt to your context.

---

Design rules (layout, animation, color, typography, interaction) can be questioned. Engineering requirements (verification, auth guards, error states, accessibility) cannot be skipped.

---

## THEME AS IDENTITY

**Dark Only** — cinematic, intimate, premium (streaming, meditation, music)
**Light Only** — text-heavy, productive, trustworthy (reading, tasks, notes)
**Both Modes** — wide usage contexts, user preference matters most

### Each Mode Is Independently Designed
- Dark mode is NOT "invert the colors." Depth cues change (blur > shadow), contrast hierarchy shifts (mid-tones carry more weight), images may need darkened overlays, and surface layers use luminance not opacity to separate.
- Light mode is NOT "make it white." Background warmth, border subtlety, and shadow softness all differ. Hierarchy comes from weight and color temperature, not just darkness.
- A screen should look intentionally designed in BOTH modes — not "correct in one, tolerable in the other."
- Never duplicate the same visual treatment across modes and call it done. Review each mode as if it's the only one.

---

## PERCEPTION ENGINEERING

### Speed is a Feeling
- Animation that starts instantly feels faster than shorter animation after delay
- Skeleton loaders make long waits feel short
- Optimistic UI: update immediately, reconcile silently
- Progressive disclosure: show something useful immediately, enhance as data arrives

### Touch Response
- Tap → immediate visual response (≤100ms)
- Long-press → visual acknowledgement (highlight or scale) within 300ms
- Release → action completes with state change
- Cancel (pan away) → action reverts gracefully
- Never leave a touch unanswered

### Depth Without Shadows
Shadows feel dated. Use: layered opacity backgrounds, subtle border gradients, background blur, color temperature shifts (warmer = closer).

---

## MOTION

### Duration Standards
- Micro-interactions (tap feedback, toggles): 100–200ms
- State transitions (show/hide, route push/pop): 300–400ms
- Page entrance sequences: 400–600ms total
- Stagger delay between list items: 50–100ms per item

### Easing Rules
- Entry = ease-out (decelerate from edge). Exit = ease-in (accelerate toward edge).
- Spring physics over linear/ease curves — use spring damping and stiffness instead of arbitrary tweens.
- No default `ease` curve on any transition.

### 3-Layer Animation Stack
- Layer 1 — Container: position and size animate first (300ms, decelerate curve)
- Layer 2 — Content: opacity and scale next (200ms, stagger 50–100ms between items)
- Layer 3 — Details: icons and badges after content settles (150ms)

### Rules
- Back-navigation reverses the forward transition exactly — not a generic fade.
- On mid-range transition: velocity is preserved when interrupted, physics continues naturally.
- Reduced motion: remove decorative animations entirely; cap functional transitions at ≤150ms.

---

## COLOR AS EMOTION

### State Through Color Temperature
- Neutral/inactive: cool tones
- Active/selected: warm shift toward primary
- Error: desaturated red (disappointment, not alarm)
- Success: brief warm pulse, then settle

### The 60-30-10 Rule
- 60% — background/surface
- 30% — surface variations, secondary elements
- 10% — accent color (precious — overuse destroys impact)

---

## TYPOGRAPHY AS HIERARCHY

- **The Squint Test** — blur your eyes. Can you still understand the structure? If everything blends, hierarchy failed.
- **Weight Before Size** — differentiate with font weight first, size changes second. Size jumps feel clunky, weight shifts feel refined.
- **Letter Spacing** — large headlines: tighter. Body: default. ALL CAPS: always add tracking. Small labels: slightly looser.

### Scale Reference
- Body: 16px / 1.5 line-height / weight 400
- Body small: 14px / 1.4 line-height / weight 400
- Label: 12px / 1.3 line-height / weight 600 (uppercase: add letter-spacing 0.08em)
- Title: 18–20px / 1.3 line-height / weight 600
- Headline: 24–28px / 1.2 line-height / weight 700
- Hero: 32px+ / 1.1 line-height / weight 700–800

Never add a size between steps. Weight carries hierarchy, not arbitrary sizing.

---

## STATE DESIGN

### Loading States
- Skeleton matches the exact final layout — not a spinner
- If the wait is long, add value to the wait (tip, preview, quote)

### Sparse States (1-3 Items)
Empty state is designed. Full state is designed. But what about 1-3 items on a screen built for 20? Sparse is its own state.
- Don't center a lonely card in a vast void — that's not minimal, it's abandoned
- Anchor sparse content to the top. Let white space breathe below, not around.
- If the screen supports creation, the sparse state should subtly encourage more: "Great start" energy, not "this looks broken" energy
- A grid with 1 item should NOT show a grid — show the item with presence

### Empty States
Empty is invitation, not error. Copy should name what is missing and offer a next action — never just report the absence. Always pair an illustration with a human-voiced message and a single clear action.

### Error States
Error copy must name what happened, not just that something went wrong. Speak to the user plainly: identify the specific failure, give them a concrete next step, and never dead-end. Never blame the user. Never be vague.

---

## MOBILE PATTERNS

### Gesture & Touch
- Minimum tap target: ≥48×48dp (44dp floor on iOS). Never rely on visual size alone — extend hit area with padding if needed.
- Minimum gap between adjacent targets: ≥8dp (prevents mis-taps for motor-impaired users)
- Primary actions in bottom portion of screen (thumb zone)
- One-handed operation: all core tasks reachable with one thumb
- Destructive actions get 3–5s undo window — never execute on a single tap without confirmation or undo

### Feedback Layering
1. Visual — ≤100ms response from tap
2. Haptic — fires 10–50ms after visual (not simultaneously)
3. Audio — only for significant or milestone actions
4. State — persistent change confirms completion

### Haptic Intensity Rules
- `lightImpact` — standard taps, toggle switches, selection changes
- `mediumImpact` — completing an action, confirming a choice
- `heavyImpact` — destructive actions, significant milestones
- `selectionClick` — picker scrolling, slider ticks
- Check user haptic preference before firing

---

## PLATFORM INTELLIGENCE

- **iOS**: bouncy overscroll, swipe-back, sliding sheets
- **Android**: glow overscroll, predictive back, snapping sheets
- Respect platform conventions — don't force one on the other
- Never assume screen bounds (notch, Dynamic Island, home indicator, keyboard)
- Keyboard: content moves, not hides

---

## ACCESSIBILITY AS CRAFT

The principle: not compliance — competence. Reduced motion: decorative animations are removed entirely. Functional transitions (navigation, modal presentation) are kept but reduced to ≤150ms. The result must feel purposeful, not broken.

Loading, error, and empty states are engineering requirements — not design features. Accessibility implementation rules are engineering requirements. Neither can be broken.

---

## NAVIGATION & BACK GESTURE

- **Back Is Not Exit** — in a tabbed app, back means "go home" before "leave." Only home tab exits.
- **Sheets Absorb Back** — modal owns the back gesture while visible.
- **Cold Start Is a Full Journey** — every route handles being the entry point.
- **Data Continuity Across Screens** — update on a detail screen must reflect on the parent list immediately on back-navigate. No stale cards. No "pull to refresh to see your own change." The app remembers what you just did.

---

## INFORMATION ARCHITECTURE — THE FOUNDATION

Before choosing colors, spacing, or animations, the screen must deserve to exist.

### Screen Identity
- **One Sentence Rule** — if you can't explain why a screen exists in one sentence, delete it or merge it. "This shows modules" is not a reason if another screen already shows modules.
- **No Duplicate Content** — the same data must never appear on two tabs or two sibling screens. If Home shows a module grid AND a Modules tab shows a module list, one of them is waste. Pick one home for each piece of content.
- **Every Section Earns Its Space** — before adding a widget to a screen, ask: "Does the user need this HERE, or am I filling space?" Stats, badges, and cards that don't inform a decision are decoration, not design.

### Tab Architecture
- **Each Tab = One Job** — a tab exists because it serves a distinct user intent. "Home" is not "everything." Home is "where am I and what's next." Browse is "show me all content." Profile is "my stuff and settings."
- **Tab Roots Are Not Push Screens** — a screen designed as a push destination (with a back button, a "go back" flow) must be redesigned when promoted to a tab root. Remove back buttons. Add a proper header. Rethink the information density for a landing page, not a detail page.
- **3-5 Tabs Maximum** — if you need more, the information architecture is wrong. Combine related concerns. Search belongs inside the content tab, not as its own tab. Settings belong inside Profile, not as their own tab.
- **Tab Uniqueness Test** — open each tab side by side (mentally or in screenshots). If two tabs show >50% of the same content, merge them.

### Data Meaningfulness
- **No Naked Numbers** — a stat shown to the user must have a label, context, or both. "📖 3" means nothing. "3 lessons completed" means something. "3 of 12 lessons" means more.
- **No Duplicate Metrics** — if streak is in the header, don't repeat it in a stats row below. Show each metric once, in its most useful context.
- **Real Over Impressive** — don't show analytics the app can't actually deliver. If the data is a counter with no trend, insight, or action, it's a vanity metric. Either make it actionable ("3 lessons left to complete Module 2") or remove it.
- **Progressive Disclosure of Data** — show summary on the overview screen, detail on the detail screen. Don't dump everything on one page.

### Screen Density Identity
Every screen type has a density signature. Mixing them feels wrong even if you can't say why.
- **Hub screens** (home, browse) — spacious, scannable, generous spacing. The user is choosing, not consuming.
- **Detail screens** — dense, complete, information-rich. The user chose — now give them everything.
- **Settings / forms** — compact, efficient, minimal decoration. The user is configuring, not exploring.
- **Creation screens** — focused, minimal chrome, maximum canvas. Get out of the way.
- Never give a hub the density of a detail screen. Never give a form the spaciousness of a hub.

### Visual System Constraints
- **Grid**: 8px baseline. All spacing values are multiples of 4 or 8. No odd numbers.
- **Corner radius**: 4px — inputs, badges, chips. 8px — cards, list items. 12–16px — sheets, modals, hero sections. Never mix adjacent elements with different radii.
- **Color palette**: 1 primary (actions/selection), 1 secondary (accents), 6-step neutral scale, 3 semantic (error/success/warning). No tertiary colors. No per-feature accent colors.
- **Shadows**: Do not use drop shadows. Elevation via background color shift or 1px border at 8–12% opacity.

### Content Placement Logic
- **Search Lives With Content** — search is a tool for finding things. Put it where the things are (content browse screen), not in its own isolated tab.
- **Actions Near Their Objects** — a "practice" button belongs on the question screen, not on a separate practice tab. A "bookmark" action belongs on the item, not in a bookmarks-first screen.
- **Hub and Spoke** — overview screens (hub) link to detail screens (spoke). The hub shows just enough to choose. The spoke shows everything about that choice. Never put spoke-level detail on a hub.

### The IA Checklist
Before building any multi-screen flow:
- Can you name each screen's ONE job in ≤5 words?
- Does any content appear on more than one tab? If yes, pick one home.
- Does every number/stat on screen have a label a new user would understand?
- Would removing a tab break the app — or would users not notice?
- Are tab root screens designed AS tab roots, or are they recycled push screens?

---

## CONTEXTUAL AWARENESS

- **First Use vs 100th Use** — a new user needs orientation (labels, hints, fuller explanations). A returning user needs speed (compact, direct, no hand-holding). Design for day 1, then design for day 100, then make them coexist.
- **Progress-Aware UI** — a beginner with 0 habits sees encouragement. A power user with 20 habits sees efficiency. The same screen, adapted to where they are in their journey.
- **Content-Volume-Aware Layout** — don't design for the ideal 8-item grid and hope it works for 1 or 200. Design the layout to breathe at every content count.
- **Recency Awareness** — something created seconds ago should feel fresh (subtle highlight, "just added" energy). Something untouched for weeks should feel patient, not stale.

---

## THE CRAFT CHECKLIST

Before shipping, interrogate every screen:

- Does tapping *anything* produce instant response — or silence?
- Does slow network reveal a designed loading state — or a blank screen?
- Does a forced error guide recovery — or dead-end?
- Does empty data invite action — or display a void?
- Can a screen reader user complete the task — or are they guessing?
- Does reduced motion still feel intentional — or broken?
- Is any screen screenshot-worthy — or merely functional?
- Does squinting reveal clear hierarchy — or visual noise?
- Does midnight mode maintain contrast — or become unreadable?
- Does a slow device stay smooth — or stutter?
- Does back gesture on a non-home tab return home — or eject the user?
- Does every color, size, and spacing trace back to the design system — or are orphans hiding?
- Are patterns reused across screens — or reinvented each time?
- Can each screen explain its existence in one sentence — or is it duplicating another?
- Does every visible number have a label — or are there naked stats?
- Do tab roots feel like landing pages — or recycled push screens with back buttons?
- Is search integrated where content lives — or stranded in its own tab?
- Does the screen look intentionally designed in BOTH dark and light mode — or just tolerable in one?
- Does a screen with 1-3 items feel composed — or abandoned?
- Does long user-generated text gracefully truncate — or overflow/clip?
- Does the screen density match its type (spacious hub, dense detail, compact settings)?
- Does navigating back show your latest changes — or stale data?

