/// Closed-set base for template-builder canvas layout strategies — parity
/// rows C-2 + C-3.
///
/// The base is `abstract` (not `sealed`) because Dart's `sealed` modifier
/// requires same-library subclasses; using `abstract` lets the executor
/// document a closed set while still permitting consumer experimentation.
/// In v1 the canvas only recognises the two library-shipped engines below
/// and throws on unknown subtypes.
abstract class EdenTemplateLayoutEngine {
  const EdenTemplateLayoutEngine();
}

/// Default layout — Column + ReorderableListView, top-down block flow.
/// Composable with most consumer surfaces; supports drag-to-reorder.
class EdenTemplateVerticalStackLayout extends EdenTemplateLayoutEngine {
  const EdenTemplateVerticalStackLayout();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is EdenTemplateVerticalStackLayout;

  @override
  int get hashCode => 0;
}

/// Freeform x/y layout — composes obj 006's `EdenDiagram` (does NOT extend
/// it). Block positions live in `block.content['x']` / `block.content['y']`;
/// when absent, the canvas cascades default positions to avoid stack-overlap.
class EdenTemplateFreeformLayout extends EdenTemplateLayoutEngine {
  const EdenTemplateFreeformLayout();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is EdenTemplateFreeformLayout;

  @override
  int get hashCode => 1;
}
