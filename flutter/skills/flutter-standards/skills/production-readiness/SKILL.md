---
name: production-readiness
description: Apply when auditing a Flutter app for production readiness — smart Detect → Check → Suggest audit for retry + backoff, app lifecycle, deep links, push notification UX, force-update gate, secure storage, locale / RTL, offline + sync, env-aware logging. Never blindly enforces — detects what's present, audits depth, suggests options with tradeoffs if absent. Auto-invoke when reviewing app-level wiring, service layer, or release-readiness changes.
---

# Flutter Production Readiness

These are the concerns that decide whether a Flutter app survives contact with real users on real devices. None of them are universally required — each depends on the app's surface area, regulatory scope, and deployment model. Every item follows Detect → Check → Suggest.

## How to read this audit

Every concern has three phases:

1. **Detect** — grep/read the codebase for signs this is addressed (package, setup call, service, config).
2. **Check** — if present, audit depth: scoped correctly? covers edge cases? no bypass paths?
3. **Suggest** — if absent, propose options with tradeoffs. The user decides. Do not rewrite their app.

Skip concerns that don't apply (a single-locale B2B app doesn't need RTL). Flag concerns where the user's answer is "not yet" so they aren't silently missed at launch.

---

## R1. Retry + backoff on network calls

- **Detect** — retry logic inside the API client (`dio_smart_retry`, custom interceptor, `retry` package), circuit-breaker patterns, or explicit retry at call sites.
- **Check (if present)** —
  - Bounded attempts (≤3) — unbounded retries turn a slow endpoint into a DoS on yourself.
  - Exponential backoff with jitter — fixed-delay retries synchronise clients and amplify load spikes.
  - Retry only on idempotent operations (GET, PUT by ID) and transient errors (network timeout, 502/503/504). Never on 4xx — those won't succeed by retrying.
  - User-visible operations have a visible "retry" affordance; background operations retry silently with a cap.
- **Suggest (if absent)** — For flaky upstream services, offer `dio_smart_retry` or a Dio `InterceptorsWrapper` with exponential backoff + jitter. Warn: retry without idempotency on mutations = duplicate payments / duplicate messages sent.

---

## R2. App lifecycle handling

- **Detect** — `WidgetsBindingObserver`, `AppLifecycleState` listeners, background task scheduling (`workmanager`, iOS `BGTaskScheduler`), sync-on-resume logic.
- **Check (if present)** —
  - `paused` state flushes pending mutations (sync queue, analytics) — OS can kill the app any time after.
  - `resumed` state refreshes stale data (content, auth session), not just cached view state.
  - `detached` is handled (iOS-only, fires when app killed from switcher) — clean up / stop timers.
  - `inactive` is not used to pause sync — it also fires on system dialogs (Face ID prompt), so pausing here creates jank.
- **Suggest (if absent)** — Offer a single `LifecycleObserver` service (attached once from `App`) that broadcasts state changes via stream. Features subscribe for their own cleanup/refresh hooks. Warn: without `paused` flushing, mutations in flight get lost when the OS kills the app to reclaim memory.

---

## R3. Deep linking / universal links

- **Detect** — `go_router` deep link config, `uni_links` / `app_links` package, `GoRouter.redirect` for auth-gated deep routes, iOS `Info.plist` `CFBundleURLTypes` + Associated Domains, Android `AndroidManifest.xml` `<intent-filter>` with `autoVerify`.
- **Check (if present)** —
  - Cold start from deep link resolves correctly (app launch → parse link → route), not just warm-start.
  - Auth-gated routes redirect to sign-in first, then deep-link after sign-in success (preserved in query param or state).
  - Malformed / expired links land on a graceful error screen with a recovery action — not a crash or blank route.
  - Universal Links verified server-side (`apple-app-site-association`, `assetlinks.json`) — otherwise iOS/Android ignore them and fall back to browser.
  - Analytics tracks deep-link source (push, email, web) for attribution.
- **Suggest (if absent) AND the app supports sharing / notifications / web-to-app** — offer `go_router` with `initialLocation` driven by parsed URI, plus platform config checklist. Warn: setting up client-side without server-side manifests = links only open in the browser.

---

## R4. Push notification permission UX

- **Detect** — `firebase_messaging`, `flutter_local_notifications`, or native plugin. Look for where `requestPermission` is called.
- **Check (if present)** —
  - **Pre-prompt rationale** shown before the OS dialog — explains *why* notifications matter (delivery reminders, chat, lesson streaks). One denial on the OS prompt is permanent on iOS until the user goes to Settings.
  - Prompt not fired on first launch — let the user see value first (after 1–2 core interactions or at a contextual moment).
  - Settings screen shows current permission status with a clear re-enable path (deep link to OS settings on iOS).
  - `criticalAlert` / provisional authorization used appropriately — overclaiming critical gets the app rejected.
- **Suggest (if absent or prompting too early)** — offer a `NotificationPermissionFlow` helper that: (1) shows a branded rationale dialog, (2) requests OS permission, (3) handles denial with a re-engagement path. Warn: prompting at cold start is the #1 reason apps have low push opt-in.

