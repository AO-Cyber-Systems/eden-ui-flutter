// The two nav surfaces whose text the oracle could not see until the
// painted-text contrast walk landed: the BOTTOM BAR's badge and the DESKTOP
// RAIL.
//
// WHY THIS FILE EXISTS. `textContrastGuideline` resolves a node's text with
// `find.text(<the node's label>)`. A nav row publishes ONE node carrying the
// ROW's label and wraps its renderer in `ExcludeSemantics`, so a badge's
// string is the label of nothing and was never contrast-checked anywhere in
// this library. Three badge defects on this branch were found by hand for
// exactly that reason.
//
// The two surfaces below are the ones that were still carrying the failure
// when the instrument was fixed:
//
//   bottom bar  badge "3"  Colors.white on colorScheme.error   3.76:1  (9px)
//   rail        badge "3"  Colors.white on colorScheme.primary 2.20:1  (10px)
//   rail        selected label, brand gold on the 10% band     2.05:1  (13px)
//
// Every one of them is BELOW WCAG 1.4.3's 4.5:1 floor, and every one of them
// went green on a suite of 4778 tests.
//
// These are ORACLE assertions, not computed cases: the point of the branch is
// that a badge whose text fails contrast is named by `expectUiSane` on a real
// surface, with no per-case arithmetic to keep in sync.
library;

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:eden_ui_flutter/testing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_support/ui_oracle/wrap.dart';

/// Four destinations, so nothing overflows into a "More" sheet and the badged
/// row is rendered by the BOTTOM BAR itself — the surface under assertion.
const List<EdenNavItem> _barItems = <EdenNavItem>[
  EdenNavItem(id: 'home', label: 'Home', icon: Icons.home_outlined),
  EdenNavItem(
      id: 'orders',
      label: 'Orders',
      icon: Icons.receipt_long_outlined,
      badge: '3'),
  EdenNavItem(
      id: 'reports', label: 'Reports', icon: Icons.insert_chart_outlined),
  EdenNavItem(id: 'settings', label: 'Settings', icon: Icons.settings_outlined),
];

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
    testWidgets('the bottom bar\'s BADGE is sane ($mode)',
        (WidgetTester tester) async {
      await wrap(
        tester,
        EdenMobileLayout(
          navItems: _barItems,
          selectedId: 'home',
          onNavChanged: (_) {},
          topBar: const EdenTopBarConfig(title: 'Orders'),
          user: _user,
          body: const SizedBox.shrink(),
        ),
        width: 390,
        themeMode: themeMode,
      );
      expect(find.text('3'), findsOneWidget,
          reason: 'the badge must actually be rendered — an assertion against '
              'a bar with no badge is the hole this file closes.');

      await expectUiSane(tester, inputModality: EdenInputModality.touch);
    });

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
