// Do NOT regenerate via LLM — hand-built tests for EdenTemplateBlockPalette.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_template_palette_fixtures.dart';

Future<void> pumpTall(
  WidgetTester tester,
  Widget child,
) async {
  await tester.binding.setSurfaceSize(const Size(1200, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  setUp(() {
    EdenTemplateBlockRegistry.instance.resetToDefaults();
    EdenTemplateVariablesRegistry.instance.reset();
  });

  group('EdenTemplateBlockPalette — default registry rendering', () {
    testWidgets('renders both CONTENT and ADVANCED section headers',
        (tester) async {
      await pumpTall(
        tester,
        SizedBox(
          width: 600,
          child: EdenTemplateBlockPalette(onAddBlock: (_) {}),
        ),
      );
      expect(find.text('CONTENT'), findsOneWidget);
      expect(find.text('ADVANCED'), findsOneWidget);
    });

    testWidgets('renders 10 Content cards and 2 Advanced cards',
        (tester) async {
      await pumpTall(
        tester,
        SizedBox(
          width: 600,
          child: EdenTemplateBlockPalette(onAddBlock: (_) {}),
        ),
      );
      expect(find.text('Text'), findsOneWidget);
      expect(find.text('Field'), findsOneWidget);
      expect(find.text('Table'), findsOneWidget);
      expect(find.text('Image'), findsOneWidget);
      expect(find.text('Conditional'), findsOneWidget);
      expect(find.text('Repeater'), findsOneWidget);
    });
  });

  group('EdenTemplateBlockPalette — explicit category order', () {
    testWidgets('categories: [Content, Advanced] renders Content header first',
        (tester) async {
      await pumpTall(
        tester,
        SizedBox(
          width: 600,
          child: EdenTemplateBlockPalette(
            categories: const ['Content', 'Advanced'],
            onAddBlock: (_) {},
          ),
        ),
      );
      final contentY = tester.getTopLeft(find.text('CONTENT')).dy;
      final advancedY = tester.getTopLeft(find.text('ADVANCED')).dy;
      expect(contentY, lessThan(advancedY));
    });

    testWidgets('categories: [Content] renders ONLY Content section',
        (tester) async {
      await pumpTall(
        tester,
        SizedBox(
          width: 600,
          child: EdenTemplateBlockPalette(
            categories: const ['Content'],
            onAddBlock: (_) {},
          ),
        ),
      );
      expect(find.text('CONTENT'), findsOneWidget);
      expect(find.text('ADVANCED'), findsNothing);
      expect(find.text('Conditional'), findsNothing);
      expect(find.text('Text'), findsOneWidget);
    });
  });

  group('EdenTemplateBlockPalette — empty registry', () {
    testWidgets('renders default empty placeholder', (tester) async {
      EdenTemplateBlockRegistry.instance.reset();
      await pumpTall(
        tester,
        SizedBox(
          width: 600,
          child: EdenTemplateBlockPalette(onAddBlock: (_) {}),
        ),
      );
      expect(find.text('No block types registered'), findsOneWidget);
      expect(
        find.textContaining('resetToDefaults'),
        findsOneWidget,
      );
    });

    testWidgets('emptyPlaceholder override is honoured', (tester) async {
      EdenTemplateBlockRegistry.instance.reset();
      await pumpTall(
        tester,
        SizedBox(
          width: 600,
          child: EdenTemplateBlockPalette(
            emptyPlaceholder: const Text('Custom empty'),
            onAddBlock: (_) {},
          ),
        ),
      );
      expect(find.text('Custom empty'), findsOneWidget);
      expect(find.text('No block types registered'), findsNothing);
    });
  });

  group('EdenTemplateBlockPalette — consumer-registered category', () {
    testWidgets('register adds a new section / card', (tester) async {
      EdenTemplateBlockRegistry.instance.register(
        buildPaletteFixture(
          id: 'payment_line',
          displayName: 'Payment Line',
          description: 'Receipt payment row',
          icon: Icons.attach_money,
          category: 'Commerce',
        ),
      );
      await pumpTall(
        tester,
        SizedBox(
          width: 600,
          child: EdenTemplateBlockPalette(
            categories: const ['Content', 'Advanced', 'Commerce'],
            onAddBlock: (_) {},
          ),
        ),
      );
      expect(find.text('COMMERCE'), findsOneWidget);
      expect(find.text('Payment Line'), findsOneWidget);
    });
  });

  group('EdenTemplateBlockPalette — click-to-add', () {
    testWidgets('tap on Text card fires onAddBlock with id=text',
        (tester) async {
      EdenTemplateBlockDescriptor? captured;
      await pumpTall(
        tester,
        SizedBox(
          width: 600,
          child: EdenTemplateBlockPalette(onAddBlock: (d) => captured = d),
        ),
      );
      await tester.tap(find.text('Text'));
      await tester.pump();
      expect(captured, isNotNull);
      expect(captured!.id, 'text');
    });

    testWidgets('tap on Image card fires onAddBlock with id=image',
        (tester) async {
      EdenTemplateBlockDescriptor? captured;
      await pumpTall(
        tester,
        SizedBox(
          width: 600,
          child: EdenTemplateBlockPalette(onAddBlock: (d) => captured = d),
        ),
      );
      await tester.tap(find.text('Image'));
      await tester.pump();
      expect(captured, isNotNull);
      expect(captured!.id, 'image');
    });
  });

  group('EdenTemplateBlockPalette — narrow rendering safety', () {
    testWidgets('renders at 240pt without overflow', (tester) async {
      await pumpTall(
        tester,
        SizedBox(
          width: 240,
          child: EdenTemplateBlockPalette(onAddBlock: (_) {}),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Text'), findsOneWidget);
    });

    testWidgets('renders at 390pt (iPhone-narrow) without overflow',
        (tester) async {
      await pumpTall(
        tester,
        SizedBox(
          width: 390,
          child: EdenTemplateBlockPalette(onAddBlock: (_) {}),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Text'), findsOneWidget);
    });
  });

  group('EdenTemplateBlockPalette — consumer card override', () {
    testWidgets('cardBuilder renders custom widget per descriptor',
        (tester) async {
      await pumpTall(
        tester,
        SizedBox(
          width: 600,
          child: EdenTemplateBlockPalette(
            cardBuilder: (ctx, d) => Text('Override-${d.id}'),
            onAddBlock: (_) {},
          ),
        ),
      );
      expect(find.text('Override-text'), findsOneWidget);
      expect(find.text('Override-image'), findsOneWidget);
      expect(find.text('Override-conditional'), findsOneWidget);
    });
  });

  group('EdenTemplateBlockPalette — drag source', () {
    testWidgets('each card is a Draggable<EdenTemplateBlockDescriptor>',
        (tester) async {
      await pumpTall(
        tester,
        SizedBox(
          width: 600,
          child: EdenTemplateBlockPalette(onAddBlock: (_) {}),
        ),
      );
      final draggables = find.byType(Draggable<EdenTemplateBlockDescriptor>);
      // 12 cards by default.
      expect(draggables, findsNWidgets(12));
    });
  });
}
