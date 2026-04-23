---
name: production-readiness
description: Apply when auditing a mobile app for production readiness — retry + backoff, app lifecycle, deep links, push notification UX, force-update gate, secure storage, locale / RTL, offline + sync, env-aware logging. Auto-invoke when reviewing app-level wiring, service layer, or release-readiness changes.
---

# Flutter Production Readiness

These are the concerns that decide whether a Flutter app survives contact with real users on real devices. None of them are universally required — each depends on the app's surface area, regulatory scope, and deployment model.

## How to run this audit

Every concern has three phases:

1. **Detect** — grep/read the codebase for signs this is addressed (package, setup call, service, config).
2. **Check** — if present, audit depth: scoped correctly? covers edge cases? no bypass paths?
3. **Suggest** — if absent, propose options with tradeoffs. The user decides. Do not rewrite their app.

Skip concerns that don't apply (a single-locale B2B app doesn't need RTL). Flag concerns where the answer is "not yet" so they aren't silently missed at launch.

---

## R1. Retry + backoff on network calls

- **Detect** — retry logic inside the API client (`dio_smart_retry`, custom interceptor, `retry` package), circuit-breaker patterns, or explicit retry at call sites.
- **Check** —
  - Attempts are bounded at ≤3 — unbounded retries turn a slow endpoint into a self-inflicted DoS.
  - Backoff is exponential with jitter — fixed-delay retries synchronize clients and amplify load spikes.
  - Retry applies only to idempotent operations (GET, PUT by ID) and transient errors (network timeout, 502/503/504).
  - Retry is never applied to 4xx responses — those won't succeed by retrying.
  - User-visible operations expose a visible "retry" affordance; background operations retry silently with a cap.
- **Pass**: retry present, bounded, idempotent-only, exponential-with-jitter. **Fail**: absent, unbounded, or applied to mutations without idempotency keys.
- **Suggest (if absent)** — `dio_smart_retry` or a `Dio InterceptorsWrapper` with exponential backoff + jitter. Warn: retry without idempotency on mutations = duplicate payments / duplicate messages sent.

---

## R2. App lifecycle handling

- **Detect** — `WidgetsBindingObserver`, `AppLifecycleState` listeners, background task scheduling (`workmanager`, iOS `BGTaskScheduler`), sync-on-resume logic.
- **Check** —
  - `paused` state flushes pending mutations (sync queue, analytics) — the OS can kill the app any time after this state.
  - `resumed` state refreshes stale data (content, auth session), not just cached view state.
  - `detached` is handled (iOS-only, fires when app is killed from switcher) — timers stopped, cleanup complete.
  - `inactive` is not used to pause sync — it also fires on system dialogs (Face ID prompt), so pausing here creates observable jank.
- **Pass**: all four states handled with correct semantics. **Fail**: `paused` does not flush mutations, or `inactive` is used as a pause trigger.
- **Suggest (if absent)** — a single `LifecycleObserver` service (attached once from `App`) that broadcasts state changes via stream; features subscribe for their own cleanup/refresh hooks. Warn: without `paused` flushing, mutations in flight get lost when the OS kills the app to reclaim memory.

---

## R3. Deep linking / universal links

- **Detect** — `go_router` deep link config, `uni_links` / `app_links` package, `GoRouter.redirect` for auth-gated deep routes, iOS `Info.plist` `CFBundleURLTypes` + Associated Domains, Android `AndroidManifest.xml` `<intent-filter>` with `autoVerify`.
- **Check** —
  - Cold-start from a deep link resolves correctly (launch → parse link → route), not just warm-start.
  - Auth-gated routes redirect to sign-in first, then deep-link after sign-in success (destination preserved).
  - Malformed or expired links land on a graceful error screen with a recovery action — not a crash or blank route.
  - Universal Links verified server-side (`apple-app-site-association`, `assetlinks.json`) — without this, iOS/Android fall back to the browser.
  - Analytics tracks deep-link source (push, email, web) for attribution.
- **Pass**: cold-start works, auth-gating works, malformed links handled, server manifests present. **Fail**: any of these missing.
- **Suggest (if absent and app supports sharing/notifications/web-to-app)** — `go_router` with `initialLocation` driven by parsed URI, plus platform config checklist. Warn: client-side setup without server-side manifests means links only open in the browser.

---

## R4. Push notification permission UX

- **Detect** — `firebase_messaging`, `flutter_local_notifications`, or native plugin. Locate where `requestPermission` is called relative to app first-launch.
- **Check** —
  - A pre-prompt rationale screen is shown before the OS dialog — explains why notifications matter. One denial on the iOS OS prompt is permanent until the user visits Settings.
  - Permission is not requested on first launch — user sees value first (after 1–2 core interactions or at a contextual moment).
  - Settings screen shows current permission status with a clear re-enable path (deep link to OS Settings on iOS).
  - `criticalAlert` / provisional authorization used only where appropriate — overclaiming critical triggers App Store rejection.
- **Pass**: rationale shown before prompt, prompt deferred past first launch, settings re-enable path present. **Fail**: prompt on cold start, or no rationale.
- **Suggest (if absent or prompting too early)** — a `NotificationPermissionFlow` that: (1) shows a branded rationale dialog, (2) requests OS permission, (3) handles denial with a re-engagement path. Warn: prompting at cold start is the leading cause of low push opt-in rates.

---

## R5. App version / force-update gate

