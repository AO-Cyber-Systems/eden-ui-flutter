// Do NOT regenerate via LLM — hand-built tests for EdenVisualTemplateBuilder.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_template_canvas_fixtures.dart';

void main() {
  setUp(() {
    EdenTemplateBlockRegistry.instance.resetToDefaults();
    EdenTemplateVariablesRegistry.instance.reset();
    EdenTemplateVariablesRegistry.instance
        .register('customer', const ['name', 'email']);
  });

  Future<void> pumpBuilder(
    WidgetTester tester,
    Widget child, {
    Size size = const Size(1600, 1200),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
  }

  EdenVisualTemplateBuilder builder({
    EdenTemplateLayoutEngine layout = const EdenTemplateVerticalStackLayout(),
    bool hideRightRail = false,
    EdenTemplateLayoutSettings layoutSettings = const EdenTemplateLayoutSettings(),
    EdenTemplateStyleSettings styleSettings = const EdenTemplateStyleSettings(),
    void Function(EdenTemplateBlockDescriptor, EdenTemplateSection, int?)?
        onAddBlock,
    void Function(EdenTemplateStyleSettings)? onChangeStyle,
    void Function(EdenTemplateLayoutSettings)? onChangeLayout,
    void Function(String)? onInsertField,
  }) =>
      EdenVisualTemplateBuilder(
        graph: buildCanvasGraphFixture(),
        styleSettings: styleSettings,
        layoutSettings: layoutSettings,
        layout: layout,
        hideRightRail: hideRightRail,
        onAddBlock: onAddBlock,
        onChangeStyle: onChangeStyle,
        onChangeLayout: onChangeLayout,
        onInsertField: onInsertField,
      );

  group('Composite root — full canvas rendering', () {
    testWidgets('canvas + 4 tab icons + default Blocks panel render',
        (tester) async {
      await pumpBuilder(tester, builder());
      expect(find.byType(EdenTemplateBuilderCanvas), findsOneWidget);
      expect(find.byIcon(Icons.dashboard), findsOneWidget);
      expect(find.byIcon(Icons.data_object), findsOneWidget);
      expect(find.byIcon(Icons.palette_outlined), findsOneWidget);
      expect(find.byType(EdenTemplateBlockPalette), findsOneWidget);
    });
  });

  group('Composite root — tab switching', () {
    testWidgets('Variables tab shows EdenTemplateVariablesPanel',
        (tester) async {
      await pumpBuilder(tester, builder());
      await tester.tap(find.byIcon(Icons.data_object));
      await tester.pumpAndSettle();
      expect(find.byType(EdenTemplateVariablesPanel), findsOneWidget);
      expect(find.byType(EdenTemplateBlockPalette), findsNothing);
    });

    testWidgets('Layout tab shows EdenTemplateLayoutPanel', (tester) async {
      await pumpBuilder(tester, builder());
      // Layout tab uses article_outlined; canvas may also have it, so use last.
      final layoutIcon = find.byIcon(Icons.article_outlined);
      await tester.tap(layoutIcon.last);
      await tester.pumpAndSettle();
      expect(find.byType(EdenTemplateLayoutPanel), findsOneWidget);
    });

    testWidgets('Styles tab shows EdenTemplateStylesPanel', (tester) async {
      await pumpBuilder(tester, builder());
      await tester.tap(find.byIcon(Icons.palette_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(EdenTemplateStylesPanel), findsOneWidget);
    });

    testWidgets('returning to Blocks tab shows palette again', (tester) async {
      await pumpBuilder(tester, builder());
      await tester.tap(find.byIcon(Icons.data_object));
      await tester.pumpAndSettle();
      expect(find.byType(EdenTemplateBlockPalette), findsNothing);
      await tester.tap(find.byIcon(Icons.dashboard));
      await tester.pumpAndSettle();
      expect(find.byType(EdenTemplateBlockPalette), findsOneWidget);
    });
  });

  group('Composite root — hide right rail', () {
    testWidgets('hideRightRail: true removes tab strip and panels',
        (tester) async {
      await pumpBuilder(tester, builder(hideRightRail: true));
      expect(find.byIcon(Icons.dashboard), findsNothing);
      expect(find.byIcon(Icons.data_object), findsNothing);
      expect(find.byType(EdenTemplateBlockPalette), findsNothing);
      // Canvas still present
      expect(find.byType(EdenTemplateBuilderCanvas), findsOneWidget);
    });
  });

  group('Composite root — narrow fallback boundary', () {
    testWidgets('< (1200 + railWidth) shows fallback', (tester) async {
      await pumpBuilder(tester, builder(), size: const Size(1199, 1000));
      expect(
        find.textContaining('tablet/desktop'),
        findsOneWidget,
      );
      expect(find.byType(EdenTemplateBuilderCanvas), findsNothing);
    });

    testWidgets(
        '>= (1200 + railWidth) shows full layout with right rail',
        (tester) async {
      // rightRailWidth default is 280; threshold = 1480.
      await pumpBuilder(tester, builder(), size: const Size(1480, 1000));
      expect(find.byType(EdenTemplateBuilderCanvas), findsOneWidget);
    });

    testWidgets(
        'hideRightRail=true lowers threshold to 1200pt',
        (tester) async {
      await pumpBuilder(
        tester,
        builder(hideRightRail: true),
        size: const Size(1200, 1000),
      );
      expect(find.byType(EdenTemplateBuilderCanvas), findsOneWidget);
    });
  });

  group('Composite root — wiring', () {
    testWidgets('onChangeStyle fires when swatch tapped', (tester) async {
      EdenTemplateStyleSettings? captured;
      await pumpBuilder(
        tester,
        builder(onChangeStyle: (s) => captured = s),
      );
      await tester.tap(find.byIcon(Icons.palette_outlined));
      await tester.pumpAndSettle();
      // Tap any GestureDetector inside the panel (a swatch).
      final swatches = find
          .descendant(
            of: find.byType(EdenTemplateStylesPanel),
            matching: find.byType(GestureDetector),
          )
          .evaluate();
      expect(swatches.isNotEmpty, isTrue);
      // Tap the second swatch to ensure a CHANGE happens (first is default).
      await tester.tap(
        find
            .descendant(
              of: find.byType(EdenTemplateStylesPanel),
              matching: find.byType(GestureDetector),
            )
            .at(1),
      );
      await tester.pump();
      expect(captured, isNotNull);
    });

    testWidgets('onChangeLayout fires when A4 segment tapped', (tester) async {
      EdenTemplateLayoutSettings? captured;
      await pumpBuilder(
        tester,
        builder(onChangeLayout: (s) => captured = s),
      );
      await tester.tap(find.byIcon(Icons.article_outlined).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('A4'));
      await tester.pump();
      expect(captured, isNotNull);
      expect(captured!.pageSize, EdenTemplatePageSize.a4);
    });

    testWidgets('onInsertField fires when variable token tapped',
        (tester) async {
      String? captured;
      await pumpBuilder(
        tester,
        builder(onInsertField: (t) => captured = t),
      );
      await tester.tap(find.byIcon(Icons.data_object));
      await tester.pumpAndSettle();
      await tester.tap(find.text('{{customer.email}}'));
      await tester.pump();
      expect(captured, '{{customer.email}}');
    });
  });
}
