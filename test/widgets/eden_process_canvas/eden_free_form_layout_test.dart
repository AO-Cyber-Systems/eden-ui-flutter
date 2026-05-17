import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_process_layout_fixtures.dart';

void main() {
  const freeForm = EdenFreeFormLayout();

  group('EdenFreeFormLayout — identity', () {
    test('id is "free_form"', () {
      expect(freeForm.id, 'free_form');
    });

    test('empty input returns empty output', () {
      expect(freeForm.applyLayout(const [], const []), isEmpty);
    });
  });

  group('EdenFreeFormLayout — simple chain', () {
    test('chain start → phase-1 → phase-2 → end positions at successive ranks',
        () {
      final (nodes, edges) = chainGraph();
      final out = freeForm.applyLayout(nodes, edges);
      final start = out.firstWhere((n) => n.id == 'start');
      final p1 = out.firstWhere((n) => n.id == 'phase-1');
      final p2 = out.firstWhere((n) => n.id == 'phase-2');
      final end = out.firstWhere((n) => n.id == 'end');
      // origin (100,100); colSpacing=280; rowSpacing=140
      expect(start.x, 100);
      expect(start.y, 100);
      expect(p1.x, 380);
      expect(p2.x, 660);
      expect(end.x, 940);
    });
  });

  group('EdenFreeFormLayout — branching', () {
    test('start → [p1, p2] → end stacks p1/p2 vertically at rank 1', () {
      final (nodes, edges) = branchingGraph();
      final out = freeForm.applyLayout(nodes, edges);
      final p1 = out.firstWhere((n) => n.id == 'phase-1');
      final p2 = out.firstWhere((n) => n.id == 'phase-2');
      final end = out.firstWhere((n) => n.id == 'end');
      expect(p1.x, 380);
      expect(p2.x, 380);
      // First-visited in input order = phase-1 gets y=100, phase-2 gets y=240.
      expect(p1.y, 100);
      expect(p2.y, 240);
      expect(end.x, 660);
    });
  });

  group('EdenFreeFormLayout — longest-path semantics (diamond)', () {
    test('end placed at rank 3 because longest path is start→a→c→end', () {
      final (nodes, edges) = diamondGraph();
      final out = freeForm.applyLayout(nodes, edges);
      final end = out.firstWhere((n) => n.id == 'end');
      // start=0, a=1, b=1, c=2, end=3 (longest path)
      expect(end.x, 100 + 3 * 280);
    });
  });

  group('EdenFreeFormLayout — cycle handling', () {
    test('cycle a → b → c → a converges without infinite loop', () {
      final (nodes, edges) = cycleGraph();
      final out = freeForm.applyLayout(nodes, edges);
      expect(out.length, nodes.length);
      // Every node has a finite position.
      for (final n in out) {
        expect(n.x.isFinite, isTrue);
        expect(n.y.isFinite, isTrue);
      }
    });
  });

  group('EdenFreeFormLayout — disconnected', () {
    test('disconnected orphan at rank = maxRank + 1', () {
      final (nodes, edges) = chainWithDisconnectedOrphanGraph();
      final out = freeForm.applyLayout(nodes, edges);
      final orphan = out.firstWhere((n) => n.id == 'orphan-1');
      // Main chain: start=0, phase-1=1, end=2. orphan rank=3.
      expect(orphan.x, 100 + 3 * 280);
    });
  });

  group('EdenFreeFormLayout — pure function', () {
    test('input node x/y not mutated', () {
      final (nodes, edges) = chainGraph();
      final originalXs = nodes.map((n) => n.x).toList();
      freeForm.applyLayout(nodes, edges);
      for (int i = 0; i < nodes.length; i++) {
        expect(nodes[i].x, originalXs[i]);
      }
    });

    test('returns new instances for positioned nodes', () {
      final (nodes, edges) = chainGraph();
      final out = freeForm.applyLayout(nodes, edges);
      expect(identical(nodes.first, out.first), isFalse);
    });
  });
}
