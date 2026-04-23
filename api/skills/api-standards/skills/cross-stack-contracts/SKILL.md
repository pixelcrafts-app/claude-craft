---
name: cross-stack-contracts
description: Apply when a project uses 2 or more stacks that communicate — Flutter+NestJS, Next.js+NestJS, any frontend+backend combination. Governs error shape, pagination format, auth header, and versioning contracts at the boundary. Active when craft.json stacks[] contains 2+ entries. Auto-invoke on any file touching API boundaries: controllers, DTOs, API clients, response types.
---

# Cross-Stack Contracts

When a project has multiple stacks (frontend + backend, mobile + API), the boundary between them is the highest-risk point for silent drift. A breaking change on one side that the other side doesn't know about produces runtime failures that neither stack's tests catch.

**Activation:** Active when `craft.json stacks[]` contains 2 or more entries. When a single-stack project touches an external API boundary: apply these rules to that boundary.

---

## §C1 Unified Error Shape

Every error response across all stacks must use one shared shape:

```typescript
{
  code: string;      // machine-readable, dot-separated: "auth.token_expired"
  message: string;   // human-readable, not for UI display
  details?: unknown; // validation errors, field-level failures
}
```

- `code` is the contract. The frontend/mobile switches on `code`, not on HTTP status alone.
- `message` is for logging and debugging — never display it directly in the UI.
- HTTP status codes alone are not a sufficient error contract. `401` has multiple meanings (expired, invalid, missing); `code` disambiguates.

Every new error response must define a `code` before implementation. The code lives in a shared enum or constant file, not as a raw string in the handler.

---

## §C2 Pagination Format

Cursor-based pagination only for new endpoints. Offset pagination is not permitted in new API endpoints.

Cursor response shape:

```typescript
{
  data: T[];
  cursor: {
    next: string | null;   // opaque cursor, not a page number
    hasMore: boolean;
  }
}
```

Offset pagination breaks under concurrent writes (items shift, pages repeat or skip). Cursor pagination is stable regardless of concurrent mutations.

For existing offset-paginated endpoints: do not change the format without a versioned route. Document the limitation.

---

## §C3 Auth Header Standard

All stacks in the project use `Authorization: Bearer <token>` — no custom header names.

No custom auth headers (`X-Auth-Token`, `X-Api-Key` for user sessions, `token` query params for authenticated requests). Non-standard headers are invisible to auth proxies, gateways, and security scanners.

API keys for service-to-service calls may use custom headers — this rule applies to user-session authentication only.

---

## §C4 Versioning for Breaking Changes

Breaking changes to any API contract require a new route version.

A breaking change is: removing a field from a response, renaming a field, changing a field's type, changing an endpoint's HTTP method, changing authentication requirements.

```
/api/v1/users/:id   — existing contract, unchanged
/api/v2/users/:id   — new contract with breaking change
```

Non-breaking additions (new optional fields, new endpoints) do not require versioning.

Never remove a field from an existing versioned response. Mark it deprecated (`@deprecated` in the DTO) and keep it in the response until the old version is decommissioned.

---

## §C5 Contract Documentation

Every API boundary must have a contract document or OpenAPI spec that is:
- Source-of-truth (generated from code, not written by hand)
- Updated on every change to the boundary
- Readable by all stacks without running the API

For NestJS: generate from decorators via `@nestjs/swagger`. For Next.js API routes: use `next-swagger-doc` or equivalent. The generated spec is committed to the repo.

Frontend/mobile reads the spec before implementing API calls — not the endpoint name.

---

## Verification Checklist

When `craft.json stacks[]` has 2+ entries, Phase 2 checks:

- `§C1` — grep for error responses not using the shared error shape; flag any `{ error: string }` or `{ message: string }` without `code`
- `§C2` — grep for `page` / `offset` / `limit` patterns in new endpoint handlers
- `§C3` — grep for custom auth header names in API client files and middleware
- `§C4` — grep for field removal in existing DTOs without route version bump
- `§C5` — confirm OpenAPI/Swagger spec file exists and was updated if contracts changed
