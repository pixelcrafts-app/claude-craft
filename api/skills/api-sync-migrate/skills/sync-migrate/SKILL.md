---
name: sync-migrate
description: Guide Prisma schema changes — edit schema, create migration, regenerate client, remind to sync downstream consumers
disable-model-invocation: true
---

# Schema Change Workflow (Prisma)

Guide the full schema change process for a Prisma-based API service.

## Steps

1. **Edit schema** — Make changes in `prisma/schema.prisma`
2. **Generate client** — Run `npx prisma generate` to update the Prisma client
3. **Create migration** — Run `npx prisma migrate dev --name <descriptive-name>`
4. **Verify** — Run `npx tsc --noEmit` and your lint command to confirm no type errors
5. **Update consumers** — Update any TypeScript interfaces, services, or repositories that use the changed models
6. **Sync downstream** — If another service consumes this schema (generated types, sibling microservice), push and remind the user to run the consumer-side sync/regenerate step

## Important

- Migration names should be descriptive: `add-user-preferences`, `rename-article-status`, etc.
- Never edit migrations after they've been applied — create a new migration instead
- If the migration fails, check for data that violates new constraints before retrying
- In schema-owning / schema-consumer splits, the owner repo creates migrations; consumers pull schema + regenerate client only
