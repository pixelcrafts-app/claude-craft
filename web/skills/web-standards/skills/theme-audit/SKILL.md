---
name: theme-audit
description: Verify theme completeness — every themeable value uses tokens, light and dark are independently designed, no hardcoded values bleed through, SSR hydration flash prevented, `color-scheme` set, every screen works in both themes. Use before shipping any theme-related change.
disable-model-invocation: true
argument-hint: [optional: scope — "app" | "components" | "<directory>"]
---

# Theme Audit — Web

Premium apps don't have "light mode" and "dark mode tolerable." They have two themes, each independently designed, each verified.

Runs in iteration-loop style — every rule explicitly evaluated, no sweep-and-skip.

---

## Step 0 — Load tokens

1. Read `design-tokens.md` if present (written by `/web-standards:extract-tokens`)
2. If absent, fall back to scanning `tailwind.config.*`, `app/globals.css`, and CSS vars in `:root` + `.dark`
3. If neither theme has any tokens, stop and tell the user to run `/web-standards:extract-tokens` first

---

## Step 1 — Token discipline (themeable values come from tokens)

For each rule, output `[RULE] PASS | FAIL` with file:line evidence.

**T1.1 — No hardcoded colors in `.tsx` / `.ts`**
```
rg "(?:#[0-9a-fA-F]{3,8}|rgba?\(|hsla?\()" --type tsx --type ts
```
Every match not inside a comment is a FAIL. Acceptable: `currentColor`, `transparent`, `inherit`, CSS vars.

**T1.2 — No hardcoded colors in CSS outside of theme declarations**
```
rg "(?:#[0-9a-fA-F]{3,8}|rgba?\()" --type css --glob '!**/globals.css' --glob '!**/theme*.css'
```

**T1.3 — Every shadow uses a token**
```
rg "box-shadow:" --type css --type tsx
```
Match any value that's not `var(--shadow-*)` or a Tailwind token alias → FAIL.

**T1.4 — Every radius uses a token**
Grep for inline `border-radius:` with numeric values in CSS, and `rounded-[...]` arbitrary in Tailwind.

**T1.5 — Every font-size uses a scale step**
Grep `text-[...]` arbitrary in Tailwind; any `font-size:` with numeric in CSS outside theme.

**T1.6 — Every spacing uses a scale step**
```
rg "(?:p|m|gap|space|inset)-\[[0-9]+(?:px|rem)\]" --type tsx
```

---

## Step 2 — Semantic naming (tokens describe role, not value)

**T2.1 — No value-named tokens used in components**
```
rg "(?:--blue-500|--gray-100|--red-500)" --type tsx --type css
```
Token names like `--primary`, `--muted-foreground`, `--border-subtle` are correct. Value names like `--blue-500` leak into components → FAIL.

**T2.2 — Token prefix consistent**
All tokens share one prefix (`--app-*`, no prefix, or project-specific). Mixed prefixes = token lineage broken.

---

## Step 3 — Light / dark parity

**T3.1 — Every token defined in `:root` has a `.dark` counterpart**
Parse both blocks. Set-diff keys. Any token in one block but not the other = FAIL.

**T3.2 — Dark mode is not a computed invert**
Heuristic: if every dark value is `100% − light value` (for HSL lightness, or exact RGB invert), that's a FAIL — dark was not independently designed.

**T3.3 — Contrast verified in both modes**
For every fg/bg token pair used in components, compute contrast in both modes. Both must meet threshold (body 4.5:1, UI 3:1). Failures listed with evidence.

**T3.4 — Images with baked-in contrast have theme variants**
```
rg "<img|next/image" --type tsx -A 3 | rg "src="
```
Any `src` pointing to a PNG/JPG with visible chrome (logos on white, screenshots with light UI) needs a dark counterpart — flag for human check.

**T3.5 — Third-party embeds theme correctly**
`iframe`, `<Map>`, `<Stripe>`, `<Chart>` components often need explicit theme prop. Flag embeds without theme prop for human check.

---

## Step 4 — `color-scheme` CSS property

**T4.1 — `color-scheme` declared on `:root` or per theme class**
Without it, native form controls (checkbox, radio, date-picker, scrollbar) flash light in dark mode.

