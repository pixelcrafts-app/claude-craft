---
name: observability
description: Apply when adding logging, crash reporting, analytics, or handling user data in Flutter — one logger, structured events, no PII in logs/crashes/analytics, consent flows, retention policies, correlation via trace + session IDs. Auto-invoke on any observability or telemetry change.
---

# Observability Rules

You can't fix what you can't see. Apps in production are black boxes unless you instrument them — and instrumentation done badly is worse than none (noise that hides real signal, PII leaks that create compliance incidents).

Concrete patterns for logging, crash reporting, analytics, and privacy. Implements `engineering.md`'s "Security by Default" — does not restate it.

---

## The Three Pillars

| Pillar | Question it answers | Tools |
|--------|---------------------|-------|
| **Logging** | What is the app doing right now? | `logger` package, console, remote log sinks |
| **Crash reporting** | What went wrong (and how often)? | Firebase Crashlytics, Sentry, Bugsnag |
| **Analytics** | What are users doing? | Firebase Analytics, Amplitude, Mixpanel |

Don't conflate them. Logs are for developers debugging. Crashes are for engineering urgency. Analytics is for product decisions. Mixing audiences produces noise.

---

## Logging

### One Logger

- One logger instance, one class that wraps it, one import path — never `print()` in feature code
- `print()` is for `main.dart` init only, and only in debug
- The logger routes to: console (debug builds), structured remote sink (release builds, for critical logs only)

### Log Levels

| Level | When | Example |
|-------|------|---------|
| `trace` / `verbose` | Developer-detail flow | "Provider rebuilt with 12 items" |
| `debug` | Useful during development | "Cache hit for key profile_123" |
| `info` | Significant app events | "User signed in", "Sync started" |
| `warn` | Unexpected but recoverable | "API returned 429, retrying" |
| `error` | Failures that degraded the experience | "Failed to load profile, showing cached" |
| `fatal` | Crashes, corruption, data loss | "Sync queue corrupted, reset required" |

**Release build threshold: `warn` and above.** Debug/trace logs are devtime only — never ship to production log sinks. Excess logging costs money and buries real signals.

### Log Structure

Every log entry has:
- **Level** — see above
- **Event name** — short, stable, searchable: `auth.signin.success`, `sync.flush.complete`
- **Context map** — structured key-value pairs, no free-form strings
- **Timestamp** — auto-attached by the logger
- **Build info** — version, platform, auto-attached

```dart
// Bad
logger.info("user signed in with email $email at $timestamp");

// Good
logger.info('auth.signin.success', {
  'provider': 'email',
  'is_new_user': false,
  // NO email, NO userId, NO tokens
});
```

### Log Rules

- **Never log PII** — emails, names, phone numbers, addresses, DOB, device IDs, IP addresses
- **Never log secrets** — tokens (ID, refresh, session), passwords, API keys
- **Never log full user objects** — always hand-pick non-identifying fields
- **Never log full API responses** — structure only, not content
- **Never log in tight loops** — a `logger.debug` inside a 60fps build method is a perf bug
- **Never use string concatenation** in log messages — use structured context instead
- Keep event names in a constants file — prevents typos and enables search

---

## Crash Reporting

### Hook into Flutter Errors

```dart
FlutterError.onError = (details) {
  CrashReporter.recordFlutterError(details);
  FlutterError.presentError(details); // still print to console in debug
};

PlatformDispatcher.instance.onError = (error, stack) {
  CrashReporter.recordError(error, stack, fatal: true);
  return true;
};
```

Both hooks are required — `FlutterError.onError` catches framework errors, `PlatformDispatcher.instance.onError` catches uncaught async errors.

### What to Report

- **Unhandled exceptions** — every one
- **Caught-but-unexpected exceptions** — log with `recordError(e, stack, fatal: false)` when your app swallowed something it shouldn't have
- **Assertion failures** — in release builds, treat as non-fatal crash reports
- **Manual breadcrumbs** — screen navigations, significant state transitions, API calls (without payloads)

### Attach Context, Not PII

- User identifier: use an **internal user ID** (UUID), never email or phone
- Attach: screen name, last action, network state, feature flags active, app version
- **Never** attach: auth tokens, passwords, user content, device location

### Crash Triage

- Every release: review new crashes within 24 hours
- Crashes affecting >1% of sessions: patch priority
- Crashes affecting >0.1% but <1%: next release
- Tag crashes to tickets — never leave a crash "acknowledged" without an owner
- Zero-crash target is unrealistic; set a budget: 99.9% crash-free sessions, track trend

---

## Analytics

### Event Naming Convention

Stable, lowercase, dot-separated, noun-first:

```
<domain>.<object>.<action>[.<qualifier>]
```

