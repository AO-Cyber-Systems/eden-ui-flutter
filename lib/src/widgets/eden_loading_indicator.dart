import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/durations.dart';
import '../tokens/springs.dart';

enum _IndicatorMode { shapeMorph, shimmer, crossFade }

/// M3 Expressive loading indicator — the default for under-5s loads.
///
/// Three variants:
///
/// * [EdenLoadingIndicator.shapeMorph] — 4 dots morphing between shapes
///   driven by a 1.2s repeat loop. M3 Expressive default.
/// * [EdenLoadingIndicator.shimmer] — sweeping shimmer band; same color
///   conventions as `EdenSkeleton`.
/// * [EdenLoadingIndicator.crossFade] — inline skeleton → content swap
///   (use `EdenSkeletonScope` from TRD 010-08 for larger subtree fades).
///
/// `EdenSpinner` and `EdenSkeleton` are preserved unchanged — this is
/// additive. Use `EdenSpinner` for indeterminate long-running ops;
/// `EdenLoadingIndicator` is for known-short loads (<5s).
class EdenLoadingIndicator extends StatefulWidget {
  const EdenLoadingIndicator.shapeMorph({
    super.key,
    this.size = 48,
    this.color,
  })  : _mode = _IndicatorMode.shapeMorph,
        width = null,
        height = null,
        borderRadius = null,
        skeleton = null,
        content = null,
        isLoading = false;

  const EdenLoadingIndicator.shimmer({
    super.key,
    this.width = 200,
    this.height = 16,
    this.borderRadius,
  })  : _mode = _IndicatorMode.shimmer,
        size = null,
        color = null,
        skeleton = null,
        content = null,
        isLoading = false;

  const EdenLoadingIndicator.crossFade({
    super.key,
    required this.skeleton,
    required this.content,
    required this.isLoading,
  })  : _mode = _IndicatorMode.crossFade,
        size = null,
        color = null,
        width = null,
        height = null,
        borderRadius = null;

  final _IndicatorMode _mode;
  final double? size;
  final Color? color;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? skeleton;
  final Widget? content;
  final bool isLoading;

  @override
  State<EdenLoadingIndicator> createState() => _EdenLoadingIndicatorState();
}

class _EdenLoadingIndicatorState extends State<EdenLoadingIndicator>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    switch (widget._mode) {
      case _IndicatorMode.shapeMorph:
        _controller = AnimationController(
          duration: const Duration(milliseconds: 1200),
          vsync: this,
        )..repeat();
        break;
      case _IndicatorMode.shimmer:
        _controller = AnimationController(
          duration: const Duration(milliseconds: 1500),
          vsync: this,
        )..repeat();
        break;
      case _IndicatorMode.crossFade:
        // AnimatedCrossFade owns its own animation timing; no controller.
        break;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    switch (widget._mode) {
      case _IndicatorMode.shapeMorph:
        final dotColor = widget.color ?? theme.colorScheme.primary;
        return Semantics(
          label: 'Loading',
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: AnimatedBuilder(
              animation: _controller!,
              builder: (context, _) {
                return CustomPaint(
                  painter: _DotMorphPainter(
                    progress: _controller!.value,
                    color: dotColor,
                  ),
                  size: Size(widget.size!, widget.size!),
                );
              },
            ),
          ),
        );
      case _IndicatorMode.shimmer:
        final isDark = theme.brightness == Brightness.dark;
        final baseColor = isDark ? EdenColors.neutral[800]! : EdenColors.neutral[200]!;
        final highlightColor = isDark ? EdenColors.neutral[700]! : EdenColors.neutral[100]!;
        return Semantics(
          label: 'Loading',
          child: SizedBox(
            width: widget.width,
            height: widget.height,
            child: AnimatedBuilder(
              animation: _controller!,
              builder: (context, _) {
                final v = _controller!.value;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: widget.borderRadius ?? BorderRadius.zero,
                    gradient: LinearGradient(
                      colors: [baseColor, highlightColor, baseColor],
                      stops: [
                        (v - 0.3).clamp(0.0, 1.0),
                        v.clamp(0.0, 1.0),
                        (v + 0.3).clamp(0.0, 1.0),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      case _IndicatorMode.crossFade:
        final curve = EdenSprings.curveFor(EdenSprings.smooth);
        return Semantics(
          label: 'Loading',
          child: AnimatedCrossFade(
            firstChild: widget.skeleton!,
            secondChild: widget.content!,
            crossFadeState: widget.isLoading
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: EdenDurations.normal,
            firstCurve: curve,
            secondCurve: curve,
          ),
        );
    }
  }
}

/// Custom painter for the 4-dot shape-morph variant.
///
/// Each dot's per-frame phase = (progress + i * 0.15) mod 1.0. The phase
/// interpolates dot scale + radius so circles "morph" into rounded-squares
/// and back. Stagger per dot gives the visual rhythm of M3 Expressive's
/// canonical loader.
class _DotMorphPainter extends CustomPainter {
  _DotMorphPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const dotCount = 4;
    final spacing = size.width / (dotCount + 1);
    final baseDotSize = size.height * 0.45;
    final paint = Paint()..color = color..style = PaintingStyle.fill;

    for (int i = 0; i < dotCount; i++) {
      final phase = (progress + i * 0.15) % 1.0;
      // Smooth oscillation: scale dips at phase 0.5, returns at 0/1.
      final scale = 0.7 + 0.3 * (1 - (phase * 2 - 1).abs());
      // Corner radius oscillates: full-circle at phase 0, rounded-square at 0.5.
      final cornerR = baseDotSize * (0.5 - 0.25 * (phase * 2 - 1).abs() * 2)
          .clamp(0.0, 0.5);
      final dotW = baseDotSize * scale;
      final cx = spacing * (i + 1);
      final cy = size.height / 2;
      final rect = Rect.fromCenter(center: Offset(cx, cy), width: dotW, height: dotW);
      final rrect = RRect.fromRectAndRadius(rect, Radius.circular(cornerR));
      canvas.drawRRect(rrect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DotMorphPainter old) =>
      old.progress != progress || old.color != color;
}
