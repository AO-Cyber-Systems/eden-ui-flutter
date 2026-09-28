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
  }
}
