import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: Center(child: child)));
  }

  group('EdenQuickDateRange', () {
    testWidgets('renders selected option label (7d)', (tester) async {
      await tester.pumpWidget(wrap(
        EdenQuickDateRange(
          selectedRange: '7d',
          onChanged: (_) {},
        ),
      ));
      expect(find.text('Last 7 days'), findsOneWidget);
    });

    testWidgets('renders selected option label (mtd)', (tester) async {
      await tester.pumpWidget(wrap(
        EdenQuickDateRange(
          selectedRange: 'mtd',
          onChanged: (_) {},
        ),
      ));
      expect(find.text('Month to date'), findsOneWidget);
    });

    testWidgets('renders for each preset value without error',
        (tester) async {
      const presets = ['7d', '30d', '90d', 'mtd', 'ytd'];
      for (final p in presets) {
        await tester.pumpWidget(wrap(
          EdenQuickDateRange(
            selectedRange: p,
            onChanged: (_) {},
          ),
        ));
        await tester.pump();
      }
    });
  });
}
