// The DESKTOP RAIL, held to the oracle for the first time.
//
// WHY THIS FILE EXISTS. `textContrastGuideline` resolves a node's text with
// `find.text(<the node's label>)`. A nav row publishes ONE node carrying the
// ROW's label and wraps its renderer in `ExcludeSemantics`, so a badge's
// string is the label of nothing and was never contrast-checked anywhere in
// this library. Three badge defects on this branch were found by hand for
// exactly that reason.
//
// The rail is the FOURTH rendering of the nav row — bar, drawer, "More"
// sheet, rail — and the first three all carried the gold-on-white failure. It
// had never been audited. It was carrying three defects, every one of them
// green on a suite of 4778 tests:
//
//   rail        badge "3"  Colors.white on colorScheme.primary 2.20:1 light
//                                                              2.33:1 dark
//   rail        selected label, brand gold on the 10% band     2.05:1 light
//   rail footer user initials "AL", gold on a 15% gold circle  1.98:1 light
//
// These are ORACLE assertions, not computed cases: the point of the branch is
// that a badge whose text fails contrast is named by `expectUiSane` on a real
// surface, with no per-case arithmetic to keep in sync.
//
// A FOURTH DEFECT WAS IN THE SAME ROW THE WHOLE TIME (eden-ui-flutter#55).
// The audit above fixed the selected LABEL — brand gold on the 10% band,
// 2.05:1 light. The selected ICON beside it, same row, same gold, same
// 2.05:1, was left. It stayed failing with every gate green because no
// instrument in this package could see icon ink: `expectUiSane`'s painted-ink
// rule enumerates `find.byType(Text)` and `EditableText`, an `Icon` renders as
// a `RichText`, and until #52 every icon in every golden was an empty square,
// so a gold glyph and a black glyph and no glyph were the same bytes.
//
// The second half of this file is therefore NOT an oracle assertion. It is
// eight computed cases — icon ink and label ink, selected and unselected, in
// both themes — each of which takes the ink from the resolved widget and the
// SURFACE FROM THE RASTERISED FRAME and computes the WCAG ratio. They are
// computed rather than pinned deliberately: `expect(icon.color, <hex>)` passes
// forever and reports nothing the day the band behind it moves, which is
// exactly how a 2.05:1 glyph survived an audit that was looking straight at
// it. They can be deleted the day `expectUiSane` walks icons — and that, not
// this file, is the real fix.
//
// THE BOTTOM BAR IS NOT RE-PUMPED HERE. Its badge — Colors.white on
// colorScheme.error, 3.76:1 at 9px in both themes — is held by the generated
// `mobile-layout/default` story, which pumps the real shell at 390px in both
// themes and is where the oracle named it.
//
// A hand-built four-item bar WAS tried here first, and what it turned up is
// why the stock `textContrastGuideline` is no longer in the oracle at all.
// That guideline partitions a region's pixels at their mean HSL lightness and
// takes the MODE of each half; for an 11px light-grey label on the dark
// theme's near-black bar the antialiased stroke shades outnumber the glyph's
// core pixels, so the "light" mode came back as a blend (#77777E) and the
// label reported 3.99:1 where its colour pair is 6.91:1. It was
// order-dependent — green when that test ran first, red once a sibling had
// warmed google_fonts and the real Eden face was in use — and it reproduced
// with every product change on this branch reverted. The oracle's own
// painted-text rule reads its ink from the resolved TextStyle instead and is
// not subject to it.
//
// WHAT THIS FILE ADDS, AND WHY THE EIGHT CASES ABOVE COULD NOT SEE #58's
// REGRESSION (eden-ui-flutter#58 code review). Every one of the eight
// computed cases above measures ink against the SURFACE that ink sits on —
// icon-vs-band, label-vs-band, icon-vs-fill, label-vs-fill. That is correct
// as far as it looks, and it is blind ON PRINCIPLE to the axis that
// regressed: WHAT IDENTIFIES the row as selected in the first place. #58
// correctly moved the selected icon's ink off the 10%-primary band — brand
// gold at 2.05:1, the same failure #55 fixed on the label — and onto
// `onSurface`, which is 16.47:1 light / 13.74:1 dark on that same band. A
// real fix, and every one of the eight cases above passed on it both before
// and after, because none of them was ever looking at the band's OWN
// legibility. Once the icon stopped carrying the colour, the band was the
// ONLY thing left identifying the selected row, and it measures 1.08:1
// light / 1.17:1 dark against the rail's own fill (`Colors.white` light /
// `EdenColors.neutral[900]` dark) — under WCAG 1.4.11's 3:1 floor for the
// visual information that identifies a component's state. A file that
// looks straight at both colours and never asks whether the STATE ITSELF is
// identifiable cannot see that. The five cases below ask that question
// directly, parameterised ALSO over the COLLAPSED rail (72px, icon-only) —
// which the eight cases above never pump at all, and which is the one state
// with no label to fall back on once the band is gone.
library;

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:eden_ui_flutter/testing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_support/ui_oracle/measure_ink.dart';
import '../../test_support/ui_oracle/wrap.dart';

