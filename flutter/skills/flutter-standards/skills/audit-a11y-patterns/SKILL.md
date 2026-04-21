---
name: audit-a11y-patterns
description: Flutter-specific accessibility pattern scanner — fast regex-based sweep across lib/ for the 10 most common a11y bugs in Dart widget code (missing Semantics labels, color-alone signals, tiny touch targets, placeholder-only form fields, missing autofill hints, broken text scaling, unannounced errors, RTL violations, reduced-motion misses).
disable-model-invocation: true
argument-hint: [optional-directory]
---

# Flutter A11y Pattern Scan

Scan `$ARGUMENTS` (default: `lib/`) for ten recurring accessibility bugs that only appear in Flutter/Dart widget code. Report violations grouped by severity with file:line and a concrete fix.

**This is not THE accessibility audit — it's a fast, regex-based pattern scan** that catches the top recurring offenders with Flutter-specific greps. The full-rule a11y audit (contrast math, semantic-HTML-equivalent checks, rule-by-rule pass/fail against `accessibility.md`) runs as the `accessibility` dimension inside `premium-check` / `pre-ship` / `verify-changes` — the cross-stack engine handles iteration and reporting there. Use this command when you want a quick Dart-specific sweep; use `premium-check` when you want the full audit with fix loop.

Runtime checks (actual contrast ratios, actual touch target sizes in the rendered UI) still need the accessibility scanner in DevTools — this skill covers what's visible in source.

## Scan Targets

### 1. Missing Semantics on Interactive Elements

Icons and images used as buttons without a label are invisible to screen readers.

**Patterns to flag:**
- `IconButton(... icon: Icon(...))` without a `tooltip:` AND not wrapped in `Semantics(label: ...)`
- `GestureDetector(onTap: ..., child: Icon(...))` with no `Semantics`
- `InkWell(onTap: ..., child: Image.asset(...))` with no `Semantics` and no alt-equivalent
- `Image.asset(...)` / `Image.network(...)` without `semanticLabel:` when used as content (decorative images should have `excludeFromSemantics: true`)

**Grep:**
```
IconButton\(
GestureDetector\(
InkWell\(
Image\.(asset|network|file)\(
```

For each match, check the surrounding ~10 lines for `Semantics(`, `tooltip:`, `semanticLabel:`, or `excludeFromSemantics:`.

### 2. Color-Alone Signals

Status, error, success, and required-field indicators that communicate via color only.

**Patterns to flag:**
- `Container` with red/green/yellow background and no accompanying `Icon` or `Text`
- `Text` with `color: Colors.red` (or semantic error color) and no icon + no `Semantics`
- Dots/badges using color to indicate state (`Container(width: 8, height: 8, color: ...)`)
- Required field markers using only color (red border, red outline) without `*` or "Required" label

**Grep:**
```
color: .*(Red|Green|Yellow|Error|Success|Warning)
BoxDecoration\(.*color:
```

Flag each for manual review — check whether there's an adjacent text label or icon that carries the same meaning.

### 3. Touch Targets Smaller Than 48dp

Interactive elements must have a tappable area of at least 48×48dp (accessibility.md is strict on this).

**Patterns to flag:**
- `IconButton(iconSize: <24)` — default IconButton is 48×48 but shrinks with `padding: EdgeInsets.zero`
- `IconButton(padding: EdgeInsets.zero)` — kills the default 48dp padding
- `GestureDetector` wrapping an `Icon` with no explicit `SizedBox`/`Padding` expanding it to 48
- `InkWell` with a `child` smaller than 48dp and no `Container(constraints: BoxConstraints(minWidth: 48, minHeight: 48))`
- Custom tap areas (`onTap:` on small containers) that aren't expanded

**Grep:**
```
IconButton\(.*padding:\s*EdgeInsets\.zero
iconSize:\s*(1[0-9]|2[0-3])\b
GestureDetector\(.*child:\s*Icon
InkWell\(.*child:\s*Icon
```

### 4. Placeholder-Only Form Fields

Fields using `hintText:` / `labelText` placeholder as the only label — disappears on focus, invisible to screen readers.

**Patterns to flag:**
- `TextField` / `TextFormField` with `decoration: InputDecoration(hintText: ...)` and no visible `Text` label above AND no `labelText:` (labelText floats, still accessible)
- Search fields using only a placeholder with no `Semantics(label: ...)` wrapper

**Grep:**
```
TextField\(|TextFormField\(
```

For each match, check that one of these is present:
- A `Text('...')` widget in the same column/row before the field
- `labelText:` inside the `InputDecoration`
- A `Semantics(label: ...)` wrapper

