// Do NOT regenerate via LLM — hand-built fixtures for EdenWorkflowFlowNodes.

import 'package:eden_ui_flutter/eden_ui.dart';

/// Fixtures for branch + condition nodes (TRD 020-04).

EdenDiagramNodeContext branchNodeContextFixture({bool selected = false}) {
  return EdenDiagramNodeContext(
    node: EdenDiagramNode(
      id: 'branch-0',
      x: 0,
      y: 0,
      width: 160,
      height: 80,
      label: 'Branch',
      data: const {'nodeType': 'branch'},
    ),
    selected: selected,
  );
}

EdenDiagramNodeContext conditionNodeContextFixture({
  String field = 'status',
  EdenWorkflowConditionOperator operator = EdenWorkflowConditionOperator.equals,
  dynamic value = 'completed',
  bool selected = false,
}) {
  return EdenDiagramNodeContext(
    node: EdenDiagramNode(
      id: 'condition-0',
      x: 0,
      y: 0,
      width: 140,
      height: 140,
      label: 'Condition',
      data: {
        'nodeType': 'condition',
        'field': field,
        'operator': operator.name,
        'value': value,
      },
    ),
    selected: selected,
  );
}

EdenDiagramNodeContext unconfiguredConditionNodeContextFixture() {
  return EdenDiagramNodeContext(
    node: EdenDiagramNode(
      id: 'condition-0',
      x: 0,
      y: 0,
      width: 140,
      height: 140,
      label: 'Condition',
      data: const {
        'nodeType': 'condition',
        'field': '',
        'operator': 'equals',
        'value': null,
      },
    ),
  );
}
