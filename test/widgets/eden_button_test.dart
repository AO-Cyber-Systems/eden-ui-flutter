import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: Center(child: child)));
  }

  group('EdenButton', () {
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
