import 'dart:async';

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_time_clock_fixtures.dart';

Widget wrap(Widget child, {double width = 500}) => MaterialApp(
      home: Scaffold(body: SizedBox(width: width, child: child)),
    );

void main() {
  // ─────────────────────────────────────────────────────────────────────
  // Test #1 — Renders idle UI
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('renders idle UI (EdenOtpInput + Enter PIN header)',
      (tester) async {
    await tester.pumpWidget(wrap(EdenTimeClock(
      onResolveStaff: (_) async => null,
      onAction: (_) {},
    )));
    expect(find.text('Enter PIN'), findsOneWidget);
    expect(find.byType(EdenOtpInput), findsOneWidget);
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #2 — Renders clockedIn UI
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('renders clockedIn UI with active session', (tester) async {
    await tester.pumpWidget(wrap(EdenTimeClock(
      onResolveStaff: (_) async => null,
      onAction: (_) {},
      activeSession: EdenTimeClockFixtures.clockedInSession,
    )));
    expect(find.text('Clocked in'), findsOneWidget);
    expect(find.text('Clock out'), findsOneWidget);
    expect(find.text('Take break'), findsOneWidget);
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #3 — Renders onBreak UI
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('renders onBreak UI with break session', (tester) async {
    await tester.pumpWidget(wrap(EdenTimeClock(
      onResolveStaff: (_) async => null,
      onAction: (_) {},
      activeSession: EdenTimeClockFixtures.onBreakSession,
    )));
    expect(find.text('On break'), findsOneWidget);
    expect(find.text('Resume work'), findsOneWidget);
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #4 — Typing PIN triggers onResolveStaff
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('typing full PIN calls onResolveStaff', (tester) async {
    final completer = Completer<String?>();
    String? captured;
    Future<String?> fakeResolve(String pin) {
      captured = pin;
      return completer.future;
    }

    await tester.pumpWidget(wrap(EdenTimeClock(
      onResolveStaff: fakeResolve,
      onAction: (_) {},
    )));
    // EdenOtpInput uses TextField under the hood — find the box(es)
    // and submit via the onSubmit path.
    final otp = tester.widget<EdenOtpInput>(find.byType(EdenOtpInput));
    otp.onSubmit?.call('1234');
    await tester.pump();
    expect(captured, '1234');
    completer.complete(null);
    await tester.pumpAndSettle();
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #5 — PIN resolves to staff → emits clockIn event
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('successful PIN resolve emits clockIn event', (tester) async {
    final events = <EdenTimeClockEvent>[];
    await tester.pumpWidget(wrap(EdenTimeClock(
      onResolveStaff: (_) async => 'staff-1',
      onAction: events.add,
    )));
    final otp = tester.widget<EdenOtpInput>(find.byType(EdenOtpInput));
    otp.onSubmit?.call('1234');
    await tester.pumpAndSettle();
    expect(events, isNotEmpty);
    expect(events.last.action, EdenTimeClockAction.clockIn);
    expect(events.last.staffId, 'staff-1');
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #6 — PIN null → Invalid PIN banner
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('failed PIN resolve surfaces Invalid PIN danger banner',
      (tester) async {
    await tester.pumpWidget(wrap(EdenTimeClock(
      onResolveStaff: (_) async => null,
      onAction: (_) {},
    )));
    final otp = tester.widget<EdenOtpInput>(find.byType(EdenOtpInput));
    otp.onSubmit?.call('9999');
    await tester.pumpAndSettle();
    expect(find.text('Invalid PIN'), findsOneWidget);
    final banner = tester.widget<EdenBanner>(find.byType(EdenBanner));
    expect(banner.variant, EdenBannerVariant.danger);
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #7 — Clock out button emits clockOut event
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('Clock-out tap emits clockOut event', (tester) async {
    final events = <EdenTimeClockEvent>[];
    await tester.pumpWidget(wrap(EdenTimeClock(
      onResolveStaff: (_) async => null,
      onAction: events.add,
      activeSession: EdenTimeClockFixtures.clockedInSession,
    )));
    await tester.tap(find.text('Clock out'));
    await tester.pump();
    expect(events.length, 1);
    expect(events.first.action, EdenTimeClockAction.clockOut);
    expect(events.first.staffId,
        EdenTimeClockFixtures.clockedInSession.staffId);
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #8 — Take-break emits breakStart
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('Take-break tap emits breakStart event', (tester) async {
    final events = <EdenTimeClockEvent>[];
    await tester.pumpWidget(wrap(EdenTimeClock(
      onResolveStaff: (_) async => null,
      onAction: events.add,
      activeSession: EdenTimeClockFixtures.clockedInSession,
    )));
    await tester.tap(find.text('Take break'));
    await tester.pump();
    expect(events.length, 1);
    expect(events.first.action, EdenTimeClockAction.breakStart);
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #9 — Resume-work emits breakEnd
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('Resume-work tap emits breakEnd event', (tester) async {
    final events = <EdenTimeClockEvent>[];
    await tester.pumpWidget(wrap(EdenTimeClock(
      onResolveStaff: (_) async => null,
      onAction: events.add,
      activeSession: EdenTimeClockFixtures.onBreakSession,
    )));
    await tester.tap(find.text('Resume work'));
    await tester.pump();
    expect(events.length, 1);
    expect(events.first.action, EdenTimeClockAction.breakEnd);
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #10 — Live elapsed-time updates after 30s pump
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('elapsed-time refreshes on Timer tick (30s pump)',
      (tester) async {
    final session = EdenTimeClockSession(
      staffId: 'staff-x',
      clockInAt: DateTime.now().subtract(const Duration(minutes: 60)),
      breaksAccumulated: Duration.zero,
      isOnBreak: false,
    );
    await tester.pumpWidget(wrap(EdenTimeClock(
      onResolveStaff: (_) async => null,
      onAction: (_) {},
      activeSession: session,
    )));
    expect(find.textContaining('Elapsed:'), findsOneWidget);
    // Advance virtual time by 31 seconds; Timer fires at 30s.
    await tester.pump(const Duration(seconds: 31));
    expect(find.textContaining('Elapsed:'), findsOneWidget);
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #11 — iPhone-narrow safe across all states
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('iPhone-narrow (390pt): all 3 states render without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    // Idle
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: EdenTimeClock(
          onResolveStaff: (_) async => null,
          onAction: (_) {},
        ),
      ),
    ));
    expect(tester.takeException(), isNull);

    // ClockedIn
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: EdenTimeClock(
          onResolveStaff: (_) async => null,
          onAction: (_) {},
          activeSession: EdenTimeClockFixtures.clockedInSession,
        ),
      ),
    ));
    expect(tester.takeException(), isNull);

    // OnBreak
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: EdenTimeClock(
          onResolveStaff: (_) async => null,
          onAction: (_) {},
          activeSession: EdenTimeClockFixtures.onBreakSession,
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #12 — Semantics: PIN input + clock-out label
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('Semantics: PIN input announces digit count', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(EdenTimeClock(
      onResolveStaff: (_) async => null,
      onAction: (_) {},
    )));
    expect(
      find.bySemanticsLabel(RegExp(r'PIN entry,.+digits')),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets("Semantics: clock-out carries 'X hours elapsed' label",
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(EdenTimeClock(
      onResolveStaff: (_) async => null,
      onAction: (_) {},
      activeSession: EdenTimeClockSession(
        staffId: 'staff-1',
        clockInAt:
            DateTime.now().subtract(const Duration(hours: 2, minutes: 15)),
        isOnBreak: false,
      ),
    )));
    expect(
      find.bySemanticsLabel(RegExp(r'Clock out of shift,.+elapsed')),
      findsOneWidget,
    );
    handle.dispose();
  });
}
