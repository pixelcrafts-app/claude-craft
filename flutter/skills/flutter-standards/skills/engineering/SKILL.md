---
name: engineering
description: Apply when writing or reviewing any Dart or Flutter code — DRY, single source of truth, Surgeon Principle, no hardcoded values, centralized cross-cutting concerns, consistent error handling, security by default, AI-Assisted Definition of Done. Auto-invoke on any Flutter code change.
---

# Engineering Discipline Guide

> Verification, architecture, and operational discipline.
> The craft guide governs how things look and feel. This guide governs how things are built and shipped.
> Code-level rules live in flutter.md, api-data.md, and app-level.md — not here.

---

## CORE PRINCIPLES — OVERRIDE EVERYTHING ELSE

When a specific rule and a core principle conflict, the principle wins.

### Reusability First (DRY)

Never write the same logic twice. Before writing any widget, helper, mapper, provider, or constant, search the codebase. If it exists, use it. If it almost exists, extend it. If it doesn't exist and will be needed in 2+ places, create it in the right shared location *first*, then use it from both sites.

```
Before writing code, ask:
1. Does this widget/helper already exist in lib/shared/widgets/, lib/shared/services/, lib/shared/utils/?
2. Is another feature already solving this layout problem?
3. Am I about to copy-paste? Stop. Extract instead.
```

| Reused in 2+ widgets | Extract to `lib/shared/widgets/{category}/` |
| Reused in 2+ features | Extract to `lib/shared/widgets/` |
| Pure function, no Flutter deps | Extract to `lib/shared/utils/` |
| Shared format/parse logic | Extract to `lib/shared/utils/` |
| Feature-specific transform | Live in the feature's mapper or local helper |
| Used once, < 10 lines | Inline it |

**Forbidden:**
- Two widgets that render the same thing with different names
- Two helpers doing the same date/string/number formatting
- Two providers exposing the same data
- Two mappers parsing the same API shape
- Copy-pasted card/list/button code across feature folders

### Single Source of Truth

Every fact lives in **one place**. Importers depend on that one place.

| Fact | Single source |
|------|---------------|
| Colors | one colors file — one class + one context extension, no other sources |
| Typography | one typography file — one class with all text styles |
| Spacing | one spacing file — one class with named constants |
| Radius | one radius file — one class with named constants |
| Gradients | one gradients file — one class |
| Shadows | one shadows file — one class |
| App constants (icon sizes, button heights) | one constants file — one class |
| Routes | one routes file — one class + one `generateRoute()` or router config |
| Models | one models directory, shared across features |
| Mappers | one mappers directory, shared across features |
| Singletons | one `.instance` per service, declared in the service file |
| Persistence boxes | one storage service — no direct box access from features |
| Sync keys | one sync service — no ad-hoc dirty tracking in features |

> Each app names its own classes (e.g. `AppColors`, `FluentProColors`, `DaypilotColors`) — the rule is one class, not the prefix.

If you find a fact defined in two places, **delete one and import from the other.** No exceptions.

### No Hardcoded Values

Every literal that has meaning must be a named constant. If you can't think of a name for it, that's a sign it doesn't belong in the code at all.

```dart
// Bad
SizedBox(height: 6)
EdgeInsets.all(13)
BorderRadius.circular(7)
Color(0xFFB4A0FF)
TextStyle(fontSize: 14, fontWeight: FontWeight.w600)
Duration(milliseconds: 350)
if (count > 5) { ... }

// Good
SizedBox(height: AppSpacing.sm)
EdgeInsets.all(AppSpacing.smmd)
BorderRadius.circular(AppRadius.sm)
AppColors.primary                    // or context.colors.primary
AppTypography.bodyMedium.semiBold
const Duration(milliseconds: 300)    // route transition constant
if (count > MAX_DAILY_LESSONS) { ... }
```

**The only literals allowed inline are:**
- `0`, `1`, `-1` for boundary checks (`length == 0`, `index + 1`)
- Empty strings `''` and lists `[]`
- Boolean `true` / `false`
- Map keys

Everything else comes from the design system or a feature constant.

