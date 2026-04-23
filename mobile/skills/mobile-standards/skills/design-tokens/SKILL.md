---
name: design-tokens
description: Apply when auditing or documenting design token usage in a mobile app — color, typography, spacing, radius token completeness and naming. Auto-invoke when reviewing theme files, constants, or design system implementation.
---

## Token Completeness Audit

All categories must be fully defined before building screens:

- Colors: brand, semantic (primary, secondary, error, success, warning), surface levels, text levels, border
- Typography: scale (6–8 steps), line-heights per step, weights per step
- Spacing: named scale (xxs through xxxl), at least 8 steps on a 4px base
- Radius: named scale (xs through full), at least 5 steps
- Duration: named animation durations (instant, fast, normal, slow)
- Shadows/elevation: 3 levels maximum

## Token Naming Rules

- Names are semantic, not descriptive: `primary` not `blue500`, `error` not `red`.
- Surface hierarchy: `surface` < `surfaceVariant` < `surfaceContainer` (lighter = higher elevation in light mode).
- Never expose raw values in screens — always token names.
- Tokens in a single file per category — no scattered constants.

## Token Usage Audit

Flag these violations:

- Any hardcoded hex/RGBA color not in the token file
- Any inline TextStyle declaration not from the typography scale
- Any SizedBox/EdgeInsets with a value not in the spacing scale
- Any BorderRadius with a value not in the radius scale
- Any Duration literal not from the duration token

## Token Documentation

Each token file must include: token name, value, and intended use (1 line). Tokens without all three fields are incomplete.
