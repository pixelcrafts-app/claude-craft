---
name: widget-rules
description: Apply when writing Flutter widgets — const usage, stateful vs stateless choice, animation scope (never the whole screen), text resilience with maxLines/overflow, image scrims, Prototype Exception. Auto-invoke when creating or editing widget code in lib/.
---

# Flutter UI Implementation Rules

Concrete code patterns for Flutter widgets, animations, layout, and interaction. Implements the craft guide's design philosophy — does not restate it.

---

## Design System Tokens — No Exceptions

- All colors from design system constants — zero hardcoded hex/RGBA in widgets
- All text styles from the typography scale — zero inline TextStyle declarations
- All spacing from named constants — zero magic number EdgeInsets or SizedBox values
- All radii from named constants — zero inline BorderRadius
- All elevation/shadow from named constants — zero inline BoxShadow with arbitrary values
- Icon sizes follow the system standard sizes only (e.g., 20, 24, 28)
- One icon family per project — never mix icon packages

**Prototype Exception:** During explicit prototyping phases (user says "prototype", "experiment", or "explore"), hardcoded values are acceptable as `// TODO: move to design system` markers. Before any completion/PR, all must be migrated to design system tokens.

---

## Animation & Motion

### Spring Physics
- Use spring curves (`Curves.elasticOut`, `Curves.easeOutBack`) over linear or basic easeOut
- `flutter_animate` for stagger sequences and choreographed entrances
- `AnimatedContainer`, `AnimatedOpacity`, `AnimatedScale` for simple state transitions

### Duration Standards
- Micro-interactions (tap feedback, toggles): 100-200ms
- Screen transitions: 300-400ms
- Stagger delay between list items: 50-100ms
- Page entrance animations: 400-600ms total sequence

### 3-Layer Animation Stack (Implementation)
1. **Container** — position, size (300ms, decelerate curve)
2. **Content** — opacity, scale (200ms, stagger 50-100ms between items)
3. **Details** — icons, badges (150ms, after content settles)

### Reduced Motion
- Check `MediaQuery.of(context).disableAnimations` or `reduceMotion`
- When enabled: skip decorative animations, keep functional transitions (page navigation)

---

## Tap & Touch Interaction

### Touch Targets
- Minimum 48px height AND width for all interactive elements
- Comfortable: 56px for primary actions
- If visual element is smaller, expand hit area with padding or `GestureDetector`

### Tap Feedback Pattern
```
onTapDown → scale to 0.96 (100ms)
onTapUp/onTapCancel → spring back to 1.0 (200ms, elasticOut)
```
- Use `GestureDetector` + `AnimatedScale` or `Transform.scale` for custom elements
- Use `InkWell` for Material-style ripple on flat surfaces

### Haptic Feedback
- `HapticFeedback.lightImpact()` — standard taps, toggle switches, selection
- `HapticFeedback.mediumImpact()` — completing an action, confirming a choice
- `HapticFeedback.heavyImpact()` — destructive actions, significant milestones
- `HapticFeedback.selectionClick()` — picker scrolling, slider ticks
- Haptic fires 10-50ms AFTER the visual response, not simultaneously
- Respect user's haptic settings — check before firing

---

## Headers & Screen Structure

### Header Pattern
- Every screen's header: same back button style, same title position, same height
- Back button: leading position, consistent icon and size across all screens
- Title: same typography token, same alignment

### Screen Structure
```
SafeArea
  └─ Column / CustomScrollView
       ├─ Header (consistent pattern)
       ├─ Content area
       └─ Bottom action (if any, in thumb zone)
```

---

## Loading State Implementation

- Skeleton/placeholder shape and spacing must match final layout exactly (same card dimensions, text line widths)
- Loading indicator style is app-specific — use whatever the app already uses consistently (shimmer, skeleton, pulse, etc.)
- Loading colors: subtle surface variation, not high contrast
- For waits >2s, show tips/quotes alongside the loading state
- Never show a blank screen or a centered spinner as the only loading state

---

## Color Implementation

