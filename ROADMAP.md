# Roadmap

Where Claude Craft is headed. Dates are directional — we ship when it's ready.

## Shipped

- **v0.2.0** — First public release. Four plugins: Flutter, API, Web, core-hooks. Repo consolidated to one bundle per stack.
- **v0.1.1** — Review agents load their pack's standards on invocation.
- **v0.1.0** — Internal release. Three stack packs + core-hooks, multi-tool export.

## Packs today

| Pack | Covers | Install |
|---|---|---|
| **flutter-standards** | Widgets, state, lists, forms, a11y, perf, observability | `flutter-standards@pixelcrafts` |
| **api-standards** | NestJS + Prisma — schema workflow, controller/service/repo split, validation, error shapes | `api-standards@pixelcrafts` |
| **web-standards** | Next.js + Tailwind + shadcn — app router, state, data fetching, responsive, dark mode, a11y | `web-standards@pixelcrafts` |
| **core-hooks** | Cross-stack safety — block secret edits, dangerous shell | `core-hooks@pixelcrafts` |

## Next up

### Database pack (`db-standards`) — planned

Postgres-first, MySQL notes. Scope:

- Schema design (naming, normalization, denormalization trade-offs)
- Migration discipline (idempotency, backfill patterns, zero-downtime rollouts)
- Index strategy (reading a query plan, when to add, when to drop)
- Query patterns (N+1 detection, pagination, soft-delete)
- Audit: `/db-standards:review-migration` — catches dangerous DDL before it hits production

### Core extraction (`core-standards`) — planned

Universal content — DRY, testing pyramid, observability basics, security basics — currently duplicated across Flutter, API, and Web skills. Extract to a shared plugin that stack packs reference.

Goal: single source of truth for cross-stack principles. Stack packs keep stack-specific enforcement; universal rules live in one place.

### Tooling — planned

- **CI validation** — GitHub Actions workflow that validates `marketplace.json` against the filesystem (plugin paths exist, versions consistent, SKILL.md frontmatter parses)
- **Drift detector** — catches when a plugin's version bumps but the marketplace entry doesn't
- **Skill linter** — checks every SKILL.md for required frontmatter and a non-empty body

## Under consideration

Not promised. These land if someone needs them enough to PR them.

- **Rust pack** — when there's a meaningful production Rust codebase to extract from
- **Mobile native pack** — SwiftUI + Jetpack Compose
- **Infra pack** — Terraform / Pulumi, state management, secret handling
- **Observability pack** — logging schema, metric naming, trace propagation
- **Per-IDE exporters** — Zed, Windsurf, others as they stabilize rule formats

## Not planned

- **Vendor-specific skills** — if a skill only works for one company's patterns, it belongs in that company's private fork
- **Auto-fix tooling** — we show what's wrong, we don't rewrite your code. Scaffolds are the exception because they generate new files rather than mutate existing ones.

## How to influence this

Open an issue or a discussion. Concrete use cases land better than general requests. See [docs/contributing.md](docs/contributing.md).
