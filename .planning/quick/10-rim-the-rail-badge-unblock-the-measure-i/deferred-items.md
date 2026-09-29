# Deferred items — out of scope for this remediation

Recorded here rather than filed as GitHub issues because this worktree has no
`gh` access. Repeated verbatim in `10-SUMMARY.md` so they reach the tracker
the next time this PR chain (eden-ui-flutter#58 and its two follow-up
reviews) is touched.

## 1. `_DisclosedChildren`'s hairline strikes through a selected child's pill

**File:** `lib/src/widgets/eden_layout/eden_desktop_layout.dart`, class
`_DisclosedChildren` (`build()` around :870-897).

The disclosed-children rule is the LAST child of the `Stack` in
`_DisclosedChildren.build()` — after the `Column` of child rows, not before
— so it paints ON TOP of them. The rule sits at `left:
_kExpandableRuleInset` (5px from the block's own left edge, i.e. global x =
ListView pad 12 + 5 = 17) with `width: _kExpandableRuleWidth` (1px), so it
spans x = [17, 18]. A disclosed child's selection pill
(`EdenNavSelectionIndicator`, expanded branch) is `Positioned` with a -10px
horizontal inset around a 20px icon whose column starts at x = 24 (measured:
`childIconDx` in `eden_desktop_layout_expandable_test.dart` case 22), so the
pill spans roughly x = [14, 54]. The rule's x = [17, 18] falls INSIDE that
span: if a disclosed child row is selected, the 1px hairline paints over the
pill, visually striking a thin line through it.

Pre-existing (not introduced by this remediation), and no test in this repo
pumps a disclosed group with a SELECTED child to catch it — an uncovered
state, the same shape of gap this whole chain has been closing one adjacency
at a time. Likely fix: paint the rule BEHIND the children (reorder the
`Stack`'s children), or z-order it only across the vertical span the pill
does not occupy.

## 2. `decorationInk` takes `.first` where its siblings use `.single`

**File:** `test_support/ui_oracle/measure_ink.dart`, `decorationInk`
(currently line 285: `final Element element = finder.evaluate().first;`).

Every other resolver in this file — `paintedBackgroundOf` (:63), `iconInk`
(:239), `textInk` (:267) — calls `.single`, which throws if the finder
matches zero or more than one element: a cardinality guard, not just a
lookup. `decorationInk` alone uses `.first`, so a finder that accidentally
matches more than one `Container` (e.g. a predicate that is looser than
intended) silently measures whichever one Flutter's element tree happens to
visit first, rather than failing the way its siblings would. Not observed to
have caused a wrong measurement in this remediation — the finders it is
currently called with are already unique — but it is an inconsistency in the
instrument's own contract that a future caller could trip over silently.

## 3. `measure_ink.dart:213-218`'s (now ~248-257) `base == null` throw is unreachable

**File:** `test_support/ui_oracle/measure_ink.dart`, `iconInk`:

```dart
final Color? declared = icon.color;
final Color? inherited = IconTheme.of(element).color;
final Color? base = declared ?? inherited;
if (base == null) {
  throw StateError(
    'no resolvable ink for ${icon.icon} — neither Icon.color nor an '
    'ancestor IconTheme names one.',
  );
}
```

`IconTheme.of(context)` (`packages/flutter/lib/src/widgets/icon_theme_data.dart`)
falls back to `IconThemeData.fallback()` when no ancestor `IconTheme` is
present, and that fallback always carries a non-null `color`. So
`inherited` can never actually be null in a real widget tree, which means
`base` can never be null either, and this branch is dead code — the
opposite failure mode from guard (b)'s old defect (a branch that is dead
because it is unreachable, rather than dead because callers are refused
before reaching it). Confirmed by reading the Flutter SDK source, not
executed as a repro. Harmless as written (an unreachable defensive throw is
not a correctness bug), but worth deleting or converting to an `assert` the
next time this file is touched, so the file's own claims about what it
guards stay accurate.
