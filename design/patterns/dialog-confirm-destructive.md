---
id: dialog-confirm-destructive
---
# Destructive confirm dialog

## Intent
The last chance to not do the irreversible thing. A confirm dialog is worth the interruption only when
the action cannot be undone; used for anything reversible it trains the user to dismiss dialogs without
reading them, which is how the one that mattered gets dismissed too.

## Widgets
The overlay components exercised by the overlays gallery — `story:overlays/all` for the full set and
`story:overlays/interactive` for the knob-driven dialog, which is where this library's confirm and
destructive variants are demonstrated today. There is no dedicated `EdenConfirmDialog` widget yet; the
rules below bind the composition rather than a single class.

## States
- **idle** — dialog open, destructive action not yet pressed, cancel focused.
- **confirming** — the action is in flight; both buttons are disabled and progress is shown in place.
- **failed** — the action failed; the dialog stays open with the error, so the user does not have to
  re-derive what they were doing.
- **succeeded** — the dialog closes and the surface beneath reflects the change.

## Interaction rules
- `must_not: default to the destructive action` — cancel holds initial focus, cancel is what Enter
  triggers, and Escape cancels. The destructive button is reachable in one deliberate move and never in
  one reflexive one.
- `must_not: destroy data without confirmation` — the confirm affordance names the object and the
  consequence. For a bulk target it names the count, and for an unrecoverable target it requires a
  second, typed confirmation rather than a second button.
- `must_not: fire twice per activation` — the confirm button disables on press. A double-tapped confirm
  must not issue two deletes, and a dialog dismissed while its action is in flight must not leave that
  action to complete unobserved.
- `must_not: navigate on close` — dismissing the dialog returns the user exactly where they were.
  Cancel is not a route change, and a dialog that pops a screen on cancel has punished the user for
  declining.
- `must_not: change route` — on success the surface beneath updates in place where it can. Bouncing the
  user to a list after a delete is acceptable only when the record they were on no longer exists.
- `must_not: steal focus` — while the dialog is closing, focus returns to the control that opened it,
  not to the top of the page.

## Breakpoints
Centred dialog above the breakpoint; below it the same content may present as a bottom sheet, but the
button order, the default, and the Escape behaviour do not change with the presentation. A destructive
action must not become the wider, more thumb-reachable button just because the layout changed.

## Content
The title states the action and the object: "Delete invoice 1042?". The body states what is lost and
whether it can be recovered. The confirm button repeats the verb — "Delete invoice" — never "OK" or
"Yes", because a user skimming only the buttons must still be able to tell which one destroys.

## Accessibility
- `must_not: render an unlabelled tappable` — the close affordance in the dialog corner has a label;
  an unlabelled 56×56 tappable is exactly the defect the oracle found in `EdenMobileLayout`.
- `must_not: render below the tap target floor` — dialog buttons and the corner close control meet
  48dp/44pt. A 20×20 close glyph is the shell's collapse-control defect in a new place.
- `must_not: nest semantics without a container` — the confirm and cancel controls are addressed by
  `identifier` in tests and drivers; without `container: true` those identifiers are not published at
  all on Flutter 3.41.9.
- Focus is trapped inside the dialog while it is open, and the surface beneath is made inert to both
  pointer and assistive technology — an "inert" backdrop that only blocks taps still lets a screen
  reader wander into the content behind the dialog.
