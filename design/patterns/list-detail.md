# List–detail

## Intent
A list of records beside (or in front of) the detail of the one selected. Wide viewports show both
panes at once and selection is a pane swap; narrow viewports show one at a time and selection is a
push. The list is the source of truth for *which* record is current — the detail pane never selects on
the list's behalf.

## Widgets
_No implementing widget in this library yet — wave 1's story scope is the shell widgets
(`EdenDesktopLayout`, `EdenMobileLayout`, `EdenNavItem`)._ The pattern is written down now because
eden-biz and aodex both build list–detail surfaces on top of the shell, and their Surface Specs
inherit these rules before a shared widget exists.

## States
- **empty list** — no records match; the detail pane shows the empty affordance, not a stale record.
- **list with nothing selected** — valid on wide viewports; the detail pane invites a selection.
- **list with a selection** — exactly one row is marked current in the list *and* rendered in detail.
- **selected record deleted or filtered out** — the row is gone; the detail pane must resolve to the
  empty affordance rather than keep rendering a record the list no longer contains.
- **loading a detail while the list stays interactive.**

_no story yet — wave 1 story scope is the shell widgets_

## Interaction rules
- `must_not: lose selection` — refreshing the list, re-sorting it, or changing a filter that still
  matches the current record keeps that record selected and in view. Only a filter that excludes it may
  clear it, and then the detail pane clears with it.
- `must_not: fire twice per activation` — tapping the already-selected row is a no-op, not a second
  selection event and not a second detail fetch.
- `must_not: steal focus` — selecting a row does not move focus into the detail pane on wide
  viewports; a keyboard user arrowing down the list must not be teleported out of it. On narrow
  viewports, where selection is a push, focus follows the push.
- `must_not: replace loaded content with a spinner` — while the detail of a newly selected record
  loads, the list stays rendered and interactive. A full-surface spinner over a list the user is
  already reading is a regression, not a loading state.

## Breakpoints
Two panes above the split breakpoint, one below. Crossing the breakpoint with a record selected lands
on the detail, not on the list — dropping the user back to the list loses their place. Crossing back
with nothing selected shows the list, not an empty detail pane.

## Content
Rows lead with the field the user searches by, not with an internal id. Secondary metadata is at most
one line. The detail pane's title repeats the row's primary field verbatim so the user can see the
selection matched what they tapped.

## Accessibility
- `must_not: render below the tap target floor` — list rows are tap targets and meet 48dp/44pt, even in
  a dense table rendering.
- `must_not: render an unlabelled tappable` — per-row affordances (overflow menus, checkboxes, quick
  actions) carry labels that name the row, not just the action: "Delete invoice 1042", not "Delete".
- `must_not: cover sibling hit rects` — row hit rects stay disjoint; a row whose hit rect spills into
  its neighbour makes keyboard and screen-reader ordering ambiguous.
- Selection is announced as a selected state on the row, not as a separate live-region message.
