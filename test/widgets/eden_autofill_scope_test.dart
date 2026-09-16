import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reproduces `40-RESEARCH.md` Appendix A probe 1: a mock handler on
/// [SystemChannels.textInput] captures `TextInput.finishAutofillContext`, which
/// is the only call that makes any platform offer to SAVE a credential.
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

  // Filter by exact method name rather than list length: the engine emits
  // unrelated TextInput.* traffic (setClient, show, ...) on the same channel.
  List<MethodCall> finishCalls() =>
      calls.where((c) => c.method == 'TextInput.finishAutofillContext').toList();

  group('EdenAutofillScope', () {
    testWidgets('installs an AutofillGroup when enabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EdenAutofillScope(child: SizedBox.shrink()),
        ),
      );

      expect(find.byType(AutofillGroup), findsOneWidget);
    });

    testWidgets('enabled: false is a pass-through', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EdenAutofillScope(
            enabled: false,
            child: SizedBox.shrink(),
          ),
        ),
      );

      expect(
        find.byType(AutofillGroup),
        findsNothing,
        reason: 'enabled: false must install no AutofillGroup at all',
      );
      // The State must still be reachable so an enclosing widget can resolve it.
      expect(find.byType(EdenAutofillScope), findsOneWidget);
    });

    testWidgets('commit() invokes TextInput.finishAutofillContext',
        (tester) async {
      installTextInputSpy(tester);

      late BuildContext innerContext;
      await tester.pumpWidget(
        MaterialApp(
          home: EdenAutofillScope(
            child: Builder(
              builder: (context) {
                innerContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(finishCalls(), isEmpty);

      EdenAutofillScope.of(innerContext).commit();
      await tester.pump();

      expect(
        calls.map((c) => c.method),
        contains('TextInput.finishAutofillContext'),
      );
      expect(
        finishCalls().single.arguments,
        isTrue,
        reason: 'commit() must pass shouldSave: true — shouldSave: false tears '
            'the context down without ever offering to save',
      );
    });

    testWidgets('cancel() also invokes finishAutofillContext, with '
        'shouldSave false', (tester) async {
      installTextInputSpy(tester);

      late BuildContext innerContext;
      await tester.pumpWidget(
        MaterialApp(
          home: EdenAutofillScope(
            child: Builder(
              builder: (context) {
                innerContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      EdenAutofillScope.of(innerContext).cancel();
      await tester.pump();

      expect(
        calls.map((c) => c.method),
        contains('TextInput.finishAutofillContext'),
      );
      expect(
        finishCalls().single.arguments,
        isFalse,
        reason: 'cancel() must differ from commit() in the shouldSave payload',
      );
    });

    testWidgets('nothing is invoked merely by building the scope',
        (tester) async {
      installTextInputSpy(tester);

      await tester.pumpWidget(
        const MaterialApp(
          home: EdenAutofillScope(child: Text('hello')),
        ),
      );
      await tester.pump();

      expect(
        finishCalls(),
        isEmpty,
        reason: 'commit() is imperative and caller-driven — no lifecycle hook '
            'in EdenAutofillScope may ever fire it',
      );
    });

    testWidgets('of() asserts with a fix-it message when there is no scope',
        (tester) async {
      late BuildContext scopelessContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              scopelessContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(EdenAutofillScope.maybeOf(scopelessContext), isNull);
      expect(
        () => EdenAutofillScope.of(scopelessContext),
        throwsA(
          isA<AssertionError>().having(
            (e) => e.message.toString(),
            'message',
            allOf(
              contains('No EdenAutofillScope found'),
              contains('EdenForm'),
            ),
          ),
        ),
      );
    });
  });
}
