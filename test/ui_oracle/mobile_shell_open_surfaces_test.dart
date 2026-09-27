// The mobile shell's DRAWER and "More" SHEET, held to the same oracle as the
// bottom bar.
//
// WHY THIS FILE EXISTS. `mobile-layout/default` pumps the shell with the
// drawer CLOSED and the sheet unopened, so neither surface is ever rendered
// while `expectUiSane` is looking. That is not "the gate passed them" — the
// gate never looked. The bottom bar's selected state was found to be brand
// gold at 2.20:1 on a white bar and fixed (c828c87); `_DrawerTile` and the
// "More" sheet carried the IDENTICAL failure at the same time and nothing in
// the suite could see it.
//
// Both surfaces are overlays the story harness cannot reach: the drawer is
// opened through the app bar's menu button and the sheet through the overflow
// tab, so each needs a tap between the pump and the assertion. That is what
// these tests add.
//
// BOTH OVERLAYS BLOCK THE SEMANTICS BEHIND THEM (`DrawerController` and
// `ModalBarrier` both wrap in `BlockSemantics`), so the assertion here is
// about the OPEN surface alone — the bar's nodes are not in the tree and
// cannot mask or duplicate anything.
library;

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:eden_ui_flutter/testing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_support/ui_oracle/wrap.dart';

/// Six destinations, so the bar overflows at `maxBottomItems: 5` and the
/// "More" tab exists at all. A caption and a divider are included because the
/// drawer — unlike the bar — renders them, and they are part of the surface
/// under assertion.
const List<EdenNavItem> _navItems = <EdenNavItem>[
  EdenNavItem.caption('Workspace'),
  EdenNavItem(id: 'home', label: 'Home', icon: Icons.home_outlined),
  EdenNavItem(
      id: 'orders',
      label: 'Orders',
      icon: Icons.receipt_long_outlined,
      badge: '3'),
  EdenNavItem.divider(),
  EdenNavItem(
      id: 'reports', label: 'Reports', icon: Icons.insert_chart_outlined),
  EdenNavItem(id: 'settings', label: 'Settings', icon: Icons.settings_outlined),
  EdenNavItem(id: 'billing', label: 'Billing', icon: Icons.credit_card),
  EdenNavItem(id: 'team', label: 'Team', icon: Icons.group_outlined),
];

const EdenLayoutUser _user = EdenLayoutUser(
  name: 'Ada Lovelace',
  email: 'ada@example.com',
  initials: 'AL',
);

Future<void> _pumpShell(
  WidgetTester tester, {
  required ThemeMode themeMode,
  required String selectedId,
}) async {
  await wrap(
    tester,
    EdenMobileLayout(
      navItems: _navItems,
      selectedId: selectedId,
      onNavChanged: (_) {},
      topBar: const EdenTopBarConfig(title: 'Orders'),
      user: _user,
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Orders placed in the last 30 days appear here.'),
      ),
    ),
    width: 390,
    themeMode: themeMode,
  );
}

void main() {
  for (final (String mode, ThemeMode themeMode) in <(String, ThemeMode)>[
    ('light', ThemeMode.light),
    ('dark', ThemeMode.dark),
  ]) {
    testWidgets('the OPEN drawer is sane ($mode)', (WidgetTester tester) async {
      // Selected item is in the drawer AND in the bottom bar, which is the
      // configuration a real shell is in.
      await _pumpShell(tester, themeMode: themeMode, selectedId: 'orders');
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      expect(find.byType(Drawer), findsOneWidget,
          reason: 'the drawer must actually be open — an assertion against a '
              'closed drawer is the exact hole this file closes.');

      await expectUiSane(tester, inputModality: EdenInputModality.touch);
    });

    testWidgets('the OPEN "More" sheet is sane ($mode)',
        (WidgetTester tester) async {
      // Selected item lives in the OVERFLOW, so the sheet renders a selected
      // row — the state that carries the brand colour.
      await _pumpShell(tester, themeMode: themeMode, selectedId: 'billing');
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      expect(find.text('Billing'), findsOneWidget,
          reason: 'the sheet must actually be open and listing the overflow '
              'destinations.');

      await expectUiSane(tester, inputModality: EdenInputModality.touch);
    });
  }
}
