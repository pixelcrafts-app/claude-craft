---
name: premium-signals
description: Apply when building or reviewing mobile UI for premium polish — iOS Liquid Glass, Material You color extraction, bottom sheet detents, haptic timing, scroll-driven animation, button micro-interactions, empty state formula. Overlays craft-guide foundations with market-sourced precise values. Auto-invoke on any screen that must feel native-quality, not cross-platform template.
---

# Mobile Premium Signals

Rules derived from auditing iOS 26 UIKit/SwiftUI, Material You, Things 3, Superhuman iOS, Arc Mobile, and Apple Design Award winners. Every value was found in a shipped product.

Craft-guide provides the foundation rules. This skill provides the precise values that separate platform-quality from generic.

---

## PLATFORM-NATIVE MOTION

### iOS — Spring Physics Constants
Spring motion over tween/ease curves for all interactive elements.

```swift
// Standard interactive spring (panel presentation, card reveal)
.animation(.spring(response: 0.35, dampingFraction: 0.7), value: isExpanded)

// Snappy spring (toggle, selection, quick feedback)
.animation(.spring(response: 0.25, dampingFraction: 0.8), value: isSelected)

// Gentle spring (large modal, sheet entrance)
.animation(.spring(response: 0.5, dampingFraction: 0.75), value: isPresented)
```

### Android — Predictive Back + Material Motion
Predictive back gesture: scale destination screen `0.95 → 1.0` during drag. Velocity-matched on release — do not animate to a fixed endpoint, read the drag velocity and continue.

Material motion: `FastOutSlowIn` for entering elements, `FastOutLinearIn` for exiting, `LinearOutSlowIn` for incoming. Never `AccelerateDecelerateInterpolator` on UI elements (looks mechanical).

### Timing Hierarchy
- Micro (tap feedback, toggle, haptic confirm): `100–200ms`
- State transitions (show/hide, push/pop): `300–400ms`
- Entrance sequences (page load, modal present): `400–600ms`
- Stagger between list items: `50–100ms` per item, cap total at `400ms`

Never animate more than 3 concurrent elements without stagger. Everything animating simultaneously reads as glitchy.

---

## iOS LIQUID GLASS (iOS 26 / visionOS)

Liquid Glass is Apple's 2026 design language: translucent chrome with animated specular highlights and spring-physics morphing.

### Tab Bar — Liquid Glass
```swift
TabView {
  ContentView()
    .tabItem { Label("Home", systemImage: "house") }
}
.tabBarMinimizeBehavior(.onScrollDown)

// Corner radius for floating glass tab bar
.clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
```

Background material: `.ultraThinMaterial` or `.regularMaterial` depending on content density behind the bar. Never a solid fill — the glass requires the blur.

### Navigation Bar — Adaptive Glass
```swift
.toolbarBackground(.ultraThinMaterial, for: .navigationBar)
.toolbarBackgroundVisibility(.automatic, for: .navigationBar)
```

`automatic` means the bar becomes solid only when content scrolls beneath it. At top of scroll: fully translucent. After first `ScrollView` offset: material kicks in. This matches iOS Calendar, Photos, and Messages behavior.

### Specular Highlights
Liquid Glass panels have a subtle gradient overlay (inner highlight) that shifts with device orientation via CoreMotion parallax. If implementing without native UIKit: a 3–8% white radial gradient `from top-left`, simulates the specular without motion tracking.

---

## MATERIAL YOU (Android / Cross-Platform)

### Dynamic Color Extraction
```kotlin
// Jetpack Compose — extract palette from user wallpaper
val dynamicColorScheme = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
    dynamicLightColorScheme(context) // or dynamicDarkColorScheme
} else {
    // Fallback to brand palette
    lightColorScheme(primary = BrandPrimary, ...)
}
```

Provide a `DynamicColorSource` from the user's wallpaper when available (Android 12+). Always have a brand-defined fallback — never crash or show gray on older Android.

### Tonal Surface Hierarchy (Material 3)
Material You uses tonal elevation — surfaces at higher elevation get a tint of the primary color mixed in at increasing percentages:

| Level | Primary tint | dp elevation |
|---|---|---|
| Surface | 0% | 0 |
| Surface+1 | 5% | 1 |
| Surface+2 | 8% | 3 |
| Surface+3 | 11% | 6 |
| Surface+4 | 12% | 8 |
| Surface+5 | 14% | 12 |

