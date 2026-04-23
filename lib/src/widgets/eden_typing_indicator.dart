import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';

/// Mirrors the eden_typing_indicator Rails component.
///
/// Animated bouncing dots indicating someone is typing.
class EdenTypingIndicator extends StatefulWidget {
  const EdenTypingIndicator({
    super.key,
    this.sender,
    this.avatar,
  });

  final String? sender;
  final Widget? avatar;

  @override
  State<EdenTypingIndicator> createState() => _EdenTypingIndicatorState();
}

class _EdenTypingIndicatorState extends State<EdenTypingIndicator> with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) => AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    ));
    _animations = _controllers.map((c) => Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: c, curve: Curves.easeInOut),
    )).toList();

    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
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

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (widget.avatar != null) ...[
          widget.avatar!,
          const SizedBox(width: 8),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: EdenSpacing.space4, vertical: EdenSpacing.space3),
          decoration: BoxDecoration(
            color: isDark ? EdenColors.neutral[800] : EdenColors.neutral[100],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(16),
              bottomLeft: Radius.circular(4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                AnimatedBuilder(
                  animation: _animations[i],
                  builder: (context, child) => Transform.translate(
                    offset: Offset(0, _animations[i].value),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? EdenColors.neutral[500] : EdenColors.neutral[400],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
