import 'package:flutter/material.dart';

import 'template_block_registry.dart';
import 'template_models.dart';

/// Left-rail block palette UI — parity rows P-1..P-5.
///
/// Reads from [EdenTemplateBlockRegistry]; renders a categorised
/// 2-column grid of [EdenTemplateBlockDescriptor] cards. Each card is a
/// [Draggable] of the descriptor (for drag-to-canvas in TRD-03) and also
/// fires [onAddBlock] on tap (click-to-add fallback on touch / no-drag
/// contexts).
///
/// **Stateless** — consumers wrap in a [StatefulWidget] and call `setState`
/// after `EdenTemplateBlockRegistry.instance.register(...)` if reactive
/// updates are required.
///
/// **Composes**, does NOT extend, the eden_diagram canvas. The palette only
/// emits drag events; the canvas owns the [DragTarget].
class EdenTemplateBlockPalette extends StatelessWidget {
  const EdenTemplateBlockPalette({
    super.key,
    required this.onAddBlock,
    this.categories,
    this.cardBuilder,
    this.emptyPlaceholder,
  });

  /// Fired on tap (click-to-add fallback). NOT fired on drag-end —
  /// the DragTarget consumer (canvas) handles drop events.
  final void Function(EdenTemplateBlockDescriptor descriptor) onAddBlock;

  /// Explicit category order. When null, derived from registry — sorted
  /// alphabetically.
  final List<String>? categories;

  /// Consumer-provided card renderer override. When null, the default
  /// `_DefaultBlockCard` is used.
  final Widget Function(BuildContext, EdenTemplateBlockDescriptor)? cardBuilder;

  /// Override for the empty-registry placeholder.
  final Widget? emptyPlaceholder;

  @override
  Widget build(BuildContext context) {
    final all = EdenTemplateBlockRegistry.instance.all();
    if (all.isEmpty) {
      return emptyPlaceholder ?? const _DefaultEmptyPlaceholder();
    }

    final effectiveCategories = categories ??
        (all.map((d) => d.category).toSet().toList()..sort());

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final category in effectiveCategories) ...[
          _SectionHeader(label: category.toUpperCase()),
          const SizedBox(height: 8),
          _BlockGrid(
            descriptors:
                all.where((d) => d.category == category).toList(growable: false),
            onAddBlock: onAddBlock,
            cardBuilder: cardBuilder,
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: theme.colorScheme.onSurfaceVariant,
            ) ??
            const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
      ),
    );
  }
}

class _BlockGrid extends StatelessWidget {
  const _BlockGrid({
    required this.descriptors,
    required this.onAddBlock,
    required this.cardBuilder,
  });

  final List<EdenTemplateBlockDescriptor> descriptors;
  final void Function(EdenTemplateBlockDescriptor) onAddBlock;
  final Widget Function(BuildContext, EdenTemplateBlockDescriptor)? cardBuilder;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: descriptors.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 1.3,
      ),
      itemBuilder: (ctx, i) {
        final d = descriptors[i];
        final card = cardBuilder != null
            ? cardBuilder!(ctx, d)
            : _DefaultBlockCard(descriptor: d, onAddBlock: onAddBlock);
        // Wrap consumer cards in a Draggable too so drag-source semantics
        // are preserved regardless of cardBuilder.
        return Draggable<EdenTemplateBlockDescriptor>(
          data: d,
          feedback: Material(
            elevation: 4,
            color: Colors.transparent,
            child: SizedBox(
              width: 120,
              height: 90,
              child: _CardContent(descriptor: d, isFeedback: true),
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.3, child: card),
          child: card,
        );
      },
    );
  }
}

class _DefaultBlockCard extends StatefulWidget {
  const _DefaultBlockCard({
    required this.descriptor,
    required this.onAddBlock,
  });

  final EdenTemplateBlockDescriptor descriptor;
  final void Function(EdenTemplateBlockDescriptor) onAddBlock;

  @override
  State<_DefaultBlockCard> createState() => _DefaultBlockCardState();
}

class _DefaultBlockCardState extends State<_DefaultBlockCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => widget.onAddBlock(widget.descriptor),
        behavior: HitTestBehavior.opaque,
        child: _CardContent(
          descriptor: widget.descriptor,
          isHovered: _isHovered,
        ),
      ),
    );
  }
}

class _CardContent extends StatelessWidget {
  const _CardContent({
    required this.descriptor,
    this.isHovered = false,
    this.isFeedback = false,
  });

  final EdenTemplateBlockDescriptor descriptor;
  final bool isHovered;
  final bool isFeedback;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = isHovered || isFeedback
        ? theme.colorScheme.primary
        : theme.colorScheme.outlineVariant;
    final bgColor = isHovered
        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.18)
        : theme.colorScheme.surface;
    final iconColor = isHovered || isFeedback
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor, width: 1.2),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(descriptor.icon, size: 20, color: iconColor),
          const SizedBox(height: 4),
          Text(
            descriptor.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ) ??
                const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            descriptor.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 9,
                  color: theme.colorScheme.onSurfaceVariant,
                ) ??
                const TextStyle(fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _DefaultEmptyPlaceholder extends StatelessWidget {
  const _DefaultEmptyPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.dashboard, size: 32),
          SizedBox(height: 8),
          Text('No block types registered'),
          SizedBox(height: 4),
          Text(
            'Call EdenTemplateBlockRegistry.instance.resetToDefaults() to load defaults',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
