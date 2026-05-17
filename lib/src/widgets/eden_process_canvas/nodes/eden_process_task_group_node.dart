import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../tokens/radii.dart';
import '../../eden_diagram/eden_diagram_exports.dart';
import '../process_models.dart';
import 'eden_process_node_renderer.dart';

/// Process-flow Task Group node — parity row N-4.
///
/// 240-280pt card with expandable inline task list, per-task inline rename,
/// 4 inline property toggle dots (Req/Photo/Sig/Approve), reorder arrows,
/// delete + advanced-edit per task, workflow-hooks Zap indicator at both
/// group and task levels, drag-target on each task row for the
/// 'split task into new group' affordance (parity row D-6).
///
/// **Drag-data convention** (agreed with `EdenProcessToolbox` TRD 006-12 and
/// `EdenVisualProcessCanvas` TRD 006-14):
/// - `'task'` — a fresh task being dragged from the toolbox.
/// - `'task-existing:{taskId}'` — an existing task being dragged from
///   another group (split source).
/// - `'phase'`, `'taskGroup'`, `'decision'` — non-task drag data that the
///   task rows MUST reject.
///
/// **Reorder semantics:** tapping ChevronUp/ChevronDown fires TWO
/// `onUpdateTask` calls back-to-back (one for the moved task, one for the
/// swapped task). Consumers MUST handle this batched-mutation contract
/// (wrap in a transaction, debounce, or accept the intermediate state).
class EdenProcessTaskGroupNode extends StatefulWidget {
  const EdenProcessTaskGroupNode({
    super.key,
    required this.context,
    required this.config,
  });

  final EdenDiagramNodeContext context;
  final EdenProcessNodeRendererConfig config;

  @override
  State<EdenProcessTaskGroupNode> createState() =>
      _EdenProcessTaskGroupNodeState();
}

class _EdenProcessTaskGroupNodeState extends State<EdenProcessTaskGroupNode> {
  bool _hovered = false;
  bool _editingName = false;
  int? _editingTaskId;
  late TextEditingController _nameCtrl;
  late TextEditingController _taskNameCtrl;
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _taskNameFocus = FocusNode();
  bool? _expanded;

