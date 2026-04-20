---
name: scaffold-feature
description: Generate a complete feature folder — model, mapper, repository, provider, screen with 4 states, and test stubs. Detects app conventions (state mgmt, design-system prefix, folder layout). Bigger than scaffold-screen.
disable-model-invocation: true
argument-hint: feature-name [--with-api] [--with-persistence]
---

# Scaffold Feature

Generate a complete feature folder for `$ARGUMENTS` — not just a screen but everything around it: model, mapper, repository, provider, screen, and test stubs.

Use this when starting a new vertical slice (e.g., `lessons`, `bookmarks`, `notifications`). Use `scaffold-screen` instead for a standalone screen with no data layer.

## Pre-Generation Detection

Before writing any files, read `CLAUDE.md`, `CLAUDE.local.md`, and `pubspec.yaml` to detect:

1. **State management** — check imports and references:
   - `flutter_riverpod` / `hooks_riverpod` → Riverpod
   - `provider` → Provider
   - `flutter_bloc` → Bloc/Cubit
2. **Routing** — `go_router` in pubspec vs. `Navigator.pushNamed` + `generateRoute`
3. **Persistence** — `hive`, `sqflite`, `shared_preferences`, `isar`
4. **HTTP client** — `dio`, `http`, `chopper`
5. **Design-system prefix** — search for `class \w+Colors`, `class \w+Spacing` in `lib/shared/**` or `lib/core/**`. Extract the prefix (e.g., `App`, `FluentPro`, `Daypilot`).
6. **Folder convention** — check `lib/features/<any>/` to see sub-folder names used:
   - `widgets/` vs `components/`
   - `providers/` vs `state/` vs `controllers/`
   - `models/` vs `data/`
   - `repositories/` vs `repository/`
   - `services/`, `mappers/` — whether they're sub-folders or flat
7. **Test convention** — `test/` layout mirrors `lib/features/<name>/`? Or grouped differently?
8. **Error type** — does the app use `Failure` / `AppException` / raw `Exception`?
9. **Mapper pattern** — `fromJson` on the model, separate `XMapper` class, or both?

Record these conventions; match them exactly when generating files.

## Arguments

- `feature-name` (required) — kebab-case or snake_case: `lessons`, `user-bookmarks`
- `--with-api` (optional) — include repository + mapper + remote data source
- `--with-persistence` (optional) — include local cache (Hive box or similar)
- If neither flag: scaffold is UI-only with a placeholder provider returning mock data

## Generated Structure

For feature name `bookmarks` with Riverpod + `--with-api` + `--with-persistence` and design-system prefix `App`:

```
lib/features/bookmarks/
├── models/
│   └── bookmark.dart                    # Freezed model OR plain class matching convention
├── mappers/
│   └── bookmark_mapper.dart             # JSON ↔ model
├── repositories/
│   └── bookmark_repository.dart         # Abstraction over remote + local
├── data_sources/
│   ├── bookmark_remote_data_source.dart # Thin wrapper over API client
│   └── bookmark_local_data_source.dart  # Hive box access
├── providers/
│   ├── bookmark_repository_provider.dart # DI for repo
│   └── bookmarks_provider.dart          # FutureProvider / StateNotifierProvider
├── screens/
│   └── bookmarks_screen.dart            # 4 states wired (use scaffold-screen logic)
├── widgets/
│   └── bookmark_tile.dart               # Starter widget
└── README.md                            # Feature summary + data flow

test/features/bookmarks/
├── models/bookmark_test.dart
├── mappers/bookmark_mapper_test.dart
├── repositories/bookmark_repository_test.dart
├── providers/bookmarks_provider_test.dart
└── screens/bookmarks_screen_test.dart   # widget test with mocked provider
```

Adjust sub-folder names to match detected convention. If the app uses flat layout (no sub-folders), put all files in `lib/features/bookmarks/` directly with clear filename prefixes.

## File Templates

All templates below assume detected Riverpod + detected `App*` design-system prefix. Swap accordingly.

### Model (Freezed if detected, else plain)

```dart
// lib/features/bookmarks/models/bookmark.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'bookmark.freezed.dart';
part 'bookmark.g.dart';

@freezed
class Bookmark with _$Bookmark {
  const factory Bookmark({
    required String id,
    required String title,
    required DateTime createdAt,
  }) = _Bookmark;

  factory Bookmark.fromJson(Map<String, dynamic> json) => _$BookmarkFromJson(json);
}
```

