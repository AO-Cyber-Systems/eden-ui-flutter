import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: Center(child: child)));
  }

  group('EdenInput', () {
    testWidgets('renders with label text', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenInput(label: 'Email'),
      ));
      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('renders hint text in text field', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenInput(hint: 'Enter your email'),
      ));
      expect(find.text('Enter your email'), findsOneWidget);
    });

    testWidgets('shows error text when errorText provided', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenInput(errorText: 'Required field'),
      ));
      expect(find.text('Required field'), findsOneWidget);
    });

    testWidgets('shows helper text when helperText provided', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenInput(helperText: 'We will not share your email'),
      ));
      expect(find.text('We will not share your email'), findsOneWidget);
    });

    testWidgets('onChanged fires when typing', (tester) async {
      String? captured;
      await tester.pumpWidget(wrap(
        EdenInput(onChanged: (v) => captured = v),
      ));
      await tester.enterText(find.byType(TextField), 'hello');
      expect(captured, 'hello');
    });

    testWidgets('disabled state prevents input', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenInput(enabled: false),
      ));
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, false);
    });

    testWidgets('hides helper text when error is present', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenInput(helperText: 'Helper', errorText: 'Error'),
      ));
      expect(find.text('Error'), findsOneWidget);
      expect(find.text('Helper'), findsNothing);
    });

    testWidgets('renders prefix icon', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenInput(prefixIcon: Icons.email),
      ));
      expect(find.byIcon(Icons.email), findsOneWidget);
    });

    testWidgets('renders suffix icon', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenInput(suffixIcon: Icons.visibility),
      ));
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('works with controller', (tester) async {
      final controller = TextEditingController(text: 'preset');
      await tester.pumpWidget(wrap(
        EdenInput(controller: controller),
      ));
      expect(find.text('preset'), findsOneWidget);
      controller.dispose();
    });

    testWidgets('renders each size variant without error', (tester) async {
      for (final size in EdenInputSize.values) {
        await tester.pumpWidget(wrap(
          EdenInput(hint: 'Size ${size.name}', size: size),
        ));
        expect(find.text('Size ${size.name}'), findsOneWidget);
      }
    });

    testWidgets('multiline maxLines works', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenInput(maxLines: 5, hint: 'Multiline'),
      ));
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.maxLines, 5);
    });

    testWidgets('obscureText hides input', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenInput(obscureText: true),
      ));
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, true);
    });
  });
}
