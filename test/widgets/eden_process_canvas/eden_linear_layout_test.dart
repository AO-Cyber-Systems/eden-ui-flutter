import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_process_layout_fixtures.dart';

void main() {
  group('EdenLinearLayout — identity and defaults', () {
    test('id is "linear"', () {
      expect(const EdenLinearLayout().id, 'linear');
    });

    test('default spacing=300, startX=100, startY=200', () {
      const layout = EdenLinearLayout();
      expect(layout.spacing, 300);
      expect(layout.startX, 100);
      expect(layout.startY, 200);
    });

    test('custom params applied', () {
      const layout = EdenLinearLayout(spacing: 250, startX: 50, startY: 100);
      expect(layout.spacing, 250);
      expect(layout.startX, 50);
      expect(layout.startY, 100);
    });
  });

  group('EdenLinearLayout — basic positioning', () {
    test('4 nodes in single row with default spacing', () {
      final nodes = fourNodesForLinear();
      final out = const EdenLinearLayout().applyLayout(nodes, const []);
      expect(out[0].x, 100);
      expect(out[0].y, 200);
      expect(out[1].x, 400);
      expect(out[2].x, 700);
      expect(out[3].x, 1000);
      // All in same row
      for (final n in out) {
        expect(n.y, 200);
      }
    });
  });

  group('EdenLinearLayout — pure function', () {
    test('input nodes not mutated', () {
      final nodes = fourNodesForLinear();
      final originalXs = nodes.map((n) => n.x).toList();
      const EdenLinearLayout().applyLayout(nodes, const []);
      for (int i = 0; i < nodes.length; i++) {
        expect(nodes[i].x, originalXs[i]);
      }
    });
  });
}