If Freezed is NOT in pubspec, generate a plain immutable class with `const` constructor, `copyWith`, `==`, `hashCode`, and `toJson`/`fromJson` — or defer serialization to the mapper (detected pattern wins).

### Mapper

```dart
// lib/features/bookmarks/mappers/bookmark_mapper.dart
import '../models/bookmark.dart';

class BookmarkMapper {
  static Bookmark fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static Map<String, dynamic> toJson(Bookmark bookmark) {
    return {
      'id': bookmark.id,
      'title': bookmark.title,
      'created_at': bookmark.createdAt.toIso8601String(),
    };
  }
}
```

If the app puts `fromJson`/`toJson` on the model itself (no separate mapper class), skip this file and put the logic on the model.

### Remote Data Source

```dart
// lib/features/bookmarks/data_sources/bookmark_remote_data_source.dart
import '../models/bookmark.dart';
import '../mappers/bookmark_mapper.dart';
// import the app's API client (detect actual import path)

class BookmarkRemoteDataSource {
  BookmarkRemoteDataSource(this._api);

  final ApiClient _api;

  Future<List<Bookmark>> fetchAll() async {
    final response = await _api.get('/bookmarks');
    final items = (response.data as List).cast<Map<String, dynamic>>();
    return items.map(BookmarkMapper.fromJson).toList();
  }

  Future<void> add(Bookmark bookmark) async {
    await _api.post('/bookmarks', data: BookmarkMapper.toJson(bookmark));
  }

  Future<void> remove(String id) async {
    await _api.delete('/bookmarks/$id');
  }
}
```

### Local Data Source

```dart
// lib/features/bookmarks/data_sources/bookmark_local_data_source.dart
import 'package:hive/hive.dart';
import '../models/bookmark.dart';
import '../mappers/bookmark_mapper.dart';

class BookmarkLocalDataSource {
  static const _boxName = 'bookmarks';

  Future<Box<Map>> _box() async {
    if (Hive.isBoxOpen(_boxName)) return Hive.box<Map>(_boxName);
    return Hive.openBox<Map>(_boxName);
  }

  Future<List<Bookmark>> readAll() async {
    final box = await _box();
    return box.values
        .map((e) => BookmarkMapper.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> writeAll(List<Bookmark> items) async {
    final box = await _box();
    await box.clear();
    for (final item in items) {
      await box.put(item.id, BookmarkMapper.toJson(item));
    }
  }
}
```

### Repository

```dart
// lib/features/bookmarks/repositories/bookmark_repository.dart
import '../models/bookmark.dart';
import '../data_sources/bookmark_remote_data_source.dart';
import '../data_sources/bookmark_local_data_source.dart';

class BookmarkRepository {
  BookmarkRepository({
    required BookmarkRemoteDataSource remote,
    required BookmarkLocalDataSource local,
  })  : _remote = remote,
        _local = local;

  final BookmarkRemoteDataSource _remote;
  final BookmarkLocalDataSource _local;

  Future<List<Bookmark>> list({bool refresh = false}) async {
    if (!refresh) {
      final cached = await _local.readAll();
      if (cached.isNotEmpty) return cached;
    }
    final fresh = await _remote.fetchAll();
    await _local.writeAll(fresh);
    return fresh;
  }

  Future<void> add(Bookmark bookmark) => _remote.add(bookmark);
  Future<void> remove(String id) => _remote.remove(id);
}
```

### Providers

```dart
// lib/features/bookmarks/providers/bookmark_repository_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/bookmark_repository.dart';
import '../data_sources/bookmark_remote_data_source.dart';
import '../data_sources/bookmark_local_data_source.dart';
// import the API client provider (detect actual path)

final bookmarkRepositoryProvider = Provider<BookmarkRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return BookmarkRepository(
    remote: BookmarkRemoteDataSource(api),
    local: BookmarkLocalDataSource(),
  );
});
```

```dart
// lib/features/bookmarks/providers/bookmarks_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bookmark.dart';
import 'bookmark_repository_provider.dart';

final bookmarksProvider = FutureProvider.autoDispose<List<Bookmark>>((ref) async {
  final repo = ref.watch(bookmarkRepositoryProvider);
  return repo.list();
});
```

