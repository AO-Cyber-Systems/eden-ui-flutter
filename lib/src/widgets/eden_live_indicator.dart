import 'package:flutter/material.dart';

import '../tokens/colors.dart';

import '../tokens/spacing.dart';

/// Represents the state of a real-time connection.
enum EdenConnectionState {
  /// The connection is active and healthy.
  connected,

  /// The connection has been lost.
  disconnected,

  /// The connection is attempting to re-establish.
  reconnecting,
}

/// A compact indicator widget showing real-time connection status with an
/// animated dot.
///
/// The dot pulses when in [EdenConnectionState.connected] or
/// [EdenConnectionState.reconnecting] states, and remains static when
/// disconnected.
class EdenLiveIndicator extends StatefulWidget {
  /// Creates a live indicator widget.
  const EdenLiveIndicator({
    super.key,
    required this.state,
    this.label,
    this.size = 8,
  });

  /// The current connection state.
  final EdenConnectionState state;

  /// An optional label displayed next to the dot.
  final String? label;

  /// The diameter of the indicator dot in logical pixels.
  final double size;

  @override
  State<EdenLiveIndicator> createState() => _EdenLiveIndicatorState();
}

class _EdenLiveIndicatorState extends State<EdenLiveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _updateAnimation();
  }

  @override
  void didUpdateWidget(EdenLiveIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _updateAnimation();
    }
  }

  void _updateAnimation() {
    if (widget.state == EdenConnectionState.disconnected) {
      _controller.stop();
      _controller.reset();
    } else {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _dotColor {
    switch (widget.state) {
      case EdenConnectionState.connected:
        return EdenColors.success;
      case EdenConnectionState.disconnected:
        return EdenColors.neutral[400]!;
      case EdenConnectionState.reconnecting:
        return EdenColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = _dotColor;

    final dot = widget.state == EdenConnectionState.disconnected
        ? _buildStaticDot(color)
        : AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return _buildAnimatedDot(color, _scaleAnimation.value);
            },
          );

    if (widget.label == null) return dot;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        dot,
        const SizedBox(width: EdenSpacing.space1),
        Text(
          widget.label!,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark ? EdenColors.neutral[400] : EdenColors.neutral[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStaticDot(Color color) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildAnimatedDot(Color color, double scale) {
    return Container(
      width: widget.size * scale,
      height: widget.size * scale,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4 * (scale - 1.0) / 0.3),
            blurRadius: widget.size * (scale - 0.7),
            spreadRadius: widget.size * 0.2 * (scale - 1.0) / 0.3,
          ),
        ],
      ),
    );
  }
}
