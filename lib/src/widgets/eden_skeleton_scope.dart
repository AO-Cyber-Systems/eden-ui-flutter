import 'package:flutter/material.dart';
import '../tokens/durations.dart';
import '../tokens/springs.dart';

/// Cross-fades a skeleton subtree to its real content subtree when [isLoading]
/// toggles.
///
/// Distinct from `EdenLoadingIndicator.crossFade` (TRD 010-05): that one is a
/// lightweight inline swap helper for identical-shape items.
/// [EdenSkeletonScope] is for SCOPE-of-a-larger-subtree fades (entire card,
/// entire list section, entire dashboard panel) where skeleton and content
/// may have different internal shapes. Both children stay in the tree for the
/// duration of the transition so Hero / Focus / animation state is preserved.
///
/// Composes existing `EdenSkeleton` (no replacement).
///
/// Usage:
/// ```dart
/// EdenSkeletonScope(
///   isLoading: state.isLoading,
///   skeleton: Column(children: [
///     EdenSkeleton.text(width: 200),
///     SizedBox(height: 8),
///     EdenSkeleton.block(width: double.infinity, height: 120),
///   ]),
///   content: MyDashboardPanel(data: state.data!),
/// )
/// ```
class EdenSkeletonScope extends StatefulWidget {
  const EdenSkeletonScope({
    super.key,
    required this.isLoading,
    required this.skeleton,
    required this.content,
    this.fadeDuration = EdenDurations.normal,
    this.curve,
  });

  final bool isLoading;
  final Widget skeleton;
  final Widget content;
  final Duration fadeDuration;
  final Curve? curve;

  @override
  State<EdenSkeletonScope> createState() => _EdenSkeletonScopeState();
}

class _EdenSkeletonScopeState extends State<EdenSkeletonScope>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late CurvedAnimation _curved;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.fadeDuration,
      vsync: this,
      value: widget.isLoading ? 1.0 : 0.0,
    );
    _curved = CurvedAnimation(
      parent: _controller,
      curve: widget.curve ?? EdenSprings.curveFor(EdenSprings.smooth),
    );
  }

  @override
  void didUpdateWidget(EdenSkeletonScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fadeDuration != widget.fadeDuration) {
      _controller.duration = widget.fadeDuration;
    }
    if (oldWidget.curve != widget.curve) {
      _curved.dispose();
      _curved = CurvedAnimation(
        parent: _controller,
        curve: widget.curve ?? EdenSprings.curveFor(EdenSprings.smooth),
      );
    }
    if (oldWidget.isLoading != widget.isLoading) {
      if (widget.isLoading) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _curved.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curved,
      builder: (context, _) {
        final loadingOpacity = _curved.value.clamp(0.0, 1.0);
        final contentOpacity = (1.0 - _curved.value).clamp(0.0, 1.0);
        return Stack(
          alignment: Alignment.topLeft,
          children: [
            // Content beneath; receives pointer events only when fully visible.
            IgnorePointer(
              ignoring: contentOpacity == 0.0,
              child: Opacity(
                opacity: contentOpacity,
                child: widget.content,
              ),
            ),
            // Skeleton overlay; receives no pointer events; semantically excluded
            // unless announcing 'Loading content' while visible.
            IgnorePointer(
              ignoring: true,
              child: Opacity(
                opacity: loadingOpacity,
                child: ExcludeSemantics(
                  excluding: loadingOpacity == 0.0,
                  child: Semantics(
                    label: 'Loading content',
                    child: widget.skeleton,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
