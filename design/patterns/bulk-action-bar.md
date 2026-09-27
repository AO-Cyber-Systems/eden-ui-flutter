---
id: bulk-action-bar
---
# Bulk action bar

## Intent
A contextual bar that appears once a multi-select has at least one member, offering actions that apply
to the whole selection. It exists to make "do this to these forty things" a single gesture, which is
precisely why its failure modes are expensive: a bulk action that half-succeeds, or that loses track of
what was selected, damages forty records instead of one.

## Widgets
_No implementing widget in this library yet — wave 1's story scope is the shell widgets._
`story:selection/table-copy` and `story:selection/region` are the nearest shipped behaviour — they
cover selection semantics and copy-out of a selected region, not the action bar itself.

## States
- **hidden** — nothing selected. The bar occupies no space and no layout is reserved for it.
- **one selected** — the bar is present and names the count.
- **many selected** — the bar names the count and may disable actions that are invalid for part of the
  selection.
- **all-on-page selected, more exist** — the bar distinguishes "40 selected" from "select all 1,240".
- **action in flight** — the bar is busy; the selection is frozen.
- **action partially failed** — some records succeeded, some did not.

_no story yet — wave 1 story scope is the shell widgets_

## Interaction rules
- `must_not: lose selection` — paging, sorting, filtering or refreshing the underlying list keeps the
  selection. A selection that silently shrinks to what is currently on screen means the user's next
  bulk action hits a different set than the one they counted.
- `must_not: report a partial failure as success` — if 38 of 40 succeed, the result says so and names
  the two that did not. A success toast over a partial failure is the bulk-action equivalent of an
  outage rendering as an empty state, and it is unrecoverable because the user has already moved on.
- `must_not: fire twice per activation` — every action in the bar is single-fire and disables itself
  while in flight. A doubled bulk delete is a doubled blast radius.
- `must_not: destroy data without confirmation` — destructive bulk actions route through the confirm
  dialog (see `design/patterns/dialog-confirm-destructive.md`) and the confirmation states the count.
- `must_not: cover sibling hit rects` — the bar docks; it does not float over the last rows of the
  list. A bar overlapping row hit rects makes the rows underneath unselectable and untestable.
- `must_not: steal focus` — the bar appearing does not move focus out of the list the user is
  selecting in.

## Breakpoints
Above the breakpoint the bar docks to the top or bottom of the list region. Below it, the bar takes the
full width and actions beyond the first two collapse into an overflow menu — never into a horizontally
scrolling strip of icons, which hides actions with no affordance that they exist. The selection count
is never the thing that gets truncated.

## Content
The bar leads with the count and the noun: "12 invoices selected". Actions are verbs. The clear-
selection affordance is always present and always says what it clears.

## Accessibility
- `must_not: render an unlabelled tappable` — icon-only bulk actions carry labels that include the
  count: "Delete 12 invoices". "Delete" alone is not enough when the target is invisible to a screen
  reader.
- `must_not: render below the tap target floor` — bar actions and per-row checkboxes meet 48dp/44pt.
  Row checkboxes are the densest controls on the surface and the most likely to fail this.
- `must_not: nest semantics without a container` — actions addressed by `identifier` inside the bar
  need `container: true`. The penalty is SDK-dependent — on Flutter 3.41.9 the nested identifier was
  dropped outright, on 3.47.4 it publishes its own node — so `container: true` is what makes the
  boundary explicit across the range eden-ui-flutter declares (`flutter: ">=3.27.0"`) instead of
  SDK-dependent.
- The appearance of the bar and any change in the selection count is announced, so a screen-reader user
  knows the action set changed and what it now applies to.
