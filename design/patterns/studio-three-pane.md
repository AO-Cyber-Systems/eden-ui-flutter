# Studio three-pane

## Intent
The authoring layout: a navigator on the left, a canvas in the middle, an inspector on the right. It is
the shape every builder in the product family converges on — process builder, template builder,
workflow designer — and it has one governing rule that separates it from list–detail: **the canvas has
a current object, and the navigator selecting a different object is not the same gesture as the
inspector editing the current one.**

## Widgets
_No implementing widget in this library yet — wave 1's story scope is the shell widgets._ The
builder screens in the dev app are static renderings of the layout, not a shared widget, so this
pattern deliberately cites no story: there is no registered story that exercises the three-pane
*behaviour* (project selection, canvas focus, inspector binding) as opposed to its appearance.

## States
- **no project selected** — navigator populated, canvas and inspector empty.
- **project selected, nothing on the canvas focused** — inspector shows project-level properties.
- **node focused** — inspector bound to the focused node.
- **multi-focus** — inspector shows the intersection of the focused nodes' properties.
- **inspector edit in flight** — a property is being saved; the canvas stays interactive.
- **unsaved changes** — the canvas is dirty and the navigator must not discard it silently.

_no story yet — wave 1 story scope is the shell widgets_

## Interaction rules
- `must_not: select the project` — focusing a node on the canvas, or editing a property in the
  inspector, must not re-select the project in the navigator. The inspector edits the current object;
  it does not reach back up and change what the navigator considers current. This is the pattern's
  defining rule and the one that breaks first when the inspector is wired to the same selection stream
  as the navigator.
- `must_not: lose selection` — a canvas re-layout, a zoom, a save, or an inspector edit preserves the
  focused node. Re-rendering the canvas is not a deselection.
- `must_not: steal focus` — the inspector does not pull keyboard focus when its binding changes; a user
  dragging on the canvas keeps the canvas focused. Conversely, typing in the inspector must not be
  interrupted by a canvas repaint.
- `must_not: destroy data without confirmation` — navigating to a different project with unsaved canvas
  changes confirms first (see `design/patterns/dialog-confirm-destructive.md`).
- `must_not: fire twice per activation` — an inspector field commits once per edit; a field that
  commits on both change and blur writes twice and makes undo history unreadable.
- `must_not: cover sibling hit rects` — pane splitters have their own hit rects and must not overlap
  the panes they divide, or the outermost column of the canvas becomes undraggable.

## Breakpoints
Three panes above the wide breakpoint. Between breakpoints the inspector becomes a collapsible drawer
over the canvas and the navigator collapses to icons. Below the narrow breakpoint the layout is not a
studio at all — it presents as navigator-then-canvas, with the inspector as a sheet; authoring on a
phone-width viewport is an explicit product decision per surface, not a free consequence of the layout
collapsing.

## Content
The navigator names projects; the canvas names the current project in its own header so the current
object is legible without looking left. The inspector's header names what it is bound to — "Step:
Approve invoice", not "Properties" — because an inspector that does not say what it edits is the direct
cause of edits landing on the wrong object.

## Accessibility
- `must_not: render an unlabelled tappable` — canvas nodes are tappable and must publish names;
  toolbar and splitter controls are labelled by function, not by glyph.
- `must_not: render below the tap target floor` — splitters, canvas node handles and inspector steppers
  meet 48dp/44pt. Handles are the smallest controls in the product and fail this most often.
- `must_not: nest semantics without a container` — canvas nodes are addressed by `identifier` by both
  tests and drivers; a node's `Semantics` inside another `Semantics` without `container: true` is not
  published at all on Flutter 3.41.9, so the node becomes unaddressable.
- Each pane is a landmark region so a screen-reader user can move between navigator, canvas and
  inspector directly rather than traversing the whole canvas to reach the inspector.
