---
name: accessibility
description: Apply when building Flutter UI — Semantics labels, 4.5:1 contrast, 48dp touch targets, no color-alone signals, text scaling to 200%, reduced motion, RTL via EdgeInsetsDirectional, focus indicators, screen reader announcements. Auto-invoke on any interactive widget or form field change.
---

# Accessibility Rules

Concrete patterns for building apps that work for every user — screen-reader, low-vision, motor-impaired, seizure-sensitive, non-English-primary, and ability-shifting users. See `mobile-standards:craft-guide` for accessibility-as-craft aesthetic principles — not restated here.

Accessibility is not a compliance checkbox. It's the difference between an app that serves everyone and one that locks out 15% of users.

---

## Semantics — Every Interactive Element

- Every tappable/swipeable element has a **Semantics label describing the ACTION**, not the element type — label the action performed, never the widget type (e.g. never `label: 'Button'`)
- Use built-in widgets when possible — `IconButton`, `TextButton`, `InkWell` expose semantics for free
- For custom widgets: wrap in `Semantics` or use `MergeSemantics` to combine children into one node
- Decorative icons: wrap in `ExcludeSemantics` — screen readers skip them
- Informative icons: wrap in `Semantics` with a label announcing the meaning, not the icon name
- Set `button: true`, `header: true`, `checked`, `selected`, and other semantic flags that match the role of the element

---

## Touch Targets

Touch target sizing and hit-area implementation are covered in `flutter-standards:engineering §Widget Patterns`. Follow those rules. Accessibility-specific additions:

- Targets on edges/corners: extend toward the edge to make them easier to hit one-handed
- Spacing between adjacent targets: minimum 8 dp — users with tremor or thick fingers must not trigger the wrong target

---

## Color Contrast

| Element | Minimum ratio | Against |
|---------|---------------|---------|
| Body text (<18pt regular, <14pt bold) | **4.5:1** | background |
| Large text (≥18pt regular, ≥14pt bold) | **3:1** | background |
| Icons + essential UI elements | **3:1** | background |
| Focus indicators | **3:1** | unfocused state |
| Disabled elements | no minimum (but convey disabled state with more than color) |

- Verify with a contrast tool, not by eye
- Test BOTH dark and light themes — one usually passes and one usually doesn't
- Text on images: always use a gradient scrim or solid background layer

---

## Text Scaling

- Respect `MediaQuery.of(context).textScaleFactor` — never override to a fixed value
- Test at **0.85×, 1.0×, 1.3×, 2.0×** — the UI must remain usable, not pixel-perfect
- Use `FittedBox` sparingly — it can make text smaller, defeating user intent
- Multi-line text: set reasonable `maxLines` with fade/ellipsis, never truncate at 1 line for content the user chose
- Buttons with text: must grow vertically, never clip text — pair `Flexible` with `maxLines: 2` for button labels that may scale
- Icons paired with text should scale with text — use `IconTheme` driven by text scale

---

## Bold Text

- Respect `MediaQuery.boldTextOf(context)` — many users with low vision enable OS-wide bold
- Use relative weights (`regular`, `semiBold`, `bold`) from the typography scale — bold users get their preference applied automatically
- Never pin font weight to numeric values in ways that ignore the system bold setting

---

## Reduced Motion

- Check `MediaQuery.disableAnimations`. When true: remove decorative animations entirely. Functional transitions (navigation, modals) remain but cap at 150ms.
- **Remove** decorative animations (stagger entrances, hero choreography, confetti, pulses)
- **Replace** parallax/auto-scroll with static presentation
- Never treat reduced motion as "broken" — the alternative experience should feel intentional
- Test with reduced motion enabled — no skipped state transitions, no invisible-until-animated content

---

## Screen Reader Flows

- Every critical user journey must be completable with TalkBack (Android) and VoiceOver (iOS) — test manually before shipping auth, checkout, and primary task flows
- Announce **dynamic state changes** using `SemanticsService.announce` with the appropriate `TextDirection`
  - Announce confirmations: "Added to cart", "Form saved"
  - Announce loading transitions: "Loading" → "Loaded 12 items"
- Focus order: logical, matches visual reading order (top-to-bottom, leading-to-trailing in LTR)
- Custom focus order: use `FocusTraversalGroup` and `FocusTraversalOrder` rather than fighting defaults
- Modals/dialogs: focus moves in on open, must return to origin on dismiss