Examples:
- `auth.signin.success`
- `auth.signin.failure`
- `lesson.start`
- `lesson.complete`
- `purchase.paywall.view`
- `purchase.paywall.dismiss`
- `purchase.checkout.start`
- `purchase.checkout.complete`

**Rules:**
- Never rename events — break history. Deprecate, then add a new one.
- Never use user-visible strings ("Start Lesson" → no; `lesson.start` → yes)
- Keep the list in a single constants file — prevents duplicates (`lesson_started` vs `lessonStart` vs `lesson.start`)
- Never exceed 500 distinct event names — more than that is noise

### Event Properties

- Keep < 10 properties per event — analytics platforms limit and truncate
- Types: strings, numbers, booleans only — no nested objects
- Values: enumerated where possible (`source: 'home' | 'deep_link' | 'notification'`), not free-form
- **Never** attach PII as event properties — follow the logging rules

### User Properties (vs Event Properties)

- User properties: attached to the user, persist across events (`plan: 'pro'`, `cohort: '2026-03'`)
- Event properties: attached to this specific event (`source: 'home'`)
- Don't duplicate — if `plan` is a user property, don't attach it to every event

### What NOT to Track

- Scroll events (noise)
- Every tap (noise)
- Screen re-renders (noise)
- Anything that can't answer a specific question the team agreed to ask

If you can't say "we need this event because we want to answer X," don't add it.

---

## Privacy & Compliance

### PII Classification

| Category | Examples | Logging | Crash reports | Analytics |
|----------|----------|---------|---------------|-----------|
| **Direct identifiers** | email, phone, name, address | ❌ never | ❌ never | ❌ never |
| **Indirect identifiers** | user UUID, device ID | ⚠️ only if needed | ✅ for correlation | ✅ for user analysis |
| **Content** | user-generated text, photos | ❌ never | ❌ never | ❌ never |
| **Behavioral** | screen visited, button tapped | ✅ yes | ✅ as breadcrumbs | ✅ primary use case |
| **Technical** | OS version, app version, network type | ✅ yes | ✅ yes | ✅ yes |

### Consent & Opt-Out

- Analytics requires **opt-in on first launch** in GDPR regions (EU, UK)
- Crash reporting can be opt-out (legitimate interest) but must be disclosed
- Provide an in-app toggle to disable analytics — respect it
- On disable: stop sending, flush existing buffer, don't collect until re-enabled
- Track the consent state itself as a user property (anonymized)

### Data Retention

- Logs: 30 days, then deleted
- Crashes: 90 days (helps debug rare issues)
- Analytics: follow the platform default unless stricter per region

### Regional Compliance

- Route EU traffic to EU data regions (Firebase, Sentry, Amplitude all support this)
- Respect DSRs (data subject requests): delete on request, export on request
- App Store requires privacy nutrition labels declaring all data collected — keep them in sync

---

## Debug vs Release Behavior

### Debug builds

- All log levels to console
- Crash reporter disabled (or routed to a debug project)
- Analytics disabled or routed to a debug project
- `assert()` active — crash-fast on invariant violations

### Release builds

- Logs: `warn` and above, routed to remote sink
- Crash reporter: full, routed to production project
- Analytics: full, with user consent
- `assert()` stripped by the compiler

Use `kDebugMode` / `kReleaseMode` to branch — don't read environment variables at runtime for build mode.

---

## Correlation

### Trace IDs

- Every API request gets a client-generated trace ID (UUID)
- Attach it to: the request header (`X-Trace-Id`), any log entry about the request, any crash report if that request crashed
- Server logs same ID → full request lifecycle traceable

### Session IDs

- One session ID per app launch
- Attached to analytics events, logs, crash reports
- Enables "what was the user doing right before the crash?" queries

---

## Monitoring & Alerting

- **Crash rate > threshold** → page oncall
- **P50 API latency > target** → Slack alert
- **New crash type in last release** → notify release owner
- **Analytics event delivery dropping** → integration health alert

Set alerts based on user impact, not absolute numbers. "100 crashes" means nothing if you have 10M users; means everything if you have 100.

---

## Dashboards

Every team ships a dashboard with, at minimum:
- Crash-free sessions rate (last 24h, 7d)
- Session count
- Cold start P50 and P95
- Top 5 screens by time
- Top 5 crashes by impact
- Primary funnel (signup → activation → first value)

Dashboards are for the team, not for show. If nobody looks at it, delete it.

---

## DON'TS

- Don't `print()` in feature code
- Don't log PII or secrets
- Don't add `logger.debug` in 60fps paths
- Don't rename analytics events — deprecate and add new
- Don't exceed 500 distinct event names
- Don't ship analytics without a consent flow in GDPR regions
- Don't route crashes to a project without an owner
- Don't ignore crashes because "they're rare" — rare crashes affect real users
- Don't add metrics you won't look at
- Don't log full API requests/responses — structure only
- Don't use free-form strings in analytics properties — enumerate
