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
  }
}
