import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_tip_split_editor_fixtures.dart';

Widget wrap(Widget child, {double width = 600}) => MaterialApp(
      home: Scaffold(body: SizedBox(width: width, child: child)),
    );

void main() {
  // ─────────────────────────────────────────────────────────────────────
  // Test #13 — Renders 2 recipient rows with default 50/50
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('renders 2 recipient rows with default 50/50 split in percent mode',
      (tester) async {
    List<EdenTipSplitAllocation>? captured;
    await tester.pumpWidget(wrap(EdenTipSplitEditor(
      totalTip: 20.0,
      recipients: EdenTipSplitEditorFixtures.twoWayStaff,
      onAllocationsChanged: (a) => captured = a,
    )));
    expect(find.text('Sarah'), findsOneWidget);
    expect(find.text('Mia'), findsOneWidget);
    expect(find.text('Primary stylist'), findsOneWidget);
    expect(find.text('Assistant'), findsOneWidget);
    expect(find.byType(Slider), findsNWidgets(2));
    expect(captured, isNull); // No emission until interaction.
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #14 — Renders 3 recipient rows with initialAllocations
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('renders 3 recipient rows with initialAllocations [60/25/15]',
      (tester) async {
    await tester.pumpWidget(wrap(EdenTipSplitEditor(
      totalTip: 20.0,
      recipients: EdenTipSplitEditorFixtures.threeWayStaff,
      initialAllocations:
          EdenTipSplitEditorFixtures.sixtyTwentyFiveFifteenAllocations,
      onAllocationsChanged: (_) {},
    )));
    expect(find.text('Sarah'), findsOneWidget);
    expect(find.text('Mia'), findsOneWidget);
    expect(find.text('Amy'), findsOneWidget);
    expect(find.byType(Slider), findsNWidgets(3));
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #15 — Slider drag absorbs delta into last-modified other row
  // ─────────────────────────────────────────────────────────────────────

  testWidgets(
      'slider drag absorbs delta into the last-modified other row (locked-row)',
      (tester) async {
    List<EdenTipSplitAllocation>? captured;
    await tester.pumpWidget(wrap(EdenTipSplitEditor(
      totalTip: 20.0,
      recipients: EdenTipSplitEditorFixtures.twoWayStaff,
      onAllocationsChanged: (a) => captured = a,
    )));
    // Programmatically set the first slider to 0.70 via the
    // onChanged callback. tester.drag on a Slider is finicky in unit
    // tests; using the widget's state via onChanged is the pattern
    // mirrored from EdenSplitTender testing.
    final firstSlider = tester.widget<Slider>(find.byType(Slider).first);
    firstSlider.onChanged?.call(0.70);
    await tester.pump();
    expect(captured, isNotNull);
    expect(captured!.length, 2);
    expect(captured![0].share, closeTo(0.70, 0.01));
    // Row 1 absorbed the delta (default last-modified-index == 1):
    // 0.50 - (0.70 - 0.50) = 0.30
    expect(captured![1].share, closeTo(0.30, 0.01));
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #16 — Fixed-amount mode does NOT auto-rebalance
  // ─────────────────────────────────────────────────────────────────────

  testWidgets(
      'fixedAmount mode: editing row 0 leaves row 1 unchanged (no auto-rebalance)',
      (tester) async {
    List<EdenTipSplitAllocation>? captured;
    await tester.pumpWidget(wrap(EdenTipSplitEditor(
      totalTip: 18.0,
      recipients: EdenTipSplitEditorFixtures.twoWayStaff,
      mode: EdenTipSplitMode.fixedAmount,
      initialAllocations: const [
        EdenTipSplitAllocation(
          recipient: EdenTipRecipient(id: 'sarah', displayName: 'Sarah'),
          share: 10.80,
        ),
        EdenTipSplitAllocation(
          recipient: EdenTipRecipient(id: 'mia', displayName: 'Mia'),
          share: 7.20,
        ),
      ],
      onAllocationsChanged: (a) => captured = a,
    )));
    final field = find.byType(TextFormField).first;
    await tester.enterText(field, '12.00');
    await tester.pump();
    expect(captured, isNotNull);
    expect(captured![0].share, closeTo(12.00, 0.001));
    expect(captured![1].share, closeTo(7.20, 0.001));
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #17 — Sum-not-100% banner appears in percent mode
  // ─────────────────────────────────────────────────────────────────────

  testWidgets(
      'percent mode: sum-not-100% banner appears when sum != 1.0 (within 0.01)',
      (tester) async {
    await tester.pumpWidget(wrap(EdenTipSplitEditor(
      totalTip: 20.0,
      recipients: EdenTipSplitEditorFixtures.twoWayStaff,
      initialAllocations: const [
        EdenTipSplitAllocation(
          recipient: EdenTipRecipient(id: 'sarah', displayName: 'Sarah'),
          share: 0.60,
        ),
        EdenTipSplitAllocation(
          recipient: EdenTipRecipient(id: 'mia', displayName: 'Mia'),
          share: 0.30,
        ),
      ],
      onAllocationsChanged: (_) {},
    )));
    // 0.60 + 0.30 = 0.90 → banner present.
    expect(find.byType(EdenBanner), findsOneWidget);
    final banner = tester.widget<EdenBanner>(find.byType(EdenBanner));
    expect(banner.variant, EdenBannerVariant.danger);
  });

  testWidgets(
      'percent mode: balanced 50/50 default — no banner', (tester) async {
    await tester.pumpWidget(wrap(EdenTipSplitEditor(
      totalTip: 20.0,
      recipients: EdenTipSplitEditorFixtures.twoWayStaff,
      onAllocationsChanged: (_) {},
    )));
    expect(find.byType(EdenBanner), findsNothing);
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #18 — Sum-not-totalTip banner in dollar mode
  // ─────────────────────────────────────────────────────────────────────

  testWidgets(
      'fixedAmount mode: sum-not-totalTip banner appears when sum != totalTip',
      (tester) async {
    await tester.pumpWidget(wrap(EdenTipSplitEditor(
      totalTip: 18.0,
      recipients: EdenTipSplitEditorFixtures.twoWayStaff,
      mode: EdenTipSplitMode.fixedAmount,
      initialAllocations: const [
        EdenTipSplitAllocation(
          recipient: EdenTipRecipient(id: 'sarah', displayName: 'Sarah'),
          share: 5.0,
        ),
        EdenTipSplitAllocation(
          recipient: EdenTipRecipient(id: 'mia', displayName: 'Mia'),
          share: 5.0,
        ),
      ],
      onAllocationsChanged: (_) {},
    )));
    // Sum is 10.00, totalTip 18.00 → banner.
    expect(find.byType(EdenBanner), findsOneWidget);
    final banner = tester.widget<EdenBanner>(find.byType(EdenBanner));
    expect(banner.variant, EdenBannerVariant.danger);
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #19 — iPhone-narrow (390pt) collapses to Column
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('iPhone-narrow (390pt): rows collapse to Column; no overflow',
      (tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: EdenTipSplitEditor(
          totalTip: 20.0,
          recipients: EdenTipSplitEditorFixtures.threeWayStaff,
          initialAllocations:
              EdenTipSplitEditorFixtures.sixtyTwentyFiveFifteenAllocations,
          onAllocationsChanged: (_) {},
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #20 — Semantics labels per row
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('Semantics: each recipient row carries a tip-split label',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(EdenTipSplitEditor(
      totalTip: 20.0,
      recipients: EdenTipSplitEditorFixtures.twoWayStaff,
      onAllocationsChanged: (_) {},
    )));
    expect(find.bySemanticsLabel('Tip split for Sarah: 50%'), findsOneWidget);
    expect(find.bySemanticsLabel('Tip split for Mia: 50%'), findsOneWidget);
    handle.dispose();
  });

  // ─────────────────────────────────────────────────────────────────────
  // Bonus — value class sanity
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('EdenTipSplitAllocation.copyWith preserves untouched fields',
      (tester) async {
    const original = EdenTipSplitAllocation(
      recipient: EdenTipRecipient(id: 'sarah', displayName: 'Sarah'),
      share: 0.60,
    );
    final updated = original.copyWith(share: 0.50);
    expect(updated.share, 0.50);
    expect(updated.recipient.id, 'sarah');
  });
}