### Centralize Cross-Cutting Concerns

Anything that ≥2 features need is **not** feature code — it's infrastructure. Put it in the right shared layer:

| Concern | Where it lives |
|---------|----------------|
| Auth | one auth service (singleton) — never direct `FirebaseAuth`/`Auth0`/etc. calls in features |
| API requests | one API client — never imported by feature code directly |
| Persistence | one storage service — never direct Hive/SharedPreferences in features |
| Sync (dirty queue, push, pull) | one sync service — never ad-hoc flush calls in features |
| Connectivity | one connectivity service — one stream, not per-screen listeners |
| Notifications | one notification service — permissions + handlers in one place |
| Purchases | one purchase/entitlement service — RevenueCat/StoreKit wrapper |
| Loading skeletons | one shared skeleton widget — features configure, never reimplement |
| Error display | one shared error-state widget — features pass message + retry callback |
| Empty state display | one shared empty-state widget — features pass illustration + message + action |
| Buttons | one shared button widget family — never inline `ElevatedButton`/`TextButton` styling |
| Theme tokens | one theme directory + one app-constants class |

**A feature screen's `build()` method should mostly compose existing widgets.** If you find yourself writing layout primitives from scratch in a feature folder, the widget probably belongs in `lib/shared/widgets/`.

### Consistent Error Handling

There is **one** way to surface errors in this app:

1. Data layer (API client + repositories) returns result types — never throws unhandled exceptions
2. Repositories translate API errors into a known set of failure modes
3. Providers expose `AsyncValue` so screens can `.when(loading, error, data)`
4. Screens render the error state with a **specific message and a recovery action** — never "Something went wrong"
5. Critical errors get logged via the structured logger
6. Auth errors trigger the session-expiry flow, not generic error UI

Forbidden:
- `try { ... } catch (_) {}` — silent swallow
- Generic strings: "Error", "Failed", "Something went wrong", "Invalid input"
- Blaming the user: "You didn't fill in", "Wrong input"
- Errors that don't tell the user what to try next

### Security by Default

- **Never log** auth tokens (ID, refresh, session), passwords, full user objects, emails, or device IDs
- **Never persist** auth tokens to local storage — the auth provider (Firebase/Auth0/etc.) manages them
- **Never trust** API responses — mappers default every optional field
- **Always check** BOTH the auth provider's current-user state AND a local `isLoggedIn` flag before any API call — checking only one creates race conditions
- **Always await** sync operations before navigation that depends on the result
- **Always clear** user data on sign-out via the documented cleanup chain
- **Never** access the API client from a feature screen or provider — services and repositories only

---

## VERIFICATION — NON-NEGOTIABLE

- After ANY change: verify the full pipeline renders real content in the app
- Never declare "done" without confirming the UI displays actual data — not placeholders, not empty, not "coming soon"
- Run `flutter analyze` before completion — zero errors, zero warnings
- `flutter analyze` passing means it compiles. It does NOT mean it works. Verify function, not just syntax.
- Run existing tests after changes. If tests fail, fix them before declaring done.
- Every screen must handle all four states: loading, empty, error, content. This applies to ALL screens — not just data screens. A settings screen has loading (prefs loading), error (prefs corrupted), empty (first launch), and content.

---

## DATA PIPELINE VERIFICATION

When working with content or data, verify each layer in order:

1. **Source** — Is the data in the DB? Is it published/active? Is the flag set?
2. **API** — Does the endpoint return it? With the correct structure and fields?
3. **Mapper** — Does the mapper handle the actual API shape?
4. **Model** — Do model fields match what the mapper produces?
5. **Provider** — Does the provider expose the data correctly?
6. **Screen** — Does the UI render it correctly?

Skip none. Verify each. A passing compile check at step 6 does not validate steps 1-5.

---

## VERIFY, DON'T GUESS — CROSS-BOUNDARY CONTRACTS

When writing code that crosses a boundary — calling an API, using a shared type, reading an env var, depending on a third-party library signature, hitting a DB column — **read the source of truth before assuming its shape.** Never invent a field name, type, or return value from context.

Decision tree:

