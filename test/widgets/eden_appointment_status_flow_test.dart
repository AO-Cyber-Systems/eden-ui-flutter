// TDD test file for EdenAppointmentStatusFlow (obj 017-03).

import 'package:eden_ui_flutter/src/theme/eden_theme.dart';
import 'package:eden_ui_flutter/src/theme/eden_theme_profile.dart';
import 'package:eden_ui_flutter/src/widgets/eden_appointment_status_flow.dart';
import 'package:eden_ui_flutter/src/widgets/eden_stepper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_appointment_status_flow_fixtures.dart';

void main() {
  Widget wrap(Widget child, {double width = 600, double height = 1200}) {
    final theme = EdenTheme.light(profile: EdenThemeProfile.medicalInstitutional);
    return MaterialApp(
      theme: theme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: Center(
            child: SizedBox(width: width, height: height, child: child),
          ),
        ),
      ),
    );
  }

  group('EdenAppointmentStatusFlow — stepper compose (cases 1..4)', () {
    testWidgets('renders EdenStepper with 5 linear steps',
        (tester) async {
      await tester.pumpWidget(wrap(EdenAppointmentStatusFlow(
        event: AppointmentFixtures.scheduledFuture(),
        now: DateTime(2026, 5, 17, 9, 0),
      )));
      final stepper = tester.widget<EdenStepper>(find.byType(EdenStepper));
      expect(stepper.steps.length, 5);
      expect(stepper.steps[0].label, 'Scheduled');
      expect(stepper.steps[1].label, 'Confirmed');
      expect(stepper.steps[2].label, 'Arrived');
      expect(stepper.steps[3].label, 'In Room');
      expect(stepper.steps[4].label, 'Completed');
    });

    testWidgets('currentStatus=scheduled: step 0 current, 1..4 upcoming',
        (tester) async {
      await tester.pumpWidget(wrap(EdenAppointmentStatusFlow(
        event: AppointmentFixtures.scheduledFuture(),
        now: DateTime(2026, 5, 17, 9, 0),
      )));
      final stepper = tester.widget<EdenStepper>(find.byType(EdenStepper));
      expect(stepper.steps[0].status, EdenStepStatus.current);
      expect(stepper.steps[1].status, EdenStepStatus.upcoming);
      expect(stepper.steps[2].status, EdenStepStatus.upcoming);
      expect(stepper.steps[3].status, EdenStepStatus.upcoming);
      expect(stepper.steps[4].status, EdenStepStatus.upcoming);
    });

    testWidgets('currentStatus=arrived: 0..1 complete, 2 current, 3..4 upcoming',
        (tester) async {
      await tester.pumpWidget(wrap(EdenAppointmentStatusFlow(
        event: AppointmentFixtures.arrivedOnTime(),
        now: DateTime(2026, 5, 17, 10, 0),
      )));
      final stepper = tester.widget<EdenStepper>(find.byType(EdenStepper));
      expect(stepper.steps[0].status, EdenStepStatus.complete);
      expect(stepper.steps[1].status, EdenStepStatus.complete);
      expect(stepper.steps[2].status, EdenStepStatus.current);
      expect(stepper.steps[3].status, EdenStepStatus.upcoming);
      expect(stepper.steps[4].status, EdenStepStatus.upcoming);
    });

    testWidgets('currentStatus=completed: all 5 steps complete',
        (tester) async {
      await tester.pumpWidget(wrap(EdenAppointmentStatusFlow(
        event: AppointmentFixtures.completed(),
        now: DateTime(2026, 5, 18),
      )));
      final stepper = tester.widget<EdenStepper>(find.byType(EdenStepper));
      for (var i = 0; i < 5; i++) {
        expect(stepper.steps[i].status, EdenStepStatus.complete);
      }
    });
  });

  group('EdenAppointmentStatusFlow — header (case 5)', () {
    testWidgets('renders visitType + providerName + location + scheduledFor',
        (tester) async {
      await tester.pumpWidget(wrap(EdenAppointmentStatusFlow(
        event: AppointmentFixtures.scheduledFuture(),
        now: DateTime(2026, 5, 17, 9, 0),
      )));
      expect(find.text('Annual physical'), findsOneWidget);
      expect(find.textContaining('Dr. Smith, MD'), findsOneWidget);
      expect(find.textContaining('Main Clinic Suite 200'), findsOneWidget);
      expect(find.textContaining('2026-06-15'), findsOneWidget);
    });
  });

  group('EdenAppointmentStatusFlow — history list (cases 6+7)', () {
    testWidgets('renders status history when showHistory=true (default)',
        (tester) async {
      await tester.pumpWidget(wrap(EdenAppointmentStatusFlow(
        event: AppointmentFixtures.arrivedOnTime(),
        now: DateTime(2026, 5, 17, 10, 0),
      )));
      expect(find.byKey(const ValueKey('eden-appt-history-list')),
          findsOneWidget);
      expect(find.textContaining('Front desk'), findsWidgets);
      expect(find.textContaining('Patient self-service'), findsWidgets);
    });

    testWidgets('showHistory=false suppresses history list', (tester) async {
      await tester.pumpWidget(wrap(EdenAppointmentStatusFlow(
        event: AppointmentFixtures.arrivedOnTime(),
        now: DateTime(2026, 5, 17, 10, 0),
        showHistory: false,
      )));
      expect(find.byKey(const ValueKey('eden-appt-history-list')),
          findsNothing);
    });
  });

  group('EdenAppointmentStatusFlow — terminal badges (cases 8..12)', () {
    testWidgets('noShow: NO SHOW badge in danger color', (tester) async {
      await tester.pumpWidget(wrap(EdenAppointmentStatusFlow(
        event: AppointmentFixtures.noShow(),
        now: DateTime(2026, 5, 17),
      )));
      final badge = find.byKey(const ValueKey('eden-appt-terminal-badge'));
      expect(badge, findsOneWidget);
      expect(find.text('NO SHOW'), findsOneWidget);
    });

    testWidgets('lateCancel: LATE CANCEL badge in warning color',
        (tester) async {
      await tester.pumpWidget(wrap(EdenAppointmentStatusFlow(
        event: AppointmentFixtures.lateCancel(),
        now: DateTime(2026, 5, 18),
      )));
      expect(find.text('LATE CANCEL'), findsOneWidget);
    });

    testWidgets('cancelled: CANCELLED badge in neutral color',
        (tester) async {
      await tester.pumpWidget(wrap(EdenAppointmentStatusFlow(
        event: AppointmentFixtures.cancelled(),
        now: DateTime(2026, 5, 18),
      )));
      expect(find.text('CANCELLED'), findsOneWidget);
    });

    testWidgets('off-path terminal: stepper wrapped in Opacity(0.4)',
        (tester) async {
      await tester.pumpWidget(wrap(EdenAppointmentStatusFlow(
        event: AppointmentFixtures.noShow(),
        now: DateTime(2026, 5, 17),
      )));
      final stepperFinder = find.byType(EdenStepper);
      final opacityAncestors =
          find.ancestor(of: stepperFinder, matching: find.byType(Opacity));
      // Find an Opacity widget with opacity == 0.4 wrapping the stepper.
      var wrapped = false;
      for (final el in opacityAncestors.evaluate()) {
        final op = el.widget as Opacity;
        if (op.opacity == 0.4) {
          wrapped = true;
          break;
        }
      }
      expect(wrapped, isTrue,
          reason: 'off-path terminal MUST wrap EdenStepper in Opacity(0.4)');
    });

    testWidgets('completed does NOT render terminal badge', (tester) async {
      await tester.pumpWidget(wrap(EdenAppointmentStatusFlow(
        event: AppointmentFixtures.completed(),
        now: DateTime(2026, 5, 18),
      )));
      expect(find.byKey(const ValueKey('eden-appt-terminal-badge')),
          findsNothing);
    });
  });

  group('EdenAppointmentStatusFlow — action affordances (cases 13..19)', () {
    testWidgets('advance button visible when non-terminal AND callback set',
        (tester) async {
      await tester.pumpWidget(wrap(EdenAppointmentStatusFlow(
        event: AppointmentFixtures.scheduledFuture(),
        now: DateTime(2026, 5, 17, 9, 0),
        onStatusAdvance: (_) {},
      )));
      expect(find.byKey(const ValueKey('eden-appt-advance-button')),
          findsOneWidget);
    });

    testWidgets('advance button hidden when currentStatus=completed',
        (tester) async {
      await tester.pumpWidget(wrap(EdenAppointmentStatusFlow(
        event: AppointmentFixtures.completed(),
        now: DateTime(2026, 5, 18),
        onStatusAdvance: (_) {},
      )));
      expect(find.byKey(const ValueKey('eden-appt-advance-button')),
          findsNothing);
    });

    testWidgets('advance button hidden when off-path terminal',
        (tester) async {
      await tester.pumpWidget(wrap(EdenAppointmentStatusFlow(
        event: AppointmentFixtures.noShow(),
        now: DateTime(2026, 5, 17),
        onStatusAdvance: (_) {},
      )));
      expect(find.byKey(const ValueKey('eden-appt-advance-button')),
          findsNothing);
    });

    testWidgets('advance button fires onStatusAdvance(nextLinearStatus)',
        (tester) async {
      EdenAppointmentStatus? fired;
      await tester.pumpWidget(wrap(EdenAppointmentStatusFlow(
        event: AppointmentFixtures.scheduledFuture(),
        now: DateTime(2026, 5, 17, 9, 0),
        onStatusAdvance: (s) => fired = s,
      )));
      await tester.tap(find.byKey(const ValueKey('eden-appt-advance-button')));
      expect(fired, EdenAppointmentStatus.confirmed);
    });

    testWidgets('advance from arrived fires onStatusAdvance(inRoom)',
        (tester) async {
      EdenAppointmentStatus? fired;
      await tester.pumpWidget(wrap(EdenAppointmentStatusFlow(
        event: AppointmentFixtures.arrivedOnTime(),
        now: DateTime(2026, 5, 17, 10, 0),
        onStatusAdvance: (s) => fired = s,
      )));
      await tester.tap(find.byKey(const ValueKey('eden-appt-advance-button')));
      expect(fired, EdenAppointmentStatus.inRoom);
    });

    testWidgets('terminal menu visible when non-terminal AND callback set',
        (tester) async {
      await tester.pumpWidget(wrap(EdenAppointmentStatusFlow(
        event: AppointmentFixtures.scheduledFuture(),
        now: DateTime(2026, 5, 17, 9, 0),
        onTerminalStateRequest: (_) {},
      )));
      expect(find.byKey(const ValueKey('eden-appt-terminal-menu')),
          findsOneWidget);
    });

    testWidgets('terminal menu fires onTerminalStateRequest(selected)',
        (tester) async {
      EdenAppointmentStatus? fired;
      await tester.pumpWidget(wrap(EdenAppointmentStatusFlow(
        event: AppointmentFixtures.scheduledFuture(),
        now: DateTime(2026, 5, 17, 9, 0),
        onTerminalStateRequest: (s) => fired = s,
      )));
      await tester.tap(find.byKey(const ValueKey('eden-appt-terminal-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mark as No-Show'));
      await tester.pumpAndSettle();
      expect(fired, EdenAppointmentStatus.noShow);
    });

    testWidgets('terminal menu hidden when already terminal', (tester) async {
      await tester.pumpWidget(wrap(EdenAppointmentStatusFlow(
        event: AppointmentFixtures.noShow(),
        now: DateTime(2026, 5, 17),
        onTerminalStateRequest: (_) {},
      )));
      expect(find.byKey(const ValueKey('eden-appt-terminal-menu')),
          findsNothing);
    });
  });

  group('EdenAppointmentStatusFlow — late arrival chip (cases 20..22)', () {
    testWidgets('arrived + 30min late: "Waiting 30m past scheduled time"',
        (tester) async {
      await tester.pumpWidget(wrap(EdenAppointmentStatusFlow(
        event: AppointmentFixtures.arrivedLate(),
        // Scheduled 10:00; pumped at 10:30 => 30 min late.
        now: DateTime(2026, 5, 17, 10, 30),
      )));
      expect(find.byKey(const ValueKey('eden-appt-late-arrival-chip')),
          findsOneWidget);
      expect(find.textContaining('Waiting 30m'), findsOneWidget);
    });

    testWidgets('arrived + 10min late: no late arrival chip', (tester) async {
      await tester.pumpWidget(wrap(EdenAppointmentStatusFlow(
        event: AppointmentFixtures.arrivedOnTime(),
        // Scheduled 10:00; pumped at 10:10 => 10 min late (< 15min threshold).
        now: DateTime(2026, 5, 17, 10, 10),
      )));
      expect(find.byKey(const ValueKey('eden-appt-late-arrival-chip')),
          findsNothing);
    });

    testWidgets('scheduled (not arrived) + 60min past scheduledFor: no chip',
        (tester) async {
      // Late-arrival warning ONLY applies when currentStatus=arrived.
      await tester.pumpWidget(wrap(EdenAppointmentStatusFlow(
        event: AppointmentFixtures.scheduledFuture(
          scheduledFor: DateTime(2026, 5, 17, 9, 0),
        ),
        now: DateTime(2026, 5, 17, 10, 0), // 60min past
      )));
      expect(find.byKey(const ValueKey('eden-appt-late-arrival-chip')),
          findsNothing);
    });
  });

  group('EdenAppointmentStatusFlow — HIPAA isolation (cases 23+24)', () {
    testWidgets('patient A event MUST NOT render patient B history',
        (tester) async {
      // Render patient-alpha (annual physical) only.
      await tester.pumpWidget(wrap(EdenAppointmentStatusFlow(
        event: AppointmentFixtures.arrivedOnTime(),
        now: DateTime(2026, 5, 17, 10, 0),
      )));
      // patient-bravo no-show note MUST NOT appear.
      expect(find.textContaining('Patient did not arrive, no contact'),
          findsNothing);
      // patient-charlie late-cancel note MUST NOT appear.
      expect(find.textContaining('Cancelled via portal 4h before appointment'),
          findsNothing);
    });
  });
}
