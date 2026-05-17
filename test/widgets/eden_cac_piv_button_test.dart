import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_cac_piv_button_fixtures.dart';

Widget wrap(Widget child, {double width = 400}) =>
    MaterialApp(home: Scaffold(body: SizedBox(width: width, child: child)));

void main() {
  group('EdenCacPivController', () {
    test('initial state is idle', () {
      final c = EdenCacPivController();
      expect(c.state, EdenCacPivState.idle);
      expect(c.errorMessage, isNull);
    });

    test('transitionTo(reading) updates state + notifies', () {
      final c = EdenCacPivController();
      var notified = 0;
      c.addListener(() => notified++);
      c.transitionTo(EdenCacPivState.reading);
      expect(c.state, EdenCacPivState.reading);
      expect(notified, 1);
    });

    test('transitionTo(error, errorMessage) stores message', () {
      final c = EdenCacPivController();
      c.transitionTo(
        EdenCacPivState.error,
        errorMessage: EdenCacPivButtonFixtures.errorPinFailed,
      );
      expect(c.state, EdenCacPivState.error);
      expect(c.errorMessage, EdenCacPivButtonFixtures.errorPinFailed);
    });

    test('reset() returns to idle + clears errorMessage', () {
      final c = EdenCacPivButtonFixtures.controllerInState(
        EdenCacPivState.error,
        errorMessage: 'oops',
      );
      var notified = 0;
      c.addListener(() => notified++);
      c.reset();
      expect(c.state, EdenCacPivState.idle);
      expect(c.errorMessage, isNull);
      expect(notified, 1);
    });
  });

  group('EdenCacPivButton — state rendering', () {
    testWidgets('idle renders Insert button with credit_card icon', (tester) async {
      final c = EdenCacPivController();
      await tester.pumpWidget(wrap(EdenCacPivButton(controller: c)));
      expect(find.byIcon(Icons.credit_card), findsOneWidget);
      expect(find.textContaining('Insert'), findsOneWidget);
    });

    testWidgets('reading renders progress spinner + Reading…', (tester) async {
      final c = EdenCacPivButtonFixtures.controllerInState(EdenCacPivState.reading);
      await tester.pumpWidget(wrap(EdenCacPivButton(controller: c)));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.textContaining('Reading'), findsOneWidget);
    });

    testWidgets('promptPin renders EdenSecretField + Submit button', (tester) async {
      final c = EdenCacPivButtonFixtures.controllerInState(EdenCacPivState.promptPin);
      await tester.pumpWidget(wrap(EdenCacPivButton(controller: c)));
      expect(find.byType(EdenSecretField), findsOneWidget);
      expect(find.textContaining('Submit'), findsOneWidget);
    });

    testWidgets('authenticating renders progress spinner + Verifying…', (tester) async {
      final c = EdenCacPivButtonFixtures.controllerInState(EdenCacPivState.authenticating);
      await tester.pumpWidget(wrap(EdenCacPivButton(controller: c)));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.textContaining('Verifying'), findsOneWidget);
    });

    testWidgets('error renders error icon + message + Try again button', (tester) async {
      final c = EdenCacPivButtonFixtures.controllerInState(
        EdenCacPivState.error,
        errorMessage: EdenCacPivButtonFixtures.errorPinFailed,
      );
      await tester.pumpWidget(wrap(EdenCacPivButton(controller: c)));
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text(EdenCacPivButtonFixtures.errorPinFailed), findsOneWidget);
      expect(find.textContaining('Try again'), findsOneWidget);
    });
  });

  group('EdenCacPivButton — callbacks', () {
    testWidgets('idle tap fires onInsertRequested', (tester) async {
      var fired = false;
      final c = EdenCacPivController();
      await tester.pumpWidget(wrap(EdenCacPivButton(
        controller: c,
        onInsertRequested: () => fired = true,
      )));
      await tester.tap(find.byType(ElevatedButton));
      expect(fired, isTrue);
    });

    testWidgets('promptPin Submit fires onPinSubmitted with current value', (tester) async {
      String? submittedPin;
      final c = EdenCacPivButtonFixtures.controllerInState(EdenCacPivState.promptPin);
      await tester.pumpWidget(wrap(EdenCacPivButton(
        controller: c,
        onPinSubmitted: (v) => submittedPin = v,
      )));
      await tester.enterText(find.byType(EdenSecretField), EdenCacPivButtonFixtures.validPin);
      await tester.tap(find.text('Submit PIN'));
      await tester.pump();
      expect(submittedPin, EdenCacPivButtonFixtures.validPin);
    });

    testWidgets('promptPin field clears after Submit', (tester) async {
      final c = EdenCacPivButtonFixtures.controllerInState(EdenCacPivState.promptPin);
      await tester.pumpWidget(wrap(EdenCacPivButton(
        controller: c,
        onPinSubmitted: (_) {},
      )));
      await tester.enterText(find.byType(EdenSecretField), EdenCacPivButtonFixtures.validPin);
      await tester.tap(find.text('Submit PIN'));
      await tester.pump();
      // After submit, the EdenSecretField's value prop should be empty.
      final field = tester.widget<EdenSecretField>(find.byType(EdenSecretField));
      expect(field.value, isEmpty);
    });

    testWidgets('error Try again fires onRetry AND resets controller to idle', (tester) async {
      var retryFired = false;
      final c = EdenCacPivButtonFixtures.controllerInState(
        EdenCacPivState.error,
        errorMessage: 'fail',
      );
      await tester.pumpWidget(wrap(EdenCacPivButton(
        controller: c,
        onRetry: () => retryFired = true,
      )));
      await tester.tap(find.text('Try again'));
      await tester.pump();
      expect(retryFired, isTrue);
      expect(c.state, EdenCacPivState.idle);
    });
  });

  group('EdenCacPivButton — controller listener lifecycle', () {
    testWidgets('disposing widget then mutating controller does not throw', (tester) async {
      final c = EdenCacPivController();
      await tester.pumpWidget(wrap(EdenCacPivButton(controller: c)));
      await tester.pumpWidget(const SizedBox()); // dispose
      c.transitionTo(EdenCacPivState.reading); // should not throw
      expect(c.state, EdenCacPivState.reading);
    });
  });

  group('EdenCacPivButton — Section 508 a11y', () {
    testWidgets('Semantics label includes the state name (idle)', (tester) async {
      final handle = tester.ensureSemantics();
      final c = EdenCacPivController();
      await tester.pumpWidget(wrap(EdenCacPivButton(controller: c)));
      final semantics = tester.getSemantics(find.byType(EdenCacPivButton));
      expect(semantics.label, contains('idle'));
      expect(semantics.label, contains('CAC/PIV'));
      handle.dispose();
    });

    testWidgets('Semantics label includes the state name (promptPin)', (tester) async {
      final handle = tester.ensureSemantics();
      final c = EdenCacPivButtonFixtures.controllerInState(EdenCacPivState.promptPin);
      await tester.pumpWidget(wrap(EdenCacPivButton(controller: c)));
      final semantics = tester.getSemantics(find.byType(EdenCacPivButton));
      expect(semantics.label, contains('promptPin'));
      handle.dispose();
    });

    testWidgets('PIN field label includes CAC/PIV PIN', (tester) async {
      final c = EdenCacPivButtonFixtures.controllerInState(EdenCacPivState.promptPin);
      await tester.pumpWidget(wrap(EdenCacPivButton(controller: c)));
      final field = tester.widget<EdenSecretField>(find.byType(EdenSecretField));
      expect(field.label, contains('CAC/PIV PIN'));
    });
  });

  group('EdenCacPivButton — iPhone-narrow (390pt) safety', () {
    testWidgets('all 5 states render without overflow at 390pt', (tester) async {
      for (final state in EdenCacPivState.values) {
        final c = EdenCacPivButtonFixtures.controllerInState(
          state,
          errorMessage: state == EdenCacPivState.error ? 'short error' : null,
        );
        await tester.pumpWidget(wrap(EdenCacPivButton(controller: c), width: 390));
        expect(tester.takeException(), isNull, reason: 'state=$state overflow');
      }
    });

    testWidgets('long error message at 390pt does not overflow', (tester) async {
      final c = EdenCacPivButtonFixtures.controllerInState(
        EdenCacPivState.error,
        errorMessage: EdenCacPivButtonFixtures.errorLong,
      );
      await tester.pumpWidget(wrap(EdenCacPivButton(controller: c), width: 390));
      expect(tester.takeException(), isNull);
    });
  });
}
