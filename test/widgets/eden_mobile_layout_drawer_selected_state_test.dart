// The mobile DRAWER's and "More" SHEET's selected state — the other two
// renderings of the same nav row.
//
// THE DEFECT THIS PINS. When the bottom bar's selected state was fixed
// (c828c87) the brand gold #D4A853 moved off the label and onto an indicator,
// because gold at fontSize 11 on the white bar measures 2.20:1 against WCAG
// 1.4.3's 4.5:1 floor. `_DrawerTile` and the "More" sheet's `ListTile` carried
// the IDENTICAL failure in the same file and were not touched:
//
//   drawer selected label   gold on the band #F6F2E9   1.97:1  (fontSize 14)
//   sheet  selected title   gold on #FAFAFA            2.11:1  (fontSize 16)
//   drawer avatar initials  gold on #F4EEE1            1.91:1  (fontSize 13)
//   drawer badge text       white on the gold fill     2.20:1  (fontSize 10)
//   sheet  badge text       white on the gold fill     2.20:1  (fontSize 11)
//
// and the app was left saying "selected" in two different languages on two
// surfaces a user reaches from the same bar.
//
// WHY THE ASSERTIONS ARE COMPUTED, NOT LITERAL. Asserting
// `color == colorScheme.onSurface` passes for any token that happens to be
// wired up, including the next low-contrast one. These cases compute the WCAG
// ratio from the colours actually resolved onto the widgets, against the
// surface actually resolved onto the drawer's / sheet's own `Material` — so
// the rule under test is the CONTRAST a user experiences, and it holds for
// every brand preset rather than just gold.
//
// AND WHY CASE 9 EXISTS. Every case below could be satisfied by giving the
// drawer a THIRD selection treatment of its own. Case 9 is what forbids that:
// the bar, the drawer and the sheet must resolve the same indicator colours.
library;

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_support/ui_oracle/wcag_contrast.dart';
import '../../test_support/ui_oracle/wrap.dart';

/// Six destinations: the bar holds four plus "More", and `billing`/`team`
/// overflow into the sheet. Badges on one bar-resident row and one overflow
/// row so both badge treatments are rendered.
const List<EdenNavItem> _navItems = <EdenNavItem>[
  EdenNavItem(id: 'home', label: 'Home', icon: Icons.home_outlined),
  EdenNavItem(
      id: 'orders',
      label: 'Orders',
      icon: Icons.receipt_long_outlined,
      badge: '3'),
  EdenNavItem(
      id: 'reports', label: 'Reports', icon: Icons.insert_chart_outlined),
  EdenNavItem(id: 'settings', label: 'Settings', icon: Icons.settings_outlined),
  EdenNavItem(
      id: 'billing',
      label: 'Billing',
      icon: Icons.credit_card,
      badge: '2'),
  EdenNavItem(id: 'team', label: 'Team', icon: Icons.group_outlined),
];

/// In the drawer: selected and badged. Also present in the bottom bar, which
/// is what lets case 9 read the bar's indicator from the same pumped tree.
const String _drawerSelected = 'Orders';

/// In the drawer: not selected, no badge.
const String _drawerUnselected = 'Home';

/// In the "More" sheet: selected and badged.
const String _sheetSelected = 'Billing';

/// In the "More" sheet: not selected, no badge.
const String _sheetUnselected = 'Team';

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
      body: const Text('Body'),
    ),
    width: 390,
    themeMode: themeMode,
  );
}

Future<void> _openDrawer(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Open navigation menu'));
  await tester.pumpAndSettle();
  expect(find.byType(Drawer), findsOneWidget,
      reason: 'the drawer must actually be open — every assertion below is '
          'about a surface that has to be on screen.');
}

Future<void> _openMoreSheet(WidgetTester tester) async {
  await tester.tap(find.text('More'));
  await tester.pumpAndSettle();
  expect(find.byType(BottomSheet), findsOneWidget,
      reason: 'the "More" sheet must actually be open.');
}

/// The colour the [Drawer]'s own `Material` resolves — NOT a repeat of
/// Material 3's default token, so a `drawerTheme` override in `EdenTheme`
/// would be measured rather than missed.
Color _surfaceOf(WidgetTester tester, Finder overlay) {
  final Material material = tester.widget<Material>(
    find.descendant(of: overlay, matching: find.byType(Material)).first,
  );
  final Color? colour = material.color;
  expect(colour, isNotNull,
      reason: 'the surface under test must paint an opaque colour, or there '
          'is no contrast ratio to measure.');
  return colour!;
}

/// The row whose label is [label], inside [overlay].
Finder _rowFor(Finder overlay, String label, Type rowType) => find
    .ancestor(
      of: find.descendant(of: overlay, matching: find.text(label)),
      matching: find.byType(rowType),
    )
    .first;