Never use literal shadow elevation in dark mode — use tonal elevation only (box shadow is invisible on dark surfaces).

---

## BOTTOM SHEETS & MODALS

### iOS Sheet Detents
```swift
.sheet(isPresented: $isPresented) {
  ContentView()
    .presentationDetents([
      .fraction(0.15),   // peek / handle-only
      .fraction(0.5),    // half-screen  
      .large             // full-screen
    ])
    .presentationDragIndicator(.visible)
    .presentationCornerRadius(28)
}
```

Corner radius `28` is the iOS 26 standard for sheets. `presentationDragIndicator(.visible)` always — never hide the drag handle, it signals dismissibility.

Detents must be an intentional choice for the content: `.fraction(0.15)` for persistent utility (mini-player, snooze bar), `.fraction(0.5)` for secondary info, `.large` for primary workflows.

### Modal Backdrop
Dark mode: `rgba(0, 0, 0, 0.5)` backdrop behind sheets. Light mode: `rgba(0, 0, 0, 0.25)`. Never a colored backdrop — it competes with the modal content.

### Dismissal Gesture
Sheet must dismiss on both: downward swipe AND tap on backdrop. If tap-on-backdrop dismiss is disabled (for important modals), add a visible close button in the top-right corner.

---

## HAPTIC PATTERNS

### Haptic Timing Rule
Haptic fires `10–50ms` after visual response — never simultaneously. The visual leads; haptic follows. Simultaneous visual+haptic reads as a single blunt sensation. The brief offset makes them feel layered and intentional.

### Intensity Mapping

| Action | iOS | Android |
|---|---|---|
| Toggle switch, selection change, picker scroll | `UIImpactFeedbackGenerator(style: .light)` | `VibrationEffect.createPredefined(CLICK)` |
| Completing an action, confirming a choice | `UIImpactFeedbackGenerator(style: .medium)` | `VibrationEffect.createPredefined(HEAVY_CLICK)` |
| Destructive action, significant milestone, error | `UIImpactFeedbackGenerator(style: .heavy)` | `VibrationEffect.createPredefined(DOUBLE_CLICK)` |
| Slider ticks, digit scroll, picker snap | `UISelectionFeedbackGenerator()` | `VibrationEffect.createWaveform([0, 20], [80])` |
| Success / milestone | `UINotificationFeedbackGenerator().notificationOccurred(.success)` | `VibrationEffect.createPredefined(TICK)` |

Always check `CHHapticEngine.capabilitiesForHardware().supportsHaptics` before firing. Silent fail on devices without haptics — never show UI error.

---

## SCROLL-DRIVEN ANIMATION

### CSS — Web-Native Scroll Animation
```css
@keyframes fade-in-up {
  from { opacity: 0; transform: translateY(24px); }
  to   { opacity: 1; transform: translateY(0); }
}

.scroll-reveal {
  animation: fade-in-up linear both;
  animation-timeline: view();
  animation-range: entry 0% entry 30%;
}
```

`animation-timeline: view()` — no JavaScript, no IntersectionObserver. Chrome 115+, Safari 18+. Provide `@supports` fallback: elements visible without animation on older browsers.

### Native Mobile Scroll Animation
```swift
// SwiftUI — phase-based scroll animation
.scrollTransition(.animated(.spring(response: 0.35, dampingFraction: 0.7))) { content, phase in
  content
    .opacity(phase.isIdentity ? 1 : 0.3)
    .scaleEffect(phase.isIdentity ? 1 : 0.85)
    .blur(radius: phase.isIdentity ? 0 : 3)
}
```

`.isIdentity` = element fully in viewport. Animate toward identity on enter, away from identity on exit.

---

## BUTTON MICRO-INTERACTIONS

### Web — Exact Timing
```css
.btn {
  transition: background-color 100ms ease-out,    /* hover response */
              transform 60ms ease-in,              /* press response */
              box-shadow 100ms ease-out;
}
.btn:hover  { background-color: var(--primary-hover); }
.btn:active { transform: scale(0.97); }
```

- Hover: `100ms ease-out`
- Press: `60ms ease-in` (feels instant and physical)
- Release: `100ms ease-out` (spring back)

