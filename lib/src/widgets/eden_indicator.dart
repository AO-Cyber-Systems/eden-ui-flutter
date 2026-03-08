import 'package:flutter/material.dart';
import '../tokens/colors.dart';

/// Variant colors for the status indicator.
enum EdenIndicatorVariant { success, warning, danger, info, neutral }

/// Mirrors the eden_indicator Rails component.
///
/// A small status dot with optional ping animation.
class EdenIndicator extends StatefulWidget {
  const EdenIndicator({
    super.key,
    this.variant = EdenIndicatorVariant.success,
    this.size = 8,
    this.ping = false,
    this.label,
  });

  final EdenIndicatorVariant variant;
  final double size;
  final bool ping;
  final String? label;

  @override
  State<EdenIndicator> createState() => _EdenIndicatorState();
}

class _EdenIndicatorState extends State<EdenIndicator> with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _scaleAnimation;
  Animation<double>? _opacityAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.ping) _initAnimation();
  }

  @override
  void didUpdateWidget(EdenIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ping && !oldWidget.ping) {
      _initAnimation();
    } else if (!widget.ping && oldWidget.ping) {
      _controller?.dispose();
      _controller = null;
    }
  }

  void _initAnimation() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 2.5).animate(
      CurvedAnimation(parent: _controller!, curve: Curves.easeOut),
    );
    _opacityAnimation = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _controller!, curve: Curves.easeOut),
    );
    _controller!.repeat();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Color _resolveColor() {
    switch (widget.variant) {
      case EdenIndicatorVariant.success:
        return EdenColors.success;
      case EdenIndicatorVariant.warning:
        return EdenColors.warning;
      case EdenIndicatorVariant.danger:
        return EdenColors.error;
      case EdenIndicatorVariant.info:
        return EdenColors.info;
      case EdenIndicatorVariant.neutral:
        return EdenColors.neutral[400]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _resolveColor();

    final dot = SizedBox(
      width: widget.size * 2.5,
      height: widget.size * 2.5,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (widget.ping && _controller != null)
              AnimatedBuilder(
                animation: _controller!,
                builder: (context, child) => Transform.scale(
                  scale: _scaleAnimation!.value,
                  child: Opacity(
                    opacity: _opacityAnimation!.value,
                    child: Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                      ),
                    ),
                  ),
                ),
              ),
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.label != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          dot,
          const SizedBox(width: 6),
          Text(
            widget.label!,
            style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      );
    }

    return dot;
  }
}
