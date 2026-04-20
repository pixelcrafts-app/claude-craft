---
name: premium-check
description: Audit a screen or widget against the premium mobile craft standard
disable-model-invocation: true
argument-hint: [screen-file-path]
---

# Premium Craft Audit

Audit `$ARGUMENTS` against the premium mobile standard. Read the file, then evaluate every point below.

## Design System Discipline
- [ ] All colors reference the design system — zero hardcoded hex/RGBA
- [ ] All text uses the typography scale — zero inline font sizes or TextStyle
- [ ] All spacing uses named constants — zero magic number padding/margin
- [ ] All radii use named constants — zero inline BorderRadius values
- [ ] Icon sizes are consistent with the system (standard sizes only)

## Interaction Quality
- [ ] Every tappable element has a minimum 48px touch target
- [ ] Tap feedback is immediate (scale, color change, or ripple)
- [ ] Buttons disable and show loading state during async operations
- [ ] Destructive actions require confirmation
- [ ] Swipe-to-dismiss has undo capability where appropriate

## State Design
- [ ] Loading state: skeleton/shimmer matching final layout shape
- [ ] Empty state: illustration or icon + inviting message + single clear action
- [ ] Error state: specific message + retry action (never "Error occurred")
- [ ] Transition between states is animated, not a hard cut

## Visual Polish
- [ ] Squint test passes — hierarchy is clear when blurred
- [ ] No orphaned pixels — consistent alignment across all elements
- [ ] Consistent spacing rhythm throughout the screen
- [ ] Shadows/elevation follow the depth system (no arbitrary values)
- [ ] Safe area respected (notch, home indicator, system UI)

## Performance
- [ ] Lists over 20 items use virtualized builders (ListView.builder)
- [ ] Images load progressively (placeholder → blur → full)
- [ ] No unnecessary rebuilds — only changed widgets rebuild
- [ ] Controllers and subscriptions are properly disposed

## Accessibility
- [ ] Text contrast ratio: 4.5:1 minimum
- [ ] Semantic labels on interactive elements
- [ ] Doesn't rely on color alone to convey meaning
- [ ] Respects reduced motion settings

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
