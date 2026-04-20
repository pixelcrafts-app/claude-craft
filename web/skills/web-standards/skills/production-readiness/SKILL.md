---
name: production-readiness
description: Apply when auditing a Next.js app for production readiness — smart Detect → Check → Suggest audit for error boundaries, Suspense, optimistic UI, image optimization, metadata / OG / sitemap, CSP + security headers, analytics consent, Core Web Vitals budgets, env-aware logging. Never blindly enforces — detects what's present, audits depth, suggests options with tradeoffs if absent. Auto-invoke when reviewing app-level wiring, route config, or release-readiness changes.
---

# Next.js Production Readiness

These are the concerns that decide whether a Next.js app survives contact with real traffic, search engines, ad networks, and privacy regulators. None are universally required — each depends on audience, regulatory scope, and deployment model. Every item follows Detect → Check → Suggest.

## How to read this audit

Every concern has three phases:

1. **Detect** — grep/read the codebase for signs this is addressed (file, export, header, config).
2. **Check** — if present, audit depth: scoped correctly? covers edge cases? no bypass paths?
3. **Suggest** — if absent, propose options with tradeoffs. The user decides. Do not rewrite their app.

Skip concerns that don't apply (an internal tool behind SSO doesn't need OG tags or a sitemap). Flag concerns where the user's answer is "not yet" so they aren't silently missed at launch.

---

## R1. Error boundaries scoped per route

- **Detect** — `error.tsx` at route and sub-route levels, root `global-error.tsx`, or client-side `<ErrorBoundary>` in feature layouts.
- **Check (if present)** —
  - `error.tsx` exists at the root of every meaningful route segment — not just the app root. A crash in `/dashboard` shouldn't crash the marketing site.
  - Error UI provides a specific message + retry affordance (calling `reset()`), never a generic "Something went wrong."
  - Crash reports fire from the boundary (Sentry / equivalent) with request context attached.
  - `global-error.tsx` exists as the last-resort boundary — handles errors in the root layout.
- **Suggest (if absent)** — Offer an `error.tsx` template with retry + report hooks. Warn: without boundaries, one exception in a deep component blanks the entire tab — users close the app and don't come back.

---

## R2. Suspense boundaries for streaming

- **Detect** — `<Suspense>` wrapping async Server Component children, `loading.tsx` per route, use of `use()` hook.
- **Check (if present)** —
  - Suspense boundary placed so slow data doesn't block the shell — user sees navbar + skeleton within 100ms, not a white screen until all data resolves.
  - `loading.tsx` matches the final layout (skeleton, not a spinner) — reduces perceived jank.
  - Independent data fetches wrapped in independent Suspense boundaries — slow one doesn't block fast one.
  - Nested Suspense makes sense (shell → list → item) — not all-or-nothing.
- **Suggest (if absent) AND the app uses Server Components / streaming** — offer a route-level `loading.tsx` + targeted `<Suspense>` around the slow segment. Warn: without Suspense, streaming doesn't happen and the route blocks on the slowest query.

---

## R3. Optimistic updates + rollback on failure

- **Detect** — React Query `onMutate` / `onError` with cache rollback, `useOptimistic` in Server Actions, form libraries with optimistic state.
- **Check (if present)** —
  - Optimistic mutation runs only for low-risk actions (toggles, reorderings, likes) — not for money, identity, or destructive actions.
  - `onError` rolls back the cache to its prior state — not a generic refetch which is slow and can show stale data.
  - User sees a non-intrusive error toast when rollback fires — never silent.
  - Server confirms the final state via `invalidateQueries` — client isn't trusted as the truth forever.
- **Suggest (if absent) AND the UI has interactive toggles or lists** — offer the React Query `onMutate` pattern. For critical mutations (checkout, delete account) suggest staying with loading state — optimistic rollback confuses users.

---

## R4. Image optimization

- **Detect** — `next/image` usage, `sizes` prop, blur placeholder config, remote pattern config in `next.config.js`.
- **Check (if present)** —
  - `next/image` used universally — not raw `<img>` tags (audit finds `<img ` and flags).
  - `width` / `height` explicit — avoids CLS from layout shift.
  - `sizes` prop set on responsive images — otherwise browser downloads the largest variant on small screens.
  - `placeholder="blur"` or a colour fallback for above-the-fold images — avoids flash-of-empty.
  - `priority` set on the LCP image only — overusing it defeats the laziness.
  - Remote images from an allowed domain list in `next.config.js` — not `remotePatterns: [{ hostname: '**' }]` (SSRF risk).
- **Suggest (if absent)** — offer a migration from `<img>` to `next/image`. Warn: non-optimized images are the #1 LCP killer.

---

## R5. Metadata / OG / Twitter cards

- **Detect** — `export const metadata` in `layout.tsx` / `page.tsx`, `generateMetadata()` for dynamic routes, OG image generation via `opengraph-image.tsx`.
- **Check (if present)** —
  - Every public route has `title` and `description` — not just inherited from the root.
  - OG image set per route (dynamic routes generate per-content OG) — not a generic site card for every URL.
  - `twitter: { card: 'summary_large_image' }` — distinct from OG for Twitter-specific treatment.
  - Canonical URL set on paginated/filtered pages — avoids duplicate-content SEO penalties.
  - `robots: { index: true, follow: true }` explicit on public pages — staging previews should be `noindex`.
