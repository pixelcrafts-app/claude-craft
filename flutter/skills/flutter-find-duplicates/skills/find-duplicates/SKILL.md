---
name: find-duplicates
description: Scan lib/ for DRY violations — widgets rendering the same UI under different names, helpers doing the same format/parse, providers exposing the same data, mappers parsing the same API shape, copy-pasted card/list/button code
disable-model-invocation: true
argument-hint: [optional-directory]
---

# Find DRY Violations

Scan `$ARGUMENTS` (default: `lib/`) for code that duplicates existing code. Report pairs/groups with the suggested extraction target and rough effort.

Unlike `find-hardcoded` (which looks at literals), this skill looks at **structure** — widgets, functions, classes that do the same thing under different names.

## Scan Targets

### 1. Widget Duplicates

Look for widgets that render visually identical UI with different class names.

**Detection approach:**
- Grep `class \w+ extends (Stateless|Stateful|Consumer|HookConsumer)Widget`
- For each widget, extract its `build()` method skeleton (strip variable names, keep structure: `Column > [Container, Text, Row > [Icon, Text]]`)
- Group widgets with identical skeletons
- Manual verification needed — similar skeletons don't always mean duplication

**Common patterns:**
- `HomeCard` and `ProfileCard` both render `Container > Padding > Column > [Text, Text, SizedBox, Row > [Icon, Text]]`
- `PrimaryButton`, `SubmitButton`, `CtaButton` all wrap `FilledButton` with the same styling
- `LoadingList` and `ShimmerList` both produce placeholder rectangles

### 2. Helper/Utility Duplicates

Look for functions/extensions doing the same job under different names.

**Detection approach:**
- Grep `String formatDate`, `String formatTime`, `String formatDuration`, `String formatCurrency`
- Grep `bool isValidEmail`, `bool validateEmail`, `bool emailIsValid`
- Grep `extension \w+ on DateTime`, `extension \w+ on String`
- Group by function signature (return type + params), flag duplicates

**Common duplicate functions:**
- Date formatting (`formatDate`, `toDisplayDate`, `formatForList`, `toReadable`)
- String validation (email, phone, URL)
- Number formatting (currency, percent, compact)
- Duration humanizers ("2h ago", "Yesterday")
- Color manipulators (lighten, darken, opacity variants)

### 3. Provider Duplicates

Look for providers exposing the same data through different names.

**Detection approach:**
- Grep `Provider<`, `FutureProvider<`, `StateNotifierProvider<`, `StreamProvider<`
- For each, identify what it returns and what source it reads from
- Flag cases where two providers return the same data from the same source

**Common patterns:**
- `currentUserProvider` and `userProvider` — same thing
- `itemsProvider` and `itemListProvider` — same data
- `isPremiumProvider` and `premiumStatusProvider` — same flag

### 4. Mapper Duplicates

Look for mappers parsing the same API shape.

**Detection approach:**
- Grep `class \w+Mapper`, `\w+ fromJson\(Map<String, dynamic> json\)`, `static \w+ parse\(`
- Identify input shape (field names used) and output type
- Flag multiple mappers producing the same output type

**Common patterns:**
- Two `UserMapper` classes in different features
- `fromJson` on the model AND a separate mapper class — pick one
- Legacy mapper + new mapper coexisting after a refactor

### 5. Copy-Pasted Card/List/Button Code

Look for inline widget code duplicated across screens.

**Detection approach:**
- Grep for common patterns like `Container(decoration: BoxDecoration(` — count per file and total
- Extract patterns that appear 3+ times with minor variations
- Flag inline button styling (`ElevatedButton.styleFrom(...)`) appearing across files instead of in a shared button family

**Common patterns:**
- Inline `Card` with same padding/radius/shadow across 4+ screens
- `ListTile`-equivalent built from `Row > [Icon, Column, Icon]` repeated
- Bottom action button with same shadow/margin/padding copied into each screen

### 6. Service/Repository Duplicates

