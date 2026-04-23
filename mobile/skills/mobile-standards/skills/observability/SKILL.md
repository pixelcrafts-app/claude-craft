---
name: observability
description: Apply when adding logging, analytics, or crash reporting to a mobile app. Auto-invoke when writing observability, logging, or analytics code.
---

# Observability Rules

Universal engineering rules — see `core-standards:rules` §1–§4. This skill covers Flutter/mobile-specific patterns only.

---

## Logging

### One Logger

- One logger instance, one class that wraps it, one import path — never `print()` in feature code
- `print()` is for `main.dart` init only, and only in debug builds
- The logger routes to: console (debug builds), structured remote sink (release builds, `warn` and above only)

### Log Levels

| Level | When to use |
|-------|-------------|
| `trace` / `verbose` | Developer-detail flow (function entry/exit, tight loops) |
| `debug` | State changes and decisions useful during development |
| `info` | Significant app events (user signed in, purchase complete) |
| `warn` | Unexpected but recoverable (retry triggered, fallback used, config missing) |
| `error` | Failures that degraded the user experience (API call failed and shown to user) |
| `fatal` | Crashes, data corruption, irrecoverable state |

**Thresholds by build mode:**

| Build mode | Minimum level sent to console | Minimum level sent to remote sink |
|------------|-------------------------------|-----------------------------------|
| Debug | `trace` | nothing (disabled) |
| Profile | `debug` | nothing (disabled) |
| Release | nothing | `warn` |

`debug`, `info`, and `trace` are never sent to the production log infrastructure. Excess logging costs money and buries real signals.

### Log Structure

Every log entry must have:
- **Level** — from the table above
- **Event name** — short, stable, searchable, dot-separated: `<domain>.<object>.<action>` (e.g., `auth.session.expired`, `cart.item.added`)
- **Context map** — structured key-value pairs, not free-form strings
- **Timestamp** — auto-attached by the logger
- **Build info** — version, platform — auto-attached

### Log Rules

- **Never use string concatenation** in log messages — use structured context map fields instead
- Keep event names in a constants file — prevents typos and enables search
- **Never log in tight loops** — a `logger.debug` inside a 60fps build method is a performance bug, not just noise

---

## Crash Reporting

### Hook into Flutter Errors

Both hooks are required:

- `FlutterError.onError` — catches framework errors; still forward to `FlutterError.presentError` in debug so console output is preserved
- `PlatformDispatcher.instance.onError` — catches uncaught async errors; return `true` to mark them as handled

### What to Report

- **Unhandled exceptions** — every one, automatically via the hooks above
- **Caught-but-unexpected exceptions** — record as non-fatal when the app swallowed something it should not have
- **Assertion failures** — in release builds, treat as non-fatal crash reports
- **Manual breadcrumbs** — screen navigations, significant state transitions, API calls (without payloads)

### Attach Context, Not PII

Allowed in crash reports:
- Internal user ID (UUID) — not email or phone
- Screen name
- Last user action (button tapped, route navigated)
- Network state (connected/disconnected)
- Feature flags active
- App version, OS version
- Device ID (not advertising ID/IDFA) — for session correlation only, never as a tracking identifier

Never in crash reports:
- Auth tokens, passwords, API keys
- User-generated content (messages, photos, notes)
- GPS coordinates or precise location
- Email, phone number, name, or any direct identifier

### Crash Triage

- Every release: review new crashes within 24 hours
- >1% of sessions affected: patch priority (hotfix)
- >0.1% but ≤1% of sessions affected: next release
- Every crash tagged to a ticket with an owner — never left "acknowledged" without one
- Target: 99.9% crash-free sessions — track the trend, not just the absolute

---

## Analytics

### Event Naming Convention

Pattern: `<domain>.<object>.<action>[.<qualifier>]`

Requirements:
- Lowercase, dot-separated, stable — never use user-visible strings as event names
- `<domain>`: product area (e.g., `auth`, `cart`, `onboarding`, `settings`)
- `<object>`: the noun being acted on (e.g., `session`, `item`, `step`, `plan`)
- `<action>`: past-tense verb (e.g., `started`, `completed`, `failed`, `changed`)
- All event names live in a single constants file — prevents duplicates and variant spellings
- Never exceed 500 distinct event names — beyond that is noise, not signal
- Never rename an event — it breaks historical continuity. Deprecate the old name, add a new one.

