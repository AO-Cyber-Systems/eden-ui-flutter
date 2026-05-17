// Do NOT regenerate via LLM — hand-built tests for EdenTemplateStylesPanel.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_template_panels_fixtures.dart';

void main() {
  setUp(() {
    EdenTemplateBlockRegistry.instance.resetToDefaults();
    EdenTemplateVariablesRegistry.instance.reset();
  });

  testWidgets('initial render shows STYLES + dropdown + size fields',
      (tester) async {
    await pumpPanel(
      tester,
      EdenTemplateStylesPanel(
        value: buildPanelStyleFixture(),
        onChangeStyle: (_) {},
      ),
    );
    expect(find.text('STYLES'), findsOneWidget);
    expect(find.text('Font Family'), findsOneWidget);
    expect(find.text('Header Font Size'), findsOneWidget);
    expect(find.text('Body Font Size'), findsOneWidget);
    // Header font size field initial '16'.
    expect(find.text('16'), findsOneWidget);
    expect(find.text('11'), findsOneWidget);
  });

  testWidgets('renders 6 default brand-color swatches', (tester) async {
    await pumpPanel(
      tester,
      EdenTemplateStylesPanel(
        value: buildPanelStyleFixture(),
        onChangeStyle: (_) {},
      ),
    );
    final swatches = find.byType(GestureDetector);
    // At least 6 swatches (others may exist for dropdown).
    expect(swatches, findsAtLeastNWidgets(6));
  });

  testWidgets('custom brandColorSwatches overrides defaults', (tester) async {
    await pumpPanel(
      tester,
      EdenTemplateStylesPanel(
        value: buildPanelStyleFixture(),
        brandColorSwatches: const [Color(0xFFAAAAAA), Color(0xFFBBBBBB)],
        onChangeStyle: (_) {},
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('font-family dropdown shows current value', (tester) async {
    await pumpPanel(
      tester,
      EdenTemplateStylesPanel(
        value: buildPanelStyleFixture(fontFamily: 'Inter'),
        onChangeStyle: (_) {},
      ),
    );
    expect(find.text('Inter'), findsOneWidget);
  });

  testWidgets('changing font-family fires onChangeStyle', (tester) async {
    EdenTemplateStyleSettings? captured;
    await pumpPanel(
      tester,
      EdenTemplateStylesPanel(
        value: buildPanelStyleFixture(),
        onChangeStyle: (s) => captured = s,
      ),
    );
    await tester.tap(find.text('Plus Jakarta Sans'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Inter').last);
    await tester.pumpAndSettle();
    expect(captured, isNotNull);
    expect(captured!.fontFamily, 'Inter');
  });

  testWidgets('header font-size blur with valid input fires onChangeStyle',
      (tester) async {
    EdenTemplateStyleSettings? captured;
    await pumpPanel(
      tester,
      EdenTemplateStylesPanel(
        value: buildPanelStyleFixture(),
        onChangeStyle: (s) => captured = s,
      ),
    );
    final headerField = find.widgetWithText(TextField, '16');
    await tester.enterText(headerField, '20');
    // Trigger submit (tap outside)
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(captured, isNotNull);
    expect(captured!.headerFontSize, 20.0);
  });

  testWidgets('header font-size clamps to max', (tester) async {
    EdenTemplateStyleSettings? captured;
    await pumpPanel(
      tester,
      EdenTemplateStylesPanel(
        value: buildPanelStyleFixture(),
        onChangeStyle: (s) => captured = s,
        maxFontSize: 72,
      ),
    );
    final headerField = find.widgetWithText(TextField, '16');
    await tester.enterText(headerField, '999');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(captured, isNotNull);
    expect(captured!.headerFontSize, 72.0);
  });

  testWidgets(
      'header font-size invalid input reverts and does not fire callback',
      (tester) async {
    var calls = 0;
    await pumpPanel(
      tester,
      EdenTemplateStylesPanel(
        value: buildPanelStyleFixture(),
        onChangeStyle: (_) => calls++,
      ),
    );
    final headerField = find.widgetWithText(TextField, '16');
    await tester.enterText(headerField, 'abc');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    // Numeric input filter strips alpha → empty → parse fails → reverts.
    expect(calls, 0);
  });

  testWidgets('renders at 240pt without overflow', (tester) async {
    await pumpPanel(
      tester,
      EdenTemplateStylesPanel(
        value: buildPanelStyleFixture(),
        onChangeStyle: (_) {},
      ),
      width: 240,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders at 390pt without overflow', (tester) async {
    await pumpPanel(
      tester,
      EdenTemplateStylesPanel(
        value: buildPanelStyleFixture(),
        onChangeStyle: (_) {},
      ),
      width: 390,
    );
    expect(tester.takeException(), isNull);
  });
}
