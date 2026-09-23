# Form validation

## Intent
Telling a user a field is wrong, at a moment when that is useful. Validation is a conversation with a
tempo: silent while they are typing a field for the first time, corrective once they have left it,
exhaustive on submit. The failure mode this pattern guards is a form that shouts at a half-typed email
address and then quietly refuses to submit for a reason it never showed.

## Widgets
`EdenInput` and the field wrappers exercised by the inputs gallery
(`lib/dev_app/screens/inputs_screen.dart`, which drives `errorText` and a validator).
`story:inputs/interactive` is the knob-driven story for the field states;
`story:field/field` and `story:autofill/login-form` cover field purpose and autofill behaviour, which
interact with validation because an autofilled value arrives without a keystroke.

## States
- **pristine** — never focused, never edited. No error, no success mark.
- **editing** — focused and being typed into. Existing errors may clear here; new ones do not appear.
- **invalid, after blur** — the field has been left and its value does not validate.
- **invalid, after submit** — every failing field is marked at once and the first is scrolled to.
- **valid** — validated without an error; marked only where absence of an error is ambiguous.
- **disabled / read-only** — not validated at all, and not reported as an error on submit.

## Interaction rules
- `must_not: steal focus` — validation never pulls focus out of the field the user is typing in. On
  submit, focus moves once, to the first failing field, and only because the user asked to submit.
- `must_not: fire twice per activation` — a submit press runs the submit path once. Double-firing a
  submit is how duplicate records are created, and a validator that re-runs the submit on its own
  completion is the usual cause.
- `must_not: change route` — a failed validation keeps the user on the form with their input intact. A
  form that navigates away on failure has discarded work.
- `must_not: lose selection` — re-validating does not reset a dropdown, re-sort an option list, or
  discard a multi-select. The user's other answers survive one field being wrong.
- `must_not: replace loaded content with a spinner` — an in-flight async validation (uniqueness checks,
  address lookups) shows progress on the field, not over the form.

## Breakpoints
Error text renders below its field at every width and is never moved into a tooltip, a snackbar, or a
summary banner on narrow viewports — those detach the message from the field it is about. Multi-column
forms collapse to one column below the form breakpoint; the tab order follows the visual order at both
widths, not the declaration order at one of them.

## Content
Error text says what is wrong and what a correct value looks like: "Enter a date on or after today",
not "Invalid". It names the constraint, never the regular expression. Required-ness is stated on the
field before submit, not discovered by submitting.

## Accessibility
- `must_not: render an unlabelled tappable` — every field has a persistent visible label. A placeholder
  is not a label; it disappears exactly when the user needs it.
- `must_not: render below the tap target floor` — checkboxes, radios, steppers and the affordances
  inside a field (clear, reveal password, date picker) meet 48dp/44pt. A 20×20 icon button inside a
  text field is the same defect as the shell's 20×20 collapse control.
- `must_not: nest semantics without a container` — a field's inner affordance addressed by
  `identifier` needs `container: true`, or its annotation merges into the field's node and the
  identifier is not published.
- Error text is associated with its field so it is announced on focus, not only rendered near it. Error
  state is never communicated by colour alone.
