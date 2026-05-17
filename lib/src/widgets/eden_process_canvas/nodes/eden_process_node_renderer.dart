import 'package:flutter/material.dart';

import '../../eden_diagram/eden_diagram_exports.dart';
import '../process_models.dart';
import 'eden_process_decision_node.dart';
import 'eden_process_end_node.dart';
import 'eden_process_orphan_node.dart';
import 'eden_process_phase_node.dart';
import 'eden_process_start_node.dart';
import 'eden_process_task_group_node.dart';
import 'eden_process_task_node.dart';

/// Per-node callbacks aggregated for [EdenProcessNodeRenderer.dispatch].
///
/// TRDs 006-05/006-06/006-07 extend this additively with phase / taskGroup /
/// task callbacks. TRD 006-14 (`EdenVisualProcessCanvas`) composes the full
/// config from its props.
class EdenProcessNodeRendererConfig {
  const EdenProcessNodeRendererConfig({
    // Orphan node (TRD 006-04)
    this.onDeleteOrphan,
    // Phase node (TRD 006-05)
    this.onTogglePhaseExpanded,
    this.onUpdatePhase,
    this.onDeletePhase,
    this.onOpenPhaseEditor,
    this.phasesById = const {},
    this.expandedPhaseIds = const {},
    // Task-group node (TRD 006-06)
    this.groupsById = const {},
    this.onUpdateTaskGroup,
    this.onDeleteTaskGroup,
    this.onOpenTaskGroupEditor,
    this.onOpenTaskEditor,
    this.onAddTaskInGroup,
    this.onUpdateTask,
    this.onDeleteTask,
    this.onSplitTaskToNewGroup,
    // Task + Decision nodes (TRD 006-07)
    this.tasksById = const {},
    this.decisionsById = const {},
    this.onOpenTaskFormFieldsEditor,
    this.onUpdateDecision,
    this.onDeleteDecision,
  });

  /// Fires with the orphan node's id when its delete affordance is invoked.
  final void Function(String nodeId)? onDeleteOrphan;

  /// Fires when a phase node's chevron is tapped.
  final void Function(int phaseId)? onTogglePhaseExpanded;

  /// Fires when the inline-rename popover saves a new displayName (or any
  /// other phase field). The `updates` map carries the changed field(s).
  final void Function(int phaseId, Map<String, dynamic> updates)?
      onUpdatePhase;

  /// Fires when the hover-show trash button on a phase node is tapped.
  final void Function(int phaseId)? onDeletePhase;

  /// Fires when the hover-show pencil-edit button on a phase node is tapped.
  /// Consumer opens the TRD 006-10 PhaseEditorDialog in response.
  final void Function(int phaseId)? onOpenPhaseEditor;

  /// Lookup of full phase objects by id. Populated once per render by
  /// `EdenVisualProcessCanvas` (TRD 006-14). Used by `EdenProcessPhaseNode`
  /// to resolve display data.
  final Map<int, EdenProcessPhase> phasesById;

  /// Set of phase ids currently expanded. Drives the chevron + body state
  /// of `EdenProcessPhaseNode`.
  final Set<int> expandedPhaseIds;

  /// Lookup of full task-group objects by id (TRD 006-06).
  final Map<int, EdenProcessTaskGroup> groupsById;

  /// Fires when a task-group node's inline rename or other group field
  /// update is committed.
  final void Function(int groupId, Map<String, dynamic> updates)?
      onUpdateTaskGroup;

  /// Fires when the hover-show trash button on a task-group node is tapped.
  final void Function(int groupId)? onDeleteTaskGroup;

  /// Fires when the hover-show pencil-edit button on a task-group node is
  /// tapped. Consumer opens TaskGroupEditorDialog (TRD 006-10).
  final void Function(int groupId)? onOpenTaskGroupEditor;

  /// Fires when the per-task Settings icon is tapped. Consumer opens the
  /// TaskEditorDialog (TRD 006-10).
  final void Function(int taskId)? onOpenTaskEditor;

