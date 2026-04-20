---
name: code-quality
description: Apply when auditing NestJS endpoints for security and correctness — every route guarded or explicitly @Public, DTO validated, no any leaks, no console.log in feature code, tests for happy and auth/validation failure paths, caching keys scoped by tenant. Auto-invoke when adding or modifying endpoints.
---

# API Code Quality Audit

> Every item is a pass/fail check. Run before major releases or as the basis for a pre-ship skill.

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
