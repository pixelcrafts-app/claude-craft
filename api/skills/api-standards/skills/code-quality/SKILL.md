---
name: code-quality
description: Apply when auditing NestJS endpoints for security, correctness, and production readiness — every route guarded or explicitly @Public, DTO validated, no any leaks, no console.log in feature code, tests for happy and auth/validation failure paths, caching keys scoped by tenant. Smart-audits production concerns (rate limiting, idempotency, retries, webhook verification, graceful shutdown, health endpoints, correlation IDs, soft delete, audit logs, DB pool) via Detect → Check → Suggest — never blindly enforces. Auto-invoke when adding or modifying endpoints.
---

# API Code Quality Audit

> Every item is a pass/fail check. Run before major releases or as the basis for a pre-ship skill.

## How to read this audit

Checks fall into two modes:

- **Binary requirements (A–I)** — pass or fail. No interpretation. Example: "All protected endpoints have auth guards" is either true or it isn't.
- **Detect → Check → Suggest (J, V)** — contextual. The audit first looks for whether a concern is already addressed; if yes, it checks *how well*; if no, it suggests with tradeoffs, *never enforces*.

For Detect→Check→Suggest items, the flow is always:

1. **Detect** — grep/read the codebase for signs this is addressed (library, decorator, middleware, table, header).
2. **Check** — if present, audit depth: scoped correctly? covers the right cases? no bypass paths?
3. **Suggest** — if absent, propose options with tradeoffs. The user decides. Do not rewrite their app.

The reason: real codebases have real reasons for absent patterns (cost, scale stage, already handled upstream at the gateway/CDN/WAF). A rigid "must have X" rule from an AI creates noise. A smart audit catches genuine gaps.

---

## A. Architecture & Single Source of Truth

- [ ] A1. Controllers handle HTTP only — no business logic, no DB queries
- [ ] A2. Services contain all business logic — not scattered in controllers/guards
- [ ] A3. Zero hardcoded values — all config from env vars, constants, or DB
- [ ] A4. No duplicate logic across modules — same check in 2+ places = extract to shared
- [ ] A5. Feature flags / plan enforcement / role checks live in ONE place (interceptor or guard) — zero inline duplicates
- [ ] A6. Feature names and domain constants use typed enums / `as const` — no raw string literals scattered in code
- [ ] A7. Modules don't import from each other's internals — only exported services

## B. Type Safety

- [ ] B1. Zero `as any` casts
- [ ] B2. Zero `as unknown as` double casts
- [ ] B3. DB client results properly typed — no `(result as any).field`
- [ ] B4. All DTOs have `@ApiProperty()` for Swagger
- [ ] B5. Request/response types match between controller and service

## C. Error Handling

- [ ] C1. Controllers use NestJS exceptions (NotFoundException, BadRequestException)
- [ ] C2. Services throw typed errors — never raw `throw new Error()`
- [ ] C3. Global exception filter catches unhandled errors
- [ ] C4. Error responses follow consistent shape: `{ statusCode, message, error }`
- [ ] C5. No silent `catch {}` blocks — always log or propagate

## D. Database

- [ ] D1. Only repositories/services query the DB — never controllers
- [ ] D2. All queries use indexed columns — no sequential scans
- [ ] D3. Transactions for multi-step mutations
- [ ] D4. No N+1 queries — batch lookups with `IN` clauses
- [ ] D5. Pagination clamped: `Math.min(Math.max(limit, 1), 100)`

## E. Security

- [ ] E1. All protected endpoints have auth guards
- [ ] E2. API keys server-side only — never in responses
- [ ] E3. JWT_SECRET / signing keys in env — never hardcoded
- [ ] E4. Input validation via class-validator on all DTOs
- [ ] E5. No raw SQL injection risk — parameterized queries only

## F. Dead Code & Hygiene

- [ ] F1. Zero unused imports
- [ ] F2. Zero unused services/providers registered in modules
- [ ] F3. Zero `console.log` — use NestJS Logger
- [ ] F4. Zero commented-out code
- [ ] F5. Zero `// TODO` without linked issue
- [ ] F6. Lint passes with zero errors and zero warnings

## G. Performance

- [ ] G1. `AbortSignal.timeout()` on all external fetch calls
- [ ] G2. Cache with TTL on frequently accessed data
- [ ] G3. No unbounded queries — always `take` limit
- [ ] G4. `Promise.allSettled` for parallel independent calls
- [ ] G5. Intervals cleared in `onModuleDestroy`

## H. API Design

- [ ] H1. All endpoints have Swagger decorators: `@ApiOperation`, `@ApiResponse`
- [ ] H2. Consistent response wrapper across all endpoints
- [ ] H3. Versioned routes: `/api/v1/`
- [ ] H4. Proper HTTP status codes (201 for create, 204 for delete)
- [ ] H5. Query params validated via DTOs with class-validator