  /// Fires when the Add-task affordance inside an expanded task group is
  /// tapped. Optional `config` carries runtime defaults (e.g.
  /// `{'runtimeComponent': 'checklist'}`).
  final void Function(int groupId, Map<String, dynamic>? config)?
      onAddTaskInGroup;

  /// Fires when a task field changes (inline rename, toggle, reorder).
  /// **Reorder semantics:** chevron-up/down dispatches TWO sequential
  /// calls — one for the moved task, one for the swapped task. Consumers
  /// MUST handle the batched-mutation contract.
  final void Function(int taskId, Map<String, dynamic> updates)? onUpdateTask;

  /// Fires when the per-task trash button is tapped.
  final void Function(int taskId)? onDeleteTask;

  /// Fires when a task is dragged from another group onto a task row inside
  /// this group's expanded list. Args: dragged task id, current group's
  /// `processPhaseId`. Consumer creates a new group inside that phase and
  /// moves the task.
  final void Function(int taskId, int newPhaseId)? onSplitTaskToNewGroup;

  /// Lookup of task templates by id — used by standalone `EdenProcessTaskNode`
  /// (TRD 006-07). In objective 006 v1 the graph builder does not emit
  /// standalone task nodes; this is for future workflows + dispatch
  /// completeness.
  final Map<int, EdenProcessTaskTemplate> tasksById;

  /// Lookup of decision configs by id — used by `EdenProcessDecisionNode`
  /// (TRD 006-07).
  final Map<int, EdenProcessDecisionConfig> decisionsById;

  /// Fires when the Configure Fields button on a form-type task is tapped.
  /// Consumer opens the TaskFormFieldsEditorDialog (TRD 006-10).
  final void Function(int taskId)? onOpenTaskFormFieldsEditor;

  /// Fires when the Save action of the decision-node inline edit dialog
  /// is confirmed with a non-empty name.
  final void Function(int decisionId, Map<String, dynamic> updates)?
      onUpdateDecision;

  /// Fires when the hover-show trash button on a decision node is tapped.
  final void Function(int decisionId)? onDeleteDecision;
}

/// Central dispatcher used by `EdenDiagram.customNodeRenderer` to route a
/// node-context to the correct process-canvas node widget.
///
/// Switches on `ctx.node.data['nodeType']`. Unknown / missing types render a
/// loud red-bordered fallback so missing cases surface during development.
class EdenProcessNodeRenderer {
  EdenProcessNodeRenderer._();

  static Widget dispatch(
    EdenDiagramNodeContext ctx, {
    EdenProcessNodeRendererConfig? config,
  }) {
    final effectiveConfig = config ?? const EdenProcessNodeRendererConfig();
    final nodeType = ctx.node.data['nodeType'] as String?;
    switch (nodeType) {
      case 'start':
        return EdenProcessStartNode(context: ctx);
      case 'end':
        return EdenProcessEndNode(context: ctx);
      case 'orphan':
        return EdenProcessOrphanNode(
          context: ctx,
          onDelete: effectiveConfig.onDeleteOrphan,
        );
      case 'phase':
        return EdenProcessPhaseNode(context: ctx, config: effectiveConfig);
      case 'taskGroup':
        return EdenProcessTaskGroupNode(
            context: ctx, config: effectiveConfig);
      case 'task':
        return EdenProcessTaskNode(context: ctx, config: effectiveConfig);
      case 'decision':
        return EdenProcessDecisionNode(
            context: ctx, config: effectiveConfig);
      default:
        return _UnknownNodeFallback(label: ctx.node.label);
    }
  }
}

class _UnknownNodeFallback extends StatelessWidget {
  const _UnknownNodeFallback({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red),
          color: Colors.red.shade50,
        ),
        padding: const EdgeInsets.all(4),
        child: Text(
          label.isEmpty ? 'unknown' : label,
          style: const TextStyle(fontSize: 10),
        ),
      );
}
