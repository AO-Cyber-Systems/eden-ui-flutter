import 'package:flutter/material.dart';

import '../tokens/colors.dart';

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

/// Visual style for a rule node type.
class EdenRuleNodeStyle {
  const EdenRuleNodeStyle({
    required this.label,
    required this.color,
  });

  /// Type label shown above the node content (e.g., "TRIGGER", "CONDITION").
  final String label;

  /// Border and label color for this node type.
  final Color color;
}

/// A node in an [EdenRuleTree] decision/flow tree.
class EdenRuleNode {
  const EdenRuleNode({
    required this.title,
    required this.style,
    this.subtitle,
    this.children = const [],
  });

  /// Primary text shown in the node card.
  final String title;

  /// Visual style (type label + color).
  final EdenRuleNodeStyle style;

  /// Optional secondary text.
  final String? subtitle;

  /// Child nodes. Single child = linear chain. Multiple = vertical branch.
  final List<EdenRuleNode> children;
}

/// Common rule node styles for convenience.
class EdenRuleNodeStyles {
  EdenRuleNodeStyles._();

  static const trigger = EdenRuleNodeStyle(
    label: 'TRIGGER',
    color: Color(0xFF10B981),
  );
  static const condition = EdenRuleNodeStyle(
    label: 'CONDITION',
    color: Color(0xFF3B82F6),
  );
  static const action = EdenRuleNodeStyle(
    label: 'ACTION',
    color: Color(0xFFA855F7),
  );
  static const delay = EdenRuleNodeStyle(
    label: 'DELAY',
    color: Color(0xFFF59E0B),
  );
}

// ---------------------------------------------------------------------------
// Main widget
// ---------------------------------------------------------------------------

/// Interactive recursive decision tree visualization.
///
/// Renders nodes as cards with colored borders. Single children chain
/// horizontally with arrow connectors. Multiple children branch vertically.
/// Supports pan/zoom via [InteractiveViewer] with a dot grid background.
///
/// ```dart
/// EdenRuleTree(
///   roots: [
///     EdenRuleNode(
///       title: 'Project Created',
///       style: EdenRuleNodeStyles.trigger,
///       children: [
///         EdenRuleNode(
///           title: 'Value > \$10K?',
///           style: EdenRuleNodeStyles.condition,
///           children: [
///             EdenRuleNode(title: 'Assign Senior Tech', style: EdenRuleNodeStyles.action),
///             EdenRuleNode(title: 'Assign Available Tech', style: EdenRuleNodeStyles.action),
///           ],
///         ),
///       ],
///     ),
///   ],
/// )
/// ```
class EdenRuleTree extends StatelessWidget {
  const EdenRuleTree({
    super.key,
    required this.roots,
    this.transformationController,
    this.minScale = 0.5,
    this.maxScale = 2.0,
    this.backgroundColor,
    this.showDotGrid = true,
    this.nodeWidth = 200.0,
  });

  /// Root nodes to render (each is an independent tree).
  final List<EdenRuleNode> roots;

  /// Optional external transformation controller.
  final TransformationController? transformationController;

  final double minScale;
  final double maxScale;

  /// Canvas background color.
  final Color? backgroundColor;

  /// Whether to render the dot grid background.
  final bool showDotGrid;

  /// Width of each node card.
  final double nodeWidth;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? EdenColors.neutral[950]!;

    return InteractiveViewer(
      transformationController: transformationController,
      minScale: minScale,
      maxScale: maxScale,
      boundaryMargin: const EdgeInsets.all(200),
      child: Container(
        color: bg,
        child: CustomPaint(
          painter: showDotGrid ? _DotGridPainter() : null,
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < roots.length; i++) ...[
                    _buildNodeTree(roots[i]),
                    if (i < roots.length - 1) const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNodeTree(EdenRuleNode node) {
    if (node.children.isEmpty) {
      return _NodeCard(node: node, width: nodeWidth);
    }

    if (node.children.length == 1) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _NodeCard(node: node, width: nodeWidth),
          const _HorizontalArrow(),
          _buildNodeTree(node.children.first),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _NodeCard(node: node, width: nodeWidth),
        const _HorizontalArrow(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < node.children.length; i++) ...[
              _buildNodeTree(node.children[i]),
              if (i < node.children.length - 1) const _VerticalConnector(),
            ],
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Node card
// ---------------------------------------------------------------------------

class _NodeCard extends StatelessWidget {
  const _NodeCard({required this.node, required this.width});

  final EdenRuleNode node;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border.all(color: node.style.color, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            node.style.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: node.style.color,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            node.title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (node.subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              node.subtitle!,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Connectors
// ---------------------------------------------------------------------------

class _HorizontalArrow extends StatelessWidget {
  const _HorizontalArrow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 2,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          Icon(
            Icons.arrow_forward,
            size: 14,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          Container(
            width: 8,
            height: 2,
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ],
      ),
    );
  }
}

class _VerticalConnector extends StatelessWidget {
  const _VerticalConnector();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 100),
      child: Column(
        children: [
          Container(
            width: 2,
            height: 8,
            color: Colors.white.withValues(alpha: 0.15),
          ),
          Icon(
            Icons.arrow_downward,
            size: 12,
            color: Colors.white.withValues(alpha: 0.25),
          ),
          Container(
            width: 2,
            height: 4,
            color: Colors.white.withValues(alpha: 0.15),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dot grid painter
// ---------------------------------------------------------------------------

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    const spacing = 20.0;
    const radius = 1.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