- Semantic color names: `surface`, `surfaceVariant`, `primary`, `error` — not `grey800`, `blue500`
- Apply color temperature states per the craft guide using design system tokens

---

## Typography Implementation

- Use the full weight range: regular, medium, semiBold, bold
- Letter spacing values: large headlines negative (-0.5 to -1.0), ALL CAPS positive (+1.0 to +1.5), small labels slightly positive

### Text Resilience
- Long text: use `maxLines` + `TextOverflow.ellipsis` — never let text overflow its container
- User-generated text (names, titles): always assume it could be 3x longer than your test data
- Single-line labels: constrain with `maxLines: 1`. Multi-line bodies: set a sensible `maxLines` with fade or ellipsis.
- Numbers: format with locale-aware separators (1,234 not 1234). Use `intl` package.
- Relative time: "2h ago", "Yesterday", "Mar 3" — never raw ISO timestamps in UI
- Units always labeled: "5 min" not "5", "3 of 12" not "3/12"

---

## Depth & Elevation Implementation

- Subtle border: `Border.all` with color at 5-10% alpha for card edges
- Background blur: `BackdropFilter` for overlays and sheets
- If using shadows: consistent across same-level elements, values from design system

---

## Safe Areas & Layout

- Always wrap with `SafeArea` or account for `MediaQuery.padding`
- Account for: notch, Dynamic Island, home indicator, system status bar
- Keyboard: use `MediaQuery.viewInsets.bottom` for keyboard-aware padding
- Bottom actions: position above home indicator, not on it

---

## Scroll & Lists

- Lists >20 items: `ListView.builder` or `SliverList` (virtualized)
- Short lists (<20 items): `Column` with `SingleChildScrollView` is fine
- Pull-to-refresh: `RefreshIndicator` + `AlwaysScrollableScrollPhysics`
- Platform scroll physics: `BouncingScrollPhysics` (iOS), `ClampingScrollPhysics` (Android)

---

## Images

- Decode at display size: `cacheWidth`/`cacheHeight` on `Image`
- Progressive loading: placeholder color → blur/low-res → full resolution
- Use `CachedNetworkImage` for remote images
- Below-the-fold images: load on demand (lazy), not on screen arrival
- Error fallback: subtle placeholder icon, not a broken image indicator
- Text over images: always add a gradient scrim or backdrop for guaranteed contrast — never rely on image content being "probably dark enough"
- Image-dominant screens: reduce UI chrome prominence. Let the content breathe. Navigation and actions should recede, not compete.

---

## Destructive Actions Implementation

- Delete/remove: show 3-5 second undo `SnackBar` before executing
- "Queued for deletion" — execute after undo window closes
- Confirmation dialogs for irreversible actions (account deletion, data wipe)

---

## Dart Standards

- `withValues(alpha:)` not `withOpacity()` (deprecated in Flutter 3.27+)
- `const` constructors wherever possible
- Prefer `final` over `var` — immutability by default
- Named parameters for functions with more than 2 parameters
- Use `switch` expressions over `switch` statements where applicable

---

## State Management (Widget Level)

- Only rebuild what changed — never the whole tree for one value update
- Computation belongs in the state layer, never in the render path

---

## Performance

- No blocking operations on the main isolate — use `compute()` for heavy work
- Avoid unnecessary `setState()` — rebuild only what changed
- `RepaintBoundary` around expensive widgets that repaint independently
- `const` widgets wherever possible to skip rebuild
- Profile with DevTools before optimizing — measure, don't guess

---

## Accessibility Implementation

- Semantic labels on all interactive elements (describe the action, not the element type)
- Text contrast: 4.5:1 minimum — verify with design system tokens
- Respect `MediaQuery.boldTextOf(context)` and `textScaleFactor`
- Test with screen reader (TalkBack / VoiceOver) for critical flows

---

## Guards & Safety

- `mounted` check before `setState()` in async callbacks
- Null-safe access on all provider data — never force-unwrap
- Dispose all controllers, subscriptions, `AnimationController`s, and listeners in `dispose()`
