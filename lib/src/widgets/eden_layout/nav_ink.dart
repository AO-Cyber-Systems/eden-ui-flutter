import 'package:flutter/widgets.dart';

import '../../tokens/colors.dart';

/// The ink a glyph or a badge count takes when it sits ON a saturated fill —
/// the selected-state indicator's pill, or a nav badge.
///
/// ONE DEFINITION, FOUR SURFACES. The bottom bar, the drawer, the "More" sheet
/// and the desktop rail are four renderings of the same nav row, and every one
/// of them had at some point painted `Colors.white` on a coloured pill:
///
///   white on colorScheme.primary (gold #D4A853)   2.20:1 light, 2.33:1 dark
///   white on colorScheme.error   (red   #EF4444)  3.76:1 in both themes
///
/// all of them below WCAG 1.4.3's 4.5:1 floor for text under 14px bold, and
/// none of them reportable until `expectUiSane` learned to measure painted
/// text: a badge sits inside the row's `ExcludeSemantics`, so its string is
/// the label of no semantics node and `textContrastGuideline` never looks it
/// up. Four surfaces, four separate literals, one defect repeated.
///
/// `EdenColors.neutral[900]` and NOT `colorScheme.onSurface`: onSurface
/// inverts with the theme, and neutral[100] on gold[400] is 2.12:1 — the dark
/// theme would gain a new failure. This near-black clears the floor on every
/// fill either layout puts text on:
///
///   on colorScheme.primary   8.04:1 light, 7.61:1 dark (gold; worst preset
///                            is slate, still above the floor)
///   on colorScheme.error     4.71:1 in both themes
///
/// and 3:1 as a non-text glyph on every preset's fill (worst case slate at
/// 3.72:1).
///
/// A constant rather than a literal at each site because those four sites must
/// move together or they are back to disagreeing.
Color get edenNavOnFillInk => EdenColors.neutral[900]!;
