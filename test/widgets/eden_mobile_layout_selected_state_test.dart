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

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_support/ui_oracle/wcag_contrast.dart';

const List<EdenNavItem> _navItems = <EdenNavItem>[
  EdenNavItem(id: 'home', label: 'Home', icon: Icons.home),
  // Badged, so case 7 has a bar badge to measure. The bar's badge is the
  // ERROR-token one — a different pair from the gold badges the drawer and
  // the sheet carry.
  EdenNavItem(
      id: 'orders', label: 'Orders', icon: Icons.receipt_long, badge: '3'),
  EdenNavItem(id: 'reports', label: 'Reports', icon: Icons.bar_chart),
];

const String _selected = 'Orders';
const String _unselected = 'Home';

// The WCAG arithmetic moved to `test_support/ui_oracle/wcag_contrast.dart`
// when the drawer and the "More" sheet were held to the same floor: three
// renderings of one nav row, and two copies of the formula would be two
// places for the floor to drift. It is still written out FROM THE SPEC and
// still depends on nothing in `lib/` — see that file's header.

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
          wcagContrastRatio(label, bar),
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
          wcagContrastRatio(label, bar),
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
          wcagContrastRatio(edge, bar),
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
          wcagContrastRatio(icon.color!, indicator.color!),
          greaterThanOrEqualTo(3.0),
          reason: 'the glyph sits ON the pill now, not on the bar. A near-'
              'white icon on gold[400] measures 2.12:1 in the dark theme, so '
              'inheriting onSurface here would have been a new failure.',
        );
      },
    );

    testWidgets(
      'case 7 ($mode): the bar badge text clears 4.5:1 on its own fill',
      (WidgetTester tester) async {
        await _pump(tester, theme);
        // The badge is the last decorated Container inside the selected tab's
        // column — the indicator pill is the other one, and it comes first.
        final Finder column = find
            .ancestor(of: find.text(_selected), matching: find.byType(Column))
            .first;
        final Container badge = tester
            .widgetList<Container>(
              find.descendant(of: column, matching: find.byType(Container)),
            )
            .lastWhere((Container c) =>
                c.decoration is BoxDecoration &&
                (c.decoration! as BoxDecoration).color != null);
        final Text text = tester.widget<Text>(
          find.descendant(of: column, matching: find.text('3')),
        );
        expect(
          wcagContrastRatio(
            text.style!.color!,
            (badge.decoration! as BoxDecoration).color!,
          ),
          greaterThanOrEqualTo(4.5),
          reason: 'the bar badge was Colors.white on colorScheme.error — '
              '3.76:1 in BOTH themes at fontSize 9, since #EF4444 is the error '
              'token in each. A DIFFERENT token pair from the gold defect the '
              'drawer and the sheet carried, and unreportable for the same '
              'reason: the badge sits inside the row\'s ExcludeSemantics.',
        );
      },
    );

    testWidgets(
      'case 7b ($mode): the bar badge FILL stays identifiable on the bar',
      (WidgetTester tester) async {
        await _pump(tester, theme);
        final Finder column = find
            .ancestor(of: find.text(_selected), matching: find.byType(Column))
            .first;
        final Container badge = tester
            .widgetList<Container>(
              find.descendant(of: column, matching: find.byType(Container)),
            )
            .lastWhere((Container c) =>
                c.decoration is BoxDecoration &&
                (c.decoration! as BoxDecoration).color != null);
        // THE DIFFERENTIAL CONTROL for case 7. Fixing the text by darkening
        // the FILL instead — red[700] #B91C1C would give white 6.47:1 — also
        // satisfies case 7 and quietly breaks the badge's own 1.4.11 contrast
        // against the dark theme's bar: 2.74:1 against neutral[900], where
        // colorScheme.error is 4.71:1. This case is what stops that "fix",
        // and it is why the remedy was the glyph and not the token.
        expect(
          wcagContrastRatio((badge.decoration! as BoxDecoration).color!, bar),
          greaterThanOrEqualTo(3.0),
          reason: 'a count nobody can find on the bar is not a count. '
              'colorScheme.error measures 3.76:1 on the white bar and 4.71:1 '
              'on the dark one.',
        );
      },
    );
  }
}
