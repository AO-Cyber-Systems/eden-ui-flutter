import '../eden_diagram/eden_diagram_exports.dart';
import 'process_models.dart';

/// Result of running [EdenProcessValidator.validate].
///
/// `isValid` is true only when zero errors are present (warnings allowed).
/// `summary` exposes the (errors, warnings) split as a Dart record.
class EdenProcessValidationResult {
  const EdenProcessValidationResult({
    required this.isValid,
    required this.issues,
    required this.orphanCount,
  });

  final bool isValid;
  final List<EdenProcessValidationIssue> issues;
  final int orphanCount;

  ({int errors, int warnings}) get summary {
    var errors = 0;
    for (final i in issues) {
      if (i.type == EdenProcessValidationSeverity.error) errors++;
    }
    return (errors: errors, warnings: issues.length - errors);
  }
}

/// Pure-function process validator — parity row V-1.
///
/// Inspects an `EdenProcessDefinition` together with the canvas-rendered
/// nodes + edges and emits a list of issues (errors + warnings) plus
/// derived counters. Donor port of `processValidation.ts:13-132`.
///
/// Validation rules:
/// 1. Each orphan node emits a warning ("X is not connected to the process").
/// 2. Definition with empty `phases` emits a "Process has no phases" error.
/// 3. Each phase with no groups OR no tasks emits a warning.
/// 4. Each empty group emits a warning.
/// 5. Each decision node missing yes OR no path emits an error. yes/no
///    branches resolve via `edge.sourcePortId` (new) with fallback to
///    `edge.sourcePort` enum (legacy — right→yes, bottom→no).
/// 6. Each non-start/end/orphan node not referenced by any edge emits a
///    "disconnected" warning. Start + end are special-cased as connected.
///
/// **Pure function:** no state, no side effects, no caching. Call freely
/// from the canvas's build method.
class EdenProcessValidator {
  EdenProcessValidator._();

  static EdenProcessValidationResult validate(
    EdenProcessDefinition definition,
    List<EdenDiagramNode> nodes,
    List<EdenDiagramEdge> edges,
  ) {
    final issues = <EdenProcessValidationIssue>[];

    // 1. Orphan nodes.
    final orphans =
        nodes.where((n) => n.data['nodeType'] == 'orphan').toList();
    for (final orphan in orphans) {
      final displayName = orphan.data['displayName'] as String? ?? 'Unnamed';
      final orphanType = orphan.data['orphanType'] as String? ?? 'element';
      issues.add(EdenProcessValidationIssue(
        type: EdenProcessValidationSeverity.warning,
        nodeId: orphan.id,
        message: '"$displayName" is not connected to the process',
        suggestion: 'Connect this $orphanType to a parent node',
      ));
    }

    // 2. No-phases error.
    if (definition.phases.isEmpty) {
      issues.add(const EdenProcessValidationIssue(
        type: EdenProcessValidationSeverity.error,
        nodeId: 'start',
        message: 'Process has no phases',
        suggestion: 'Add at least one phase to define your process workflow',
      ));
    }

    // 3. Empty-phase + empty-group warnings.
    for (final phase in definition.phases) {
      final hasGroups = phase.groups.isNotEmpty;
      final hasAnyTasks = phase.groups.any((g) => g.tasks.isNotEmpty);
      if (!hasGroups) {
        issues.add(EdenProcessValidationIssue(
          type: EdenProcessValidationSeverity.warning,
          nodeId: 'phase-${phase.id}',
          message: 'Phase "${phase.displayName}" has no task groups',
          suggestion: 'Add task groups or tasks to this phase',
        ));
      } else if (!hasAnyTasks) {
        issues.add(EdenProcessValidationIssue(
          type: EdenProcessValidationSeverity.warning,
          nodeId: 'phase-${phase.id}',
          message: 'Phase "${phase.displayName}" has no tasks',
          suggestion: 'Add tasks to the task groups in this phase',
        ));
      }

      for (final group in phase.groups) {
        if (group.tasks.isEmpty) {
          issues.add(EdenProcessValidationIssue(
            type: EdenProcessValidationSeverity.warning,
            nodeId: 'group-${group.id}',
            message: 'Task group "${group.displayName}" is empty',
            suggestion: 'Add tasks to this group or remove it',
          ));
        }
      }
    }

    // 4. Decision missing branches.
    final decisions = nodes.where((n) => n.data['nodeType'] == 'decision');
    for (final decision in decisions) {
      final outgoing = edges.where((e) => e.sourceId == decision.id);
      final hasYes = outgoing.any((e) =>
          e.sourcePortId == 'yes' ||
          e.sourcePortId == 'right' ||
          (e.sourcePortId == null && e.sourcePort == EdenPortSide.right));
      final hasNo = outgoing.any((e) =>
          e.sourcePortId == 'no' ||
          e.sourcePortId == 'bottom' ||
          (e.sourcePortId == null && e.sourcePort == EdenPortSide.bottom));
      if (!hasYes || !hasNo) {
        final name = decision.label.isEmpty ? 'Unnamed' : decision.label;
        issues.add(EdenProcessValidationIssue(
          type: EdenProcessValidationSeverity.error,
          nodeId: decision.id,
          message: 'Decision "$name" is missing branches',
          suggestion: 'Connect both Yes and No paths from this decision',
        ));
      }
    }

    // 5. Disconnected nodes.
    final connectedIds = <String>{'start', 'end'};
    for (final e in edges) {
      connectedIds.add(e.sourceId);
      connectedIds.add(e.targetId);
    }
    for (final node in nodes) {
      final type = node.data['nodeType'] as String?;
      if (type == 'orphan' || type == 'start' || type == 'end') continue;
      if (!connectedIds.contains(node.id)) {
        final displayName = node.label.isEmpty ? 'Unnamed' : node.label;
        issues.add(EdenProcessValidationIssue(
          type: EdenProcessValidationSeverity.warning,
          nodeId: node.id,
          message: '"$displayName" has no connections',
          suggestion: 'Connect this element to the process flow',
        ));
      }
    }

    final hasErrors =
        issues.any((i) => i.type == EdenProcessValidationSeverity.error);
    return EdenProcessValidationResult(
      isValid: !hasErrors,
      issues: List.unmodifiable(issues),
      orphanCount: orphans.length,
    );
  }
}