## I. Consistency

- [ ] I1. File naming: kebab-case
- [ ] I2. Class naming: PascalCase
- [ ] I3. One service per domain concern
- [ ] I4. Same error handling pattern in every service
- [ ] I5. Constants in UPPER_SNAKE_CASE

---

## J. Production Operational Concerns — Detect → Check → Suggest

These are the concerns that decide whether an API survives contact with production traffic. None of them are universally required — each depends on traffic, stakes, and whether something upstream already handles it. Follow the Detect → Check → Suggest flow for every item.

### J1. Rate limiting / throttling

- **Detect** — search for `@Throttle`, `@nestjs/throttler`, `express-rate-limit`, a Redis-backed limiter, or upstream handling (Cloudflare, API gateway, WAF). Ask the user if limits live outside the repo.
- **Check (if present)** — Is it per-route or global? Are auth endpoints (login, password reset) stricter than read endpoints? Are webhook receivers excluded (they come from trusted senders at bursty rates)? Is the key tenant-aware (per user/org, not per IP for authenticated routes)?
- **Suggest (if absent)** — Flag the risk (brute-force on auth, scraper abuse, cost runaway on expensive endpoints). Offer: `@nestjs/throttler` for simple cases, Redis-backed for multi-instance, or upstream at the gateway if infra supports it. Let the user choose. Do not add a throttler middleware without approval.

### J2. Idempotency keys on mutations

- **Detect** — search for `idempotency-key` header handling, an `idempotency_keys` table, or middleware checking replay.
- **Check (if present)** — Is the key stored with a TTL long enough to cover retry windows (24h common)? Does a replay return the *original* response, not re-execute the mutation? Is the scope (endpoint + user) part of the key?
- **Suggest (if absent)** — Ask which mutations are critical (payments, account creation, sending money/messages). For those, explain why idempotency matters (network retries, client double-submit) and offer a middleware pattern. Don't retrofit on every endpoint.

### J3. Retry + backoff on upstream calls

- **Detect** — search for `axios-retry`, `p-retry`, `retry`, custom backoff logic, or circuit breakers (`opossum`).
- **Check (if present)** — Bounded attempts (≤3–5)? Exponential backoff with jitter (not fixed delay that synchronises retries)? Retries only on idempotent operations (GET, PUT by ID) and transient errors (5xx, timeouts), never on 4xx? Circuit breaker for persistently failing upstreams?
- **Suggest (if absent)** — For flaky upstream services, offer `p-retry` + `AbortSignal.timeout()` as a starting point. Warn: retry without idempotency on mutations = duplicate charges, duplicate emails.

### J4. Webhook signature verification

- **Detect** — any endpoint receiving webhooks (Stripe, GitHub, Twilio, Clerk, etc.). Look for signature-verification middleware or raw-body access.
- **Check (if present)** — Signature verified *before* parsing/acting on the body? Raw body preserved (most verifiers need the exact bytes)? Timestamp checked to reject replays (>5min old)? Secret loaded from env, rotated on incident?
- **Suggest (if absent) AND webhooks exist** — This is a security gap, not a nice-to-have. Flag prominently. Provide the specific verification snippet for the provider in use.

### J5. Graceful shutdown

- **Detect** — `app.enableShutdownHooks()`, SIGTERM handlers, `onApplicationShutdown` lifecycle hooks.
- **Check (if present)** — In-flight requests drained before process exit? DB connections closed? Background jobs/queues quiesced? Shutdown timeout bounded (otherwise orchestrator SIGKILLs)?
- **Suggest (if absent)** — In containerised deploys (k8s, Fly, Render), SIGTERM without draining = dropped requests on every deploy. Offer `app.enableShutdownHooks()` as the minimum.

### J6. Health + readiness endpoints

- **Detect** — `/health`, `/healthz`, `/ready`, `@nestjs/terminus` usage.
- **Check (if present)** — `/health` is pure liveness (returns 200 while the process is alive, no dependency checks — otherwise a Redis blip restarts your app)? `/ready` checks dependencies (DB, Redis, critical upstreams)? Load balancer points at the right one?
- **Suggest (if absent)** — Required behind any orchestrator (k8s, Fly, ECS). `/health` for liveness, `/ready` for traffic gating. Offer `@nestjs/terminus` if the project wants dependency-aware checks.

### J7. Correlation IDs / request tracing

- **Detect** — middleware setting `x-request-id` / `traceparent`, AsyncLocalStorage for context propagation, log fields including the ID.
- **Check (if present)** — ID generated if client didn't send one, preserved if they did? Propagated to downstream service calls (outbound HTTP headers)? Included in every structured log line via the logger? Survives async boundaries (AsyncLocalStorage, not just a closure)?
- **Suggest (if absent)** — In multi-service or multi-instance setups, debugging without correlation IDs is detective work. Offer a minimal middleware + logger integration.

