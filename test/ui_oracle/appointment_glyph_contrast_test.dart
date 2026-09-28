// The two `EdenAppointmentList` glyphs that carry a SEMANTIC hue, measured
// against the surface they are painted on rather than pinned to a hex.
//
// WHY THIS FILE EXISTS. eden-ui-flutter#55 started as one nav icon and turned
// out to be a property of the palette: Eden's hues are tuned against the DARK
// surface, and the same token painted as a GLYPH on the light one lands at
// roughly 2:1 every time. Three components, three hues, three surfaces, all
// within 0.06 of each other:
//
//   desktop rail, selected nav icon   #D4A853 on the 10% band   2.05:1 light
//   appointment status dot            #10B981 on the chip fill  2.00:1 light
//   truncation-notice icon            #F59E0B on the footer     2.06:1 light
//
// and 6.47 / 5.87 / 8.25 in dark, which is why every one of them read as fine.
// WCAG 1.4.11's floor for non-text is 3:1.
//
// THE TWO HERE ARE ARGUABLY EXEMPT AND ARE PINNED ANYWAY. 1.4.11 does not bind
// a graphic that is purely decorative or fully redundant with adjacent text,
// and both of these sit beside a word that says the same thing. That exemption
// is exactly why a per-instance ruling is the wrong shape: whether the next
// glyph someone adds happens to sit next to explanatory text is not a property
// the palette can know, and the glyph starts at ~2:1 either way. `EdenGlyphInk`
// is the token that stops it; these are the assertions that notice when it
// stops being used.
//
// COMPUTED, NOT PINNED. Each case takes the ink from the resolved widget, the
// SURFACE from the rasterised frame, and computes the WCAG ratio.
// `expect(dot.color, <hex>)` is green whether the chip behind it is
// `surfaceContainerHigh` or black; it is a spelling check. The number is the
// assertion.
//
// THE STORIES, NOT A HAND-BUILT FIXTURE. These pump the same registered
// stories the goldens are blessed from, so the surface measured here and the
// surface pinned there cannot drift apart.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eden_ui_flutter/dev_app/registry/eden_story.dart';

import '../../test_support/ui_oracle/measure_ink.dart';
import '../../test_support/ui_oracle/story_harness.dart';
import '../../test_support/ui_oracle/wrap.dart';

/// WCAG 1.4.11: 3:1 for non-text content that carries information.
const double _kNonTextFloor = 3.0;

void main() {
  ensureStoriesRegistered();

  for (final (String mode, ThemeMode themeMode) in <(String, ThemeMode)>[
    ('light', ThemeMode.light),
    ('dark', ThemeMode.dark),
  ]) {
    testWidgets(
        'the appointment STATUS DOT clears the non-text floor against the '
        'chip it sits on ($mode)', (WidgetTester tester) async {
      final EdenStory story = storyById('list-appointments/populated');
      await wrap(
        tester,
        Builder(
          builder: (BuildContext context) =>
              story.build(context, story.defaultKnobValues),
        ),
        width: storyViewportWidth(story, null),
        themeMode: themeMode,
      );

      final Finder dot =
          find.byKey(const ValueKey<String>('eden-appointment-status-dot'));
      expect(dot, findsWidgets,
          reason: 'the fixture must actually render a status dot, or this '
              'run reports on nothing.');

      // 2.00:1 light / 5.87:1 dark before #55; 4.32:1 / 5.87:1 after. The
      // dark tone is UNCHANGED — the base hue already cleared the floor
      // there, and a single tone that clears both themes does not exist in
      // the emerald ramp (emerald[600] is 2.97:1 light, emerald[700] is
      // 2.72:1 dark). That is why `EdenGlyphInk` is a brightness-split pair.
      await expectInkContrast(
        tester,
        dot.first,
        decorationInk(tester, dot.first),
        floor: _kNonTextFloor,
        what: 'the appointment status dot (WCAG 1.4.11, non-text)',
      );
    });

    testWidgets(
        'the TRUNCATION NOTICE icon clears the non-text floor against the '
        'footer it sits on ($mode)', (WidgetTester tester) async {
      final EdenStory story = storyById('list-appointments/large-truncated');
      await wrap(
        tester,
        Builder(
          builder: (BuildContext context) =>
              story.build(context, story.defaultKnobValues),
        ),
        width: storyViewportWidth(story, null),
        themeMode: themeMode,
      );

      final Finder icon =
          find.byKey(const ValueKey<String>('eden-appointment-truncated-icon'));
      expect(icon, findsOneWidget,
          reason: 'the truncated fixture must actually render its notice '
              'icon, or this run reports on nothing.');

      // 2.06:1 light / 8.25:1 dark before #55; 4.81:1 / 8.25:1 after.
      await expectInkContrast(
        tester,
        icon,
        iconInk(tester, icon),
        floor: _kNonTextFloor,
        what: 'the truncation-notice icon (WCAG 1.4.11, non-text)',
      );
    });
  }
}
