---
name: nextjs
description: Apply when writing or reviewing Next.js + React + Tailwind + shadcn code — app router, Server Components by default, client boundary pushed deep, Tailwind utilities with CSS variable tokens, shadcn base components, React Query with structured keys, React Hook Form + Zod, next/image + next/font, no barrel files, no any or as assertions. Auto-invoke on changes under app/, components/, or lib/.
---

# Next.js Implementation Rules

> **Ownership**: Generic Next.js patterns — reusable across any Next.js + Tailwind + shadcn/ui project.
> App-specific values (tokens, container widths, brand colors, API clients) belong in your app's `CLAUDE.md` or a local app-level rule.

Concrete code patterns for Next.js app router, React components, Tailwind CSS, and shadcn/ui.

---

## App Router Architecture

- **Server Components by default** — only add `"use client"` when the component needs interactivity, hooks, or browser APIs
- `"use client"` goes at the very top of the file, before imports
- Push client boundaries as deep as possible — wrap only the interactive parts, not entire pages
- Layouts for shared UI (nav, sidebar) — they don't re-render on navigation
- `loading.tsx` for route-level loading states — matches the page's layout
- `error.tsx` for route-level error boundaries — must be a client component
- `not-found.tsx` for 404 states

---

## Component Patterns

- One component per file — named export matches filename
- Use `React.memo()` for expensive components that receive stable props
- Prefer composition over prop drilling — use children and slots
- Destructure props in the function signature — not inside the body
- Colocate component-specific types in the same file — shared types in `lib/types/`

---

## Tailwind CSS Standards

- All styling via Tailwind utilities — no inline styles, no CSS modules (unless escaping Tailwind or for dynamic computed values like animation delays, z-index stacking, or values derived from props/state)
- Dark mode via CSS class strategy (`dark:` prefix) — controlled by `next-themes`
- Semantic colors via CSS custom properties (HSL): `--background`, `--foreground`, `--border`, `--primary`, etc.
- Never hardcode hex/RGB values in components — use CSS variables or Tailwind theme tokens
- Responsive: mobile-first (`sm:`, `md:`, `lg:` for larger viewports)
- Use `cn()` utility (clsx + tailwind-merge) for conditional class composition
- Spacing via Tailwind scale — no arbitrary values like `p-[13px]` unless truly necessary
- Max content width: constrain via container or `max-w-*` utility — never full-width body text. Specific value lives in your app-level config.

---

## shadcn/ui Components

- Use shadcn/ui components as the base — don't rebuild what already exists
- Customize via the component file in `components/ui/` — not by overriding with wrapper components
- Follow shadcn/ui patterns: `variants` via `class-variance-authority`, composable primitives
- Radix UI primitives underneath — respect their accessibility patterns (keyboard nav, ARIA)
- Toast notifications via Sonner — not custom implementations
- Dialogs/sheets via Radix — respect focus trapping and escape-to-close

---

## State Management

### Server State

**Decide first: Server Component fetch or React Query?**

| Use Server Component fetch (no React Query) | Use React Query (requires `"use client"`) |
|---|---|
| Data needed at initial render, can block | Data needed after interaction or on user action |
| Data is auth-scoped and must not be cached client-side | Data benefits from client-side cache / stale-while-revalidate |
| SEO-sensitive content | Optimistic updates, background refetch, dependent queries |
| Page-level data that rarely changes per-session | User-specific dynamic data that changes during the session |

Never add `"use client"` solely to use React Query when a Server Component fetch would work — that removes Server Component benefits (no client bundle, no loading flash for initial data).

**React Query rules (when applicable):**
- Query keys: structured arrays `['entity', 'list', { filter }]` — never plain strings
- `staleTime` and `gcTime` set per query based on data volatility
- Mutations use `useMutation` with `onSuccess` invalidation
- Optimistic updates for user-initiated actions where appropriate

### Client State (React Context)
- React Context for app-wide client state (theme, view preferences, UI state)
- Keep context providers minimal — don't put server data in context
- Split contexts by concern — one provider per domain, not one giant provider

### Local State
- `useState` for component-local UI state (open/closed, selected tab)
- `useReducer` for complex local state with multiple actions
- Persist user preferences to `localStorage` (view mode, collapsed states)

---

## Data Fetching

- Fetch strategy: use the decision table in State Management above before choosing Server Component fetch vs React Query
- Server Components: fetch directly — no React Query, no `useEffect`, no client state
- Client Components: React Query hooks — never raw `fetch` in `useEffect`
- New routes require sibling files: `loading.tsx` (Suspense boundary), `error.tsx` (error boundary), and `not-found.tsx` — all three are required for every new route, not optional
- API client: centralized HTTP client class with timeout + abort signals
- Server Component cache semantics: use `cache()` for deduplication within a request, `revalidatePath()` / `revalidateTag()` after mutations, `fetch` `revalidate` option for time-based invalidation — never leave Server Component fetches uncached by default
- Handle loading, error, empty states for every data-driven component — no exceptions

