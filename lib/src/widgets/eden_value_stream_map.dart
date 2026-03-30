import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// A single stage in a value stream.
class EdenValueStreamStage {
  /// Creates a value stream stage.
  const EdenValueStreamStage({
    required this.name,
    required this.medianDays,
    this.icon,
  });

  /// The display name for this stage.
  final String name;

  /// The median number of days spent in this stage.
  final double medianDays;

  /// An optional icon for the stage.
  final IconData? icon;
}

/// Color mode for the stage gradient.
enum EdenValueStreamColorMode {
  /// Cool-to-warm gradient from left to right.
  coolToWarm,

  /// All stages use the theme primary color.
  uniform,
}

/// A horizontal value stream map showing stages connected by arrows.
///
/// Each stage is rendered as a rounded box with its name, icon, and median
/// cycle time. Stages are connected by directional arrows. The longest stage
/// is automatically highlighted as a bottleneck. Total lead time is displayed.
class EdenValueStreamMap extends StatefulWidget {
  /// Creates an Eden value stream map.
  const EdenValueStreamMap({
    super.key,
    required this.stages,
    this.colorMode = EdenValueStreamColorMode.coolToWarm,
    this.onStageTap,
  });

  /// The ordered list of stages in the value stream.
  final List<EdenValueStreamStage> stages;

  /// How stages are colored.
  final EdenValueStreamColorMode colorMode;

  /// Called when a stage box is tapped.
  final ValueChanged<EdenValueStreamStage>? onStageTap;

  @override
  State<EdenValueStreamMap> createState() => _EdenValueStreamMapState();
}

class _EdenValueStreamMapState extends State<EdenValueStreamMap> {
  int? _bottleneckIndex;

  @override
  void didUpdateWidget(covariant EdenValueStreamMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    _bottleneckIndex = null;
  }

  int _findBottleneck() {
    if (_bottleneckIndex != null) return _bottleneckIndex!;
    var maxDays = -1.0;
    var idx = 0;
    for (int i = 0; i < widget.stages.length; i++) {
      if (widget.stages[i].medianDays > maxDays) {
        maxDays = widget.stages[i].medianDays;
        idx = i;
      }
    }
    _bottleneckIndex = idx;
    return idx;
  }

  double get _totalLeadTime =>
      widget.stages.fold(0.0, (sum, s) => sum + s.medianDays);

  Color _stageColor(int index, int total, bool isDark) {
    if (widget.colorMode == EdenValueStreamColorMode.uniform) {
      return isDark ? EdenColors.blue[700]! : EdenColors.blue[500]!;
    }
    // Cool (blue/cyan) to warm (orange/red) gradient.
    final t = total > 1 ? index / (total - 1) : 0.5;
    final coolColors = [
      EdenColors.blue[500]!,
      EdenColors.emerald[500]!,
      EdenColors.gold[500]!,
      EdenColors.red[400]!,
    ];
    // Interpolate through the color stops.
    final segment = t * (coolColors.length - 1);
    final lower = segment.floor().clamp(0, coolColors.length - 2);
    final localT = segment - lower;
    return Color.lerp(coolColors[lower], coolColors[lower + 1], localT)!;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final stages = widget.stages;

    if (stages.isEmpty) return const SizedBox.shrink();

    final bottleneck = _findBottleneck();
    final totalLead = _totalLeadTime;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Total lead time
        Text(
          'Total lead time: ${_formatDays(totalLead)}',
          style: theme.textTheme.titleSmall?.copyWith(
            color: isDark ? EdenColors.neutral[200] : EdenColors.neutral[800],
          ),
        ),
        const SizedBox(height: EdenSpacing.space4),
        // Scrollable stage row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(stages.length * 2 - 1, (i) {
              if (i.isOdd) {
                return _buildArrow(isDark);
              }
              final idx = i ~/ 2;
              return _buildStageBox(
                stages[idx],
                idx,
                stages.length,
                bottleneck == idx,
                isDark,
                theme,
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildStageBox(
    EdenValueStreamStage stage,
    int index,
    int total,
    bool isBottleneck,
    bool isDark,
    ThemeData theme,
  ) {
    final color = _stageColor(index, total, isDark);
    final borderColor = isBottleneck ? EdenColors.warning : color;
    final bgColor = isBottleneck
        ? EdenColors.warningBg
        : color.withValues(alpha: isDark ? 0.15 : 0.1);

    return GestureDetector(
      onTap: () => widget.onStageTap?.call(stage),
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(
          horizontal: EdenSpacing.space3,
          vertical: EdenSpacing.space3,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: EdenRadii.borderRadiusLg,
          border: Border.all(
            color: borderColor.withValues(alpha: isBottleneck ? 0.8 : 0.4),
            width: isBottleneck ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (stage.icon != null) ...[
              Icon(
                stage.icon,
                size: 20,
                color: isBottleneck ? EdenColors.warning : color,
              ),
              const SizedBox(height: EdenSpacing.space1),
            ],
            Text(
              stage.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? EdenColors.neutral[100]
                    : EdenColors.neutral[900],
              ),
            ),
            const SizedBox(height: EdenSpacing.space1),
            Text(
              _formatDays(stage.medianDays),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isBottleneck
                    ? EdenColors.warning
                    : (isDark
                        ? EdenColors.neutral[400]
                        : EdenColors.neutral[500]),
              ),
            ),
            if (isBottleneck) ...[
              const SizedBox(height: EdenSpacing.space1),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: EdenSpacing.space2,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: EdenColors.warning.withValues(alpha: 0.15),
                  borderRadius: EdenRadii.borderRadiusFull,
                ),
                child: Text(
                  'Bottleneck',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? EdenColors.warning
                        : EdenColors.gold[700],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildArrow(bool isDark) {
    final arrowColor =
        isDark ? EdenColors.neutral[600]! : EdenColors.neutral[300]!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: EdenSpacing.space1),
      child: SizedBox(
        width: 32,
        height: 2,
        child: CustomPaint(
          painter: _ArrowPainter(color: arrowColor),
        ),
      ),
    );
  }

  static String _formatDays(double days) {
    if (days == days.roundToDouble()) {
      return '${days.toInt()} ${days == 1 ? 'day' : 'days'}';
    }
    return '${days.toStringAsFixed(1)} days';
  }
}

class _ArrowPainter extends CustomPainter {
  _ArrowPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final midY = size.height / 2;
    // Line
    canvas.drawLine(Offset(0, midY), Offset(size.width - 6, midY), paint);
    // Arrowhead
    final path = Path()
      ..moveTo(size.width - 8, midY - 4)
      ..lineTo(size.width, midY)
      ..lineTo(size.width - 8, midY + 4);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter old) => old.color != color;
}
