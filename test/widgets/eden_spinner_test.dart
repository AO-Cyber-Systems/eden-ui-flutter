import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: Center(child: child)));
  }

  group('EdenSpinner', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenSpinner(),
      ));

      expect(find.byType(EdenSpinner), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders all sizes without error', (tester) async {
      for (final size in EdenSpinnerSize.values) {
        await tester.pumpWidget(wrap(
          EdenSpinner(size: size),
        ));
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      }
    });

    testWidgets('renders with custom color', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenSpinner(color: Colors.red),
      ));

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(indicator.color, Colors.red);
    });

    testWidgets('renders indeterminate by default', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenSpinner(),
      ));

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(indicator.value, isNull);
    });

    testWidgets('renders determinate when value provided', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenSpinner(value: 0.5),
      ));

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(indicator.value, 0.5);
    });

    testWidgets('sm size is 16px', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenSpinner(size: EdenSpinnerSize.sm),
      ));

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, 16);
      expect(sizedBox.height, 16);
    });

    testWidgets('md size is 24px', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenSpinner(size: EdenSpinnerSize.md),
      ));

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, 24);
      expect(sizedBox.height, 24);
    });

    testWidgets('lg size is 36px', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenSpinner(size: EdenSpinnerSize.lg),
      ));

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, 36);
      expect(sizedBox.height, 36);
    });
  });
}
