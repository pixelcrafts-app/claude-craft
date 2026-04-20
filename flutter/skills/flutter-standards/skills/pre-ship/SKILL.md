---
name: pre-ship
description: Full quality gate checklist before marking any feature complete
disable-model-invocation: true
---

# Pre-Ship Quality Gate

Run this before declaring any feature or task complete.

## Step 1: Compile Check
Run `flutter analyze` in the project root.
- Must be zero errors AND zero warnings
- If any exist, fix them before proceeding

## Step 2: Data Pipeline Verification
For every data-related change in this task:
- Confirm source data exists and is accessible (DB published, API returns it)
- Confirm mapper handles the actual response shape (not assumed shape)
- Confirm model fields match mapper output
- Confirm provider exposes data correctly
- Confirm UI screen renders the data — read the screen file and trace the data binding

## Step 3: Screen Quality Audit
For every screen modified in this task:
- Loading state exists and matches final layout (skeleton, not spinner)
- Empty state is inviting with a clear action
- Error state provides guidance and retry
- All design system tokens used (no hardcoded values)
- Touch targets are 48px minimum
- Text has maxLines + overflow protection

## Step 4: Edge Cases
- What happens if the user has no internet?
- What happens if the API returns an empty list?
- What happens if the API returns an error?
- What happens if the user kills the app mid-operation?
- What happens on sign-out and sign-in with a different account?

## Step 5: Cross-Boundary Contracts
For every API call, env var, third-party SDK, or DB query touched in this task:
- [ ] Field names, types, and response shapes were verified against the source of truth (controller/DTO, schema, typings, `.env.example`) — not guessed
- [ ] Any assumption that couldn't be verified is surfaced to the user in the final response, not silently coded

## Step 6: Docs sync (only if this completes a feature or release — not mid-work)

If this change completes a feature, a release, or adds/removes a capability users will notice, invoke `core-hooks:docs-sync` to catch drift between the code and the docs:

- README reflects the current plugin count, version, and install snippet
- CHANGELOG has an entry for the new version
- ROADMAP moves shipped items out of "Next up"
- `docs/skills.md` lists every skill that actually exists
- Plugin and skill descriptions match the work they now do

Skip for single-file fixes or internal refactors with no user-facing surface change.

## Step 7: Checklist
Answer each honestly:
- [ ] I verified the UI renders REAL content, not placeholders
- [ ] I ran `flutter analyze` — zero errors, zero warnings
- [ ] Every screen I touched is screenshot-worthy
- [ ] No "remaining steps" or "TODO" items are left unfinished
- [ ] I did not add unrequested features or refactoring
- [ ] I did not guess any cross-boundary contract (API shape, env var, SDK method, DB column)

## Verdict
If all boxes are checked: task is complete.
If ANY box is unchecked: list what's remaining and do it.
