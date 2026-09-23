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

## The machine twin

`design/patterns.json` is the machine catalogue of this directory — the file DevFlow reads as
`df-tools ui spec validate <spec> --patterns design/patterns.json`, which is how Surface Spec §4.5
invariant I5 resolves a referenced pattern and inherits its `must_not` defaults. Without it I5 cannot
run and reports `PAT000 … UNCHECKED` on every spec. It sits in `design/` rather than in here because
`design/` is already this package's published machine-interface directory (W1b mirrors
`design/must_not_vocabulary.json` from it); a JSON file inside `design/patterns/` would read as an
eleventh pattern.

It is **generated, never hand-edited**, and the **prose in these files is its single source**. Every
rule is a line of the form

```
- `must_not: <term>` — <prose>
```

and **every one of them reaches the catalogue**. Front matter carries only the two facts prose cannot
state unambiguously:

```yaml
---
id: navigation/disclosure-group
kind: disclosure-header
---
```

* **`id`** is the catalogue id — slash-namespaced where the file name already carries a group prefix
  (`navigation-*`), otherwise the file stem. It is locked to the file name.
* **`kind`** is a Surface Spec control kind, and it is present only where the pattern governs **one**
  control of exactly that kind. A kind is a blast radius: every control of that kind in every spec
  inherits this pattern's `must_not`. Nine of the ten patterns govern a composition (a shell, a
  list–detail, a studio, a bar, a dialog) or a non-interactive element (a caption) and therefore
  declare no kind and inherit nothing onto anybody.

A `must_not:` or `must_not_scoped:` key in front matter is **refused**. Those lists used to restate
what the body already said, which is two sources for one fact — and they drifted at once: only one of
the ten docs ever carried them, so the catalogue shipped 2 of the 78 rules these files state while the
freshness gate, which regenerated from the same front matter, reported success.

### Electing an inherited default: `*(inherited)*`

The catalogue still separates the rules a control **inherits** at control level — the schema's
"applies to EVERY behaviour of this control" — from the rules it does not. That separation is signalled
by a marker on the rule line itself:

```
- `must_not: fire twice per activation` *(inherited)* — the header row is one tap target. …
```

Stated once, in the prose, beside the rule it classifies. **The default is _not_ inherited**, because
inheritance is a blast radius and should be opted into by the author who understands the control,
never acquired by a rule's position in the file. A marker is legal only under `## Interaction rules`
(`## Accessibility` and `## Breakpoints` rules are carried by a spec's `a11y` and `hit_rect` fields)
and only in a doc that declares a `kind` — with no kind nothing can inherit it, so the marker would be
dead data.

Section position is **not** the signal and never was. `## Interaction rules` mixes rules stated as flat
properties of the control with rules whose prose names the gesture or state they bite under
("collapsing a group…", "when a group collapses over the selected child…"); a section cannot tell them
apart, and the one doc that carried a hand-written partition classified two of its four interaction
rules as scoped for exactly that reason.

### What the JSON carries

* **`must_not`** — the elected defaults. Emitted only alongside a `kind`, because that is the pair
  DevFlow's PAT002 reads; a `must_not` without a `kind` inherits onto nobody.
* **`must_not_scoped`** — every other rule the doc states. DevFlow reads only `id`, `kind` and
  `must_not`; this key exists so the catalogue is a **complete record** of this directory rather than a
  fraction of it, and so the freshness gate can prove it.

Regenerate with `flutter test tool/gen_pattern_catalogue.dart`.
`test/design/pattern_catalogue_fresh_test.dart` case 12 compares the **committed JSON against these
doc bodies** — no front matter, no generator, no regeneration in between — so a rule written in prose
and absent from the catalogue fails, naming the term and the file. Case 2 fails in both directions for
a doc edited without regenerating and for a JSON edited by hand, and the unit cases refuse a marker
that nothing can inherit, a kind that inherits nothing, and a `must_not:` token written in a shape the
parser cannot see.
