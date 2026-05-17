// Do NOT regenerate via LLM — hand-built fixtures for EdenProcessNode widgets.
//
// Used by TRD 006-04 / 006-05 / 006-06 / 006-07 widget tests for the seven
// process node types. Builds `EdenDiagramNode` instances pre-shaped with the
// `data` map keys the renderer dispatches on (`nodeType`, `orphanType`,
// `displayName`, `config`) plus an `EdenDiagramNodeContext` helper.

import 'package:eden_ui_flutter/eden_ui.dart';

EdenDiagramNode startDiagramNodeFixture({String id = 'start'}) => EdenDiagramNode(
      id: id,
      shape: EdenNodeShape.circle,
      x: 0,
      y: 0,
      width: 48,
      height: 48,
      label: 'Start',
      data: const {'nodeType': 'start'},
    );

EdenDiagramNode endDiagramNodeFixture({String id = 'end'}) => EdenDiagramNode(
      id: id,
      shape: EdenNodeShape.circle,
      x: 0,
      y: 0,
      width: 48,
      height: 48,
      label: 'End',
      data: const {'nodeType': 'end'},
    );

EdenDiagramNode phaseOrphanFixture({
  String id = 'orphan-1',
  String displayName = 'New Phase',
}) =>
    EdenDiagramNode(
      id: id,
      shape: EdenNodeShape.roundedRect,
      x: 0,
      y: 0,
      width: 180,
      height: 56,
      label: displayName,
      data: {
        'nodeType': 'orphan',
        'orphanType': 'phase',
        'displayName': displayName,
        'config': const <String, dynamic>{},
      },
    );

EdenDiagramNode taskGroupOrphanFixture({
  String id = 'orphan-2',
  String displayName = 'New Task Group',
}) =>
    EdenDiagramNode(
      id: id,
      shape: EdenNodeShape.roundedRect,
      x: 0,
      y: 0,
      width: 180,
      height: 56,
      label: displayName,
      data: {
        'nodeType': 'orphan',
        'orphanType': 'taskGroup',
        'displayName': displayName,
        'config': const <String, dynamic>{},
      },
    );

EdenDiagramNode decisionOrphanFixture({
  String id = 'orphan-3',
  String displayName = 'New Decision',
}) =>
    EdenDiagramNode(
      id: id,
      shape: EdenNodeShape.roundedRect,
      x: 0,
      y: 0,
      width: 180,
      height: 56,
      label: displayName,
      data: {
        'nodeType': 'orphan',
        'orphanType': 'decision',
        'displayName': displayName,
        'config': const <String, dynamic>{},
      },
    );

EdenDiagramNode taskOrphanFixture({
  String id = 'orphan-4',
  String displayName = 'New Task',
  String? runtimeComponent,
}) =>
    EdenDiagramNode(
      id: id,
      shape: EdenNodeShape.roundedRect,
      x: 0,
      y: 0,
      width: 180,
      height: 56,
      label: displayName,
      data: {
        'nodeType': 'orphan',
        'orphanType': 'task',
        'displayName': displayName,
        'config': <String, dynamic>{
          if (runtimeComponent != null) 'runtimeComponent': runtimeComponent,
        },
      },
    );

EdenDiagramNodeContext nodeCtx(
  EdenDiagramNode node, {
  bool selected = false,
  bool hovered = false,
  bool dropTarget = false,
}) =>
    EdenDiagramNodeContext(
      node: node,
      selected: selected,
      hovered: hovered,
      dropTarget: dropTarget,
    );