  int get _groupId => widget.context.node.data['groupId'] as int;
  EdenProcessTaskGroup? get _group => widget.config.groupsById[_groupId];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: _group?.displayName ?? '');
    _taskNameCtrl = TextEditingController();
    _nameFocus.addListener(_onNameFocusChange);
    _taskNameFocus.addListener(_onTaskNameFocusChange);
  }

  @override
  void dispose() {
    _nameFocus.removeListener(_onNameFocusChange);
    _taskNameFocus.removeListener(_onTaskNameFocusChange);
    _nameCtrl.dispose();
    _taskNameCtrl.dispose();
    _nameFocus.dispose();
    _taskNameFocus.dispose();
    super.dispose();
  }

  void _onNameFocusChange() {
    if (!_nameFocus.hasFocus && _editingName) _commitName(save: true);
  }

  void _onTaskNameFocusChange() {
    if (!_taskNameFocus.hasFocus && _editingTaskId != null) {
      _commitTaskName(save: true);
    }
  }

  void _enterNameEdit() {
    setState(() {
      _nameCtrl.text = _group?.displayName ?? '';
      _editingName = true;
    });
    Future.microtask(() {
      if (mounted) _nameFocus.requestFocus();
    });
  }

  void _commitName({required bool save}) {
    if (save) {
      final trimmed = _nameCtrl.text.trim();
      if (trimmed.isNotEmpty && trimmed != _group?.displayName) {
        widget.config.onUpdateTaskGroup
            ?.call(_groupId, {'displayName': trimmed});
      }
    }
    if (mounted) setState(() => _editingName = false);
  }

  void _enterTaskEdit(EdenProcessTaskTemplate task) {
    setState(() {
      _taskNameCtrl.text = task.displayName;
      _editingTaskId = task.id;
    });
    Future.microtask(() {
      if (mounted) _taskNameFocus.requestFocus();
    });
  }

  void _commitTaskName({required bool save}) {
    if (_editingTaskId == null) return;
    if (save) {
      final trimmed = _taskNameCtrl.text.trim();
      final task = _group?.tasks.firstWhere(
        (t) => t.id == _editingTaskId,
        orElse: () => _group!.tasks.first,
      );
      if (trimmed.isNotEmpty && trimmed != task?.displayName) {
        widget.config.onUpdateTask
            ?.call(_editingTaskId!, {'displayName': trimmed});
      }
    }
    if (mounted) setState(() => _editingTaskId = null);
  }

  bool get _isExpanded {
    if (_expanded != null) return _expanded!;
    return !(_group?.isCollapsedDefault ?? false);
  }

  void _toggleExpanded() {
    setState(() => _expanded = !_isExpanded);
  }

  bool _groupHasHooks(EdenProcessTaskGroup g) =>
      g.onAllCompleteWorkflowId != null ||
      g.onItemNaWorkflowId != null ||
      g.onItemCantDoWorkflowId != null;

  bool _taskHasHooks(EdenProcessTaskTemplate t) =>
      t.onCompleteWorkflowId != null ||
      t.onBlockedWorkflowId != null ||
      t.onNaWorkflowId != null ||
      t.onCantDoWorkflowId != null;

  @override
  Widget build(BuildContext context) {
    final group = _group;
    if (group == null) return _MissingGroupFallback(groupId: _groupId);

    final theme = Theme.of(context);
    final isDropTarget = widget.context.dropTarget;
    final isSelected = widget.context.selected;
    final sortedTasks = [...group.tasks]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        constraints: const BoxConstraints(minWidth: 240, maxWidth: 280),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: EdenRadii.borderRadiusLg,
          border: Border.all(
            color: isDropTarget
                ? theme.colorScheme.primary
                : (isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(group, theme, sortedTasks.length),
            if (_isExpanded) ...[
              _buildAddRow(theme),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < sortedTasks.length; i++)
                        _buildTaskRow(
                          sortedTasks[i],
                          i,
                          sortedTasks.length,
                          theme,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
      EdenProcessTaskGroup group, ThemeData theme, int taskCount) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _toggleExpanded,
            child: Icon(
              _isExpanded ? Icons.expand_more : Icons.chevron_right,
              size: 18,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            group.taskGroupTemplateId != null
                ? Icons.menu_book
                : Icons.folder,
            size: 14,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _editingName
                ? _buildNameField(theme)
                : GestureDetector(
                    onTap: _enterNameEdit,
                    child: Text(
                      group.displayName,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
          ),
          // Task count badge.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: EdenRadii.borderRadiusSm,
            ),
            child: Text(
              '$taskCount',
              style: theme.textTheme.labelSmall,
            ),
          ),
          if (_groupHasHooks(group))
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(
                Icons.bolt,
                size: 14,
                color: Colors.amber.shade700,
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
                  tooltip: 'Edit group',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => widget.config.onOpenTaskGroupEditor
                      ?.call(_groupId),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 14),
                  color: theme.colorScheme.error,
                  tooltip: 'Delete group',
                  visualDensity: VisualDensity.compact,
                  onPressed: () =>
                      widget.config.onDeleteTaskGroup?.call(_groupId),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField(ThemeData theme) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            _commitName(save: true);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            _commitName(save: false);
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
          contentPadding:
              EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        ),
      ),
    );
  }

  Widget _buildAddRow(ThemeData theme) {
    return InkWell(
      onTap: () => widget.config.onAddTaskInGroup
          ?.call(_groupId, {'runtimeComponent': 'checklist'}),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Icon(Icons.add, size: 14, color: theme.colorScheme.primary),
            const SizedBox(width: 4),
            Text(
              'Add task',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskRow(
    EdenProcessTaskTemplate task,
    int index,
    int totalTasks,
    ThemeData theme,
  ) {
    final isEditing = _editingTaskId == task.id;
    return _TaskRowDragTarget(
      key: ValueKey('drag-target-task-${task.id}'),
      onSplit: (sourceTaskId) {
        widget.config.onSplitTaskToNewGroup
            ?.call(sourceTaskId, _group!.processPhaseId);
      },
      builder: (context, isOver) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isOver
              ? theme.colorScheme.primary.withValues(alpha: 0.05)
              : null,
          border: isOver
              ? Border.all(color: theme.colorScheme.primary)
              : Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outlineVariant
                        .withValues(alpha: 0.5),
                  ),
                ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  '${index + 1}.',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: isEditing
                      ? _buildTaskNameField(theme)
                      : GestureDetector(
                          onTap: () => _enterTaskEdit(task),
                          child: Text(
                            task.displayName,
                            style: theme.textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                ),
                if (_taskHasHooks(task))
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.bolt,
                      size: 12,
                      color: Colors.amber.shade700,
                    ),
                  ),
                IconButton(
                  key: ValueKey('move-up-${task.id}'),
                  icon: const Icon(Icons.keyboard_arrow_up, size: 14),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Move up',
                  onPressed: index == 0 ? null : () => _moveTask(index, -1),
                ),
                IconButton(
                  key: ValueKey('move-down-${task.id}'),
                  icon: const Icon(Icons.keyboard_arrow_down, size: 14),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Move down',
                  onPressed: index == totalTasks - 1
                      ? null
                      : () => _moveTask(index, 1),
                ),
                IconButton(
                  key: ValueKey('edit-task-${task.id}'),
                  icon: const Icon(Icons.settings, size: 14),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Advanced edit',
                  onPressed: () =>
                      widget.config.onOpenTaskEditor?.call(task.id),
                ),
                IconButton(
                  key: ValueKey('delete-task-${task.id}'),
                  icon: const Icon(Icons.delete_outline, size: 14),
                  color: theme.colorScheme.error,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Delete task',
                  onPressed: () => widget.config.onDeleteTask?.call(task.id),
                ),
              ],
            ),
            if (!isEditing)
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 2),
                child: Wrap(
                  spacing: 8,
                  children: [
                    _InlineToggle(
                      key: ValueKey('toggle-${task.id}-isRequired'),
                      label: 'Req',
                      checked: task.isRequired,
                      onChanged: () => widget.config.onUpdateTask
                          ?.call(task.id, {'isRequired': !task.isRequired}),
                    ),
                    _InlineToggle(
                      key: ValueKey('toggle-${task.id}-photoRequired'),
                      label: 'Photo',
                      checked: task.photoRequired,
                      onChanged: () => widget.config.onUpdateTask?.call(
                          task.id, {'photoRequired': !task.photoRequired}),
                    ),
                    _InlineToggle(
                      key: ValueKey('toggle-${task.id}-signatureRequired'),
                      label: 'Sig',
                      checked: task.signatureRequired,
                      onChanged: () => widget.config.onUpdateTask?.call(
                          task.id,
                          {'signatureRequired': !task.signatureRequired}),
                    ),
                    _InlineToggle(
                      key: ValueKey('toggle-${task.id}-approvalRequired'),
                      label: 'Approve',
                      checked: task.approvalRequired,
                      onChanged: () => widget.config.onUpdateTask?.call(
                          task.id,
                          {'approvalRequired': !task.approvalRequired}),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskNameField(ThemeData theme) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            _commitTaskName(save: true);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            _commitTaskName(save: false);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: TextField(
        controller: _taskNameCtrl,
        focusNode: _taskNameFocus,
        style: theme.textTheme.bodySmall,
        decoration: const InputDecoration(
          isDense: true,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        ),
      ),
    );
  }

  void _moveTask(int idx, int delta) {
    final group = _group;
    if (group == null) return;
    final sorted = [...group.tasks]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final targetIdx = idx + delta;
    if (targetIdx < 0 || targetIdx >= sorted.length) return;
    final moving = sorted[idx];
    final swapped = sorted[targetIdx];
    widget.config.onUpdateTask
        ?.call(moving.id, {'sortOrder': swapped.sortOrder});
    widget.config.onUpdateTask
        ?.call(swapped.id, {'sortOrder': moving.sortOrder});
  }
}