/// The rail's own set: the SELECTED row also carries the badge, so the
/// selected-state colours and the badge colours are both on screen at once.
const List<EdenNavItem> _railItems = <EdenNavItem>[
  EdenNavItem(
      id: 'home', label: 'Home', icon: Icons.home_outlined, badge: '3'),
  EdenNavItem(
      id: 'reports', label: 'Reports', icon: Icons.insert_chart_outlined),
];

const EdenLayoutUser _user = EdenLayoutUser(
  name: 'Ada Lovelace',
  email: 'ada@example.com',
  initials: 'AL',
);

/// The rail, at either sidebar width. [collapsed] pumps the 72px icon-only
/// rail — the state the eight cases above never exercise, and the one with
/// no label to identify the row once the band is gone.
Widget _rail(bool collapsed) => EdenDesktopLayout(
      navItems: _railItems,
      selectedId: 'home',
      onNavChanged: (_) {},
      user: _user,
      initiallyCollapsed: collapsed,
      body: const SizedBox.shrink(),
    );

void main() {
  for (final (String mode, ThemeMode themeMode) in <(String, ThemeMode)>[
    ('light', ThemeMode.light),
    ('dark', ThemeMode.dark),
  ]) {
    testWidgets('the desktop RAIL is sane ($mode)',
        (WidgetTester tester) async {
      await wrap(
        tester,
        EdenDesktopLayout(
          navItems: _railItems,
          selectedId: 'home',
          onNavChanged: (_) {},
          user: _user,
          body: const SizedBox.shrink(),
        ),
        themeMode: themeMode,
      );
      expect(find.text('3'), findsOneWidget,
          reason: 'the rail badge must actually be rendered.');
      expect(find.text('Home'), findsOneWidget,
          reason: 'the SELECTED rail row must actually be rendered — its '
              'label is the one that carried the brand colour.');

      await expectUiSane(tester, inputModality: EdenInputModality.pointer);
    });

    // -----------------------------------------------------------------------
    // COMPUTED: the four inks of a nav row, measured against the frame.
    // -----------------------------------------------------------------------
    //
    // WHY BOTH INKS AND BOTH STATES. The label was fixed and the icon was not,
    // and the only reason that was possible is that the two were never
    // measured together. Selected and unselected are both here because the
    // defect lived in ONE of the two states — a test that only pumps the
    // default state measures whichever one the fixture happens to select.
    //
    // FLOORS. WCAG 1.4.11 asks 3:1 for a non-text glyph that carries meaning;
    // WCAG 1.4.3 asks 4.5:1 for the 13px label. Different numbers, so they are
    // stated per assertion rather than shared.
    testWidgets('the rail row\'s ICON and LABEL both clear their floor '
        'against the surface they are painted on, selected and unselected '
        '($mode)', (WidgetTester tester) async {
      await wrap(
        tester,
        EdenDesktopLayout(
          navItems: _railItems,
          selectedId: 'home',
          onNavChanged: (_) {},
          user: _user,
          body: const SizedBox.shrink(),
        ),
        themeMode: themeMode,
      );

      final Finder selectedIcon = find.byIcon(Icons.home_outlined);
      final Finder selectedLabel = find.text('Home');
      final Finder unselectedIcon = find.byIcon(Icons.insert_chart_outlined);
      final Finder unselectedLabel = find.text('Reports');
      for (final Finder f in <Finder>[
        selectedIcon,
        selectedLabel,
        unselectedIcon,
        unselectedLabel,
      ]) {
        expect(f, findsOneWidget,
            reason: 'the measurement needs exactly one node to measure; '
                '$f matched a different number, so the fixture — not the '
                'contrast — is what this run would be reporting on.');
      }

      // SELECTED. The row carries the 10%-primary band, and it is the band —
      // not the glyph — that is the selection affordance. Both inks are
      // therefore `onSurface`: 16.47:1 light, 13.74:1 dark at the branch
      // point. The icon read 2.05:1 light / 6.49:1 dark before #55.
      await expectInkContrast(
        tester,
        selectedIcon,
        iconInk(tester, selectedIcon),
        floor: 3.0,
        what: 'the SELECTED rail icon (WCAG 1.4.11, non-text)',
      );
      await expectInkContrast(
        tester,
        selectedLabel,
        textInk(tester, selectedLabel),
        floor: 4.5,
        what: 'the SELECTED rail label (WCAG 1.4.3, 13px text)',
      );

      // UNSELECTED. No band; both inks sit on the rail's own fill.
      // `onSurfaceVariant` is 4.83:1 light / 6.91:1 dark there — it was never
      // part of the failure, and it is asserted so that a future change that
      // lightens the variant tone cannot pass silently.
      await expectInkContrast(
        tester,
        unselectedIcon,
        iconInk(tester, unselectedIcon),
        floor: 3.0,
        what: 'the UNSELECTED rail icon (WCAG 1.4.11, non-text)',
      );
      await expectInkContrast(
        tester,
        unselectedLabel,
        textInk(tester, unselectedLabel),
        floor: 4.5,
        what: 'the UNSELECTED rail label (WCAG 1.4.3, 13px text)',
      );
    });

    // -------------------------------------------------------------------
    // SELECTION CARRIER — what identifies the row, not just its ink.
    // -------------------------------------------------------------------
    //
    // Five independent cases (not five asserts in one test) so a failure in
    // one does not hide the others: (a) is expected to fail on the unfixed
    // tree with zero matches, (e) is expected to fail printing the band's
    // measured ratio, (b) either fails on the same cardinality check or has
    // nothing to read a rim from, and (c)/(d) are expected to PASS — they
    // measure ink-vs-surface, which is correct today and was never the
    // defect. Parameterised over collapsed too: the collapsed rail has no
    // label at all, so it is the state with the least to fall back on.
    for (final bool collapsed in <bool>[false, true]) {
      final String railState = collapsed ? 'collapsed' : 'expanded';

      testWidgets(
          'the desktop RAIL selected row publishes exactly one selection '
          'indicator ($mode, $railState)', (WidgetTester tester) async {
        await wrap(tester, _rail(collapsed), themeMode: themeMode);
        expect(
          find.byKey(const ValueKey<String>('eden-nav-selection-indicator')),
          findsOneWidget,
          reason: 'the rail selects exactly one row (Home). An indicator on '
              'every row identifies nothing and an indicator on no row is '
              'the eden-ui-flutter#58 review finding: today the desktop '
              'rail has no colour-bearing carrier for its selected state '
              'at all.',
        );
      });

      testWidgets(
          "the selection indicator's RIM clears 3:1 against the rail's own "
          'painted fill ($mode, $railState)', (WidgetTester tester) async {
        await wrap(tester, _rail(collapsed), themeMode: themeMode);
        final Finder indicator = find
            .byKey(const ValueKey<String>('eden-nav-selection-indicator'));
        expect(indicator, findsOneWidget,
            reason: 'no selection indicator is on screen to read a rim '
                'colour off — see the cardinality case above for the '
                'underlying defect.');
        final BoxDecoration decoration =
            tester.widget<Container>(indicator).decoration! as BoxDecoration;
        final Color rim = decoration.border!.top.color;
        // Sampled from the UNSELECTED row's own icon: that row carries no
        // pill and no rim, so the dominant pixel in its tiny bounding box
        // is unambiguously the rail's own fill, not a guess about how much
        // of the selected row's box the pill occupies.
        await expectInkContrast(
          tester,
          find.byIcon(Icons.insert_chart_outlined),
          rim,
          floor: 3.0,
          what: "the SELECTED indicator's RIM against the rail's own "
              'painted fill (WCAG 1.4.11, non-text)',
        );
      });

      testWidgets(
          'the selected glyph clears 3:1 against the pill it is painted on '
          '($mode, $railState)', (WidgetTester tester) async {
        await wrap(tester, _rail(collapsed), themeMode: themeMode);
        final Finder selectedIcon = find.byIcon(Icons.home_outlined);
        expect(selectedIcon, findsOneWidget,
            reason: 'the measurement needs exactly one node to measure.');
        await expectInkContrast(
          tester,
          selectedIcon,
          iconInk(tester, selectedIcon),
          floor: 3.0,
          what: 'the SELECTED rail icon against the pill it sits on (WCAG '
              '1.4.11, non-text)',
        );
      });

      testWidgets(
          "the unselected glyph clears 3:1 against the rail's own fill "
          '($mode, $railState)', (WidgetTester tester) async {
        await wrap(tester, _rail(collapsed), themeMode: themeMode);
        final Finder unselectedIcon =
            find.byIcon(Icons.insert_chart_outlined);
        expect(unselectedIcon, findsOneWidget,
            reason: 'the measurement needs exactly one node to measure.');
        await expectInkContrast(
          tester,
          unselectedIcon,
          iconInk(tester, unselectedIcon),
          floor: 3.0,
          what: 'the UNSELECTED rail icon (WCAG 1.4.11, non-text)',
        );
      });

      testWidgets(
          'no rail row paints a primary@0.1 selection band ($mode, '
          '$railState)', (WidgetTester tester) async {
        await wrap(tester, _rail(collapsed), themeMode: themeMode);

        final BuildContext context =
            tester.element(find.byType(EdenDesktopLayout));
        final ThemeData theme = Theme.of(context);
        final Color band = theme.colorScheme.primary.withValues(alpha: 0.1);
        final Color railFill = theme.brightness == Brightness.dark
            ? EdenColors.neutral[900]!
            : Colors.white;
        final double ratio =
            wcagContrast(Color.alphaBlend(band, railFill), railFill);

        final Iterable<Element> bandedBoxes = find
            .byWidgetPredicate((Widget w) =>
                w is Container &&
                w.decoration is BoxDecoration &&
                (w.decoration! as BoxDecoration).color?.toARGB32() ==
                    band.toARGB32())
            .evaluate();

        expect(
          bandedBoxes,
          isEmpty,
          reason: 'a rail row still paints colorScheme.primary at 10% '
              "alpha as its selection cue. That composites to "
              '${ratio.toStringAsFixed(2)}:1 against the rail\'s own fill '
              '(${hexOf(railFill)}), under WCAG 1.4.11\'s 3:1 floor for '
              "the visual information identifying a component's state. A "
              'band at that ratio identifies nothing; the rim-carrying '
              'indicator is the replacement.',
        );
      });
    }
  }
}
