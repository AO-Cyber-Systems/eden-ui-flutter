// EdenWorkflowValidator — pure-function workflow graph validator.
//
// Donor parity: `workflowValidation.ts` (164 LOC). Implements 8 distinct
// validation rules. Each rule produces error/warning issues with a
// suggestion message.
//
// Reuses obj 006's `EdenProcessValidationSeverity` enum (locked decision —
// no parallel severity enum).
//
// Parity rows V-1 / V-2.

import '../eden_diagram/diagram_data.dart';
import '../eden_process_canvas/process_models.dart'
    show EdenProcessValidationSeverity;

/// A single validation finding for a workflow graph.
class EdenWorkflowValidationIssue {
  const EdenWorkflowValidationIssue({
    required this.severity,
    this.nodeId,
    required this.message,
    this.suggestion,
  });

  final EdenProcessValidationSeverity severity;
  final String? nodeId;
  final String message;
  final String? suggestion;

  @override
  bool operator ==(Object other) =>
      other is EdenWorkflowValidationIssue &&
      other.severity == severity &&
      other.nodeId == nodeId &&
      other.message == message &&
      other.suggestion == suggestion;

  @override
  int get hashCode => Object.hash(severity, nodeId, message, suggestion);
}

/// Result of validating a workflow canvas. `isValid` is derived: no errors.
class EdenWorkflowValidationResult {
  const EdenWorkflowValidationResult({required this.issues});

  final List<EdenWorkflowValidationIssue> issues;

  bool get isValid =>
      issues.every((i) => i.severity != EdenProcessValidationSeverity.error);

  /// (errors, warnings) counts.
  ({int errors, int warnings}) get summary => (
        errors: issues
            .where((i) => i.severity == EdenProcessValidationSeverity.error)
            .length,
        warnings: issues
            .where((i) => i.severity == EdenProcessValidationSeverity.warning)
            .length,
      );
}

/// Workflow graph validator. Pure-function `validate` implements 8 donor
/// rules and returns an [EdenWorkflowValidationResult] holding all findings.
abstract class EdenWorkflowValidator {
  EdenWorkflowValidator._();

