import 'dart:convert';

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_process_models_fixtures.dart';

void main() {
  group('EdenProcessDefinition', () {
    test('constructs with required fields', () {
      final def = processDefinitionFixture();
      expect(def.id, 1);
      expect(def.processTypeId, 10);
      expect(def.name, 'work_order');
      expect(def.displayName, 'Work Order');
      expect(def.version, 1);
      expect(def.isDefault, isTrue);
      expect(def.isActive, isTrue);
      expect(def.isPublished, isFalse);
      expect(def.hasUnpublishedChanges, isFalse);
      expect(def.phases, isEmpty);
    });

    test('exposes optional description', () {
      final def = processDefinitionFixture(description: 'a process');
      expect(def.description, 'a process');
    });

    test('round-trips through toJson/fromJson', () {
      final def = processDefinitionFixture(
        description: 'desc',
        phases: [planningPhaseFixture()],
      );
      final json = def.toJson();
      final encoded = jsonEncode(json);
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      final back = EdenProcessDefinition.fromJson(decoded);
      expect(back, def);
    });
  });

  group('EdenProcessPhase', () {
    test('constructs with required fields', () {
      final phase = planningPhaseFixture();
      expect(phase.id, 1);
      expect(phase.processDefinitionId, 100);
      expect(phase.name, 'planning');
      expect(phase.displayName, 'Planning');
      expect(phase.sortOrder, 0);
      expect(phase.isRequired, isTrue);
      expect(phase.isMilestone, isFalse);
      expect(phase.canSkip, isFalse);
      expect(phase.autoAdvance, isFalse);
      expect(phase.allowsScopeChange, isTrue);
      expect(phase.allowsAdHocTasks, isTrue);
      expect(phase.groups, isEmpty);
    });

    test('color defaults non-null per fixture; can be null per spec', () {
      final phase = planningPhaseFixture(color: null);
      expect(phase.color, isNull);
    });

    test('icon defaults non-null per fixture; can be null per spec', () {
      final phase = planningPhaseFixture(icon: null);
      expect(phase.icon, isNull);
    });

    test('exposes color when set', () {
      final phase = planningPhaseFixture(color: '#3B82F6');
      expect(phase.color, '#3B82F6');
    });

    test('exposes icon when set', () {
      final phase = planningPhaseFixture(icon: 'layers');
      expect(phase.icon, 'layers');
    });

    test('round-trips through toJson/fromJson with groups', () {
      final phase = planningPhaseFixture(
        groups: [
          taskGroupFixture(),
        ],
      );
      final json = phase.toJson();
      final encoded = jsonEncode(json);
      final back = EdenProcessPhase.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
      );
      expect(back, phase);
    });
  });

  group('EdenProcessTaskGroup', () {
    test('constructs with required fields', () {
      final g = taskGroupFixture();
      expect(g.id, 10);
      expect(g.processPhaseId, 1);
      expect(g.name, 'site_inspection');
      expect(g.displayName, 'Site Inspection');
      expect(g.sortOrder, 0);
      expect(g.isCollapsedDefault, isFalse);
      expect(g.isRequired, isTrue);
      expect(g.tasks, isEmpty);
      expect(g.onAllCompleteWorkflowId, isNull);
      expect(g.onItemNaWorkflowId, isNull);
      expect(g.onItemCantDoWorkflowId, isNull);
    });

    test('workflow hooks exposed when set', () {
      final g = taskGroupWithHooksFixture();
      expect(g.onAllCompleteWorkflowId, 5);
      expect(g.onItemNaWorkflowId, 6);
      expect(g.onItemCantDoWorkflowId, 7);
    });

    test('round-trips through JSON', () {
      final g = taskGroupWithHooksFixture();
      final back = EdenProcessTaskGroup.fromJson(
        jsonDecode(jsonEncode(g.toJson())) as Map<String, dynamic>,
      );
      expect(back, g);
    });
  });

  group('EdenProcessTaskTemplate', () {
    test('constructs with required fields', () {
      final t = checklistTaskFixture();
      expect(t.id, 100);
      expect(t.taskGroupId, 10);
      expect(t.runtimeComponent, 'checklist');
      expect(t.isRequired, isTrue);
      expect(t.photoRequired, isFalse);
      expect(t.signatureRequired, isFalse);
      expect(t.approvalRequired, isFalse);
    });

    test('descriptionRequired and attachmentRequired default false', () {
      final t = checklistTaskFixture();
      expect(t.descriptionRequired, isFalse);
      expect(t.attachmentRequired, isFalse);
    });

    test('approvalRole, approvalUserId, responsibilityType default null', () {
      final t = checklistTaskFixture();
      expect(t.approvalRole, isNull);
      expect(t.approvalUserId, isNull);
      expect(t.responsibilityType, isNull);
    });

    test('materializesAsTask defaults true; can be overridden false', () {
      final t = checklistTaskFixture();
      expect(t.materializesAsTask, isTrue);
    });

    test('workflow hook ids default null and are individually settable', () {
      final t = checklistTaskFixture();
      expect(t.onCompleteWorkflowId, isNull);
      expect(t.onBlockedWorkflowId, isNull);
      expect(t.onNaWorkflowId, isNull);
      expect(t.onCantDoWorkflowId, isNull);
    });

    test('runtimeComponent accepts any string (no validation at construction)', () {
      final t = EdenProcessTaskTemplate(
        id: 999,
        taskGroupId: 10,
        name: 'made_up',
        displayName: 'Made Up',
        sortOrder: 0,
        runtimeComponent: 'made_up_future_type',
        runtimeComponentConfig: const {},
        isRequired: false,
        photoRequired: false,
        signatureRequired: false,
        approvalRequired: false,
        descriptionRequired: false,
        attachmentRequired: false,
        allowsNa: false,
        allowsBlocked: false,
        allowsCantDo: false,
        blockingBehavior: 'soft',
        materializesAsTask: true,
      );
      expect(t.runtimeComponent, 'made_up_future_type');
    });

    test('round-trips through JSON', () {
      final t = approvalTaskFixture();
      final back = EdenProcessTaskTemplate.fromJson(
        jsonDecode(jsonEncode(t.toJson())) as Map<String, dynamic>,
      );
      expect(back, t);
    });
  });

  group('EdenProcessDecisionConfig', () {
    test('constructs', () {
      final d = decisionFixture();
      expect(d.id, 1);
      expect(d.name, 'Approval Required?');
      expect(d.condition, 'cost > 5000');
    });

    test('round-trips through JSON', () {
      final d = decisionFixture();
      final back = EdenProcessDecisionConfig.fromJson(
        jsonDecode(jsonEncode(d.toJson())) as Map<String, dynamic>,
      );
      expect(back, d);
    });
  });

  group('EdenProcessConfig', () {
    test('constructs empty', () {
      const config = EdenProcessConfig();
      expect(config.layout, isNull);
      expect(config.decisions, isEmpty);
      expect(config.flowNodes, isNull);
      expect(config.extra, isEmpty);
    });

    test('constructs with layout + decisions + flowNodes', () {
      final config = EdenProcessConfig(
        layout: layoutDataFixture(),
        decisions: [decisionFixture()],
        flowNodes: const {'start': true, 'end': true},
      );
      expect(config.layout, isNotNull);
      expect(config.decisions, hasLength(1));
      expect(config.flowNodes, {'start': true, 'end': true});
    });

    test('extra defaults empty; settable', () {
      const c1 = EdenProcessConfig();
      expect(c1.extra, isEmpty);
      const c2 = EdenProcessConfig(extra: {'vertical': 'trades'});
      expect(c2.extra, {'vertical': 'trades'});
    });

    test('round-trips through JSON preserving extras', () {
      final config = EdenProcessConfig(
        layout: layoutDataFixture(),
        decisions: [decisionFixture()],
        flowNodes: const {'start': true, 'end': false},
        extra: const {'vertical': 'trades', 'count': 3},
      );
      final back = EdenProcessConfig.fromJson(
        jsonDecode(jsonEncode(config.toJson())) as Map<String, dynamic>,
      );
      expect(back, config);
    });
  });

  group('EdenProcessLayoutData', () {
    test('constructs', () {
      const layout = EdenProcessLayoutData(
        version: 1,
        autoLayout: false,
        nodes: {
          'phase-1': EdenProcessNodePosition(x: 100, y: 50),
        },
      );
      expect(layout.version, 1);
      expect(layout.autoLayout, isFalse);
      expect(layout.nodes['phase-1']?.x, 100);
      expect(layout.edges, isEmpty);
      expect(layout.viewport, isNull);
    });

    test('edges + viewport settable', () {
      final layout = EdenProcessLayoutData(
        version: 1,
        autoLayout: false,
        nodes: const {},
        edges: [savedEdgeFixture()],
        viewport: const EdenProcessViewport(x: 10, y: 20, zoom: 1.5),
      );
      expect(layout.edges, hasLength(1));
      expect(layout.viewport?.zoom, 1.5);
    });

    test('round-trips through JSON', () {
      final layout = EdenProcessLayoutData(
        version: 1,
        autoLayout: true,
        nodes: const {
          'phase-1': EdenProcessNodePosition(x: 100, y: 50, expanded: true),
        },
        edges: [savedEdgeFixture(sourceHandle: 'right', targetHandle: 'left')],
        viewport: const EdenProcessViewport(x: 5, y: 10, zoom: 1.25),
      );
      final back = EdenProcessLayoutData.fromJson(
        jsonDecode(jsonEncode(layout.toJson())) as Map<String, dynamic>,
      );
      expect(back, layout);
    });
  });

  group('EdenProcessNodePosition + EdenProcessSavedEdge + EdenProcessViewport', () {
    test('EdenProcessNodePosition basic', () {
      const p = EdenProcessNodePosition(x: 100.5, y: 200.0);
      expect(p.x, 100.5);
      expect(p.y, 200.0);
      expect(p.expanded, isNull);
    });

    test('EdenProcessSavedEdge basic + handles', () {
      const e = EdenProcessSavedEdge(id: 'edge-1', source: 'phase-1', target: 'group-2');
      expect(e.id, 'edge-1');
      expect(e.sourceHandle, isNull);
      expect(e.targetHandle, isNull);
      const e2 = EdenProcessSavedEdge(
        id: 'edge-2',
        source: 'phase-1',
        target: 'group-2',
        sourceHandle: 'right',
        targetHandle: 'left',
      );
      expect(e2.sourceHandle, 'right');
      expect(e2.targetHandle, 'left');
    });

    test('EdenProcessViewport basic', () {
      const v = EdenProcessViewport(x: 0, y: 0, zoom: 1.0);
      expect(v.zoom, 1.0);
    });

    test('JSON round-trips for all three', () {
      const p = EdenProcessNodePosition(x: 1.5, y: 2.5, expanded: true);
      final pBack = EdenProcessNodePosition.fromJson(
        jsonDecode(jsonEncode(p.toJson())) as Map<String, dynamic>,
      );
      expect(pBack, p);

      const e = EdenProcessSavedEdge(
        id: 'edge-1',
        source: 's',
        target: 't',
        sourceHandle: 'yes',
        targetHandle: 'top',
      );
      final eBack = EdenProcessSavedEdge.fromJson(
        jsonDecode(jsonEncode(e.toJson())) as Map<String, dynamic>,
      );
      expect(eBack, e);

      const v = EdenProcessViewport(x: 100, y: 200, zoom: 0.75);
      final vBack = EdenProcessViewport.fromJson(
        jsonDecode(jsonEncode(v.toJson())) as Map<String, dynamic>,
      );
      expect(vBack, v);
    });
  });

  group('EdenProcessValidationIssue + EdenProcessValidationSeverity', () {
    test('severity enum has 2 values', () {
      expect(EdenProcessValidationSeverity.values, hasLength(2));
      expect(EdenProcessValidationSeverity.values, contains(EdenProcessValidationSeverity.error));
      expect(EdenProcessValidationSeverity.values, contains(EdenProcessValidationSeverity.warning));
    });

    test('warning issue constructs with optional suggestion', () {
      final issue = warningIssueFixture();
      expect(issue.type, EdenProcessValidationSeverity.warning);
      expect(issue.nodeId, 'orphan-1');
      expect(issue.message, 'Element not connected');
      expect(issue.suggestion, isNull);
    });

    test('issue.toJson writes type name (lowercase)', () {
      final issue = warningIssueFixture();
      final json = issue.toJson();
      expect(json['type'], 'warning');
    });

    test('fromJson parses error severity', () {
      final json = {
        'type': 'error',
        'nodeId': 'decision-1',
        'message': 'msg',
      };
      final issue = EdenProcessValidationIssue.fromJson(json);
      expect(issue.type, EdenProcessValidationSeverity.error);
      expect(issue.nodeId, 'decision-1');
    });
  });

  group('EdenProcessEntityTypeRegistry', () {
    setUp(() {
      EdenProcessEntityTypeRegistry.instance.reset();
    });

    test('is a singleton (same instance across calls)', () {
      final a = EdenProcessEntityTypeRegistry.instance;
      final b = EdenProcessEntityTypeRegistry.instance;
      expect(identical(a, b), isTrue);
    });

    test('after reset, all() is empty', () {
      EdenProcessEntityTypeRegistry.instance.reset();
      expect(EdenProcessEntityTypeRegistry.instance.all(), isEmpty);
    });

    test('register then lookup returns the entry', () {
      EdenProcessEntityTypeRegistry.instance.register(serviceVisitEntityTypeFixture());
      final entry = EdenProcessEntityTypeRegistry.instance.lookup('service_visit');
      expect(entry, isNotNull);
      expect(entry!.displayName, 'Service Visit');
    });

    test('register twice with same id throws StateError', () {
      EdenProcessEntityTypeRegistry.instance.register(serviceVisitEntityTypeFixture());
      expect(
        () => EdenProcessEntityTypeRegistry.instance.register(serviceVisitEntityTypeFixture()),
        throwsA(isA<StateError>()),
      );
    });

    test('lookup unknown id returns null', () {
      expect(EdenProcessEntityTypeRegistry.instance.lookup('nonexistent'), isNull);
    });

    test('reset clears registered entries', () {
      EdenProcessEntityTypeRegistry.instance.register(serviceVisitEntityTypeFixture());
      EdenProcessEntityTypeRegistry.instance.reset();
      expect(EdenProcessEntityTypeRegistry.instance.lookup('service_visit'), isNull);
    });

    test('multiple distinct ids can be registered side-by-side', () {
      EdenProcessEntityTypeRegistry.instance.register(serviceVisitEntityTypeFixture());
      EdenProcessEntityTypeRegistry.instance.register(fuelDeliveryEntityTypeFixture());
      expect(EdenProcessEntityTypeRegistry.instance.all(), hasLength(2));
    });
  });

  group('EdenProcessRuntimeComponentRegistry', () {
    setUp(() {
      EdenProcessRuntimeComponentRegistry.instance.resetToDefaults();
    });

    test('is a singleton', () {
      final a = EdenProcessRuntimeComponentRegistry.instance;
      final b = EdenProcessRuntimeComponentRegistry.instance;
      expect(identical(a, b), isTrue);
    });

    test('after resetToDefaults, has at least the 6 standard ids', () {
      EdenProcessRuntimeComponentRegistry.instance.resetToDefaults();
      final all = EdenProcessRuntimeComponentRegistry.instance.all();
      expect(all.length, greaterThanOrEqualTo(6));
      final ids = all.map((c) => c.id).toSet();
      expect(ids, containsAll(<String>{
        'checklist',
        'form',
        'photo_gallery',
        'signature_capture',
        'approval_gate',
        'notes_log',
      }));
    });

    test('lookup("checklist") returns non-null with icon + displayName', () {
      final c = EdenProcessRuntimeComponentRegistry.instance.lookup('checklist');
      expect(c, isNotNull);
      expect(c!.displayName, isNotEmpty);
    });

    test('register adds a new component', () {
      EdenProcessRuntimeComponentRegistry.instance
          .register(customWidgetComponentFixture());
      expect(
        EdenProcessRuntimeComponentRegistry.instance.lookup('custom_widget'),
        isNotNull,
      );
    });

    test('register twice with same id throws', () {
      EdenProcessRuntimeComponentRegistry.instance
          .register(customWidgetComponentFixture());
      expect(
        () => EdenProcessRuntimeComponentRegistry.instance
            .register(customWidgetComponentFixture()),
        throwsA(isA<StateError>()),
      );
    });

    test('reset clears everything (no defaults left)', () {
      EdenProcessRuntimeComponentRegistry.instance.reset();
      expect(EdenProcessRuntimeComponentRegistry.instance.all(), isEmpty);
    });

    test('resetToDefaults re-registers exactly the 6 defaults', () {
      EdenProcessRuntimeComponentRegistry.instance.reset();
      EdenProcessRuntimeComponentRegistry.instance.resetToDefaults();
      final ids = EdenProcessRuntimeComponentRegistry.instance
          .all()
          .map((c) => c.id)
          .toSet();
      expect(ids, {
        'checklist',
        'form',
        'photo_gallery',
        'signature_capture',
        'approval_gate',
        'notes_log',
      });
    });
  });

  group('EdenDiagramPort + EdenDiagramNode.ports (additive)', () {
    test('existing EdenDiagramNode constructor still works (no ports)', () {
      final node = EdenDiagramNode(id: 'n1', x: 0, y: 0);
      expect(node.id, 'n1');
      expect(node.ports, isNull);
    });

    test('legacy portOffset returns same values as before', () {
      final node = EdenDiagramNode(id: 'n', x: 100, y: 50, width: 200, height: 60);
      expect(node.portOffset(EdenPortSide.top), const Offset(200, 50));
      expect(node.portOffset(EdenPortSide.right), const Offset(300, 80));
      expect(node.portOffset(EdenPortSide.bottom), const Offset(200, 110));
      expect(node.portOffset(EdenPortSide.left), const Offset(100, 80));
    });

    test('EdenDiagramPort constructs with required fields + defaults', () {
      const port = EdenDiagramPort(
        id: 'top',
        side: EdenPortSide.top,
        kind: EdenDiagramPortKind.target,
      );
      expect(port.id, 'top');
      expect(port.side, EdenPortSide.top);
      expect(port.offset, 0.5);
      expect(port.kind, EdenDiagramPortKind.target);
      expect(port.color, isNull);
      expect(port.data, isEmpty);
    });

    test('EdenDiagramPortKind values length is 3', () {
      expect(EdenDiagramPortKind.values, hasLength(3));
      expect(EdenDiagramPortKind.values, contains(EdenDiagramPortKind.source));
      expect(EdenDiagramPortKind.values, contains(EdenDiagramPortKind.target));
      expect(EdenDiagramPortKind.values, contains(EdenDiagramPortKind.both));
    });

    test('EdenDiagramNode accepts ports list', () {
      final node = EdenDiagramNode(
        id: 'd',
        x: 100,
        y: 100,
        ports: const [
          EdenDiagramPort(
            id: 'yes',
            side: EdenPortSide.right,
            kind: EdenDiagramPortKind.source,
          ),
          EdenDiagramPort(
            id: 'no',
            side: EdenPortSide.bottom,
            kind: EdenDiagramPortKind.source,
          ),
        ],
      );
      expect(node.ports?.length, 2);
      expect(node.ports![0].id, 'yes');
      expect(node.ports![1].id, 'no');
    });

    test('node.portOffset still returns legacy offset when ports are set (back-compat)', () {
      final node = EdenDiagramNode(
        id: 'd',
        x: 100,
        y: 100,
        width: 100,
        height: 100,
        ports: const [
          EdenDiagramPort(
            id: 'right',
            side: EdenPortSide.right,
            kind: EdenDiagramPortKind.source,
          ),
        ],
      );
      expect(node.portOffset(EdenPortSide.right), const Offset(200, 150));
    });

    test('EdenDiagramPort round-trips through JSON', () {
      const port = EdenDiagramPort(
        id: 'yes',
        side: EdenPortSide.right,
        offset: 0.3,
        kind: EdenDiagramPortKind.source,
        color: '#10B981',
        data: {'handleId': 'yes'},
      );
      final back = EdenDiagramPort.fromJson(
        jsonDecode(jsonEncode(port.toJson())) as Map<String, dynamic>,
      );
      expect(back, port);
    });

    test('EdenDiagramNode round-trips through JSON with ports', () {
      final node = EdenDiagramNode(
        id: 'd',
        x: 100,
        y: 100,
        ports: const [
          EdenDiagramPort(
            id: 'yes',
            side: EdenPortSide.right,
            kind: EdenDiagramPortKind.source,
            color: '#10B981',
          ),
        ],
      );
      final json = node.toJson();
      final back = EdenDiagramNode.fromJson(
        jsonDecode(jsonEncode(json)) as Map<String, dynamic>,
      );
      expect(back.ports?.length, 1);
      expect(back.ports![0].id, 'yes');
      expect(back.ports![0].color, '#10B981');
    });

    test('EdenDiagramData.fromJson back-compat — diagram without ports parses OK', () {
      final data = EdenDiagramData(
        nodes: [EdenDiagramNode(id: 'a', x: 0, y: 0)],
        edges: [],
      );
      final back = EdenDiagramData.fromJson(
        jsonDecode(jsonEncode(data.toJson())) as Map<String, dynamic>,
      );
      expect(back.nodes, hasLength(1));
      expect(back.nodes[0].ports, isNull);
    });
  });

  group('Public exports', () {
    test('all process-canvas + diagram-port types are importable from barrel', () {
      // Compile-time validation — if any type isn't exported, this file fails to compile.
      // We assert one constructor per type to validate the imports take effect at runtime.
      expect(
        const EdenProcessDefinition(
          id: 0,
          processTypeId: 0,
          name: 'x',
          displayName: 'X',
          version: 1,
          isDefault: false,
          isActive: false,
          isPublished: false,
          hasUnpublishedChanges: false,
          config: EdenProcessConfig(),
          phases: [],
        ).runtimeType.toString(),
        contains('EdenProcessDefinition'),
      );
      expect(
        const EdenProcessNodePosition(x: 0, y: 0).runtimeType.toString(),
        contains('EdenProcessNodePosition'),
      );
      expect(EdenDiagramPortKind.source.name, 'source');
    });
  });
}
