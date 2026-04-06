import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: Center(child: child)));
  }

  group('EdenToggle', () {
    testWidgets('renders in off state', (tester) async {
      await tester.pumpWidget(wrap(
        EdenToggle(value: false, onChanged: (_) {}),
      ));
      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, false);
    });

    testWidgets('renders in on state', (tester) async {
      await tester.pumpWidget(wrap(
        EdenToggle(value: true, onChanged: (_) {}),
      ));
      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, true);
    });

    testWidgets('calls onChanged with opposite value when tapped',
        (tester) async {
      bool? received;
      await tester.pumpWidget(wrap(
        EdenToggle(value: false, onChanged: (v) => received = v),
      ));
      await tester.tap(find.byType(Switch));
      expect(received, true);
    });

    testWidgets('disabled state prevents toggle', (tester) async {
      bool? received;
      await tester.pumpWidget(wrap(
        EdenToggle(value: false, onChanged: (v) => received = v, disabled: true),
      ));
      await tester.tap(find.byType(Switch));
      expect(received, isNull);
    });
  });
}
