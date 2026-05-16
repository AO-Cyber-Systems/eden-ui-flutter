import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../../tokens/radii.dart';
import '../../tokens/spacing.dart';
import 'scheduler_models.dart';
import 'scheduler_time_math.dart';

/// Visual + interactive primitive for a single event in [EdenScheduler].
/// Composes:
///
/// - **title + customer / location** rendering with truck-color background
/// - **dispatch readiness border** (red / yellow / green) when
///   [EdenSchedulerEvent.readiness] is non-null OR a dispatch issue string is
///   provided
/// - **drag-to-reschedule** via [Draggable] / [LongPressDraggable] (platform
///   branch — desktop uses Draggable, mobile uses LongPressDraggable for
///   tap/drag disambiguation)
/// - **top + bottom resize handles** with 15-min-snapped delta math via
///   [EdenSchedulerTimeMath.yDeltaPxToMinutes]
/// - **resize preview chip** floating above the block during resize
///
/// Mirrors donor `AppointmentCard` + `ResizableAppointmentCard`
/// (`EnhancedCalendar.tsx:785..1377`). Parity rows TG-6, DR-1, DR-2, DR-5.
class EdenSchedulerEventBlock extends StatefulWidget {
  const EdenSchedulerEventBlock({
    super.key,
    required this.event,
    this.height,
    this.compact = false,
    this.slotHeight = 60.0,
    this.onTap,
    this.onMove,
    this.onResize,
    this.draggable = true,
    this.resizable = true,
  });

  /// Event to render.
  final EdenSchedulerEvent event;

  /// Height of the block (drives resize-handle visibility — handles only
  /// render when there's room).
  final double? height;

  /// Compact mode collapses subtitle / metadata for narrow columns.
  final bool compact;

  /// Slot height (pt per hour) — used by resize-handle delta math.
  final double slotHeight;

  /// Fires on a non-drag tap.
  final ValueChanged<EdenSchedulerEvent>? onTap;

  /// Fires after a successful drag-to-move with the new start/end times.
  /// Caller computes new start/end from the drop position before invoking
  /// (typical: a parent [DragTarget] does the math).
  final void Function(EdenSchedulerEvent event, DateTime newStart,
      DateTime newEnd)? onMove;

  /// Fires after a successful resize with the new start/end times.
  final void Function(EdenSchedulerEvent event, DateTime newStart,
      DateTime newEnd)? onResize;

  /// When false, the block is not draggable (read-only mode).
  final bool draggable;

  /// When false, resize handles are not rendered.
  final bool resizable;

  @override
  State<EdenSchedulerEventBlock> createState() =>
      _EdenSchedulerEventBlockState();
}

class _EdenSchedulerEventBlockState extends State<EdenSchedulerEventBlock> {
  DateTime? _resizePreviewStart;
  DateTime? _resizePreviewEnd;

