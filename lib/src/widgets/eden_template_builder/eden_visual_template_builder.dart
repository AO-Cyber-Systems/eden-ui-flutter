import 'package:flutter/material.dart';

import 'eden_template_block_palette.dart';
import 'eden_template_builder_canvas.dart';
import 'eden_template_layout_panel.dart';
import 'eden_template_styles_panel.dart';
import 'eden_template_variables_panel.dart';
import 'template_layout_engine.dart';
import 'template_models.dart';

/// Composite-root visual template builder — parity rows X-1 + X-2.
///
/// Composes: [EdenTemplateBuilderCanvas] (center) + right-rail with 4 icon
/// tabs (Blocks/Variables/Layout/Styles). Mirrors the donor
/// `builder_canvas.dart` layout — palette lives in the right rail behind the
/// Blocks tab; consumers wanting a separate left rail can compose
/// [EdenTemplateBlockPalette] directly.
///
/// Controlled — consumer owns graph + style + layout settings state and
/// re-renders via setState whenever a callback fires.
class EdenVisualTemplateBuilder extends StatefulWidget {
  const EdenVisualTemplateBuilder({
    super.key,
    required this.graph,
    required this.styleSettings,
    required this.layoutSettings,
    this.onAddBlock,
    this.onDeleteBlock,
    this.onUpdateBlock,
    this.onReorderBlock,
    this.onChangeStyle,
    this.onChangeLayout,
    this.onInsertField,
    this.layout = const EdenTemplateVerticalStackLayout(),
    this.initialSection = EdenTemplateSection.body,
    this.narrowFallback,
    this.rightRailWidth = 280,
    this.hideRightRail = false,
  });

  final EdenTemplateGraph graph;
  final EdenTemplateStyleSettings styleSettings;
  final EdenTemplateLayoutSettings layoutSettings;
  final void Function(
    EdenTemplateBlockDescriptor descriptor,
    EdenTemplateSection section,
    int? insertIndex,
  )? onAddBlock;
  final void Function(String blockId)? onDeleteBlock;
  final void Function(String blockId, Map<String, dynamic> newContent)?
      onUpdateBlock;
  final void Function(
    EdenTemplateSection section,
    int oldIndex,
    int newIndex,
  )? onReorderBlock;
  final void Function(EdenTemplateStyleSettings)? onChangeStyle;
  final void Function(EdenTemplateLayoutSettings)? onChangeLayout;
  final void Function(String token)? onInsertField;
  final EdenTemplateLayoutEngine layout;
  final EdenTemplateSection initialSection;
  final Widget? narrowFallback;
  final double rightRailWidth;
  final bool hideRightRail;

  @override
  State<EdenVisualTemplateBuilder> createState() =>
      _EdenVisualTemplateBuilderState();
}

class _EdenVisualTemplateBuilderState extends State<EdenVisualTemplateBuilder> {
  int _activePanelIndex = 0; // 0 Blocks, 1 Variables, 2 Layout, 3 Styles
  late EdenTemplateSection _activeSection;

  @override
  void initState() {
    super.initState();
    _activeSection = widget.initialSection;
  }

  static const _tabs = [
    (icon: Icons.dashboard, label: 'Blocks'),
    (icon: Icons.data_object, label: 'Variables'),
    (icon: Icons.article_outlined, label: 'Layout'),
    (icon: Icons.palette_outlined, label: 'Styles'),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        // Composite root must reserve enough width for the canvas (1200pt)
        // PLUS the right rail; otherwise the inner canvas hits its own
        // narrow-fallback and the composite root shows empty space.
        final railWidth = widget.hideRightRail ? 0.0 : widget.rightRailWidth;
        final minimum = 1200.0 + railWidth;
        if (constraints.maxWidth < minimum) {
          return widget.narrowFallback ??
              const _DefaultBuilderNarrowFallback();
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: EdenTemplateBuilderCanvas(
                graph: widget.graph,
                onAddBlock: widget.onAddBlock,
                onDeleteBlock: widget.onDeleteBlock,
                onUpdateBlock: widget.onUpdateBlock,
                onReorderBlock: widget.onReorderBlock,
                layout: widget.layout,
                initialSection: _activeSection,
              ),
            ),
            if (!widget.hideRightRail) _buildRightRail(context),
          ],
        );
      },
    );
  }

  Widget _buildRightRail(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: widget.rightRailWidth,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          left: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        children: [
          _buildTabStrip(context),
          Expanded(child: _buildActivePanel(context)),
        ],
      ),
    );
  }

  Widget _buildTabStrip(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(_tabs.length, (i) {
          final isActive = _activePanelIndex == i;
          return Tooltip(
            message: _tabs[i].label,
            child: InkWell(
              onTap: () => setState(() => _activePanelIndex = i),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isActive
                      ? theme.colorScheme.primary.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  _tabs[i].icon,
                  size: 20,
                  color: isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildActivePanel(BuildContext context) {
    switch (_activePanelIndex) {
      case 0:
        return EdenTemplateBlockPalette(
          onAddBlock: (descriptor) => widget.onAddBlock?.call(
            descriptor,
            _activeSection,
            null,
          ),
        );
      case 1:
        return EdenTemplateVariablesPanel(
          onInsertField: widget.onInsertField ?? (_) {},
        );
      case 2:
        return EdenTemplateLayoutPanel(
          value: widget.layoutSettings,
          onChangeLayout: widget.onChangeLayout ?? (_) {},
        );
      case 3:
        return EdenTemplateStylesPanel(
          value: widget.styleSettings,
          onChangeStyle: widget.onChangeStyle ?? (_) {},
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _DefaultBuilderNarrowFallback extends StatelessWidget {
  const _DefaultBuilderNarrowFallback();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.devices_other,
              size: 36,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'Template builder requires tablet/desktop width (1200pt+).',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Use mobile preview instead.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
