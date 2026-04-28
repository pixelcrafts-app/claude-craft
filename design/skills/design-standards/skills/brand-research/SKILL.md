---
name: brand-research
description: Before designing for a specific brand — verify the product exists via search, then collect brand assets in priority order: logo → product imagery → UI screenshots → color → font. Prevents designing from false assumptions or generic placeholders. Applies to Web, iOS, Android, and any visual output.
origin: alchaincyf/huashu-design
---

# Brand Research

## Triggers

- User mentions a specific brand, product name, or company
- Designing marketing material, launch animations, or UI for an external product
- Any task where "which version / does this exist?" is relevant
- User provides vague reference ("make it look like Notion", "DJI-style")

---

## Step 0 — Verify facts before anything else (highest priority)

Any claim about a specific product — existence, release status, version, specs — must be verified via search **before** asking clarifying questions or starting design.

**Trigger conditions (any one):**
- Product name you don't have confirmed knowledge of
- Anything released in or after 2024
- Internal thought: "I think this is...", "probably not released yet", "I recall..."

**Hard rule:** Search first. Never assume. Never design from unverified facts.

```
WebSearch: "<product name> latest 2026"
WebSearch: "<product name> release date specs"
```

Read 1–3 authoritative results. Confirm: existence / release status / current version / key specs.

**Cost comparison:** 10-second search vs 2-hour rework from wrong assumptions.

**Banned phrases (stop and search instead):**
- "I think X hasn't been released yet"
- "X is probably version N"
- "X might not exist"

---

## Step 1 — Collect assets in priority order

Brand recognition comes from assets, not specs. Priority order by recognition impact:

| Priority | Asset | Required when |
|----------|-------|---------------|
| 1 | **Logo** (SVG / hi-res PNG) | Any brand, always |
| 2 | **Product imagery / renders** | Physical products (hardware, packaging) |
| 3 | **UI screenshots** | Digital products (apps, SaaS, websites) |
| 4 | Color values (HEX / RGB) | Supplementary |
| 5 | Font names | Supplementary |

**Rule:** Do not extract color + font while skipping logo and product imagery. Color without logo = unrecognizable. A CSS silhouette is not a product image.

Ask the user first:
```
For <brand>, which of these do you have?
1. Logo (SVG or hi-res PNG)
2. Product photos / official renders
3. App/UI screenshots
4. Color values or brand guidelines
5. Font names or brand guidelines PDF/link

Share what you have — I'll search for the rest.
```

---

## Step 2 — Search official channels

| Asset | Where to search |
|-------|----------------|
| Logo | `<brand>.com/brand`, `/press`, `/press-kit`; homepage inline SVG |
| Product imagery | Product detail page hero + gallery; official launch video stills; press releases |
| UI screenshots | App Store / Google Play listing; official website screenshots section |
| Colors | Homepage CSS / Tailwind config; brand guidelines PDF |
| Fonts | `<link rel="stylesheet">` on official site; Google Fonts; brand guidelines |

Fallback searches:
- Logo not found → `"<brand> logo SVG download"`, `"<brand> press kit"`
- Product image not found → `"<brand> <product> official renders"`, `"<brand> <product> product photography"`

---

## Step 3 — Validate before using

Before using any asset:
- Logo: confirm transparent background, not a compressed JPEG artifact
- Product image: confirm it's the correct product version (not an older model)
- UI screenshot: confirm it reflects the current app version

If quality is below usable threshold — ask the user, do not substitute with a generated placeholder without disclosure.

---

## Anti-patterns

| Wrong | Right |
|-------|-------|
| Extract color + font, skip logo | Collect logo first — it IS the brand |
| Use CSS/SVG silhouette as "product image" | Find the real product render or ask user |
| Assume product exists from memory | Search to confirm before designing |
| Design from "I think the brand colors are..." | Extract from official source |
| Use a generic placeholder labeled with the brand name | Honest gray box > wrong brand impression |
