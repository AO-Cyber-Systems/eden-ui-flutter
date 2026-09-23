// THE INSTRUMENT MUST NOT GO GREEN ON A DEAD SURFACE.
//
// THE REGRESSION THIS PINS. `expectUiSane`'s tap-action rule was an upper
// bound only — it fired on `routes > 1` and was silent on zero. Replacing
// `ExcludeSemantics` with `IgnorePointer` in `EdenMobileLayout._navRow` (one
// edit) killed all four bottom-nav buttons and the whole mobile-layout story
// oracle went GREEN: `+2 ~2: All tests passed!`. The contrast violation that
// had been red disappeared with it, because `textContrastGuideline` locates
// its paragraph by HIT TEST and a surface that takes no pointer offers nothing
// to hit. The oracle reported FEWER violations the more broken the surface
// was.
//
// WHY THIS IS A TEST AND NOT A ONE-OFF CHECK. The proof above required editing
// shipping source, so it cannot live in the suite as written. It does not have
// to: `EdenMobileLayout.itemBuilder` is PUBLIC, and a consumer builder that
// returns a row which refuses the pointer reproduces exactly the same tree —
// `Semantics(onTap:) > ExcludeSemantics > IgnorePointer > row`. That is also a
// defect a consumer can really ship, which the source edit was only standing
// in for.
//
// CASE 1 IS THE CONTROL. Asserting only that the broken shell goes red proves
// nothing about the rule: a rule that named every row on every surface would
// pass case 2 and be useless. Case 1 requires the REAL default renderer —
// whose rows are live — to be named by nothing.
library;

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:eden_ui_flutter/testing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const List<EdenNavItem> _navItems = <EdenNavItem>[
  EdenNavItem(id: 'home', label: 'Home', icon: Icons.home),
  EdenNavItem(id: 'orders', label: 'Orders', icon: Icons.receipt_long),
  EdenNavItem(id: 'reports', label: 'Reports', icon: Icons.bar_chart),
  EdenNavItem(id: 'settings', label: 'Settings', icon: Icons.settings),
];

Future<void> _pumpShell(
  WidgetTester tester, {
  EdenNavItemBuilder? itemBuilder,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(1280, 800);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(MaterialApp(
    theme: EdenTheme.light(),
    home: EdenMobileLayout(
      navItems: _navItems,
      selectedId: 'home',
      onNavChanged: (_) {},
      itemBuilder: itemBuilder,
      body: const Text('Body'),
    ),
  ));
  await tester.pumpAndSettle();
}

/// The aggregated violation message, or null when the surface was clean.
///
/// The message is what is asserted on, never merely "something threw": the
/// point of the rule is that it NAMES the dead control.
Future<String?> _saneReport(WidgetTester tester) async {
  try {
    await expectUiSane(tester, inputModality: EdenInputModality.touch);
    return null;
  } on TestFailure catch (failure) {
    return failure.message;
  }
}

/// A row that renders normally and cannot take a pointer.
///
/// `IgnorePointer` is the exact wrapper from the original defect: it returns
/// false from `hitTest` AND sets `isBlockingUserActions`, so the row's own
/// implicit tap route vanishes from the published tree and the route COUNT
/// stays a healthy 1. Neither the `> 1` arm nor the zero arm can see this.
Widget? _deadRowBuilder(
  BuildContext context,
  EdenNavItem item,
  EdenNavItemState state,
) {
  return IgnorePointer(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(item.icon, size: 22),
        const SizedBox(height: 4),
        Text(item.label, style: const TextStyle(fontSize: 11)),
      ],
    ),
  );
}

void main() {
  testWidgets(
    'case 1: the REAL bottom bar is named by no liveness rule',
    (WidgetTester tester) async {
      await _pumpShell(tester);
      final String? report = await _saneReport(tester);

      expect(
        report ?? '',
        isNot(contains('inert')),
        reason: 'the shipping renderer wraps each row in ExcludeSemantics, '
            'which removes the subtree from the SEMANTICS tree only — the '
            'GestureDetector under it still takes the pointer. A rule that '
            'names these rows would name every surface in the catalogue and '
            'case 2 would prove nothing.',
      );
    },
  );

  testWidgets(
    'case 2: a bottom bar whose rows refuse the pointer is REPORTED, not '
    'silently green',
    (WidgetTester tester) async {
      await _pumpShell(tester, itemBuilder: _deadRowBuilder);
      final String? report = await _saneReport(tester);

      expect(
        report,
        isNotNull,
        reason: 'every bottom-nav row announces button: true with a tap '
            'action and cannot be tapped. This is the surface on which the '
            'oracle used to print "All tests passed!".',
      );
      for (final EdenNavItem item in _navItems) {
        expect(
          report,
          contains('"eden-nav-${item.id}"'),
          reason: 'the report must NAME each dead row, not merely fail.',
        );
      }
      expect(report, contains('inert to a real tap'));
    },
  );

  testWidgets(
    'case 3: the dead bar is reported even though its route COUNT is one',
    (WidgetTester tester) async {
      await _pumpShell(tester, itemBuilder: _deadRowBuilder);
      final String? report = await _saneReport(tester);

      // The discriminator. IgnorePointer strips the inner route rather than
      // adding one, so the old `routes > 1` message must NOT appear — if it
      // did, case 2 would be passing for the wrong reason and the liveness
      // rule would be untested.
      expect(
        report,
        isNot(contains('declares 2 tap actions')),
        reason: 'IgnorePointer sets isBlockingUserActions, so the row publishes '
            'exactly ONE tap action. Reachability is the only arm that can '
            'see this defect.',
      );
    },
  );
}
