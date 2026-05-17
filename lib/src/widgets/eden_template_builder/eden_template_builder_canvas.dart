import 'package:flutter/material.dart';

import '../eden_diagram/diagram_data.dart';
import '../eden_diagram/eden_diagram.dart';
import 'eden_template_block_placeholder.dart';
import 'template_block_registry.dart';
import 'template_layout_engine.dart';
import 'template_models.dart';

/// Editable template canvas — parity rows C-1 + C-4..C-9.
///
/// Routes to one of two pluggable layout strategies (vertical-stack or
/// freeform that composes obj 006's [EdenDiagram]). Section tabs filter by
/// [EdenTemplateSection]. Empty section renders a helpful placeholder.
/// Drop zone accepts [EdenTemplateBlockDescriptor] from the palette.
/// Narrow fallback below 1200pt per the desktop-primary positioning.
///
/// Callbacks (consumer-driven state):
/// - [onAddBlock] — fired on drop from palette
/// - [onDeleteBlock] — fired on placeholder delete affordance
/// - [onUpdateBlock] — fired on placeholder edit affordance (consumer ships
///   the edit dialog, e.g. via TRD 021-05 dev catalog stub)
/// - [onReorderBlock] — fired on drag-to-reorder (vertical-stack only); the
///   `newIndex` is pre-adjusted for Flutter's `ReorderableListView` quirk
///   (subtract 1 when oldIndex < newIndex)
class EdenTemplateBuilderCanvas extends StatefulWidget {
  const EdenTemplateBuilderCanvas({
    super.key,
    required this.graph,
    this.onAddBlock,
    this.onDeleteBlock,
    this.onUpdateBlock,
    this.onReorderBlock,
    this.layout = const EdenTemplateVerticalStackLayout(),
    this.initialSection = EdenTemplateSection.body,
    this.narrowFallback,
    this.currentPage = 1,
    this.totalPages = 1,
  });

  final EdenTemplateGraph graph;
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
  final EdenTemplateLayoutEngine layout;
  final EdenTemplateSection initialSection;
  final Widget? narrowFallback;
  final int currentPage;
  final int totalPages;

  @override
  State<EdenTemplateBuilderCanvas> createState() =>
      _EdenTemplateBuilderCanvasState();
}

class _EdenTemplateBuilderCanvasState extends State<EdenTemplateBuilderCanvas> {
  late EdenTemplateSection _activeSection;

  @override
  void initState() {
    super.initState();
    _activeSection = widget.initialSection;
  }

  List<EdenTemplateBlock> get _sectionBlocks {
    final filtered = widget.graph.blocks
        .where((b) => b.section == _activeSection)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return filtered;
  }

  /// Internal — exposed via dynamic for unit tests to bypass
  /// ReorderableListView's gesture machinery.
  void handleReorderForTest(int oldIndex, int newIndex) {
    _handleReorder(oldIndex, newIndex);
  }

