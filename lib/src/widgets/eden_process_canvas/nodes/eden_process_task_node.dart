import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../tokens/radii.dart';
import '../../eden_diagram/eden_diagram_exports.dart';
import '../process_models.dart';
import '../process_runtime_component_registry.dart';
import 'eden_process_node_renderer.dart';

/// Process-flow Task node — parity row N-5.
///
/// 160-200pt card showing a single task with its runtime-component icon
/// (looked up from `EdenProcessRuntimeComponentRegistry`), display name,
/// optional description, requirement badges (Photo/Sig/Approve when set),
/// Optional badge when `isRequired == false`, and a form-field count badge
/// when `runtimeComponent == 'form'` and the config carries a `fields`
/// list. Hover-show edit + delete buttons.
///
/// **Note:** in objective 006 v1, the graph builder does NOT emit standalone
/// task nodes — tasks render inline within `EdenProcessTaskGroupNode`. This
/// widget exists for dispatch completeness, future workflow nodes that wrap
/// tasks (objective A4-b WorkflowDesigner), and consumers who want
/// standalone-task canvas rendering.
class EdenProcessTaskNode extends StatefulWidget {
  const EdenProcessTaskNode({
    super.key,
    required this.context,
    required this.config,
  });

  final EdenDiagramNodeContext context;
  final EdenProcessNodeRendererConfig config;

  @override
  State<EdenProcessTaskNode> createState() => _EdenProcessTaskNodeState();
}

class _EdenProcessTaskNodeState extends State<EdenProcessTaskNode> {
  bool _hovered = false;
  bool _editing = false;
  late TextEditingController _nameCtrl;
  final FocusNode _nameFocus = FocusNode();

  int get _taskId => widget.context.node.data['taskId'] as int;
  EdenProcessTaskTemplate? get _task => widget.config.tasksById[_taskId];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: _task?.displayName ?? '');
    _nameFocus.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _nameFocus.removeListener(_onFocusChange);
    _nameCtrl.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_nameFocus.hasFocus && _editing) _commit(save: true);
  }

  void _enterEdit() {
    setState(() {
      _nameCtrl.text = _task?.displayName ?? '';
      _editing = true;
    });
    Future.microtask(() {
      if (mounted) _nameFocus.requestFocus();
    });
  }

  void _commit({required bool save}) {
    if (save) {
      final trimmed = _nameCtrl.text.trim();
      if (trimmed.isNotEmpty && trimmed != _task?.displayName) {
        widget.config.onUpdateTask
            ?.call(_taskId, {'displayName': trimmed});
      }
    }
    if (mounted) setState(() => _editing = false);
  }

  IconData _icon() {
    final task = _task;
    if (task == null) return Icons.check_box;
    final component = EdenProcessRuntimeComponentRegistry.instance
        .lookup(task.runtimeComponent);
    return component?.icon ?? Icons.check_box;
  }

  int? _formFieldCount() {
    final task = _task;
    if (task == null || task.runtimeComponent != 'form') return null;
    final fields = task.runtimeComponentConfig['fields'];
    if (fields is List) return fields.length;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final task = _task;
    if (task == null) return _MissingTaskFallback(taskId: _taskId);

    final theme = Theme.of(context);
    final isSelected = widget.context.selected;
    final isDropTarget = widget.context.dropTarget;
    final fieldCount = _formFieldCount();

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        constraints: const BoxConstraints(minWidth: 160, maxWidth: 220),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: EdenRadii.borderRadiusLg,
          border: Border.all(
            color: isDropTarget || isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: isDropTarget || isSelected ? 2 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: EdenRadii.borderRadiusSm,
                  ),
                  child: Icon(
                    _icon(),
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _editing
                      ? _buildNameField(theme)
                      : GestureDetector(
                          onTap: _enterEdit,
                          child: Text(
                            task.displayName,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                ),
                AnimatedOpacity(
                  opacity: _hovered ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 120),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 14),
                        tooltip: 'Edit task',
                        visualDensity: VisualDensity.compact,
                        onPressed: () =>
                            widget.config.onOpenTaskEditor?.call(_taskId),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 14),
                        color: theme.colorScheme.error,
                        tooltip: 'Delete',
                        visualDensity: VisualDensity.compact,
                        onPressed: () =>
                            widget.config.onDeleteTask?.call(_taskId),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (task.description != null && task.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  task.description!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  if (!task.isRequired) _Badge(label: 'Optional', muted: true),
                  if (task.photoRequired) _Badge(label: 'Photo'),
                  if (task.signatureRequired) _Badge(label: 'Sig'),
                  if (task.approvalRequired) _Badge(label: 'Approve'),
                  if (fieldCount != null) _Badge(label: '$fieldCount fields'),
                ],
              ),
            ),
            if (task.runtimeComponent == 'form')
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: TextButton.icon(
                  onPressed: widget.config.onOpenTaskFormFieldsEditor == null
                      ? null
                      : () => widget.config.onOpenTaskFormFieldsEditor!
                          .call(_taskId),
                  icon: const Icon(Icons.tune, size: 14),
                  label: const Text('Configure Fields'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField(ThemeData theme) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            _commit(save: true);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            _commit(save: false);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: TextField(
        controller: _nameCtrl,
        focusNode: _nameFocus,
        style: theme.textTheme.bodyMedium
            ?.copyWith(fontWeight: FontWeight.w600),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, this.muted = false});

  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: muted
            ? theme.colorScheme.surfaceContainerHighest
            : theme.colorScheme.primary.withValues(alpha: 0.08),
        border: muted
            ? null
            : Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.4),
              ),
        borderRadius: EdenRadii.borderRadiusSm,
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: muted
              ? theme.colorScheme.onSurfaceVariant
              : theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _MissingTaskFallback extends StatelessWidget {
  const _MissingTaskFallback({required this.taskId});

  final int taskId;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red),
          color: Colors.red.shade50,
        ),
        padding: const EdgeInsets.all(4),
        child: Text(
          'Missing task $taskId',
          style: const TextStyle(fontSize: 10, color: Colors.red),
        ),
      );
}
