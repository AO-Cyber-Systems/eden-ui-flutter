// Do NOT regenerate via LLM — hand-built tests for EdenTemplateVariablesPanel.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_template_panels_fixtures.dart';

void main() {
  setUp(() {
    EdenTemplateBlockRegistry.instance.resetToDefaults();
    EdenTemplateVariablesRegistry.instance.reset();
  });

  testWidgets('renders registered group names and field tokens',
      (tester) async {
    registerVariablesFixture();
    await pumpPanel(
      tester,
      EdenTemplateVariablesPanel(onInsertField: (_) {}),
    );
    expect(find.text('customer'), findsOneWidget);
    expect(find.text('company'), findsOneWidget);
    expect(find.text('{{customer.name}}'), findsOneWidget);
    expect(find.text('{{customer.email}}'), findsOneWidget);
    expect(find.text('{{company.phone}}'), findsOneWidget);
  });

  testWidgets('empty registry renders default placeholder', (tester) async {
    await pumpPanel(
      tester,
      EdenTemplateVariablesPanel(onInsertField: (_) {}),
    );
    expect(find.text('No variable groups registered'), findsOneWidget);
  });

  testWidgets('empty registry honours custom placeholder', (tester) async {
    await pumpPanel(
      tester,
      EdenTemplateVariablesPanel(
        onInsertField: (_) {},
        emptyPlaceholder: const Text('custom-empty'),
      ),
    );
    expect(find.text('custom-empty'), findsOneWidget);
    expect(find.text('No variable groups registered'), findsNothing);
  });

  testWidgets('tap fires onInsertField with full token', (tester) async {
    registerVariablesFixture();
    String? captured;
    await pumpPanel(
      tester,
      EdenTemplateVariablesPanel(onInsertField: (t) => captured = t),
    );
    await tester.tap(find.text('{{customer.email}}'));
    await tester.pump();
    expect(captured, '{{customer.email}}');
  });

  testWidgets('search narrows fields and hides empty groups', (tester) async {
    registerVariablesFixture();
    await pumpPanel(
      tester,
      EdenTemplateVariablesPanel(onInsertField: (_) {}),
    );
    await tester.enterText(find.byType(TextField), 'email');
    await tester.pump();
    expect(find.text('{{customer.email}}'), findsOneWidget);
    expect(find.text('{{customer.name}}'), findsNothing);
    expect(find.text('company'), findsNothing);
  });

  testWidgets('search with no match shows "No matching fields"',
      (tester) async {
    registerVariablesFixture();
    await pumpPanel(
      tester,
      EdenTemplateVariablesPanel(onInsertField: (_) {}),
    );
    await tester.enterText(find.byType(TextField), 'zzzzz');
    await tester.pump();
    expect(find.text('No matching fields'), findsOneWidget);
  });

  testWidgets('renders at 240pt without overflow', (tester) async {
    registerVariablesFixture();
    await pumpPanel(
      tester,
      EdenTemplateVariablesPanel(onInsertField: (_) {}),
      width: 240,
    );
    expect(tester.takeException(), isNull);
    expect(find.text('customer'), findsOneWidget);
  });

  testWidgets('renders at 390pt (iPhone-narrow) without overflow',
      (tester) async {
    registerVariablesFixture();
    await pumpPanel(
      tester,
      EdenTemplateVariablesPanel(onInsertField: (_) {}),
      width: 390,
    );
    expect(tester.takeException(), isNull);
    expect(find.text('customer'), findsOneWidget);
  });
}
