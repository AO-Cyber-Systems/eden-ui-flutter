import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_consent_flow_fixtures.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  /// Helper that taps every "I accept..." checkbox for the simpleClauses set.
  Future<void> acceptAllSimpleClauses(WidgetTester tester) async {
    for (final clause in EdenConsentFlowFixtures.simpleClauses) {
      await tester.tap(find.byKey(ValueKey<String>('accept_${clause.id}')));
      await tester.pump();
    }
  }

  /// Helper that simulates the user drawing a stroke on the signature pad
  /// identified by [key], pushing the pad past the "empty" gate.
  Future<void> drawStroke(WidgetTester tester, ValueKey<String> key) async {
    final pad = find.byKey(key);
    expect(pad, findsOneWidget);
    final Offset center = tester.getCenter(pad);
    final TestGesture gesture = await tester.startGesture(center);
    await gesture.moveBy(const Offset(20, 0));
    await gesture.moveBy(const Offset(0, 20));
    await gesture.up();
    await tester.pump();
  }

  group('EdenConsentFlow', () {
    testWidgets('renders step 1 with one checkbox per clause', (tester) async {
      await tester.pumpWidget(wrap(
        EdenConsentFlow(
          clauses: EdenConsentFlowFixtures.simpleClauses,
          onComplete: (_) {},
        ),
      ));
      // One accept checkbox per simple clause.
      for (final clause in EdenConsentFlowFixtures.simpleClauses) {
        expect(
          find.byKey(ValueKey<String>('accept_${clause.id}')),
          findsOneWidget,
          reason: 'expected accept checkbox for ${clause.id}',
        );
      }
    });

    testWidgets('cannot advance until all clauses checked', (tester) async {
      await tester.pumpWidget(wrap(
        EdenConsentFlow(
          clauses: EdenConsentFlowFixtures.simpleClauses,
          onComplete: (_) {},
        ),
      ));
      // Next button exists but is disabled while clauses incomplete.
      final nextFinder = find.widgetWithText(EdenButton, 'Next');
      expect(nextFinder, findsOneWidget);
      final EdenButton next = tester.widget<EdenButton>(nextFinder);
      expect(next.onPressed, isNull,
          reason: 'Next must be disabled before clauses are accepted');

      // Check two of three; still disabled.
      await tester.tap(find.byKey(const ValueKey<String>('accept_tos')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey<String>('accept_privacy')));
      await tester.pump();
      final EdenButton stillDisabled =
          tester.widget<EdenButton>(find.widgetWithText(EdenButton, 'Next'));
      expect(stillDisabled.onPressed, isNull);

      // Accept the third.
      await tester
          .tap(find.byKey(const ValueKey<String>('accept_communications')));
      await tester.pump();
      final EdenButton nowEnabled =
          tester.widget<EdenButton>(find.widgetWithText(EdenButton, 'Next'));
      expect(nowEnabled.onPressed, isNotNull);
    });

    testWidgets('after clauses accepted + Next, signature step shows pad',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenConsentFlow(
          clauses: EdenConsentFlowFixtures.simpleClauses,
          onComplete: (_) {},
        ),
      ));
      await acceptAllSimpleClauses(tester);
      await tester.tap(find.widgetWithText(EdenButton, 'Next'));
      await tester.pumpAndSettle();
      // Primary signature pad now mounted.
      expect(
        find.byKey(const ValueKey<String>('primary_signature_pad')),
        findsOneWidget,
      );
      // Heading appears.
      expect(find.text('Sign below'), findsOneWidget);
    });

    testWidgets('after signing + Next, review step lists clauses + preview',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenConsentFlow(
          clauses: EdenConsentFlowFixtures.simpleClauses,
          onComplete: (_) {},
        ),
      ));
      await acceptAllSimpleClauses(tester);
      await tester.tap(find.widgetWithText(EdenButton, 'Next'));
      await tester.pumpAndSettle();
      await drawStroke(
          tester, const ValueKey<String>('primary_signature_pad'));
      await tester.tap(find.widgetWithText(EdenButton, 'Next'));
      await tester.pumpAndSettle();
      // Review step rendered.
      expect(find.text('Review'), findsOneWidget);
      expect(find.text('Accepted clauses'), findsOneWidget);
      for (final clause in EdenConsentFlowFixtures.simpleClauses) {
        expect(find.text(clause.title), findsOneWidget);
      }
      // Signature preview rendered.
      expect(
        find.byKey(const ValueKey<String>('primary_signature_preview')),
        findsOneWidget,
      );
      // Submit button visible.
      expect(find.widgetWithText(EdenButton, 'Submit consent'), findsOneWidget);
    });

    testWidgets('submit emits EdenConsentRecord with clauses + signature',
        (tester) async {
      EdenConsentRecord? captured;
      await tester.pumpWidget(wrap(
        EdenConsentFlow(
          clauses: EdenConsentFlowFixtures.simpleClauses,
          metadata: const <String, String>{'tenant': 'salon-001'},
          onComplete: (EdenConsentRecord r) => captured = r,
        ),
      ));
      await acceptAllSimpleClauses(tester);
      await tester.tap(find.widgetWithText(EdenButton, 'Next'));
      await tester.pumpAndSettle();
      await drawStroke(
          tester, const ValueKey<String>('primary_signature_pad'));
      await tester.tap(find.widgetWithText(EdenButton, 'Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(EdenButton, 'Submit consent'));
      await tester.pump();
      expect(captured, isNotNull);
      expect(captured!.acceptedClauses, hasLength(3));
      expect(captured!.acceptedClauses['tos'], isTrue);
      expect(captured!.acceptedClauses['privacy'], isTrue);
      expect(captured!.acceptedClauses['communications'], isTrue);
      expect(captured!.primarySignature, isNotEmpty);
      expect(captured!.metadata['tenant'], 'salon-001');
      expect(captured!.witnessName, isNull);
      expect(captured!.witnessSignature, isNull);
    });

    testWidgets(
        'requireWitness=true inserts witness step after primary signature',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenConsentFlow(
          clauses: EdenConsentFlowFixtures.simpleClauses,
          requireWitness: true,
          onComplete: (_) {},
        ),
      ));
      await acceptAllSimpleClauses(tester);
      await tester.tap(find.widgetWithText(EdenButton, 'Next'));
      await tester.pumpAndSettle();
      await drawStroke(
          tester, const ValueKey<String>('primary_signature_pad'));
      await tester.tap(find.widgetWithText(EdenButton, 'Next'));
      await tester.pumpAndSettle();
      // Witness step visible.
      expect(find.text('Witness'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('witness_name_field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('witness_signature_pad')),
        findsOneWidget,
      );
    });

    testWidgets(
        'witness step requires non-empty name AND non-empty signature',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenConsentFlow(
          clauses: EdenConsentFlowFixtures.simpleClauses,
          requireWitness: true,
          onComplete: (_) {},
        ),
      ));
      await acceptAllSimpleClauses(tester);
      await tester.tap(find.widgetWithText(EdenButton, 'Next'));
      await tester.pumpAndSettle();
      await drawStroke(
          tester, const ValueKey<String>('primary_signature_pad'));
      await tester.tap(find.widgetWithText(EdenButton, 'Next'));
      await tester.pumpAndSettle();

      // Both empty → Next disabled.
      final EdenButton disabled =
          tester.widget<EdenButton>(find.widgetWithText(EdenButton, 'Next'));
      expect(disabled.onPressed, isNull);

      // Type name only → still disabled.
      await tester.enterText(
          find.byKey(const ValueKey<String>('witness_name_field')),
          'Jane Witness');
      await tester.pump();
      final EdenButton stillDisabled =
          tester.widget<EdenButton>(find.widgetWithText(EdenButton, 'Next'));
      expect(stillDisabled.onPressed, isNull);

      // Sign too → enabled.
      await drawStroke(
          tester, const ValueKey<String>('witness_signature_pad'));
      final EdenButton enabled =
          tester.widget<EdenButton>(find.widgetWithText(EdenButton, 'Next'));
      expect(enabled.onPressed, isNotNull);
    });

    testWidgets(
        'completed witness flow emits record with witnessName + signature',
        (tester) async {
      EdenConsentRecord? captured;
      await tester.pumpWidget(wrap(
        EdenConsentFlow(
          clauses: EdenConsentFlowFixtures.simpleClauses,
          requireWitness: true,
          onComplete: (r) => captured = r,
        ),
      ));
      await acceptAllSimpleClauses(tester);
      await tester.tap(find.widgetWithText(EdenButton, 'Next'));
      await tester.pumpAndSettle();
      await drawStroke(
          tester, const ValueKey<String>('primary_signature_pad'));
      await tester.tap(find.widgetWithText(EdenButton, 'Next'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const ValueKey<String>('witness_name_field')),
          'Jane Witness');
      await drawStroke(
          tester, const ValueKey<String>('witness_signature_pad'));
      await tester.tap(find.widgetWithText(EdenButton, 'Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(EdenButton, 'Submit consent'));
      await tester.pump();
      expect(captured, isNotNull);
      expect(captured!.witnessName, 'Jane Witness');
      expect(captured!.witnessSignature, isNotNull);
      expect(captured!.witnessSignature, isNotEmpty);
    });

    testWidgets('single clause + no witness yields minimal 3-step flow',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenConsentFlow(
          clauses: EdenConsentFlowFixtures.singleClause,
          onComplete: (_) {},
        ),
      ));
      // Step 1: clauses.
      expect(
        find.byKey(const ValueKey<String>('accept_attestation')),
        findsOneWidget,
      );
      await tester
          .tap(find.byKey(const ValueKey<String>('accept_attestation')));
      await tester.pump();
      await tester.tap(find.widgetWithText(EdenButton, 'Next'));
      await tester.pumpAndSettle();
      // Step 2: signature.
      expect(
        find.byKey(const ValueKey<String>('primary_signature_pad')),
        findsOneWidget,
      );
      await drawStroke(
          tester, const ValueKey<String>('primary_signature_pad'));
      await tester.tap(find.widgetWithText(EdenButton, 'Next'));
      await tester.pumpAndSettle();
      // Step 3: review (NOT witness — only 3 steps).
      expect(find.text('Review'), findsOneWidget);
      expect(find.text('Witness'), findsNothing);
    });

    testWidgets('requireAffirmation clause shows "I understand" checkbox',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenConsentFlow(
          clauses: EdenConsentFlowFixtures.medicalClauses,
          onComplete: (_) {},
        ),
      ));
      // procedure_explained + risks_disclosed have requireAffirmation=true.
      expect(
        find.byKey(const ValueKey<String>('affirm_procedure_explained')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('affirm_risks_disclosed')),
        findsOneWidget,
      );
      // hipaa does not.
      expect(
        find.byKey(const ValueKey<String>('affirm_hipaa')),
        findsNothing,
      );
      // 'I understand' label is rendered for the affirmations.
      expect(find.text('I understand'), findsNWidgets(2));
    });

    testWidgets('back from signature step preserves clause checkbox state',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenConsentFlow(
          clauses: EdenConsentFlowFixtures.simpleClauses,
          onComplete: (_) {},
        ),
      ));
      await acceptAllSimpleClauses(tester);
      await tester.tap(find.widgetWithText(EdenButton, 'Next'));
      await tester.pumpAndSettle();
      // Confirm we're on signature step.
      expect(
        find.byKey(const ValueKey<String>('primary_signature_pad')),
        findsOneWidget,
      );
      // Go back.
      await tester.tap(find.widgetWithText(EdenButton, 'Back'));
      await tester.pumpAndSettle();
      // Each checkbox is still checked.
      for (final clause in EdenConsentFlowFixtures.simpleClauses) {
        final CheckboxListTile tile = tester.widget<CheckboxListTile>(
            find.byKey(ValueKey<String>('accept_${clause.id}')));
        expect(tile.value, isTrue,
            reason: 'clause ${clause.id} should remain checked after back');
      }
    });
  });
}
