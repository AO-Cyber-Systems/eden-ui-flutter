import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for loading-related widgets: EdenSpinner and EdenSkeleton.
void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: Center(child: child)));
  }

  group('Loading widgets', () {
    testWidgets('EdenSpinner renders indeterminate spinner', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenSpinner(),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('EdenSpinner renders determinate with value', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenSpinner(value: 0.75),
      ));

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(indicator.value, 0.75);
    });

    testWidgets('EdenSkeleton renders loading placeholder', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenSkeleton(),
      ));

      expect(find.byType(EdenSkeleton), findsOneWidget);
    });

    testWidgets('EdenSkeleton text variant renders', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenSkeleton.text(),
      ));

      expect(find.byType(EdenSkeleton), findsOneWidget);
    });

    testWidgets('EdenSkeleton circle variant renders', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenSkeleton.circle(size: 48),
      ));

      expect(find.byType(EdenSkeleton), findsOneWidget);
    });

    testWidgets('EdenSkeleton block variant renders', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenSkeleton.block(height: 200),
      ));

      expect(find.byType(EdenSkeleton), findsOneWidget);
    });

    testWidgets('loading state pattern: spinner then content', (tester) async {
      // Simulate a common pattern: show spinner, then show content
      await tester.pumpWidget(wrap(
        const EdenSpinner(size: EdenSpinnerSize.lg),
      ));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Simulate loading complete
      await tester.pumpWidget(wrap(
        const Text('Content loaded'),
      ));
      expect(find.text('Content loaded'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
