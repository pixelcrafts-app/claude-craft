---
name: find-hardcoded
description: Scan lib/ for hardcoded values that should be design-system tokens — hex colors, magic numbers in EdgeInsets/BorderRadius/SizedBox, inline TextStyle, uncommon Durations
disable-model-invocation: true
argument-hint: [optional-directory]
---

# Find Hardcoded Values

Scan `$ARGUMENTS` (default: `lib/`) for hardcoded design values that should reference the app's design system. Report file:line with suggested replacements.

## Scan Targets

Run each pattern below via Grep against the target directory. Collect all matches, then filter using the **ignore list** at the bottom.

### 1. Hardcoded hex colors

Pattern: `Color\(0x[0-9A-Fa-f]{8}\)` or `Color\.fromARGB`
- Every match is a violation unless it's in the app's `colors.dart` or equivalent theme file
- Suggested fix: "Replace with `AppColors.<name>` from the design system. If no token exists, add one."

### 2. Magic EdgeInsets

Patterns:
- `EdgeInsets\.all\([0-9]+(\.[0-9]+)?\)`
- `EdgeInsets\.symmetric\(horizontal: [0-9]+`
- `EdgeInsets\.symmetric\(vertical: [0-9]+`
- `EdgeInsets\.only\([a-z]+: [0-9]+`
- `EdgeInsets\.fromLTRB\([0-9]`

- Every numeric literal is a violation unless it's `0`
- Suggested fix: "Replace with `AppSpacing.<name>` (check spacing scale for closest match)."

### 3. Magic SizedBox dimensions

Patterns:
- `SizedBox\(height: [0-9]`
- `SizedBox\(width: [0-9]`

- Literals other than `0` are violations
- `SizedBox.shrink()` and `SizedBox.expand()` are fine
- Suggested fix: "Replace with `SizedBox(height: AppSpacing.<name>)`."

### 4. Magic BorderRadius

Patterns:
- `BorderRadius\.circular\([0-9]`
- `BorderRadius\.all\(Radius\.circular\([0-9]`
- `Radius\.circular\([0-9]`

- Suggested fix: "Replace with `AppRadius.<name>Border` or `BorderRadius.circular(AppRadius.<name>)`."

### 5. Inline TextStyle

Pattern: `TextStyle\(` — any construction outside the typography module
- Any inline `TextStyle(fontSize: ...)`, `TextStyle(fontWeight: ...)`, `TextStyle(color: ...)` is a violation
- Exception: the typography module itself where styles are defined
- Suggested fix: "Replace with `AppTypography.<name>` from the typography scale, possibly chained with `.copyWith(color: ...)` using design-system colors only."

### 6. Hardcoded durations

Pattern: `Duration\(milliseconds: [0-9]+\)` or `Duration\(seconds: [0-9]+\)`
- Flag uncommon values. Standard durations (100, 150, 200, 300, 400, 600 ms) MAY be inline if they match the motion standards in `craft-guide.md`, but should ideally be named (e.g., `AppAnimations.fast`).
- Suggested fix: "Move to `AppAnimations` or an animation-constants module."

### 7. Hardcoded font weights outside typography

Pattern: `FontWeight\.w[0-9]+` outside the typography module
- Suggested fix: "Use `AppTypography.<name>.semiBold` or `.bold` extensions."

### 8. Opacity / alpha magic

Pattern: `withValues\(alpha: 0\.[0-9]+\)` or `withOpacity\(0\.[0-9]+\)`
- Very common but often repeated — flag if the same alpha value appears in 3+ places with no named constant
- Suggested fix: "Define `AppColors.<name>Muted` or `AppOpacity.<name>` and reuse."

## Ignore List

Skip matches in:
- `lib/**/theme/*.dart` — the design system itself defines raw values
- `lib/**/colors.dart`, `typography.dart`, `spacing.dart`, `radius.dart`, `shadows.dart`, `gradients.dart`, `animations.dart`
- `test/**` — test files may use literals to construct fixtures
- Files matching `*.g.dart`, `*.freezed.dart` — generated code
- Lines containing `// design-system` or `// allow-literal` — explicit opt-out markers
- Commented-out code (lines starting with `//` or inside `/* */`)

## Report Format

Group findings by severity. Use this structure:

```
# Hardcoded Values Report

Scope: lib/
Scanned: <N> .dart files
Violations: <total>

## Critical (colors & typography)
lib/features/home/home_screen.dart:42
  Color(0xFFB4A0FF)
  → Replace with AppColors.primary (or add new token if this color isn't in the system)

lib/features/profile/profile_header.dart:18
  TextStyle(fontSize: 20, fontWeight: FontWeight.w600)
  → Replace with AppTypography.headlineSmall.semiBold

## High (spacing & radius)
lib/features/home/home_screen.dart:67
  EdgeInsets.all(13)
  → Replace with EdgeInsets.all(AppSpacing.smmd) (closest match: 12)
  → Or add AppSpacing.mds13 = 13 if the value is intentional

lib/shared/widgets/card.dart:24
  BorderRadius.circular(7)
  → Replace with BorderRadius.circular(AppRadius.smd) (closest match: 8)

## Medium (durations)
lib/features/onboarding/splash.dart:89
  Duration(milliseconds: 350)
  → Non-standard duration. Move to AppAnimations or use a standard value (300 or 400).

## Summary
- <N> color violations across <M> files
- <N> spacing violations across <M> files
- <N> typography violations across <M> files
- Top offenders (by file): <list>

## Next Steps
1. Start with Critical violations — colors leak brand consistency
2. Fix Spacing next — it's the most common pattern across apps
3. Typography last — may require adding new tokens to the scale
```

## Before Reporting

- Confirm each violation is actually a violation (check ignore list, check the file isn't the design system)
- Suggest the **closest existing token** for spacing/radius — don't just say "use a token"
- For hex colors: if you recognize the color from the design system, name it. If not, flag as "add new token or reuse existing."
- Count violations per file — apps often have one or two bad actors

## Verdict

- **0 violations:** Clean. Report "No hardcoded design values found in scanned scope."
- **1–10 violations:** Quick cleanup. Fix inline.
- **11–50 violations:** Systemic. Fix in a dedicated pass.
- **50+ violations:** Design system adoption incomplete. Flag at architecture level — discuss with team before bulk-changing.
