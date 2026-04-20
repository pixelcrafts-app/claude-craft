---
name: performance
description: Apply when optimizing Flutter performance — 16ms frame budget (8ms on 120Hz), cold start under 2s, decode-at-display-size for images, isolates via compute, const widgets, ListView.builder for long lists, bounded image cache, dispose controllers. Auto-invoke on list / image / animation work.
---

# Performance Rules

Performance is a feature, not an afterthought. Users don't complain about slow apps — they delete them.

Concrete patterns for frame budget, startup, memory, image handling, and profiling in Flutter apps. Implements the craft guide's "Speed is a Feeling" — this file is the engineering side.

---

## Performance Budgets

Every app has budgets. These are the defaults — apps may tighten, never loosen:

| Metric | Budget | Why |
|--------|--------|-----|
| Frame time (scroll/animation) | **16ms** (60fps) | One dropped frame is visible |
| Frame time (120Hz displays) | **8ms** | Modern iOS/Android phones are 120Hz; falling back to 60fps feels sluggish |
| Cold start (first paint) | **<2s** | User patience before they context-switch |
| Cold start (interactive) | **<3s** | First input responds |
| Warm start | **<1s** | App resume is "instant" in user perception |
| Route transition | **<300ms** total | Animation duration, not wait time |
| Button tap feedback | **<100ms** | Perceived as "immediate" |
| API response render | **<500ms** from response | Parse + layout + paint |

Measure in release mode on mid-tier devices (iPhone 12 / Pixel 6a class), not on your M3 Pro.

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
- `Stack` with many `Positioned.fill` children — each adds a paint layer. Prefer `Container` with `Stack` sparingly.

---

## Lists & Scroll

- >20 items: **always** use `ListView.builder` / `GridView.builder` / `SliverList` — virtualized rendering
- <20 items: `Column` + `SingleChildScrollView` is fine
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

- **Decode at display size**: always pass `cacheWidth` / `cacheHeight` to `Image`/`NetworkImage` matching the actual rendered size × `devicePixelRatio`
  - A 40×40 avatar on a 3× display needs `cacheWidth: 120` — not 2000
- `CachedNetworkImage` for remote images — network + memory + disk cache
- `Image.asset` — pre-decoded at build time; fast
- Below-the-fold images: lazy — `visibility_detector` or list virtualization handles it
- Large background images: `BoxFit.cover` with `cacheWidth` matching screen width, not source width
- `FadeInImage` for network placeholders — prevents layout jump

### Memory Caps

- `PaintingBinding.instance.imageCache.maximumSizeBytes = 100 * 1024 * 1024` (100MB default is too generous on low-end devices)
- `maximumSize` (count) — cap at 200 unless you have a very image-heavy app
- Clear cache on memory warnings: `WidgetsBindingObserver.didHaveMemoryPressure` → `imageCache.clear()`

---

## Cold Start

### Targets
- **First frame** (splash visible): <1s
- **First meaningful paint** (real content visible): <2s
- **Time to interactive** (input responds): <3s

### Cold start checklist
- `main()` does the minimum — Firebase init, Hive init, critical services only
- Defer non-critical initialization: analytics, crash reporting, remote config, background sync — `await` them in the background after `runApp`
- `runApp` should be reached within 200ms of app launch
- First screen shows cached data if available, fetches fresh in background
- Avoid `await` chains in `main()` — parallelize with `Future.wait([...])`

### Bad
```dart
Future<void> main() async {
  await Firebase.initializeApp();       // 300ms
  await Hive.initFlutter();             // 100ms
  await Hive.openBox('user');           // 50ms
  await Hive.openBox('content');        // 80ms
  await PurchaseService.instance.init(); // 400ms — NOT critical for first frame
  await AnalyticsService.init();         // 200ms — NOT critical
  await RemoteConfig.init();             // 500ms — NOT critical
  runApp(App());                         // 1630ms before user sees anything
}
```

### Good
```dart
Future<void> main() async {
  await Future.wait([
    Firebase.initializeApp(),
    Hive.initFlutter().then((_) => Future.wait([
      Hive.openBox('user'),
      Hive.openBox('content'),
    ])),
  ]);
  runApp(App()); // ~300ms

  // Fire-and-forget non-critical init
  unawaited(PurchaseService.instance.init());
  unawaited(AnalyticsService.init());
  unawaited(RemoteConfig.init());
}
```

---

## Heavy Work — Use Isolates