**Detection approach:**
- Grep `class \w+Service`, `class \w+Repository`
- Flag services with overlapping responsibilities (e.g., `UserService` and `ProfileService` both managing user data)

## Ignore List

Skip matches in:
- `test/**` — test fixtures often duplicate intentionally
- `*.g.dart`, `*.freezed.dart` — generated code
- Abstract classes and interfaces (they SHOULD have multiple implementations)
- `deprecated_` prefixed files/classes (deletion target)
- Files in `migrations/` (one-time)

## Report Format

Group findings by type. Lead with highest-impact violations (most duplicated code).

```
# DRY Violation Report

Scope: lib/
Scanned: <N> .dart files
Candidate violations: <total>

## Critical (3+ copies of the same structure)

### Card widgets (5 copies)
Target extraction: lib/shared/widgets/cards/app_card.dart
Copies at:
  lib/features/home/widgets/home_card.dart:12
  lib/features/profile/widgets/profile_card.dart:8
  lib/features/modules/widgets/module_card.dart:14
  lib/features/lessons/widgets/lesson_card.dart:10
  lib/features/achievements/widgets/achievement_card.dart:18
Common structure:
  Container > Padding > Column > [Text(title), SizedBox, Text(subtitle), Row > [Icon, Text(meta)]]
Differences: title/subtitle/meta content, icon choice
Extraction effort: medium — parameterize title/subtitle/icon/onTap

### Email validator (3 copies)
Target: lib/shared/utils/validators.dart
Copies at:
  lib/features/auth/signin/signin_form.dart:42 — bool isValidEmail(String v)
  lib/features/auth/signup/signup_form.dart:38 — bool validateEmail(String email)
  lib/features/profile/edit/email_field.dart:22 — bool _emailIsValid(String s)
Extraction effort: low — three lines, one function

## High (2 copies)

### User provider
  lib/features/profile/providers/current_user_provider.dart
  lib/shared/providers/user_provider.dart
Both expose the same `User?` from `UserRepository.instance.current`.
Extraction: keep `currentUserProvider` in shared/, delete the feature copy.

### UserMapper
  lib/features/auth/mappers/user_mapper.dart
  lib/shared/mappers/user_mapper.dart
Both parse `{ id, email, name, avatar_url }` to `User`.
Extraction: shared version wins — it handles the cache format too.

## Medium (inline repeated patterns)

### Inline Card decoration (appears 8 times)
Pattern: `Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(color: ..., borderRadius: BorderRadius.circular(12), boxShadow: [...]))`
Files: <list of 8 files>
Extraction: AppCard widget with optional padding/elevation params.

## Summary
- <N> widget duplicates across <M> feature folders
- <N> helper duplicates
- <N> provider duplicates
- <N> mapper duplicates
- Top offender folders: <list>
- Estimated LoC saved by extraction: ~<N>

## Extraction Plan (recommended order)

1. **High-traffic widgets first** — one card/button widget used 5 times saves the most
2. **Validators + formatters next** — small, easy wins, used throughout forms
3. **Providers/mappers last** — require careful refactor, higher risk of breaking data flow
```

## Before Reporting

- **Verify** — similar structure doesn't always mean duplication. A `ProductCard` and a `UserCard` may look identical but represent different domain concepts. Flag as candidates, let the user decide.
- **Suggest a concrete extraction target** — say *where* the shared version should live (see engineering.md's "Centralize Cross-Cutting Concerns" table)
- **Estimate effort** — low (copy-paste wrapper), medium (parameterize), high (refactor call sites)
- **Order by impact** — LoC saved × frequency of change

## Verdict

- **0 candidates:** Exceptionally clean. Report and note "no DRY violations found — codebase is well-factored."
- **1–5 candidates:** Good hygiene. Fix opportunistically.
- **6–20 candidates:** Typical mid-size app. Schedule a refactor sprint.
- **20+ candidates:** Systemic DRY problem. Flag at architecture level — the issue isn't individual duplicates, it's the absence of a shared widget library.
