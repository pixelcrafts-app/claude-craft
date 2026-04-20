---
name: accessibility
description: Apply when building Flutter UI — Semantics labels, 4.5:1 contrast, 48dp touch targets, no color-alone signals, text scaling to 200%, reduced motion, RTL via EdgeInsetsDirectional, focus indicators, screen reader announcements. Auto-invoke on any interactive widget or form field change.
---

# Accessibility Rules

Concrete patterns for building apps that work for every user — screen-reader, low-vision, motor-impaired, seizure-sensitive, non-English-primary, and ability-shifting users. Implements the craft guide's "Accessibility As Craft" and flutter.md's accessibility checklist — does not restate them.

Accessibility is not a compliance checkbox. It's the difference between an app that serves everyone and one that locks out 15% of users.

---

## Semantics — Every Interactive Element

- Every tappable/swipeable element has a **Semantics label describing the ACTION**, not the element type
  - ✅ `Semantics(label: 'Play song', button: true, child: ...)`
  - ❌ `Semantics(label: 'Button', ...)`
- Use built-in widgets when possible — `IconButton`, `TextButton`, `InkWell` expose semantics for free
- For custom widgets: wrap in `Semantics(...)` or use `MergeSemantics` to combine children into one node
- Decorative icons: `ExcludeSemantics(child: icon)` — screen readers skip them
- Informative icons: `Semantics(label: '<meaning>', child: icon)` — announce the meaning

---

## Touch Targets

- Minimum **48×48 dp** for every interactive element (see flutter.md for implementation)
- If the visible element is smaller, wrap in `SizedBox(width: 48, height: 48, child: Center(child: ...))` or expand hit area with `GestureDetector` + padding
- Targets on edges/corners: extend toward the edge to make them easier to hit one-handed
- Spacing between adjacent targets: minimum 8 dp — users with tremor or thick fingers shouldn't hit the wrong one

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
- Text on images: always use a gradient scrim or solid background layer (flutter.md Images section)

---

## Never Rely on Color Alone

Color must never be the only way a user learns something. Always pair color with:

- **Text** — "Error: invalid date" + red, not just red
- **Icon** — ❌/✓/⚠ alongside color
- **Shape/position** — checkbox checked state uses both color AND checkmark
- **Pattern/stroke** — chart series use color AND line style (solid/dashed/dotted)

Use cases where this matters most: form validation, status indicators, chart legends, selection state, required-field markers.

---

## Text Scaling

- Respect `MediaQuery.textScaleFactorOf(context)` — never override to fixed value
- Test at **0.85×, 1.0×, 1.3×, 2.0×** — the UI must remain usable, not pixel-perfect
- Use `FittedBox` sparingly — it can make text smaller, defeating user intent
- Multi-line text: set reasonable `maxLines` with fade/ellipsis, never truncate at 1 line for content the user chose
- Buttons with text: must grow vertically, never clip text. Pair `Flexible` + `maxLines: 2` for button labels that might scale
- Icons paired with text should scale with text — use `IconTheme` driven by text scale

---

## Bold Text

- Respect `MediaQuery.boldTextOf(context)` — many users with low vision enable OS-wide bold
- Use relative weights (`regular`, `semiBold`, `bold`) from the typography scale — bold users get their preference applied automatically
- Never pin font weight to numeric values (`FontWeight.w400`) in ways that ignore the system setting

---

## Reduced Motion

- Check `MediaQuery.of(context).disableAnimations` OR `reduceMotion`
- When enabled:
  - **Skip** decorative animations (stagger entrances, hero choreography, confetti, pulses)
  - **Keep** functional transitions (page navigation, modal presentation) — but make them instant or near-instant
  - **Replace** parallax/auto-scroll with static presentation
- Never treat reduced motion as "broken" — the alternative experience should feel intentional
- Test with reduced motion enabled — no skipped state transitions, no invisible-until-animated content

---

## Screen Reader Flows

- Every critical user journey must be completable with TalkBack (Android) and VoiceOver (iOS) — test manually before shipping auth, checkout, and primary task flows
- Announce **dynamic state changes** using `SemanticsService.announce(message, TextDirection.ltr)`:
  - "Added to cart"
  - "Form saved"
  - "Loading" → "Loaded 12 items"
