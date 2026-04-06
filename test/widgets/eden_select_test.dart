import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: Center(child: child)));
  }

  final options = [
    const EdenSelectOption(value: 'a', label: 'Alpha'),
    const EdenSelectOption(value: 'b', label: 'Beta'),
    const EdenSelectOption(value: 'c', label: 'Gamma'),
  ];

  group('EdenSelect', () {
    testWidgets('renders with label', (tester) async {
      await tester.pumpWidget(wrap(
        EdenSelect<String>(
          options: options,
          label: 'Choose One',
          onChanged: (_) {},
        ),
      ));
      expect(find.text('Choose One'), findsOneWidget);
    });

    testWidgets('shows current value text', (tester) async {
      await tester.pumpWidget(wrap(
        EdenSelect<String>(
          options: options,
          value: 'b',
          onChanged: (_) {},
        ),
      ));
      expect(find.text('Beta'), findsOneWidget);
    });

    testWidgets('opens dropdown on tap and shows options', (tester) async {
      await tester.pumpWidget(wrap(
        EdenSelect<String>(
          options: options,
          value: 'a',
          onChanged: (_) {},
        ),
      ));
      // Tap the dropdown to open it
      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();

      // All options should be visible in the dropdown overlay
      // The selected item appears twice (in field + in dropdown)
      expect(find.text('Beta'), findsOneWidget);
      expect(find.text('Gamma'), findsOneWidget);
    });

    testWidgets('calls onChanged when option selected', (tester) async {
      String? selected;
      await tester.pumpWidget(wrap(
        EdenSelect<String>(
          options: options,
          value: 'a',
          onChanged: (v) => selected = v,
        ),
      ));

      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Beta').last);
      await tester.pumpAndSettle();

      expect(selected, 'b');
    });

    testWidgets('disabled state prevents opening', (tester) async {
      String? selected;
      await tester.pumpWidget(wrap(
        EdenSelect<String>(
          options: options,
          value: 'a',
          onChanged: (v) => selected = v,
          enabled: false,
        ),
      ));

      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();

      // Beta should not appear since dropdown shouldn't open
      expect(find.text('Beta'), findsNothing);
      expect(selected, isNull);
    });
  });
}
