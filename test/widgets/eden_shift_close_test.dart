import 'dart:async';

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_shift_close_fixtures.dart';

Widget wrap(Widget child, {double width = 700, double height = 1600}) =>
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: width,
          height: height,
          child: SingleChildScrollView(child: child),
        ),
      ),
    );

Future<void> goTo(WidgetTester tester, String step) async {
  await tester.tap(find.widgetWithText(ChoiceChip, step));
  await tester.pump();
}

void main() {
  testWidgets('renders DRAWERCLOSE step with EdenCashDrawerClose visible',
      (tester) async {
    await tester.pumpWidget(wrap(EdenShiftClose(
      initialSession: EdenShiftCloseFixtures.initialSession(),
      reportSnapshot: EdenShiftCloseFixtures.sampleShiftReport,
      onSessionChanged: (_) {},
      onCompleted: (_) {},
    )));
    expect(find.byType(EdenCashDrawerClose), findsOneWidget);
  });

  testWidgets('inner EdenCashDrawerClose onSubmit advances to reportPreview',
      (tester) async {
    await tester.pumpWidget(wrap(EdenShiftClose(
      initialSession: EdenShiftCloseFixtures.initialSession(),
      reportSnapshot: EdenShiftCloseFixtures.sampleShiftReport,
      onSessionChanged: (_) {},
      onCompleted: (_) {},
      allowDeposit: false,
    )));
    // Walk inner drawer-close to confirm: jump to inner review step,
    // tap Confirm close. The inner uses its own ChoiceChip header.
    // Switch the inner's step to review via its ChoiceChip.
    await tester.tap(find.widgetWithText(ChoiceChip, 'review'));
    await tester.pump();
    await tester.tap(find.text('Confirm close'));
    await tester.pump();
    // Outer state should advance: EdenCashDrawerClose no longer in tree,
    // EdenXZReport visible.
    expect(find.byType(EdenXZReport), findsOneWidget);
  });

  testWidgets('renders REPORTPREVIEW step with EdenXZReport visible',
      (tester) async {
    await tester.pumpWidget(wrap(EdenShiftClose(
      initialSession: EdenShiftCloseFixtures.initialSession(),
      reportSnapshot: EdenShiftCloseFixtures.sampleShiftReport,
      onSessionChanged: (_) {},
      onCompleted: (_) {},
    )));
    await goTo(tester, 'reportPreview');
    expect(find.byType(EdenXZReport), findsOneWidget);
  });

  testWidgets('Continue on reportPreview advances to printOrEmail',
      (tester) async {
    await tester.pumpWidget(wrap(EdenShiftClose(
      initialSession: EdenShiftCloseFixtures.initialSession(),
      reportSnapshot: EdenShiftCloseFixtures.sampleShiftReport,
      onSessionChanged: (_) {},
      onCompleted: (_) {},
    )));
    await goTo(tester, 'reportPreview');
    // Drag the scrollable to find the Continue button (XZReport is tall).
    await tester.ensureVisible(find.widgetWithText(EdenButton, 'Continue'));
    await tester.pump();
    await tester.tap(find.widgetWithText(EdenButton, 'Continue'));
    await tester.pump();
    expect(find.text('Print thermal'), findsOneWidget);
  });

  testWidgets('printOrEmail step renders 3 distribution buttons',
      (tester) async {
    await tester.pumpWidget(wrap(EdenShiftClose(
      initialSession: EdenShiftCloseFixtures.initialSession(),
      reportSnapshot: EdenShiftCloseFixtures.sampleShiftReport,
      onSessionChanged: (_) {},
      onCompleted: (_) {},
    )));
    await goTo(tester, 'printOrEmail');
    expect(find.text('Print thermal'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('SMS'), findsOneWidget);
  });

  testWidgets('Print-thermal tap calls onDistribute(thermalPrint)',
      (tester) async {
    final completer = Completer<void>();
    EdenShiftCloseDistribution? capturedChannel;
    Future<void> fakeDistribute(
        EdenShiftReport report, EdenShiftCloseDistribution channel) {
      capturedChannel = channel;
      return completer.future;
    }

    await tester.pumpWidget(wrap(EdenShiftClose(
      initialSession: EdenShiftCloseFixtures.initialSession(),
      reportSnapshot: EdenShiftCloseFixtures.sampleShiftReport,
      onSessionChanged: (_) {},
      onCompleted: (_) {},
      onDistribute: fakeDistribute,
    )));
    await goTo(tester, 'printOrEmail');
    await tester.tap(find.text('Print thermal'));
    await tester.pump();
    expect(capturedChannel, EdenShiftCloseDistribution.thermalPrint);
    completer.complete();
    await tester.pumpAndSettle();
    expect(find.textContaining('Distributed:'), findsOneWidget);
  });

  testWidgets('Distribution buttons disabled when onDistribute=null',
      (tester) async {
    await tester.pumpWidget(wrap(EdenShiftClose(
      initialSession: EdenShiftCloseFixtures.initialSession(),
      reportSnapshot: EdenShiftCloseFixtures.sampleShiftReport,
      onSessionChanged: (_) {},
      onCompleted: (_) {},
      onDistribute: null,
    )));
    await goTo(tester, 'printOrEmail');
    final printBtn = tester.widget<EdenButton>(
        find.widgetWithText(EdenButton, 'Print thermal'));
    expect(printBtn.onPressed, isNull);
  });

  testWidgets("'Skip distribution' advances to confirm without onDistribute",
      (tester) async {
    bool distributeCalled = false;
    await tester.pumpWidget(wrap(EdenShiftClose(
      initialSession: EdenShiftCloseFixtures.initialSession(),
      reportSnapshot: EdenShiftCloseFixtures.sampleShiftReport,
      onSessionChanged: (_) {},
      onCompleted: (_) {},
      onDistribute: (_, __) async {
        distributeCalled = true;
      },
    )));
    await goTo(tester, 'printOrEmail');
    await tester.ensureVisible(
        find.widgetWithText(EdenButton, 'Skip distribution'));
    await tester.pump();
    await tester.tap(find.widgetWithText(EdenButton, 'Skip distribution'));
    await tester.pump();
    // 2 'Confirm shift close' occurrences: title + button.
    expect(find.text('Confirm shift close'), findsWidgets);
    expect(distributeCalled, isFalse);
  });

  testWidgets('Confirm step renders summary with distributedTo',
      (tester) async {
    await tester.pumpWidget(wrap(EdenShiftClose(
      initialSession: EdenShiftCloseFixtures.initialSession(),
      reportSnapshot: EdenShiftCloseFixtures.sampleShiftReport,
      onSessionChanged: (_) {},
      onCompleted: (_) {},
    )));
    await goTo(tester, 'confirm');
    expect(find.textContaining('Drawer close:'), findsOneWidget);
    expect(find.textContaining('Distributed to:'), findsOneWidget);
    expect(find.textContaining('Cash deposit:'), findsOneWidget);
  });

  testWidgets("Confirm shift close calls onCompleted with full result",
      (tester) async {
    EdenShiftCloseResult? captured;
    await tester.pumpWidget(wrap(EdenShiftClose(
      initialSession: EdenShiftCloseFixtures.initialSession(),
      reportSnapshot: EdenShiftCloseFixtures.sampleShiftReport,
      onSessionChanged: (_) {},
      onCompleted: (r) => captured = r,
      allowDeposit: false,
    )));
    // First complete the inner drawer close.
    await tester.tap(find.widgetWithText(ChoiceChip, 'review'));
    await tester.pump();
    await tester.tap(find.text('Confirm close'));
    await tester.pump();
    // Now in reportPreview; jump to confirm step.
    await goTo(tester, 'confirm');
    await tester.ensureVisible(
        find.widgetWithText(EdenButton, 'Confirm shift close'));
    await tester.pump();
    await tester.tap(find.widgetWithText(EdenButton, 'Confirm shift close'));
    await tester.pump();
    expect(captured, isNotNull);
    expect(captured!.reportSnapshot.reportId,
        EdenShiftCloseFixtures.sampleShiftReport.reportId);
  });

  testWidgets('iPhone-narrow (390pt): 4 steps render without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: EdenShiftClose(
            initialSession: EdenShiftCloseFixtures.initialSession(),
            reportSnapshot: EdenShiftCloseFixtures.sampleShiftReport,
            onSessionChanged: (_) {},
            onCompleted: (_) {},
          ),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
    // Verify each step renders by tapping its chip.
    for (final step in ['reportPreview', 'printOrEmail', 'confirm']) {
      await tester.tap(find.widgetWithText(ChoiceChip, step));
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Semantics: distribution buttons announce channel',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(EdenShiftClose(
      initialSession: EdenShiftCloseFixtures.initialSession(),
      reportSnapshot: EdenShiftCloseFixtures.sampleShiftReport,
      onSessionChanged: (_) {},
      onCompleted: (_) {},
      onDistribute: (_, __) async {},
    )));
    await goTo(tester, 'printOrEmail');
    expect(
      find.bySemanticsLabel(RegExp(r'Print thermal — not yet')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp(r'Email — not yet')),
      findsOneWidget,
    );
    handle.dispose();
  });
}