  /// Validate the canvas graph and return all findings.
  ///
  /// Rules (donor `workflowValidation.ts:17-122` parity):
  /// 1. Must have exactly one trigger node (ERROR)
  /// 2. Must have at least one action node (ERROR)
  /// 3. Should have an end node (WARNING)
  /// 4. All non-trigger nodes must have at least one incoming edge (ERROR)
  /// 5. All non-end nodes should have at least one outgoing edge (WARNING)
  /// 6. Branch nodes should have at least 2 outgoing edges (WARNING)
  /// 7. Merge nodes should have at least 2 incoming edges (WARNING)
  /// 8. Condition nodes should be configured (WARNING)
  static EdenWorkflowValidationResult validate(
    List<EdenDiagramNode> nodes,
    List<EdenDiagramEdge> edges,
  ) {
    final issues = <EdenWorkflowValidationIssue>[];

    String labelFor(EdenDiagramNode node) {
      final nt = node.data['nodeType'] as String?;
      switch (nt) {
        case 'trigger':
          return 'Trigger';
        case 'action':
          final at = node.data['actionType'] as String?;
          return at != null ? 'Action ($at)' : 'Action';
        case 'condition':
          final field = node.data['field'] as String?;
          return field != null && field.isNotEmpty
              ? 'Condition ($field)'
              : 'Condition';
        case 'branch':
          return 'Branch';
        case 'merge':
          return 'Merge';
        case 'delay':
          return 'Delay';
        case 'end':
          return 'End';
        default:
          return node.label.isNotEmpty ? node.label : node.id;
      }
    }

    // Rule 1
    final triggerNodes =
        nodes.where((n) => n.data['nodeType'] == 'trigger').toList();
    if (triggerNodes.isEmpty) {
      issues.add(const EdenWorkflowValidationIssue(
        severity: EdenProcessValidationSeverity.error,
        message: 'Workflow must have a trigger node',
        suggestion: 'Drag a trigger from the toolbox onto the canvas',
      ));
    } else if (triggerNodes.length > 1) {
      issues.add(const EdenWorkflowValidationIssue(
        severity: EdenProcessValidationSeverity.error,
        message: 'Workflow can only have one trigger node',
        suggestion: 'Remove extra trigger nodes',
      ));
    }

    // Rule 2
    final actionNodes =
        nodes.where((n) => n.data['nodeType'] == 'action').toList();
    if (actionNodes.isEmpty) {
      issues.add(const EdenWorkflowValidationIssue(
        severity: EdenProcessValidationSeverity.error,
        message: 'Workflow must have at least one action',
        suggestion:
            'Add an action node (Create Task, Send Notification, etc.)',
      ));
    }

    // Rule 3
    final endNodes = nodes.where((n) => n.data['nodeType'] == 'end').toList();
    if (endNodes.isEmpty) {
      issues.add(const EdenWorkflowValidationIssue(
        severity: EdenProcessValidationSeverity.warning,
        message: 'Workflow has no end node',
        suggestion: 'Add an End node to clearly mark workflow completion',
      ));
    }

    // Rule 4
    final targetNodeIds = edges.map((e) => e.targetId).toSet();
    for (final node in nodes) {
      final nt = node.data['nodeType'] as String?;
      if (nt != 'trigger' && !targetNodeIds.contains(node.id)) {
        issues.add(EdenWorkflowValidationIssue(
          severity: EdenProcessValidationSeverity.error,
          nodeId: node.id,
          message: '${labelFor(node)} is not connected to any input',
          suggestion: 'Connect this node to the workflow flow',
        ));
      }
    }

    // Rule 5
    final sourceNodeIds = edges.map((e) => e.sourceId).toSet();
    for (final node in nodes) {
      final nt = node.data['nodeType'] as String?;
      if (nt != 'end' && !sourceNodeIds.contains(node.id)) {
        issues.add(EdenWorkflowValidationIssue(
          severity: EdenProcessValidationSeverity.warning,
          nodeId: node.id,
          message: '${labelFor(node)} has no outgoing connection',
          suggestion:
              'Connect this node to the next step or an End node',
        ));
      }
    }

    // Rule 6
    for (final node
        in nodes.where((n) => n.data['nodeType'] == 'branch')) {
      final outgoing = edges.where((e) => e.sourceId == node.id).length;
      if (outgoing < 2) {
        issues.add(EdenWorkflowValidationIssue(
          severity: EdenProcessValidationSeverity.warning,
          nodeId: node.id,
          message: 'Branch node should split into at least 2 paths',
          suggestion: 'Add more outgoing connections from this branch',
        ));
      }
    }

    // Rule 7
    for (final node in nodes.where((n) => n.data['nodeType'] == 'merge')) {
      final incoming = edges.where((e) => e.targetId == node.id).length;
      if (incoming < 2) {
        issues.add(EdenWorkflowValidationIssue(
          severity: EdenProcessValidationSeverity.warning,
          nodeId: node.id,
          message: 'Merge node should receive at least 2 paths',
          suggestion: 'Connect more paths to this merge node',
        ));
      }
    }

    // Rule 8
    for (final node
        in nodes.where((n) => n.data['nodeType'] == 'condition')) {
      final field = node.data['field'] as String?;
      final operator = node.data['operator'] as String?;
      if (field == null ||
          field.isEmpty ||
          operator == null ||
          operator.isEmpty) {
        issues.add(EdenWorkflowValidationIssue(
          severity: EdenProcessValidationSeverity.warning,
          nodeId: node.id,
          message: 'Condition node is not configured',
          suggestion:
              'Click the condition node to set field, operator, and value',
        ));
      }
    }

    return EdenWorkflowValidationResult(issues: issues);
  }
}
