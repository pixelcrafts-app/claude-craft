---
name: api-design
description: REST API design principles — resource naming, HTTP semantics, status codes, pagination, filtering, error responses, auth, rate limiting, and versioning. Framework-agnostic. NestJS-specific enforcement lives in api-standards:code-quality.
origin: ECC
---

# API Design Patterns

## Triggers

- Designing new API endpoints
- Reviewing existing API contracts
- Adding pagination, filtering, or sorting
- Implementing error handling for APIs
- Planning API versioning strategy
- Building public or partner-facing APIs

## URL Structure

```
# Resources: plural, lowercase, kebab-case nouns
GET    /api/v1/users
GET    /api/v1/users/:id
POST   /api/v1/users
PUT    /api/v1/users/:id
PATCH  /api/v1/users/:id
DELETE /api/v1/users/:id

# Sub-resources for relationships
GET    /api/v1/users/:id/orders
POST   /api/v1/users/:id/orders

# Actions that don't map to CRUD — use verb sparingly
POST   /api/v1/orders/:id/cancel
POST   /api/v1/auth/refresh
```

```
# GOOD                              BAD
/api/v1/team-members               /api/v1/getUsers         (verb in URL)
/api/v1/orders?status=active       /api/v1/user             (singular)
/api/v1/users/123/orders           /api/v1/team_members     (snake_case)
```

## HTTP Methods

| Method | Idempotent | Safe | Use For |
|--------|-----------|------|---------|
| GET | Yes | Yes | Retrieve |
| POST | No | No | Create, trigger actions |
| PUT | Yes | No | Full replacement |
| PATCH | No* | No | Partial update |
| DELETE | Yes | No | Remove |

## Status Codes

```
200 OK               — GET, PUT, PATCH with body
201 Created          — POST (include Location header)
204 No Content       — DELETE, PUT without body

400 Bad Request      — malformed JSON, missing required field
401 Unauthorized     — missing or invalid auth token
403 Forbidden        — authenticated but not authorized
404 Not Found        — resource doesn't exist
409 Conflict         — duplicate entry, state conflict
422 Unprocessable    — valid JSON, semantically invalid data
429 Too Many Requests — rate limit exceeded

500 Internal Error   — never expose details
502 Bad Gateway      — upstream service failed
503 Unavailable      — include Retry-After header
```

```
# WRONG: 200 for everything
{ "status": 200, "success": false, "error": "Not found" }

# RIGHT: HTTP semantics + typed error
HTTP/1.1 404 Not Found
{ "error": { "code": "not_found", "message": "User not found" } }
```

## Response Format

```json
// Single resource
{ "data": { "id": "abc-123", "email": "…", "created_at": "2025-01-15T10:30:00Z" } }

// Collection
{
  "data": [{ "id": "abc-123", "name": "Alice" }],
  "meta": { "total": 142, "page": 1, "per_page": 20, "total_pages": 8 },
  "links": { "self": "…?page=1", "next": "…?page=2", "last": "…?page=8" }
}

// Error
{
  "error": {
    "code": "validation_error",
    "message": "Request validation failed",
    "details": [
      { "field": "email", "message": "Must be a valid email", "code": "invalid_format" }
    ]
  }
}
```

## Pagination

### Offset (simple)

```
GET /api/v1/users?page=2&per_page=20
SELECT * FROM users ORDER BY created_at DESC LIMIT 20 OFFSET 20;
```

- Pros: supports "jump to page N"
- Cons: slow on large offsets, inconsistent with concurrent inserts

### Cursor (scalable)

```
GET /api/v1/users?cursor=eyJpZCI6MTIzfQ&limit=20
SELECT * FROM users WHERE id > :cursor_id ORDER BY id ASC LIMIT 21;
-- fetch N+1 to detect has_next
```

```json
{ "data": […], "meta": { "has_next": true, "next_cursor": "eyJpZCI6MTQzfQ" } }
```

- Pros: consistent O(1) performance, stable with concurrent inserts
- Cons: no arbitrary page jump, opaque cursor

