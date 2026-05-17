import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_process_layout_fixtures.dart';

void main() {
  group('EdenGridLayout — identity and defaults', () {
    test('id is "grid"', () {
      expect(const EdenGridLayout().id, 'grid');
    });

    test('default columns=3, spacing=300', () {
      const layout = EdenGridLayout();
      expect(layout.columns, 3);
      expect(layout.spacing, 300);
    });

    test('custom columns and spacing applied', () {
      const layout = EdenGridLayout(columns: 4, spacing: 200);
      expect(layout.columns, 4);
      expect(layout.spacing, 200);
    });
  });

  group('EdenGridLayout — basic positioning', () {
    test('6 nodes wrap into 2 rows of 3 with default 3 columns', () {
      final nodes = sixNodesForGrid();
      final out = const EdenGridLayout(columns: 3, spacing: 300)
          .applyLayout(nodes, const []);
      // Row 0
      expect(out[0].x, 100);
      expect(out[0].y, 100);
      expect(out[1].x, 400);
      expect(out[1].y, 100);
      expect(out[2].x, 700);
      expect(out[2].y, 100);
      // Row 1
      expect(out[3].x, 100);
      expect(out[3].y, 300);
      expect(out[4].x, 400);
      expect(out[4].y, 300);
      expect(out[5].x, 700);
      expect(out[5].y, 300);
    });
  });

  group('EdenGridLayout — pure function', () {
    test('input node x not mutated', () {
      final nodes = sixNodesForGrid();
      final originalXs = nodes.map((n) => n.x).toList();
      const EdenGridLayout().applyLayout(nodes, const []);
      for (int i = 0; i < nodes.length; i++) {
        expect(nodes[i].x, originalXs[i]);
      }
    });
  });
}
