import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: Center(child: child)));
  }

  group('EdenSearchInput', () {
    testWidgets('renders with search icon', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenSearchInput(),
      ));

      expect(find.byType(EdenSearchInput), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('displays default hint text', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenSearchInput(),
      ));

      expect(find.text('Search...'), findsOneWidget);
    });

    testWidgets('displays custom hint text', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenSearchInput(hint: 'Find users...'),
      ));

      expect(find.text('Find users...'), findsOneWidget);
    });

    testWidgets('accepts text input', (tester) async {
      String? changedValue;
      await tester.pumpWidget(wrap(
        EdenSearchInput(onChanged: (v) => changedValue = v),
      ));

      await tester.enterText(find.byType(TextField), 'flutter');
      expect(changedValue, 'flutter');
    });

    testWidgets('calls onSubmitted when submitted', (tester) async {
      String? submittedValue;
      await tester.pumpWidget(wrap(
        EdenSearchInput(onSubmitted: (v) => submittedValue = v),
      ));

      await tester.enterText(find.byType(TextField), 'query');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      expect(submittedValue, 'query');
    });

    testWidgets('shows clear button when onClear provided', (tester) async {
      await tester.pumpWidget(wrap(
        EdenSearchInput(onClear: () {}),
      ));

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('does not show clear button when onClear is null',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenSearchInput(),
      ));

      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('calls onClear when clear button tapped', (tester) async {
      var cleared = false;
      await tester.pumpWidget(wrap(
        EdenSearchInput(onClear: () => cleared = true),
      ));

      await tester.tap(find.byIcon(Icons.close));
      expect(cleared, isTrue);
    });

    testWidgets('works with external controller', (tester) async {
      final controller = TextEditingController(text: 'initial');
      await tester.pumpWidget(wrap(
        EdenSearchInput(controller: controller),
      ));

      expect(find.text('initial'), findsOneWidget);
      controller.dispose();
    });

    testWidgets('clear button has semantic label', (tester) async {
      await tester.pumpWidget(wrap(
        EdenSearchInput(onClear: () {}),
      ));

      expect(find.bySemanticsLabel('Clear search'), findsOneWidget);
    });
  });
}
