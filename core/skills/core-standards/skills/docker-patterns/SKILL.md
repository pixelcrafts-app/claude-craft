---
name: docker-patterns
description: Docker and Docker Compose patterns for local development, container security, networking, volume strategies, and multi-service orchestration.
origin: ECC
---

# Docker Patterns

## Triggers

- Setting up Docker Compose for local dev
- Designing multi-container architecture
- Troubleshooting container networking or volume issues
- Reviewing Dockerfiles for security and image size
- Migrating from local to containerized workflow

## Standard Web App Stack

```yaml
# docker-compose.yml
services:
  app:
    build:
      context: .
      target: dev                     # dev stage of multi-stage Dockerfile
    ports:
      - "3000:3000"
    volumes:
      - .:/app                        # bind mount for hot reload
      - /app/node_modules             # anonymous volume — protects container deps
    environment:
      - DATABASE_URL=postgres://postgres:postgres@db:5432/app_dev
      - REDIS_URL=redis://redis:6379/0
      - NODE_ENV=development
    depends_on:
      db:
        condition: service_healthy
    command: npm run dev

  db:
    image: postgres:16-alpine
    ports:
      - "5432:5432"
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: app_dev
    volumes:
      - pgdata:/var/lib/postgresql/data
      - ./scripts/init-db.sql:/docker-entrypoint-initdb.d/init.sql
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 3s
      retries: 5

  redis:
    image: redis:7-alpine
    volumes:
      - redisdata:/data

  mailpit:
    image: axllent/mailpit
    ports:
      - "8025:8025"   # web UI
      - "1025:1025"   # SMTP

volumes:
  pgdata:
  redisdata:
```

## Multi-Stage Dockerfile

```dockerfile
FROM node:22-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci

FROM node:22-alpine AS dev
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
EXPOSE 3000
CMD ["npm", "run", "dev"]

FROM node:22-alpine AS build
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build && npm prune --production

FROM node:22-alpine AS production
WORKDIR /app
RUN addgroup -g 1001 -S appgroup && adduser -S appuser -u 1001
USER appuser
COPY --from=build --chown=appuser:appgroup /app/dist ./dist
COPY --from=build --chown=appuser:appgroup /app/node_modules ./node_modules
COPY --from=build --chown=appuser:appgroup /app/package.json ./
ENV NODE_ENV=production
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost:3000/health || exit 1
CMD ["node", "dist/server.js"]
```

## Override Files

```yaml
# docker-compose.override.yml — auto-loaded in dev
services:
  app:
    environment:
      - DEBUG=app:*
    ports:
      - "9229:9229"   # Node debugger

# docker-compose.prod.yml — explicit for production
services:
  app:
    build:
      target: production
    restart: always
    deploy:
      resources:
        limits:
          cpus: "1.0"
          memory: 512M
```

```bash
docker compose up                                                    # dev (auto-loads override)
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d  # prod
```

## Networking

```yaml
# Service discovery: containers resolve by service name
# postgres://db:5432  redis://redis:6379

# Isolate db from frontend
services:
  frontend: { networks: [frontend-net] }
  api:      { networks: [frontend-net, backend-net] }
  db:       { networks: [backend-net] }   # unreachable from frontend

networks:
  frontend-net:
  backend-net:

# Bind to localhost only — don't expose db to Docker network externally
services:
  db:
    ports:
      - "127.0.0.1:5432:5432"
```

## Volume Strategies

```yaml
services:
  app:
    volumes:
      - .:/app                   # source code (hot reload)
      - /app/node_modules        # protect container's node_modules from host overlay
      - /app/.next               # protect build cache

  db:
    volumes:
      - pgdata:/var/lib/postgresql/data
      - ./scripts/init.sql:/docker-entrypoint-initdb.d/init.sql
```

## Container Security

```dockerfile
FROM node:22.12-alpine3.20            # pin exact tags — never :latest
RUN addgroup -g 1001 -S app && adduser -S app -u 1001
USER app                              # never run as root
```

```yaml
services:
  app:
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs: [/tmp, /app/.cache]
    cap_drop: [ALL]
    cap_add: [NET_BIND_SERVICE]       # only if binding ports < 1024
```

```yaml
# Secrets — never hardcode in image or compose file
services:
  app:
    env_file: [.env]                  # gitignored
    environment:
      - API_KEY                       # inherits from host

# BAD: ENV API_KEY=sk-proj-xxxxx in Dockerfile
```

## .dockerignore

```
node_modules
.git
.env
.env.*
dist
coverage
*.log
.next
.cache
docker-compose*.yml
Dockerfile*
tests/
```

## Debug Commands

```bash
docker compose logs -f app                    # stream app logs
docker compose logs --tail=50 db             # last 50 db lines
docker compose exec app sh                   # shell into app
docker compose exec db psql -U postgres      # connect to postgres
docker compose ps                            # service status
docker stats                                 # resource usage
docker compose up --build                    # rebuild images
docker compose build --no-cache app          # force full rebuild
docker compose down -v                       # DESTRUCTIVE: stop + remove volumes
docker system prune                          # remove unused images/containers

# Network debug
docker compose exec app nslookup db
docker compose exec app wget -qO- http://api:3000/health
docker network inspect <project>_default
```

## Hard Rules

| Wrong | Right |
|-------|-------|
| `:latest` tag | Pin exact version (`postgres:16-alpine`) |
| Run as root | Non-root user in Dockerfile |
| Data in container (no volume) | Named volume for any persistent data |
| Secrets in `docker-compose.yml` | `.env` file (gitignored) |
| One container for all services | One process per container |
| `docker compose` in production bare | Kubernetes / ECS / Swarm for orchestration |
