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

  group('EdenAutofillScope dispose action', () {
    // AutofillGroup defaults onDisposeAction to commit (widgets/autofill.dart:75)
    // and its dispose then calls finishAutofillContext() with shouldSave
    // defaulting to TRUE (:232-243). So merely navigating away from a form would
    // offer to save whatever was typed - including after a FAILED sign-in.
    //
    // That path bypasses commit() and EdenForm.commitAutofillOnSubmit entirely,
    // which would make both controls decorative. EdenAutofillScope therefore
    // inverts the default to cancel.
    testWidgets('disposing the scope does NOT save by default', (tester) async {
      final List<MethodCall> calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.textInput,
        (MethodCall call) async {
          calls.add(call);
          return null;
        },
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EdenAutofillScope(
              child: TextField(autofillHints: <String>[AutofillHints.username]),
            ),
          ),
        ),
      );
      calls.clear();

      // Navigate away - the scope is disposed.
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
      await tester.pump();

      final Iterable<MethodCall> finishes = calls.where(
        (MethodCall c) => c.method == 'TextInput.finishAutofillContext',
      );
      for (final MethodCall c in finishes) {
        expect(
          c.arguments,
          isFalse,
          reason: 'dispose must cancel, never save: a failed sign-in followed by '
              'navigation would otherwise make the platform store a wrong password',
        );
      }

      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.textInput, null);
    });

    testWidgets('onDisposeAction: commit is still available when asked for',
        (tester) async {
      final List<MethodCall> calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.textInput,
        (MethodCall call) async {
          calls.add(call);
          return null;
        },
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EdenAutofillScope(
              onDisposeAction: AutofillContextAction.commit,
              child: TextField(autofillHints: <String>[AutofillHints.username]),
            ),
          ),
        ),
      );
      calls.clear();

      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
      await tester.pump();

      expect(
        calls.any((MethodCall c) =>
            c.method == 'TextInput.finishAutofillContext' && c.arguments == true),
        isTrue,
        reason: 'opting in must restore Flutter default behaviour',
      );

      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.textInput, null);
    });
  });
}
