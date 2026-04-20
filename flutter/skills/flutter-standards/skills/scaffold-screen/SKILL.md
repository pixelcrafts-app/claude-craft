---
name: scaffold-screen
description: Generate a new screen file with all four states wired (loading, empty, error, content), design tokens referenced (no hardcodes), and the app's state-management pattern applied
disable-model-invocation: true
argument-hint: [screen-name] [feature-path] [optional-provider-name]
---

# Scaffold Screen

Generate a complete screen scaffold at `$ARGUMENTS`. The output is a single `.dart` file with all four states handled, design tokens referenced, and the app's state-management pattern applied.

## Before Generating

Detect the app's conventions — do NOT assume:

1. **State management** — Grep `lib/` for `ConsumerWidget` → Riverpod. For `ChangeNotifier` → Provider. For `BlocBuilder` → Bloc. For `StatefulWidget` only → setState.
2. **Design system class names** — Grep for `class App*Colors`, `class App*Typography`, `class App*Spacing`, or `FluentPro*`, `Daypilot*` etc. Use the detected prefix.
3. **Theme extension** — Check if the app uses `context.colors.xxx` (extension) or `AppColors.xxx` (static). Match the dominant pattern.
4. **Shared state widgets** — Grep for `class LoadingState`, `class EmptyState`, `class ErrorState`. If they exist, use them. If not, inline the states and note to the user that they should be extracted.
5. **Router** — Grep for `GoRouter`, `generateRoute`, `RoutePaths`, `AppRoutes`. Match the routing pattern; don't invent route names.
6. **Feature folder structure** — Check if the app uses `lib/features/<feature>/presentation/screens/` or `lib/features/<feature>/screens/` or something else.

Report the detected conventions to the user in one line before writing, so they can correct if needed.

## Arguments

- `<screen-name>` — PascalCase name of the screen, e.g., `ProfileSettings`
- `<feature-path>` — relative path where the screen belongs, e.g., `lib/features/profile/screens/`
- `<provider-name>` (optional) — the provider/notifier/bloc supplying data. If omitted, leave a clearly marked placeholder.

## Scaffold Structure

Every scaffold has these regions in order:

```
<imports>

class <ScreenName>Screen extends <base-class> {
  const <ScreenName>Screen({super.key});

  @override
  Widget build(BuildContext context<, WidgetRef ref if applicable>) {
    return Scaffold(
      appBar: <header-widget>,
      body: SafeArea(
        child: <state-dispatcher>,
      ),
    );
  }
}

<private state widgets: _LoadingView, _EmptyView, _ErrorView, _ContentView>
```

## State Dispatcher

- **Riverpod AsyncValue:** `data.when(loading: ..., error: ..., data: ...)` with an additional empty check inside `data`
- **Manual state (StateNotifier / ChangeNotifier / Bloc):** `switch` on status field (`loading`, `error`, `empty`, `content`)
- **Stream:** `StreamBuilder` with connectionState handling for all four states
- Every branch returns a distinct widget — no merged states, no spinners standing in for missing empty states

## Each State Requirement

### Loading
- Skeleton matching the final layout (not a spinner)
- Uses shared skeleton widget if one exists; otherwise inline a `Column` of placeholder `Container`s with `AppColors.skeleton` or equivalent
- Matches the final layout dimensions (card sizes, line widths) to minimize visual jump

### Empty
- Illustration or icon (use `iconsax` or app's icon family — never mix)
- Inviting message — never "No data" or "Empty"
- Single clear primary action — CTA button using `AppButtons.primary` or equivalent
- Centered vertically, anchored with top padding for visual weight

### Error
- Specific message placeholder: `"Couldn't load <what>. <actionable-hint>"`
- Retry button — calls the provider's reload method
- Contact/support link if app has one
- Never "Something went wrong" or "Error occurred"

### Content
- Real data binding from the provider
- Every text: from `AppTypography.xxx`
- Every color: from `AppColors.xxx` or `context.colors.xxx`
- Every spacing: from `AppSpacing.xxx`
- Every radius: from `AppRadius.xxx`
- Every interactive element: ≥48×48 dp touch target with `Semantics` label
- Every list: `ListView.builder` if >20 items; `Column` + `SingleChildScrollView` if shorter
- Text has `maxLines` + `overflow` protection where content is user-generated or variable-length

## Template (Riverpod + AsyncValue example)

Output structure Claude should produce. Adapt to detected state-management pattern:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// + design system imports detected from the app

class <ScreenName>Screen extends ConsumerWidget {
  const <ScreenName>Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(<providerName>);

    return Scaffold(
      appBar: AppBar(
        title: Text('<Screen Title>', style: AppTypography.titleLarge),
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: data.when(
          loading: () => const _LoadingView(),
          error: (err, stack) => _ErrorView(
            message: 'Couldn\'t load <what>. Pull down to retry.',
            onRetry: () => ref.invalidate(<providerName>),
          ),
          data: (items) => items.isEmpty
              ? _EmptyView(onAction: () { /* TODO: primary action */ })
              : _ContentView(items: items),
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    // Skeleton matching final layout — 3 placeholder cards
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: 3,
      itemBuilder: (_, __) => Container(
        height: 80,
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.skeleton,
          borderRadius: AppRadius.mdBorder,
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onAction});
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // TODO: illustration or icon
            Icon(Icons.inbox_outlined, size: 64, color: AppColors.textMuted),
            const SizedBox(height: AppSpacing.md),
            Text('<Inviting empty message>',
                style: AppTypography.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text('<Hint about what to do first>',
                style: AppTypography.bodyMedium.muted,
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: onAction,
              child: const Text('<Primary action>'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(message,
                style: AppTypography.bodyLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContentView extends StatelessWidget {
  const _ContentView({required this.items});
  final List<dynamic> items; // TODO: replace with concrete model type

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        // TODO: render real item
        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: ListTile(
            title: Text(item.toString(),
                style: AppTypography.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        );
      },
    );
  }
}
```

## After Generation

Report to the user:

1. **Detected conventions** — state management, design system prefix, theme extension pattern, shared state widgets found/missing
2. **TODOs the developer must fill in** — provider name if not provided, model type, illustration, empty-state message, primary-action callback
3. **Route registration reminder** — "Add route to `<router-file>` with path `/<screen-name>`"
4. **Verification checklist** — "Run `flutter analyze` after filling TODOs; then use the `verify-screens` skill to audit the data pipeline."

## Don'ts

- Don't generate a screen that skips any of the four states
- Don't use any hardcoded values — if you don't know the design system name, leave a placeholder with `// TODO: confirm token name` rather than guess
- Don't invent router syntax — detect and match the app's pattern
- Don't add features the user didn't ask for (no FABs, tabs, search bars unless requested)
- Don't create a generic screen that ignores the app's existing shared widgets (loading/error/empty states) — if the app has them, use them
