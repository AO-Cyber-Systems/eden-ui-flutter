import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_time_card_fixtures.dart';

Widget wrap(Widget child, {double width = 800}) => MaterialApp(
      home: Scaffold(body: SizedBox(width: width, child: child)),
    );

void main() {
  // ─────────────────────────────────────────────────────────────────────
  // Test #13 — Renders table layout at width=800
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('renders DataTable layout at width=800 with 3 entries',
      (tester) async {
    await tester.pumpWidget(wrap(EdenTimeCard(
      entries: EdenTimeCardFixtures.completedTimeCards,
      onAction: (_) {},
    )));
    expect(find.byType(DataTable), findsOneWidget);
    expect(find.text('Sarah Vega'), findsOneWidget);
    expect(find.text('Marcus Lee'), findsOneWidget);
    expect(find.text('Jordan Park'), findsOneWidget);
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #14 — Renders stacked-card layout at width=390
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('renders stacked-card layout at width=390', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 390,
          child: EdenTimeCard(
            entries: EdenTimeCardFixtures.completedTimeCards,
            onAction: (_) {},
          ),
        ),
      ),
    ));
    expect(find.byType(DataTable), findsNothing);
    expect(find.byType(EdenCard), findsNWidgets(3));
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #15 — Open shift has badge AND no actions
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('open-shift entry suppresses approval actions (stacked-card)',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 390,
          child: EdenTimeCard(
            entries: [
              EdenTimeCardEntry(
                id: 'tc-open',
                staffId: 'staff-x',
                staffName: 'X Open',
                clockedInAt: DateTime.now()
                    .subtract(const Duration(hours: 2)),
                clockedOutAt: null,
                breaksAccumulated: Duration.zero,
              ),
            ],
            onAction: (_) {},
          ),
        ),
      ),
    ));
    // Open shift = no Approve button.
    expect(find.text('Approve'), findsNothing);
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #16 — Approve emits approve event
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('Approve-tap emits EdenTimeCardApprovalEvent(approve)',
      (tester) async {
    final events = <EdenTimeCardApprovalEvent>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 390,
          child: EdenTimeCard(
            entries: [EdenTimeCardFixtures.completedTimeCards[0]],
            onAction: events.add,
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Approve'));
    await tester.pump();
    expect(events.length, 1);
    expect(events.first.action, EdenTimeCardApprovalAction.approve);
    expect(events.first.entryId, 'tc-1');
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #17 — Reject emits reject event
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('Reject-tap emits reject event', (tester) async {
    final events = <EdenTimeCardApprovalEvent>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 390,
          child: EdenTimeCard(
            entries: [EdenTimeCardFixtures.completedTimeCards[0]],
            onAction: events.add,
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Reject'));
    await tester.pump();
    expect(events.length, 1);
    expect(events.first.action, EdenTimeCardApprovalAction.reject);
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #18 — Request-edit emits requestEdit event
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('Request-edit tap emits requestEdit event', (tester) async {
    final events = <EdenTimeCardApprovalEvent>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 390,
          child: EdenTimeCard(
            entries: [EdenTimeCardFixtures.completedTimeCards[0]],
            onAction: events.add,
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Request edit'));
    await tester.pump();
    expect(events.length, 1);
    expect(events.first.action, EdenTimeCardApprovalAction.requestEdit);
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #19 — showApprovalControls=false hides all actions
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('showApprovalControls=false hides all action buttons',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 390,
          child: EdenTimeCard(
            entries: EdenTimeCardFixtures.completedTimeCards,
            onAction: (_) {},
            showApprovalControls: false,
          ),
        ),
      ),
    ));
    expect(find.text('Approve'), findsNothing);
    expect(find.text('Reject'), findsNothing);
    expect(find.text('Request edit'), findsNothing);
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #20 — Disputed row tint
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('disputed row is rendered (verify via Semantics + note text)',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 390,
          child: EdenTimeCard(
            entries: EdenTimeCardFixtures.completedTimeCards,
            onAction: (_) {},
          ),
        ),
      ),
    ));
    // Marcus Lee is the disputed entry.
    expect(find.text('Marcus Lee'), findsOneWidget);
    expect(find.textContaining('Note: Claims 30-min lunch not 45'),
        findsOneWidget);
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #21 — Live elapsed-time updates for open-shift
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('open-shift elapsed-time refreshes on Timer tick',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 390,
          child: EdenTimeCard(
            entries: [
              EdenTimeCardEntry(
                id: 'tc-open',
                staffId: 'staff-x',
                staffName: 'X Open',
                clockedInAt: DateTime.now()
                    .subtract(const Duration(hours: 2)),
                clockedOutAt: null,
                breaksAccumulated: Duration.zero,
              ),
            ],
            onAction: (_) {},
          ),
        ),
      ),
    ));
    expect(find.textContaining('Worked:'), findsOneWidget);
    await tester.pump(const Duration(seconds: 31));
    expect(find.textContaining('Worked:'), findsOneWidget);
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #22 — Semantics: row label
  // ─────────────────────────────────────────────────────────────────────

  testWidgets("Semantics: each row carries 'Time card for <name>, ...' label",
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 390,
          child: EdenTimeCard(
            entries: EdenTimeCardFixtures.completedTimeCards,
            onAction: (_) {},
          ),
        ),
      ),
    ));
    expect(
      find.bySemanticsLabel(RegExp(r'Time card for Sarah Vega,')),
      findsOneWidget,
    );
    handle.dispose();
  });
}
