import 'package:flutter/material.dart';

import '../tokens/colors.dart';

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

/// A single item within a swimlane group.
class EdenSwimlaneItem {
  const EdenSwimlaneItem({
    required this.label,
    this.isRequired = false,
    this.icon,
  });

  final String label;
  final bool isRequired;
  final IconData? icon;
}

/// A group of items within a swimlane phase.
class EdenSwimlaneGroup {
  const EdenSwimlaneGroup({
    required this.name,
    required this.items,
  });

  final String name;
  final List<EdenSwimlaneItem> items;
}

/// A phase (row) in the swimlane chart.
class EdenSwimlanePhase {
  const EdenSwimlanePhase({
    required this.name,
    required this.groups,
    this.color,
  });

  final String name;
  final List<EdenSwimlaneGroup> groups;

  /// Accent color for the phase label and group headers. Defaults to primary.
  final Color? color;
}

// ---------------------------------------------------------------------------
// Main widget
// ---------------------------------------------------------------------------

/// Interactive swimlane flow chart with phases, groups, and items.
///
/// Phases render as horizontal lanes with a vertical color-coded label on the
/// left and group cards in a horizontal row. Supports pan/zoom via
/// [InteractiveViewer]. Renders a dot grid background using [CustomPaint].
///
/// Use with [EdenCanvasToolbar] for zoom controls.
///
/// ```dart
/// EdenSwimlaneChart(
///   phases: [
///     EdenSwimlanePhase(
///       name: 'Prep',
///       color: Colors.blue,
///       groups: [
///         EdenSwimlaneGroup(name: 'Materials', items: [
///           EdenSwimlaneItem(label: 'Order supplies', isRequired: true),
///           EdenSwimlaneItem(label: 'Confirm delivery'),
///         ]),
///       ],
///     ),
///   ],
/// )
/// ```
class EdenSwimlaneChart extends StatelessWidget {
  const EdenSwimlaneChart({
    super.key,
    required this.phases,
    this.transformationController,
    this.minScale = 0.5,
    this.maxScale = 2.0,
    this.backgroundColor,
    this.showDotGrid = true,
  });

  /// Swimlane phases to render as rows.
  final List<EdenSwimlanePhase> phases;

  /// Optional external transformation controller for zoom/pan.
  final TransformationController? transformationController;

  /// Minimum zoom scale.
  final double minScale;

  /// Maximum zoom scale.
  final double maxScale;

  /// Canvas background color. Defaults to near-black (0xFF0A0A0A).
  final Color? backgroundColor;

  /// Whether to render the dot grid background.
  final bool showDotGrid;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? EdenColors.neutral[950]!;

    return InteractiveViewer(
      transformationController: transformationController,
      minScale: minScale,
      maxScale: maxScale,
      constrained: false,
      boundaryMargin: const EdgeInsets.all(200),
      child: Container(
        color: bg,
        child: CustomPaint(
          painter: showDotGrid ? _DotGridPainter() : null,
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < phases.length; i++) ...[
                  _PhaseRow(phase: phases[i]),
                  if (i < phases.length - 1) const _PhaseConnector(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Phase row (swimlane)
// ---------------------------------------------------------------------------

class _PhaseRow extends StatelessWidget {
  const _PhaseRow({required this.phase});

  final EdenSwimlanePhase phase;

  @override
  Widget build(BuildContext context) {
    final phaseColor =
        phase.color ?? Theme.of(context).colorScheme.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Vertical phase label — uses IntrinsicHeight only for itself
        IntrinsicHeight(
          child: Container(
            width: 40,
            constraints: const BoxConstraints(minHeight: 80),
            decoration: BoxDecoration(
              color: phaseColor.withValues(alpha: 0.1),
              border: Border(
                left: BorderSide(color: phaseColor, width: 3),
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
            ),
            child: Center(
              child: RotatedBox(
                quarterTurns: 3,
                child: Text(
                  phase.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: phaseColor,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Group cards — unconstrained vertical sizing
        Flexible(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < phase.groups.length; i++) ...[
                  _GroupCard(group: phase.groups[i], phaseColor: phaseColor),
                  if (i < phase.groups.length - 1) _groupArrow(),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _groupArrow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.arrow_forward,
            size: 18,
            color: Colors.white.withValues(alpha: 0.25),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Phase connector (vertical arrow between phases)
// ---------------------------------------------------------------------------

class _PhaseConnector extends StatelessWidget {
  const _PhaseConnector();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Column(
        children: [
          Container(
            width: 2,
            height: 16,
            color: Colors.white.withValues(alpha: 0.15),
          ),
          Icon(
            Icons.arrow_downward,
            size: 14,
            color: Colors.white.withValues(alpha: 0.25),
          ),
          Container(
            width: 2,
            height: 8,
            color: Colors.white.withValues(alpha: 0.15),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Group card
// ---------------------------------------------------------------------------

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group, required this.phaseColor});

  final EdenSwimlaneGroup group;
  final Color phaseColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.3)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    group.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: phaseColor,
                    ),
                  ),
                ),
                Text(
                  '${group.items.length} items',
                  style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: group.items.map((item) => _ItemRow(item: item)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Item row
// ---------------------------------------------------------------------------

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final EdenSwimlaneItem item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(
            item.icon ?? Icons.check_box_outline_blank,
            size: 14,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              item.label,
              style: TextStyle(fontSize: 12, color: cs.onSurface),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (item.isRequired)
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
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