class _InlineToggle extends StatelessWidget {
  const _InlineToggle({
    super.key,
    required this.label,
    required this.checked,
    required this.onChanged,
  });

  final String label;
  final bool checked;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onChanged,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: checked ? theme.colorScheme.primary : Colors.transparent,
              border: Border.all(
                color: checked
                    ? theme.colorScheme.primary
                    : Colors.grey.shade400,
              ),
            ),
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: checked
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Per-task-row drag target. Exposes a test-friendly API for simulating drop
/// events without instantiating a full `Draggable` source — Flutter's
/// `DragTarget` widget-test ergonomics for this pattern are awkward; the
/// state object's `simulateDrop` / `willAccept` methods give tests deterministic
/// access while still wiring `DragTarget` correctly at runtime.
class _TaskRowDragTarget extends StatefulWidget {
  const _TaskRowDragTarget({
    super.key,
    required this.onSplit,
    required this.builder,
  });

  final void Function(int sourceTaskId) onSplit;
  final Widget Function(BuildContext context, bool isOver) builder;

  @override
  State<_TaskRowDragTarget> createState() =>
      EdenProcessTaskGroupNodeDragTargetTestApi();
}

/// Public-via-name (private file) test API for simulating drag accepts.
/// Tests look up the state via `tester.state<...>(find.byKey(...))`.
class EdenProcessTaskGroupNodeDragTargetTestApi
    extends State<_TaskRowDragTarget> {
  bool _isOver = false;

  bool willAccept(String? data) {
    if (data == null) return false;
    return data == 'task' || data.startsWith('task-existing:');
  }

  void simulateDrop(String data) {
    if (!willAccept(data)) return;
    if (data.startsWith('task-existing:')) {
      final idStr = data.substring('task-existing:'.length);
      final taskId = int.tryParse(idStr);
      if (taskId != null) widget.onSplit(taskId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) {
        final accept = willAccept(details.data);
        if (accept) setState(() => _isOver = true);
        return accept;
      },
      onLeave: (_) => setState(() => _isOver = false),
      onAcceptWithDetails: (details) {
        setState(() => _isOver = false);
        simulateDrop(details.data);
      },
      builder: (context, candidate, rejected) =>
          widget.builder(context, _isOver),
    );
  }
}

class _MissingGroupFallback extends StatelessWidget {
  const _MissingGroupFallback({required this.groupId});

  final int groupId;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red),
          color: Colors.red.shade50,
        ),
        padding: const EdgeInsets.all(4),
        child: Text(
          'Missing group $groupId',
          style: const TextStyle(fontSize: 10, color: Colors.red),
        ),
      );
}
