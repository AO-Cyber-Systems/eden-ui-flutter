// Do NOT regenerate via LLM — hand-built tests for EdenTemplateBlockPlaceholder.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  setUp(() {
    EdenTemplateBlockRegistry.instance.resetToDefaults();
    EdenTemplateVariablesRegistry.instance.reset();
  });

  testWidgets('renders icon + label + subtext + drag handle', (tester) async {
    const block = EdenTemplateBlock(
      id: 'b1',
      type: 'text',
      content: {'label': 'Hello world'},
      order: 0,
      section: EdenTemplateSection.body,
    );
    const desc = EdenTemplateBlockDescriptor(
      id: 'text',
      displayName: 'Text',
      description: 'Static text',
      icon: Icons.text_fields,
      category: 'Content',
    );
    await tester.pumpWidget(
      wrap(EdenTemplateBlockPlaceholder(block: block, descriptor: desc)),
    );
    expect(find.byIcon(Icons.text_fields), findsOneWidget);
    expect(find.byIcon(Icons.drag_indicator), findsOneWidget);
    expect(find.text('Hello world'), findsOneWidget);
    expect(find.textContaining('Text'), findsWidgets);
  });

  testWidgets(
      'label falls back to content[text] when label absent', (tester) async {
    const block = EdenTemplateBlock(
      id: 'b1',
      type: 'text',
      content: {'text': 'From text field'},
      order: 0,
      section: EdenTemplateSection.body,
    );
    const desc = EdenTemplateBlockDescriptor(
      id: 'text',
      displayName: 'Text',
      description: 'Static text',
      icon: Icons.text_fields,
      category: 'Content',
    );
    await tester.pumpWidget(
      wrap(EdenTemplateBlockPlaceholder(block: block, descriptor: desc)),
    );
    expect(find.text('From text field'), findsOneWidget);
  });

  testWidgets(
      'label falls back to descriptor displayName when both absent',
      (tester) async {
    const block = EdenTemplateBlock(
      id: 'b1',
      type: 'spacer',
      content: {},
      order: 0,
      section: EdenTemplateSection.body,
    );
    const desc = EdenTemplateBlockDescriptor(
      id: 'spacer',
      displayName: 'Spacer',
      description: 'Vertical whitespace',
      icon: Icons.expand,
      category: 'Content',
    );
    await tester.pumpWidget(
      wrap(EdenTemplateBlockPlaceholder(block: block, descriptor: desc)),
    );
    expect(find.text('Spacer'), findsWidgets);
  });

  testWidgets('onEdit fires when body tapped', (tester) async {
    var calls = 0;
    const block = EdenTemplateBlock(
      id: 'b1',
      type: 'text',
      content: {'label': 'A'},
      order: 0,
      section: EdenTemplateSection.body,
    );
    const desc = EdenTemplateBlockDescriptor(
      id: 'text',
      displayName: 'Text',
      description: 'Static text',
      icon: Icons.text_fields,
      category: 'Content',
    );
    await tester.pumpWidget(
      wrap(
        EdenTemplateBlockPlaceholder(
          block: block,
          descriptor: desc,
          onEdit: () => calls++,
        ),
      ),
    );
    await tester.tap(find.text('A'));
    await tester.pump();
    expect(calls, 1);
  });

  testWidgets('onDelete affordance is hidden when callback null',
      (tester) async {
    const block = EdenTemplateBlock(
      id: 'b1',
      type: 'text',
      content: {'label': 'A'},
      order: 0,
      section: EdenTemplateSection.body,
    );
    const desc = EdenTemplateBlockDescriptor(
      id: 'text',
      displayName: 'Text',
      description: 'Static text',
      icon: Icons.text_fields,
      category: 'Content',
    );
    await tester.pumpWidget(
      wrap(EdenTemplateBlockPlaceholder(block: block, descriptor: desc)),
    );
    expect(find.byIcon(Icons.close), findsNothing);
  });

  testWidgets('onDelete fires when delete icon tapped', (tester) async {
    var calls = 0;
    const block = EdenTemplateBlock(
      id: 'b1',
      type: 'text',
      content: {'label': 'A'},
      order: 0,
      section: EdenTemplateSection.body,
    );
    const desc = EdenTemplateBlockDescriptor(
      id: 'text',
      displayName: 'Text',
      description: 'Static text',
      icon: Icons.text_fields,
      category: 'Content',
    );
    await tester.pumpWidget(
      wrap(
        EdenTemplateBlockPlaceholder(
          block: block,
          descriptor: desc,
          onDelete: () => calls++,
        ),
      ),
    );
    expect(find.byIcon(Icons.close), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    expect(calls, 1);
  });

  testWidgets('showDragHandle: false hides the drag handle', (tester) async {
    const block = EdenTemplateBlock(
      id: 'b1',
      type: 'text',
      content: {'label': 'A'},
      order: 0,
      section: EdenTemplateSection.body,
    );
    const desc = EdenTemplateBlockDescriptor(
      id: 'text',
      displayName: 'Text',
      description: 'Static text',
      icon: Icons.text_fields,
      category: 'Content',
    );
    await tester.pumpWidget(
      wrap(
        EdenTemplateBlockPlaceholder(
          block: block,
          descriptor: desc,
          showDragHandle: false,
        ),
      ),
    );
    expect(find.byIcon(Icons.drag_indicator), findsNothing);
  });

  group('Layout engine sealed-ish base', () {
    test('vertical-stack is const + equal', () {
      const a = EdenTemplateVerticalStackLayout();
      const b = EdenTemplateVerticalStackLayout();
      expect(a, b);
      expect(a, isA<EdenTemplateLayoutEngine>());
    });

    test('freeform is const + equal', () {
      const a = EdenTemplateFreeformLayout();
      const b = EdenTemplateFreeformLayout();
      expect(a, b);
      expect(a, isA<EdenTemplateLayoutEngine>());
    });

    test('vertical-stack != freeform', () {
      const v = EdenTemplateVerticalStackLayout();
      const f = EdenTemplateFreeformLayout();
      expect(v == f, isFalse);
    });
  });
}
