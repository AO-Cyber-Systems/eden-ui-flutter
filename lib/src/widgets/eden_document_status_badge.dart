import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';

/// Document lifecycle status.
enum EdenDocumentStatus { pending, processing, ready, failed, archived }

/// Badge size presets.
enum EdenDocumentStatusBadgeSize { sm, md }

/// Status badge with pulsing animation for processing states.
class EdenDocumentStatusBadge extends StatefulWidget {
  const EdenDocumentStatusBadge({
    super.key,
    required this.status,
    this.label,
    this.size = EdenDocumentStatusBadgeSize.md,
  });

  final EdenDocumentStatus status;
  final String? label;
  final EdenDocumentStatusBadgeSize size;

  @override
  State<EdenDocumentStatusBadge> createState() =>
      _EdenDocumentStatusBadgeState();
}

class _EdenDocumentStatusBadgeState extends State<EdenDocumentStatusBadge>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _opacity;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
  }

  @override
  void didUpdateWidget(covariant EdenDocumentStatusBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      _controller?.dispose();
      _controller = null;
      _opacity = null;
      _setupAnimation();
    }
  }

  void _setupAnimation() {
    if (widget.status == EdenDocumentStatus.processing) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
      );
      _opacity = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _controller!, curve: Curves.easeInOut),
      );
      _controller!.repeat(reverse: true);
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
    final resolved = _resolveStatus(theme);
    final sizing = _resolveSizing();
    final effectiveLabel = widget.label ?? resolved.label;

    Widget badge = Container(
      padding: sizing.padding,
      decoration: BoxDecoration(
        color: resolved.background,
        borderRadius: EdenRadii.borderRadiusFull,
        border: Border.all(color: resolved.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(resolved.icon, size: sizing.iconSize, color: resolved.foreground),
          SizedBox(width: sizing.gap),
          Text(
            effectiveLabel,
            style: TextStyle(
              fontSize: sizing.fontSize,
              fontWeight: FontWeight.w600,
              color: resolved.foreground,
            ),
          ),
        ],
      ),
    );

    if (_opacity != null) {
      badge = AnimatedBuilder(
        animation: _opacity!,
        builder: (context, child) => Opacity(opacity: _opacity!.value, child: child),
        child: badge,
      );
    }

    return badge;
  }

  _ResolvedStatus _resolveStatus(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    switch (widget.status) {
      case EdenDocumentStatus.pending:
        return _ResolvedStatus(
          label: 'Pending',
          icon: Icons.access_time,
          foreground: isDark ? EdenColors.neutral[300]! : EdenColors.neutral[600]!,
          background: isDark ? EdenColors.neutral[800]! : EdenColors.neutral[100]!,
          border: isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!,
        );
      case EdenDocumentStatus.processing:
        return _ResolvedStatus(
          label: 'Processing',
          icon: Icons.sync,
          foreground: EdenColors.info,
          background: EdenColors.infoBg,
          border: EdenColors.info.withValues(alpha: 0.2),
        );
      case EdenDocumentStatus.ready:
        return _ResolvedStatus(
          label: 'Ready',
          icon: Icons.check_circle_outline,
          foreground: EdenColors.success,
          background: EdenColors.successBg,
          border: EdenColors.success.withValues(alpha: 0.2),
        );
      case EdenDocumentStatus.failed:
        return _ResolvedStatus(
          label: 'Failed',
          icon: Icons.error_outline,
          foreground: EdenColors.error,
          background: EdenColors.errorBg,
          border: EdenColors.error.withValues(alpha: 0.2),
        );
      case EdenDocumentStatus.archived:
        return _ResolvedStatus(
          label: 'Archived',
          icon: Icons.archive_outlined,
          foreground: isDark ? EdenColors.neutral[300]! : EdenColors.neutral[600]!,
          background: isDark ? EdenColors.neutral[800]! : EdenColors.neutral[100]!,
          border: isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!,
        );
    }
  }

  _BadgeSizing _resolveSizing() {
    switch (widget.size) {
      case EdenDocumentStatusBadgeSize.sm:
        return const _BadgeSizing(
          EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          11, 12, 4,
        );
      case EdenDocumentStatusBadgeSize.md:
        return const _BadgeSizing(
          EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          12, 14, 4,
        );
    }
  }
}

class _ResolvedStatus {
  const _ResolvedStatus({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.background,
    required this.border,
  });
  final String label;
  final IconData icon;
  final Color foreground;
  final Color background;
  final Color border;
}

class _BadgeSizing {
  const _BadgeSizing(this.padding, this.fontSize, this.iconSize, this.gap);
  final EdgeInsets padding;
  final double fontSize;
  final double iconSize;
  final double gap;
}
