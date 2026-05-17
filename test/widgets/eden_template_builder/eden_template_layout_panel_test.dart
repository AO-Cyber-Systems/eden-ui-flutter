// Do NOT regenerate via LLM — hand-built tests for EdenTemplateLayoutPanel.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_template_panels_fixtures.dart';

void main() {
  setUp(() {
    EdenTemplateBlockRegistry.instance.resetToDefaults();
    EdenTemplateVariablesRegistry.instance.reset();
  });

  testWidgets('initial render shows headers + segments + margins + checkboxes',
      (tester) async {
    await pumpPanel(
      tester,
      EdenTemplateLayoutPanel(
        value: buildPanelLayoutFixture(),
        onChangeLayout: (_) {},
      ),
    );
    expect(find.text('PAGE LAYOUT'), findsOneWidget);
    expect(find.text('Page Size'), findsOneWidget);
    expect(find.text('Orientation'), findsOneWidget);
    expect(find.text('Margins (in)'), findsOneWidget);
    expect(find.text('Letter'), findsOneWidget);
    expect(find.text('A4'), findsOneWidget);
    expect(find.text('Legal'), findsOneWidget);
    expect(find.text('Portrait'), findsOneWidget);
    expect(find.text('Landscape'), findsOneWidget);
    expect(find.text('Top'), findsOneWidget);
    expect(find.text('Right'), findsOneWidget);
    expect(find.text('Bottom'), findsOneWidget);
    expect(find.text('Left'), findsOneWidget);
    expect(find.text('Different first page header'), findsOneWidget);
    expect(find.text('Page numbers in footer'), findsOneWidget);
  });

  testWidgets('tapping A4 segment fires onChangeLayout',
      (tester) async {
    EdenTemplateLayoutSettings? captured;
    await pumpPanel(
      tester,
      EdenTemplateLayoutPanel(
        value: buildPanelLayoutFixture(),
        onChangeLayout: (s) => captured = s,
      ),
    );
    await tester.tap(find.text('A4'));
    await tester.pump();
    expect(captured, isNotNull);
    expect(captured!.pageSize, EdenTemplatePageSize.a4);
    expect(captured!.orientation, EdenTemplateOrientation.portrait);
  });

  testWidgets('tapping Landscape segment fires onChangeLayout',
      (tester) async {
    EdenTemplateLayoutSettings? captured;
    await pumpPanel(
      tester,
      EdenTemplateLayoutPanel(
        value: buildPanelLayoutFixture(),
        onChangeLayout: (s) => captured = s,
      ),
    );
    await tester.tap(find.text('Landscape'));
    await tester.pump();
    expect(captured, isNotNull);
    expect(captured!.orientation, EdenTemplateOrientation.landscape);
  });

  testWidgets('margin field edit + submit fires onChangeLayout with clamp',
      (tester) async {
    EdenTemplateLayoutSettings? captured;
    await pumpPanel(
      tester,
      EdenTemplateLayoutPanel(
        value: buildPanelLayoutFixture(),
        onChangeLayout: (s) => captured = s,
      ),
    );
    // Top margin field has initial value '0.75'.
    final topField = find.widgetWithText(TextField, '0.75').first;
    await tester.enterText(topField, '1');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(captured, isNotNull);
    expect(captured!.marginTop, 1.0);
  });

  testWidgets('margin field clamps to max (4.0)', (tester) async {
    EdenTemplateLayoutSettings? captured;
    await pumpPanel(
      tester,
      EdenTemplateLayoutPanel(
        value: buildPanelLayoutFixture(),
        onChangeLayout: (s) => captured = s,
      ),
    );
    final topField = find.widgetWithText(TextField, '0.75').first;
    await tester.enterText(topField, '999');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(captured, isNotNull);
    expect(captured!.marginTop, 4.0);
  });

  testWidgets('checkbox toggle (different first page) fires onChangeLayout',
      (tester) async {
    EdenTemplateLayoutSettings? captured;
    await pumpPanel(
      tester,
      EdenTemplateLayoutPanel(
        value: buildPanelLayoutFixture(),
        onChangeLayout: (s) => captured = s,
      ),
    );
    final checkbox = find.byType(Checkbox).first;
    await tester.tap(checkbox);
    await tester.pump();
    expect(captured, isNotNull);
    expect(captured!.differentFirstPageHeader, isFalse);
  });

  testWidgets('checkbox toggle (page numbers in footer) fires onChangeLayout',
      (tester) async {
    EdenTemplateLayoutSettings? captured;
    await pumpPanel(
      tester,
      EdenTemplateLayoutPanel(
        value: buildPanelLayoutFixture(),
        onChangeLayout: (s) => captured = s,
      ),
    );
    final checkboxes = find.byType(Checkbox);
    await tester.tap(checkboxes.last);
    await tester.pump();
    expect(captured, isNotNull);
    expect(captured!.pageNumbersInFooter, isTrue);
  });

  testWidgets('renders at 240pt without overflow', (tester) async {
    await pumpPanel(
      tester,
      EdenTemplateLayoutPanel(
        value: buildPanelLayoutFixture(),
        onChangeLayout: (_) {},
      ),
      width: 240,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders at 390pt without overflow', (tester) async {
    await pumpPanel(
      tester,
      EdenTemplateLayoutPanel(
        value: buildPanelLayoutFixture(),
        onChangeLayout: (_) {},
      ),
      width: 390,
    );
    expect(tester.takeException(), isNull);
  });
}
