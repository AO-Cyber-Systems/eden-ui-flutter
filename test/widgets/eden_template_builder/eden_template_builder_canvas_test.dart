// Do NOT regenerate via LLM — hand-built tests for EdenTemplateBuilderCanvas.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_template_canvas_fixtures.dart';

void main() {
  setUp(() {
    EdenTemplateBlockRegistry.instance.resetToDefaults();
    EdenTemplateVariablesRegistry.instance.reset();
  });

  group('narrow fallback boundary', () {
    testWidgets('<1200pt shows fallback message', (tester) async {
      await pumpCanvas(
        tester,
        EdenTemplateBuilderCanvas(graph: buildCanvasGraphFixture()),
        size: const Size(1199, 900),
      );
      expect(
        find.textContaining('tablet/desktop'),
        findsOneWidget,
      );
      expect(find.text('Header'), findsNothing);
    });

    testWidgets('1200pt shows full canvas (section tabs visible)',
        (tester) async {
      await pumpCanvas(
        tester,
        EdenTemplateBuilderCanvas(graph: buildCanvasGraphFixture()),
        size: const Size(1200, 900),
      );
      expect(find.text('Header'), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);
      expect(find.text('Footer'), findsOneWidget);
    });

    testWidgets('390pt (iPhone) shows fallback + no overflow', (tester) async {
      await pumpCanvas(
        tester,
        EdenTemplateBuilderCanvas(graph: buildCanvasGraphFixture()),
        size: const Size(390, 800),
      );
      expect(tester.takeException(), isNull);
      expect(
        find.textContaining('tablet/desktop'),
        findsOneWidget,
      );
    });

    testWidgets('custom narrowFallback widget overrides default',
        (tester) async {
      await pumpCanvas(
        tester,
        EdenTemplateBuilderCanvas(
          graph: buildCanvasGraphFixture(),
          narrowFallback: const Text('CUSTOM FALLBACK'),
        ),
        size: const Size(800, 600),
      );
      expect(find.text('CUSTOM FALLBACK'), findsOneWidget);
      expect(find.textContaining('tablet/desktop'), findsNothing);
    });
  });

  group('section filtering', () {
    testWidgets('body section renders 5 placeholders (initial section)',
        (tester) async {
      await pumpCanvas(
        tester,
        EdenTemplateBuilderCanvas(graph: buildCanvasGraphFixture()),
      );
      expect(find.byType(EdenTemplateBlockPlaceholder), findsNWidgets(5));
      expect(find.text('Greeting'), findsOneWidget);
      expect(find.text('Closing'), findsOneWidget);
    });

    testWidgets('tapping Header tab renders 3 placeholders', (tester) async {
      await pumpCanvas(
        tester,
        EdenTemplateBuilderCanvas(graph: buildCanvasGraphFixture()),
      );
      await tester.tap(find.text('Header'));
      await tester.pumpAndSettle();
      expect(find.byType(EdenTemplateBlockPlaceholder), findsNWidgets(3));
      expect(find.text('Header text'), findsOneWidget);
      expect(find.text('Logo'), findsOneWidget);
    });

    testWidgets(
        'tapping Footer tab renders 2 placeholders + footer chrome',
        (tester) async {
      await pumpCanvas(
        tester,
        EdenTemplateBuilderCanvas(graph: buildCanvasGraphFixture()),
      );
      await tester.tap(find.text('Footer'));
      await tester.pumpAndSettle();
      expect(find.byType(EdenTemplateBlockPlaceholder), findsNWidgets(2));
      expect(find.text('Page footer text'), findsOneWidget);
      expect(find.text('Page Footer'), findsOneWidget);
      expect(find.textContaining('Page 1 of'), findsOneWidget);
    });
  });

  group('empty-section state', () {
    testWidgets('empty body section renders helpful empty state',
        (tester) async {
      await pumpCanvas(
        tester,
        const EdenTemplateBuilderCanvas(
          graph: EdenTemplateGraph(
            id: 't',
            name: 't',
            category: 'c',
            version: 'v',
            status: 'draft',
            blocks: [],
          ),
        ),
      );
      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
      expect(find.textContaining('No blocks'), findsOneWidget);
      expect(find.textContaining('palette'), findsOneWidget);
    });
  });

  group('vertical-stack mode (default)', () {
    testWidgets('ReorderableListView is in the widget tree', (tester) async {
      await pumpCanvas(
        tester,
        EdenTemplateBuilderCanvas(graph: buildCanvasGraphFixture()),
      );
      expect(find.byType(ReorderableListView), findsOneWidget);
    });

    testWidgets('reorder fires onReorderBlock with adjusted index',
        (tester) async {
      EdenTemplateSection? capSection;
      int? capOld;
      int? capNew;
      await pumpCanvas(
        tester,
        EdenTemplateBuilderCanvas(
          graph: buildCanvasGraphFixture(),
          onReorderBlock: (s, o, n) {
            capSection = s;
            capOld = o;
            capNew = n;
          },
        ),
      );
      // Find the state and invoke handleReorder directly via the public API.
      final state = tester.state<State<EdenTemplateBuilderCanvas>>(
        find.byType(EdenTemplateBuilderCanvas),
      );
      // Use the publicly-tested adjustment: oldIndex=0, newIndex=3 → adjusted=2.
      (state as dynamic).handleReorderForTest(0, 3);
      expect(capSection, EdenTemplateSection.body);
      expect(capOld, 0);
      expect(capNew, 2);
    });

    testWidgets(
        'reorder oldIndex > newIndex passes through (no adjustment)',
        (tester) async {
      int? capOld;
      int? capNew;
      await pumpCanvas(
        tester,
        EdenTemplateBuilderCanvas(
          graph: buildCanvasGraphFixture(),
          onReorderBlock: (s, o, n) {
            capOld = o;
            capNew = n;
          },
        ),
      );
      final state = tester.state<State<EdenTemplateBuilderCanvas>>(
        find.byType(EdenTemplateBuilderCanvas),
      );
      (state as dynamic).handleReorderForTest(3, 1);
      expect(capOld, 3);
      expect(capNew, 1);
    });
  });

  group('freeform mode', () {
    testWidgets('renders EdenDiagram', (tester) async {
      await pumpCanvas(
        tester,
        EdenTemplateBuilderCanvas(
          graph: buildCanvasGraphFixture(),
          layout: const EdenTemplateFreeformLayout(),
        ),
      );
      expect(find.byType(EdenDiagram), findsOneWidget);
      expect(find.byType(ReorderableListView), findsNothing);
    });
  });

  group('callbacks', () {
    testWidgets('onDeleteBlock fires when delete affordance tapped',
        (tester) async {
      String? deletedId;
      await pumpCanvas(
        tester,
        EdenTemplateBuilderCanvas(
          graph: buildCanvasGraphFixture(),
          onDeleteBlock: (id) => deletedId = id,
        ),
      );
      // Tap the first close button on a body placeholder.
      final closeIcons = find.byIcon(Icons.close);
      expect(closeIcons, findsWidgets);
      await tester.tap(closeIcons.first);
      await tester.pump();
      expect(deletedId, isNotNull);
      // The body has b1..b5 sorted by order; deleting first → 'b1'.
      expect(deletedId, 'b1');
    });
  });

  group('desktop rendering', () {
    testWidgets('1400x900 renders without overflow', (tester) async {
      await pumpCanvas(
        tester,
        EdenTemplateBuilderCanvas(graph: buildCanvasGraphFixture()),
        size: const Size(1400, 900),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Body'), findsOneWidget);
    });
  });
}
