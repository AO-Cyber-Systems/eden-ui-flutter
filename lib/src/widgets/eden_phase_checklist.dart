import 'package:flutter/material.dart';

import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import 'eden_checklist_item.dart';

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

/// A single task within a checklist group.
class EdenChecklistTask {
  const EdenChecklistTask({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.isRequired = false,
    this.isBlocked = false,
    this.isNa = false,
    this.assignedTo,
    this.dueDate,
    this.description,
    this.blockedReason,
    this.naReason,
    this.trailing,
  });

  final String id;
  final String title;
  final bool isCompleted;
  final bool isRequired;
  final bool isBlocked;
  final bool isNa;
  final String? assignedTo;
  final DateTime? dueDate;
  final String? description;
  final String? blockedReason;
  final String? naReason;

  /// Optional trailing widget (e.g., PO badge, loading spinner).
  final Widget? trailing;
}

/// A group of tasks within a phase.
class EdenChecklistGroup {
  const EdenChecklistGroup({
    required this.name,
    required this.tasks,
  });

  final String name;
  final List<EdenChecklistTask> tasks;

  int get completedCount => tasks.where((t) => t.isCompleted).length;
  int get totalCount => tasks.length;
}

/// A phase containing groups of tasks.
class EdenChecklistPhase {
  const EdenChecklistPhase({
    required this.id,
    required this.name,
    required this.groups,
  });

  final String id;
  final String name;
  final List<EdenChecklistGroup> groups;

  int get totalTaskCount =>
      groups.fold<int>(0, (sum, g) => sum + g.totalCount);

  int get completedTaskCount =>
      groups.fold<int>(0, (sum, g) => sum + g.completedCount);

  double get completionFraction =>
      totalTaskCount > 0 ? completedTaskCount / totalTaskCount : 0;
}

// ---------------------------------------------------------------------------
// Main widget
// ---------------------------------------------------------------------------

/// Expandable phase-based checklist with per-phase progress indicators.
///
/// Each phase renders as a card with a circular progress indicator, task
/// counts, and expand/collapse. Inside, tasks are grouped with headers
/// and rendered using [EdenChecklistItem]. First incomplete phase is
/// auto-expanded by default.
///
/// ```dart
/// EdenPhaseChecklist(
///   phases: [
///     EdenChecklistPhase(
///       id: 'prep',
///       name: 'Preparation',
///       groups: [
///         EdenChecklistGroup(name: 'Materials', tasks: [
///           EdenChecklistTask(id: '1', title: 'Order supplies', isRequired: true),
///           EdenChecklistTask(id: '2', title: 'Confirm delivery', isCompleted: true),
///         ]),
///       ],
///     ),
///   ],
///   onTaskToggle: (taskId, newValue) => updateTask(taskId, newValue),
/// )
/// ```
class EdenPhaseChecklist extends StatefulWidget {
  const EdenPhaseChecklist({
    super.key,
    required this.phases,
    this.onTaskToggle,
    this.onTaskLongPress,
    this.updatingTaskIds = const {},
    this.autoExpandFirstIncomplete = true,
  });

  /// Phases to render.
  final List<EdenChecklistPhase> phases;

  /// Called when a task checkbox is toggled. Passes (taskId, newValue).
  final void Function(String taskId, bool newValue)? onTaskToggle;

  /// Called on long-press of a task. Passes taskId.
  final ValueChanged<String>? onTaskLongPress;

  /// Set of task IDs currently being updated (shows loading state).
  final Set<String> updatingTaskIds;

  /// Whether to auto-expand the first incomplete phase.
  final bool autoExpandFirstIncomplete;

  @override
  State<EdenPhaseChecklist> createState() => _EdenPhaseChecklistState();
}

