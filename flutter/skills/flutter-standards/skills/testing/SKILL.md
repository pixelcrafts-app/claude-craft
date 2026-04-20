---
name: testing
description: Apply when writing or reviewing Flutter tests — test pyramid, mocktail, ProviderScope overrides, golden tests, coverage targets, CI gates. Auto-invoke when editing files under test/ or generating test stubs.
---

# Testing Discipline Guide

Concrete patterns for unit, widget, and integration tests in Flutter apps. Implements `engineering.md`'s "Verification" section — does not restate it.

Tests are part of the product, not a separate chore. Every change ships with tests that prove it works AND tests that prove it doesn't break what came before.

---

## The Testing Pyramid

| Layer | Ratio | Purpose |
|-------|-------|---------|
| **Unit** | ~70% | Pure logic: mappers, utilities, models, state reducers |
| **Widget** | ~25% | Individual widgets render + respond to interaction |
| **Integration** | ~5% | Critical flows end-to-end (sign-in, checkout, main task) |

Upside-down pyramids (mostly integration, few units) are slow, flaky, and hide bugs. Keep unit tests fast and plentiful.

---

## What to Test

- **Pure logic** — mappers, validators, formatters, calculators, state transitions
- **Model serialization** — `fromJson` / `toJson` round-trip for every model
- **Error handling** — result types, failure modes, retry behavior
- **Widget states** — loading, empty, error, content for every screen
- **Interaction flows** — tap, swipe, form submit, dismiss
- **Navigation triggers** — buttons/gestures that push/pop routes
- **Provider emissions** — sequence of values a provider produces for a given input
- **Critical user journeys** — sign-in, primary action, purchase, sign-out

---

## What NOT to Test

- Framework code you didn't write (don't test that `setState` rebuilds)
- Private methods — test through the public API that uses them
- Getters that only return a field (`String get id => _id;`)
- Trivial `copyWith` implementations (unless they do transformations)
- Third-party library internals (assume they work; test your integration layer instead)
- UI pixel-perfect layout — that's what golden tests are for, and even those are selective

---

## Unit Tests

- One `test()` per behavior. Name it `should <expected behavior> when <condition>`
- **Arrange / Act / Assert** — three clear sections, blank lines between
- No shared mutable state between tests — use `setUp()` for fresh instances
- No network, no disk, no real timers. If you need them, it's an integration test
- `expect(actual, matcher)` — never `expect(actual == expected, true)`
- Every branch of a `switch`/`if` needs a test — including the default/else

```dart
// Good
test('should return failure when API returns 500', () async {
  // Arrange
  when(() => apiClient.get(any())).thenAnswer((_) async => ApiResult.error('500'));

  // Act
  final result = await repository.loadItems();

  // Assert
  expect(result.success, isFalse);
  expect(result.error, contains('500'));
});
```

---

## Widget Tests

- Every screen has tests for **all 4 states**: loading, empty, error, content
- Use `pumpWidget` with a minimal widget tree — wrap only what's needed (Provider, MaterialApp, etc.)
- `tester.pumpAndSettle()` only after you know animations have a terminal state — infinite animations will hang
- Interact via `tester.tap(find.byKey(...))`, `tester.enterText(...)`, `tester.drag(...)` — not by manipulating widget state directly
- Use `Key`s on widgets you test, not text content (text changes with localization)
- Assert visible UI, not internal widget state — `find.text('Welcome')` beats `expect(widget.label, 'Welcome')`

```dart
testWidgets('shows empty state when no items', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [itemsProvider.overrideWith((_) => [])],
      child: const MaterialApp(home: ItemsScreen()),
    ),
  );

  expect(find.byKey(const Key('empty-state')), findsOneWidget);
  expect(find.text('No items yet'), findsOneWidget);
});
```

---

## Integration Tests

- Reserved for critical flows. If it breaks, users notice immediately — cover it.
- Run against a real-ish environment: real navigation, real state, mocked network at the edges
- `integration_test/` directory, runs on device/emulator
- Don't duplicate widget test coverage — integration tests prove the seams work
- Keep them deterministic: seed data, frozen clock, predictable network responses

---

## Golden Tests

