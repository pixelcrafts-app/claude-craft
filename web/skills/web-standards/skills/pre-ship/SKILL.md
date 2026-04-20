---
name: pre-ship
description: Full quality gate checklist before marking any web feature complete
disable-model-invocation: true
---

# Pre-Ship Quality Gate (Web)

Run this before declaring any feature or task complete.

## Step 1: Lint Check
Run your project's lint command (e.g., `npm run lint`).
- Must be zero errors AND zero warnings
- If any exist, fix them before proceeding

## Step 2: Data Pipeline Verification
For every data-related change in this task:
- Confirm API client fetches correct data
- Confirm React Query hook uses correct query key and options
- Confirm component receives and renders the data
- Confirm loading/error/empty states are handled

## Step 3: Component Quality Audit
For every component modified in this task:
- Loading state: skeleton/shimmer matching final layout
- Empty state: inviting message with clear action
- Error state: specific message with retry
- All design system tokens used (no hardcoded hex, no arbitrary Tailwind values)
- Responsive across breakpoints (mobile → desktop)
- Dark mode works correctly

## Step 4: Edge Cases
- What happens if the API returns an empty list?
- What happens if the API returns an error?
- What happens if the user has no internet (offline / PWA)?
- What happens on slow network?
- What happens at 320px width? At 2560px?

## Step 5: Cross-Boundary Contracts
For every API call, env var, third-party SDK, or shared type touched in this task:
- [ ] Field names, types, and response shapes were verified against the source of truth (controller/DTO, OpenAPI spec, typings, `.env.example`) — not guessed
- [ ] Any assumption that couldn't be verified is surfaced to the user in the final response, not silently coded

## Step 6: Docs sync (only if this completes a feature or release — not mid-work)

If this change completes a feature, a release, or adds/removes a capability users will notice, invoke `core-hooks:docs-sync` to catch drift between the code and the docs:

- README reflects the current plugin count, version, and install snippet
- CHANGELOG has an entry for the new version
- ROADMAP moves shipped items out of "Next up"
- `docs/skills.md` lists every skill that actually exists
- Plugin and skill descriptions match the work they now do

Skip for single-component fixes or internal refactors with no user-facing surface change.

## Step 7: Checklist
Answer each honestly:
- [ ] I verified the UI renders REAL content, not placeholders
- [ ] Lint passes with zero errors, zero warnings
- [ ] Every component I touched is screenshot-worthy
- [ ] No "remaining steps" or "TODO" items are left unfinished
- [ ] Dark mode looks intentionally designed, not just "tolerable"
- [ ] Keyboard navigation works on all interactive elements
- [ ] I did not guess any cross-boundary contract (API shape, env var, SDK method, shared type)

## Verdict
If all boxes are checked: task is complete.
If ANY box is unchecked: list what's remaining and do it.