1. **Can I read the source of truth?** (API controller, Prisma schema, `.env.example`, library typings, DB migration)
   - Yes → read it. Use the exact field names, types, and shapes found there.
2. **Can't read it?** (private repo, external API, undocumented third-party)
   - Ask the user. Provide a concrete question: "The `/users/:id/subscriptions` endpoint — what does the response shape look like? I need fields and types."
3. **Never guess.** "Probably `userId`" is the same bug as "definitely `userId`" when the real field is `user_id`.

**Examples requiring this discipline:**

- Calling a NestJS endpoint from Flutter → read the controller + DTO in the API repo. If it's in a sibling directory (monorepo or adjacent project), `--add-dir` it or Read it directly. If it's a private service, ask.
- Parsing a JSON payload → read an actual sample response (curl/Postman/logs), not the endpoint's name.
- Reading `process.env.SOMETHING` equivalent → check `.env.example` or the backend's env loader; don't assume a name.
- Using a third-party SDK method → read its type definitions or docs; don't call a method "because it should exist."
- Querying a DB column → check the Prisma schema or migration; don't guess column names from model names.

**When the user asks you to build a frontend feature that calls an API:** the default move is to locate and read the API code first, then write the client. Order: read → plan → code. Not: code → hope → debug.

**Surface every assumption you couldn't verify.** End your response with a short "Assumptions I couldn't verify" list so the user knows what to sanity-check. Silent assumptions are silent bugs.

---

## ARCHITECTURE

### Clean Separation
- `shared/` → `features/` — shared code knows nothing about features. Features never know each other.
- Screens display — they don't compute. Logic belongs in the state layer.
- One file, one concept. One component, one job.

### State Management Principles
- Only rebuild what changed — never the whole tree for one value update
- Computation belongs in the state layer, never in the render path

---

## COMPLETENESS

- Every change is fully complete or explicitly listed as unfinished with specific items remaining. No silent gaps.
- Don't add features, refactor code, or make "improvements" beyond what was asked. A bug fix doesn't need surrounding code cleaned up. A simple feature doesn't need extra configurability.
- Don't create abstractions for one-time operations. Don't design for hypothetical future requirements.
- If a change spans multiple files, all files are updated. A mapper change without a model update is incomplete. A model change without a screen update is incomplete.

---

## THE SURGEON PRINCIPLE

### Diagnose Before Operating
Understand the structure before reading files. Map the territory — directory tree, then targeted search, then surgical read. Never read speculatively.

### Minimum Effective Read
Read what the task demands — not less. If a change spans files, read all affected files. "Minimum" means sufficient, not shallow. Skipping a file you need to read is not efficiency — it's a bug waiting to happen.

### State Your Intent, Then Cut
Before touching code: name the files, explain the change, wait for confirmation.

### No Redundant Exploration
If you've seen a file, you know it. Re-reading is indecision wearing the mask of thoroughness.

### Agents Are Specialists, Not Armies
A sub-agent is a scalpel for a specific incision — not a search party. One focused pass beats five scattered ones.

### The Token Budget Is the Time Budget
Tokens are the user's money. Every file read, every search costs. Work like it's billable — because it is.

---

## DON'TS

- Don't declare a phase "done" based on `flutter analyze` alone
- Don't skip loading/empty/error states — they ARE the product when data isn't ready
- Don't use multiple agents editing the same file simultaneously
- Don't leave "remaining steps" as footnotes — they are blockers, not notes
- Don't add features, refactor code, or make "improvements" beyond what was asked
- Don't assume code works without tracing the full data path from source to screen

---

## AI-ASSISTED DEFINITION OF DONE

AI cannot run the app or see the screen. Visual/runtime verification is the developer's responsibility. AI confirms correctness through:

1. `flutter analyze` passes — zero errors, zero warnings
2. All 4 states handled per screen (loading, empty, error, content)
3. Data path traced from source to screen (each layer verified in code)
4. Existing tests pass (or are updated to match changes)
5. Explicit list of what needs manual/visual verification on device

AI flags what it cannot verify. The developer confirms runtime behavior.