### 5. Missing Autofill Hints

Known-type fields without `autofillHints:` break password managers and system autofill.

**Patterns to flag:**
- `keyboardType: TextInputType.emailAddress` without `autofillHints:`
- `obscureText: true` without `autofillHints: [AutofillHints.password]` or `.newPassword`
- `keyboardType: TextInputType.phone` without `autofillHints:`
- Any `TextField` in a form named "email", "password", "name", "phone", "address" without autofill hints

**Grep:**
```
keyboardType:\s*TextInputType\.(emailAddress|phone|streetAddress|name)
obscureText:\s*true
```

### 6. Broken Text Scaling

Hardcoded text sizes, fixed heights, or ignored MediaQuery text scale break large-text users.

**Patterns to flag:**
- `MediaQuery(data: ....copyWith(textScaler: TextScaler.noScaling))` — forcibly disables scaling
- `textScaleFactor: 1.0` — legacy override
- `fontSize:` with no corresponding flexible container height
- Fixed `height:` on a `Container` containing `Text` (won't grow when text scales)
- `maxLines: 1` without `overflow: TextOverflow.ellipsis` on user-generated content (clipping breaks silently for long text or big-text users)

**Grep:**
```
textScaler:\s*TextScaler\.noScaling
textScaleFactor:
maxLines:\s*1\b
```

### 7. Missing Focus Indicators

Keyboard users need a visible focus ring — disabling it breaks keyboard nav.

**Patterns to flag:**
- `FocusableActionDetector(... includeFocusSemantics: false)` without a custom indicator
- Custom tap widgets (GestureDetector) with no `Focus` widget and no visible focus state
- `Theme(data: ....copyWith(focusColor: Colors.transparent))` — hides focus

**Grep:**
```
focusColor:\s*Colors\.transparent
includeFocusSemantics:\s*false
```

### 8. Unannounced State Changes

Screen readers miss changes that happen without an announcement.

**Patterns to flag:**
- `SnackBar` shown programmatically without `SemanticsService.announce(...)` for critical messages (errors, confirmations)
- Loading-to-error state transitions with no announcement
- Form validation errors appearing without focus shifting to the invalid field

**Grep:**
```
ScaffoldMessenger\.of\(context\)\.showSnackBar
showDialog\(
```

For each, check if the surrounding logic calls `SemanticsService.announce` or moves focus.

### 9. RTL Violations

Hardcoded `left`/`right` breaks Arabic, Hebrew, Persian users.

**Patterns to flag:**
- `EdgeInsets.only(left: ...)` / `EdgeInsets.only(right: ...)` — should be `EdgeInsetsDirectional.only(start: ..., end: ...)`
- `Alignment.centerLeft` / `Alignment.centerRight` — should be `AlignmentDirectional.centerStart` / `.centerEnd`
- `Positioned(left: ...)` / `Positioned(right: ...)` — use `PositionedDirectional`
- `MainAxisAlignment.start` is OK (directional), but hardcoded `left` icons/text arrows don't flip

**Grep:**
```
EdgeInsets\.only\(.*left:
EdgeInsets\.only\(.*right:
Alignment\.(centerLeft|centerRight|topLeft|topRight|bottomLeft|bottomRight)
Positioned\(.*(left|right):
```

### 10. Reduced Motion Not Respected

Animations that don't check `MediaQuery.disableAnimations` exclude users with vestibular disorders.

**Patterns to flag:**
- `AnimatedContainer`, `AnimatedOpacity`, `AnimationController` without any check of `MediaQuery.of(context).disableAnimations`
- Auto-playing videos, parallax effects, large motion animations on screen entry

**Grep:**
```
AnimationController|AnimatedContainer|AnimatedOpacity|AnimatedPositioned
```

Flag files that use animations without importing or referencing `disableAnimations` once — they need a review for motion preference handling.

## Ignore List

Skip:
- `test/**`, `integration_test/**`
- `*.g.dart`, `*.freezed.dart` — generated code
- `lib/shared/design_system/**` or equivalent — tokens don't interact
- Files in `migrations/`, `fixtures/`
- Third-party vendored code

## Report Format

Group by severity. Critical = screen reader totally can't use; High = significant friction; Medium = degraded experience for some users.

```
# Accessibility Audit

Scope: lib/
Scanned: <N> .dart files
Violations: <total>

## Critical (screen reader blocked)

### Icon buttons without labels (7 occurrences)
  lib/features/home/widgets/app_bar.dart:34
    IconButton(icon: Icon(Icons.settings), onPressed: ...)
    Fix: add `tooltip: 'Settings'` or wrap in `Semantics(label: 'Settings', ...)`

  lib/features/profile/widgets/avatar_button.dart:22
    GestureDetector(onTap: ..., child: Image.asset('assets/avatar.png'))
    Fix: add `Semantics(label: 'Open profile', button: true, child: ...)`

### Form fields without visible labels (3 occurrences)
  lib/features/auth/signin/email_field.dart:18
    TextField(decoration: InputDecoration(hintText: 'Email'))
    Fix: add a `Text('Email')` above OR use `labelText: 'Email'` in decoration

## High (significant friction)

### Touch targets below 48dp (4 occurrences)
  lib/features/feed/widgets/like_button.dart:28
    IconButton(iconSize: 20, padding: EdgeInsets.zero, ...)
    Fix: remove `padding: EdgeInsets.zero` OR wrap in `SizedBox(width: 48, height: 48)`

### Color-alone status indicators (6 occurrences)
  lib/features/tasks/widgets/task_row.dart:45
    Container(width: 8, height: 8, color: task.isDone ? Colors.green : Colors.red)
    Fix: add an icon (check vs. circle), or a Semantics label describing the state

### Missing autofill hints (5 occurrences)
  lib/features/auth/signup/password_field.dart:12
    TextField(obscureText: true, ...)
    Fix: add `autofillHints: const [AutofillHints.newPassword]`

## Medium (degraded UX for some users)

### RTL violations — hardcoded left/right (12 occurrences)
  lib/features/profile/screen.dart:42 — EdgeInsets.only(left: 16)
  Fix: EdgeInsetsDirectional.only(start: 16)

### Fixed-height text containers (3 occurrences)
  lib/features/home/widgets/title_bar.dart:18
    Container(height: 44, child: Text('Hello')) — won't grow on large text
    Fix: remove fixed height OR use `constraints: BoxConstraints(minHeight: 44)`

### Animations without motion-preference check (9 files)
  lib/features/onboarding/welcome_screen.dart — uses AnimationController, no `disableAnimations` check
  Fix: before animating, check `MediaQuery.of(context).disableAnimations` and skip/shorten if true

## Summary
- <N> critical violations (must fix before release)
- <N> high violations (fix this sprint)
- <N> medium violations (fix opportunistically)
- Top offender folders: <list>
- Files with 3+ violations: <list>

## Fix Order (recommended)

1. **Critical first** — icon buttons and form labels unblock the entire screen-reader flow
2. **Touch targets next** — motor-impaired users lose access to core actions
3. **Color-alone signals** — fix with icon + label pairs
4. **Autofill hints** — quick wins, improve form completion rates for everyone
5. **RTL sweep** — one codemod replacing `left:`/`right:` with `start:`/`end:`
6. **Motion preferences** — wrap animation controllers in a helper that respects `disableAnimations`
```

## Before Reporting

- **Verify context** — some matches are intentional. A decorative image should have `excludeFromSemantics: true`; a color-alone dot might be inside a parent that already has a Semantics label.
- **Check design-system escape hatches** — if the app has a `AppIconButton` that wraps `IconButton` with built-in tooltips, flag raw `IconButton` uses but not the wrapper.
- **RTL caveat** — apps that explicitly don't support RTL (e.g., English-only, documented decision) can deprioritize RTL violations. Ask/check before flagging as critical.
- **Confirm severity with user** — some teams treat color-alone as critical for WCAG compliance; others treat it as high. Default per accessibility.md.

## Verdict

- **0 violations:** Rare. Double-check — the scanner may have missed patterns specific to this codebase.
- **1–5 violations:** Good hygiene. Fix in the next PR.
- **6–20 violations:** Typical app — needs a dedicated accessibility sweep.
- **20+ violations:** Systemic gap. Recommend a design-system-level fix: `AppIconButton`, `AppTextField`, `AppStatusIndicator` that bake in Semantics, autofill hints, and icon+label pairs so the violations can't be reintroduced.

## Pairs With

- `accessibility` (auto-invoke standard) — the full rule set; the engine iterates this rule-by-rule inside `premium-check` / `pre-ship`. This pattern scan is a fast subset focused on Flutter-specific gotchas.
- `find-hardcoded` — overlaps on some patterns (hardcoded colors often carry color-alone issues).
- `premium-check` — the full craft + widget + a11y + perf audit; invokes the engine with `accessibility` as one of its dimensions. Use that for the complete walk; use this command when you want speed.
