// The top bar's search control, held to the WCAG 2.5.8 pointer floor the UI
// Oracle asserts on a `pointer` surface.
//
// THE DEFECT THIS PINS. The visible affordance is a 36px-tall rounded pill
// (`Container(height: 36)`), but the `Semantics(identifier:
// 'eden-topbar-search')` wrapper sat INSIDE it, around only the inner
// `TextField` — which carries `isDense: true`, `contentPadding: zero` and
// `fontSize: 13`, so it collapsed to the ~21px text line. The oracle read the
// node as `Size(813.1, 21.0)` and failed it under even the 24x24 pointer
// floor, while the thing a user sees and clicks was 36px tall all along.
//
// Same class as aodex#544 — a semantics node disagreeing with the visible
// control — pointing the other way: there the node was too large and
// swallowed a sibling, here it was too small and under-reported the target.
//
// CASE 2 IS THE ONE THAT MATTERS. Growing a semantics rect is trivial and
// useless: a `SizedBox` without `HitTestBehavior.opaque` around a smaller
// child publishes a 44px rect over a 20px hit target, which DEFEATS the
// oracle rather than satisfying it. A rect that lies is worse than the small
// rect it replaced. Case 2 therefore taps at the very top edge of the
// published rect — outside the old 21px line box — and requires the field to
// actually take focus there.
library;

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:eden_ui_flutter/testing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG 2.5.8 Target Size (Minimum), AA — the floor a `pointer` surface is
/// held to by `expectUiSane`.
const double kPointerTargetFloor = 24;

const EdenTopBarConfig _topBar = EdenTopBarConfig(
  title: 'Orders',
  showSearch: true,
  searchHint: 'Search orders…',
);

Future<void> _pumpShell(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(1280, 800);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(MaterialApp(
    theme: EdenTheme.light(),
    home: EdenDesktopLayout(
      navItems: const <EdenNavItem>[
        EdenNavItem(id: 'orders', label: 'Orders', icon: Icons.receipt_long),
      ],
      selectedId: 'orders',
      onNavChanged: (_) {},
      topBar: _topBar,
      body: const SizedBox(),
    ),
  ));
  await tester.pumpAndSettle();
}

Rect _searchNodeRect(WidgetTester tester) {
  final List<SemanticsGeometryNode> nodes = identifiedNodes(tester);
  final SemanticsGeometryNode node = nodes.singleWhere(
    (SemanticsGeometryNode n) => n.identifier == 'eden-topbar-search',
    orElse: () => fail(
      'no semantics node with identifier "eden-topbar-search" — the probe and '
      'its consumers key off that identifier and it must survive any fix. '
      'Nodes present: ${nodes.map((SemanticsGeometryNode n) => n.identifier)}',
    ),
  );
  return node.globalRect;
}

void main() {
  testWidgets(
    "case 1: the search control's semantics node clears the 24x24 pointer "
    'floor',
    (WidgetTester tester) async {
      await _pumpShell(tester);
      final Rect rect = _searchNodeRect(tester);

      expect(
        rect.height,
        greaterThanOrEqualTo(kPointerTargetFloor),
        reason: 'the node published for "eden-topbar-search" is $rect. The '
            'control a user sees is the 36px pill around it, so a node '
            'shorter than the ${kPointerTargetFloor}px floor is the node '
            'disagreeing with the control, not a control that is too small.',
      );
    },
  );

  testWidgets(
    'case 2: the published rect IS the tap target — a tap at its top edge '
    'focuses the field',
    (WidgetTester tester) async {
      await _pumpShell(tester);
      final Rect rect = _searchNodeRect(tester);

      expect(
        tester.testTextInput.isVisible,
        isFalse,
        reason: 'nothing should be focused before the tap',
      );

      // Two logical pixels inside the TOP edge of the published rect. Under
      // the defect this point sits above the 21px line box entirely; a fix
      // that only grows the rect leaves it landing on nothing.
      await tester.tapAt(Offset(rect.center.dx, rect.top + 2));
      await tester.pumpAndSettle();

      expect(
        tester.testTextInput.isVisible,
        isTrue,
        reason: 'tapping inside the rect the accessibility tree publishes for '
            '"eden-topbar-search" ($rect) did not focus the field. The node is '
            'claiming area it does not actually own — on web the semantics '
            'node IS the click target, so this rect would swallow clicks and '
            'do nothing with them.',
      );
    },
  );
}
