# Navigation shell

## Intent
One declared navigation model, rendered two ways: a persistent side rail on wide viewports and a
bottom bar on narrow ones. The host app supplies a single `List<EdenNavItem>` and a selected id; the
shell decides which chrome to draw. The point of the pattern is that the *model* does not fork — there
is no "mobile nav list" and "desktop nav list" to drift apart.

## Widgets
`EdenDesktopLayout` and `EdenMobileLayout` (`lib/src/widgets/eden_layout/`), both fed by `EdenNavItem`
from `layout_data.dart`. The rail additionally owns its own collapsed state and its disclosure groups;
the bar owns neither.

## States
- **rail, default width** — full labels and icons. `story:desktop-layout/default`
- **rail, narrow** — rail collapsed to icons; labels move to tooltips. `story:desktop-layout/narrow`
- **bottom bar** — the narrow-viewport rendering. `story:mobile-layout/default`
- **overlong label** — a destination whose label does not fit the rail. `story:nav-item/long-label`
- **selected** — exactly one destination is selected in either chrome. `story:nav-item/selected`

## Interaction rules
- `must_not: fire twice per activation` — selecting a destination calls `onNavigate` exactly once.
  Switching chrome at a breakpoint must not re-fire it, and a rail item that is already selected must
  not re-emit on a second tap.
- `must_not: lose selection` — crossing the rail/bar breakpoint preserves the selected id. A window
  resize is not a navigation event; the same destination stays selected on the other side of it.
- `must_not: change route` — collapsing or expanding the rail itself is chrome, not navigation. The
  collapse control changes rail width and nothing else.
- `must_not: steal focus` — the shell does not move focus into the rail when a route changes. Focus
  belongs to the content the user navigated to, not to the chrome that got them there.

## Breakpoints
The rail/bar switch is the pattern's defining behaviour; the rules that survive it are:
- `must_not: appear in the mobile bottom bar` — captions and dividers are chrome for a vertical list
  and have no meaning in a horizontal bar of destinations. They are filtered out before bar capacity is
  counted.
- `must_not: exceed the rail width` — a long label ellipsises at the rail edge. It never widens the
  rail, never wraps, and never pushes the icon out of column. The same label in the bottom bar
  ellipsises within its tab slot.
- A destination present in the rail but dropped from the bar (over capacity) must still be reachable —
  through an overflow entry, never by being silently unreachable on small screens.

## Content
Labels are nouns naming places ("Orders", "Reports"), not verbs naming actions. Every destination has
an icon; icon-only rendering is a width decision the shell makes, not a per-item option the host sets.
Badges carry counts, never prose.

## Accessibility
- `must_not: render below the tap target floor` — every selectable row and every bar tab meets 48dp
  (Android) and 44pt (iOS). The shipped rail rows are 42px and the "Collapse sidebar" control is 20×20;
  both fail this rule today and both are tracked defects of the shell. Rail density versus touch
  targets is a real product decision affecting two shipped apps, so the rule stays and the shell is
  what changes.
- `must_not: render an unlabelled tappable` — every tappable node in the shell publishes a semantic
  label. `EdenMobileLayout` shipped a 56×56 tappable with no label; that is exactly the failure this
  rule names.
- `must_not: cover sibling hit rects` — adjacent rows' semantics rects stay disjoint. Growing a hit
  rect past the row pitch to satisfy the tap-target floor trades one accessibility failure for another.
- `must_not: nest semantics without a container` — controls addressed by `identifier` need
  `container: true`; without it the annotation merges into the parent node and the identifier is not
  published at all.
