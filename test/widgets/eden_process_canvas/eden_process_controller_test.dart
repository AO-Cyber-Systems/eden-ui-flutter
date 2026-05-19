import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EdenProcessController — selection', () {
    test('select updates selectedNodeId and notifies', () {
      final ctrl = EdenProcessController();
      addTearDown(ctrl.dispose);
      int notifyCount = 0;
      ctrl.addListener(() => notifyCount++);
      ctrl.select('phase-1');
      expect(ctrl.selectedNodeId, 'phase-1');
      expect(notifyCount, 1);
    });

    test('select with same id is a no-op (no notify)', () {
      final ctrl = EdenProcessController();
      addTearDown(ctrl.dispose);
      ctrl.select('phase-1');
      int notifyCount = 0;
      ctrl.addListener(() => notifyCount++);
      ctrl.select('phase-1');
      expect(notifyCount, 0);
    });

    test('select(null) clears selection', () {
      final ctrl = EdenProcessController();
      addTearDown(ctrl.dispose);
      ctrl.select('phase-1');
      ctrl.select(null);
      expect(ctrl.selectedNodeId, isNull);
    });
  });

  group('EdenProcessController — phase expansion', () {
    test('togglePhaseExpanded toggles membership', () {
      final ctrl = EdenProcessController();
      addTearDown(ctrl.dispose);
      ctrl.togglePhaseExpanded(1);
      expect(ctrl.expandedPhaseIds, contains(1));
      ctrl.togglePhaseExpanded(1);
      expect(ctrl.expandedPhaseIds, isNot(contains(1)));
    });

    test('expandedPhaseIds returns unmodifiable set', () {
      final ctrl = EdenProcessController();
      addTearDown(ctrl.dispose);
      expect(() => ctrl.expandedPhaseIds.add(42), throwsUnsupportedError);
    });
  });

  group('EdenProcessController — orphans', () {
    test('addOrphan / removeOrphan / orphans list', () {
      final ctrl = EdenProcessController();
      addTearDown(ctrl.dispose);
      final node = EdenDiagramNode(id: 'orphan-1', x: 0, y: 0);
      ctrl.addOrphan(node);
      expect(ctrl.orphans, hasLength(1));
      ctrl.removeOrphan('orphan-1');
      expect(ctrl.orphans, isEmpty);
    });

    test('removeOrphan cascades to userEdges referencing the orphan', () {
      final ctrl = EdenProcessController();
      addTearDown(ctrl.dispose);
      final orphan = EdenDiagramNode(id: 'orphan-1', x: 0, y: 0);
      ctrl.addOrphan(orphan);
      ctrl.addUserEdge(EdenDiagramEdge(
        id: 'user-1',
        sourceId: 'orphan-1',
        targetId: 'phase-1',
      ));
      ctrl.addUserEdge(EdenDiagramEdge(
        id: 'user-2',
        sourceId: 'phase-1',
        targetId: 'orphan-1',
      ));
      ctrl.addUserEdge(EdenDiagramEdge(
        id: 'user-3',
        sourceId: 'phase-2',
        targetId: 'phase-3',
      ));
      ctrl.removeOrphan('orphan-1');
      expect(ctrl.userEdges.map((e) => e.id), ['user-3']);
    });

    test('generateOrphanId emits stable incrementing ids', () {
      final ctrl = EdenProcessController();
      addTearDown(ctrl.dispose);
      expect(ctrl.generateOrphanId(), 'orphan-1');
      expect(ctrl.generateOrphanId(), 'orphan-2');
    });
  });

  group('EdenProcessController — user edges', () {
    test('addUserEdge injects edgeStyle: user if missing', () {
      final ctrl = EdenProcessController();
      addTearDown(ctrl.dispose);
      final edge = EdenDiagramEdge(
        id: 'e',
        sourceId: 'a',
        targetId: 'b',
      );
      ctrl.addUserEdge(edge);
      expect(ctrl.userEdges.single.data['edgeStyle'], 'user');
    });

    test('addUserEdge preserves existing edgeStyle', () {
      final ctrl = EdenProcessController();
      addTearDown(ctrl.dispose);
      final edge = EdenDiagramEdge(
        id: 'e',
        sourceId: 'a',
        targetId: 'b',
        data: {'edgeStyle': 'custom'},
      );
      ctrl.addUserEdge(edge);
      expect(ctrl.userEdges.single.data['edgeStyle'], 'custom');
    });

    test('removeUserEdge removes by id', () {
      final ctrl = EdenProcessController();
      addTearDown(ctrl.dispose);
      ctrl.addUserEdge(EdenDiagramEdge(id: 'e', sourceId: 'a', targetId: 'b'));
      ctrl.removeUserEdge('e');
      expect(ctrl.userEdges, isEmpty);
    });
  });

  group('EdenProcessController — manual positions', () {
    test('recordManualPosition stores by id', () {
      final ctrl = EdenProcessController();
      addTearDown(ctrl.dispose);
      ctrl.recordManualPosition('phase-1', const Offset(150, 75));
      expect(ctrl.manualPositionFor('phase-1'), const Offset(150, 75));
    });

    test('recording same id with new offset overwrites', () {
      final ctrl = EdenProcessController();
      addTearDown(ctrl.dispose);
      ctrl.recordManualPosition('phase-1', const Offset(100, 50));
      ctrl.recordManualPosition('phase-1', const Offset(200, 25));
      expect(ctrl.manualPositionFor('phase-1'), const Offset(200, 25));
    });
  });

  group('EdenProcessController — pending positions', () {
    test('setPendingPosition stores; clearPendingPosition removes', () {
      final ctrl = EdenProcessController();
      addTearDown(ctrl.dispose);
      ctrl.setPendingPosition('orphan-1', const Offset(400, 200));
      expect(ctrl.pendingPositions['orphan-1'], const Offset(400, 200));
      ctrl.clearPendingPosition('orphan-1');
      expect(ctrl.pendingPositions.containsKey('orphan-1'), isFalse);
    });

    test('pendingPositions returns unmodifiable map', () {
      final ctrl = EdenProcessController();
      addTearDown(ctrl.dispose);
      expect(
        () => ctrl.pendingPositions['x'] = const Offset(0, 0),
        throwsUnsupportedError,
      );
    });
  });

  group('EdenProcessController — layout engine swap', () {
    test('default layout is EdenSwimlaneLayout', () {
      final ctrl = EdenProcessController();
      addTearDown(ctrl.dispose);
      expect(ctrl.layout.id, 'swimlane');
    });

    test('setting layout swaps engine and notifies', () {
      final ctrl = EdenProcessController();
      addTearDown(ctrl.dispose);
      int notifyCount = 0;
      ctrl.addListener(() => notifyCount++);
      ctrl.layout = const EdenFreeFormLayout();
      expect(ctrl.layout.id, 'free_form');
      expect(notifyCount, 1);
    });

    test('setting same layout id is a no-op', () {
      final ctrl = EdenProcessController();
      addTearDown(ctrl.dispose);
      int notifyCount = 0;
      ctrl.addListener(() => notifyCount++);
      ctrl.layout = const EdenSwimlaneLayout(); // same id as default
      expect(notifyCount, 0);
    });
  });

  group('EdenProcessController — toLayoutData / fromLayoutData round-trip', () {
    test('toLayoutData captures manual positions + user edges', () {
      final ctrl = EdenProcessController();
      addTearDown(ctrl.dispose);
      ctrl.recordManualPosition('phase-1', const Offset(100, 50));
      ctrl.recordManualPosition('group-10', const Offset(350, 50));
      ctrl.addUserEdge(EdenDiagramEdge(
        id: 'user-e1',
        sourceId: 'phase-1',
        targetId: 'group-10',
      ));
      final data = ctrl.toLayoutData(
        viewport: const EdenProcessViewport(x: 10, y: 20, zoom: 1.5),
      );
      expect(data.nodes, hasLength(2));
      expect(data.nodes['phase-1']?.x, 100);
      expect(data.edges, hasLength(1));
      expect(data.viewport?.zoom, 1.5);
    });

    test('fromLayoutData restores positions + edges + clears prior state', () {
      final ctrl = EdenProcessController();
      addTearDown(ctrl.dispose);
      ctrl.recordManualPosition('old-phase', const Offset(1, 1));
      ctrl.fromLayoutData(EdenProcessLayoutData(
        version: 1,
        autoLayout: false,
        nodes: const {
          'phase-1': EdenProcessNodePosition(x: 100, y: 50),
        },
        edges: const [
          EdenProcessSavedEdge(
            id: 'user-1',
            source: 'a',
            target: 'b',
            sourceHandle: 'right',
            targetHandle: 'left',
          ),
        ],
      ));
      expect(ctrl.manualPositionFor('old-phase'), isNull);
      expect(ctrl.manualPositionFor('phase-1'), const Offset(100, 50));
      expect(ctrl.userEdges, hasLength(1));
      expect(ctrl.userEdges.single.sourcePortId, 'right');
      expect(ctrl.userEdges.single.targetPortId, 'left');
      expect(ctrl.userEdges.single.data['edgeStyle'], 'user');
    });

    test('round-trip: toLayoutData then fromLayoutData preserves state', () {
      final ctrl = EdenProcessController();
      addTearDown(ctrl.dispose);
      ctrl.recordManualPosition('phase-1', const Offset(100, 50));
      ctrl.addUserEdge(EdenDiagramEdge(
        id: 'user-e1',
        sourceId: 'a',
        targetId: 'b',
        sourcePortId: 'yes',
      ));
      final snapshot = ctrl.toLayoutData();
      final ctrl2 = EdenProcessController();
      addTearDown(ctrl2.dispose);
      ctrl2.fromLayoutData(snapshot);
      expect(ctrl2.manualPositionFor('phase-1'), const Offset(100, 50));
      expect(ctrl2.userEdges.single.sourcePortId, 'yes');
    });
  });

  group('EdenProcessController — reset', () {
    test('reset clears all state and notifies', () {
      final ctrl = EdenProcessController();
      addTearDown(ctrl.dispose);
      ctrl.select('phase-1');
      ctrl.togglePhaseExpanded(1);
      ctrl.addOrphan(EdenDiagramNode(id: 'orphan-1', x: 0, y: 0));
      ctrl.addUserEdge(EdenDiagramEdge(id: 'e', sourceId: 'a', targetId: 'b'));
      ctrl.recordManualPosition('phase-1', const Offset(0, 0));
      ctrl.setPendingPosition('orphan-1', const Offset(0, 0));
      int notifyCount = 0;
      ctrl.addListener(() => notifyCount++);
      ctrl.reset();
      expect(ctrl.selectedNodeId, isNull);
      expect(ctrl.expandedPhaseIds, isEmpty);
      expect(ctrl.orphans, isEmpty);
      expect(ctrl.userEdges, isEmpty);
      expect(ctrl.manualPositionFor('phase-1'), isNull);
      expect(ctrl.pendingPositions, isEmpty);
      expect(notifyCount, 1);
    });

    test('reset re-zeroes orphan id counter', () {
      final ctrl = EdenProcessController();
      addTearDown(ctrl.dispose);
      ctrl.generateOrphanId();
      ctrl.generateOrphanId();
      ctrl.reset();
      expect(ctrl.generateOrphanId(), 'orphan-1');
    });
  });
}
