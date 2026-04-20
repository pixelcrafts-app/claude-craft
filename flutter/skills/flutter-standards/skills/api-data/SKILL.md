---
name: api-data
description: Apply when working with Flutter API clients, repositories, mappers, or data models — one API client, one auth strategy, feature-owned mappers, immutable models, repositories as the only data abstraction UI sees. Auto-invoke when editing lib/core/network, repositories, data_sources, or mappers.
---

# Data Layer Implementation Rules

Concrete patterns for mappers, models, repositories, and API client. Generic rules for any API-driven Flutter app.

---

## Mappers

- Never assume API response shape — check the actual endpoint response first
- Handle both direct fields and nested content sub-objects
- Provide sensible defaults for every optional field (never crash on missing data)
- Accept field aliases (e.g., `sortOrder` and `orderIndex` for the same concept)
- Test mapper output mentally against the model's expected fields

---

## Models

- Immutable — use `copyWith()` to produce new instances, never mutate
- `fromJson()` must handle both cache format and API response format
- `toJson()` must produce a format that `fromJson()` can round-trip
- Every field has a type-safe default — no nullable fields unless genuinely optional
- Use factory constructors for alternative creation paths

---

## API Client

- 401 handling: force-refresh token → retry request once → trigger session expiry on second failure
- Timeouts on all network calls
- Log request method and path for debugging
- Return result types (success/data/error) — never throw unhandled exceptions

---

## Repositories

- Use content mappers to parse API responses — never parse raw JSON in the repository
- Single source of truth: screens ask the repository, repository decides cache vs API
- Only repositories access the API client — screens and providers never touch it directly
