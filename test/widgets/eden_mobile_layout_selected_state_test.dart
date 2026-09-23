// The mobile bottom bar's SELECTED state — where the brand colour is allowed
// to live.
//
// THE DEFECT THIS PINS. The selected tab's label was painted in the brand
// gold, `EdenColors.gold` #D4A853, at fontSize 11 on the bar's white surface:
// 2.20:1 against a 4.5:1 requirement. `expectUiSane` caught it on
// `mobile-layout/default — light` and it is a genuine WCAG 1.4.3 failure, not
// an oracle artefact. The UNSELECTED label is `onSurfaceVariant`
// (neutral[500] #71717A) at 4.83:1 and was never the defect — measured, not
// assumed.
//
// THE RULING. The gold does not change and is not darkened — it moves OFF the
// text. The selected state is carried by an INDICATOR (a filled pill behind
// the icon) in brand gold at full saturation, and the label takes the normal
// dark text colour. That keeps the brand where it is visible and takes it out
// of the one role it cannot hold.
//
// WHY THE ASSERTIONS ARE COMPUTED, NOT LITERAL. Asserting
// `color == colorScheme.onSurface` would pass for any token that happens to
// be wired up, including the next low-contrast one. These cases compute the
// WCAG ratio from the colours actually resolved onto the widgets, so the rule
// under test is the CONTRAST — which is what a user experiences — and it
// holds for every brand preset, not just gold.
//
// AND WHY THE INDICATOR IS ASSERTED TOO. Moving the colour off the label and
// putting nothing back would also satisfy the contrast cases, and would
// delete the selected state from the bar. Cases 3-5 are what stops that
// "fix".
library;

import 'dart:math' as math;

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const List<EdenNavItem> _navItems = <EdenNavItem>[
  EdenNavItem(id: 'home', label: 'Home', icon: Icons.home),
  EdenNavItem(id: 'orders', label: 'Orders', icon: Icons.receipt_long),
  EdenNavItem(id: 'reports', label: 'Reports', icon: Icons.bar_chart),
];

const String _selected = 'Orders';
const String _unselected = 'Home';

/// WCAG 2.x relative luminance, written out from the spec rather than read
/// off the code under test.
double _relativeLuminance(Color colour) {
  double channel(double c) =>
      c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(colour.r) +
      0.7152 * channel(colour.g) +
      0.0722 * channel(colour.b);
}