### Screen Reader Verification

- Test every critical flow (auth, main actions, checkout) with VoiceOver (iOS) and TalkBack (Android)
- Critical = user cannot complete the app's core value without it
- Test: can a screen reader user log in, use the main feature, and navigate back?

---

## Keyboard & Focus

- Every interactive element must be focusable via keyboard navigation using `Focus`/`FocusNode`
- Visible focus indicator on every focusable element — outlined ring or highlight, minimum 3:1 contrast against unfocused state
- Never remove focus indicators without providing a replacement
- Text fields: `autofocus: true` on the primary field of a form, only when the screen's primary purpose is that form — never autofocus on screens where the form is secondary; subsequent fields reached via `TextInputAction.next`
- Escape/back closes modals and returns focus to the opener

### Focus Traversal

- Tab order follows visual reading order (top-left to bottom-right for LTR)
- `FocusTraversalGroup` to isolate focus within modals and bottom sheets
- On modal open: move focus to modal. On modal close: restore focus to the trigger element.
- Never trap focus outside a modal

---

## Form Accessibility

- Every field has a **visible label** — never placeholder-only; placeholders disappear on focus, leaving users lost
- Every field has a **Semantics label** matching the visible label
- Required fields: marked with both a visual indicator (asterisk or "Required" text) AND a Semantics hint marking it required
- Errors: announced to screen readers via `SemanticsService.announce` when validation fails
- Error messages: attached to the field, not floating — screen readers should read them when the field gains focus
- Autofill hints: set `autofillHints` appropriately — helps both users and password managers

---

## Images & Media

General image widget handling is covered in `flutter-standards:engineering §Widget Patterns`. Flutter-specific accessibility rules:

- Content images: wrap in `Semantics` with a descriptive label and `image: true` — the label must describe what the image conveys, not just its file name
- Decorative images (spacers, background flourishes): wrap in `ExcludeSemantics` — do not make screen readers announce them
- Image loading placeholders must announce loading state to screen readers
- Video: captions must be available; link a transcript for long content
- Audio: provide a transcript or captions
- Autoplaying media: muted by default, with controls accessible via keyboard and screen reader

---

## RTL & Bidirectional Text

- Use `EdgeInsetsDirectional` over `EdgeInsets` — `.start`/`.end` flip correctly in RTL
- Use `AlignmentDirectional` over `Alignment`
- Use directional icons only when semantically "forward in reading direction" — use `matchTextDirection` on decorations for automatic mirroring
- Test with a full Arabic/Hebrew locale, not just a `textDirection` override — fonts, numerals, and layouts all shift
- Numerals: decide per-locale whether to use Arabic-Indic or Western digits — the `intl` package handles this

---

## Hit Testing & Overlays

- No invisible overlays blocking touches — transparent widgets with pointer-interception enabled are a common trap
- `IgnorePointer` / `AbsorbPointer` only where intentional; never as a workaround
- Gesture regions must not extend outside their visual bounds — users must not trigger actions they cannot see

---

## Platform Defaults

- Use `CupertinoApp` / `MaterialApp` with adaptive widgets when targeting both platforms — platform screen readers expect platform idioms
- Prefer adaptive variants (`Switch.adaptive`, `Slider.adaptive`, `CircularProgressIndicator.adaptive`) — they deliver platform-correct accessibility behavior for free
- Never force one platform's paradigm on the other

---

## Testing Accessibility

- Widget tests: use `SemanticsTester` and assert nodes with expected labels, roles, and flags
- Manual: walk every critical flow with screen reader ON, eyes CLOSED
- Manual: navigate with keyboard only (Tab + Enter + arrows) on supported platforms
- Manual: enable OS reduced motion and complete primary flows
- Manual: set text scale to 2.0× and check for clipped or overlapping content
- Automated: include accessibility lints in CI (`flutter_lints` plus manual audits)

---

## DON'TS

- Don't remove focus indicators without replacement
- Don't use placeholder text as a label substitute
- Don't hardcode `textScaleFactor` to 1.0
- Don't block all animations from users who want them — and don't force them on users who don't
- Don't label the widget type in a Semantics label — label the action
- Don't skip screen-reader testing because "we'll do it later" — later never comes
- Don't assume the app is accessible because `flutter analyze` passes
