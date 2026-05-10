import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EdenPaywallDialog', () {
    testWidgets('renders default copy', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => EdenPaywallDialog.show(context),
              child: const Text('open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Credits exhausted'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Upgrade Plan'), findsOneWidget);
    });

    testWidgets('renders custom copy', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => EdenPaywallDialog.show(
                context,
                title: 'Quota reached',
                message: 'You have used all your image credits.',
                upgradeLabel: 'Buy more',
                cancelLabel: 'Later',
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Quota reached'), findsOneWidget);
      expect(find.text('You have used all your image credits.'), findsOneWidget);
      expect(find.text('Buy more'), findsOneWidget);
      expect(find.text('Later'), findsOneWidget);
    });

    testWidgets('upgrade tap dismisses dialog and fires callback',
        (tester) async {
      var upgradeCalls = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => EdenPaywallDialog.show(
                context,
                onUpgrade: () => upgradeCalls++,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Credits exhausted'), findsOneWidget);

      await tester.tap(find.text('Upgrade Plan'));
      await tester.pumpAndSettle();
      expect(find.text('Credits exhausted'), findsNothing);
      expect(upgradeCalls, 1);
    });

    testWidgets('cancel tap dismisses dialog and fires callback',
        (tester) async {
      var cancelCalls = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => EdenPaywallDialog.show(
                context,
                onCancel: () => cancelCalls++,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Credits exhausted'), findsNothing);
      expect(cancelCalls, 1);
    });

    testWidgets('dialog without callbacks still dismisses cleanly',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => EdenPaywallDialog.show(context),
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Credits exhausted'), findsNothing);
    });
  });
}
