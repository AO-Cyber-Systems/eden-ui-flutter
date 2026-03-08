import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';

/// Mirrors the eden_skeleton Rails component — loading placeholders.
class EdenSkeleton extends StatefulWidget {
  const EdenSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius,
    this.circle = false,
  });

  /// Text-line skeleton.
  const EdenSkeleton.text({super.key, this.width = double.infinity})
      : height = 14,
        borderRadius = null,
        circle = false;

  /// Circular skeleton (e.g. avatar placeholder).
  const EdenSkeleton.circle({super.key, double size = 40})
      : width = size,
        height = size,
        borderRadius = null,
        circle = true;

  /// Rectangular block skeleton.
  const EdenSkeleton.block({super.key, this.width = double.infinity, this.height = 120})
      : borderRadius = null,
        circle = false;

  final double? width;
  final double height;
  final BorderRadius? borderRadius;
  final bool circle;

  @override
  State<EdenSkeleton> createState() => _EdenSkeletonState();
}

class _EdenSkeletonState extends State<EdenSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? EdenColors.neutral[800]! : EdenColors.neutral[200]!;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: baseColor.withValues(alpha: _animation.value),
            borderRadius: widget.circle
                ? null
                : (widget.borderRadius ?? EdenRadii.borderRadiusMd),
            shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
          ),
        );
      },
    );
  }
}
