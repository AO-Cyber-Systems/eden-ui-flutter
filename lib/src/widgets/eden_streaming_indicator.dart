import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// Size variants for the streaming indicator.
enum EdenStreamingIndicatorSize { sm, md, lg }

/// Inline indicator showing streaming/loading state for AI content.
class EdenStreamingIndicator extends StatefulWidget {
  const EdenStreamingIndicator({
    super.key,
    this.label,
    this.size = EdenStreamingIndicatorSize.md,
    this.color,
  });

  final String? label;
  final EdenStreamingIndicatorSize size;
  final Color? color;

  @override
  State<EdenStreamingIndicator> createState() => _EdenStreamingIndicatorState();
}

class _EdenStreamingIndicatorState extends State<EdenStreamingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _shimmerAnimation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _defaultLabel {
    switch (widget.size) {
      case EdenStreamingIndicatorSize.sm:
        return '';
      case EdenStreamingIndicatorSize.md:
        return 'Generating...';
      case EdenStreamingIndicatorSize.lg:
        return 'Generating...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = widget.color ?? theme.colorScheme.primary;
    final label = widget.label ?? _defaultLabel;

    switch (widget.size) {
      case EdenStreamingIndicatorSize.sm:
        return _buildDots(isDark, accent);
      case EdenStreamingIndicatorSize.md:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDots(isDark, accent),
            if (label.isNotEmpty) ...[
              const SizedBox(width: EdenSpacing.space2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? EdenColors.neutral[400]
                      : EdenColors.neutral[500],
                ),
              ),
            ],
          ],
        );
      case EdenStreamingIndicatorSize.lg:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (label.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: EdenSpacing.space1),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? EdenColors.neutral[400]
                        : EdenColors.neutral[500],
                  ),
                ),
              ),
            _buildShimmerBar(isDark, accent),
          ],
        );
    }
  }

  Widget _buildDots(bool isDark, Color accent) {
    return _PulsingDots(animation: _controller, color: accent);
  }

  Widget _buildShimmerBar(bool isDark, Color accent) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          height: 4,
          width: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(EdenRadii.full),
            gradient: LinearGradient(
              begin: Alignment(_shimmerAnimation.value - 1, 0),
              end: Alignment(_shimmerAnimation.value, 0),
              colors: [
                isDark
                    ? EdenColors.neutral[700]!
                    : EdenColors.neutral[200]!,
                accent.withValues(alpha: 0.6),
                isDark
                    ? EdenColors.neutral[700]!
                    : EdenColors.neutral[200]!,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PulsingDots extends StatelessWidget {
  const _PulsingDots({required this.animation, required this.color});

  final AnimationController animation;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i * 0.2;
            final t = ((animation.value - delay) % 1.0).clamp(0.0, 1.0);
            final opacity = 0.3 + 0.7 * (0.5 + 0.5 * _pulse(t));
            return Padding(
              padding: EdgeInsets.only(left: i > 0 ? 3 : 0),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  double _pulse(double t) {
    // Sine-based pulse for smooth cycling
    return (t < 0.5) ? (t * 2) : (2 - t * 2);
  }
}
