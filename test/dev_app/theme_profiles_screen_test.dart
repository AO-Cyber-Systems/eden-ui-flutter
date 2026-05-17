// test/dev_app/theme_profiles_screen_test.dart
//
// Visual-catalog smoke test for the theme profiles screen (objective 009 TRD 05).

import 'package:eden_ui_flutter/dev_app/screens/theme_profiles_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  group('ThemeProfilesScreen', () {
    testWidgets('mounts at 390pt without exceptions', (tester) async {
      // Test list item 1.
      await tester.binding.setSurfaceSize(const Size(390, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(wrap(const ThemeProfilesScreen()));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      // No exception = success. Sanity-check by asserting takeException null.
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without RenderFlex overflowed at 390pt',
        (tester) async {
      // Test list item 2 — OBJECTIVE.md Constraint 9 gate.
      await tester.binding.setSurfaceSize(const Size(390, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(wrap(const ThemeProfilesScreen()));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull,
          reason:
              'No exceptions (including RenderFlex overflows) at 390pt iPhone-narrow');
    });

    testWidgets('displays names of all 5 profiles', (tester) async {
      // Test list item 3.
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(wrap(const ThemeProfilesScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Commercial'), findsWidgets);
      expect(find.textContaining('Medical'), findsWidgets);
      expect(find.textContaining('Federal'), findsWidgets,
          reason: 'gov profile listed as "Gov Federal" — substring match');
      expect(find.textContaining('Retail'), findsWidgets);
      expect(find.textContaining('Legal'), findsWidgets);
    });

    testWidgets('each profile card includes at least one button widget',
        (tester) async {
      // Test list item 4 — sample triptych present.
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(wrap(const ThemeProfilesScreen()));
      await tester.pumpAndSettle();

      // At least 5 button-shaped widgets (one per profile card).
      final buttonFinders = [
        find.byType(FilledButton),
        find.byType(ElevatedButton),
        find.byType(OutlinedButton),
        find.byType(TextButton),
      ];
      var totalButtons = 0;
      for (final f in buttonFinders) {
        totalButtons += tester.widgetList(f).length;
      }
      expect(totalButtons, greaterThanOrEqualTo(5),
          reason:
              'Each of 5 profile cards should have at least one sample button');
    });
  });
}