---

## Performance

- **Images**: `next/image` with explicit width/height. Lazy loading by default. Fallback placeholders.
- **Code splitting**: Dynamic imports (`next/dynamic`) for heavy components not needed at first paint
- **Bundle**: Check with `@next/bundle-analyzer` — no surprise large dependencies
- **Fonts**: `next/font` for self-hosted fonts — no layout shift
- **Memoization**: `React.memo`, `useMemo`, `useCallback` — only where profiling shows benefit, not preemptively

---

## Forms & Validation

- React Hook Form for form state management
- Zod schemas for validation — shared between client and server where possible
- Display errors inline next to the field, not in a toast
- Disable submit button during submission — show loading state
- Optimistic UI for non-critical actions, confirmation for critical ones

---

## PWA & Offline

- Service worker for asset caching and offline fallback
- Manifest for install prompt and home screen behavior
- Offline page: designed, not a browser error
- Update notifications: prompt user when new version available

---

## Accessibility

- Semantic HTML: `<nav>`, `<main>`, `<article>`, `<section>`, `<button>`
- All interactive elements keyboard-accessible with visible focus rings
- ARIA attributes from Radix UI — don't override unless necessary
- Images: meaningful `alt` text or `alt=""` for decorative
- Skip-to-content link for keyboard users
- `prefers-reduced-motion`: respect via Tailwind's `motion-reduce:` variant

---

## Naming Conventions

- **Files**: kebab-case for all files (`user-card.tsx`, `api-client.ts`, `use-viewport.tsx`)
- **Components**: PascalCase function name matching the file (`user-card.tsx` → `export default function UserCard`)
- **Hooks**: `use-` prefix in filename, `use` prefix in function name (`use-viewport.tsx` → `useViewport`)
- **Utilities**: kebab-case files, camelCase exports (`date-utils.ts` → `formatDate`)
- **Types/Interfaces**: PascalCase (`UserCardProps`, `ApiResponse`)
- **Constants**: UPPER_SNAKE_CASE for true constants (`PAGE_SIZE`, `MAX_RETRIES`), camelCase for config objects

---

## TypeScript Standards

- `interface` for component props, `type` for unions/utility types
- Avoid `any` — use `unknown` and narrow
- Avoid `as` type assertions — use type guards or explicit narrowing instead. `as` silently bypasses type safety.
- Prefer `const` over `let`
- Props: destructure in signature, provide defaults for optional props
- Generic components: use TypeScript generics for reusable typed components
- Exhaustive switch handling: use `never` for default case to catch unhandled union members at compile time
- No array index as `key` in lists with dynamic/reorderable data — use stable unique identifiers
- No barrel files (`index.ts` re-exports) — they break tree-shaking and slow builds. Import directly from the source file.
- Validate external data at boundaries — parse API responses with Zod schemas before passing into the app

---

## Verify, Don't Guess — Cross-Boundary Contracts

When writing code that crosses a boundary — calling an API, reading an env var, using a third-party SDK, consuming a shared type from another package — **read the source of truth before assuming its shape.** Never invent a field name, type, or return value from context.

Decision tree:

1. **Can I read the source of truth?** (API controller + DTO, OpenAPI spec, `.env.example`, SDK typings, shared package)
   - Yes → read it. Use the exact field names, types, and shapes found there.
2. **Can't read it?** (external API, undocumented third-party, private backend)
   - Ask the user with a concrete question: "The `/users/:id/subscriptions` endpoint — what fields does the response have?"
3. **Never guess.** "Probably `userId`" is the same bug as "definitely `userId`" when the real field is `user_id`.

**Examples requiring this discipline:**

- Calling a NestJS endpoint from Next.js → read the controller + DTO in the API repo. If it lives in a sibling directory, add it to the session (`--add-dir`) or Read it directly.
- Parsing a JSON response → read an actual sample (curl / network tab / logs), not the endpoint name.
- Reading `process.env.NEXT_PUBLIC_X` → check `.env.example` or the backend's env loader; don't assume a name.
- Using a third-party SDK method → read its type definitions or docs; don't call a method "because it should exist."

**When the user asks you to build a frontend feature that calls an API:** the default move is to locate and read the API code first, then write the client. Order: read → plan → code. Not: code → hope → debug.

**Surface every assumption you couldn't verify.** End your response with a short "Assumptions I couldn't verify" list so the user knows what to sanity-check. Silent assumptions are silent bugs.
