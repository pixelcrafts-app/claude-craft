---
name: craft-guide
description: Apply when designing, reviewing, or polishing Flutter UI — typography, spacing, motion, state design (loading/empty/error/content), visual weight, transitions, density, data continuity. Auto-invoke whenever generating or evaluating Flutter screens or widgets for craft quality.
---

# Premium Mobile Craft Guide

> For any mobile framework. Flutter, React Native, SwiftUI, Kotlin/Jetpack Compose.
> For any app type. Principles are universal — adapt to your context.

---

## THE MINDSET

You're crafting an experience someone holds 6 inches from their face, in intimate moments — commuting, relaxing, escaping. It's personal. Respect that.

---

## CREATIVE UNLOCKS

### The Only Real Rule
**Design rules can be broken — engineering rules cannot.** Every guideline in THIS file (layout, animation, color, typography, interaction) can be broken if you understand WHY it exists and have a better idea. But verification, data pipeline checks, auth guards, sync architecture, and `flutter analyze` — those are never breakable. Creativity lives in how things look, move, and feel. Discipline lives in making sure they actually work.

### Steal From Everywhere Except Apps
- **Film** — Kubrick's symmetry, Villeneuve's color grading, Nolan's time manipulation
- **Architecture** — Tadao Ando's light wells, Zaha Hadid's impossible curves
- **Fashion** — Runway reveals, fabric behavior, the pause before a drop
- **Music** — Build-ups, drops, silence as instrument, polyrhythm
- **Nature** — Bioluminescence, murmuration, water surface tension
- **Gaming** — Juice, feedback loops, environmental storytelling

### "What If?" Provocations
Before designing any screen, ask:
- What if this had **no buttons** — only gestures?
- What if the **content was the interface**?
- What if this screen had a **personality**?
- What if we removed **50% of what's here**?
- What if we added **one thing nobody expects**?

### Signature Moments
Every app needs 1-3 moments that ONLY this app has. Not "smooth animations" — specific, ownable, screenshot-worthy, shareable moments. Ask: *"What will users show their friends?"*

### Permission Slip (Design Only)
You have permission to break **design** conventions:
- Make something "wrong" if it feels right
- Spend disproportionate time on a tiny animation
- Delete a visual element to make space for craft
- Break your own design system for a moment
- Add something purely for joy, not function

This permission does NOT extend to engineering rules. You may never skip verification, ignore data pipeline checks, or declare "done" without confirming the UI works. Loading, error, and empty states are mandatory — they are never deletable "features."

### The Contradiction Principle
Great design holds contradictions: Simple AND deep. Familiar AND surprising. Minimal AND rich. Fast AND considered. Bold AND subtle. If your design is only one thing, push toward its opposite until tension appears.

---

## THEME AS IDENTITY

Theme isn't a toggle — it's a statement. And it's never a color swap.

**Dark Only** — cinematic, intimate, premium (streaming, meditation, music)
**Light Only** — text-heavy, productive, trustworthy (reading, tasks, notes)
**Both Modes** — wide usage contexts, user preference matters most

Questions: When will people use this? What's the content type? What emotion should it evoke?

### Each Mode Is Independently Designed
- Dark mode is NOT "invert the colors." Depth cues change (blur > shadow), contrast hierarchy shifts (mid-tones carry more weight), images may need darkened overlays, and surface layers use luminance not opacity to separate.
- Light mode is NOT "make it white." Background warmth, border subtlety, and shadow softness all differ. Hierarchy comes from weight and color temperature, not just darkness.
- A screen should look intentionally designed in BOTH modes — not "correct in one, tolerable in the other."
- Never duplicate the same visual treatment across modes and call it done. Review each mode as if it's the only one.

---

## THE PREMIUM STANDARD

*If it doesn't look like it belongs in a design award showcase, it's not done.*

- **The User Came for One Thing** — what does the user need from this moment? Everything else is noise. Remove it.
- **Clutter Is Cowardice** — white space isn't empty, it's confident. If you can remove something and the screen still works, it should never have been there.
- **Pixel-Level Obsession** — a tiny misalignment, padding that's slightly off, a color that's oversaturated. These are the gap between "nice app" and "who made this?"
- **Design Like It Will Be Judged** — every screen as if it will be pinned on a design board, submitted to an award, shown in a portfolio.
- **The Elimination Ritual** — after finishing any screen: 1) Remove visual noise (never functional requirements like error handling or loading states), 2) Align (intentional grid?), 3) Elevate (one memorable detail?)
- **Content Drives Layout** — never design a container then fill it. Understand the content first.
- **Visual Weight Balance** — the eye should flow, not stumble. If a screen leans left-heavy or top-heavy, the layout is fighting itself. Balance density across the visual field — symmetry when calm, intentional asymmetry when dynamic.

---

## PERCEPTION ENGINEERING

### Speed is a Feeling
- Animation that starts instantly feels faster than shorter animation after delay
- Skeleton loaders make long waits feel short
- Optimistic UI: update immediately, reconcile silently
- Progressive disclosure: show something useful immediately, enhance as data arrives

### Touch is Conversation
Users tap — app responds immediately. Users hold — app acknowledges. Users release — app completes. Users cancel — app forgives gracefully. Never leave a touch unanswered. Silence is rejection.

