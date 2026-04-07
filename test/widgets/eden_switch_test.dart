import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eden_ui_flutter/eden_ui.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('EdenToggle (switch)', () {
    testWidgets('renders in off state', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenToggle(value: false, onChanged: null),
      ));

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isFalse);
    });

    testWidgets('renders in on state', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenToggle(value: true, onChanged: null),
      ));

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isTrue);
    });

    testWidgets('calls onChanged with new value on tap', (tester) async {
      bool? receivedValue;
      await tester.pumpWidget(wrap(
        EdenToggle(
          value: false,
          onChanged: (v) => receivedValue = v,
        ),
      ));

      await tester.tap(find.byType(Switch));
      expect(receivedValue, isTrue);
    });

    testWidgets('renders with label', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenToggle(
          value: true,
          onChanged: null,
          label: 'Dark mode',
        ),
      ));

      expect(find.text('Dark mode'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('renders without label (switch only)', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenToggle(value: false, onChanged: null),
      ));

      // No Row, just the Switch directly
      expect(find.byType(Row), findsNothing);
      expect(find.byType(Switch), findsOneWidget);
    });
  });
}