- Only for screens where visual regressions would be caught by no other test (brand-critical surfaces, complex custom-painted widgets, design-system showcase screens)
- Not a substitute for widget tests — a golden proves pixels match, not that the logic is right
- Regenerate goldens intentionally, never as a "just update it" reflex — understand what changed first
- Keep golden images small (fixed viewport) and in the repo

---

## Mocking Strategy

- `mocktail` preferred over `mockito` — cleaner syntax, no build_runner
- Mock at the seam closest to what you're testing:
  - Testing a repository? Mock the API client.
  - Testing a provider? Mock the repository.
  - Testing a widget? Override the provider.
- **Never mock the class under test** — if you're mocking half of what you're testing, the test is wrong
- **Never mock value objects** (models, DTOs) — construct real instances
- Register fallback values once in a test helper: `registerFallbackValue(FakeRequest())`

---

## State Management Testing

**Riverpod:**
- `ProviderContainer` for unit-testing providers
- `ProviderScope` with `overrides:` for widget tests
- `container.listen(provider, (prev, next) { ... })` to capture emission sequences
- `container.dispose()` in `tearDown`

**Provider/ChangeNotifier:**
- Construct the notifier directly, call methods, assert state
- For widgets: wrap in `ChangeNotifierProvider.value(value: notifier)`

---

## Async Test Handling

- Always `await` async operations in tests — dangling futures cause flaky tests
- `pumpAndSettle(Duration)` with a timeout — never unbounded
- For streams: `expectLater(stream, emitsInOrder([...]))`
- For timers: `fakeAsync((async) { ... async.elapse(Duration(seconds: 5)); })`
- Avoid `Future.delayed` in tests — use `fake_async` or manual pump

---

## Coverage

- **Realistic targets:** 70–80% unit, 50–60% widget, critical-path only for integration
- Coverage number alone proves nothing — 100% coverage with weak assertions is worse than 60% with strong ones
- Track coverage trend, not absolute — don't let it drop
- Exclude generated code (`*.g.dart`, `*.freezed.dart`), `main.dart`, and trivial DTOs from coverage reports

---

## CI Gates

Before merge, the CI pipeline must enforce:

1. `flutter analyze` — zero errors, zero warnings
2. `flutter test` — all pass
3. `flutter test integration_test/` — critical flows pass
4. Coverage did not drop below threshold
5. Golden tests pass (if any)

A failing test is never "flaky, just retry." Diagnose and fix or delete the test.

---

## Test Organization

```
test/
├── unit/
│   ├── models/
│   ├── mappers/
│   ├── utils/
│   └── services/
├── widget/
│   ├── screens/
│   └── components/
└── helpers/              # shared test utilities, fakes, fixtures

integration_test/
└── flows/                # end-to-end critical journeys
```

- Mirror `lib/` structure in `test/unit/` and `test/widget/`
- One test file per source file: `foo.dart` → `foo_test.dart`
- Shared fixtures in `test/helpers/` — never copy-paste test data across files

---

## Test Naming

- File: `<source>_test.dart`
- Group: `group('ClassName', () { ... })`
- Test: `test('should <behavior> when <condition>', ...)` or `testWidgets('<what it shows/does>', ...)`

Never: `test('test1', ...)`, `test('it works', ...)`, `test('basic', ...)`.

---

## Maintenance

- When a test fails after a refactor, first ask: "Did the behavior change?"
  - If yes: update the test (the behavior change was intentional)
  - If no: fix the code (the refactor broke something)
- Never delete a failing test to make CI green — that's hiding a regression
- Flaky tests are bugs. Quarantine them in a `// TODO: fix flaky` block with a ticket, then fix within one sprint or delete
- Tests deleted should have a written justification — the test existed because of a prior bug or requirement

---

## DON'TS

- Don't write tests after the feature is "done" — write them alongside (or first)
- Don't mock the class under test
- Don't test framework behavior (Flutter, Riverpod, Firebase internals)
- Don't write brittle tests that break on any refactor — test behavior, not implementation
- Don't skip tests with `skip:` without a ticket and deadline
- Don't commit `.only()` or `.focus()` — they hide other tests from running
- Don't let coverage numbers replace thinking about what matters
