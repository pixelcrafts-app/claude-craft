---
name: i18n
description: Apply when implementing or reviewing internationalization in a web project. Conditional — active when craft.json features.i18n is true, OR when next-i18next/react-i18next/i18next detected in package.json OR locales/ directory exists at project root. Not enforced on projects without i18n declared or detected.
---

# Web i18n

**Activation (either condition):**
1. `craft.json features.i18n: true`
2. `next-i18next`, `react-i18next`, or `i18next` in `package.json` dependencies OR `locales/` directory at project root

When not declared in craft.json but trigger detected: emit `INFO` in verification, do not enforce as FAIL.

---

## §I1 No Hardcoded User-Visible Strings

All user-visible text in JSX/TSX must reference a translation key — not a hardcoded string.

```tsx
// ❌ Hardcoded
<p>Welcome back</p>

// ✓ i18n key
<p>{t('auth.welcome_back')}</p>
```

Strings that are never user-visible (console.log, error codes, test fixtures) are exempt.

Translation keys must follow a consistent namespace format: `namespace.section.key`. No flat key names (`welcomeBack`) — they don't scale.

---

## §I2 Library Plural Rules

Pluralization uses the i18n library's plural rules — not manual conditionals.

```tsx
// ❌ Manual
const label = count === 1 ? 'item' : 'items';

// ✓ i18n plural rule
t('cart.items', { count })  // library handles plural form per locale
```

Manual `count === 1 ? singular : plural` only handles English. Most languages have 3–6 plural forms. Arabic has 6. Only the i18n library handles this correctly.

---

## §I3 RTL Layout Testing

Any project with at least one RTL locale (`ar`, `he`, `fa`, `ur`) must test layout in RTL mode before shipping.

RTL requirements:
- `dir="rtl"` set on `<html>` for RTL locales
- CSS logical properties used (`margin-inline-start` not `margin-left`) or explicit RTL overrides
- Flex/grid layouts must not break when direction is reversed
- Icons that imply direction (arrows, chevrons) must be mirrored in RTL

---

## §I4 Locale Routing (Next.js)

When using Next.js with multiple locales:
- `next.config.js i18n` block declares all supported locales and a default
- All page-level data fetching passes the active locale to API calls
- `next/link` with `locale` prop is used for locale-switching links — never manual URL construction
- `NEXT_LOCALE` cookie is set on locale switch for persistence across sessions

---

## Verification Checklist

When i18n skill is active:

- `§I1` — grep for JSX string literals not wrapped in `t()`: `>[A-Z][a-z]` pattern in `.tsx` files; flag any user-visible hardcoded text
- `§I2` — grep for `=== 1 ?` in components handling counts; flag manual pluralization
- `§I3` — if RTL locales present: confirm `dir` attribute handling and logical CSS properties
- `§I4` — if Next.js: confirm `i18n` config in `next.config.js`
