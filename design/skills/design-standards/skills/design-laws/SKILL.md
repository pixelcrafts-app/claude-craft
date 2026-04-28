---
name: design-laws
description: Platform-agnostic design laws — color strategy axis, theme scene-sentence rule, anti-AI-slop tests, absolute visual bans, category-reflex check. Apply before any design work on Web, iOS, or Android. Extracted from pbakaus/impeccable shared design laws.
origin: pbakaus/impeccable
---

# Frontend Design Laws

## Triggers

- Starting any UI design or redesign task
- Reviewing a design that feels generic or "AI-made"
- Choosing colors, theme (dark/light), layout, or motion
- Any surface where category alone predicts the aesthetic

---

## Color

Pick a **color strategy** before picking colors. Four positions on the commitment axis:

| Strategy | Surface coverage | Use for |
|----------|-----------------|---------|
| **Restrained** | Tinted neutrals + one accent ≤10% | Product UI default; brand minimalism |
| **Committed** | One saturated color at 30–60% | Brand pages, identity-driven surfaces |
| **Full palette** | 3–4 named roles, used deliberately | Brand campaigns; data viz |
| **Drenched** | Surface IS the color | Hero sections, campaign pages |

Rules:
- Use OKLCH. Reduce chroma as lightness approaches 0 or 100 — high chroma at extremes looks garish.
- Never `#000` or `#fff`. Tint every neutral toward the brand hue (chroma 0.005–0.01 is enough).
- "One accent ≤10%" is Restrained only — Committed/Full palette/Drenched exceed it on purpose. Don't collapse every design to Restrained by reflex.

---

## Theme (Dark vs Light)

Dark vs light is never a default. Not dark "because tools look cool dark." Not light "to be safe."

**Rule:** Write one sentence of physical scene before choosing. Who uses this, where, under what ambient light, in what mood. If the sentence doesn't force the answer, add detail until it does.

```
✗  "Observability dashboard"           → doesn't force an answer
✓  "SRE checking incident severity on a 27" monitor at 2am in a dim room"  → forces dark
```

Run the sentence. Never run the category.

---

## Typography

- Cap body line length at 65–75ch.
- Hierarchy through scale + weight contrast (≥1.25 ratio between steps). Flat scales are monotony.

---

## Layout

- Vary spacing for rhythm. Same padding everywhere is monotony.
- Cards are the lazy answer. Use only when truly the best affordance. Nested cards are always wrong.
- Don't wrap everything in a container. Most things don't need one.

---

## Motion

- Don't animate CSS layout properties (`top`, `left`, `width`, `height`).
- Ease out with exponential curves (ease-out-quart / quint / expo). No bounce, no elastic.

---

## Absolute Bans

Match-and-refuse. If about to write any of these, rewrite the element with different structure.

| Ban | Why | Fix |
|-----|-----|-----|
| Side-stripe borders | `border-left/right` > 1px as colored accent on cards/callouts | Full borders, background tints, leading numbers/icons, or nothing |
| Gradient text | `background-clip: text` + gradient — decorative, never meaningful | Single solid color; emphasis via weight or size |
| Glassmorphism as default | Blurs/glass cards used decoratively | Rare and purposeful only |
| Hero-metric template | Big number + small label + supporting stats + gradient accent | Rework the data presentation entirely |
| Identical card grids | Same-sized cards with icon + heading + text, repeated | Mix sizes, use a different affordance |
| Modal as first thought | Modals are usually laziness | Exhaust inline / progressive disclosure first |

---

## Copy

- Every word earns its place. No restated headings, no intros that repeat the title.
- No em dashes (`—` or `--`). Use commas, colons, semicolons, periods, or parentheses.

---

## AI Slop Tests

Run both before shipping any design:

**Test 1 — The "AI made that" test**
Could someone look at this interface and say "AI made that" without doubt? If yes, it has failed.

**Test 2 — Category-reflex check**
Could someone guess the theme and palette from the category name alone?

```
observability → dark blue
healthcare    → white + teal
finance       → navy + gold
crypto        → neon on black
```

If yes, that's the training-data reflex. Rework the scene sentence and color strategy until the answer is no longer obvious from the domain.
