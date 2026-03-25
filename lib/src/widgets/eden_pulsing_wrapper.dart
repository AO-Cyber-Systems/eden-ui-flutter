import 'package:flutter/material.dart';

/// Wraps any child widget with a pulsing opacity animation.
class EdenPulsingWrapper extends StatefulWidget {
  const EdenPulsingWrapper({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1200),
    this.minOpacity = 0.5,
    this.maxOpacity = 1.0,
    this.enabled = true,
  });

  final Widget child;
  final Duration duration;
  final double minOpacity;
  final double maxOpacity;
  final bool enabled;

  @override
  State<EdenPulsingWrapper> createState() => _EdenPulsingWrapperState();
}

class _EdenPulsingWrapperState extends State<EdenPulsingWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(
      begin: widget.maxOpacity,
      end: widget.minOpacity,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.enabled) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(EdenPulsingWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !oldWidget.enabled) {
      _controller.repeat(reverse: true);
    } else if (!widget.enabled && oldWidget.enabled) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Opacity(
        opacity: _animation.value,
        child: child,
      ),
      child: widget.child,
    );
  }
}
