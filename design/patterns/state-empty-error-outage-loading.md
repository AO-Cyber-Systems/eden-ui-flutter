---
id: state-empty-error-outage-loading
---
# Empty, error, outage and loading states

## Intent
Four different reasons a surface has nothing to show, rendered four different ways. "No records exist
yet", "your filter matched nothing", "the request failed", and "the request has not finished" are
distinct facts, and collapsing them into one grey illustration is the single most common way a
production outage reaches the user disguised as a working screen.

## Widgets
_No implementing widget in this library yet — wave 1's story scope is the shell widgets._ The rules
are written down here because every Surface Spec in W1b must declare these states by name, and the
state matrix the oracle captures (populated / empty / error / loading / overflow / narrow) is derived
from this list.

## States
- **loading, first paint** — nothing has ever been rendered; a skeleton or spinner is correct.
- **loading, refresh** — content is already on screen; it stays on screen.
- **empty, genuinely** — the query succeeded and the result set is empty. Offers the action that
  creates the first record.
- **empty, by filter** — the query succeeded and the *filter* excluded everything. Offers to clear the
  filter, and says what the filter was.
- **error** — the request failed for a reason attributable to this request. Offers a retry.
- **outage** — a dependency is unreachable. Says so, says what is affected, and does not offer an
  action that cannot succeed.

_no story yet — wave 1 story scope is the shell widgets_

## Interaction rules
- `must_not: render an empty state for a failed load` — a failed or unreachable dependency renders the
  error or outage state. A loop that skips unresolvable records and renders the survivors turns an
  outage into a convincing "you have no orders", which reads to the user and to a screenshot as a
  working screen. This is the rule this pattern exists for.
- `must_not: replace loaded content with a spinner` — a refresh keeps the current content visible and
  shows progress in the chrome. Tearing the list down to a spinner loses scroll position and reads as
  data loss.
- `must_not: fire twice per activation` — a retry button issues exactly one retry per press and
  disables itself while that retry is in flight.
- `must_not: steal focus` — arriving at an error state does not pull focus to the retry button; a user
  mid-keystroke elsewhere keeps their focus.
- `must_not: change route` — an error never navigates the user somewhere else "to be helpful". It
  renders in place so the user can retry from where they are.

## Breakpoints
The same four states exist at every width. On narrow viewports the state body may lose its
illustration but never its explanatory sentence or its action — the sentence is the payload, the
illustration is decoration.

## Content
Empty-by-filter names the filter. Error names what failed and what to do. Outage names the dependency
in the user's language and gives a time or a status reference. No state text blames the user, and no
state text is a bare "Something went wrong" — that sentence is indistinguishable across all three
failure modes and makes the surface undiagnosable from a screenshot.

## Accessibility
- `must_not: render an unlabelled tappable` — retry, clear-filter and create-first-record affordances
  carry labels that name the thing they act on.
- `must_not: render below the tap target floor` — the single action in an otherwise empty surface is
  still a 48dp/44pt target; being large and centred is not the same as being large enough.
- A transition into error or outage is announced to assistive technology; a silent swap from spinner to
  error leaves a screen-reader user waiting indefinitely.
- Loading state exposes a busy status rather than only an animated image, so the fact of progress does
  not depend on seeing motion.
