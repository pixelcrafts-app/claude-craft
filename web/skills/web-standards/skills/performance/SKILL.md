---
name: performance
description: Apply when building or reviewing web apps for performance — Core Web Vitals, images, fonts, bundles, caching, SSR/hydration. Auto-invoke when touching build config, image handling, or data fetching.
---

## Core Web Vitals Targets

- LCP (Largest Contentful Paint): ≤2.5s (good), ≤4s (needs improvement), >4s (poor)
- CLS (Cumulative Layout Shift): ≤0.1 (good), ≤0.25 (needs improvement)
- INP (Interaction to Next Paint): ≤200ms (good), ≤500ms (needs improvement)
- FCP (First Contentful Paint): ≤1.8s target
- TTFB (Time to First Byte): ≤800ms target

Measure in field conditions (Chrome UX Report), not just local dev.

## Images

- Every `<img>` has explicit `width` and `height` attributes to prevent CLS.
- Lazy-load all below-the-fold images (`loading="lazy"`).
- Hero/LCP images: `loading="eager"`, `fetchpriority="high"`, preloaded in `<head>`.
- Use WebP/AVIF with JPEG/PNG fallback.
- Serve at display size — never load a 2000px image for a 400px slot.
- Alt text on all images; use empty `alt=""` for decorative images.

## Fonts

- `font-display: swap` or `optional` — never `block`.
- Preload critical fonts in `<head>` with correct `crossorigin` attribute.
- Subset fonts to character sets actually used.
- Maximum 2 typeface families per project.

## JavaScript Bundles

- Route-level code splitting — each route loads its own chunk.
- Third-party scripts: `defer` or `async` — never block render.
- Unused dependencies audited and removed before ship.
- Bundle size budget: initial JS ≤200KB gzipped, per-route ≤100KB gzipped.

## Caching

- Static assets: `Cache-Control: public, max-age=31536000, immutable` (with content hash in filename).
- API responses: appropriate `max-age`, `stale-while-revalidate` where applicable.
- HTML: `Cache-Control: no-cache` (validate on every request).

## SSR/Hydration (Next.js/Nuxt/etc.)

- Avoid hydration mismatches — server and client must produce identical initial HTML.
- Use streaming where supported — do not block the entire page on slow data.
- Avoid `useEffect` for data that can be server-rendered.
