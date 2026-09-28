import 'package:flutter/material.dart';

import '../../tokens/radii.dart';
import 'nav_ink.dart';

/// Paints the nav shell's "this row is selected" indicator behind [child].
///
/// ONE DEFINITION, FOUR SURFACES. The bottom bar, the drawer, the "More"
/// sheet and the desktop rail are four renderings of the same nav row, and
/// for a while every one of them disagreed about what selected looks like.
/// The mobile three were unified first — this class used to be
/// `_NavSelectionIndicator`, private to `eden_mobile_layout.dart` — while the
/// rail kept a separate, unaudited mechanism: a `primary@0.1` band with no
/// rim, which measures 1.07:1 light / 1.18:1 dark against the rail's own
/// fill (eden-ui-flutter#58 code review). That is how this regression got
/// in: the ink WAS unified across four surfaces (`nav_ink.dart`, two files
/// over) and the INDICATOR was not. Promoting this widget out of the mobile
/// layout and adopting it on the rail closes that gap — a change to the
/// indicator is now a change everywhere, and a surface that opts out has to
/// say so at its call site.
///
/// The pill is [Positioned] with NEGATIVE insets inside a [Clip.none] stack,
/// so it paints around the glyph without taking part in layout. That is
/// measured, not stylistic — an indicator that sized the bottom bar's column
/// overflowed the bar's fixed 60px by 7px (see `_BottomItem` in
/// `eden_mobile_layout.dart`). [inset] is how far the pill extends beyond
/// the glyph on each side, so each surface sizes it to its own glyph without
/// duplicating the mechanism.
///
/// The rim is load-bearing. WCAG 1.4.11 asks 3:1 for the visual information
/// that identifies a component's state, against the ADJACENT colour, and in
/// the light theme the gold fill never clears it (2.11:1 on the drawer,
/// 2.20:1 on the bar, 2.20:1 on the rail). `onPrimaryContainer` does, for
/// every EdenColors preset and in both themes — gold 7.14-7.45, blue
/// 8.88-10.36, emerald 8.53-9.72, purple 9.28-10.88, red 8.46-10.02, slate
/// 15.21-17.85 across the light surfaces; 12.5-15.8 across the dark ones.
///
/// KEYED, not found by type. `EdenNavSelectionIndicator` is library-private
/// — not exported from `eden_ui.dart` or `eden_layout_exports.dart` — so a
/// test cannot reach it with `find.byType` without exporting it into every
/// consumer's graph. `ValueKey<String>('eden-nav-selection-indicator')` on
/// the pill's own `Container`, and NOT on the outer `Stack` (present on
/// every row, selected or not — keying it would match all of them and the
/// cardinality check below would assert nothing), is how
/// `test/ui_oracle/desktop_rail_contrast_test.dart` names it — the same
/// device `eden-appointment-status-dot` already uses.
class EdenNavSelectionIndicator extends StatelessWidget {
  const EdenNavSelectionIndicator({
    super.key,
    required this.isSelected,
    required this.inset,
    required this.child,
  });

  /// Whether to paint the indicator at all. An indicator on every row
  /// indicates nothing, so this is never defaulted.
  final bool isSelected;

  /// How far the pill extends BEYOND [child] on each side, in logical
  /// pixels.
  final EdgeInsets inset;

  /// The glyph the indicator sits behind. Sizes the stack; the pill does
  /// not.
  final Widget child;

  /// The colour a glyph takes when it sits ON the indicator's fill.
  ///
  /// `EdenColors.neutral[900]` and NOT `colorScheme.onSurface`: onSurface
  /// inverts with the theme, and neutral[100] on gold[400] is 2.12:1 — the
  /// dark theme would gain a new failure. A near-black glyph clears 3:1 on
  /// every preset's fill (worst case slate at 3.72:1) and 4.5:1 as text on
  /// the badge (worst case slate, still above the floor).
  ///
  /// One getter rather than a literal at each site: the bar, the drawer
  /// tile, the sheet row, the rail tile and all four badges must move
  /// together or they are back to disagreeing. Defined in `nav_ink.dart`
  /// because the desktop rail — a different file — needed to reach it too.
  static Color get selectedGlyph => edenNavOnFillInk;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (isSelected)
          Positioned(
            left: -inset.left,
            right: -inset.right,
            top: -inset.top,
            bottom: -inset.bottom,
            child: Container(
              key: const ValueKey<String>('eden-nav-selection-indicator'),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                border: Border.all(
                  color: theme.colorScheme.onPrimaryContainer,
                  width: 1.5,
                ),
                borderRadius: EdenRadii.borderRadiusFull,
              ),
            ),
          ),
        child,
      ],
    );
  }
}
