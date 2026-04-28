---
name: scaffold
description: "Scaffold a new Flutter feature or screen with correct structure and file locations. Explicit command only."
argument-hint: "feature <name> [--with-api] [--with-persistence] | screen <name> <feature-path> [provider-name]"
---

# flutter:scaffold

Scaffold a new Flutter feature or screen for `$ARGUMENTS`.

## Pre-Generation Detection

Before writing any files, read `CLAUDE.md`, `CLAUDE.local.md`, and `pubspec.yaml` to detect:

- State management (`flutter_riverpod`, `provider`, `flutter_bloc`, `StatefulWidget`)
- Design-system prefix (grep `class \w+Colors` in `lib/shared/` or `lib/core/`)
- Folder convention (inspect existing `lib/features/<any>/` for sub-folder naming)
- Router (`go_router` vs `Navigator.generateRoute`)
- Persistence and HTTP client packages

Report detected conventions to the user in one line before writing files.

## Target: `feature`

Usage: `/flutter:scaffold feature <name> [--with-api] [--with-persistence]`

Required file locations — sub-folder names must match the detected convention:

| Path | Purpose |
|------|---------|
| `lib/features/<name>/models/` | Domain model |
| `lib/features/<name>/mappers/` | JSON ↔ model (only if app uses separate mapper class) |
| `lib/features/<name>/repositories/` | Abstraction over data sources |
| `lib/features/<name>/data_sources/` | Remote and/or local source (flags control inclusion) |
| `lib/features/<name>/providers/` | Repository provider + data provider |
| `lib/features/<name>/screens/` | Screen file — apply screen rules below |
| `lib/features/<name>/widgets/` | Feature-scoped widget starters |
| `test/features/<name>/` | Mirrored test stubs with arrange/act/assert comments |

Rules:
- Detect and match the existing mapper pattern (model-level `fromJson` vs separate mapper class); do not generate both.
- Omit data_sources/repository layers when neither `--with-api` nor `--with-persistence` is given; scaffold UI-only with a placeholder provider returning mock data.
- Use detected HTTP client and persistence packages; do not hardcode API paths — leave a `// TODO` placeholder.
- Generate a `README.md` inside the feature folder documenting data flow and provider names.
- Never generate files for layers the app does not use.
- For structure rules see `flutter-standards:engineering §Reusability`.

## Target: `screen`

Usage: `/flutter:scaffold screen <ScreenName> <feature-path> [provider-name]`

Required file structure:

| File | Content |
|------|---------|
| `<feature-path>/<screen_name>_screen.dart` | Main screen with all four states |

All four states are required — no exceptions:

| State | Rule |
|-------|------|
| Loading | Skeleton matching the final layout; use shared skeleton widget if it exists |
| Empty | Inviting message, single clear CTA; never "No data" |
| Error | Specific actionable message with retry; never "Something went wrong" |
| Content | Real data binding; all values from design tokens |

State dispatcher must match the detected pattern: `AsyncValue.when` for Riverpod, `switch` on status field for Bloc/Provider, `StreamBuilder` for streams.

For widget patterns see `flutter-standards:engineering §Widget Patterns`. For architecture and placement see `flutter-standards:engineering`.

## After Generation

Report:
1. Detected conventions used
2. TODOs the developer must fill in (provider name, model type, route registration, empty-state copy)
3. Next build steps (e.g., `dart run build_runner build` if Freezed detected)
