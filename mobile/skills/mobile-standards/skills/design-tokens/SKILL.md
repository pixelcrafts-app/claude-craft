---
name: design-tokens
description: Apply when auditing or documenting design token usage in a mobile app — color, typography, spacing, radius, duration token completeness and naming. Framework-agnostic — works for Flutter, React Native, SwiftUI, Jetpack Compose, KMP, NativeScript. Per-framework adapter section maps the generic violation patterns to each stack's specific idioms. Auto-invoke when reviewing theme files, constants, or design system implementation.
---

# Design tokens

> **Framework-agnostic.** Token *categories*, *naming rules*, and *audit
> patterns* are universal across mobile stacks. Stack-specific identifiers
> (the actual class names a violation matches) live in the Framework
> Adapters section at the end of this file. Pick the adapter for your
> stack; the rules above the adapter are the same.

## Token Completeness Audit

A design system is incomplete until every category is defined. Building screens against an incomplete token system guarantees orphan values in code that can't be themed later.

| Category | Required content |
|---|---|
| **Colors** | Brand, semantic (primary, secondary, error, success, warning), surface levels (≥ 3), text levels (primary / secondary / muted / disabled), border |
| **Typography** | Scale of 6–8 steps; per-step line-height; per-step weight |
| **Spacing** | Named scale (e.g. `xxs` through `xxxl`); at least 8 steps; based on a single base unit chosen by the project (commonly 4 or 8) |
| **Radius** | Named scale (e.g. `xs` through `full`); at least 5 steps |
| **Duration** | Named animation durations (e.g. `instant`, `fast`, `normal`, `slow`) |
| **Shadow / elevation** | At least 2 levels; max 5. Project chooses what each level means (shadow set, border-tint, or surface luminance shift). |

The specific names (`xxs`, `xxxl`, `fast`, `normal`) are convention, not law. What matters: every category is named, finite, and exposed as constants.

## Token Naming Rules

- **Semantic names, not descriptive.** `primary` not `blue500`, `error` not `red`. The token's name says what role it plays; the value can change without renaming.
- **Surface hierarchy is monotonically ordered.** `surface < surfaceVariant < surfaceContainer` (lighter = higher elevation in light mode; inverse in dark mode).
- **Never expose raw values in screens.** Screen code references token names; the token file is the only place a raw value lives.
- **One file per category.** Color tokens in one file; spacing tokens in another; never scattered across the screen tree.

## Token Usage Audit — generic violation patterns

A token system is only as strong as the discipline that uses it. Flag these violation patterns regardless of framework:

| Pattern | Why it's a violation |
|---|---|
| **Color literal in screen code** | Hardcoded hex / RGBA / OKLCH not from the token file |
| **Inline text-style literal** | Font size / weight / line-height set inline rather than via a typography-scale token |
| **Spacing literal** | A numeric padding / margin / gap value not from the spacing scale |
| **Edge-inset literal** | A directional inset value not built from spacing tokens |
| **Border-radius literal** | A radius value not from the radius scale |
| **Duration literal** | An animation duration not from the duration token set |
| **Shadow/elevation literal** | A shadow or border-tint built inline rather than referenced by elevation level |

The patterns above are framework-neutral. The adapter section below maps each to the specific identifier(s) to grep for in each framework.

## Token Documentation

Each token file must include three fields per token:

1. **Name** — the semantic identifier (e.g. `surface`, `space.lg`, `duration.fast`).
2. **Value** — the concrete value (with its unit / format — `#0D0D0D`, `16px`, `200ms`).
3. **Intended use** — one line of role description (`Card surface in light mode`, `Standard padding for primary actions`).

Tokens with any field missing are incomplete and should fail audit.

---

## Framework Adapters

> Pick the adapter for your stack. The rules above apply identically; only
> the *match patterns* (what identifiers to grep for) differ. Add an
> adapter for any stack not listed here — a missing adapter is a request
> for contribution, not permission to skip the audit.

### Flutter (Dart)

