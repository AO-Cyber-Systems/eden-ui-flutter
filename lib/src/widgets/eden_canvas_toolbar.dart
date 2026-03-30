import 'package:flutter/material.dart';

/// Action button definition for [EdenCanvasToolbar].
class EdenCanvasToolbarAction {
  const EdenCanvasToolbarAction({
    required this.label,
    required this.icon,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
}

/// Toolbar for interactive canvas views with action buttons and zoom controls.
///
/// Shows configurable action buttons on the left and zoom in/out/fit controls
/// on the right with a percentage display. Works with any canvas that manages
/// a zoom level externally.
///
/// ```dart
/// EdenCanvasToolbar(
///   zoomLevel: 1.0,
///   onZoomIn: () => zoom(0.1),
///   onZoomOut: () => zoom(-0.1),
///   onZoomFit: () => resetZoom(),
///   actions: [
///     EdenCanvasToolbarAction(label: '+ Phase', icon: Icons.view_stream_outlined, onTap: addPhase),
///     EdenCanvasToolbarAction(label: '+ Task', icon: Icons.add_task_outlined, onTap: addTask),
///   ],
/// )
/// ```
class EdenCanvasToolbar extends StatelessWidget {
  const EdenCanvasToolbar({
    super.key,
    required this.zoomLevel,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onZoomFit,
    this.actions = const [],
    this.height = 44,
  });

  /// Current zoom level (1.0 = 100%).
  final double zoomLevel;

  /// Called to zoom in (typically +0.1).
  final VoidCallback onZoomIn;

  /// Called to zoom out (typically -0.1).
  final VoidCallback onZoomOut;

  /// Called to reset zoom to fit/100%.
  final VoidCallback onZoomFit;

  /// Action buttons shown on the left side of the toolbar.
  final List<EdenCanvasToolbarAction> actions;

  /// Toolbar height.
  final double height;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          for (int i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _ActionButton(action: actions[i]),
          ],
          const Spacer(),
          Text(
            'Zoom:',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          const SizedBox(width: 8),
          _ZoomButton(icon: Icons.remove, onTap: onZoomOut),
          const SizedBox(width: 4),
          SizedBox(
            width: 40,
            child: Text(
              '${(zoomLevel * 100).round()}%',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: cs.onSurface),
            ),
          ),
          const SizedBox(width: 4),
          _ZoomButton(icon: Icons.add, onTap: onZoomIn),
          const SizedBox(width: 8),
          _ZoomButton(
            icon: Icons.fit_screen_outlined,
            onTap: onZoomFit,
            label: 'Fit',
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action});

  final EdenCanvasToolbarAction action;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return OutlinedButton.icon(
      onPressed: action.onTap,
      icon: Icon(action.icon, size: 16),
      label: Text(action.label, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        minimumSize: const Size(0, 30),
        side: BorderSide(color: cs.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({
    required this.icon,
    required this.onTap,
    this.label,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (label != null) {
      return OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 14),
        label: Text(label!, style: const TextStyle(fontSize: 11)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          minimumSize: const Size(0, 28),
          side: BorderSide(color: cs.outlineVariant),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      );
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: cs.onSurface),
      ),
    );
  }
}
