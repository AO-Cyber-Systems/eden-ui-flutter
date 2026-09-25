---
id: navigation/section-caption
---
# Navigation section caption

## Intent
A non-interactive label that groups the entries beneath it in the rail. It is typography, not
navigation: it names a region of the list so a long rail reads as three short lists instead of one long
one. Its whole design is defined by what it is *not* — it has no icon, no tap target, and no button
role.

## Widgets
`EdenNavItem.caption` (`lib/src/widgets/eden_layout/layout_data.dart`), whose dartdoc already states
the rule: *"A non-interactive section label. Renders as an uppercase caption and nothing else — no
icon, no tap target, no accessibility button role."* Rendered by `EdenDesktopLayout`; deliberately
filtered out by `EdenMobileLayout`.

## States
- **default** — uppercase caption text at rail width. `story:nav-item/caption`
- **collapsed rail** — the rail is narrowed to icons only; the caption collapses to a rule or is
  omitted entirely. It never degrades into a mystery-meat icon.
- There is no selected, hovered, pressed, focused or disabled state. A caption that can be hovered has
  already broken the pattern.

## Interaction rules
- `must_not: render a tap target` — a caption has no `InkWell`, no `GestureDetector`, no `onTap` and no
  focus node. It cannot be clicked, cannot be tabbed to, and produces no ripple.
- `must_not: change route` — even accidentally: a caption is never wired to `onNavigate`, so no code
  path exists by which tapping the label region can move the user.
- `must_not: steal focus` — a caption is skipped by keyboard traversal. Arrowing down the rail moves
  from the last entry of one section to the first entry of the next, never onto the caption in between.

## Breakpoints
- `must_not: appear in the mobile bottom bar` — the bottom bar holds destinations only. A caption in a
  bar of four tabs would occupy a slot the user cannot press. `EdenMobileLayout` filters captions out
  before it counts items, so a caption must not affect bar capacity either.
- `must_not: exceed the rail width` — a long caption ellipsises inside the rail. It never widens the
  rail and never wraps to a second line, because a two-line caption shifts every row below it and
  breaks the rail's fixed row pitch.

## Content
Short, uppercase, two words at most: "WORKSPACE", "ADMIN", "REPORTS". Never a sentence, never a verb,
never trailing punctuation. A caption that needs a colon is a heading in the wrong place.

## Accessibility
- `must_not: render an unlabelled tappable` — trivially satisfied here because a caption is not
  tappable at all; the inverse failure is the one to watch, where a caption is given a button role "for
  consistency". It must be published as a plain header/label node, not as a button.
- Captions carry no tap target, so the 48dp/44pt floors do not apply to them. This is the one nav
  element for which a small rendered box is correct, and a size check must exempt it explicitly rather
  than by accident.
- The caption is announced as the group heading for the entries beneath it, so a screen-reader user
  hears the section name once rather than as a prefix on every child.