| Use Case | Type |
|----------|------|
| Admin dashboards, datasets <10K | Offset |
| Infinite scroll, feeds, large datasets | Cursor |
| Public APIs | Cursor default + offset optional |
| Search results | Offset (users expect page numbers) |

## Filtering, Sorting, Search

```
GET /api/v1/orders?status=active&customer_id=abc-123
GET /api/v1/products?price[gte]=10&price[lte]=100
GET /api/v1/products?category=electronics,clothing
GET /api/v1/products?sort=-created_at,price       # prefix - = descending
GET /api/v1/products?q=wireless+headphones
GET /api/v1/users?fields=id,name,email            # sparse fieldsets
```

## Auth Patterns

```
# User-facing: Bearer token
Authorization: Bearer eyJhbGci…

# Server-to-server: API key in header
X-API-Key: sk_live_abc123
```

```typescript
// Resource-level ownership check
const order = await Order.findById(req.params.id);
if (!order) return res.status(404).json({ error: { code: "not_found" } });
if (order.userId !== req.user.id) return res.status(403).json({ error: { code: "forbidden" } });

// Role-based
app.delete("/api/v1/users/:id", requireRole("admin"), handler);
```

## Rate Limiting

```
HTTP/1.1 200 OK
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1640000000

HTTP/1.1 429 Too Many Requests
Retry-After: 60
{ "error": { "code": "rate_limit_exceeded", "message": "Try again in 60 seconds" } }
```

| Tier | Limit | Window |
|------|-------|--------|
| Anonymous | 30/min | Per IP |
| Authenticated | 100/min | Per user |
| Premium | 1000/min | Per API key |
| Internal | 10000/min | Per service |

## Versioning

**URL versioning (recommended):** `/api/v1/` → `/api/v2/`

Strategy:
1. Start with `/api/v1/` — don't version until breaking change is required
2. Maintain at most 2 active versions (current + previous)
3. Deprecation: 6 months notice → `Sunset` header → `410 Gone`
4. Non-breaking (no new version needed): add fields, add optional params, add endpoints
5. Breaking (requires new version): remove/rename fields, change types, change URL structure

## Implementation

### TypeScript (Next.js)

```typescript
export async function POST(req: NextRequest) {
  const body = await req.json();
  const parsed = createUserSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json({
      error: {
        code: "validation_error",
        message: "Request validation failed",
        details: parsed.error.issues.map(i => ({ field: i.path.join("."), message: i.message, code: i.code })),
      },
    }, { status: 422 });
  }
  const user = await createUser(parsed.data);
  return NextResponse.json({ data: user }, { status: 201, headers: { Location: `/api/v1/users/${user.id}` } });
}
```

### Go (net/http)

```go
func (h *UserHandler) CreateUser(w http.ResponseWriter, r *http.Request) {
    var req CreateUserRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        writeError(w, http.StatusBadRequest, "invalid_json", "Invalid request body")
        return
    }
    if err := req.Validate(); err != nil {
        writeError(w, http.StatusUnprocessableEntity, "validation_error", err.Error())
        return
    }
    user, err := h.service.Create(r.Context(), req)
    if err != nil {
        switch {
        case errors.Is(err, domain.ErrEmailTaken):
            writeError(w, http.StatusConflict, "email_taken", "Email already registered")
        default:
            writeError(w, http.StatusInternalServerError, "internal_error", "Internal error")
        }
        return
    }
    w.Header().Set("Location", fmt.Sprintf("/api/v1/users/%s", user.ID))
    writeJSON(w, http.StatusCreated, map[string]any{"data": user})
}
```

## Pre-Ship Checklist

- [ ] URL: plural, kebab-case, no verbs in path
- [ ] HTTP method matches semantics
- [ ] Status codes used correctly (not 200 for everything)
- [ ] Input validated with schema (Zod / Pydantic)
- [ ] Error response: `code` + `message` + optional `details[]`
- [ ] Pagination on all list endpoints
- [ ] Authentication required (or explicitly public)
- [ ] Authorization: user can only access their own resources
- [ ] Rate limiting configured
- [ ] No internal details in responses (no stack traces, no SQL errors)
- [ ] Naming consistent with existing endpoints
- [ ] OpenAPI spec updated
