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

### Server State (React Query / TanStack Query)
- All API data fetched and cached via React Query
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

- Server components: fetch directly (no React Query needed)
- Client components: React Query hooks
- API client: centralized HTTP client class with timeout + abort signals
- Cache manager: TTL-based with stale-while-revalidate and request deduplication
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
