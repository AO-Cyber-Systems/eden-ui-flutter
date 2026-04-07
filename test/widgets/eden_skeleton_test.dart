import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: Center(child: child)));
  }

  group('EdenSkeleton', () {
    testWidgets('renders default skeleton', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenSkeleton(),
      ));

      expect(find.byType(EdenSkeleton), findsOneWidget);
    });

    testWidgets('renders text skeleton', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenSkeleton.text(),
      ));

      expect(find.byType(EdenSkeleton), findsOneWidget);
    });

    testWidgets('renders circle skeleton', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenSkeleton.circle(),
      ));

      expect(find.byType(EdenSkeleton), findsOneWidget);
    });

    testWidgets('renders block skeleton', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenSkeleton.block(),
      ));

      expect(find.byType(EdenSkeleton), findsOneWidget);
    });

    testWidgets('renders with custom dimensions', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenSkeleton(width: 200, height: 50),
      ));

      expect(find.byType(EdenSkeleton), findsOneWidget);
    });

    testWidgets('animates (has AnimationController)', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenSkeleton(),
      ));

      // Pump a few frames to verify animation doesn't crash
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(EdenSkeleton), findsOneWidget);
    });

    testWidgets('multiple skeletons render together', (tester) async {
      await tester.pumpWidget(wrap(
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EdenSkeleton.text(),
            SizedBox(height: 8),
            EdenSkeleton.text(),
            SizedBox(height: 8),
            EdenSkeleton.circle(size: 40),
          ],
        ),
      ));

      expect(find.byType(EdenSkeleton), findsNWidgets(3));
    });

    testWidgets('renders in dark theme without error', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(),
        home: const Scaffold(
          body: Center(child: EdenSkeleton()),
        ),
      ));

      expect(find.byType(EdenSkeleton), findsOneWidget);
    });
  });
}
