// TDD test file for EdenVisitEncounterScaffold.

import 'package:eden_ui_flutter/src/theme/eden_theme.dart';
import 'package:eden_ui_flutter/src/theme/eden_theme_profile.dart';
import 'package:eden_ui_flutter/src/widgets/eden_blocking_alerts.dart';
import 'package:eden_ui_flutter/src/widgets/eden_soap_note.dart';
import 'package:eden_ui_flutter/src/widgets/eden_visit_encounter_scaffold.dart';
import 'package:eden_ui_flutter/src/widgets/eden_vitals_row.dart';
import 'package:eden_ui_flutter/src/widgets/eden_workflow_stepper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_visit_encounter_scaffold_fixtures.dart';

void main() {
  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize =
        const Size(1600, 1200);
    binding.platformDispatcher.views.first.devicePixelRatio = 1;
  });

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.resetPhysicalSize();
    binding.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  Widget wrap(Widget child, {double width = 1200, double height = 900}) {
    final theme = EdenTheme.light(profile: EdenThemeProfile.medicalInstitutional);
    return MaterialApp(
      theme: theme,
      home: Scaffold(
        body: SizedBox(width: width, height: height, child: child),
      ),
    );
  }

  group('EdenVisitEncounterScaffold — full smoke', () {
    testWidgets('renders header + stepper + body + right rail',
        (tester) async {
      await tester.pumpWidget(wrap(EdenVisitEncounterScaffold(
        data: VisitFixtures.annualPhysicalEmpty,
        patientId: 'pt-001',
      )));
      expect(tester.takeException(), isNull);
      // Header
      expect(find.textContaining('Annual Physical'), findsAtLeastNWidgets(1));
      // Stepper
      expect(find.byType(EdenWorkflowStepper), findsOneWidget);
      // Body + right rail keys
      expect(find.byKey(const Key('visit-step-body')), findsOneWidget);
      expect(find.byKey(const Key('visit-right-rail')), findsOneWidget);
    });

    testWidgets('stepper renders 5 step labels', (tester) async {
      await tester.pumpWidget(wrap(EdenVisitEncounterScaffold(
        data: VisitFixtures.annualPhysicalEmpty,
        patientId: 'pt-001',
      )));
      expect(find.text('Chief Complaint'), findsAtLeastNWidgets(1));
      expect(find.text('Vitals'), findsAtLeastNWidgets(1));
      expect(find.text('SOAP'), findsAtLeastNWidgets(1));
      expect(find.text('Orders + Rx'), findsAtLeastNWidgets(1));
      expect(find.text('Sign-off'), findsAtLeastNWidgets(1));
    });
  });

  group('EdenVisitEncounterScaffold — step navigation', () {
    testWidgets('default chiefComplaint step → chief-complaint input visible',
        (tester) async {
      await tester.pumpWidget(wrap(EdenVisitEncounterScaffold(
        data: VisitFixtures.annualPhysicalEmpty,
        patientId: 'pt-001',
      )));
      expect(find.byKey(const Key('chief-complaint-input')), findsOneWidget);
    });

    testWidgets('initialStep=soap → SOAP composer visible', (tester) async {
      await tester.pumpWidget(wrap(EdenVisitEncounterScaffold(
        data: VisitFixtures.uriMidVisit,
        patientId: 'pt-001',
        initialStep: EdenVisitStep.soap,
      )));
      expect(find.byType(EdenSOAPNote), findsOneWidget);
    });

    testWidgets('initialStep=signOff → sign-off button visible',
        (tester) async {
      await tester.pumpWidget(wrap(EdenVisitEncounterScaffold(
        data: VisitFixtures.uriMidVisit,
        patientId: 'pt-001',
        initialStep: EdenVisitStep.signOff,
      )));
      expect(find.byKey(const Key('sign-off-button')), findsOneWidget);
    });
  });

  group('EdenVisitEncounterScaffold — chief complaint step', () {
    testWidgets('typing fires onChiefComplaintChange', (tester) async {
      String? captured;
      await tester.pumpWidget(wrap(EdenVisitEncounterScaffold(
        data: VisitFixtures.annualPhysicalEmpty,
        patientId: 'pt-001',
        onChiefComplaintChange: (v) => captured = v,
      )));
      await tester.enterText(
        find.byKey(const Key('chief-complaint-input')),
        'cough × 5d',
      );
      await tester.pump();
      expect(captured, 'cough × 5d');
    });

    testWidgets('uriMidVisit pre-populates chief complaint', (tester) async {
      await tester.pumpWidget(wrap(EdenVisitEncounterScaffold(
        data: VisitFixtures.uriMidVisit,
        patientId: 'pt-001',
      )));
      expect(find.textContaining('Cough × 5d'), findsOneWidget);
    });
  });

  group('EdenVisitEncounterScaffold — vitals step', () {
    testWidgets('vitals step shows EdenVitalsRow with triage vitals',
        (tester) async {
      await tester.pumpWidget(wrap(EdenVisitEncounterScaffold(
        data: VisitFixtures.annualPhysicalEmpty,
        patientId: 'pt-001',
        initialStep: EdenVisitStep.vitals,
      )));
      expect(find.byType(EdenVitalsRow), findsOneWidget);
      expect(find.text('BP'), findsOneWidget);
    });
  });

  group('EdenVisitEncounterScaffold — SOAP step', () {
    testWidgets('SOAP step shows SOAPNote in compose mode', (tester) async {
      await tester.pumpWidget(wrap(EdenVisitEncounterScaffold(
        data: VisitFixtures.uriMidVisit,
        patientId: 'pt-001',
        initialStep: EdenVisitStep.soap,
      )));
      expect(find.byType(EdenSOAPNote), findsOneWidget);
      expect(find.byType(TextField), findsAtLeastNWidgets(4)); // 4 SOAP fields
    });

    testWidgets('uriMidVisit SOAP pre-populates Subjective', (tester) async {
      await tester.pumpWidget(wrap(EdenVisitEncounterScaffold(
        data: VisitFixtures.uriMidVisit,
        patientId: 'pt-001',
        initialStep: EdenVisitStep.soap,
      )));
      expect(find.textContaining('38yo M'), findsOneWidget);
    });
  });

  group('EdenVisitEncounterScaffold — Orders + Rx step', () {
    testWidgets('orders step shows Add-order button (fallback path)',
        (tester) async {
      await tester.pumpWidget(wrap(EdenVisitEncounterScaffold(
        data: VisitFixtures.annualPhysicalEmpty,
        patientId: 'pt-001',
        initialStep: EdenVisitStep.ordersAndRx,
      )));
      expect(find.byKey(const Key('add-order-button')), findsOneWidget);
      expect(find.text('No orders added yet.'), findsOneWidget);
    });

    testWidgets('tap "Add order" fires onOrdersChange with new order',
        (tester) async {
      List<EdenVisitOrder>? captured;
      await tester.pumpWidget(wrap(EdenVisitEncounterScaffold(
        data: VisitFixtures.annualPhysicalEmpty,
        patientId: 'pt-001',
        initialStep: EdenVisitStep.ordersAndRx,
        onOrdersChange: (orders) => captured = orders,
      )));
      await tester.tap(find.byKey(const Key('add-order-button')));
      await tester.pump();
      expect(captured?.length, 1);
    });
  });

  group('EdenVisitEncounterScaffold — Sign-off step', () {
    testWidgets('sign-off body shows attestation text + signature slot',
        (tester) async {
      await tester.pumpWidget(wrap(EdenVisitEncounterScaffold(
        data: VisitFixtures.uriMidVisit,
        patientId: 'pt-001',
        initialStep: EdenVisitStep.signOff,
        signaturePadSlot: Container(key: const Key('sig-pad-slot')),
      )));
      expect(
        find.textContaining('personally examined this patient'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('sig-pad-slot')), findsOneWidget);
      expect(find.byKey(const Key('sign-off-button')), findsOneWidget);
    });

    testWidgets('tap sign-off button fires onSignOff with signedBy populated',
        (tester) async {
      EdenVisitEncounterData? signed;
      await tester.pumpWidget(wrap(EdenVisitEncounterScaffold(
        data: VisitFixtures.uriMidVisit,
        patientId: 'pt-001',
        initialStep: EdenVisitStep.signOff,
        onSignOff: (d) => signed = d,
      )));
      await tester.tap(find.byKey(const Key('sign-off-button')));
      await tester.pump();
      expect(signed?.signedBy, 'Dr. Chen');
      expect(signed?.signedAt, isNotNull);
    });
  });

  group('EdenVisitEncounterScaffold — blocking alerts rail', () {
    testWidgets('uriMidVisit alerts (PCN) render in right rail',
        (tester) async {
      await tester.pumpWidget(wrap(EdenVisitEncounterScaffold(
        data: VisitFixtures.uriMidVisit,
        patientId: 'pt-001',
      )));
      expect(find.byType(EdenBlockingAlerts), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('visit-right-rail')),
          matching: find.byType(EdenBlockingAlerts),
        ),
        findsOneWidget,
      );
    });

    testWidgets('annualPhysicalEmpty alerts → "No active alerts" caption',
        (tester) async {
      await tester.pumpWidget(wrap(EdenVisitEncounterScaffold(
        data: VisitFixtures.annualPhysicalEmpty,
        patientId: 'pt-001',
      )));
      expect(find.text('No active alerts'), findsOneWidget);
    });
  });

  group(
      'EdenVisitEncounterScaffold — HIPAA isolation (per global TDD Playbook habit 6)',
      () {
    testWidgets('data.patientId mismatch → AssertionError', (tester) async {
      expect(
        () => EdenVisitEncounterScaffold(
          data: VisitFixtures.uriMidVisit,
          patientId: 'pt-002', // mismatch
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    testWidgets('matching patientId → no exception', (tester) async {
      await tester.pumpWidget(wrap(EdenVisitEncounterScaffold(
        data: VisitFixtures.uriMidVisit,
        patientId: 'pt-001',
      )));
      expect(tester.takeException(), isNull);
    });
  });

  group('EdenVisitEncounterScaffold — step change callback', () {
    testWidgets('stepper tap fires onStepChange', (tester) async {
      EdenVisitStep? captured;
      await tester.pumpWidget(wrap(EdenVisitEncounterScaffold(
        data: VisitFixtures.uriMidVisit,
        patientId: 'pt-001',
        onStepChange: (s) => captured = s,
      )));
      // EdenWorkflowStepper only makes step circles tappable, not labels.
      // Tap the third step's circle (SOAP = index 2). Use the GestureDetectors
      // inside the stepper subtree.
      final gestureDetectors = find.descendant(
        of: find.byType(EdenWorkflowStepper),
        matching: find.byType(GestureDetector),
      );
      // Step circles are rendered in order; index 2 = SOAP.
      await tester.tap(gestureDetectors.at(2));
      await tester.pumpAndSettle();
      expect(captured, EdenVisitStep.soap);
    });
  });
}