- **Suggest (if absent) AND the app is public (not SSO-gated internal)** — offer the `generateMetadata()` pattern. For internal / auth-gated apps, skip — metadata matters only for crawlers and link previews.

---

## R6. Sitemap + robots.txt

- **Detect** — `app/sitemap.ts`, `app/robots.ts`, or static `public/sitemap.xml` + `public/robots.txt`.
- **Check (if present)** —
  - Sitemap dynamic — includes every indexable route, regenerates on new content.
  - Excludes auth-gated / admin / preview routes — they shouldn't appear in search.
  - `robots.txt` matches — blocks `/admin`, `/api`, preview branches.
  - Submitted to Google Search Console / Bing Webmaster — otherwise discovery takes months.
- **Suggest (if absent) AND the app is public AND needs SEO** — offer `app/sitemap.ts`. For apps that don't need organic traffic (SSO-gated dashboards, invite-only products), skip.

---

## R7. CSP + security headers

- **Detect** — `headers()` in `next.config.js`, middleware setting security headers, or platform-level config (Vercel `vercel.json`, Cloudflare Workers).
- **Check (if present)** —
  - `Content-Security-Policy` set — script sources allowlisted, no `unsafe-inline` unless paired with nonces/hashes.
  - `Strict-Transport-Security` with `max-age ≥ 31536000; includeSubDomains`.
  - `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY` (or `frame-ancestors` CSP directive), `Referrer-Policy: strict-origin-when-cross-origin`.
  - `Permissions-Policy` restricts camera/mic/geolocation if not used — reduces attack surface.
  - Headers applied on HTML responses at minimum — some deployments forget the middleware scope.
- **Suggest (if absent)** — offer a `next.config.js` `headers()` block with a conservative baseline, then iterate per app. Warn: CSP without `nonce` breaks inline scripts — test in report-only mode first.

---

## R8. Analytics consent / cookie handling

- **Detect** — cookie banner library (`react-cookie-consent`, `cookiebot`, custom), `Consent-Mode` integration with GA4 / GTM, conditional loading of analytics scripts.
- **Check (if present) AND the app serves EU / UK / CA users** —
  - Analytics scripts do **not** load before consent — not just "don't track, but still load." Google Consent Mode v2 or a hard gate.
  - Categories distinct: strictly-necessary (always on), functional, analytics, marketing — user can opt into subsets.
  - Choice persisted (cookie) and honoured across sessions.
  - Withdraw consent path visible and functional — required by GDPR.
- **Suggest (if absent) AND the app is consumer-facing AND EU/UK/CA traffic is non-zero** — offer a consent flow. For B2B behind SSO with a DPA in place, consent banners are usually not required — confirm with the user before adding noise.

---

## R9. Core Web Vitals budgets

- **Detect** — `@next/third-parties`, Web Vitals reporting hook (`useReportWebVitals`), Lighthouse CI config, Vercel Analytics / Speed Insights.
- **Check (if present)** —
  - Targets documented: LCP < 2.5s, INP < 200ms, CLS < 0.1 (Google "good" thresholds).
  - Reported from real users, not just synthetic Lighthouse runs — field data beats lab data.
  - Regression alerts wired — new release shouldn't silently worsen LCP by 500ms.
  - Route-level breakdown, not just site-wide — one slow route can hide under a fast average.
- **Suggest (if absent)** — offer `useReportWebVitals` piped to the existing analytics platform. Warn: an app that degrades LCP by 500ms per release will be ranked below competitors in search within a quarter.

---

## R10. Env-aware logging (server-side)

- **Detect** — logger configuration that varies by `NODE_ENV` / `process.env.LOG_LEVEL`, `pino` / `winston` / Next.js built-in logger setup.
- **Check (if present)** —
  - Log level env-driven (`LOG_LEVEL`), not hardcoded.
  - Format differs by env: structured JSON in prod (parseable by Vercel Logs, Datadog, Loki), pretty in dev.
  - Sensitive fields **redacted at the logger layer**: `authorization`, `cookie`, `password`, `token`, full session objects. Not sprinkled at call sites.
  - Stack traces in dev; prod responses suppress them (never leak to HTTP bodies), but logs keep them.
  - Request bodies not logged in prod by default — PII risk.
- **Suggest (if absent)** — offer `pino` with an env-driven config factory and a redaction list. Warn: `console.log` with user data in prod is both a privacy incident and a log-bill problem at scale.

---

## When to run this audit

- Before public launch or major release.
- When adding a new consent / privacy scope (new region, new data category).
- When CSP / headers are changed (CSP regressions break rendering silently).
- When cutting over from preview → production deployment.
- As part of the `pre-ship` quality gate, for changes that modify root layout, middleware, `next.config.js`, or service layer.

Not required for isolated component / copy / styling changes.
