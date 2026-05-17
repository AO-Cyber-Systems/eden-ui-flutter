// Do NOT regenerate via LLM — hand-built fixtures for EdenWorkflowValidator.

import 'package:eden_ui_flutter/eden_ui.dart';

EdenDiagramNode triggerNodeFixture({String id = 'trigger-0'}) => EdenDiagramNode(
      id: id,
      x: 0,
      y: 0,
      data: const {
        'nodeType': 'trigger',
        'triggerType': 'entity_created',
        'category': 'appointment',
        'config': <String, dynamic>{},
      },
    );

EdenDiagramNode actionNodeFixture({
  String id = 'action-0',
  String actionType = 'create_task',
}) =>
    EdenDiagramNode(
      id: id,
      x: 200,
      y: 0,
      data: {
        'nodeType': 'action',
        'actionType': actionType,
        'config': const <String, dynamic>{},
      },
    );

EdenDiagramNode endNodeFixture({String id = 'end-0'}) => EdenDiagramNode(
      id: id,
      x: 400,
      y: 0,
      data: const {'nodeType': 'end'},
    );

EdenDiagramNode unconfiguredConditionFixture({String id = 'condition-0'}) =>
    EdenDiagramNode(
      id: id,
      x: 200,
      y: 0,
      data: const {
        'nodeType': 'condition',
        'field': '',
        'operator': '',
        'value': null,
      },
    );

EdenDiagramNode configuredConditionFixture({String id = 'condition-0'}) =>
    EdenDiagramNode(
      id: id,
      x: 200,
      y: 0,
      data: const {
        'nodeType': 'condition',
        'field': 'priority',
        'operator': 'equals',
        'value': 'high',
      },
    );

EdenDiagramNode branchNodeFixture({String id = 'branch-0'}) => EdenDiagramNode(
      id: id,
      x: 200,
      y: 0,
      data: const {'nodeType': 'branch'},
    );

EdenDiagramNode mergeNodeFixture({String id = 'merge-0'}) => EdenDiagramNode(
      id: id,
      x: 200,
      y: 0,
      data: const {'nodeType': 'merge'},
    );

EdenDiagramEdge edgeFixture({
  required String id,
  required String source,
  required String target,
}) =>
    EdenDiagramEdge(id: id, sourceId: source, targetId: target);
