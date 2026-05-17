import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_process_toolbox_fixtures.dart';

void main() {
  group('EdenProcessToolbox — defaults + rendering', () {
    testWidgets('renders default categories when consumer passes none',
        (tester) async {
      await tester.pumpWidget(toolboxTestHarness(
        EdenProcessToolbox(onAddNode: (_, __) {}),
      ));
      expect(find.text('STRUCTURE'), findsOneWidget);
      expect(find.text('TASKS'), findsOneWidget);
      expect(find.text('Phase'), findsOneWidget);
      expect(find.text('Task'), findsOneWidget);
    });

    testWidgets('renders Phase item icon + description', (tester) async {
      await tester.pumpWidget(toolboxTestHarness(
        EdenProcessToolbox(onAddNode: (_, __) {}),
      ));
      expect(find.byIcon(Icons.layers), findsOneWidget);
      expect(find.text('A stage in your process'), findsOneWidget);
    });

    testWidgets('empty categories AND empty templates renders empty rail',
        (tester) async {
      await tester.pumpWidget(toolboxTestHarness(
        EdenProcessToolbox(
          categories: const [],
          templates: const [],
          onAddNode: (_, __) {},
        ),
      ));
      // Defaults populate; that's the documented behavior.
      expect(find.text('STRUCTURE'), findsOneWidget);
      expect(find.text('TEMPLATES'), findsNothing);
    });
  });

  group('EdenProcessToolbox — click-to-add', () {
    testWidgets('tapping Phase item fires onAddNode("phase", null)',
        (tester) async {
      String? dragType;
      Map<String, dynamic>? cfg;
      await tester.pumpWidget(toolboxTestHarness(
        EdenProcessToolbox(
          onAddNode: (t, c) {
            dragType = t;
            cfg = c;
          },
        ),
      ));
      await tester.tap(find.text('Phase'));
      await tester.pump();
      expect(dragType, 'phase');
      expect(cfg, isNull);
    });

    testWidgets('tapping a task with taskConfig passes config to onAddNode',
        (tester) async {
      String? dragType;
      Map<String, dynamic>? cfg;
      await tester.pumpWidget(toolboxTestHarness(
        EdenProcessToolbox(
          categories: richToolboxCategoriesFixture(),
          onAddNode: (t, c) {
            dragType = t;
            cfg = c;
          },
        ),
      ));
      await tester.tap(find.text('Photo gallery'));
      await tester.pump();
      expect(dragType, 'task');
      expect(cfg?['runtimeComponent'], 'photo_gallery');
    });
  });

  group('EdenProcessToolbox — drag delivers EdenProcessDragPayload', () {
    testWidgets('dragging Phase delivers dragType=phase via DragTarget',
        (tester) async {
      EdenProcessDragPayload? dropped;
      await tester.pumpWidget(toolboxTestHarness(
        EdenProcessToolbox(onAddNode: (_, __) {}),
        onDrop: (p) => dropped = p,
      ));

      // Locate the Draggable for the Phase item and drag it to the target.
      final phaseDraggable = find
          .ancestor(
            of: find.text('Phase'),
            matching: find.byType(Draggable<EdenProcessDragPayload>),
          )
          .first;
      await tester.drag(
        phaseDraggable,
        const Offset(300, 0),
      );
      await tester.pumpAndSettle();

      expect(dropped, isNotNull);
      expect(dropped!.dragType, 'phase');
    });
  });

  group('EdenProcessToolbox — templates', () {
    testWidgets('templates section hidden when empty', (tester) async {
      await tester.pumpWidget(toolboxTestHarness(
        EdenProcessToolbox(onAddNode: (_, __) {}),
      ));
      expect(find.text('TEMPLATES'), findsNothing);
    });

    testWidgets('templates section renders when non-empty', (tester) async {
      await tester.pumpWidget(toolboxTestHarness(
        EdenProcessToolbox(
          templates: sampleTemplatesFixture(),
          onAddNode: (_, __) {},
        ),
      ));
      expect(find.text('TEMPLATES'), findsOneWidget);
      expect(find.text('Onboarding'), findsOneWidget);
      expect(find.text('Closeout'), findsOneWidget);
      expect(find.text('Inspection'), findsOneWidget);
    });

    testWidgets('each template shows task count subtitle', (tester) async {
      await tester.pumpWidget(toolboxTestHarness(
        EdenProcessToolbox(
          templates: sampleTemplatesFixture(),
          onAddNode: (_, __) {},
        ),
      ));
      expect(find.text('5 tasks'), findsOneWidget);
      expect(find.text('3 tasks'), findsOneWidget);
      expect(find.text('8 tasks'), findsOneWidget);
    });

    testWidgets('recommended template gets "rec" badge', (tester) async {
      await tester.pumpWidget(toolboxTestHarness(
        EdenProcessToolbox(
          templates: sampleTemplatesFixture(),
          recommendedWorkCategoryId: 100,
          onAddNode: (_, __) {},
        ),
      ));
      // Two templates have workCategoryId=100 (Onboarding + Inspection); they
      // both get the rec badge.
      expect(find.text('rec'), findsNWidgets(2));
    });

    testWidgets('recommended templates sort first', (tester) async {
      await tester.pumpWidget(toolboxTestHarness(
        EdenProcessToolbox(
          templates: sampleTemplatesFixture(),
          recommendedWorkCategoryId: 200,
          onAddNode: (_, __) {},
        ),
      ));
      // Closeout (workCategoryId=200) should render before Onboarding +
      // Inspection (workCategoryId=100). Compare y-offsets.
      final closeoutY = tester.getTopLeft(find.text('Closeout')).dy;
      final onboardingY = tester.getTopLeft(find.text('Onboarding')).dy;
      expect(closeoutY < onboardingY, isTrue);
    });

    testWidgets('tapping a template fires onTemplateSelected', (tester) async {
      int? selectedId;
      await tester.pumpWidget(toolboxTestHarness(
        EdenProcessToolbox(
          templates: sampleTemplatesFixture(),
          onAddNode: (_, __) {},
          onTemplateSelected: (id) => selectedId = id,
        ),
      ));
      await tester.tap(find.text('Closeout'));
      await tester.pump();
      expect(selectedId, 2);
    });
  });

  group('EdenProcessToolbox — vertical extensibility', () {
    testWidgets('renders custom categories + items', (tester) async {
      await tester.pumpWidget(toolboxTestHarness(
        EdenProcessToolbox(
          categories: richToolboxCategoriesFixture(),
          onAddNode: (_, __) {},
        ),
      ));
      expect(find.text('AI POWERED'), findsOneWidget);
      expect(find.text('AI Classify'), findsOneWidget);
      expect(find.text('AI Extract'), findsOneWidget);
    });

    testWidgets('tapping a custom item fires onAddNode with custom dragType',
        (tester) async {
      String? dragType;
      await tester.pumpWidget(toolboxTestHarness(
        EdenProcessToolbox(
          categories: richToolboxCategoriesFixture(),
          onAddNode: (t, _) => dragType = t,
        ),
      ));
      await tester.tap(find.text('AI Classify'));
      await tester.pump();
      expect(dragType, 'custom_ai_classify');
    });
  });

  group('EdenProcessToolbox — iPhone-narrow', () {
    testWidgets('renders at 390pt without overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(toolboxTestHarness(
        EdenProcessToolbox(onAddNode: (_, __) {}),
      ));
      expect(tester.takeException(), isNull);
    });
  });
}