---

## R5. App version / force-update gate

- **Detect** — remote config (`firebase_remote_config`), a `minSupportedVersion` field or equivalent, `package_info_plus` comparison at startup.
- **Check (if present)** —
  - Soft-update (optional) and hard-update (blocks app use) are distinct states.
  - Hard-update screen explains *why* and provides a direct link to the store listing (`https://apps.apple.com/app/id...`, Play Store package link).
  - Version comparison handles build numbers correctly (`1.2.3+45` — compare 45, not just 1.2.3).
  - Fetched before any auth / API call — outdated client may be unable to even reach the refresh endpoint.
- **Suggest (if absent) AND app has breaking server changes planned** — offer a `VersionGate` widget that wraps the app root. Warn: without this, a breaking API change orphans all old clients forever.

---

## R6. Secure storage for sensitive data

- **Detect** — `flutter_secure_storage`, iOS Keychain Services, Android Keystore / EncryptedSharedPreferences. Grep for where tokens, refresh tokens, encryption keys, biometric secrets are persisted.
- **Check (if present)** —
  - Auth tokens, refresh tokens, payment tokens, biometric secrets in `flutter_secure_storage` — never Hive/SharedPreferences plaintext.
  - Hive boxes holding user content are fine (content ≠ secret), but session-persistence keys (if any) live in secure storage.
  - iOS options: `accessibility: first_unlock_this_device` — so data not readable before first unlock but survives reboot.
  - Android options: `encryptedSharedPreferences: true` — non-default; without it it's plaintext on older Android.
- **Suggest (if absent) AND the app stores secrets** — offer a `SecureStorageService` wrapper with typed keys. Warn: storing refresh tokens in Hive/SharedPreferences is a data-at-rest compliance finding (SOC2, HIPAA) and a real attack surface on rooted / jailbroken devices.

---

## R7. Locale + RTL support

- **Detect** — `flutter_localizations`, `intl`, `.arb` files, `MaterialApp.localizationsDelegates`, `MaterialApp.supportedLocales`.
- **Check (if present)** —
  - No hardcoded user-facing strings in widgets — all via `AppLocalizations.of(context)` or equivalent.
  - `Directionality` respected — icons that have direction (`arrow_forward`) use `Icons.arrow_forward_outlined` + auto-mirroring, or conditional on `Directionality.of(context)`.
  - Date / number formatting via `intl` — never `DateTime.toString()` in user UI.
  - RTL languages (ar, he, fa, ur) tested — padding/alignment using logical properties (`EdgeInsetsDirectional.only(start:)` not `.left`).
- **Suggest (if absent) AND the app ships to >1 locale or RTL markets** — offer the `flutter_localizations` setup + `.arb` workflow. If single-locale and staying that way, note the tradeoff and move on. Do not force i18n onto a product that's explicitly single-market.

---

## R8. Offline support + sync queue

- **Detect** — local persistence layer (Hive, Isar, Drift), a sync/dirty queue, `connectivity_plus` listener, retry-on-reconnect logic.
- **Check (if present)** —
  - Reads work offline from cached data; empty/stale states are explicit, not misleading.
  - Mutations queued when offline, flushed when connectivity restored — with dedup on the server via idempotency keys (see api-standards J2).
  - Conflict resolution defined: last-write-wins, server-authoritative, or merge — not implicit.
  - Connectivity stream is ONE service — not each screen listening independently (see `engineering.md` Centralize Cross-Cutting Concerns).
- **Suggest (if absent) AND the app has meaningful write actions AND users expect spotty connectivity (mobile-first, field use)** — offer a sync service pattern. For a strictly-online app (e.g., an in-office admin dashboard), note the tradeoff and skip. Don't retrofit offline onto a product that doesn't need it.

---

## R9. Env-aware logging and observability

- **Detect** — logger config that varies by `kDebugMode` / `kReleaseMode` / `kProfileMode`, Flutter Flavors, remote sink wiring (Crashlytics, Sentry) gated by build mode.
- **Check (if present)** — (see `observability.md` Debug vs Release Behavior for the canonical list)
  - Debug: all log levels to console; crash reporter disabled or routed to a dev project; analytics disabled or dev project.
  - Release: `warn` and above to remote sink; crash reporter on; analytics on with consent.
  - `assert()` relied on only for dev invariants (stripped in release).
  - Log messages use structured context maps, not interpolated strings with user data.
  - PII/secrets redacted at logger level, not at each call site.
- **Suggest (if absent)** — centralise in a single `LoggerService` that reads `kDebugMode` / `kReleaseMode` at construction. Warn: a logger that ships `debug` logs to production is a privacy incident waiting to happen, and a cost problem once at scale.

---

## When to run this audit

- Before app store submission (launch or major release).
- When cutting over from internal beta to public.
- When adding a capability that touches any of the above (first deep link, first push, first offline feature).
- As part of the `pre-ship` quality gate, for changes that modify service layer or app-level wiring.

Not required for small UI / layout / copy changes.
