import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: Center(child: child)));
  }

  group('EdenBadge', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenBadge(label: 'New'),
      ));
      expect(find.text('New'), findsOneWidget);
    });

    testWidgets('renders with each variant without error', (tester) async {
      for (final variant in EdenBadgeVariant.values) {
        await tester.pumpWidget(wrap(
          EdenBadge(label: 'Badge', variant: variant),
        ));
        expect(find.text('Badge'), findsOneWidget);
      }
    });

    testWidgets('renders with each size without error', (tester) async {
      for (final size in EdenBadgeSize.values) {
        await tester.pumpWidget(wrap(
          EdenBadge(label: 'Sized', size: size),
        ));
        expect(find.text('Sized'), findsOneWidget);
      }
    });
  });
}