### Event Properties

- < 10 properties per event — analytics platforms limit and truncate above this
- Types: strings, numbers, booleans only — no nested objects
- Values: enumerated where possible, not free-form strings
- Never attach PII as event properties — follow the PII classification table below

### User Properties vs Event Properties

- **User properties**: attached to the user, persist across events (`plan: 'pro'`, `cohort: '2026-03'`, `locale: 'en-US'`)
- **Event properties**: attached to this specific event instance (`source: 'home_banner'`, `position: 3`)
- Do not duplicate — if `plan` is a user property, do not re-attach it to every event

### What Not to Track

- Scroll events (noise)
- Every tap (noise)
- Screen re-renders (noise)
- Any event that cannot answer a specific question the team has agreed to ask

If you cannot complete the sentence "we need this event because we want to answer: ___", do not add it.

---

## Privacy & Compliance

### PII Classification

| Category | Examples | Logging | Crash reports | Analytics |
|----------|----------|---------|---------------|-----------|
| **Direct identifiers** | email, phone, full name, address | never | never | never |
| **Indirect identifiers — safe** | internal user UUID | only if required for correlation | yes, for session correlation | yes, for user-level analysis |
| **Indirect identifiers — restricted** | advertising ID (IDFA/GAID), precise GPS | never | never | never |
| **Device ID** (non-advertising) | `flutter_device_id` equivalent | only if required | yes, for crash correlation only | never |
| **User-generated content** | messages, photos, notes, search terms | never | never | never |
| **Behavioral** | screen visited, button tapped, flow completed | yes | as breadcrumbs only | primary use case |
| **Technical** | OS version, app version, network type, device model | yes | yes | yes |

### Consent & Opt-Out

- Analytics requires **opt-in consent on first launch** in GDPR regions (EU, UK, and any jurisdiction where consent is required)
- Crash reporting can be opt-out (legitimate interest basis) but must be disclosed in the privacy policy
- An in-app toggle to disable analytics is required — respect it immediately (stop sending, flush buffer, do not collect until re-enabled)
- Track the consent state itself as a user property, anonymized (e.g., `analytics_consent: true/false`)

### Data Retention

- Logs: 30 days, then deleted
- Crash reports: 90 days
- Analytics: follow platform default unless a stricter regional requirement applies

### Regional Compliance

- Route EU traffic to EU data regions — Firebase, Sentry, and Amplitude all support regional routing
- Honor data subject requests (DSRs): delete on request, export on request
- App Store privacy nutrition labels must reflect all data collected — keep them in sync when adding new events or properties

---

## Debug vs Release Behavior

| Behavior | Debug build | Release build |
|----------|-------------|---------------|
| Log levels to console | all (`trace` and above) | none |
| Log levels to remote sink | none (disabled) | `warn` and above |
| Crash reporter | disabled or dev project | production project, active |
| Analytics | disabled or dev project | production project, with user consent |
| `assert()` | active — crash-fast on violations | stripped by compiler |

Use `kDebugMode` / `kReleaseMode` to branch — do not read environment variables at runtime to determine build mode.

---

## Correlation

### Trace IDs

- Every outbound API request gets a client-generated trace ID (UUID v4)
- Attach to: the request header (`X-Trace-Id`), any log entry about that request, any crash report if that request caused a crash
- Server logs the same ID — enables full request lifecycle tracing across client and server

### Session IDs

- One session ID per app launch (generate at startup, discard on terminate)
- Attach to: all analytics events, all log entries, all crash reports for that session
- Enables "what was the user doing right before the crash?" queries

---

## DON'TS

- Don't `print()` in feature code
- Don't log PII or secrets — see classification table above
- Don't add `logger.debug` in 60fps paths
- Don't rename analytics events — deprecate and add new
- Don't exceed 500 distinct event names
- Don't ship analytics without a consent flow in GDPR regions
- Don't route crashes to a project without an owner
- Don't log full API request or response bodies — structured context only
- Don't use free-form strings as analytics property values — enumerate them
- Don't send debug or info logs to the production remote sink
