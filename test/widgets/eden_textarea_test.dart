import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eden_ui_flutter/eden_ui.dart';

/// EdenInput with maxLines > 1 serves as the textarea equivalent.
void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('EdenInput as textarea (maxLines > 1)', () {
    testWidgets('renders multiline input', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenInput(maxLines: 5, label: 'Description'),
      ));

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
    });

    testWidgets('accepts multiline text', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(wrap(
        EdenInput(maxLines: 5, controller: controller),
      ));

      await tester.enterText(find.byType(TextField), 'Line 1\nLine 2');
      expect(controller.text, 'Line 1\nLine 2');
      controller.dispose();
    });

    testWidgets('shows label and error', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenInput(
          maxLines: 3,
          label: 'Notes',
          errorText: 'Too short',
        ),
      ));

      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('Too short'), findsOneWidget);
    });
  });
}
