// TDD test file for EdenSOAPNote.

import 'package:eden_ui_flutter/src/theme/eden_theme.dart';
import 'package:eden_ui_flutter/src/theme/eden_theme_profile.dart';
import 'package:eden_ui_flutter/src/widgets/eden_soap_note.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_soap_note_fixtures.dart';

void main() {
  Widget wrap(Widget child, {double width = 600, double height = 1000}) {
    final theme = EdenTheme.light(profile: EdenThemeProfile.medicalInstitutional);
    return MaterialApp(
      theme: theme,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            height: height,
            child: SingleChildScrollView(child: child),
          ),
        ),
      ),
    );
  }

  group('EdenSOAPNote — four-section rendering (compose mode)', () {
    testWidgets('renders 4 section headers', (tester) async {
      await tester.pumpWidget(wrap(EdenSOAPNote(
        data: SoapFixtures.empty,
        patientId: 'pt-001',
      )));
      expect(find.text('Subjective'), findsOneWidget);
      expect(find.text('Objective'), findsOneWidget);
      expect(find.text('Assessment'), findsOneWidget);
      expect(find.text('Plan'), findsOneWidget);
    });

    testWidgets('renders 4 editable TextFields in compose mode',
        (tester) async {
      await tester.pumpWidget(wrap(EdenSOAPNote(
        data: SoapFixtures.empty,
        patientId: 'pt-001',
      )));
      expect(find.byType(TextField), findsNWidgets(4));
    });
  });

  group('EdenSOAPNote — compose mode editing', () {
    testWidgets('typing in Subjective fires onChanged with subjective value',
        (tester) async {
      EdenSoapNoteData? captured;
      await tester.pumpWidget(wrap(EdenSOAPNote(
        data: SoapFixtures.empty,
        patientId: 'pt-001',
        onChanged: (d) => captured = d,
      )));
      await tester.enterText(find.byType(TextField).first, 'Chief complaint');
      await tester.pump();
      expect(captured?.subjective, 'Chief complaint');
    });

    testWidgets('typing in Plan fires onChanged with plan value',
        (tester) async {
      EdenSoapNoteData? captured;
      await tester.pumpWidget(wrap(EdenSOAPNote(
        data: SoapFixtures.annualPhysicalDraft,
        patientId: 'pt-001',
        onChanged: (d) => captured = d,
      )));
      await tester.enterText(find.byType(TextField).last, 'Continue meds');
      await tester.pump();
      expect(captured?.plan, 'Continue meds');
      // Other sections preserved.
      expect(captured?.subjective, contains('annual physical'));
    });
  });

  group('EdenSOAPNote — view mode', () {
    testWidgets('view mode → no TextField, SelectableText instead',
        (tester) async {
      await tester.pumpWidget(wrap(EdenSOAPNote(
        data: SoapFixtures.annualPhysicalSigned,
        patientId: 'pt-001',
        mode: EdenSoapMode.view,
      )));
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(SelectableText), findsAtLeastNWidgets(4));
    });

    testWidgets('view mode + signedBy → "Signed by …" caption',
        (tester) async {
      await tester.pumpWidget(wrap(EdenSOAPNote(
        data: SoapFixtures.annualPhysicalSigned,
        patientId: 'pt-001',
        mode: EdenSoapMode.view,
      )));
      expect(find.textContaining('Signed by Dr. Chen'), findsOneWidget);
    });

    testWidgets('view mode + no signedBy → "Unsigned draft" caption',
        (tester) async {
      await tester.pumpWidget(wrap(EdenSOAPNote(
        data: SoapFixtures.empty,
        patientId: 'pt-001',
        mode: EdenSoapMode.view,
      )));
      expect(find.text('Unsigned draft'), findsOneWidget);
    });
  });

  group('EdenSOAPNote — template toolbar slot', () {
    testWidgets('sectionToolbarSlotBuilder injects per-section widgets',
        (tester) async {
      await tester.pumpWidget(wrap(EdenSOAPNote(
        data: SoapFixtures.empty,
        patientId: 'pt-001',
        sectionToolbarSlotBuilder: (s) => Text('tb-$s'),
      )));
      expect(find.text('tb-subjective'), findsOneWidget);
      expect(find.text('tb-objective'), findsOneWidget);
      expect(find.text('tb-assessment'), findsOneWidget);
      expect(find.text('tb-plan'), findsOneWidget);
    });

    testWidgets('no toolbar builder → no toolbar widgets rendered',
        (tester) async {
      await tester.pumpWidget(wrap(EdenSOAPNote(
        data: SoapFixtures.empty,
        patientId: 'pt-001',
      )));
      expect(find.textContaining('tb-'), findsNothing);
    });
  });

  group('EdenSOAPNote — voice input slot', () {
    testWidgets('voiceInputSlotBuilder injects mic icons per section',
        (tester) async {
      await tester.pumpWidget(wrap(EdenSOAPNote(
        data: SoapFixtures.empty,
        patientId: 'pt-001',
        voiceInputSlotBuilder: (s) => const Icon(Icons.mic),
      )));
      expect(find.byIcon(Icons.mic), findsNWidgets(4));
    });
  });

  group('EdenSOAPNote — AI suggestion slot layout', () {
    testWidgets('width ≥ 840 + aiSuggestionSlot → side-by-side Row',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenSOAPNote(
          data: SoapFixtures.empty,
          patientId: 'pt-001',
          aiSuggestionSlot: Container(key: const Key('ai-panel')),
        ),
        width: 1200,
      ));
      expect(find.byKey(const Key('ai-panel')), findsOneWidget);
    });

    testWidgets('width < 840 + aiSuggestionSlot → stacked Column',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenSOAPNote(
          data: SoapFixtures.empty,
          patientId: 'pt-001',
          aiSuggestionSlot: Container(key: const Key('ai-panel')),
        ),
        width: 390,
      ));
      expect(find.byKey(const Key('ai-panel')), findsOneWidget);
    });

    testWidgets('no aiSuggestionSlot → no extra ai panel rendered',
        (tester) async {
      await tester.pumpWidget(wrap(EdenSOAPNote(
        data: SoapFixtures.empty,
        patientId: 'pt-001',
      )));
      expect(find.byKey(const Key('ai-panel')), findsNothing);
    });
  });

  group('EdenSOAPNote — sign-off integration', () {
    testWidgets('compose mode + signaturePadSlot renders pad slot',
        (tester) async {
      await tester.pumpWidget(wrap(EdenSOAPNote(
        data: SoapFixtures.empty,
        patientId: 'pt-001',
        signaturePadSlot: Container(key: const Key('sig-pad')),
      )));
      expect(find.byKey(const Key('sig-pad')), findsOneWidget);
    });

    testWidgets('view mode + signedBy → signature pad slot NOT rendered',
        (tester) async {
      await tester.pumpWidget(wrap(EdenSOAPNote(
        data: SoapFixtures.annualPhysicalSigned,
        patientId: 'pt-001',
        mode: EdenSoapMode.view,
        signaturePadSlot: Container(key: const Key('sig-pad')),
      )));
      expect(find.byKey(const Key('sig-pad')), findsNothing);
      expect(find.textContaining('Signed by Dr. Chen'), findsOneWidget);
    });
  });

  group(
      'EdenSOAPNote — HIPAA isolation (multitenancy-equivalent per global TDD Playbook habit 6)',
      () {
    testWidgets('data.patientId != patientId param → AssertionError',
        (tester) async {
      expect(
        () => EdenSOAPNote(
          data: SoapFixtures.patient001Empty,
          patientId: 'pt-002',
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    testWidgets('matching patientId → no exception', (tester) async {
      await tester.pumpWidget(wrap(EdenSOAPNote(
        data: SoapFixtures.patient001Empty,
        patientId: 'pt-001',
      )));
      expect(tester.takeException(), isNull);
    });
  });
}
