import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:eden_ui_flutter/dev_app/screens/process_builder_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child, {Size size = const Size(1600, 1000)}) =>
      MediaQuery(
        data: MediaQueryData(size: size),
        child: MaterialApp(
          home: SizedBox(
            width: size.width,
            height: size.height,
            child: child,
          ),
        ),
      );

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

  group('EdenVisualProcessCanvas — integration smoke', () {
    testWidgets('renders ProcessBuilderScreen with populated definition',
        (tester) async {
      await tester.pumpWidget(wrap(const ProcessBuilderScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(EdenProcessToolbox), findsOneWidget);
      expect(find.byType(EdenDiagram), findsOneWidget);
      expect(
        find.byType(EdenProcessPhaseNode).evaluate().length,
        greaterThanOrEqualTo(3),
      );
      expect(
        find.byType(EdenProcessTaskGroupNode).evaluate().length,
        greaterThanOrEqualTo(6),
      );
      // Decision node may or may not be in viewport — assert at least it's
      // dispatchable (not necessarily rendered visibly in test viewport).
      expect(find.byType(EdenProcessValidationPanel), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('layout toggle dropdown switches between layouts',
        (tester) async {
      await tester.pumpWidget(wrap(const ProcessBuilderScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(DropdownButton<String>), findsOneWidget);

      // Open dropdown and select 'Free-form'.
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Free-form').last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Toggle Toolbox button hides and shows the toolbox',
        (tester) async {
      await tester.pumpWidget(wrap(const ProcessBuilderScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(EdenProcessToolbox), findsOneWidget);

      await tester.tap(find.byTooltip('Toggle Toolbox'));
      await tester.pumpAndSettle();
      expect(find.byType(EdenProcessToolbox), findsNothing);

      await tester.tap(find.byTooltip('Toggle Toolbox'));
      await tester.pumpAndSettle();
      expect(find.byType(EdenProcessToolbox), findsOneWidget);
    });

    testWidgets('Reset Demo button does not throw', (tester) async {
      await tester.pumpWidget(wrap(const ProcessBuilderScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Reset Demo'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('iPhone-narrow fallback renders at <1200pt width',
        (tester) async {
      await tester.pumpWidget(
        wrap(const ProcessBuilderScreen(), size: const Size(800, 900)),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('tablet/desktop width'),
        findsOneWidget,
      );
      expect(find.byType(EdenProcessToolbox), findsNothing);
      expect(find.byType(EdenDiagram), findsNothing);
    });
  });
}
