import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_commissions_editor_fixtures.dart';

Widget wrap(Widget child, {double width = 600}) => MaterialApp(
      home: Scaffold(body: SizedBox(width: width, child: child)),
    );

void main() {
  // ─────────────────────────────────────────────────────────────────────
  // Test #1 — Renders percent-mode form
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('renders percent-mode form (% suffix)', (tester) async {
    await tester.pumpWidget(wrap(EdenCommissionsEditor(
      rule: EdenCommissionsEditorFixtures.percentRuleSalon,
      onRuleChanged: (_) {},
    )));
    expect(find.text('Percent'), findsWidgets);
    expect(find.text('Of qualifying sale amount'), findsOneWidget);
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #2 — Renders fixed-mode form
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('renders fixed-mode form (\$ prefix)', (tester) async {
    await tester.pumpWidget(wrap(EdenCommissionsEditor(
      rule: EdenCommissionsEditorFixtures.fixedRuleRetail,
      onRuleChanged: (_) {},
    )));
    expect(find.text('Flat dollar amount per qualifying sale'), findsOneWidget);
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #3 — Renders tiered-mode form with rows + Add tier
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('renders tiered-mode form with N rows + Add tier button',
      (tester) async {
    await tester.pumpWidget(wrap(EdenCommissionsEditor(
      rule: EdenCommissionsEditorFixtures.tieredRuleTrades,
      onRuleChanged: (_) {},
    )));
    expect(find.text('Add tier'), findsOneWidget);
    expect(find.text('Above'), findsOneWidget);
    expect(find.text('Rate'), findsWidgets);
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #4 — Renders split-mode form with participant rows
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('renders split-mode form with 3 participant rows',
      (tester) async {
    await tester.pumpWidget(wrap(EdenCommissionsEditor(
      rule: EdenCommissionsEditorFixtures.splitRuleSalonChair,
      onRuleChanged: (_) {},
    )));
    expect(find.text('Sarah'), findsOneWidget);
    expect(find.text('Mia'), findsOneWidget);
    expect(find.text('Chair'), findsOneWidget);
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #5 — Label field toggle
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('label field present when showLabelField=true (default)',
      (tester) async {
    await tester.pumpWidget(wrap(EdenCommissionsEditor(
      rule: EdenCommissionsEditorFixtures.percentRuleSalon,
      onRuleChanged: (_) {},
    )));
    expect(find.text('Commission rule label'), findsOneWidget);
  });

  testWidgets('label field absent when showLabelField=false', (tester) async {
    await tester.pumpWidget(wrap(EdenCommissionsEditor(
      rule: EdenCommissionsEditorFixtures.percentRuleSalon,
      onRuleChanged: (_) {},
      showLabelField: false,
    )));
    expect(find.text('Commission rule label'), findsNothing);
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #6 — Renders EdenSegmentedControl with 4 options
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('mode selector renders 4 options (Percent/Fixed/Tiered/Split)',
      (tester) async {
    await tester.pumpWidget(wrap(EdenCommissionsEditor(
      rule: EdenCommissionsEditorFixtures.percentRuleSalon,
      onRuleChanged: (_) {},
    )));
    expect(find.text('Percent'), findsWidgets);
    expect(find.text('Fixed'), findsOneWidget);
    expect(find.text('Tiered'), findsOneWidget);
    expect(find.text('Split'), findsOneWidget);
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #7 — Mode switch percent→fixed clears percent
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('switching to Fixed mode clears rule.percent', (tester) async {
    EdenCommissionRule? captured;
    await tester.pumpWidget(wrap(EdenCommissionsEditor(
      rule: EdenCommissionsEditorFixtures.percentRuleSalon,
      onRuleChanged: (r) => captured = r,
    )));
    await tester.tap(find.text('Fixed'));
    await tester.pump();
    expect(captured, isNotNull);
    expect(captured!.mode, EdenCommissionMode.fixed);
    expect(captured!.percent, isNull);
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #8 — Switch to tiered seeds at least one tier
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('switching to Tiered mode seeds tiers with single empty tier',
      (tester) async {
    EdenCommissionRule? captured;
    await tester.pumpWidget(wrap(EdenCommissionsEditor(
      rule: EdenCommissionsEditorFixtures.percentRuleSalon,
      onRuleChanged: (r) => captured = r,
    )));
    await tester.tap(find.text('Tiered'));
    await tester.pump();
    expect(captured, isNotNull);
    expect(captured!.mode, EdenCommissionMode.tiered);
    expect(captured!.tiers, isNotNull);
    expect(captured!.tiers!.length, greaterThanOrEqualTo(1));
    expect(captured!.percent, isNull);
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #9 — Switch to split shows warning banner
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('switching to Split mode with empty splits shows warning banner',
      (tester) async {
    EdenCommissionRule? captured;
    await tester.pumpWidget(wrap(EdenCommissionsEditor(
      rule: EdenCommissionsEditorFixtures.percentRuleSalon,
      onRuleChanged: (r) => captured = r,
    )));
    await tester.tap(find.text('Split'));
    await tester.pump();
    expect(captured, isNotNull);
    expect(captured!.mode, EdenCommissionMode.split);
    expect(find.text('Add at least one participant'), findsOneWidget);
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #10 — Percent keystroke emits rule.percent
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('typing in percent field emits rule.percent = parsed',
      (tester) async {
    EdenCommissionRule? captured;
    await tester.pumpWidget(wrap(EdenCommissionsEditor(
      rule: EdenCommissionsEditorFixtures.percentRuleSalon,
      onRuleChanged: (r) => captured = r,
      showLabelField: false,
    )));
    final field = find.byType(TextFormField).first;
    await tester.enterText(field, '45');
    await tester.pump();
    expect(captured!.percent, closeTo(0.45, 0.001));
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #11 — Fixed keystroke emits rule.fixedAmount
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('typing in fixed field emits rule.fixedAmount', (tester) async {
    EdenCommissionRule? captured;
    await tester.pumpWidget(wrap(EdenCommissionsEditor(
      rule: EdenCommissionsEditorFixtures.fixedRuleRetail,
      onRuleChanged: (r) => captured = r,
      showLabelField: false,
    )));
    final field = find.byType(TextFormField).first;
    await tester.enterText(field, '5.00');
    await tester.pump();
    expect(captured!.fixedAmount, closeTo(5.00, 0.001));
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #12 — Add tier inserts row + emits sorted tiers
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('tapping Add tier inserts a new row + emits sorted tiers',
      (tester) async {
    EdenCommissionRule? captured;
    await tester.pumpWidget(wrap(EdenCommissionsEditor(
      rule: EdenCommissionsEditorFixtures.tieredRuleTrades,
      onRuleChanged: (r) => captured = r,
    )));
    final initialCount =
        EdenCommissionsEditorFixtures.tieredRuleTrades.tiers!.length;
    await tester.tap(find.text('Add tier'));
    await tester.pump();
    expect(captured, isNotNull);
    expect(captured!.tiers!.length, initialCount + 1);
    // Sorted ascending.
    final thresholds =
        captured!.tiers!.map((t) => t.thresholdAmount).toList();
    final sorted = List<double>.from(thresholds)..sort();
    expect(thresholds, sorted);
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #13 — Remove tier suppressed when only 1 left
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('remove-tier button is suppressed when only 1 tier left',
      (tester) async {
    await tester.pumpWidget(wrap(EdenCommissionsEditor(
      rule: const EdenCommissionRule(
        id: 'r-single',
        label: 'Single tier',
        mode: EdenCommissionMode.tiered,
        tiers: [EdenCommissionTier(thresholdAmount: 0, rate: 0.10)],
      ),
      onRuleChanged: (_) {},
    )));
    // No remove icon should render.
    expect(find.byIcon(Icons.remove_circle_outline), findsNothing);
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #14 — Split sum-banner appears when sum != 1.0
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('split-sum-not-100% banner appears when sum != 1.0',
      (tester) async {
    await tester.pumpWidget(wrap(EdenCommissionsEditor(
      rule: const EdenCommissionRule(
        id: 'r-imb',
        label: 'Imbalanced',
        mode: EdenCommissionMode.split,
        splits: [
          EdenCommissionSplitParticipant(
            id: 'a',
            displayName: 'A',
            sharePercent: 0.60,
          ),
          EdenCommissionSplitParticipant(
            id: 'b',
            displayName: 'B',
            sharePercent: 0.30,
          ),
        ],
      ),
      onRuleChanged: (_) {},
    )));
    // Sum is 0.90 → banner.
    expect(find.byType(EdenBanner), findsWidgets);
    final dangers = tester
        .widgetList<EdenBanner>(find.byType(EdenBanner))
        .where((b) => b.variant == EdenBannerVariant.danger)
        .toList();
    expect(dangers, isNotEmpty);
  });

  testWidgets('split balanced 0.80/0.15/0.05 — no danger banner',
      (tester) async {
    await tester.pumpWidget(wrap(EdenCommissionsEditor(
      rule: EdenCommissionsEditorFixtures.splitRuleSalonChair,
      onRuleChanged: (_) {},
    )));
    final dangers = tester
        .widgetList<EdenBanner>(find.byType(EdenBanner))
        .where((b) => b.variant == EdenBannerVariant.danger)
        .toList();
    expect(dangers, isEmpty);
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #15 — Label keystroke emits rule.label
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('typing in label field emits rule.label keystroke-by-keystroke',
      (tester) async {
    EdenCommissionRule? captured;
    await tester.pumpWidget(wrap(EdenCommissionsEditor(
      rule: EdenCommissionsEditorFixtures.percentRuleSalon,
      onRuleChanged: (r) => captured = r,
    )));
    final field = find.byType(TextFormField).first;
    await tester.enterText(field, 'New label X');
    await tester.pump();
    expect(captured!.label, 'New label X');
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #16 — iPhone-narrow: 2x2 reflow + no overflow
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('iPhone-narrow (390pt): no RenderFlex overflow', (tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: EdenCommissionsEditor(
          rule: EdenCommissionsEditorFixtures.tieredRuleTrades,
          onRuleChanged: (_) {},
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #17 — iPhone-narrow tier rows render as Cards
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('iPhone-narrow tiered: rows wrap in EdenCard',
      (tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: EdenCommissionsEditor(
          rule: EdenCommissionsEditorFixtures.tieredRuleTrades,
          onRuleChanged: (_) {},
        ),
      ),
    ));
    // 4 tiers in the trades fixture → 4 EdenCards on iPhone-narrow.
    expect(find.byType(EdenCard), findsNWidgets(4));
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #18 — Semantics: mode-segments
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('iPhone-narrow Semantics: mode segments carry selected labels',
      (tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: EdenCommissionsEditor(
          rule: EdenCommissionsEditorFixtures.percentRuleSalon,
          onRuleChanged: (_) {},
        ),
      ),
    ));
    expect(
      find.bySemanticsLabel('Commission mode: Percent, selected'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Commission mode: Fixed, not selected'),
      findsOneWidget,
    );
    handle.dispose();
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #19 — Semantics: tier rows
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('Semantics: tier rows carry threshold + rate labels',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(EdenCommissionsEditor(
      rule: EdenCommissionsEditorFixtures.tieredRuleTrades,
      onRuleChanged: (_) {},
    )));
    expect(
      find.bySemanticsLabel(RegExp(r'Tier above \$.+rate.+')),
      findsWidgets,
    );
    handle.dispose();
  });

  // ─────────────────────────────────────────────────────────────────────
  // Test #20 — Semantics: split rows
  // ─────────────────────────────────────────────────────────────────────

  testWidgets('Semantics: split rows carry participant + share labels',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(EdenCommissionsEditor(
      rule: EdenCommissionsEditorFixtures.splitRuleSalonChair,
      onRuleChanged: (_) {},
    )));
    expect(
      find.bySemanticsLabel('Split participant Sarah, 80%'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Split participant Mia, 15%'),
      findsOneWidget,
    );
    handle.dispose();
  });
}
