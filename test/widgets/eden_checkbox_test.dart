import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eden_ui_flutter/eden_ui.dart';

/// EdenToggle is the library's checkbox/switch equivalent.
/// There is no separate EdenCheckbox widget, so we test EdenToggle here as
/// a toggle control (it renders a Switch widget).
void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('EdenToggle (checkbox-like)', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenToggle(value: false, onChanged: null),
      ));

      expect(find.byType(EdenToggle), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('displays label', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenToggle(value: false, onChanged: null, label: 'Enable'),
      ));

      expect(find.text('Enable'), findsOneWidget);
    });

    testWidgets('toggles on tap', (tester) async {
      bool currentValue = false;
      await tester.pumpWidget(wrap(
        StatefulBuilder(
          builder: (context, setState) {
            return EdenToggle(
              value: currentValue,
              onChanged: (v) => setState(() => currentValue = v),
            );
          },
        ),
      ));

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(currentValue, isTrue);
    });

    testWidgets('does not toggle when disabled', (tester) async {
      bool currentValue = false;
      await tester.pumpWidget(wrap(
        EdenToggle(
          value: currentValue,
          disabled: true,
          onChanged: (v) => currentValue = v,
        ),
      ));

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(currentValue, isFalse);
    });
  });
}
