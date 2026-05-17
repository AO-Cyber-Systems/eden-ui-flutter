import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_process_layout_fixtures.dart';

void main() {
  const swimlane = EdenSwimlaneLayout();

  group('EdenSwimlaneLayout — identity + empty input', () {
    test('id is "swimlane"', () {
      expect(swimlane.id, 'swimlane');
    });

    test('empty input returns empty output', () {
      expect(swimlane.applyLayout(const [], const []), isEmpty);
    });
  });

  group('EdenSwimlaneLayout — start + end only', () {
    test('positions start at (150, 50) and end below row gap', () {
      final (nodes, edges) = startEndOnlyGraph();
      final out = swimlane.applyLayout(nodes, edges);
      final start = out.firstWhere((n) => n.id == 'start');
      final end = out.firstWhere((n) => n.id == 'end');
      expect(start.x, 150);
      expect(start.y, 50);
      // start (y=50) + height (48) + ROW_GAP (80) = 178 → end
      expect(end.x, 150);
      expect(end.y, 178);
    });
  });

  group('EdenSwimlaneLayout — single phase, no groups', () {
    test('phase at x=50; end below it', () {
      final (nodes, edges) = singlePhaseNoGroupsGraph();
      final out = swimlane.applyLayout(nodes, edges);
      final phase = out.firstWhere((n) => n.id == 'phase-1');
      final end = out.firstWhere((n) => n.id == 'end');
      expect(phase.x, 50);
      // After start (y=50 + 48 + 80 = 178), phase row top is 178.
      // No groups → rowHeight = phaseNodeHeight = 120. phaseCenterOffset = 0
      // because the donor algorithm only centers when groups.isNotEmpty.
      expect(phase.y, 178);
      // currentY becomes 178 + 120 + 80 = 378.
      expect(end.y, 378);
    });
  });

  group('EdenSwimlaneLayout — single phase + 2 groups', () {
    test('groups stack at x=390 with 30pt gap; phase vertically centered',
        () {
      final (nodes, edges) = singlePhaseTwoGroupsGraph();
      final out = swimlane.applyLayout(nodes, edges);
      final phase = out.firstWhere((n) => n.id == 'phase-1');
      final g10 = out.firstWhere((n) => n.id == 'group-10');
      final g11 = out.firstWhere((n) => n.id == 'group-11');

      expect(g10.x, 390);
      expect(g11.x, 390);
      // rowTopY = 178 (after start row).
      expect(g10.y, 178);
      // g10 height (80 — taskCount=0) + 30 gap = next group top at 178 + 110.
      expect(g11.y, 178 + 80 + 30);

      // Total group column height = 80 + 30 + 80 = 190; rowHeight = max(190, 120) = 190
      // phaseCenterOffset = (190 - 120)/2 = 35
      expect(phase.x, 50);
      expect(phase.y, 178 + 35);
    });
  });

  group('EdenSwimlaneLayout — varying task counts impact height', () {
    test('5-task group is 240pt tall; column total = 80 + 30 + 240 = 350', () {
      final (nodes, edges) = singlePhaseTwoGroupsVaryingTaskCountGraph();
      final out = swimlane.applyLayout(nodes, edges);
      final g10 = out.firstWhere((n) => n.id == 'group-10');
      final g11 = out.firstWhere((n) => n.id == 'group-11');
      final phase = out.firstWhere((n) => n.id == 'phase-1');

      expect(g10.y, 178);
      // g10 (height 80, 0 tasks) + gap 30 = g11 top at 178 + 110.
      expect(g11.y, 178 + 80 + 30);

      // Total column = 80 + 30 + 240 = 350. rowHeight = max(350, 120) = 350.
      // phaseCenterOffset = (350 - 120) / 2 = 115
      expect(phase.y, 178 + 115);
    });
  });

  group('EdenSwimlaneLayout — multi-phase', () {
    test('3 phases each with 2 groups stack in 3 rows', () {
      final (nodes, edges) = threePhasesEachTwoGroupsGraph();
      final out = swimlane.applyLayout(nodes, edges);
      final p1 = out.firstWhere((n) => n.id == 'phase-1');
      final p2 = out.firstWhere((n) => n.id == 'phase-2');
      final p3 = out.firstWhere((n) => n.id == 'phase-3');
      final end = out.firstWhere((n) => n.id == 'end');

      // Each phase row: groups 0-task each → column total 80+30+80 = 190.
      // rowHeight = 190; phaseCenterOffset = 35.
      // rowTop progression: 178, 178+190+80=448, 448+190+80=718.
      expect(p1.y, 178 + 35);
      expect(p2.y, 448 + 35);
      expect(p3.y, 718 + 35);
      // End at 718 + 190 + 80 = 988.
      expect(end.y, 988);
    });
  });

  group('EdenSwimlaneLayout — decisions + orphans', () {
    test('placed in horizontal "other" row below end, 250pt apart', () {
      final (nodes, edges) = graphWithDecisionAndOrphan();
      final out = swimlane.applyLayout(nodes, edges);
      final end = out.firstWhere((n) => n.id == 'end');
      final decision = out.firstWhere((n) => n.id == 'decision-7');
      final orphan = out.firstWhere((n) => n.id == 'orphan-1');

      // currentY at end placement = 378 (single phase row case).
      expect(end.y, 378);
      // Others 100pt below currentY at indexes 0 and 1.
      expect(decision.x, 50);
      expect(decision.y, 378 + 100);
      expect(orphan.x, 50 + 250);
      expect(orphan.y, 378 + 100);
    });
  });

  group('EdenSwimlaneLayout — pure function', () {
    test('input node x/y not mutated', () {
      final (nodes, edges) = singlePhaseTwoGroupsGraph();
      final originalXs = nodes.map((n) => n.x).toList();
      final originalYs = nodes.map((n) => n.y).toList();
      swimlane.applyLayout(nodes, edges);
      for (int i = 0; i < nodes.length; i++) {
        expect(nodes[i].x, originalXs[i], reason: 'node ${nodes[i].id} x mutated');
        expect(nodes[i].y, originalYs[i], reason: 'node ${nodes[i].id} y mutated');
      }
    });

    test('returns new instances for positioned nodes', () {
      final (nodes, edges) = singlePhaseTwoGroupsGraph();
      final out = swimlane.applyLayout(nodes, edges);
      final inputPhase = nodes.firstWhere((n) => n.id == 'phase-1');
      final outputPhase = out.firstWhere((n) => n.id == 'phase-1');
      expect(identical(inputPhase, outputPhase), isFalse);
    });

    test('output length matches input length', () {
      final (nodes, edges) = singlePhaseTwoGroupsGraph();
      final out = swimlane.applyLayout(nodes, edges);
      expect(out.length, nodes.length);
    });
  });

  group('EdenSwimlaneLayout — skips dependency edges', () {
    test('dependency edge does not act as parent association', () {
      final (nodes, edges) = graphWithDependencyEdgeMixed();
      final out = swimlane.applyLayout(nodes, edges);
      // group-10 is parented to phase-1 via the autoFan edge; the
      // dependency edge from start→group-10 must be skipped (otherwise
      // group-10 would be placed in the "other" row, not at x=390).
      final g10 = out.firstWhere((n) => n.id == 'group-10');
      expect(g10.x, 390);
    });
  });
}
