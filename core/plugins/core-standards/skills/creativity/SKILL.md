---
name: creativity
description: Apply when designing any UI — web or mobile. Teaches what separates memorable, ownable UI from functional but forgettable. Auto-invoke when generating screens, components, or interaction patterns.
---

# Creativity

## The One Boundary

Design decisions (layout, color, animation, typography) can be questioned and changed. Engineering requirements (data verification, auth guards, error states, accessibility) cannot be skipped for aesthetics.

## Signature Moments

Every product needs 1–3 interactions that are specific to this product only. Before shipping:

- Identify the 3 actions users repeat most
- Polish each until the feedback (visual + haptic/audio) feels inevitable
- If an interaction could belong to any app, it is not a signature — make it specific

## Reduction Before Addition

Before adding any element: remove something first.

- Every screen element must earn its place by informing a user decision
- If removing it does not break the flow, it should never have been there
- White space is structure, not emptiness — it controls focus and pace

## Contrast as Hierarchy Tool

Typography hierarchy is achieved through contrast, not decoration:

- Weight contrast: difference of ≥200 between adjacent levels (400 vs 600, 600 vs 800)
- Size contrast: ≥4px difference between adjacent levels
- Color contrast: secondary text at 60% opacity of primary text
- Never use more than 3 levels of hierarchy on one screen

## Motion as Communication

- Entrance: slide from right (going deeper), slide from bottom (modal/sheet), scale up from tap point (expand)
- Exit: reverse of entrance — slide left for back, scale down for dismiss
- Micro-interaction on tap: scale to 0.96 (100ms), spring back to 1.0 (200ms, elasticOut)
- Micro-interaction duration: 100–200ms. State transition: 300–400ms. Page entrance: 400–600ms total.
- Entry easing: ease-out (decelerate from edge). Exit easing: ease-in (accelerate toward edge).
- Stagger delay between sequential list items: 50–100ms per item.
- Spring physics over linear/ease: use damping and stiffness parameters, not arbitrary curves.
- Remove any animation that does not communicate direction, confirm an action, or signal state change.

## State as Personality

The presence of empty, error, and loading states is an engineering requirement — they are never optional. Their content and craft is where personality lives:

- Empty: explains what belongs here + shows path to create it. Not "No items found."
- Error: names the specific failure + gives the next step. Not "Something went wrong."
- Loading: skeleton matches the real layout exactly. Not a spinner in a void.

These three states appear before any data exists — they are the first impression.

## Interaction Targets

- Minimum tap target: ≥48×48dp (web: ≥44px). Never rely on visual size — extend hit area with padding.
- Minimum gap between adjacent targets: ≥8dp / ≥8px
- Focus state: 2px outline, 2px offset, primary color. Never remove without equivalent replacement.
- Disabled state: 40% opacity + cursor:not-allowed + no hover state + tooltip explaining why

## Haptic Intensity Rules

- `lightImpact` — standard taps, toggle switches, selection changes
- `mediumImpact` — completing an action, confirming a choice
- `heavyImpact` — destructive actions, significant milestones
- `selectionClick` — picker scrolling, slider ticks
- Check user haptic preference before firing

## Delight Audit (run on every screen before shipping)

- Primary action tap → visual response within ≤100ms?
- Loading state uses skeleton matching the final layout (not a spinner in a void)?
- Back navigation shows the user's most recent change immediately (no stale data)?
- Error message names the specific failure and gives a concrete next step?
- Every interactive element has a visually distinct focus state?
- One element on this screen uses a treatment specific to this product (not generic UI)?
