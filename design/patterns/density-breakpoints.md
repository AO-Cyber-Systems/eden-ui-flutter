# Density and breakpoints

## Intent
How a surface changes as the viewport changes, and where the line is between "denser" and "too small
to touch". Density is a product decision — an operator scanning two hundred rows wants tight rows —
but it is bounded, and the bound is the platform tap-target floor, not taste.

## Widgets
The shell is the worked example: `EdenDesktopLayout` at full and narrow rail widths and
`EdenMobileLayout` below the bar breakpoint. `story:desktop-layout/default`,
`story:desktop-layout/narrow` and `story:mobile-layout/default` are the three registered renderings of
one navigation model at three densities, and `story:nav-item/long-label` is the overflow case that
density changes expose first.

## States
- **comfortable** — the default. Full labels, full padding.
- **compact** — reduced padding, labels retained.
- **icon-only** — the rail collapsed; labels move to tooltips and accessible names.
- **narrow viewport** — a different chrome entirely (bar instead of rail).
- **overflow** — content that does not fit at the current density.

## Interaction rules
- `must_not: render below the tap target floor` — this is the rule density exists to be bounded by. No
  density setting may take a tap target below 48dp (Android) or 44pt (iOS). The shipped rail rows are
  42px and the collapse control is 20×20; both are below the floor today, and the resolution is a
  denser *visual* row with a compliant target, not a lower floor.
- `must_not: cover sibling hit rects` — and the resolution above has a second bound: at a 42px row
  pitch, padding a 48px hit rect around each row makes adjacent rows' semantics rects overlap, which is
  its own defect. Density, tap targets and hit-rect disjointness must be solved together; fixing one in
  isolation moves the failure rather than removing it.
- `must_not: exceed the rail width` — labels ellipsise at the current density. A density change never
  widens a fixed-width region to fit its content.
- `must_not: lose selection` — changing density or crossing a breakpoint preserves what is selected,
  what is expanded, and where the user is scrolled to.
- `must_not: change route` — a viewport resize is not navigation.

## Breakpoints
Breakpoints are declared per surface and are part of its Surface Spec, not inferred at render time from
a hardcoded number sprinkled through widgets. Each declared breakpoint is a state the oracle captures,
which is why the state matrix includes a narrow-viewport row for every surface. Crossing a breakpoint
changes layout and may change chrome; it never changes which data is shown or which record is current.

## Content
Density removes chrome before it removes content: padding, then illustration, then secondary metadata,
then labels — in that order. The primary field of a row and the explanatory sentence of a state are the
last things to go, and in practice they never go.

## Accessibility
- `must_not: render an unlabelled tappable` — icon-only density is the highest-risk case for this,
  because the label the sighted user lost to a tooltip is the same label the screen reader needs. An
  icon-only rail item must still publish its name.
- `must_not: nest semantics without a container` — density wrappers that add a `Semantics` around an
  existing control must pass `container: true`, or the control's own identifier disappears into the
  wrapper's node.
- Text scaling is a density input the user controls. A surface that is correct at the declared
  breakpoints and broken at 200% text scale has not satisfied this pattern; the overflow state must be
  captured at increased text scale as well as at a narrow viewport.
