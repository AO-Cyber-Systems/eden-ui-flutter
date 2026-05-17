import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_language_selector_fixtures.dart';

Widget wrap(Widget child, {double width = 600}) =>
    MaterialApp(home: Scaffold(body: SizedBox(width: width, child: child)));

void main() {
  group('EdenLanguageOption + EdenLanguageOptions defaults', () {
    test('EdenLanguageOption stores code + nativeLabel + englishLabel', () {
      const o = EdenLanguageOption(
        code: 'fr',
        nativeLabel: 'Français',
        englishLabel: 'French',
      );
      expect(o.code, 'fr');
      expect(o.nativeLabel, 'Français');
      expect(o.englishLabel, 'French');
    });

    test('usFederalDefault has 7 entries with expected codes (EO 13166)', () {
      expect(EdenLanguageOptions.usFederalDefault.length, 7);
      final codes =
          EdenLanguageOptions.usFederalDefault.map((o) => o.code).toList();
      expect(codes, EdenLanguageSelectorFixtures.expectedDefaultCodes);
    });

    test('usFederalDefault native labels include native scripts', () {
      final natives = EdenLanguageOptions.usFederalDefault
          .map((o) => o.nativeLabel)
          .toList();
      expect(natives, contains('中文'));
      expect(natives, contains('한국어'));
      expect(natives, contains('Русский'));
      expect(natives, contains('العربية'));
    });
  });

  group('EdenLanguageSelector — chips layout', () {
    testWidgets('renders all option native labels as chips', (tester) async {
      await tester.pumpWidget(wrap(EdenLanguageSelector(
        current: EdenLanguageSelectorFixtures.english,
        layout: EdenLanguageSelectorLayout.chips,
        onLanguageChanged: (_) {},
      )));
      // All 7 default options visible as native labels.
      for (final option in EdenLanguageOptions.usFederalDefault) {
        expect(find.text(option.nativeLabel), findsOneWidget);
      }
    });

    testWidgets('current language chip is selected (ChoiceChip.selected=true)',
        (tester) async {
      await tester.pumpWidget(wrap(EdenLanguageSelector(
        current: EdenLanguageSelectorFixtures.spanish,
        layout: EdenLanguageSelectorLayout.chips,
        onLanguageChanged: (_) {},
      )));
      final spanishChip = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
      final selected = spanishChip.where((c) => c.selected);
      expect(selected.length, 1);
      final selectedLabel = (selected.first.label as Text).data;
      expect(selectedLabel, 'Español');
    });

    testWidgets('tapping a chip fires onLanguageChanged with matching option',
        (tester) async {
      EdenLanguageOption? picked;
      await tester.pumpWidget(wrap(EdenLanguageSelector(
        current: EdenLanguageSelectorFixtures.english,
        layout: EdenLanguageSelectorLayout.chips,
        onLanguageChanged: (o) => picked = o,
      )));
      await tester.tap(find.text('Español'));
      await tester.pump();
      expect(picked?.code, 'es');
    });
  });

  group('EdenLanguageSelector — button layout', () {
    testWidgets('renders current language native label as button', (tester) async {
      await tester.pumpWidget(wrap(EdenLanguageSelector(
        current: EdenLanguageSelectorFixtures.english,
        onLanguageChanged: (_) {},
      )));
      expect(find.text('English'), findsAtLeastNWidgets(1));
    });

    testWidgets('tapping button + selecting option fires onLanguageChanged',
        (tester) async {
      EdenLanguageOption? picked;
      await tester.pumpWidget(wrap(EdenLanguageSelector(
        current: EdenLanguageSelectorFixtures.english,
        onLanguageChanged: (o) => picked = o,
      )));
      // Open the menu.
      await tester.tap(find.byType(PopupMenuButton<EdenLanguageOption>));
      await tester.pumpAndSettle();
      // Tap Spanish option.
      await tester.tap(find.text('Español').last);
      await tester.pumpAndSettle();
      expect(picked?.code, 'es');
    });
  });

  group('EdenLanguageSelector — custom options', () {
    testWidgets('custom options list overrides default', (tester) async {
      final custom = [
        EdenLanguageSelectorFixtures.english,
        EdenLanguageSelectorFixtures.spanish,
      ];
      await tester.pumpWidget(wrap(EdenLanguageSelector(
        current: EdenLanguageSelectorFixtures.english,
        options: custom,
        layout: EdenLanguageSelectorLayout.chips,
        onLanguageChanged: (_) {},
      )));
      // Only the 2 custom options should be visible.
      expect(find.byType(ChoiceChip), findsNWidgets(2));
    });
  });

  group('EdenLanguageSelector — Section 508 a11y', () {
    testWidgets('button has Semantics label with current native label',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(EdenLanguageSelector(
        current: EdenLanguageSelectorFixtures.english,
        onLanguageChanged: (_) {},
      )));
      final selectorSemantics = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            (w.properties.label?.contains('Language selector') ?? false) &&
            (w.properties.label?.contains('English') ?? false),
      );
      expect(selectorSemantics, findsAtLeastNWidgets(1));
      handle.dispose();
    });
  });

  group('EdenLanguageSelector — iPhone-narrow (390pt) safety', () {
    testWidgets('chips layout at 390pt: wraps without overflow', (tester) async {
      await tester.pumpWidget(wrap(
        EdenLanguageSelector(
          current: EdenLanguageSelectorFixtures.english,
          layout: EdenLanguageSelectorLayout.chips,
          onLanguageChanged: (_) {},
        ),
        width: 390,
      ));
      expect(tester.takeException(), isNull);
      expect(find.byType(Wrap), findsAtLeastNWidgets(1));
    });

    testWidgets('button layout at 390pt: no overflow', (tester) async {
      await tester.pumpWidget(wrap(
        EdenLanguageSelector(
          current: EdenLanguageSelectorFixtures.english,
          onLanguageChanged: (_) {},
        ),
        width: 390,
      ));
      expect(tester.takeException(), isNull);
    });
  });
}
