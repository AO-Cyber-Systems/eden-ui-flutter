import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EdenValidators', () {
    test('required returns error for empty string', () {
      final validator = EdenValidators.required();
      expect(validator(''), isNotNull);
      expect(validator(null), isNotNull);
      expect(validator('hello'), isNull);
    });

    test('required returns custom message', () {
      final validator = EdenValidators.required('Name is required');
      expect(validator(''), 'Name is required');
    });

    test('email returns error for invalid email', () {
      final validator = EdenValidators.email();
      expect(validator('not-an-email'), isNotNull);
      expect(validator('user@example.com'), isNull);
      expect(validator(''), isNull); // empty is valid (use required for that)
    });

    test('minLength returns error for short string', () {
      final validator = EdenValidators.minLength(8);
      expect(validator('short'), isNotNull);
      expect(validator('long enough string'), isNull);
    });

    test('compose chains validators, first error wins', () {
      final validator = EdenValidators.compose([
        EdenValidators.required(),
        EdenValidators.email(),
      ]);
      expect(validator(''), 'This field is required');
      expect(validator('not-email'), 'Enter a valid email');
      expect(validator('a@b.com'), isNull);
    });
  });

  group('EdenForm', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: EdenForm(
            child: Text('Form Content'),
          ),
        ),
      ));
      expect(find.text('Form Content'), findsOneWidget);
    });

    testWidgets('validate returns false when fields are invalid',
        (tester) async {
      final formKey = GlobalKey<EdenFormState>();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EdenForm(
            key: formKey,
            child: EdenFormField(
              name: 'email',
              validators: [EdenValidators.required()],
              builder: (errorText) => EdenInput(
                label: 'Email',
                errorText: errorText,
              ),
            ),
          ),
        ),
      ));

      // Validate without entering anything
      final isValid = formKey.currentState!.validate();
      expect(isValid, false);
    });

    testWidgets('EdenFormState tracks dirty state', (tester) async {
      final formKey = GlobalKey<EdenFormState>();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EdenForm(
            key: formKey,
            child: const Text('Content'),
          ),
        ),
      ));

      expect(formKey.currentState!.isDirty, false);
      formKey.currentState!.markDirty();
      expect(formKey.currentState!.isDirty, true);
    });
  });
}