Color _labelColour(WidgetTester tester, Finder overlay, String label) {
  final Text text = tester.widget<Text>(
    find.descendant(of: overlay, matching: find.text(label)),
  );
  final Color? colour = text.style?.color;
  expect(colour, isNotNull,
      reason: 'the "$label" row must set its label colour EXPLICITLY — an '
          'inherited colour cannot be held to a floor here.');
  return colour!;
}

/// The selected-state indicator painted behind [row]'s glyph, or null when the
/// row paints none.
///
/// Located STRUCTURALLY — the stack that sits above the row's glyph and inside
/// the row — never by "the container that has a border", which would make
/// case 5's rim assertion unfalsifiable.
BoxDecoration? _indicatorFor(WidgetTester tester, Finder row) {
  final Finder glyph = find.descendant(of: row, matching: find.byType(Icon)).first;
  final Finder stack = find.ancestor(
    of: glyph,
    matching: find.descendant(of: row, matching: find.byType(Stack)),
  );
  if (stack.evaluate().isEmpty) {
    return null;
  }
  for (final Container container in tester.widgetList<Container>(
    find.descendant(of: stack.first, matching: find.byType(Container)),
  )) {
    final Decoration? decoration = container.decoration;
    if (decoration is BoxDecoration && decoration.color != null) {
      return decoration;
    }
  }
  return null;
}

/// The glyph colour of [row]'s leading icon.
Color _glyphColour(WidgetTester tester, Finder row) => tester
    .widget<Icon>(find.descendant(of: row, matching: find.byType(Icon)).first)
    .color!;

/// (fill, rim) of a selected row's indicator — the pair that has to agree
/// across all three surfaces.
(Color, Color) _indicatorColours(WidgetTester tester, Finder row) {
  final BoxDecoration indicator = _indicatorFor(tester, row)!;
  return (indicator.color!, indicator.border!.top.color);
}

