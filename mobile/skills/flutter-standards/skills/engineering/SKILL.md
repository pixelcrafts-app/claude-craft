---
name: engineering
description: Apply when writing or reviewing any Dart or Flutter code — widget patterns, data layer, reusability, single source of truth, no hardcoded values, centralized cross-cutting concerns, consistent error handling, data pipeline verification. Auto-invoke on any Flutter code change.
---

# Flutter Engineering Rules

Universal security, testing, observability, and engineering rules — see `universal-rules:security`, `universal-rules:testing`, `universal-rules:observability`, `universal-rules:engineering`. This skill covers Flutter-specific patterns only.

---

## Reusability

| Reused in 2+ widgets | Extract to `lib/shared/widgets/{category}/` |
|---|---|
| Reused in 2+ features | Extract to `lib/shared/widgets/` |
| Pure function, no Flutter deps | Extract to `lib/shared/utils/` |
| Shared format/parse logic | Extract to `lib/shared/utils/` |
| Feature-specific transform | Feature's mapper or local helper |
| Used once, <10 lines | Inline it |

Forbidden: two widgets rendering the same thing, two helpers doing the same formatting, two providers exposing the same data, two mappers parsing the same API shape.

---

## Single Source of Truth

Every fact lives in one place. If found in two places — delete one, import from the other. No exceptions.

| Fact | Single source |
|------|--------------|
| Colors | one colors file — one class + one context extension |
| Typography | one typography file — one class |
| Spacing | one spacing file — one class with named constants |
| Radius | one radius file — one class with named constants |
| Routes | one routes file — one `generateRoute()` or router config |
| Models | one models directory, shared across features |
| Mappers | one mappers directory, shared across features |
| Singletons | one `.instance` per service, in the service file |
| Persistence | one storage service — no direct box access from features |
| Sync keys | one sync service — no ad-hoc dirty tracking in features |

---

## No Hardcoded Values

Every spacing, radius, color, typography, duration, and threshold value references the design system or a named constant.

Only inline literals allowed: `0`, `1`, `-1`, `''`, `[]`, `true`, `false`, map keys.

---

## Centralize Cross-Cutting Concerns

Anything ≥2 features need is infrastructure, not feature code.

| Concern | Where it lives |
|---------|----------------|
| Auth | one auth service — never direct auth provider calls in features |
| API requests | one API client — never imported by features directly |
| Persistence | one storage service — never direct storage access in features |
| Sync | one sync service — never ad-hoc flush calls in features |
| Connectivity | one service — one stream, not per-screen listeners |
| Notifications | one service — permissions and handlers in one place |
| Purchases | one entitlement service |
| Loading skeletons | one shared skeleton widget |
| Error display | one shared error-state widget |
| Empty state | one shared empty-state widget |
| Buttons | one shared button widget family |

A feature screen's `build()` should mostly compose existing widgets.

---

## Consistent Error Handling

1. Data layer returns result types — never throws unhandled exceptions
2. Repositories translate API errors into known failure modes
3. Providers expose `AsyncValue` — screens use `.when(loading, error, data)`
4. Screens render error state with a specific message and a recovery action
5. Critical errors logged via the structured logger
6. Auth errors trigger the session-expiry flow, not generic error UI

Forbidden: silent `catch (_) {}`, generic strings ("Something went wrong"), errors that don't tell the user what to try next.

---

## Architecture

- `shared/` → `features/` — shared code knows nothing about features; features never know each other
- Screens display — logic belongs in the state layer
- One file, one concept; one component, one job
- Only rebuild what changed — computation belongs in the state layer, never in the render path

### State Scope

- App-wide state (auth, theme, connectivity): root-level providers, never disposed
- Feature-scoped state: feature providers with `.autoDispose`
- Screen-scoped state: `StatefulWidget` or `.autoDispose` scoped provider
- Never store UI state in app-wide providers

---

## Data Pipeline Verification

When working with any data, verify each layer in order:

1. **Source** — data exists in DB, is published, flag is set
2. **API** — endpoint returns it with correct structure
3. **Mapper** — handles the actual API shape
4. **Model** — fields match mapper output
5. **Provider** — exposes data correctly
6. **Screen** — renders it correctly

A passing `flutter analyze` at step 6 does not validate steps 1–5. Every screen handles all four states: loading, empty, error, content.

---

## Widget Patterns

Animation/perf → `flutter-standards:performance`. A11y rules → `flutter-standards:accessibility`. Design principles → `mobile-standards:craft-guide`.

### Touch Targets

- Minimum 48×48dp for every tappable element — use `SizedBox` or `ConstrainedBox` to enforce; never rely on visual size alone
- Adjacent targets separated by at least 8dp — prevents mis-taps for users with tremor or thick fingers
- Targets on edges/corners: extend toward the edge to make one-handed use easier

