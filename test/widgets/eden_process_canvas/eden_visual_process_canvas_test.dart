import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_process_canvas_fixtures.dart';

void main() {
  Widget wrap(Widget child, {Size size = const Size(1600, 1000)}) =>
      MediaQuery(
        data: MediaQueryData(size: size),
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: size.width,
              height: size.height,
              child: child,
            ),
          ),
        ),
      );

  setUpAll(() {
    // Ensure the test viewport defaults to a wide-mode size.
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    final binding = TestWidgetsFlutterBinding.instance;
    binding.platformDispatcher.views.first.physicalSize =
        const Size(1600, 1000);
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
  });

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.instance;
    binding.platformDispatcher.views.first.resetPhysicalSize();
    binding.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  group('EdenVisualProcessCanvas — basic rendering', () {
    testWidgets('renders Toolbox + EdenDiagram + Toolbar', (tester) async {
      await tester.pumpWidget(wrap(EdenVisualProcessCanvas(
        definition: populatedDefinitionFixture(),
      )));
      await tester.pumpAndSettle();
      expect(find.byType(EdenProcessToolbox), findsOneWidget);
      expect(find.byType(EdenDiagram), findsOneWidget);
      expect(find.text('Populated Process'), findsOneWidget);
    });

    testWidgets('hideToolbox=true → toolbox hidden', (tester) async {
      await tester.pumpWidget(wrap(EdenVisualProcessCanvas(
        definition: populatedDefinitionFixture(),
        hideToolbox: true,
      )));
      await tester.pumpAndSettle();
      expect(find.byType(EdenProcessToolbox), findsNothing);
      expect(find.byType(EdenDiagram), findsOneWidget);
    });

    testWidgets('Auto-layout button visible in toolbar', (tester) async {
      await tester.pumpWidget(wrap(EdenVisualProcessCanvas(
        definition: populatedDefinitionFixture(),
      )));
      expect(
        find.byKey(const ValueKey('canvas-auto-layout-button')),
        findsOneWidget,
      );
    });

    testWidgets('Save button visible', (tester) async {
      await tester.pumpWidget(wrap(EdenVisualProcessCanvas(
        definition: populatedDefinitionFixture(),
      )));
      expect(
        find.byKey(const ValueKey('canvas-save-button')),
        findsOneWidget,
      );
    });

    testWidgets('Publish button visible when not published', (tester) async {
      await tester.pumpWidget(wrap(EdenVisualProcessCanvas(
        definition: populatedDefinitionFixture(),
        onPublish: () {},
      )));
      expect(
        find.byKey(const ValueKey('canvas-publish-button')),
        findsOneWidget,
      );
    });

    testWidgets('Publish button hidden when published + no unpublished changes',
        (tester) async {
      await tester.pumpWidget(wrap(EdenVisualProcessCanvas(
        definition: publishedDefinitionFixture(),
        onPublish: () {},
      )));
      expect(
        find.byKey(const ValueKey('canvas-publish-button')),
        findsNothing,
      );
    });
  });

  group('EdenVisualProcessCanvas — toolbar actions', () {
    testWidgets('Save button fires onSaveLayout with EdenProcessLayoutData',
        (tester) async {
      EdenProcessLayoutData? saved;
      await tester.pumpWidget(wrap(EdenVisualProcessCanvas(
        definition: populatedDefinitionFixture(),
        onSaveLayout: (d) => saved = d,
      )));
      await tester.tap(find.byKey(const ValueKey('canvas-save-button')));
      await tester.pump();
      expect(saved, isNotNull);
    });

    testWidgets('Publish button fires onPublish', (tester) async {
      bool published = false;
      await tester.pumpWidget(wrap(EdenVisualProcessCanvas(
        definition: populatedDefinitionFixture(),
        onPublish: () => published = true,
      )));
      await tester.tap(find.byKey(const ValueKey('canvas-publish-button')));
      await tester.pump();
      expect(published, isTrue);
    });
  });

  group('EdenVisualProcessCanvas — narrow fallback', () {
    testWidgets('width < 1200 renders fallback (no canvas)', (tester) async {
      await tester.pumpWidget(wrap(
        EdenVisualProcessCanvas(
          definition: populatedDefinitionFixture(),
        ),
        size: const Size(800, 1000),
      ));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('canvas-narrow-fallback')),
        findsOneWidget,
      );
      expect(find.byType(EdenDiagram), findsNothing);
      expect(find.byType(EdenProcessToolbox), findsNothing);
      expect(
        find.textContaining('Process builder requires tablet/desktop width'),
        findsOneWidget,
      );
    });

    testWidgets('narrow fallback shows each phase + group counts',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenVisualProcessCanvas(
          definition: populatedDefinitionFixture(),
        ),
        size: const Size(800, 1000),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Phase 1'), findsOneWidget);
      expect(find.text('Phase 2'), findsOneWidget);
      expect(find.text('Phase 3'), findsOneWidget);
      expect(find.text('Group 1.1 — 3 tasks'), findsOneWidget);
    });
  });

  group('EdenVisualProcessCanvas — validation panel', () {
    testWidgets('validation chip is rendered in the toolbar',
        (tester) async {
      await tester.pumpWidget(wrap(EdenVisualProcessCanvas(
        definition: populatedDefinitionFixture(),
      )));
      // The populated definition has a disconnected decision (graph builder
      // does NOT auto-connect decisions) → expect a validation chip
      // referencing the disconnected/missing-branches state.
      expect(find.byType(EdenProcessValidationPanel), findsOneWidget);
    });

    testWidgets('empty definition shows errors in chip', (tester) async {
      await tester.pumpWidget(wrap(EdenVisualProcessCanvas(
        definition: emptyDefinitionFixture(),
      )));
      expect(find.text('1 error'), findsOneWidget);
    });
  });

  group('EdenVisualProcessCanvas — controller lifecycle', () {
    testWidgets('disposes owned controller on widget unmount',
        (tester) async {
      await tester.pumpWidget(wrap(EdenVisualProcessCanvas(
        definition: populatedDefinitionFixture(),
      )));
      // Replace with empty widget — should dispose without exception.
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    });

    testWidgets('does NOT dispose consumer-provided controller',
        (tester) async {
      final consumerController = EdenProcessController();
      addTearDown(consumerController.dispose);
      await tester.pumpWidget(wrap(EdenVisualProcessCanvas(
        definition: populatedDefinitionFixture(),
        controller: consumerController,
      )));
      // Unmount; consumer controller must still be usable.
      await tester.pumpWidget(const SizedBox());
      // If the canvas had disposed it, the addTearDown dispose would throw.
      // Trigger a tear-down equivalent check: notify listeners should work.
      consumerController.togglePhaseExpanded(1);
      expect(tester.takeException(), isNull);
    });
  });
}
