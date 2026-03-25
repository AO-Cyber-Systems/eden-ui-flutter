import 'package:flutter/material.dart';
import '../tokens/colors.dart';

/// Reusable bouncing dots animation widget.
class EdenBouncingDots extends StatefulWidget {
  const EdenBouncingDots({
    super.key,
    this.dotCount = 3,
    this.dotSize = 8,
    this.color,
    this.duration = const Duration(milliseconds: 600),
    this.staggerDelay = const Duration(milliseconds: 150),
  });

  final int dotCount;
  final double dotSize;
  final Color? color;
  final Duration duration;
  final Duration staggerDelay;

  @override
  State<EdenBouncingDots> createState() => _EdenBouncingDotsState();
}

class _EdenBouncingDotsState extends State<EdenBouncingDots>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.dotCount,
      (i) => AnimationController(vsync: this, duration: widget.duration),
    );
    _animations = _controllers
        .map((c) => Tween<double>(begin: 0, end: -6).animate(
              CurvedAnimation(parent: c, curve: Curves.easeInOut),
            ))
        .toList();

    for (int i = 0; i < widget.dotCount; i++) {
      Future.delayed(widget.staggerDelay * i, () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dotColor =
        widget.color ?? (isDark ? EdenColors.neutral[500]! : EdenColors.neutral[400]!);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < widget.dotCount; i++) ...[
          if (i > 0) SizedBox(width: widget.dotSize * 0.5),
          AnimatedBuilder(
            animation: _animations[i],
            builder: (context, child) => Transform.translate(
              offset: Offset(0, _animations[i].value),
              child: Container(
                width: widget.dotSize,
                height: widget.dotSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
