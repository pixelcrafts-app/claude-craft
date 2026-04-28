---
name: performance
description: Apply when optimizing Flutter performance — 16ms frame budget (8ms on 120Hz), cold start under 2s, decode-at-display-size for images, isolates via compute, const widgets, ListView.builder for long lists, bounded image cache, dispose controllers. Auto-invoke on list / image / animation work.
---

# Performance Rules

Motion aesthetic discipline (duration scales, easing curves, reduced-motion handling) is in `mobile-standards:craft-guide`. This skill covers the engineering side.

---

## Performance Budgets

Every app has budgets. These are the defaults — apps may tighten, never loosen:

| Metric | Budget |
|--------|--------|
| Frame time (scroll/animation) | **16ms** (60fps) |
| Frame time (120Hz displays) | **8ms** |
| Cold start — first frame (splash visible) | **<1s** |
| Cold start — first meaningful paint (real content visible) | **<2s (P75)** |
| Cold start — time to interactive (input responds) | **<3s (P95)** |
| Warm start | **<1s** |
| Route transition | **<300ms** total |
| Button tap feedback | **<100ms** |
| API response render | **<500ms** from response received |
| Memory — low-end devices (≤2GB RAM) | **<100MB** RSS |

Measure in release mode on mid-tier devices (iPhone 12 / Pixel 6a class), not on a development machine.

---

## Frame Budget (16ms / 8ms)

Every frame is a full render pass. The 16ms budget breaks down:

- Build phase: <4ms
- Layout phase: <4ms
- Paint phase: <4ms
- Rasterization + GPU: <4ms

Exceed any phase → dropped frame → visible jank.

### Keep build() cheap

- No computation in `build()` — move it to `initState`, a provider, or a memoized derived value
- No sorting, filtering, or mapping lists inside `build()` — do it once when data changes
- No `Future.delayed`, `Timer`, or synchronous I/O in `build()`
- `build()` runs on every rebuild — assume it runs 60 times a second

### Minimize rebuild scope

- `const` widgets wherever possible — they skip rebuild
- Split widgets so only the part that changes rebuilds
- `Consumer`/`Selector` (Provider) or `ref.watch(provider.select(...))` (Riverpod) for narrow subscriptions
- `ValueListenableBuilder` for fine-grained listener scope
- Never wrap an entire screen in a `Consumer` if only one widget uses the value

### Avoid layout thrashing

- `IntrinsicWidth`/`IntrinsicHeight` — expensive, force multi-pass layout. Avoid in lists.
- Unbounded constraints + `shrinkWrap: true` on nested scrollables — forces full-list layout before scroll. Use slivers or fixed heights.
- Deeply nested `Column`/`Row` with `Expanded` — each level re-computes. Flatten when possible.
- `Stack` with many `Positioned.fill` children — each adds a paint layer. Use sparingly.

---

## Lists & Scroll

- >20 items: **always** use `ListView.builder` / `GridView.builder` / `SliverList` — virtualized rendering
- <20 items: `Column` + `SingleChildScrollView` is acceptable
- `itemExtent` or `prototypeItem` when item heights are known/uniform — skips size calculation
- `cacheExtent`: default 250 is fine; raise for tall items, lower for memory-constrained screens
- `addAutomaticKeepAlives: false` on long lists unless items must retain state across scroll
- `addRepaintBoundaries: true` (default) — keep. Each item paints independently.
- Nested scrolling: one `CustomScrollView` with slivers, not multiple scroll views

### Pagination

- Load 20–50 items per page, not 500
- Trigger next page at 80% scroll (not at the bottom — avoids visible empty state)
- Debounce scroll events — don't fire a fetch on every pixel

---

## Images

- **Decode at display size**: always pass `cacheWidth` / `cacheHeight` to `Image`/`NetworkImage` matching the actual rendered size × `devicePixelRatio` — a 40×40 avatar on a 3× display needs `cacheWidth: 120`, not 2000
- `CachedNetworkImage` for remote images — network + memory + disk cache
- `Image.asset` — pre-decoded at build time; fast
- Below-the-fold images: lazy — list virtualization handles it
- Large background images: `BoxFit.cover` with `cacheWidth` matching screen width, not source width
- `FadeInImage` for network placeholders — prevents layout jump

### Image Cache Caps

- Default image cache is 100MB — too generous for low-end devices
- Set `PaintingBinding.instance.imageCache.maximumSizeBytes` to **50MB** on devices with ≤2GB RAM
- Cap `maximumSize` (count) at 200 unless the app is heavily image-driven
- Clear cache on memory warnings: `WidgetsBindingObserver.didHaveMemoryPressure` → `imageCache.clear()`

---

## Cold Start

### Cold start checklist

