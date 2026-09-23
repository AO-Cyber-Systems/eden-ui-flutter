# Interaction patterns

Ten recurring interaction patterns, each written to the same seven headings — `## Intent`,
`## Widgets`, `## States`, `## Interaction rules`, `## Breakpoints`, `## Content`, `## Accessibility`,
in that order. The point of the fixed shape is that a reviewer can compare a surface against a *named
pattern* instead of against taste, and a W1b Surface Spec can inherit a pattern's rules instead of
restating them.

Rules are phrased in the **closed `must_not` vocabulary** at
[`../must_not_vocabulary.json`](../must_not_vocabulary.json) — see
[its README](../must_not_vocabulary.README.md). Every term completes "this control must_not …", and a
pattern using a term the vocabulary does not contain fails `test/design/patterns_test.dart`. The
vocabulary is mirrored by W1b at `devflow/schemas/must_not_vocabulary.json`, so adding a term is a
cross-repo change.

Do/don't examples are cited in prose as `story:<id>` tokens, resolved against the dev-app
`StoryRegistry`. A pattern citing an unregistered story id fails the same test, so the examples cannot
rot into references to stories that were deleted. Where wave 1 has no story for a pattern, the file
says so under its `## States` section rather than citing an id that does not exist.

DevFlow's `design-stack-flutter.md` points at this index; it extends DevFlow 2.7's design reference set
rather than forking it.

| Pattern | Intent |
| --- | --- |
| [navigation-disclosure-group](./navigation-disclosure-group.md) | A nav entry that opens and closes its children in place — a view gesture the shell owns, not a selection the host makes. |
| [navigation-section-caption](./navigation-section-caption.md) | A non-interactive label grouping rail entries: no icon, no tap target, no button role. |
| [navigation-shell](./navigation-shell.md) | One navigation model rendered two ways — desktop rail and mobile bottom bar — without forking the model. |
| [list-detail](./list-detail.md) | A list of records beside the detail of the selected one; two panes wide, one pane narrow. |
| [state-empty-error-outage-loading](./state-empty-error-outage-loading.md) | Four distinct reasons a surface has nothing to show, and why collapsing them hides outages. |
| [form-validation](./form-validation.md) | When to tell a user a field is wrong: silent while typing, corrective on blur, exhaustive on submit. |
| [bulk-action-bar](./bulk-action-bar.md) | Contextual actions over a multi-selection, where a half-succeeded action damages forty records. |
| [dialog-confirm-destructive](./dialog-confirm-destructive.md) | The last chance to not do the irreversible thing — reserved for actions that cannot be undone. |
| [density-breakpoints](./density-breakpoints.md) | How a surface changes with the viewport, bounded by the platform tap-target floor rather than by taste. |
| [studio-three-pane](./studio-three-pane.md) | Navigator, canvas, inspector — and the rule that editing the current object never re-selects the project. |

## Which patterns cite stories today

Six of the ten cite registered stories. Four cite none, because wave 1's story scope is the shell
widgets and no registered story exercises their behaviour: `list-detail`,
`state-empty-error-outage-loading`, `bulk-action-bar` and `studio-three-pane`. Those four say so in
their own files. Absence is allowed; a dangling reference is not.