### Depth Without Shadows
Shadows feel dated. Use: layered opacity backgrounds, subtle border gradients, background blur, color temperature shifts (warmer = closer).

---

## MOTION PHILOSOPHY

- **Physics Over Tweens** — springs feel alive, linear tweens feel mechanical. Use spring physics.
- **The 3-Layer Animation Stack** — Container first (position, size), then Content (opacity, scale, staggered), then Details (icons, badges, after content settles). Never animate everything at once. Choreograph.
- **Interruption Handling** — user taps during animation? Premium: velocity is preserved, physics continues naturally.
- **Transition Continuity** — animations tell a spatial story. Where did I come from? Where am I going? Push transitions imply depth. Shared elements anchor context. The user should never feel teleported — they should feel they *traveled*. Back-navigation reverses the forward animation, not a generic fade.

---

## MICRO-INTERACTIONS AS PERSONALITY

- **The Invisible Signature** — users won't remember your layout, they'll remember how things *moved*. The repeated actions are where personality lives.
- **Weight, Not Snap** — nothing transitions instantly. Things travel, overshoot, settle. Mechanical feels cheap, organic feels considered.
- **The 80/20 of Delight** — 80% of perceived quality comes from 20% of interactions. Find the five actions users repeat most. Polish those until they feel inevitable.

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
Empty is invitation, not error.
```
"No items found"        → wrong
"Your collection is ready for its first addition" → right
```
Include: Illustration + Message + Single clear action

### Error States
```
"Invalid input"   → wrong
"That doesn't look like an email address" → right

"Network error"   → wrong
"Can't reach the server. Check connection and try again." → right
```
Never blame user. Never be vague. Never dead-end.

---

## MOBILE PATTERNS

### Gesture & Touch
- Generous tap targets — don't make users aim
- Primary actions in bottom portion of screen (thumb zone)
- One-handed operation: can they do core tasks with one thumb?
- Destructive actions get undo window — never execute on a single tap without confirmation or undo

### Feedback Layering
1. Visual — immediate response
2. Haptic — shortly after visual
3. Audio — only for significant actions
4. State — persistent change confirms completion

### Sensory Choreography
- **Haptics as instrument** — not feedback, expression. A heartbeat. A breath. A knock.
- **Sound as space** — reverb implies room size, frequency implies temperature
- **Motion as emotion** — nervous jitter, confident stride, sleepy drift, excited bounce

---

## PLATFORM INTELLIGENCE

- **iOS**: bouncy overscroll, swipe-back, sliding sheets
- **Android**: glow overscroll, predictive back, snapping sheets
- Respect platform conventions — don't force one on the other
- Never assume screen bounds (notch, Dynamic Island, home indicator, keyboard)
- Keyboard: content moves, not hides

---

## ACCESSIBILITY AS CRAFT

Not compliance — competence. Semantic labels describe the action, not the element. Contrast ratios meet standards. Color alone never conveys meaning. Reduced motion still feels intentional, not broken.

---

## DESIGN CONSISTENCY AS SYSTEM

Design systems aren't constraints — they're vocabulary.

- **Color Discipline** — no hardcoded values in screens. Semantic names over raw values.
- **Typography Hierarchy** — all text from the type scale. Add to the system first, then use it.
- **Spacing Rhythm** — all gaps from named values. Arbitrary numbers break rhythm.
- **Header Identity** — every screen's header follows the same pattern. Consistency is orientation.
- **Icon Coherence** — one icon family, consistent sizes, same color rules as text.

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

Premium apps feel like they *know* you.

- **First Use vs 100th Use** — a new user needs orientation (labels, hints, fuller explanations). A returning user needs speed (compact, direct, no hand-holding). Design for day 1, then design for day 100, then make them coexist.
- **Progress-Aware UI** — a beginner with 0 habits sees encouragement. A power user with 20 habits sees efficiency. The same screen, adapted to where they are in their journey.
- **Content-Volume-Aware Layout** — don't design for the ideal 8-item grid and hope it works for 1 or 200. Design the layout to breathe at every content count.
- **Recency Awareness** — something created seconds ago should feel fresh (subtle highlight, "just added" energy). Something untouched for weeks should feel patient, not stale.

---

## THE CRAFT CHECKLIST

Before shipping, interrogate every screen:

- Does tapping *anything* produce instant response — or silence?
- Does slow network reveal a designed loading state — or a blank screen?
- Does forced error guide recovery — or dead-end?
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
- Does every visible number have a label — or are there naked stats with just icons?
- Do tab roots feel like landing pages — or recycled push screens with back buttons?
- Is search integrated where content lives — or stranded in its own tab?
- Does the screen look intentionally designed in BOTH dark and light mode — or just tolerable in one?
- Does a screen with 1-3 items feel composed — or abandoned?
- Does long user-generated text gracefully truncate — or overflow/clip?
- Does every number have a formatted label — or is raw data leaking into the UI?
- Does the screen density match its type (spacious hub, dense detail, compact settings)?
- Does navigating back show your latest changes — or stale data?

---

## THE ULTIMATE TEST

1. Would someone **pay** for this?
2. Would someone **show** this to a friend?
3. Would someone **remember** this tomorrow?
4. Would someone **feel** something using this?
5. Would someone **miss** this if it disappeared?

If yes to all five — you've built something real.