### Screen

Delegate to the `scaffold-screen` skill's template — same 4 states (loading/empty/error/content), same design-token references, same `ref.watch(bookmarksProvider).when(...)` pattern.

### Widget starter

```dart
// lib/features/bookmarks/widgets/bookmark_tile.dart
import 'package:flutter/material.dart';
import '../models/bookmark.dart';

class BookmarkTile extends StatelessWidget {
  const BookmarkTile({super.key, required this.bookmark, this.onTap});

  final Bookmark bookmark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(bookmark.title),
      subtitle: Text('${bookmark.createdAt.toLocal()}'),
      onTap: onTap,
    );
  }
}
```

Encourage replacement with `AppCard` / `AppListTile` (or detected equivalents) rather than raw Material — flag this as a "replace with design-system widget" TODO in the file.

### Feature README

```markdown
# Bookmarks

Short description of what this feature does.

## Data flow

API (`/bookmarks`) → BookmarkRemoteDataSource → BookmarkRepository
                                                      ↓
                                         BookmarkLocalDataSource (Hive: 'bookmarks')

Repository returns cached data immediately when present; refresh param forces a remote fetch.

## State

- `bookmarkRepositoryProvider` — DI for the repository
- `bookmarksProvider` — FutureProvider returning the list

## Screens

- `BookmarksScreen` — list of bookmarks with 4-state wiring

## TODOs

- Replace raw ListTile in BookmarkTile with design-system widget
- Add pagination once the API supports it
- Add optimistic update for add/remove
```

### Test stubs

```dart
// test/features/bookmarks/mappers/bookmark_mapper_test.dart
import 'package:flutter_test/flutter_test.dart';
// match detected test framework (mocktail vs mockito)

void main() {
  group('BookmarkMapper.fromJson', () {
    test('parses a well-formed payload', () {
      // arrange
      // act
      // assert
    });

    test('defaults missing optional fields', () {
      // arrange — json without `title`
      // act
      // assert — bookmark.title == ''
    });

    test('throws on missing required fields', () {
      // arrange — json without `id`
      // act / assert — expect throws
    });
  });
}
```

Repeat stubs for repository (mock data sources), provider (override repository), screen (mock provider + pump).

## After Generation

Print to the user:

```
Scaffolded feature: bookmarks

Created:
  lib/features/bookmarks/ (N files)
  test/features/bookmarks/ (M test stubs)

Next steps:
  1. Run `dart run build_runner build` (freezed + json_serializable if detected)
  2. Open lib/features/bookmarks/screens/bookmarks_screen.dart — wire the empty/error copy
  3. Replace placeholder widgets in widgets/ with design-system versions
  4. Fill in the test stubs — arrange/act/assert blocks are scaffolded
  5. Register the route (detected: GoRouter / Navigator.generateRoute)

Detected conventions:
  - State management: Riverpod
  - Design-system prefix: App
  - Mapper style: separate mapper class (BookmarkMapper.fromJson)
  - Test framework: mocktail
  - Folder layout: feature/<models|mappers|repositories|data_sources|providers|screens|widgets>

Mismatched? Edit the files and tell me — I'll adjust the template for next time.
```

## Don'ts

- **Don't scaffold without detecting conventions first** — generating Riverpod code in a Bloc app wastes the user's time
- **Don't hardcode import paths** — use the detected API client provider path, not a made-up one
- **Don't generate files for layers the app doesn't use** — if the app has no local cache, skip `BookmarkLocalDataSource`
- **Don't invent API endpoints** — use a placeholder with a TODO comment, user wires the real one
- **Don't skip the feature README** — it forces the author to document the data flow while it's fresh
- **Don't leave tests empty** — scaffold the group/test structure with arrange/act/assert comments so the intent is visible
- **Don't cross-reference scaffold-screen's logic** — re-run it here for the screen file, don't duplicate the template inline

## Pairs With

- `scaffold-screen` — for when you need just a screen, no data layer
- `find-duplicates` — after scaffolding, run to catch any helpers the new feature duplicates from existing ones
- `verify-screens` — after wiring real data, run to confirm source → screen trace is clean
- `pre-ship` — final gate before merging the new feature