- `main()` does the minimum — Firebase init, Hive init, critical services only
- Defer non-critical initialization: analytics, crash reporting, remote config, background sync — run them after `runApp` completes
- `runApp` must be reached within 200ms of app launch
- First screen shows cached data if available, fetches fresh in background
- Parallelize with `Future.wait([...])` — avoid sequential `await` chains in `main()`

---

## Heavy Work — Use Isolates

- **Never** parse >1MB JSON on the main isolate — use `compute()`
- **Never** do image transformations (crop, resize, filter) on the main isolate
- **Never** run crypto/hashing on the main isolate for anything >1KB
- **Never** sort/filter lists of >1000 items synchronously on the main isolate

`compute()` spawns a fresh isolate per call — has overhead (~10ms). For frequent operations, use a long-lived isolate via `Isolate.spawn`.

---

## State & Provider Performance

- `ref.watch(provider.select((state) => state.field))` — rebuilds only when that field changes
- Provider emissions must be **distinct** — ensure your state type implements equality (`freezed`, `Equatable`, or manual `==`)
- Avoid provider chains where A depends on B depends on C depends on D — each hop is a rebuild trigger
- `Provider.autoDispose` for screen-scoped state — prevents memory leaks on navigation

---

## Animations

Motion aesthetic (duration, curves, reduced-motion) is in `mobile-standards:craft-guide`. Render-performance rules only:

- Use `AnimatedBuilder` with a `child:` argument — the child is built once, not on every frame
- `RepaintBoundary` around independently-animating widgets — isolates repaints
- `TickerProviderStateMixin` for multiple controllers, `SingleTickerProviderStateMixin` for one
- Never animate `Opacity` on large subtrees — use `FadeTransition` (opacity layer, cheaper)
- Never animate shadows on many widgets — paints every frame
- `BackdropFilter` is expensive — never on scroll-heavy screens

---

## Memory Discipline

- Dispose all controllers, subscriptions, streams, `FocusNode`s, `AnimationController`s in `dispose()`
- Hive boxes: close boxes you don't need (`box.close()`) — they hold memory
- Image cache bounded (see Images section)
- Avoid holding large objects in `final` top-level fields — they live for app lifetime
- `StreamController` without `close()` leaks listeners — always close
- Use `WeakReference` for callback-style handlers that shouldn't extend the holder's lifetime

### Detecting Leaks

- Flutter DevTools → Memory tab → heap snapshot before and after a user flow
- Look for: widgets that should be disposed but aren't, growing image cache, unclosed streams
- Run the same flow 10× — memory must plateau, not grow monotonically

---

## Network Performance

- Cache everything cacheable — respect `Cache-Control` headers, add a local cache layer
- Limit concurrent requests to 4–6 simultaneous
- Debounce typed input (search, validation) — 250–500ms
- Cancel requests when the initiating screen dismounts — use `CancelToken` (Dio) or `AbortController`
- Every request has a timeout — 15s default, shorter for critical paths

---

## Bundle Size

- Review `flutter build --analyze-size` on every major release
- Prune unused packages — each adds startup time and binary size
- Icons: use icon fonts (Material Icons) rather than per-icon SVGs
- Images: WebP for photos, SVG for vectors — never PNG at multiple densities when a vector works
- Fonts: load only weights used — not the full variable font family

---

## Profiling Discipline

- Profile before optimizing — use Flutter DevTools Performance tab: record a session, identify frames >16ms
- Long build times → widget tree too deep; long layout times → unbounded constraints; long raster times → too many paint layers
- Always profile in `--profile` or `--release` mode on a real mid-tier device — debug mode measurements are not valid

### Benchmarking

- `flutter drive --profile --target=test_driver/app.dart` for integration perf tests
- `WidgetsBinding.instance.addTimingsCallback` — measure frame times programmatically
- Track frame timings in production (Firebase Performance or equivalent) — real-user data beats synthetic tests

---

## Budget Enforcement Priority

Non-negotiable in these contexts:
- Main tab screens (users spend the most time here)
- Scroll-heavy lists (feeds, timelines, catalogs)
- Animated transitions (page push/pop, modal present)
- First screen after cold start
- Input fields

May be relaxed (but not ignored) for:
- Settings screens
- One-off dialogs
- Admin/debug screens

---

## DON'TS

- Don't block the main isolate with heavy work — use `compute()` or isolates
- Don't load full-resolution images into small widgets
- Don't leak controllers, streams, or listeners
- Don't add animations that drop frames on mid-tier devices
- Don't use `shrinkWrap: true` on nested scrollables inside long lists
- Don't animate `Opacity` on large subtrees — use `FadeTransition`
- Don't neglect `dispose()` for `AnimationController`, `FocusNode`, `StreamController`