void main() {
  for (final (String mode, ThemeMode themeMode) in <(String, ThemeMode)>[
    ('light', ThemeMode.light),
    ('dark', ThemeMode.dark),
  ]) {
    // -----------------------------------------------------------------------
    // Drawer
    // -----------------------------------------------------------------------

    testWidgets(
      'case 1 ($mode): the SELECTED drawer label clears WCAG AA 4.5:1 on the '
      'drawer',
      (WidgetTester tester) async {
        await _pumpShell(tester, themeMode: themeMode, selectedId: 'orders');
        await _openDrawer(tester);
        final Finder drawer = find.byType(Drawer);
        expect(
          wcagContrastRatio(
            _labelColour(tester, drawer, _drawerSelected),
            _surfaceOf(tester, drawer),
          ),
          greaterThanOrEqualTo(4.5),
          reason: 'the selected drawer label was the brand gold on a 10% gold '
              'band: 1.97:1 at fontSize 14, which is not large text. The '
              'indicator carries the state; the label takes normal text '
              'colour, exactly as the bar does.',
        );
      },
    );

    testWidgets(
      'case 2 ($mode): the UNSELECTED drawer label clears 4.5:1 too',
      (WidgetTester tester) async {
        await _pumpShell(tester, themeMode: themeMode, selectedId: 'orders');
        await _openDrawer(tester);
        final Finder drawer = find.byType(Drawer);
        expect(
          wcagContrastRatio(
            _labelColour(tester, drawer, _drawerUnselected),
            _surfaceOf(tester, drawer),
          ),
          greaterThanOrEqualTo(4.5),
          reason: 'onSurface on the drawer passes today and must keep '
              'passing — a fix to the selected row cannot be traded against '
              'the unselected one.',
        );
      },
    );

    testWidgets(
      'case 3 ($mode): the SELECTED drawer row paints an indicator in the '
      'brand colour',
      (WidgetTester tester) async {
        await _pumpShell(tester, themeMode: themeMode, selectedId: 'orders');
        await _openDrawer(tester);
        final ThemeData theme = Theme.of(tester.element(find.byType(Drawer)));
        final BoxDecoration? indicator = _indicatorFor(
          tester,
          _rowFor(find.byType(Drawer), _drawerSelected, GestureDetector),
        );
        expect(indicator, isNotNull,
            reason: 'taking the gold off the drawer label without putting an '
                'indicator back deletes the selected state from the drawer.');
        expect(indicator!.color, theme.colorScheme.primary,
            reason: 'full saturation, same as the bar — the brand moves role, '
                'it is not diluted to a 10% band.');
      },
    );

    testWidgets(
      'case 4 ($mode): an UNSELECTED drawer row paints no indicator',
      (WidgetTester tester) async {
        await _pumpShell(tester, themeMode: themeMode, selectedId: 'orders');
        await _openDrawer(tester);
        expect(
          _indicatorFor(
            tester,
            _rowFor(find.byType(Drawer), _drawerUnselected, GestureDetector),
          ),
          isNull,
          reason: 'an indicator on every row indicates nothing. This is the '
              'differential control for case 3.',
        );
      },
    );

    testWidgets(
      'case 5 ($mode): the drawer indicator is identifiable against the '
      'drawer at 3:1',
      (WidgetTester tester) async {
        await _pumpShell(tester, themeMode: themeMode, selectedId: 'orders');
        await _openDrawer(tester);
        final Finder drawer = find.byType(Drawer);
        final BoxDecoration indicator = _indicatorFor(
          tester,
          _rowFor(drawer, _drawerSelected, GestureDetector),
        )!;
        // WCAG 1.4.11: 3:1 for the visual information identifying a
        // component's STATE, against the ADJACENT colour. The gold fill is
        // 2.11:1 on the light drawer and never clears it; the rim does.
        final Color edge = indicator.border?.top.color ?? indicator.color!;
        expect(
          wcagContrastRatio(edge, _surfaceOf(tester, drawer)),
          greaterThanOrEqualTo(3.0),
          reason: 'the pill must be distinguishable from the drawer it sits '
              'on — measured, because the fill alone is not.',
        );
      },
    );

    testWidgets(
      'case 6 ($mode): the drawer glyph on the indicator clears 3:1 against '
      'its fill',
      (WidgetTester tester) async {
        await _pumpShell(tester, themeMode: themeMode, selectedId: 'orders');
        await _openDrawer(tester);
        final Finder row =
            _rowFor(find.byType(Drawer), _drawerSelected, GestureDetector);
        expect(
          wcagContrastRatio(
            _glyphColour(tester, row),
            _indicatorFor(tester, row)!.color!,
          ),
          greaterThanOrEqualTo(3.0),
          reason: 'the glyph sits ON the pill now. Inheriting onSurface here '
              'would be neutral[100] on gold[400] — 2.12:1 — a new dark-theme '
              'failure.',
        );
      },
    );

    testWidgets(
      'case 7 ($mode): the drawer badge text clears 4.5:1 on its own fill',
      (WidgetTester tester) async {
        await _pumpShell(tester, themeMode: themeMode, selectedId: 'orders');
        await _openDrawer(tester);
        final Finder row =
            _rowFor(find.byType(Drawer), _drawerSelected, GestureDetector);
        final Container badge = tester.widgetList<Container>(
          find.descendant(of: row, matching: find.byType(Container)),
        ).lastWhere((Container c) =>
            c.decoration is BoxDecoration &&
            (c.decoration! as BoxDecoration).color != null);
        final Text text =
            tester.widget<Text>(find.descendant(of: row, matching: find.text('3')));
        expect(
          wcagContrastRatio(
            text.style!.color!,
            (badge.decoration! as BoxDecoration).color!,
          ),
          greaterThanOrEqualTo(4.5),
          reason: 'the badge was Colors.white on the gold fill: 2.20:1 light, '
              '2.33:1 dark, at fontSize 10. Same defect class as the label, '
              'and invisible for the same reason.',
        );
      },
    );

    // -----------------------------------------------------------------------
    // "More" sheet
    // -----------------------------------------------------------------------

    testWidgets(
      'case 8a ($mode): the SELECTED sheet title clears WCAG AA 4.5:1 on the '
      'sheet',
      (WidgetTester tester) async {
        await _pumpShell(tester, themeMode: themeMode, selectedId: 'billing');
        await _openMoreSheet(tester);
        final Finder sheet = find.byType(BottomSheet);
        expect(
          wcagContrastRatio(
            _labelColour(tester, sheet, _sheetSelected),
            _surfaceOf(tester, sheet),
          ),
          greaterThanOrEqualTo(4.5),
          reason: 'the selected sheet row was brand gold at the ListTile\'s '
              'fontSize 16 on #FAFAFA: 2.11:1.',
        );
      },
    );

    testWidgets(
      'case 8b ($mode): the UNSELECTED sheet title clears 4.5:1 too',
      (WidgetTester tester) async {
        await _pumpShell(tester, themeMode: themeMode, selectedId: 'billing');
        await _openMoreSheet(tester);
        final Finder sheet = find.byType(BottomSheet);
        expect(
          wcagContrastRatio(
            _labelColour(tester, sheet, _sheetUnselected),
            _surfaceOf(tester, sheet),
          ),
          greaterThanOrEqualTo(4.5),
        );
      },
    );

    testWidgets(
      'case 8c ($mode): the SELECTED sheet row paints the indicator, an '
      'UNSELECTED one does not',
      (WidgetTester tester) async {
        await _pumpShell(tester, themeMode: themeMode, selectedId: 'billing');
        await _openMoreSheet(tester);
        final Finder sheet = find.byType(BottomSheet);
        final ThemeData theme = Theme.of(tester.element(sheet));
        final BoxDecoration? indicator = _indicatorFor(
          tester,
          _rowFor(sheet, _sheetSelected, ListTile),
        );
        expect(indicator, isNotNull);
        expect(indicator!.color, theme.colorScheme.primary);
        expect(
          _indicatorFor(tester, _rowFor(sheet, _sheetUnselected, ListTile)),
          isNull,
          reason: 'differential control: an indicator on every sheet row '
              'indicates nothing.',
        );
      },
    );

    testWidgets(
      'case 8d ($mode): the sheet indicator clears 3:1 on the sheet and its '
      'glyph clears 3:1 on the fill',
      (WidgetTester tester) async {
        await _pumpShell(tester, themeMode: themeMode, selectedId: 'billing');
        await _openMoreSheet(tester);
        final Finder sheet = find.byType(BottomSheet);
        final Finder row = _rowFor(sheet, _sheetSelected, ListTile);
        final BoxDecoration indicator = _indicatorFor(tester, row)!;
        expect(
          wcagContrastRatio(
            indicator.border?.top.color ?? indicator.color!,
            _surfaceOf(tester, sheet),
          ),
          greaterThanOrEqualTo(3.0),
        );
        expect(
          wcagContrastRatio(_glyphColour(tester, row), indicator.color!),
          greaterThanOrEqualTo(3.0),
        );
      },
    );

    testWidgets(
      'case 8e ($mode): the sheet badge text clears 4.5:1 on its own fill',
      (WidgetTester tester) async {
        await _pumpShell(tester, themeMode: themeMode, selectedId: 'billing');
        await _openMoreSheet(tester);
        final Finder row =
            _rowFor(find.byType(BottomSheet), _sheetSelected, ListTile);
        final Container badge = tester.widgetList<Container>(
          find.descendant(of: row, matching: find.byType(Container)),
        ).lastWhere((Container c) =>
            c.decoration is BoxDecoration &&
            (c.decoration! as BoxDecoration).color != null);
        final Text text = tester
            .widget<Text>(find.descendant(of: row, matching: find.text('2')));
        expect(
          wcagContrastRatio(
            text.style!.color!,
            (badge.decoration! as BoxDecoration).color!,
          ),
          greaterThanOrEqualTo(4.5),
        );
      },
    );

    // -----------------------------------------------------------------------
    // One selection language
    // -----------------------------------------------------------------------

    // ONE PUMP PER CASE, deliberately. Re-pumping inside a test does NOT
    // reset the shell: the Scaffold keeps its state (an open drawer stays
    // open) and a pushed sheet route outlives the rebuild, so a second
    // interaction taps a scrim instead of a control — and `tap` only WARNS
    // when it misses. Each case opens exactly one overlay.

    testWidgets(
      'case 9a ($mode): the drawer paints the SAME indicator as the bar',
      (WidgetTester tester) async {
        // `orders` is a bar destination AND a drawer row, so both indicators
        // exist in one tree.
        await _pumpShell(tester, themeMode: themeMode, selectedId: 'orders');
        final (Color, Color) bar = _indicatorColours(
          tester,
          _rowFor(find.byType(Scaffold), _drawerSelected, Column),
        );
        await _openDrawer(tester);
        final (Color, Color) drawer = _indicatorColours(
          tester,
          _rowFor(find.byType(Drawer), _drawerSelected, GestureDetector),
        );
        expect(drawer, bar,
            reason: 'the drawer and the bar must not say "selected" in two '
                'different languages in one app. THIS is the case that failed '
                'silently for as long as the drawer was never rendered under '
                'a test.');
      },
    );

    testWidgets(
      'case 9b ($mode): the "More" sheet paints the SAME indicator as the bar',
      (WidgetTester tester) async {
        // `billing` lives in the overflow, so the bar's selected tab is the
        // "More" tab itself — the same indicator, read before the sheet
        // covers it.
        await _pumpShell(tester, themeMode: themeMode, selectedId: 'billing');
        final (Color, Color) bar = _indicatorColours(
          tester,
          _rowFor(find.byType(Scaffold), 'More', Column),
        );
        await _openMoreSheet(tester);
        final (Color, Color) sheet = _indicatorColours(
          tester,
          _rowFor(find.byType(BottomSheet), _sheetSelected, ListTile),
        );
        expect(sheet, bar,
            reason: 'the "More" sheet is the same nav row a third time and '
                'may not invent a third treatment either.');
      },
    );
  }
}