| Generic pattern | Flutter match |
|---|---|
| Color literal | `Color(0x...)`, `Colors.<name>`, `Color.fromRGBO(`, raw hex in `Color(` |
| Inline text-style literal | `TextStyle(fontSize:`, `TextStyle(fontWeight:`, `TextStyle(height:` outside of theme |
| Spacing literal | `SizedBox(width:`, `SizedBox(height:`, raw `double` in `padding:` |
| Edge-inset literal | `EdgeInsets.all(`, `EdgeInsets.symmetric(`, `EdgeInsets.fromLTRB(` with raw numbers |
| Border-radius literal | `BorderRadius.circular(`, `BorderRadius.all(Radius.circular(` with raw numbers |
| Duration literal | `Duration(milliseconds:`, `Duration(seconds:` with raw numbers outside token file |
| Shadow literal | `BoxShadow(` with inline `color`, `offset`, `blurRadius`, `spreadRadius` |

Allowed location for these literals: **only inside the token file itself**. Outside the token file → audit FAIL.

### React Native (JS/TS)

| Generic pattern | RN match |
|---|---|
| Color literal | Raw hex / rgb / rgba string in `style={...}`, `StyleSheet.create({...})`, or props |
| Inline text-style literal | `style={{ fontSize: ..., fontWeight: ..., lineHeight: ... }}` outside theme |
| Spacing literal | `margin: 12`, `padding: 8`, `gap: 16` numeric literal in inline style |
| Border-radius literal | `borderRadius: 8` numeric literal |
| Duration literal | `Animated.timing(..., { duration: 200 })` numeric literal |
| Shadow literal | `shadowOpacity: ..., shadowOffset: ..., elevation: ...` set inline |

Allowed location: only inside the theme file (e.g. `theme/colors.ts`, `theme/spacing.ts`).

### SwiftUI (Swift)

| Generic pattern | SwiftUI match |
|---|---|
| Color literal | `Color(red:`, `Color(hex:`, `Color(.sRGB,` outside design system |
| Inline text-style literal | `.font(.system(size:`, `.fontWeight(`, `.lineSpacing(` outside `ViewModifier` |
| Spacing literal | `.padding(12)`, `Spacer(minLength:`, `.frame(width:`, `.frame(height:` with raw numbers |
| Border-radius literal | `.cornerRadius(8)`, `RoundedRectangle(cornerRadius:` raw |
| Duration literal | `Animation.linear(duration:`, `.animation(.easeInOut(duration:`, `withAnimation(.spring(duration:` raw |
| Shadow literal | `.shadow(color:` `radius:` `x:` `y:` with literal values |

Allowed location: token enum / struct (`AppColors`, `AppSpacing`, etc.).

### Jetpack Compose (Kotlin)

| Generic pattern | Compose match |
|---|---|
| Color literal | `Color(0xFF...)`, `Color.<name>` outside `Material[3]Theme` colors |
| Inline text-style literal | `TextStyle(fontSize = ...)`, `Modifier.fontFamily(...)` inline |
| Spacing literal | `Modifier.padding(12.dp)`, `Spacer(Modifier.width(8.dp))`, raw `.dp` in `Modifier.size(` |
| Border-radius literal | `RoundedCornerShape(8.dp)`, `clip(RoundedCornerShape(...))` raw |
| Duration literal | `tween(durationMillis = 200)`, `animateColorAsState(animationSpec = tween(...))` |
| Shadow literal | `Modifier.shadow(elevation = ...)` raw without a theme reference |

Allowed location: `theme/Color.kt`, `theme/Type.kt`, `theme/Shape.kt`, `theme/Dimens.kt`.

### Kotlin Multiplatform Mobile (KMP) shared design system

Apply the Compose adapter in `composeApp/`, plus a shared-tokens contract in `shared/commonMain/` (typically `expect`/`actual` for platform-specific surfaces). Audit pattern is identical; identifiers come from whichever rendering layer is in use per target.

### Adding a new framework adapter

When introducing claude-craft to a stack not listed (Compose Multiplatform Desktop, Flutter Embedder, NativeScript, etc.), add an adapter section with the same generic-pattern → framework-match table shape. The rule content above the adapter section never changes — only the match patterns vary.