Check:
```
rg "color-scheme:" --type css
```
Must have either `color-scheme: light` on `:root` + `color-scheme: dark` on `.dark`, OR `color-scheme: light dark` on `html`.

---

## Step 5 — SSR hydration flash (Next.js App Router)

Light-mode flash before stored theme applies is a premium-killing bug.

**T5.1 — `suppressHydrationWarning` on `<html>`**
Check `app/layout.tsx` for `<html lang="en" suppressHydrationWarning>`.

**T5.2 — Theme script runs blocking, before first paint**
Either:
- `next-themes` `<ThemeProvider>` wraps the tree with `attribute="class"`, OR
- Inline `<Script>` in `<head>` reads cookie/localStorage and sets `html.classList` synchronously

Both use an inline blocking script — confirm present.

**T5.3 — Initial theme class rendered server-side**
If theme is stored in cookie, the `<html className>` should reflect the cookie on first render. Check server component reads `cookies()` and sets class.

**T5.4 — Reduced-motion + preferred-color-scheme fallback**
If user has no preference stored, honor `prefers-color-scheme` — don't force one default.

---

## Step 6 — Theme switch coverage

Toggle theme, walk every route. For each discovered screen:

**T6.1 — Backgrounds change**
**T6.2 — Text colors change**
**T6.3 — Borders change**
**T6.4 — Shadows change or adapt**
**T6.5 — Form inputs themed (not browser-default)**
**T6.6 — Icons use `currentColor` (inherit theme)**
**T6.7 — Charts / data-viz themed**
**T6.8 — Skeleton shimmer visible in both modes**

Any screen where a rule fails → FAIL with file:line.

---

## Step 7 — Multi-theme readiness (optional — premium)

**T7.1 — High-contrast theme token set present**
Declared via extra class or `prefers-contrast: more` media query.

**T7.2 — Forced-colors mode**
```
rg "forced-colors" --type css
```
Premium sites honor Windows High Contrast mode. Check.

**T7.3 — `prefers-reduced-transparency` fallback (for glassmorphism apps)**
If any component uses `backdrop-filter: blur`, check for a `@media (prefers-reduced-transparency: reduce)` opaque fallback.

---

## Step 8 — Aggregate

```
Theme audit — <scope>

Token discipline:      X PASS / Y FAIL
Semantic naming:       X PASS / Y FAIL
Light/dark parity:     X PASS / Y FAIL
color-scheme:          PASS | FAIL
SSR hydration:         X PASS / Y FAIL
Switch coverage:       X screens PASS / Y FAIL
Multi-theme (opt):     X PASS / Y FAIL

Critical failures:
  [list — hydration flash, contrast misses, computed-invert dark mode]

Polish failures:
  [list — forced-colors, reduced-transparency, third-party embeds]

Verdict:
  - 0 critical → THEMES SHIP
  - any critical → BLOCK
```

---

## Fix loop (if `--fix`)

1. Fix every FAIL — smallest change per rule
2. Re-run Step 1 from top
3. Loop until zero FAILs
4. Report what changed

Fixes **never** invent token values. If a hardcoded color should become a token but the token doesn't exist, ask the user for the value or skip with `NEEDS_USER_INPUT`.

---

## Scope boundaries

This skill does not:

- Decide which colors go in dark mode — independent design is the user's job
- Rewrite dark mode values when `extract-tokens` detected computed-invert (flags only)
- Invent tokens where drift was found
- Refactor themes architecture beyond what rules FAILed

When in doubt, ask — don't silently choose a default.

---

## Tradeoffs

- **Slow on large codebases** — grep passes across every `.tsx`/`.css` file. Scope with argument: `theme-audit components/ui` faster than full repo.
- **Contrast check is heuristic** — token pairing is inferred from usage; borderline cases may need human review with axe/Lighthouse.
- **Computed-invert detection** — heuristic math; designer who legitimately chose inversion can override and document.
- **Switch coverage needs live screens** — static audit catches most, but hydration bugs and layout shifts often only surface in a real browser. Run static first, then toggle the app.
