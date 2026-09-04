import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: Center(child: child)));
  }

  group('EdenButton', () {
    // Regression: the button's label inherited NO font family.
    //
    // _resolveSizing() returned `const TextStyle(fontSize: N, fontWeight: w600)`
    // -- size and weight, no family and no fallback -- and that went straight
    // into styleFrom(textStyle:). ButtonStyleButton resolves textStyle with a
    // strict `??` (button_style_button.dart), so it BEAT the theme's
    // labelLarge, and Material(textStyle:) then replaced the ambient style.
    // The label therefore asked for no family at all.
    //
    // On web that falls back to the browser default, so every EdenButton
    // rendered in a DIFFERENT typeface from the text around it. Found by
    // reading a real-pixel capture (eden-biz objective 696): every button in
    // the console rendered as .notdef boxes under `flutter test`, while all
    // surrounding copy was correct -- the visible symptom of the same cause.
    //
    // The button owns SIZE and WEIGHT. The theme owns the FAMILY.
    testWidgets('label inherits the ambient font family, keeping its own size '
        'and weight', (tester) async {
      const family = 'PlusJakartaSans';
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(
          textTheme: const TextTheme(
            labelLarge: TextStyle(fontFamily: family),
          ),
        ),
        home: Scaffold(
          body: Center(
            child: EdenButton(label: 'Link task', onPressed: () {}),
          ),
        ),
      ));

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      final style = button.style!.textStyle!.resolve(<WidgetState>{});

      expect(style?.fontFamily, family,
          reason: 'the label must take the ambient family -- a family-less '
              'style falls back to the browser font on web, rendering every '
              'button in a different typeface from its surroundings');
      // The button's own contract is unchanged.
      expect(style?.fontSize, 14, reason: 'md size is still the button\'s');
      expect(style?.fontWeight, FontWeight.w600,
          reason: 'weight is still the button\'s');
    });

    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(wrap(
        EdenButton(label: 'Click Me', onPressed: () {}),
      ));
      expect(find.text('Click Me'), findsOneWidget);
    });

    testWidgets('renders with each variant without error', (tester) async {
      for (final variant in EdenButtonVariant.values) {
        await tester.pumpWidget(wrap(
          EdenButton(label: 'Test', variant: variant, onPressed: () {}),
        ));
        expect(find.text('Test'), findsOneWidget);
      }
    });

    testWidgets('shows CircularProgressIndicator when loading', (tester) async {
      await tester.pumpWidget(wrap(
        EdenButton(label: 'Loading', loading: true, onPressed: () {}),
      ));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('disabled state: onPressed not called when tapped',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(wrap(
        EdenButton(label: 'Disabled', disabled: true, onPressed: () => tapped = true),
      ));
      await tester.tap(find.text('Disabled'));
      expect(tapped, false);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(wrap(
        EdenButton(label: 'Active', onPressed: () => tapped = true),
      ));
      await tester.tap(find.text('Active'));
      expect(tapped, true);
    });

    testWidgets('renders leading icon when provided', (tester) async {
      await tester.pumpWidget(wrap(
        EdenButton(label: 'Icon', icon: Icons.add, onPressed: () {}),
      ));
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('renders trailing icon when provided', (tester) async {
      await tester.pumpWidget(wrap(
        EdenButton(
          label: 'Trail',
          trailingIcon: Icons.arrow_forward,
          onPressed: () {},
        ),
      ));
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    testWidgets('loading state prevents onPressed', (tester) async {
      var tapped = false;
      await tester.pumpWidget(wrap(
        EdenButton(label: 'Loading', loading: true, onPressed: () => tapped = true),
      ));
      await tester.tap(find.text('Loading'));
      expect(tapped, false);
    });

    testWidgets('outline renders OutlinedButton', (tester) async {
      await tester.pumpWidget(wrap(
        EdenButton(label: 'Outlined', outline: true, onPressed: () {}),
      ));
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('non-outline renders ElevatedButton', (tester) async {
      await tester.pumpWidget(wrap(
        EdenButton(label: 'Solid', onPressed: () {}),
      ));
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('pill shape renders without error', (tester) async {
      await tester.pumpWidget(wrap(
        EdenButton(label: 'Pill', pill: true, onPressed: () {}),
      ));
      expect(find.text('Pill'), findsOneWidget);
    });

    testWidgets('fullWidth renders without error', (tester) async {
      await tester.pumpWidget(wrap(
        EdenButton(label: 'Full', fullWidth: true, onPressed: () {}),
      ));
      expect(find.text('Full'), findsOneWidget);
    });

    testWidgets('renders each size variant without error', (tester) async {
      for (final size in EdenButtonSize.values) {
        await tester.pumpWidget(wrap(
          EdenButton(label: 'Btn', size: size, onPressed: () {}),
        ));
        expect(find.text('Btn'), findsOneWidget);
      }
    });

    testWidgets('danger variant renders', (tester) async {
      await tester.pumpWidget(wrap(
        EdenButton(
          label: 'Delete',
          variant: EdenButtonVariant.danger,
          onPressed: () {},
        ),
      ));
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('success variant renders', (tester) async {
      await tester.pumpWidget(wrap(
        EdenButton(
          label: 'Save',
          variant: EdenButtonVariant.success,
          onPressed: () {},
        ),
      ));
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('ghost variant renders', (tester) async {
      await tester.pumpWidget(wrap(
        EdenButton(
          label: 'Ghost',
          variant: EdenButtonVariant.ghost,
          onPressed: () {},
        ),
      ));
      expect(find.text('Ghost'), findsOneWidget);
    });
  });
}