- **Detect** — remote config (`firebase_remote_config`), a `minSupportedVersion` field or equivalent, `package_info_plus` comparison at startup.
- **Check** —
  - Soft-update (optional banner) and hard-update (blocks app use) are distinct states with separate version thresholds.
  - Hard-update screen explains why and provides a direct link to the store listing (App Store URL, Play Store package link).
  - Version comparison handles build numbers correctly (`1.2.3+45` — compare build number 45, not just 1.2.3).
  - Version gate runs before any auth or API call — an outdated client may be unable to reach the refresh endpoint.
- **Pass**: soft and hard states distinct, correct build-number comparison, gate fires before auth. **Fail**: absent, or build number not included in comparison.
- **Suggest (if absent and breaking server changes are planned)** — a `VersionGate` widget that wraps the app root. Warn: without this, a breaking API change orphans all old clients with no recovery path.

---

## R6. Secure storage for sensitive data

- **Detect** — `flutter_secure_storage`, iOS Keychain Services, Android Keystore / EncryptedSharedPreferences. Grep for where tokens, refresh tokens, encryption keys, and biometric secrets are persisted.
- **Check** —
  - Auth tokens, refresh tokens, payment tokens, and biometric secrets stored in `flutter_secure_storage` — never Hive/SharedPreferences plaintext.
  - iOS options: `accessibility: first_unlock_this_device` — data not readable before first unlock but survives reboot.
  - Android options: `encryptedSharedPreferences: true` — non-default; without it, data is plaintext on older Android versions.
  - Hive boxes holding user content are acceptable (content ≠ secret), but session-persistence keys live in secure storage.
- **Pass**: all tokens and secrets in `flutter_secure_storage` with correct platform options. **Fail**: any token or secret in Hive/SharedPreferences.
- **Suggest (if absent and app stores secrets)** — a `SecureStorageService` wrapper with typed keys. Warn: storing refresh tokens in Hive/SharedPreferences is a data-at-rest compliance finding (SOC 2, HIPAA) and a real attack surface on rooted/jailbroken devices.

---

## R7. Locale + RTL support

- **Detect** — `flutter_localizations`, `intl`, `.arb` files, `MaterialApp.localizationsDelegates`, `MaterialApp.supportedLocales`.
- **Check** —
  - No hardcoded user-facing strings in widgets — all via `AppLocalizations.of(context)` or equivalent.
  - Directional icons (`arrow_forward`) use auto-mirroring or are conditional on `Directionality.of(context)`.
  - Date and number formatting via `intl` — never `DateTime.toString()` in user-facing UI.
  - Padding and alignment use logical properties (`EdgeInsetsDirectional.only(start:)` not `.left`) for RTL correctness.
  - RTL languages (ar, he, fa, ur) verified in a test build.
- **Pass**: no hardcoded strings, logical padding throughout, RTL verified. **Fail**: hardcoded strings present, or `.left`/`.right` used in layouts that must support RTL.
- **Suggest (if absent and app ships to >1 locale or RTL markets)** — `flutter_localizations` setup + `.arb` workflow. If single-locale and staying that way, note the tradeoff and move on.

---

## R8. Offline support + sync queue

- **Detect** — local persistence layer (Hive, Isar, Drift), a sync/dirty queue, `connectivity_plus` listener, retry-on-reconnect logic.
- **Check** —
  - Reads serve cached data when offline; empty/stale states are explicit, not misleading to the user.
  - Mutations are queued when offline and flushed when connectivity is restored, with idempotency keys for server-side dedup.
  - Conflict resolution strategy is defined: last-write-wins, server-authoritative, or merge — not implicit.
  - Connectivity state is managed by one service — not each screen listening independently.
- **Pass**: offline reads work, mutations queue and flush, conflict resolution defined, single connectivity service. **Fail**: app shows misleading empty state offline, or mutations are silently dropped.
- **Suggest (if absent and users expect spotty connectivity)** — a sync service pattern with a dirty queue. For a strictly-online app (e.g., in-office admin dashboard), note the tradeoff and skip.

---

## R9. Env-aware logging and observability

- **Detect** — logging service that branches on `kDebugMode`/`kReleaseMode`, remote log sink gated by build mode, crash reporter initialization gated by build mode.
- **Check** —
  - Debug builds: all log levels to console; crash reporter disabled or routed to a debug project; analytics disabled or routed to a debug project.
  - Release builds: only `warn` and above routed to the remote sink; `debug`/`trace`/`info` are not sent to production log infrastructure.
  - `print()` does not appear in feature code — only in `main.dart` init in debug.
  - `kDebugMode`/`kReleaseMode` used to branch — not environment variables read at runtime.
  - Full observability rules: see `mobile-standards:observability`.
- **Pass**: build mode gates are present and correct for all three systems (logging, crash, analytics). **Fail**: `print()` in feature code, debug logs reaching the production sink, or crash reporter active in debug builds.
- **Suggest (if absent)** — a `LoggerService` with a build-mode-aware constructor that sets the minimum level and sink at app start. Warn: shipping debug-level logs to production costs money and buries real signals.

---

## When to run this audit

- Before App Store / Play Store submission (launch or major release).
- When cutting over from internal beta to public.
- When adding a capability that touches any of the above (first deep link, first push, first offline feature).
- As part of the pre-ship quality gate for changes that modify the service layer or app-level wiring.

Not required for small UI, layout, or copy changes.