### J8. Soft delete vs hard delete policy

- **Detect** — `deletedAt` / `isDeleted` columns on Prisma models, `$extends` middleware filtering soft-deleted rows.
- **Check (if present)** — All queries filter consistently (a global Prisma extension, not per-repository)? A hard-delete path exists for GDPR / "delete my account" requests? Unique constraints handle the soft-deleted row (email uniqueness across active + deleted rows breaks re-signup)?
- **Suggest (if absent or inconsistent) AND user-facing data is deletable** — Ask the user: GDPR / compliance requirements? Restore-on-mistake UX? If neither, hard delete is fine. If either, soft delete with a scheduled hard-delete job is the pattern.

### J9. Audit logs for sensitive mutations

- **Detect** — audit log table, `@AuditLog` decorator or interceptor, event stream (Kafka, etc.) for mutations.
- **Check (if present)** — Covers auth changes (role, password, 2FA), data exports, mutations by admins on other users' data? Append-only (no UPDATE/DELETE on the audit table)? Includes actor, target, action, before/after, timestamp, request ID?
- **Suggest (if absent) AND app has admins/multi-tenant/compliance scope** — Flag for B2B/regulated domains. Offer an interceptor-based pattern. Not needed for solo/consumer apps without admin actions.

### J10. DB connection pool + query timeouts

- **Detect** — Prisma `connection_limit` query param, `statement_timeout`, pool sizing config.
- **Check (if present)** — Pool sized for (container concurrency × instances) without exceeding DB max connections? Statement timeout set (default unlimited is a footgun — one slow query can pin a connection)? Separate read/write pools if the app uses replicas?
- **Suggest (if absent)** — Offer sensible defaults based on stack (Prisma + Postgres on Fly → `connection_limit=10`, `statement_timeout=30s`). Warn: production outages from connection exhaustion are almost always traceable to missing pool config.

### J11. Environment-aware logging discipline

- **Detect** — logger configuration that varies by `NODE_ENV` / config: level (`debug`/`info`/`warn`), format (JSON in prod, pretty in dev), transport (stdout in containers, file otherwise), sampling, redaction rules. Check for `pino`, `winston`, or the NestJS `Logger` with environment wiring.
- **Check (if present)** —
  - Log level driven by env (`LOG_LEVEL`), not hardcoded? Defaults to `info` in prod, `debug` in dev.
  - Format differs by env: structured JSON in prod (parseable by Datadog/Loki/Cloudwatch), pretty/human in dev.
  - Sensitive fields **redacted in all envs**: `password`, `token`, `authorization` header, `refreshToken`, full user objects, card numbers, API keys. Redaction happens at the logger layer, not at each call site.
  - Stack traces included in dev and staging, suppressed or truncated in prod responses (never in HTTP bodies), but **always** kept in the log stream for post-hoc debugging.
  - Request/response bodies not logged in prod by default (PII risk); enable only for specific endpoints with a justified reason.
  - Log volume sampled or throttled for hot paths in prod (100% logs on a 10k-RPS endpoint = log bill eats the margin).
- **Suggest (if absent)** — Offer `pino` (fast, structured by default, first-class redaction via `redact` option) or `winston` with an env-driven config factory. Call out the redaction list as the non-negotiable part — the rest is tunable.

---

## VERIFY, DON'T GUESS — CROSS-BOUNDARY CONTRACTS

When code crosses a boundary — reading a DB column, calling a third-party API, consuming an env var, importing a shared type from another package, relying on a library's signature — **read the source of truth before assuming its shape.** Never invent a field name, type, or return value from context.

Decision tree:

1. **Can I read the source of truth?** (Prisma schema / migration, `.env.example`, third-party SDK typings, shared DTO, OpenAPI spec)
   - Yes → read it. Use the exact field names, types, and shapes found there.
2. **Can't read it?** (external API with no typings, private upstream service)
   - Ask the user with a concrete question: "The Stripe webhook payload — which event type and which fields do you need me to handle?"
3. **Never guess.** "Probably `user_id`" is the same bug as "definitely `user_id`" when the real column is `userId`.

**Audit checks:**

- [ ] V1. Every Prisma query uses field names verified against `schema.prisma` — not guessed from model names
- [ ] V2. Every `process.env.X` has a matching entry in `.env.example` with a comment describing what it is
- [ ] V3. Every third-party SDK call uses methods verified in the package's type definitions — not invented
- [ ] V4. Every response DTO shape matches what the frontend/consumer actually reads — verified against the client code or OpenAPI spec
- [ ] V5. When parsing external webhooks / upstream responses, a real sample payload has been checked — not inferred from the endpoint name
- [ ] V6. Assumptions that couldn't be verified are surfaced to the user, not silently coded