  Color _borderColorForReadiness(BuildContext context) {
    final readiness = widget.event.readiness;
    if (readiness == null && widget.event.dispatchIssue == null) {
      return Colors.transparent;
    }
    if (widget.event.dispatchIssue != null) return EdenColors.error;
    switch (readiness!) {
      case EdenSchedulerEventReadiness.ready:
        return EdenColors.success;
      case EdenSchedulerEventReadiness.warning:
        return EdenColors.warning;
      case EdenSchedulerEventReadiness.urgent:
        return EdenColors.error;
    }
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.event.color ?? theme.colorScheme.primary;
    final readinessBorderColor = _borderColorForReadiness(context);
    final hasReadinessBorder = readinessBorderColor != Colors.transparent;

    final bg = color.withValues(alpha: 0.15);
    final leftBar = BorderSide(color: color, width: 3);
    final readinessBorder = hasReadinessBorder
        ? Border.all(color: readinessBorderColor, width: 2)
        : null;

    return Semantics(
      button: widget.onTap != null,
      label: 'Event: ${widget.event.title}',
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: EdenRadii.borderRadiusSm,
          border: readinessBorder ??
              Border(left: leftBar),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: EdenSpacing.space2,
          vertical: EdenSpacing.space1,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.event.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: widget.compact ? 11 : 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            if (!widget.compact && widget.event.location != null)
              Text(
                widget.event.location!.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            if (!widget.compact && widget.event.assignee != null)
              Text(
                widget.event.assignee!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// True when the running platform should use [LongPressDraggable] (touch
  /// devices need long-press to disambiguate tap-vs-drag). Desktop/web use
  /// the snappier non-long-press [Draggable].
  bool _useLongPressDraggable(BuildContext context) {
    if (kIsWeb) return false;
    final platform = Theme.of(context).platform;
    return platform == TargetPlatform.android || platform == TargetPlatform.iOS;
  }

  void _onResizeUpdate(double deltaPx, {required bool isTopHandle}) {
    final deltaMin = EdenSchedulerTimeMath.yDeltaPxToMinutes(
        deltaPx, widget.slotHeight);
    final newStart = isTopHandle
        ? widget.event.start.add(Duration(minutes: deltaMin))
        : widget.event.start;
    var newEnd = isTopHandle
        ? widget.event.end
        : widget.event.end.add(Duration(minutes: deltaMin));
    // Clamp to >=15 min duration.
    if (newEnd.difference(newStart).inMinutes < 15) {
      if (isTopHandle) {
        // Top handle moved too far down — clamp to end - 15min.
        setState(() {
          _resizePreviewStart = newEnd.subtract(const Duration(minutes: 15));
          _resizePreviewEnd = newEnd;
        });
        return;
      } else {
        newEnd = newStart.add(const Duration(minutes: 15));
      }
    }
    setState(() {
      _resizePreviewStart = newStart;
      _resizePreviewEnd = newEnd;
    });
  }

  void _onResizeEnd() {
    final s = _resizePreviewStart;
    final e = _resizePreviewEnd;
    if (s != null && e != null) {
      widget.onResize?.call(widget.event, s, e);
    }
    setState(() {
      _resizePreviewStart = null;
      _resizePreviewEnd = null;
    });
  }

  void _onResizeCancel() {
    setState(() {
      _resizePreviewStart = null;
      _resizePreviewEnd = null;
    });
  }

  Widget _buildResizeHandle({required bool isTopHandle}) {
    // 6pt touch region, 2pt visible bar.
    return MouseRegion(
      cursor: SystemMouseCursors.resizeRow,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: (_) {
          _resizePreviewStart ??= widget.event.start;
          _resizePreviewEnd ??= widget.event.end;
        },
        onVerticalDragUpdate: (d) {
          _onResizeUpdate(d.delta.dy, isTopHandle: isTopHandle);
        },
        onVerticalDragEnd: (_) => _onResizeEnd(),
        onVerticalDragCancel: _onResizeCancel,
        child: SizedBox(
          height: 6,
          child: Center(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(
                      alpha: 0.5,
                    ),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewChip() {
    final s = _resizePreviewStart;
    final e = _resizePreviewEnd;
    if (s == null || e == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final startText = EdenSchedulerTimeMath.formatTime(
      '${s.hour.toString().padLeft(2, '0')}:'
      '${s.minute.toString().padLeft(2, '0')}',
    );
    final endText = EdenSchedulerTimeMath.formatTime(
      '${e.hour.toString().padLeft(2, '0')}:'
      '${e.minute.toString().padLeft(2, '0')}',
    );
    return Positioned(
      top: -28,
      left: 0,
      right: 0,
      child: Center(
        child: Material(
          color: theme.colorScheme.primary,
          borderRadius: EdenRadii.borderRadiusSm,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: EdenSpacing.space2,
              vertical: 2,
            ),
            child: Text(
              '$startText – $endText',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);

    Widget interactive = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap == null ? null : () => widget.onTap!(widget.event),
      child: content,
    );

    // Drag wrapping.
    if (widget.draggable && widget.onMove != null) {
      final useLongPress = _useLongPressDraggable(context);
      final feedback = Opacity(
        opacity: 0.7,
        child: Material(
          color: Colors.transparent,
          child: SizedBox(
            width: 220,
            child: content,
          ),
        ),
      );
      final ghost = Opacity(opacity: 0.3, child: content);
      interactive = useLongPress
          ? LongPressDraggable<EdenSchedulerEvent>(
              data: widget.event,
              feedback: feedback,
              childWhenDragging: ghost,
              child: interactive,
            )
          : Draggable<EdenSchedulerEvent>(
              data: widget.event,
              feedback: feedback,
              childWhenDragging: ghost,
              child: interactive,
            );
    }

    // Resize handles overlay.
    if (widget.resizable && widget.onResize != null) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          interactive,
          // Top handle.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildResizeHandle(isTopHandle: true),
          ),
          // Bottom handle.
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildResizeHandle(isTopHandle: false),
          ),
          _buildPreviewChip(),
        ],
      );
    }

    return interactive;
  }
}
