import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: Center(child: child)));
  }

  group('EdenProgress', () {
    testWidgets('renders with 0% value', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenProgress(value: 0.0),
      ));
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('renders with 50% value', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenProgress(value: 0.5),
      ));
      final indicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(indicator.value, closeTo(0.5, 0.01));
    });

    testWidgets('renders with 100% value', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenProgress(value: 1.0),
      ));
      final indicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(indicator.value, closeTo(1.0, 0.01));
    });

    testWidgets('renders label when provided', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenProgress(value: 0.75, label: 'Upload Progress'),
      ));
      expect(find.text('Upload Progress'), findsOneWidget);
    });
  });
}
