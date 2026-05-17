// Do NOT regenerate via LLM — hand-built smoke test for the obj 021
// template-builder dev-catalog screen.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eden_ui_flutter/dev_app/screens/template_builder_screen.dart';

Future<void> pumpScreen(WidgetTester tester) async {
  // Surface must be wide enough for canvas (1200pt) + right rail (280pt)
  // + a bit of slack for the Scaffold chrome.
  await tester.binding.setSurfaceSize(const Size(1600, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(const MaterialApp(home: TemplateBuilderScreen()));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    EdenTemplateBlockRegistry.instance.resetToDefaults();
    EdenTemplateVariablesRegistry.instance.reset();
  });

  testWidgets('TemplateBuilderScreen renders full builder at desktop width',
      (tester) async {
    await pumpScreen(tester);
    expect(find.byType(EdenVisualTemplateBuilder), findsOneWidget);
    expect(find.byType(EdenTemplateBuilderCanvas), findsOneWidget);
    expect(find.byType(EdenTemplateBlockPalette), findsOneWidget);
    expect(
      find.byType(EdenTemplateBlockPlaceholder).evaluate().length,
      greaterThanOrEqualTo(5),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('right-rail tab switching surfaces all 4 panels',
      (tester) async {
    await pumpScreen(tester);
    // Variables.
    await tester.tap(find.byIcon(Icons.data_object));
    await tester.pumpAndSettle();
    expect(find.byType(EdenTemplateVariablesPanel), findsOneWidget);
    // Layout — icon shared with home_screen tile + dev catalog appbar; use
    // descendant within the right-rail surface area.
    await tester.tap(find.byIcon(Icons.article_outlined).last);
    await tester.pumpAndSettle();
    expect(find.byType(EdenTemplateLayoutPanel), findsOneWidget);
    // Styles.
    await tester.tap(find.byIcon(Icons.palette_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(EdenTemplateStylesPanel), findsOneWidget);
    // Back to Blocks.
    await tester.tap(find.byIcon(Icons.dashboard));
    await tester.pumpAndSettle();
    expect(find.byType(EdenTemplateBlockPalette), findsOneWidget);
  });

  testWidgets('layout-engine toggle switches between vertical-stack and freeform',
      (tester) async {
    await pumpScreen(tester);
    expect(find.byType(ReorderableListView), findsOneWidget);
    expect(find.byType(EdenDiagram), findsNothing);

    // Open the dropdown.
    await tester.tap(find.text('Vertical Stack'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Freeform').last);
    await tester.pumpAndSettle();

    expect(find.byType(EdenDiagram), findsOneWidget);
  });

  testWidgets('Reset Demo button is wired and idempotent', (tester) async {
    await pumpScreen(tester);
    final initialCount =
        find.byType(EdenTemplateBlockPlaceholder).evaluate().length;
    expect(initialCount, greaterThanOrEqualTo(5));

    await tester.tap(find.text('Reset Demo'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.byType(EdenTemplateBlockPlaceholder).evaluate().length,
      equals(initialCount),
    );
  });
}