### Dart Standards

- `withValues(alpha:)` not `withOpacity()` (deprecated in Flutter 3.4+)
- `const` constructors wherever possible
- `final` over `var` — immutability by default
- Named parameters for functions with more than 2 parameters
- `switch` expressions over `switch` statements

### Guards & Safety

- `mounted` check before `setState()` in async callbacks
- Null-safe access on all provider data — never force-unwrap
- Dispose all controllers, subscriptions, `AnimationController`s, and `FocusNode`s in `dispose()`

### Widget Keys

- `ValueKey(id)` — required on list items that can reorder, add, or remove
- `PageStorageKey` — required on scrollable lists inside tabs to preserve scroll position
- No key — default for static widgets that never reorder
- Never use index as key for dynamic lists — causes silent state loss on reorder

### Text Resilience

- `maxLines` + `TextOverflow.ellipsis` on every text that could overflow — never assume short input
- Never use `maxLines: 1` for user-generated content (article body, note content, descriptions the user navigated to read). Use `maxLines: 2` minimum for those. `maxLines: 1` is only for labels, captions, list item titles, and navigational text.
- User-generated text (names, titles): assume 3× longer than test data
- Numbers: locale-aware separators via `intl`
- Relative time: human-readable format ("2h ago", "Yesterday") — never raw ISO timestamps in UI
- Units always labeled — never a bare number when a unit conveys meaning

### Safe Areas & Layout

- Wrap with `SafeArea` or account for `MediaQuery.padding`
- Account for notch, Dynamic Island, home indicator, and status bar
- Keyboard: `MediaQuery.viewInsets.bottom` for keyboard-aware padding
- Bottom actions: above home indicator, not on it

### Headers & Screen Structure

- Every screen's header: same back button style, same title position, same height
- Structural order: `SafeArea → Column/CustomScrollView → [Header, Content, Bottom action]`

### Tap Feedback

- `onTapDown` → scale to 0.96 (100ms); `onTapUp`/`onTapCancel` → spring back to 1.0 (200ms, elasticOut)
- `GestureDetector` + `AnimatedScale` for custom elements; `InkWell` for Material ripple

### Haptic Feedback

- `lightImpact()` — taps, toggles, selection
- `mediumImpact()` — completing action, confirming choice
- `heavyImpact()` — destructive actions, significant milestones
- `selectionClick()` — picker scrolling, slider ticks
- Haptic fires 10–50ms after visual response; respect the user's haptic preference setting

### Loading State

- Skeleton/placeholder shape matches final layout exactly — same card dimensions, text line widths
- One loading style per app — never mix shimmer, spinner, and skeleton in the same app
- Never show a blank screen as the sole loading state

### Destructive Actions

- Delete/remove: 3–5s undo `SnackBar` before executing
- Irreversible actions (account deletion, data wipe): confirmation dialog required

### Images

- Text on images: gradient scrim or backdrop — never assume image content is sufficiently dark
- Image-dominant screens: reduce chrome prominence, let content breathe

---

## Data Layer

### Mappers

- Never assume API response shape — check the actual endpoint response first
- Handle both direct fields and nested content sub-objects
- Provide sensible defaults for every optional field — never crash on missing data
- Accept field aliases when the same concept appears under multiple key names
- Verify mapper output mentally against the model's expected fields before shipping

### Models

- Immutable — use `copyWith()` to produce new instances, never mutate in place
- `fromJson()` must handle both cache format and live API response format
- `toJson()` must produce a format that `fromJson()` can round-trip without loss
- Every field has a type-safe default — no nullable fields unless genuinely optional in the domain
- Use factory constructors for alternative creation paths

### API Client

- Accessed from services and repositories only — features and screens never import it directly
- 401 handling: force-refresh token → retry request once → trigger session expiry on second failure
- Timeouts on all network calls
- Return result types (success/data/error) — never throw unhandled exceptions

### Repositories

- Use mappers to parse API responses — never parse raw JSON inside a repository method
- Single source of truth: screens ask the repository; the repository decides cache vs. live API
- Only repositories access the API client — providers and screens never touch the network layer directly

### Error Pattern

- Data layer returns `Result<T, Failure>` or `AsyncValue<T>` — never raw exceptions
- Repositories translate HTTP errors into typed failure modes: `NetworkFailure`, `AuthFailure`, `NotFoundFailure`, `ServerFailure`
- Providers expose `AsyncValue<T>` — screens use `.when(loading:, error:, data:)`
- Never mix AsyncValue and Result<T> in the same feature — pick one pattern per project and use it everywhere
- Retry only on idempotent operations (GET, PUT) and transient errors (timeout, 502/503/504). Never retry 4xx.