- Focus order: logical, matches visual reading order (top-to-bottom, leading-to-trailing in LTR)
- Custom focus order: use `FocusTraversalGroup` + `FocusTraversalOrder` rather than fighting defaults
- Modals/dialogs: focus moves in, must return to origin on dismiss

---

## Keyboard & Focus

- Every interactive element must be focusable via keyboard navigation (Flutter: `Focus`/`FocusNode`)
- Visible focus indicator on every focusable element — outlined ring or highlight, minimum 3:1 contrast against unfocused state
- Never remove focus indicators without providing a replacement
- Text fields: `autofocus: true` on the primary field of a form; subsequent fields reached via `TextInputAction.next`
- Escape/back closes modals and returns focus to the opener

---

## Form Accessibility

- Every field has a **visible label** — never placeholder-only. Placeholders disappear on focus, leaving users lost.
- Every field has a **Semantics label** matching the visible label
- Required fields: marked with both a visual indicator (asterisk, "Required" text) AND a `Semantics(label: 'Required')` hint
- Errors: announced to screen readers via `SemanticsService.announce` when validation fails
- Error messages: attached to the field, not floating. Screen readers should read them when the field gains focus.
- Autofill hints: `autofillHints: [AutofillHints.email]` etc. — helps both users and password managers

---

## Images & Media

- Every content image: `Semantics(label: '<description>', image: true, child: Image(...))`
- Decorative images (spacers, background flourishes): `ExcludeSemantics` — don't make screen readers read them
- Image loading placeholders announce loading state
- Video: captions available, transcript linked for long content
- Audio: transcript or captions
- Autoplaying media: muted by default, with controls accessible

---

## Animations — Seizure Safety

- No flashing content more than **3 times per second** — WCAG 2.3.1
- No large-area rapid brightness changes
- Strobing/flicker effects behind a user-disablable setting, never default-on
- If in doubt, slow it down — premium apps don't need to strobe

---

## RTL & Bidirectional Text

- Use `EdgeInsetsDirectional` over `EdgeInsets` — `.start`/`.end` flip correctly in RTL
- Use `AlignmentDirectional` over `Alignment`
- Use `Icon(Icons.arrow_forward)` only when semantically "forward in reading direction" — use `Icons.arrow_forward` + automatic mirroring via `matchTextDirection` on decorations
- Test with a full Arabic/Hebrew locale, not just `textDirection: rtl` override — fonts, numerals, and layouts all shift
- Numerals: decide per-locale whether to use Arabic-Indic or Western digits — `intl` handles this

---

## Hit Testing & Overlays

- No invisible overlays blocking touches — transparent widgets with `ignoring: false` are a common trap
- `IgnorePointer` / `AbsorbPointer` only where intentional; never "just to make it compile"
- Gesture regions don't extend outside their visual bounds — users shouldn't trigger actions they can't see

---

## Platform Defaults

- Use `CupertinoApp` / `MaterialApp` with adaptive widgets when the app targets both platforms — platform screen readers expect platform idioms
- `Switch.adaptive`, `Slider.adaptive`, `CircularProgressIndicator.adaptive` — free accessibility wins
- Never force one platform's paradigm on the other

---

## Testing Accessibility

- Widget tests: use `SemanticsTester` and `expect(semantics, includesNodeWith(label: ...))`
- Manual: walk every critical flow with screen reader ON, eyes CLOSED
- Manual: navigate with keyboard only (Tab + Enter + arrows) on supported platforms
- Manual: enable OS reduced motion and complete primary flows
- Manual: set text scale to 2.0× and check for clipped/overlapping content
- Automated: include a11y lints in CI (`flutter_lints` + manual audits)

---

## DON'TS

- Don't use color as the only indicator of state, meaning, or action
- Don't remove focus indicators without replacement
- Don't use placeholder text as a label substitute
- Don't hardcode `textScaleFactor` to 1.0
- Don't block all animations from users who want them — and don't force them on users who don't
- Don't use `Semantics(label: 'button')` — label the action, not the widget type
- Don't skip screen-reader testing because "we'll do it later" — later never comes
- Don't assume your app is accessible because `flutter analyze` passes
