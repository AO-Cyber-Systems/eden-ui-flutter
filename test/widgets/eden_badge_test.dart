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

    testWidgets('renders with icon', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenBadge(label: 'Status', icon: Icons.check_circle),
      ));
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
    });

    testWidgets('renders dismiss button when onDismiss provided',
        (tester) async {
      var dismissed = false;
      await tester.pumpWidget(wrap(
        EdenBadge(label: 'Tag', onDismiss: () => dismissed = true),
      ));
      expect(find.byIcon(Icons.close), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      expect(dismissed, true);
    });

    testWidgets('does not show dismiss button without onDismiss',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenBadge(label: 'Tag'),
      ));
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('has semantic label for dismiss button', (tester) async {
      await tester.pumpWidget(wrap(
        EdenBadge(label: 'Filter', onDismiss: () {}),
      ));
      expect(find.bySemanticsLabel('Remove Filter'), findsOneWidget);
    });
  });
}
