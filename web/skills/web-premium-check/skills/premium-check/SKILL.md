---
name: premium-check
description: Audit a component or page against the premium web craft standard
disable-model-invocation: true
argument-hint: [component-file-path]
---

# Premium Craft Audit (Web)

Audit `$ARGUMENTS` against the premium web standard. Read the file, then evaluate every point below.

## Design System Discipline
- [ ] All colors reference CSS variables or Tailwind theme tokens — zero hardcoded hex/RGB
- [ ] All text uses the typography scale — zero arbitrary font sizes
- [ ] All spacing uses Tailwind scale — zero arbitrary values like `p-[13px]`
- [ ] All radii use Tailwind tokens — zero inline border-radius values
- [ ] Icon sizes are consistent with the system

## Interaction Quality
- [ ] Every interactive element has a hover state
- [ ] Focus rings are visible and styled for keyboard navigation
- [ ] Buttons disable and show loading state during async operations
- [ ] Destructive actions require confirmation
- [ ] Click/tap targets are minimum 44px

## State Design
- [ ] Loading state: skeleton matching final layout shape
- [ ] Empty state: icon/illustration + inviting message + single clear action
- [ ] Error state: specific message + retry action (never "Error occurred")
- [ ] Transitions between states are smooth, not hard cuts

## Visual Polish
- [ ] Squint test passes — hierarchy is clear when blurred
- [ ] Consistent alignment across all elements
- [ ] Consistent spacing rhythm throughout the component
- [ ] Dark mode is independently designed, not just inverted

## Responsive
- [ ] Works at 320px mobile width
- [ ] Works at 768px tablet width
- [ ] Works at 1440px+ desktop width
- [ ] No horizontal overflow at any breakpoint
- [ ] Touch targets sufficient on mobile

## Accessibility
- [ ] Semantic HTML elements used (not div soup)
- [ ] Text contrast ratio: 4.5:1 minimum
- [ ] ARIA labels on interactive elements
- [ ] Keyboard navigable
- [ ] `prefers-reduced-motion` respected

## Report
```
File: [path:line]
Score: [X/6 categories pass]
Critical Issues:
  - [issue with fix suggestion]
Polish Issues:
  - [issue with fix suggestion]
Verdict: SHIP / NEEDS WORK
```