### iOS — SwiftUI Button Feel
```swift
Button(action: onTap) {
  label
}
.buttonStyle(.plain)
.scaleEffect(isPressed ? 0.96 : 1.0)
.animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
```

Scale target on press: `0.96–0.97` — enough to feel tactile, not enough to feel broken.

---

## EMPTY STATE FORMULA

Three components — all required, nothing more:

1. **Illustration** — monochrome, stroke weight matched to the app's icon library stroke. Not stock SVG. Not 3D. Not AI-generated clipart. If the icon library is 1.5px stroke, the illustration is 1.5px stroke.

2. **One sentence** — names what is missing AND implies the benefit of having it. Format: `"[What's missing] [gives you/lets you/means you can]..."`. Not: "No items found." Not: "You haven't added anything yet."

3. **Single CTA** — specific verb + object. "Create your first project." "Add a task." Not "Get started." Not "OK."

No subtext. No secondary buttons. No multi-paragraph explanation. Three elements, in that hierarchy.

---

## TYPOGRAPHY PRECISION (MOBILE)

### Size Scale Reference — Market-Sourced

| Role | Size | Line-height | Weight | Letter-spacing |
|---|---|---|---|---|
| Hero / display | 32–40pt | 1.05–1.1 | 700–800 | −0.03em |
| Headline | 24–28pt | 1.15–1.2 | 700 | −0.02em |
| Title | 18–20pt | 1.25–1.3 | 600 | −0.01em |
| Body | 16pt | 1.5 | 400 | 0 |
| Body small | 14pt | 1.45 | 400 | 0 |
| Label | 12pt | 1.3 | 600 | +0.03em |
| Caption | 11pt | 1.3 | 400 | +0.02em |

Power-user and task-focused apps (task managers, email, dashboards): body at 14pt, not 16pt. Consumer and content apps: body at 16pt.

### Dynamic Type (iOS)
All font sizes through `UIFontMetrics` or SwiftUI's `dynamicTypeSize` modifier — never hardcoded pt values:
```swift
.font(.body) // not .font(.system(size: 16))
```

Text container must respond to `.accessibilityLargeText` without truncation or overflow. Test at `xLarge`, `xxLarge`, `xxxLarge` Dynamic Type before shipping.

### Android — Text Scaling
Use `sp` units for all text sizes (not `dp`). Text must scale with system font size preference. Test at 130% and 200% system font scale.

---

## COLOR SYSTEM (MOBILE)

### OKLCH for Token Definitions
```dart
// Flutter token example
const primaryColor = Color.fromOKLCH(0.55, 0.22, 262); // oklch(55% 0.22 262)
```

Use OKLCH for defining color tokens where the framework supports it. For framework-native colors (SwiftUI `Color`, Material `ColorScheme`), map from OKLCH-defined primaries.

### Dark Mode: Independent Design
Dark palette is never a computed invert of light. Minimum decisions for each dark token:
- Background: warm-neutral dark, not `#000000`
- Text primary: `rgba(255, 255, 255, 0.87)` — not `#fff`
- Text secondary: `rgba(255, 255, 255, 0.65)` — calibrated (not 60% — see web skill)
- Elevated surfaces: progressively lighter gray, 5 steps

### Neutral Tint Rule
All neutrals carry 5–15% saturation of the primary hue. Pure gray `hsl(0 0% ...)` reads as dead. Tinted neutral: `hsl(260 8% 12%)` (purple-tinted dark) or `hsl(220 6% 95%)` (blue-tinted light).

---

## WHAT BREAKS NATIVE FEEL

These patterns immediately read as cross-platform template:

- **Solid navigation bar** with no material — ignores iOS blur convention
- **Single haptic intensity** for all interactions — no differentiation
- **Bottom sheet without detents** — full-screen only feels coarse
- **`ease` curve** on any transition (should be spring or expo-out)
- **No scroll-linked animation** — everything appears fully formed at rest
- **16px body text in productivity apps** — matches consumer apps, wrong density
- **Letter-spacing: 0** on display text (32pt+) — unfinished at large sizes
- **Static skeleton** without shimmer — reads as layout placeholder, not loading state
- **Stock illustration** in empty state — breaks visual language continuity
- **Simultaneous visual + haptic** (no offset) — reads as one blunt tap, not layered feedback