double _contrastRatio(Color a, Color b) {
  final double la = _relativeLuminance(a);
  final double lb = _relativeLuminance(b);
  final double hi = math.max(la, lb);
  final double lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

Future<void> _pump(WidgetTester tester, ThemeData theme) async {
  await tester.pumpWidget(MaterialApp(
    theme: theme,
    home: EdenMobileLayout(
      navItems: _navItems,
      selectedId: 'orders',
      onNavChanged: (_) {},
      body: const Text('Body'),
    ),
  ));
  await tester.pumpAndSettle();
}

Color _labelColour(WidgetTester tester, String label) {
  final Text text = tester.widget<Text>(find.text(label));
  final Color? colour = text.style?.color;
  expect(
    colour,
    isNotNull,
    reason: 'the "$label" tab label must set its colour explicitly — an '
        'inherited one cannot be held to a contrast floor here.',
  );
  return colour!;
}

/// The first decorated [Container] inside the tab that renders [label] — the
/// selected-state indicator, or null when the tab paints none.
BoxDecoration? _indicatorFor(WidgetTester tester, String label) {
  final Finder tab =
      find.ancestor(of: find.text(label), matching: find.byType(Column)).first;
  for (final Container container in tester.widgetList<Container>(
    find.descendant(of: tab, matching: find.byType(Container)),
  )) {
    final Decoration? decoration = container.decoration;
    if (decoration is BoxDecoration && decoration.color != null) {
      return decoration;
    }
  }
  return null;
}

void main() {
  for (final (String mode, ThemeData Function() build) in <(
    String,
    ThemeData Function()
  )>[
    ('light', EdenTheme.light),
    ('dark', EdenTheme.dark),
  ]) {
    final ThemeData theme = build();
    final Color bar = theme.colorScheme.surface;

    testWidgets(
      'case 1 ($mode): the SELECTED tab label clears WCAG AA 4.5:1 on the bar',
      (WidgetTester tester) async {
        await _pump(tester, theme);
        final Color label = _labelColour(tester, _selected);
        expect(
          _contrastRatio(label, bar),
          greaterThanOrEqualTo(4.5),
          reason: 'the selected label was the brand gold #D4A853 at 2.20:1 on '
              'white. fontSize 11 is not large text, so 4.5:1 is the floor. '
              'Paint the selected state with the indicator instead.',
        );
      },
    );

    testWidgets(
      'case 2 ($mode): the UNSELECTED tab label clears WCAG AA 4.5:1 too',
      (WidgetTester tester) async {
        await _pump(tester, theme);
        final Color label = _labelColour(tester, _unselected);
        expect(
          _contrastRatio(label, bar),
          greaterThanOrEqualTo(4.5),
          reason: 'onSurfaceVariant measures 4.83:1 on white and 6.91:1 on the '
              'dark bar — it passes today and must keep passing, so a fix to '
              'the selected label cannot be traded against it.',
        );
      },
    );

    testWidgets(
      'case 3 ($mode): the SELECTED tab paints an indicator in the brand '
      'colour',
      (WidgetTester tester) async {
        await _pump(tester, theme);
        final BoxDecoration? indicator = _indicatorFor(tester, _selected);
        expect(
          indicator,
          isNotNull,
          reason: 'taking the gold off the label without putting an indicator '
              'back deletes the selected state from the bar. The state has to '
              'be carried by something.',
        );
        expect(
          indicator!.color,
          theme.colorScheme.primary,
          reason: 'the brand colour stays at FULL saturation — it moves role, '
              'it is not darkened. EdenColors.gold is unchanged.',
        );
      },
    );

    testWidgets(
      'case 4 ($mode): an UNSELECTED tab paints no indicator',
      (WidgetTester tester) async {
        await _pump(tester, theme);
        expect(
          _indicatorFor(tester, _unselected),
          isNull,
          reason: 'an indicator on every tab indicates nothing. This is the '
              'differential control for case 3.',
        );
      },
    );

    testWidgets(
      'case 5 ($mode): the indicator is identifiable against the bar at 3:1',
      (WidgetTester tester) async {
        await _pump(tester, theme);
        final BoxDecoration indicator = _indicatorFor(tester, _selected)!;
        // WCAG 1.4.11 Non-text Contrast: 3:1 for the visual information that
        // identifies a component's STATE, against ADJACENT colour.
        //
        // The fill alone cannot carry this in the light theme: gold #D4A853
        // on the white bar is 2.20:1, and no shade of the brand that stays
        // #D4A853 ever will. The pill's BOUNDARY is what has to clear it, and
        // 1.4.11 is satisfied by a boundary that does — which is why the
        // border is load-bearing and not decoration.
        final Color edge = indicator.border?.top.color ?? indicator.color!;
        expect(
          _contrastRatio(edge, bar),
          greaterThanOrEqualTo(3.0),
          reason: 'the pill must be distinguishable from the bar it sits on. '
              'Measured: the gold FILL is 2.20:1 on the light bar (fails) and '
              '7.61:1 on the dark one; the boundary clears 3:1 in both.',
        );
      },
    );

    testWidgets(
      'case 6 ($mode): the icon on the indicator clears 3:1 against its fill',
      (WidgetTester tester) async {
        await _pump(tester, theme);
        final BoxDecoration indicator = _indicatorFor(tester, _selected)!;
        final Icon icon = tester.widget<Icon>(
          find
              .descendant(
                of: find
                    .ancestor(
                        of: find.text(_selected), matching: find.byType(Column))
                    .first,
                matching: find.byType(Icon),
              )
              .first,
        );
        expect(
          _contrastRatio(icon.color!, indicator.color!),
          greaterThanOrEqualTo(3.0),
          reason: 'the glyph sits ON the pill now, not on the bar. A near-'
              'white icon on gold[400] measures 2.12:1 in the dark theme, so '
              'inheriting onSurface here would have been a new failure.',
        );
      },
    );
  }
}
