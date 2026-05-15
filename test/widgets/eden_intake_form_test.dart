import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_intake_form_fixtures.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  Future<void> tapNext(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(EdenButton, 'Next'));
    await tester.pumpAndSettle();
  }

  group('EdenIntakeForm', () {
    testWidgets('renders first question (text) with label + placeholder',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenIntakeForm(
          questions: EdenIntakeFormFixtures.salonOnboarding,
          onComplete: (_) {},
        ),
      ));
      expect(find.text('Full name'), findsOneWidget);
      // Renders an input field for the text question.
      expect(
        find.byKey(const ValueKey<String>('input_name')),
        findsOneWidget,
      );
    });

    testWidgets('typing into text question updates answer state',
        (tester) async {
      Map<String, dynamic>? partial;
      await tester.pumpWidget(wrap(
        EdenIntakeForm(
          questions: EdenIntakeFormFixtures.salonOnboarding,
          onPartialSave: (m) => partial = m,
          onComplete: (_) {},
        ),
      ));
      await tester.enterText(
          find.byKey(const ValueKey<String>('input_name')), 'Alice Salon');
      await tester.pump();
      await tapNext(tester);
      // After advancing, onPartialSave fired with the captured answer.
      expect(partial, isNotNull);
      expect(partial!['name'], 'Alice Salon');
    });

    testWidgets('required text question blocks advance when empty',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenIntakeForm(
          questions: EdenIntakeFormFixtures.salonOnboarding,
          onComplete: (_) {},
        ),
      ));
      // Next is disabled (or shows error) when required field empty.
      final EdenButton nextBtn =
          tester.widget<EdenButton>(find.widgetWithText(EdenButton, 'Next'));
      expect(nextBtn.onPressed, isNull,
          reason: 'required+empty answer must disable Next');
    });

    testWidgets('singleChoice renders RadioListTile per option',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenIntakeForm(
          questions: EdenIntakeFormFixtures.legalIntake,
          initialAnswers: const <String, dynamic>{'clientName': 'Acme Co.'},
          onComplete: (_) {},
        ),
      ));
      // Advance past required clientName (resume prefilled).
      await tapNext(tester);
      // Now on matterType singleChoice.
      expect(find.text('Litigation'), findsOneWidget);
      expect(find.text('Transactional'), findsOneWidget);
      expect(find.text('IP'), findsOneWidget);
      expect(find.text('Estate'), findsOneWidget);
      expect(find.byType(RadioListTile<String>), findsNWidgets(4));
    });

    testWidgets('multipleChoice renders CheckboxListTile + answer is a List',
        (tester) async {
      Map<String, dynamic>? captured;
      await tester.pumpWidget(wrap(
        EdenIntakeForm(
          questions: EdenIntakeFormFixtures.salonOnboarding,
          initialAnswers: const <String, dynamic>{
            'name': 'Alice',
            'phone': '555-0100',
          },
          onComplete: (m) => captured = m,
        ),
      ));
      await tapNext(tester); // name
      await tapNext(tester); // phone
      // Now on services multipleChoice.
      expect(find.byType(CheckboxListTile), findsNWidgets(4));
      await tester.tap(find.text('Haircut'));
      await tester.pump();
      await tester.tap(find.text('Color'));
      await tester.pump();
      await tapNext(tester); // services → marketing
      // Skip optional marketing question.
      await tapNext(tester);
      // Should be on review or submit.
      await tester.pumpAndSettle();
      final submitFinder = find.widgetWithText(EdenButton, 'Submit');
      expect(submitFinder, findsOneWidget);
      await tester.tap(submitFinder);
      await tester.pump();
      expect(captured, isNotNull);
      expect(captured!['services'], isA<List<String>>());
      expect((captured!['services'] as List<String>),
          containsAll(<String>['Haircut', 'Color']));
    });

    testWidgets('number question keeps numeric answer typed as num',
        (tester) async {
      Map<String, dynamic>? captured;
      await tester.pumpWidget(wrap(
        EdenIntakeForm(
          questions: EdenIntakeFormFixtures.legalIntake,
          initialAnswers: const <String, dynamic>{
            'clientName': 'X',
            'matterType': 'IP',
          },
          onComplete: (m) => captured = m,
        ),
      ));
      await tapNext(tester); // clientName
      await tapNext(tester); // matterType (already 'IP')
      // partyCount (number)
      await tester.enterText(
          find.byKey(const ValueKey<String>('input_partyCount')), '3');
      await tester.pump();
      await tapNext(tester);
      // jurisdictions (multipleChoice, optional)
      await tapNext(tester);
      // summary (longText, required)
      await tester.enterText(
          find.byKey(const ValueKey<String>('input_summary')), 'X v. Y');
      await tester.pump();
      await tapNext(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(EdenButton, 'Submit'));
      await tester.pump();
      expect(captured!['partyCount'], 3);
      expect(captured!['partyCount'], isA<num>());
    });

    testWidgets('date question renders EdenDatePicker', (tester) async {
      await tester.pumpWidget(wrap(
        EdenIntakeForm(
          questions: EdenIntakeFormFixtures.medicalIntake,
          initialAnswers: const <String, dynamic>{
            'fullName': 'Jane Patient',
          },
          onComplete: (_) {},
        ),
      ));
      await tapNext(tester); // fullName
      // Now on DOB date question.
      expect(find.byType(EdenDatePicker), findsOneWidget);
    });

    testWidgets('yesNo question renders two-button segmented choice',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenIntakeForm(
          questions: EdenIntakeFormFixtures.salonOnboarding,
          initialAnswers: const <String, dynamic>{
            'name': 'A',
            'phone': '1',
          },
          onComplete: (_) {},
        ),
      ));
      await tapNext(tester); // name
      await tapNext(tester); // phone
      await tapNext(tester); // services (optional, skip)
      // marketing yesNo
      expect(find.widgetWithText(EdenButton, 'Yes'), findsOneWidget);
      expect(find.widgetWithText(EdenButton, 'No'), findsOneWidget);
    });

    testWidgets('conditional branching: hides Q when predicate false',
        (tester) async {
      Map<String, dynamic>? captured;
      await tester.pumpWidget(wrap(
        EdenIntakeForm(
          questions: EdenIntakeFormFixtures.medicalIntake,
          initialAnswers: <String, dynamic>{
            'fullName': 'Jane',
            'dob': DateTime(1990, 1, 1),
            'allergies': '',
          },
          onComplete: (m) => captured = m,
        ),
      ));
      // Advance through fullName, dob, allergies.
      await tapNext(tester); // fullName
      await tapNext(tester); // dob
      await tapNext(tester); // allergies (optional)
      // takingMeds (yesNo, required) — choose No.
      await tester.tap(find.widgetWithText(EdenButton, 'No'));
      await tester.pump();
      await tapNext(tester);
      // meds_list should be SKIPPED — we should now be on insurance.
      expect(find.text('Insurance carrier'), findsOneWidget,
          reason: 'meds_list must be skipped when takingMeds=No');
      // The captured snapshot must NOT have meds_list set.
      // Continue and submit minimally to inspect.
      await tapNext(tester); // insurance (optional)
      // primary complaint (required longText)
      await tester.enterText(
          find.byKey(const ValueKey<String>('input_complaint')), 'Headache');
      await tester.pump();
      await tapNext(tester);
      // consent_followup (optional yesNo)
      await tapNext(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(EdenButton, 'Submit'));
      await tester.pump();
      expect(captured, isNotNull);
      expect(captured!.containsKey('meds_list'), isFalse);
      expect(captured!['takingMeds'], false);
    });

    testWidgets(
        'conditional branching: reveals Q when predicate true on next step',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenIntakeForm(
          questions: EdenIntakeFormFixtures.medicalIntake,
          initialAnswers: <String, dynamic>{
            'fullName': 'Jane',
            'dob': DateTime(1990, 1, 1),
            'allergies': '',
          },
          onComplete: (_) {},
        ),
      ));
      await tapNext(tester); // fullName
      await tapNext(tester); // dob
      await tapNext(tester); // allergies
      await tester.tap(find.widgetWithText(EdenButton, 'Yes'));
      await tester.pump();
      await tapNext(tester);
      // meds_list should now be visible.
      expect(find.text('List your current medications'), findsOneWidget);
    });

    testWidgets('onPartialSave fires on each step advance', (tester) async {
      final List<Map<String, dynamic>> saved = <Map<String, dynamic>>[];
      await tester.pumpWidget(wrap(
        EdenIntakeForm(
          questions: EdenIntakeFormFixtures.salonOnboarding,
          onPartialSave: (m) => saved.add(Map<String, dynamic>.from(m)),
          onComplete: (_) {},
        ),
      ));
      await tester.enterText(
          find.byKey(const ValueKey<String>('input_name')), 'Alice');
      await tester.pump();
      await tapNext(tester);
      await tester.enterText(
          find.byKey(const ValueKey<String>('input_phone')), '555');
      await tester.pump();
      await tapNext(tester);
      expect(saved.length, greaterThanOrEqualTo(2));
      expect(saved.last['name'], 'Alice');
      expect(saved.last['phone'], '555');
    });

    testWidgets('initialAnswers pre-fills the form (resume scenario)',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenIntakeForm(
          questions: EdenIntakeFormFixtures.salonOnboarding,
          initialAnswers: const <String, dynamic>{
            'name': 'Resumed Alice',
            'phone': '555-9999',
          },
          onComplete: (_) {},
        ),
      ));
      final TextField nameField = tester.widget<TextField>(
          find.byKey(const ValueKey<String>('input_name')));
      expect(nameField.controller?.text, 'Resumed Alice');
    });

    testWidgets('review step lists answered Q&A pairs',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenIntakeForm(
          questions: EdenIntakeFormFixtures.salonOnboarding,
          initialAnswers: const <String, dynamic>{
            'name': 'Alice',
            'phone': '555-0100',
            'services': <String>['Haircut'],
            'marketing': true,
          },
          onComplete: (_) {},
        ),
      ));
      // Advance through all 4 questions.
      await tapNext(tester);
      await tapNext(tester);
      await tapNext(tester);
      await tapNext(tester);
      await tester.pumpAndSettle();
      // Review step now visible.
      expect(find.text('Review'), findsOneWidget);
      // Each Q&A pair shown.
      expect(find.text('Full name'), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.widgetWithText(EdenButton, 'Submit'), findsOneWidget);
    });

    testWidgets('submit emits answers map via onComplete', (tester) async {
      Map<String, dynamic>? captured;
      await tester.pumpWidget(wrap(
        EdenIntakeForm(
          questions: EdenIntakeFormFixtures.salonOnboarding,
          initialAnswers: const <String, dynamic>{
            'name': 'Alice',
            'phone': '555-0100',
            'services': <String>['Haircut', 'Color'],
            'marketing': true,
          },
          onComplete: (m) => captured = m,
        ),
      ));
      for (int i = 0; i < 4; i++) {
        await tapNext(tester);
      }
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(EdenButton, 'Submit'));
      await tester.pump();
      expect(captured, isNotNull);
      expect(captured!['name'], 'Alice');
      expect(captured!['phone'], '555-0100');
      expect(captured!['services'], <String>['Haircut', 'Color']);
      expect(captured!['marketing'], true);
    });
  });
}
