---
name: universal-rules
description: Apply when editing any code file. Universal rules that apply regardless of stack. Checked via §N.M rule IDs.
---

# Rules

## §1 Security — ALWAYS-MANDATORY

**These rules apply to every file touched in every task. No scope boundary, no craft.json opt-out, no project configuration suppresses them. No exceptions.**

§1.1 — No credentials, secrets, API keys, or tokens hardcoded in source. Use environment variables or a secrets manager.
§1.2 — Validate all input at system boundaries (user input, external APIs, file reads). Do not trust data that crossed a network or process boundary.
§1.3 — Never suppress or swallow authentication or authorization errors. Surface them explicitly.

## §2 Testing

§2.1 — Critical paths (auth, payment, data mutation) must have tests. No exception for "will add later."
§2.2 — Tests must assert behavior, not implementation. Changing internal structure without changing behavior must not break tests.
§2.3 — Test failures are blockers. Do not ship with known failing tests.

## §3 Observability

§3.1 — Errors must be logged with enough context to reproduce: input shape, relevant state, stack trace.
§3.2 — Log levels must be intentional. Debug logs must not appear in production paths.
§3.3 — Health and readiness signals must exist for any long-running process.

## §4 Engineering

§4.1 — No duplicate logic. If the same operation appears twice, extract it.
§4.2 — Names must state intent. Abbreviations are only acceptable if universally understood in the domain.
§4.3 — Comments explain WHY, not WHAT. Code that needs a comment explaining what it does should be renamed or restructured instead.

## §5 Design tokens

§5.1 — In token-managed projects, do not hardcode design values (colors, spacing, radius, shadow, typography). Reference tokens.
§5.2 — Token names must be semantic (what it means, not what it looks like). `color-action-primary` not `blue-500`.
