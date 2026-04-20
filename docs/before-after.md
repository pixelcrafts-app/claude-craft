# Before / After

> Template. Fill in real examples per pack. The point of this file is to show — in under 30 seconds of scanning — what the packs change about Claude's output. The README links here.

## How to write an entry

Each entry is a single concrete task the user asked Claude for. Two code blocks side by side (or stacked on mobile). Same prompt, same file context, one without the pack, one with.

- **Left / top = without** the pack — what Claude outputs by default.
- **Right / bottom = with** the pack — what Claude outputs when the standards auto-invoke.
- Keep snippets ≤ 25 lines each. No blog-post commentary. Let the diff speak.
- Call out the 2–3 concrete things the pack changed beneath the snippet.

---

## Flutter — build a bookmark card

**Prompt:** *"Add a card widget showing a bookmark's title, description, and a save button."*

<!-- TODO: fill in real example. Rough shape below. -->

### Without `flutter-standards`

```dart
// paste the typical AI output here — hardcoded colors, EdgeInsets.all(16),
// inline TextStyle, no 4-state handling on the button's loading
```

### With `flutter-standards`

```dart
// paste the pack-guided output here — AppColors, AppSpacing, AppTypography,
// const constructors, loading state wired, Semantics on the button
```

**What the pack fixed:**
- Hardcoded hex → `AppColors.primary`
- Magic `16` padding → `AppSpacing.md`
- Inline text style → `AppTypography.bodyMedium.semiBold`
- Save button has loading + disabled states

---

## API — add a NestJS endpoint

**Prompt:** *"Add a GET /bookmarks/:id endpoint."*

<!-- TODO: fill in real example. -->

### Without `api-standards`

```ts
// typical output — controller does the DB query inline, no DTO,
// no auth guard, no Swagger decorator, no error shape
```

### With `api-standards`

```ts
// pack-guided — controller delegates to service, service calls
// repository, response DTO with @ApiProperty, @UseGuards(AuthGuard),
// NotFoundException on miss, typed throughout
```

**What the pack fixed:**
- Controller no longer queries the DB directly
- Auth guard applied
- Response DTO with Swagger decorators
- `NotFoundException` instead of returning `null`

---

## Web — add a bookmark list route

**Prompt:** *"Add a /bookmarks page that lists the user's bookmarks."*

<!-- TODO: fill in real example. -->

### Without `web-standards`

```tsx
// typical output — 'use client' at the top unnecessarily, fetch in
// useEffect, no loading/error/empty states, inline hex colors
```

### With `web-standards`

```tsx
// pack-guided — Server Component by default, client boundary pushed
// to just the save toggle, React Query hook with structured key,
// all 4 states handled, Tailwind tokens with semantic colors
```

**What the pack fixed:**
- Kept as Server Component — client boundary scoped to the toggle
- React Query with `['bookmarks', 'list', { userId }]` key
- Loading skeleton, empty state with CTA, error with retry
- `bg-background` + `text-foreground` instead of `bg-white` + `text-black`

---

## Production readiness — API rate-limit detection

**Prompt:** *"Ship this API to production — is it ready?"*

<!-- TODO: fill in real example. -->

### Without `api-standards`

```
Claude reviews the code and says it looks good. Merges, deploys, gets
paged two days later when a bot scrapes /users/search 400 times a second
and pegs the DB.
```

### With `api-standards`

```
Docs-sync + production-readiness fire together. Claude's report:

Detect → Check → Suggest — Rate limiting (J1)
  Status: NOT DETECTED
  Risk: /users/search is unauthenticated and DB-backed. Brute force
        or scraper abuse will pin a DB connection per request.
  Options:
    (a) @nestjs/throttler — per-route decorators, in-process
    (b) Redis-backed limiter — shared across instances
    (c) Handle upstream at the gateway (Cloudflare / Fly)
  Recommendation: (a) for single-instance, (b) for HA. Do not add
  without your approval.
```

**What the pack fixed:**
- Caught the gap before deploy
- Explained *why* it matters for this specific endpoint
- Proposed options — did not silently install `throttler` and rewrite controllers

---

## How to pull real examples

1. Run Claude without the pack enabled on a real task — save the output.
2. Enable the pack, reset context, re-run the same prompt — save the second output.
3. Pick the 3–5 most striking diffs. Paste in the templates above.
4. Keep examples realistic, not cherry-picked. If the pack didn't change something, don't fake it.

Real examples beat theoretical ones. Vibe coders trust what they can read — hypothetical "imagine if" snippets read as marketing.
