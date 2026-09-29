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

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:eden_ui_flutter/dev_app/registry/eden_story.dart';

import '../../test_support/ui_oracle/measure_ink.dart';
import '../../test_support/ui_oracle/story_harness.dart';
import '../../test_support/ui_oracle/wrap.dart';

/// WCAG 1.4.11: 3:1 for non-text content that carries information.
const double _kNonTextFloor = 3.0;

void main() {
  ensureStoriesRegistered();

  // -------------------------------------------------------------------
  // EdenGlyphInk.of(context) — the foot-gun it exists to close.
  // -------------------------------------------------------------------
  testWidgets(
      'EdenGlyphInk.of(context) resolves against the THEME brightness, not '
      "the platform's, when they disagree", (WidgetTester tester) async {
    // A LIGHT theme, pinned with ThemeMode.light, under a DARK platform
    // brightness. `MediaQuery.platformBrightnessOf(context)` would read
    // Brightness.dark here and hand back the DARK member on a LIGHT
    // surface — the exact mistake nothing in this package could see before
    // EdenGlyphInk existed (eden-ui-flutter#55): not a type error, no lint
    // names it, and the oracle only measures surfaces a story actually
    // pumps in the brightness it pumps them.
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    late EdenGlyphInkSet resolved;
    await tester.pumpWidget(
      MaterialApp(
        theme: EdenTheme.light(),
        darkTheme: EdenTheme.dark(),
        themeMode: ThemeMode.light,
        home: Builder(
          builder: (BuildContext context) {
            resolved = EdenGlyphInk.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Naming WHICH brightness it resolved, not merely that some colour came
    // back — a wrong brightness that coincidentally shares a colour with
    // the right one would pass a colour-only assertion and prove nothing.
    expect(
      resolved.brightness,
      Brightness.light,
      reason: 'the app pins ThemeMode.light, so Theme.of(context).brightness '
          'is light even though the PLATFORM brightness is dark. '
          'EdenGlyphInk.of(context) must resolve against the THEME, not '
          'MediaQuery.platformBrightnessOf(context).',
    );
    expect(
      resolved.success,
      EdenGlyphInk.success(Brightness.light),
      reason: 'the LIGHT member must come back — a caller who reached for '
          'MediaQuery.platformBrightnessOf(context) instead would get the '
          'DARK member (emerald[500] at 2.00:1) on a light surface, which is '
          'the exact defect this class exists to make the short spelling '
          'avoid.',
    );
  });

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

      // BY KEY, NOT BY MIXING TONES (eden-ui-flutter#58 code review). The
      // old form (`eden-appointment-status-dot`, `findsWidgets` + `.first`)
      // was attached to EVERY status dot REGARDLESS OF TONE and took
      // whichever rendered first — green on fixture 01 because all five of
      // its real rows are `confirmed`, and blind to a `confirmed` dot
      // regressing the day a non-confirmed row led the list, because
      // `.first` would then measure `neutralFg` instead. Keying each tone
      // separately (`-confirmed` / `-neutral`) makes this finder match ONLY
      // confirmed dots — five of them, all identical by construction (same
      // key, same switch arm, same ink) — so `.first` among THEM is no
      // longer order-dependent on TONE, which is the axis that regressed.
      // The fixture now carries a synthetic non-confirmed row FIRST (see
      // `eden_appointment_list.stories.dart`'s header) precisely so this
      // could not silently keep passing if it were still tone-blind.
      final Finder confirmedDots = find.byKey(
        const ValueKey<String>('eden-appointment-status-dot-confirmed'));
      expect(confirmedDots, findsWidgets,
          reason: 'the fixture must render at least one CONFIRMED status '
              'dot, found by its own key regardless of row order, or this '
              'run reports on nothing.');
      final Finder confirmedDot = confirmedDots.first;

      final Color resolvedInk = decorationInk(tester, confirmedDot);
      // Read through EdenGlyphInk.of(context) — the SAME call the migrated
      // widget now makes (eden-ui-flutter#58 code review, lower-3) — rather
      // than the bare Brightness form, so this assertion is checking that
      // the call site resolves THROUGH .of(context), not merely that the
      // numbers still happen to agree.
      final BuildContext glyphContext = tester.element(confirmedDot);
      // THE RATIO ALONE CANNOT TELL YOU WHICH TONE IT MEASURED — a glyph
      // that drifted onto `neutralFg` could still clear 3:1 by accident and
      // this identity check is the one that would catch it. Both together:
      // the ratio (below) is the conformance floor, the identity is the
      // spelling check this file exists to enforce.
      expect(resolvedInk, equals(EdenGlyphInk.of(glyphContext).success),
          reason: 'the confirmed dot must resolve to exactly '
              'EdenGlyphInk.of(context).success, not merely something that '
              'happens to clear the floor.');

      // 2.00:1 light / 5.87:1 dark before #55; 4.32:1 / 5.87:1 after. The
      // dark tone is UNCHANGED — the base hue already cleared the floor
      // there, and a single tone that clears both themes does not exist in
      // the emerald ramp (emerald[600] is 2.97:1 light, emerald[700] is
      // 2.72:1 dark). That is why `EdenGlyphInk` is a brightness-split pair.
      await expectInkContrast(
        tester,
        confirmedDot,
        resolvedInk,
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

      // Read through EdenGlyphInk.of(context) — the same call the migrated
      // widget now makes — so this is checking the call site resolves
      // THROUGH .of(context), not merely that the numbers still agree.
      final Color resolvedIcon = iconInk(tester, icon);
      final BuildContext glyphContext = tester.element(icon);
      expect(resolvedIcon, equals(EdenGlyphInk.of(glyphContext).warning),
          reason: 'the truncation-notice icon must resolve to exactly '
              'EdenGlyphInk.of(context).warning.');

      // 2.06:1 light / 8.25:1 dark before #55; 4.81:1 / 8.25:1 after.
      await expectInkContrast(
        tester,
        icon,
        resolvedIcon,
        floor: _kNonTextFloor,
        what: 'the truncation-notice icon (WCAG 1.4.11, non-text)',
      );
    });
  }
}
