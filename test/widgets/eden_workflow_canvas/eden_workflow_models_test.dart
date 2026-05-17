import 'dart:convert';

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_workflow_models_fixtures.dart';

void main() {
  group('EdenWorkflowTriggerType', () {
    test('exposes exactly 6 enum values', () {
      expect(EdenWorkflowTriggerType.values.length, 6);
    });

    test('contains all 6 trigger types', () {
      final names = EdenWorkflowTriggerType.values.map((e) => e.name).toSet();
      expect(names, {
        'scheduled',
        'completed',
        'status_change',
        'time_based',
        'manual',
        'entity_created',
      });
    });

    test('entity_created has expected name', () {
      expect(EdenWorkflowTriggerType.entity_created.name, 'entity_created');
    });
  });

  group('EdenWorkflowConditionOperator', () {
    test('exposes exactly 6 enum values', () {
      expect(EdenWorkflowConditionOperator.values.length, 6);
    });

    test('contains all 6 operators', () {
      final names = EdenWorkflowConditionOperator.values.map((e) => e.name).toSet();
      expect(names, {
        'equals',
        'not_equals',
        'greater_than',
        'less_than',
        'contains',
        'not_contains',
      });
    });
  });

  group('EdenWorkflowCondition', () {
    test('constructs with required fields', () {
      final c = statusEqualsCompletedFixture();
      expect(c.field, 'status');
      expect(c.operator, EdenWorkflowConditionOperator.equals);
      expect(c.value, 'completed');
    });

    test('value can be int', () {
      final c = amountGreaterThan5000Fixture();
      expect(c.value, 5000);
      expect(c.value, isA<int>());
    });

    test('value can be bool', () {
      const c = EdenWorkflowCondition(
        field: 'is_active',
        operator: EdenWorkflowConditionOperator.equals,
        value: true,
      );
      expect(c.value, isTrue);
      expect(c.value, isA<bool>());
    });

    test('value can be null', () {
      const c = EdenWorkflowCondition(
        field: 'description',
        operator: EdenWorkflowConditionOperator.equals,
        value: null,
      );
      expect(c.value, isNull);
    });

    test('round-trips through toJson/fromJson with String value', () {
      final c = statusEqualsCompletedFixture();
      final json = c.toJson();
      final encoded = jsonEncode(json);
      final back = EdenWorkflowCondition.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
      );
      expect(back, c);
    });

    test('round-trips through JSON with int value', () {
      final c = amountGreaterThan5000Fixture();
      final back = EdenWorkflowCondition.fromJson(
        jsonDecode(jsonEncode(c.toJson())) as Map<String, dynamic>,
      );
      expect(back, c);
    });

    test('round-trips through JSON with bool value', () {
      const c = EdenWorkflowCondition(
        field: 'is_active',
        operator: EdenWorkflowConditionOperator.equals,
        value: true,
      );
      final back = EdenWorkflowCondition.fromJson(
        jsonDecode(jsonEncode(c.toJson())) as Map<String, dynamic>,
      );
      expect(back, c);
    });
  });

  group('EdenWorkflowAction', () {
    test('constructs with required fields', () {
      const a = EdenWorkflowAction(
        actionType: 'send_email',
        config: {'to': 'a@b.com', 'subject': 'hi'},
      );
      expect(a.actionType, 'send_email');
      expect(a.config['to'], 'a@b.com');
      expect(a.config['subject'], 'hi');
    });

    test('config defaults to empty map when omitted', () {
      const a = EdenWorkflowAction(actionType: 'send_sms');
      expect(a.config, isEmpty);
    });

    test('toJson uses "type" key (donor wire shape) not "actionType"', () {
      final a = sendEmailActionFixture();
      final json = a.toJson();
      expect(json['type'], 'send_email');
      expect(json.containsKey('actionType'), isFalse);
    });

    test('round-trips through toJson/fromJson', () {
      final a = sendEmailActionFixture();
      final back = EdenWorkflowAction.fromJson(
        jsonDecode(jsonEncode(a.toJson())) as Map<String, dynamic>,
      );
      expect(back, a);
    });
  });

  group('EdenWorkflowCanvasLayout', () {
    test('constructs with empty nodes', () {
      const l = EdenWorkflowCanvasLayout(version: 1, nodes: {});
      expect(l.version, 1);
      expect(l.nodes, isEmpty);
      expect(l.edges, isEmpty);
      expect(l.viewport, isNull);
    });

    test('constructs with saved positions', () {
      const l = EdenWorkflowCanvasLayout(
        version: 1,
        nodes: {'trigger-0': EdenProcessNodePosition(x: 100, y: 50)},
      );
      expect(l.nodes['trigger-0'], const EdenProcessNodePosition(x: 100, y: 50));
    });

    test('EdenWorkflowCanvasLayout.empty() returns version 1 + empty nodes/edges', () {
      final l = EdenWorkflowCanvasLayout.empty();
      expect(l.version, 1);
      expect(l.nodes, isEmpty);
      expect(l.edges, isEmpty);
    });

    test('round-trips through JSON preserving nodes + edges + viewport', () {
      const l = EdenWorkflowCanvasLayout(
        version: 1,
        nodes: {
          'trigger-0': EdenProcessNodePosition(x: 100, y: 50),
          'action-0': EdenProcessNodePosition(x: 300, y: 50),
        },
        edges: [
          EdenProcessSavedEdge(
            id: 'edge-user-1',
            source: 'trigger-0',
            target: 'action-0',
            sourceHandle: 'right',
            targetHandle: 'left',
          ),
        ],
        viewport: EdenProcessViewport(x: 0, y: 0, zoom: 1.0),
      );
      final back = EdenWorkflowCanvasLayout.fromJson(
        jsonDecode(jsonEncode(l.toJson())) as Map<String, dynamic>,
      );
      expect(back, l);
    });
  });

  group('EdenWorkflowDefinition', () {
    test('constructs with required fields and sensible defaults', () {
      final d = definitionWithEmptyConditionsAndActionsFixture();
      expect(d.id, 1);
      expect(d.name, 'trigger_only');
      expect(d.version, 1);
      expect(d.isPublished, isFalse);
      expect(d.hasUnpublishedChanges, isFalse);
      expect(d.triggerType, EdenWorkflowTriggerType.entity_created);
      expect(d.category, 'appointment');
      expect(d.triggerConfig, isEmpty);
      expect(d.conditions, isEmpty);
      expect(d.actions, isEmpty);
      expect(d.canvasLayout, isNull);
    });

    test('description defaults null', () {
      final d = definitionWithEmptyConditionsAndActionsFixture();
      expect(d.description, isNull);
    });

    test('description settable', () {
      final d = fullExampleDefinitionFixture();
      expect(d.description, 'Automated high-priority appointment follow-up');
    });

    test('canvasLayout defaults null', () {
      final d = definitionWithSingleActionFixture();
      expect(d.canvasLayout, isNull);
    });

    test('round-trips through toJson/fromJson with conditions[] + actions[]', () {
      final d = definitionWith2Conditions3ActionsFixture();
      final back = EdenWorkflowDefinition.fromJson(
        jsonDecode(jsonEncode(d.toJson())) as Map<String, dynamic>,
      );
      expect(back, d);
      // Order preserved
      expect(back.conditions.length, 2);
      expect(back.actions.length, 3);
      expect(back.conditions[0], d.conditions[0]);
      expect(back.conditions[1], d.conditions[1]);
      expect(back.actions[0], d.actions[0]);
      expect(back.actions[1], d.actions[1]);
      expect(back.actions[2], d.actions[2]);
    });

    test('round-trips through JSON with description + canvasLayout', () {
      final d = fullExampleDefinitionFixture();
      final back = EdenWorkflowDefinition.fromJson(
        jsonDecode(jsonEncode(d.toJson())) as Map<String, dynamic>,
      );
      expect(back, d);
    });
  });

  group('EdenWorkflowSaveData', () {
    test('constructs with required fields', () {
      final s = EdenWorkflowSaveData(
        triggerType: EdenWorkflowTriggerType.entity_created,
        triggerConfig: const {},
        category: 'appointment',
        conditions: const [],
        actions: const [],
        canvasLayout: EdenWorkflowCanvasLayout.empty(),
      );
      expect(s.triggerType, EdenWorkflowTriggerType.entity_created);
      expect(s.category, 'appointment');
    });

    test('toJson emits donor wire shape keys', () {
      final s = EdenWorkflowSaveData(
        triggerType: EdenWorkflowTriggerType.scheduled,
        triggerConfig: const {'cron': '0 9 * * 1'},
        category: 'task',
        conditions: [priorityEqualsHighFixture()],
        actions: [sendEmailActionFixture()],
        canvasLayout: EdenWorkflowCanvasLayout.empty(),
      );
      final json = s.toJson();
      expect(json.keys, containsAll([
        'triggerType',
        'triggerConfig',
        'category',
        'conditions',
        'actions',
        'canvasLayout',
      ]));
      expect(json['triggerType'], 'scheduled');
      expect(json['category'], 'task');
      expect(json['conditions'], isA<List<dynamic>>());
      expect(json['actions'], isA<List<dynamic>>());
    });
  });

  group('EdenWorkflowEdgeStyle', () {
    test('user color is indigo #6366F1 with 2pt stroke', () {
      expect(EdenWorkflowEdgeStyle.userColor, const Color(0xFF6366F1));
      expect(EdenWorkflowEdgeStyle.userStrokeWidth, 2);
    });

    test('auto stroke width is 2', () {
      expect(EdenWorkflowEdgeStyle.autoStrokeWidth, 2);
    });
  });

  group('Public exports — smoke import', () {
    test('all workflow types resolvable from package root', () {
      // Compile-time check: these references must resolve via the package
      // root import. If any are missing from eden_workflow_canvas_exports.dart
      // (or lib/eden_ui.dart), this test fails to compile.
      const refs = <Type>[
        EdenWorkflowDefinition,
        EdenWorkflowCondition,
        EdenWorkflowAction,
        EdenWorkflowCanvasLayout,
        EdenWorkflowSaveData,
        EdenWorkflowTriggerType,
        EdenWorkflowConditionOperator,
        EdenWorkflowCategory,
        EdenWorkflowCategoryRegistry,
        EdenWorkflowActionType,
        EdenWorkflowActionRegistry,
        EdenWorkflowGraphBuilder,
        EdenWorkflowEdgeStyle,
      ];
      expect(refs.length, 13);
    });
  });
}
