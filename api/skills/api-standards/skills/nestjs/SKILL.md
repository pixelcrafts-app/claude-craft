---
name: nestjs
description: Apply when writing or reviewing NestJS + Prisma code — module/controller/service/repository discipline, thin controllers, DTOs with class-validator on every inbound payload, Prisma repository wrappers, consistent error shape via global exception filter. Auto-invoke on any change under src/.
---

# NestJS Implementation Rules

Concrete code patterns for NestJS modules, controllers, services, DTOs, and middleware.

---

## Module Architecture

- One module per domain/feature — each under `src/modules/<feature>/`
- Shared infrastructure lives in `src/common/` (filters, guards, pipes, utils, config)
- Modules export only what other modules need — minimize the public surface
- Use `forwardRef()` only when circular dependencies are genuinely unavoidable
- Register global pipes, filters, and guards in the app module — not per-controller

---

## Controllers

- Controllers handle HTTP — they don't contain business logic
- One controller per resource/domain concept
- Use `@Version()` decorators for API versioning
- Every endpoint has Swagger decorators: `@ApiOperation`, `@ApiResponse`, `@ApiParam`/`@ApiQuery`/`@ApiBody`
- Return DTOs, never raw database entities
- Use `@HttpCode()` explicitly when response code differs from default (e.g., 204 for deletes)
- Route params and query use dedicated DTOs with class-validator decorators

---

## Services

- All business logic lives in services — controllers delegate, services decide
- Services receive and return typed objects (DTOs/interfaces), not raw JSON
- Inject dependencies via constructor — never instantiate manually
- Use `Logger` from `@nestjs/common` for structured logging
- Handle errors with specific NestJS exceptions (`NotFoundException`, `BadRequestException`, etc.)
- One service per domain concern — don't overload a service with multiple responsibilities

---

## DTOs & Validation

- Request DTOs use class-validator decorators (`@IsString`, `@IsNotEmpty`, `@IsOptional`, etc.)
- Response DTOs use `@ApiProperty()` for Swagger documentation
- Never trust incoming data — validate everything at the boundary
- Use `class-transformer` decorators (`@Transform`, `@Type`) for type coercion
- Provide sensible defaults for optional fields
- Separate Create/Update DTOs — don't reuse the same DTO for both operations
- Use `PartialType()`, `PickType()`, `OmitType()` from `@nestjs/swagger` for DTO composition

---

## Error Handling

- Global exception filter catches unhandled errors — use a consistent response format across the app
- Validation errors: extract from class-validator into human-readable messages
- Stack traces: only in development environment, never in production
- Never return raw database errors to the client
- Use specific HTTP exceptions (`NotFoundException`, `BadRequestException`, etc.) — never generic `HttpException` with arbitrary codes

---

## Database & Repositories

- Repository pattern: services call repositories, never query the DB directly
- Only repositories/data-access layers import the database client
- Handle connection errors gracefully — return typed error results
- Use transactions for multi-step mutations
- Index frequently queried fields — never rely on sequential scans for filtered queries

---

## Configuration

- All config from environment variables via `ConfigService` or config objects
- Never hardcode URLs, keys, ports, or secrets in source code
- Use `.env` files for local development, environment variables for deployed environments
- Validate required config on startup — fail fast if critical config is missing

---

## Testing

- Unit tests for services (mock dependencies)
- Integration tests for controllers (use `supertest` via `@nestjs/testing`)
- Test the happy path AND error paths (validation errors, not-found, unauthorized)
- Mock external services (DB, APIs) — tests must run offline and fast

---

## TypeScript Standards

NestJS-specific type constraints only — general TypeScript rules are in `core-standards:rules`.

- Prefer `readonly` properties on DTOs and config objects
- Use `enum` for finite value sets that map to DB/API values — not raw string literals
- Avoid `any` — use `unknown` when type is genuinely uncertain, then narrow with type guards at the boundary