class _EdenPhaseChecklistState extends State<EdenPhaseChecklist> {
  final _expanded = <String>{};
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized && widget.autoExpandFirstIncomplete) {
      _initialized = true;
      for (final phase in widget.phases) {
        if (phase.completionFraction < 1.0) {
          _expanded.add(phase.id);
          break;
        }
      }
      if (_expanded.isEmpty && widget.phases.isNotEmpty) {
        _expanded.add(widget.phases.first.id);
      }
    }
  }

  void _toggle(String id) {
    setState(() {
      if (_expanded.contains(id)) {
        _expanded.remove(id);
      } else {
        _expanded.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.phases
          .map((phase) => _PhaseCard(
                phase: phase,
                isExpanded: _expanded.contains(phase.id),
                updatingTaskIds: widget.updatingTaskIds,
                onToggleExpand: () => _toggle(phase.id),
                onTaskToggle: widget.onTaskToggle,
                onTaskLongPress: widget.onTaskLongPress,
              ))
          .toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Phase card
// ---------------------------------------------------------------------------

class _PhaseCard extends StatelessWidget {
  const _PhaseCard({
    required this.phase,
    required this.isExpanded,
    required this.updatingTaskIds,
    required this.onToggleExpand,
    this.onTaskToggle,
    this.onTaskLongPress,
  });

  final EdenChecklistPhase phase;
  final bool isExpanded;
  final Set<String> updatingTaskIds;
  final VoidCallback onToggleExpand;
  final void Function(String taskId, bool newValue)? onTaskToggle;
  final ValueChanged<String>? onTaskLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isComplete = phase.completionFraction >= 1.0;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: EdenRadii.borderRadiusLg,
        side: BorderSide(
          color: isComplete
              ? Colors.green.withValues(alpha: 0.4)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          // Phase header
          InkWell(
            onTap: onToggleExpand,
            borderRadius: isExpanded
                ? const BorderRadius.only(
                    topLeft: Radius.circular(EdenRadii.lg),
                    topRight: Radius.circular(EdenRadii.lg),
                  )
                : EdenRadii.borderRadiusLg,
            child: Padding(
              padding: const EdgeInsets.all(EdenSpacing.space3),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: phase.completionFraction,
                          strokeWidth: 3,
                          color: isComplete
                              ? Colors.green
                              : theme.colorScheme.primary,
                          backgroundColor: theme.colorScheme.outlineVariant,
                        ),
                        if (isComplete)
                          const Icon(Icons.check, size: 14, color: Colors.green),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          phase.name,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isComplete
                                ? theme.colorScheme.onSurfaceVariant
                                : null,
                          ),
                        ),
                        Text(
                          '${phase.completedTaskCount}/${phase.totalTaskCount} tasks',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),

          // Groups and tasks (when expanded)
          if (isExpanded)
            for (final group in phase.groups) ...[
              const Divider(height: 1),
              _GroupHeader(group: group),
              for (final task in group.tasks)
                _TaskRow(
                  task: task,
                  isUpdating: updatingTaskIds.contains(task.id),
                  onToggle: onTaskToggle != null
                      ? (v) => onTaskToggle!(task.id, v)
                      : null,
                  onLongPress: onTaskLongPress != null
                      ? () => onTaskLongPress!(task.id)
                      : null,
                ),
              const SizedBox(height: 4),
            ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Group header
// ---------------------------------------------------------------------------

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.group});

  final EdenChecklistGroup group;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Icon(
            Icons.folder_outlined,
            size: 14,
            color: theme.colorScheme.secondary,
          ),
          const SizedBox(width: 6),
          Text(
            group.name,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (group.totalCount > 0) ...[
            const Spacer(),
            Text(
              '${group.completedCount}/${group.totalCount}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Task row (delegates to EdenChecklistItem)
// ---------------------------------------------------------------------------

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.isUpdating,
    this.onToggle,
    this.onLongPress,
  });

  final EdenChecklistTask task;
  final bool isUpdating;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    Widget? trailing = task.trailing;
    if (isUpdating) {
      trailing = const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return EdenChecklistItem(
      title: task.title,
      isCompleted: task.isCompleted,
      isRequired: task.isRequired,
      isBlocked: task.isBlocked,
      isNa: task.isNa,
      assignedTo: task.assignedTo,
      dueDate: task.dueDate,
      description: task.description,
      blockedReason: task.blockedReason,
      naReason: task.naReason,
      enabled: !isUpdating && !task.isBlocked && !task.isNa,
      onToggle: onToggle ?? (_) {},
      onLongPress: onLongPress,
      trailing: trailing,
    );
  }
}