- **Never** parse >1MB JSON on the main isolate — use `compute()`
- **Never** do image transformations (crop, resize, filter) on main isolate
- **Never** run crypto/hashing on main isolate for anything >1KB
- **Never** sort/filter lists of >1000 items synchronously

`compute()` spawns a fresh isolate per call — has overhead (~10ms). For frequent operations, use a long-lived isolate via `Isolate.spawn`.

---

## State & Provider Performance

- `ref.watch(provider.select((state) => state.field))` — rebuilds only when that field changes
- Provider emissions should be **distinct** — `StateNotifier` won't emit if `==` returns true; make sure your state type implements equality (freezed, Equatable, or manual)
- Avoid provider chains where A depends on B depends on C depends on D — each hop is a rebuild trigger
- `Provider.autoDispose` for screen-scoped state — prevents memory leaks on navigation

---

## Animations

- Use `AnimatedBuilder` with a `child:` argument — the child is built once, not on every frame
- `RepaintBoundary` around independently-animating widgets — isolates repaints
- `TickerProviderStateMixin` for multiple controllers, `SingleTickerProviderStateMixin` for one
- Never animate `Opacity` on large subtrees — use `FadeTransition` (uses opacity layer, cheaper)
- Never animate shadows on many widgets — paints every frame
- `BackdropFilter` is expensive — use sparingly, never on scroll-heavy screens

---

## Memory Discipline

- Dispose all controllers, subscriptions, streams, `FocusNode`s, `AnimationController`s in `dispose()`
- Hive boxes: close boxes you don't need (`box.close()`) — they hold memory
- Image cache bounded (see Images section)
- Avoid holding large objects in `final` top-level fields — they live for app lifetime
- `StreamController` without `close()` leaks listeners — always close
- Use `WeakReference` for callback-style handlers that shouldn't extend the holder's lifetime

### Detecting leaks

- Flutter DevTools → Memory tab → heap snapshot before and after a user flow
- Look for: widgets that should be disposed but aren't, growing image cache, unclosed streams
- Run the same flow 10× — memory should plateau, not grow monotonically

---

## Network Performance

- Cache everything cacheable — respect `Cache-Control` headers, add a local cache layer
- Concurrent requests: limit to 4–6 simultaneous — more competes with the main isolate
- Prefer fewer, larger requests over many small ones (with pagination caveats)
- Debounce typed input (search, validation) — 250–500ms
- Request cancellation when screens dismount — use `CancelToken` (Dio) or AbortController
- Timeout every request — 15s default, shorter for critical paths

---

## Bundle Size

- Review `flutter build --analyze-size` on every major release
- Prune unused packages — each one adds startup time AND binary size
- Icons: use icon fonts (Material Icons, iconsax) rather than per-icon SVGs
- Images: WebP for photos, SVG for vectors — never PNG at multiple densities when a vector works
- Fonts: load only weights you use — not the full variable font family

---

## Profiling Discipline

- **Never optimize without profiling first** — intuition is wrong about performance 80% of the time
- Flutter DevTools: Performance tab → record a session → identify frames >16ms
- Look for: long build times (widget tree too deep), long layout times (unbounded constraints), long raster times (too many paint layers)
- CPU profiler: identify hot functions on the main isolate
- Memory profiler: heap snapshots, allocation timeline

### Benchmarking

- `flutter drive --profile --target=test_driver/app.dart` for integration perf tests
- `WidgetsBinding.instance.addTimingsCallback` — measure frame times programmatically
- Track frame timings in production (via Firebase Performance or similar) — real user data beats synthetic tests

---

## When Perf Matters Most

Budget enforcement is non-negotiable in these contexts:
- Main app tab screens (users spend most time here)
- Scroll-heavy lists (feeds, timelines, catalogs)
- Animated transitions (page push/pop, modal present)
- First screen after cold start
- Input fields (typing feels slow → app feels slow)

Budgets can be relaxed (but not ignored) for:
- Settings screens
- One-off dialogs
- Admin/debug screens

---

## DON'TS

- Don't optimize without profiling
- Don't measure performance in debug mode (always use `--profile` or `--release`)
- Don't measure on your dev machine only — test on a mid-tier real device
- Don't trust "works fine for me" — frame rate varies by device, battery, thermal state
- Don't block the main isolate with heavy work — use `compute()` or isolates
- Don't load full-resolution images into small widgets
- Don't leak controllers, streams, or listeners
- Don't defer optimization to "later" — perf debt compounds
- Don't add animations that drop frames on mid-tier devices
