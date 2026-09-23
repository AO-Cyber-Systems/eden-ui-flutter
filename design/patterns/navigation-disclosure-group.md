---
id: navigation/disclosure-group
kind: disclosure-header
---
# Navigation disclosure group

## Intent
A navigation entry that owns child entries and can be opened or closed in place. Opening it reveals
its children in the rail; closing it hides them. It is a *view* gesture on the shell, not a selection
the host app makes — which is why `EdenDesktopLayout` owns the expanded-id set internally
(`_expanded`, alongside `_collapsed`) and emits no callback out for it. The host is told which item was
*selected*; it is never told which group was opened.

## Widgets
`EdenNavItem` with a non-empty `children` list, rendered by `EdenDesktopLayout`
(`lib/src/widgets/eden_layout/eden_desktop_layout.dart`, the `_expanded` set and the group-header row
around line 558). `EdenMobileLayout` does not render disclosure groups at all — see
`design/patterns/navigation-shell.md` for what happens to a group's children on mobile.

## States
- **collapsed** — header visible, children absent from the tree. `story:nav-item/expandable-collapsed`
- **expanded** — header visible, children rendered beneath it. `story:nav-item/expandable-expanded`
- **selected-child-hidden** — the group is collapsed while one of its hidden children is the selected
  route. The header carries the selection indicator on the child's behalf.

## Interaction rules
- `must_not: navigate on close` — collapsing a group is a disclosure gesture. It must not call
  `onNavigate`, must not clear the selected id, and must not push or pop a route. A user tidying the
  rail has not asked to go anywhere.
- `must_not: lose selection` — when a group collapses over the selected child, the selection survives
  and the header shows it. Re-expanding the group must restore the same child as selected, with no
  round-trip through the host.
- `must_not: fire twice per activation` *(inherited)* — the header row is one tap target. A tap must
  produce exactly one expand/collapse transition; a nested `InkWell` inside a `GestureDetector` on the
  same row is the usual cause of a doubled toggle and is not allowed.
- `must_not: cover sibling hit rects` *(inherited)* — the header's tap rect stops at its own row. This
  is the live constraint in this library: nav rows are laid out at a 42px pitch, so a naively enlarged
  48px hit rect overlaps the rows above and below and the oracle's semantics-disjointness rule flags
  it. Fix the row height, not the hit rect.

## Breakpoints
Disclosure groups exist on the desktop rail only. Below the rail/bar breakpoint the group header
disappears and its children are flattened into the bottom bar's item list (or dropped, if the bar is
already at capacity) — a group must never render as a bottom-bar tab that expands a sheet of children
on tap, because that gives the same entry two different meanings at two widths.

## Content
The header label names the group, not the action: "Reports", never "Show reports". Children are
labelled as destinations. A group with exactly one child is a mistake — render the child directly.

## Accessibility
- `must_not: render below the tap target floor` — the header row must meet 48dp (Android) and 44pt
  (iOS). The shipped rail row is 42px and currently fails both floors; this is a known, tracked defect
  of the shell, not a licence to lower the rule.
- `must_not: nest semantics without a container` — the expand/collapse affordance is addressed by
  `identifier`, and on Flutter 3.41.9 a nested `Semantics` without `container: true` merges into the
  enclosing node and the nested identifier is not published at all. Any inner `Semantics` on the header
  row must pass `container: true` or it does not exist to a test or a screen reader.
- The header exposes its expanded/collapsed state to assistive technology; a collapsed group hiding the
  selected child must still announce that it contains the current destination.