  void _handleReorder(int oldIndex, int newIndex) {
    var adjusted = newIndex;
    if (oldIndex < newIndex) adjusted -= 1;
    widget.onReorderBlock?.call(_activeSection, oldIndex, adjusted);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        if (constraints.maxWidth < 1200) {
          return widget.narrowFallback ?? const _DefaultNarrowFallback();
        }
        return Column(
          children: [
            _SectionTabBar(
              active: _activeSection,
              onChange: (s) => setState(() => _activeSection = s),
            ),
            Expanded(child: _buildDocumentPage(ctx)),
          ],
        );
      },
    );
  }

  Widget _buildDocumentPage(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: DragTarget<EdenTemplateBlockDescriptor>(
            onAcceptWithDetails: (details) {
              widget.onAddBlock?.call(details.data, _activeSection, null);
            },
            builder: (ctx, candidate, rejected) {
              return Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: candidate.isNotEmpty
                      ? Border.all(color: theme.colorScheme.primary, width: 2)
                      : Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 12,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: _buildPageContent(ctx),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPageContent(BuildContext context) {
    final blocks = _sectionBlocks;
    if (blocks.isEmpty) {
      return _EmptySection(section: _activeSection);
    }
    final layout = widget.layout;
    Widget content;
    if (layout is EdenTemplateVerticalStackLayout) {
      content = _buildVerticalStack(blocks);
    } else if (layout is EdenTemplateFreeformLayout) {
      content = _buildFreeform(blocks);
    } else {
      throw StateError(
        'Unsupported layout engine: ${widget.layout.runtimeType}',
      );
    }
    if (_activeSection == EdenTemplateSection.footer) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: content),
          _FooterIndicator(
            currentPage: widget.currentPage,
            totalPages: widget.totalPages,
          ),
        ],
      );
    }
    return content;
  }

  Widget _buildVerticalStack(List<EdenTemplateBlock> blocks) {
    return ReorderableListView(
      shrinkWrap: true,
      buildDefaultDragHandles: false,
      onReorder: _handleReorder,
      children: [
        for (final block in blocks)
          ReorderableDragStartListener(
            key: ValueKey(block.id),
            index: blocks.indexOf(block),
            child: _renderBlock(block),
          ),
      ],
    );
  }

  Widget _renderBlock(EdenTemplateBlock block) {
    final descriptor =
        EdenTemplateBlockRegistry.instance.lookup(block.type) ??
            _fallbackDescriptor(block.type);
    if (descriptor.placeholderBuilder != null) {
      return descriptor.placeholderBuilder!(context, block);
    }
    return EdenTemplateBlockPlaceholder(
      block: block,
      descriptor: descriptor,
      onEdit: () =>
          widget.onUpdateBlock?.call(block.id, block.content),
      onDelete: widget.onDeleteBlock == null
          ? null
          : () => widget.onDeleteBlock!(block.id),
    );
  }

  EdenTemplateBlockDescriptor _fallbackDescriptor(String type) {
    return EdenTemplateBlockDescriptor(
      id: type,
      displayName: type,
      description: 'Unregistered block type',
      icon: Icons.widgets_outlined,
      category: 'Unknown',
    );
  }

  Widget _buildFreeform(List<EdenTemplateBlock> blocks) {
    final nodes = blocks.asMap().entries.map((entry) {
      final idx = entry.key;
      final block = entry.value;
      final descriptor =
          EdenTemplateBlockRegistry.instance.lookup(block.type);
      final x = (block.content['x'] as num?)?.toDouble() ?? (50.0 + idx * 20);
      final y = (block.content['y'] as num?)?.toDouble() ?? (50.0 + idx * 20);
      return EdenDiagramNode(
        id: block.id,
        label: descriptor?.displayName ?? block.type,
        x: x,
        y: y,
        width: 160,
        height: 60,
      );
    }).toList();
    return SizedBox(
      height: 600,
      child: EdenDiagram(
        data: EdenDiagramData(nodes: nodes, edges: const []),
        readOnly: false,
        showToolbar: false,
      ),
    );
  }
}

class _SectionTabBar extends StatelessWidget {
  const _SectionTabBar({required this.active, required this.onChange});

  final EdenTemplateSection active;
  final ValueChanged<EdenTemplateSection> onChange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Tab(
            label: 'Header',
            active: active == EdenTemplateSection.header,
            onTap: () => onChange(EdenTemplateSection.header),
          ),
          const SizedBox(width: 4),
          _Tab(
            label: 'Body',
            active: active == EdenTemplateSection.body,
            onTap: () => onChange(EdenTemplateSection.body),
          ),
          const SizedBox(width: 4),
          _Tab(
            label: 'Footer',
            active: active == EdenTemplateSection.footer,
            onTap: () => onChange(EdenTemplateSection.footer),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        decoration: BoxDecoration(
          color: active
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: active
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.section});

  final EdenTemplateSection section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 36,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              'No blocks in ${section.name} section',
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add blocks from the palette',
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

class _FooterIndicator extends StatelessWidget {
  const _FooterIndicator({required this.currentPage, required this.totalPages});

  final int currentPage;
  final int totalPages;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Text(
            'Page Footer',
            style: TextStyle(
              fontSize: 10,
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            'Page $currentPage of $totalPages',
            style: TextStyle(
              fontSize: 10,
              fontFamily: 'monospace',
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _DefaultNarrowFallback extends StatelessWidget {
  const _DefaultNarrowFallback();

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
