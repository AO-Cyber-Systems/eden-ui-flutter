import 'package:flutter/material.dart';

import '../../../tokens/radii.dart';
import '../../eden_diagram/eden_diagram_exports.dart';
import '../process_runtime_component_registry.dart';

/// Process-flow Orphan node — parity row N-7.
///
/// Renders a colored card sized 160-200pt wide with:
/// - a type-driven icon (Phase = Layers, TaskGroup = Folder, Decision =
///   call_split, Task = registry-driven runtime-component icon or check_box
///   fallback)
/// - a display name + type label
/// - a hover-reveal delete button (desktop pointer); on touch surfaces the
///   button stays hidden — call `onDelete` from a long-press handler upstream
///   if a touch affordance is needed.
///
/// Selection ring drawn here when `context.selected == true`.
class EdenProcessOrphanNode extends StatefulWidget {
  const EdenProcessOrphanNode({
    super.key,
    required this.context,
    this.onDelete,
  });

  final EdenDiagramNodeContext context;
  final void Function(String nodeId)? onDelete;

  @override
  State<EdenProcessOrphanNode> createState() => _EdenProcessOrphanNodeState();
}

class _EdenProcessOrphanNodeState extends State<EdenProcessOrphanNode> {
  bool _hovered = false;

  String get _orphanType =>
      widget.context.node.data['orphanType'] as String? ?? 'task';
  String get _displayName =>
      widget.context.node.data['displayName'] as String? ?? 'New Element';
  Map<String, dynamic> get _config =>
      (widget.context.node.data['config'] as Map<String, dynamic>?) ??
          const {};

  IconData _icon() {
    switch (_orphanType) {
      case 'phase':
        return Icons.layers;
      case 'taskGroup':
        return Icons.folder;
      case 'decision':
        return Icons.call_split;
      default:
        // task
        final runtimeId = _config['runtimeComponent'] as String?;
        if (runtimeId != null) {
          final comp =
              EdenProcessRuntimeComponentRegistry.instance.lookup(runtimeId);
          if (comp != null) return comp.icon;
        }
        return Icons.check_box;
    }
  }

  ({Color border, Color fill}) _colors(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (_orphanType) {
      case 'phase':
        return (
          border: Colors.blue.shade300,
          fill: isDark ? Colors.blue.shade900 : Colors.blue.shade50,
        );
      case 'taskGroup':
        return (
          border: Colors.grey.shade300,
          fill: isDark ? Colors.grey.shade800 : Colors.white,
        );
      case 'decision':
        return (
          border: Colors.amber.shade300,
          fill: isDark ? Colors.amber.shade900 : Colors.amber.shade50,
        );
      default:
        return (
          border: Colors.green.shade300,
          fill: isDark ? Colors.grey.shade800 : Colors.white,
        );
    }
  }

  String _typeLabel() {
    switch (_orphanType) {
      case 'phase':
        return 'Phase';
      case 'taskGroup':
        return 'Task Group';
      case 'decision':
        return 'Decision';
      default:
        return 'Task';
    }
  }

  @override
  Widget build(BuildContext buildContext) {
    final theme = Theme.of(buildContext);
    final colors = _colors(buildContext);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        decoration: BoxDecoration(
          color: colors.fill,
          borderRadius: EdenRadii.borderRadiusLg,
          border: Border.all(
            color: widget.context.selected
                ? theme.colorScheme.primary
                : colors.border,
            width: widget.context.selected ? 2 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: EdenRadii.borderRadiusSm,
              ),
              child: Icon(
                _icon(),
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _displayName,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _typeLabel(),
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            AnimatedOpacity(
              opacity: _hovered ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 120),
              child: IconButton(
                icon: const Icon(Icons.delete_outline, size: 16),
                color: theme.colorScheme.error,
                tooltip: 'Delete',
                onPressed: widget.onDelete == null
                    ? null
                    : () => widget.onDelete!(widget.context.node.id),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
