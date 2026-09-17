import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pins the central decision of TRD 40-04: [EdenForm] never auto-commits the
/// autofill context by default, and even with the opt-in enabled it must not
/// commit when the submission did not succeed. A commit after a REJECTED login
/// makes the OS and 1Password offer to save WRONG credentials.
void main() {
  late List<MethodCall> calls;

  setUp(() {
    calls = <MethodCall>[];
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.textInput, null);
  });

  void installTextInputSpy(WidgetTester tester) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.textInput,
      (MethodCall call) async {
        calls.add(call);
        return null;
      },
    );
  }

  List<MethodCall> finishCalls() =>
      calls.where((c) => c.method == 'TextInput.finishAutofillContext').toList();

  Widget buildForm({
    bool autofillScope = true,
    bool commitAutofillOnSubmit = false,
    VoidCallback? onSubmit,
    String? Function(String?)? validator,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: EdenForm(
          autofillScope: autofillScope,
          commitAutofillOnSubmit: commitAutofillOnSubmit,
          onSubmit: onSubmit,
          child: TextFormField(
            autofillHints: const [AutofillHints.username],
            validator: validator ?? (_) => null,
          ),
        ),
      ),
    );
  }

  EdenFormState formState(WidgetTester tester) =>
      tester.state<EdenFormState>(find.byType(EdenForm));

  group('EdenForm autofill scope', () {
    testWidgets('EdenForm provides an ambient AutofillGroup by default',
        (tester) async {
      await tester.pumpWidget(buildForm());

      expect(find.byType(EdenAutofillScope), findsOneWidget);
      expect(
        find.byType(AutofillGroup),
        findsOneWidget,
        reason: 'callers must not have to wire AutofillGroup by hand',
      );

      await tester.pumpWidget(buildForm(autofillScope: false));
      expect(find.byType(AutofillGroup), findsNothing);
    });

    testWidgets('commit does NOT fire on submit by default', (tester) async {
      installTextInputSpy(tester);
      await tester.pumpWidget(buildForm(onSubmit: () {}));

      await formState(tester).submit();
      await tester.pump();

      expect(
        finishCalls(),
        isEmpty,
        reason: 'onSubmit is a bare VoidCallback carrying no success signal, '
            'so auto-commit must be opt-in — committing here would offer to '
            'save credentials an async login has not yet accepted',
      );
    });

    testWidgets('commit fires on a valid submit when commitAutofillOnSubmit '
        'is true', (tester) async {
      installTextInputSpy(tester);
      var submitted = false;
      await tester.pumpWidget(
        buildForm(
          commitAutofillOnSubmit: true,
          onSubmit: () => submitted = true,
        ),
      );

      await formState(tester).submit();
      await tester.pump();

      expect(submitted, isTrue);
      expect(
        calls.map((c) => c.method),
        contains('TextInput.finishAutofillContext'),
      );
      expect(finishCalls().single.arguments, isTrue);
    });

    testWidgets('commit does NOT fire when validation fails', (tester) async {
      installTextInputSpy(tester);
      var submitted = false;
      await tester.pumpWidget(
        buildForm(
          commitAutofillOnSubmit: true,
          onSubmit: () => submitted = true,
          validator: (_) => 'always invalid',
        ),
      );

      await formState(tester).submit();
      await tester.pump();

      expect(submitted, isFalse, reason: 'invalid form must not reach onSubmit');
      expect(
        finishCalls(),
        isEmpty,
        reason: 'a failed login must never make the OS offer to save wrong '
            'credentials',
      );
    });

    testWidgets('commit does NOT fire when onSubmit throws', (tester) async {
      installTextInputSpy(tester);
      await tester.pumpWidget(
        buildForm(
          commitAutofillOnSubmit: true,
          onSubmit: () => throw StateError('login rejected'),
        ),
      );

      final state = formState(tester);
      await expectLater(state.submit(), throwsA(isA<StateError>()));
      await tester.pump();

      expect(
        finishCalls(),
        isEmpty,
        reason: 'a throwing onSubmit is a failed submission — committing would '
            'offer to save rejected credentials',
      );
      expect(
        state.isSubmitting,
        isFalse,
        reason: 'the finally block must still reset _isSubmitting',
      );
    });

    testWidgets(
        'EdenAsyncFormScaffold provides an ambient AutofillGroup on the data '
        'branch only', (tester) async {
      Widget scaffold(EdenAsyncSnapshot<String> value) => MaterialApp(
            home: Scaffold(
              body: EdenAsyncFormScaffold<String>(
                value: value,
                onHydrate: (_) {},
                builder: (context, data) => Text(data),
              ),
            ),
          );

      await tester.pumpWidget(scaffold(const EdenAsyncSnapshot.data('hydrated')));
      await tester.pump();
      expect(find.byType(AutofillGroup), findsOneWidget);
      expect(find.text('hydrated'), findsOneWidget);

      await tester.pumpWidget(scaffold(const EdenAsyncSnapshot.loading()));
      await tester.pump();
      expect(
        find.byType(AutofillGroup),
        findsNothing,
        reason: 'an AutofillGroup around a spinner is noise',
      );

      await tester.pumpWidget(scaffold(EdenAsyncSnapshot.error(Exception('x'))));
      await tester.pump();
      expect(find.byType(AutofillGroup), findsNothing);
    });

    testWidgets('EdenAsyncFormScaffold autofillScope: false is a pass-through',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EdenAsyncFormScaffold<String>(
              value: const EdenAsyncSnapshot.data('hydrated'),
              autofillScope: false,
              onHydrate: (_) {},
              builder: (context, data) => Text(data),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(AutofillGroup), findsNothing);
      expect(find.byType(EdenAutofillScope), findsNothing);
    });
  });
}
