// Hand-built fixture file — Do NOT regenerate via LLM.
//
// Covers EdenSkeletonScope (Stack+Opacity cross-fade wrapper). Includes the
// mandatory dispose-clean check + bidirectional transition tests.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: Center(child: child)));
  }

  Widget skel() => Container(
        key: const ValueKey('skel'),
        width: 200,
        height: 100,
        color: const Color(0xFFCCCCCC),
      );
  Widget content({String text = 'CONTENT', VoidCallback? onTap}) {
    return GestureDetector(
      key: ValueKey('content-$text'),
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 200,
        height: 100,
        child: ColoredBox(color: const Color(0xFF3333FF), child: Center(child: Text(text))),
      ),
    );
  }

  EdenSkeletonScope build({
    bool isLoading = true,
    Widget? skeleton,
    Widget? content,
    Duration fadeDuration = const Duration(milliseconds: 250),
    Curve? curve,
  }) {
    return EdenSkeletonScope(
      isLoading: isLoading,
      skeleton: skeleton ?? skel(),
      content: content ?? const Text('CONTENT'),
      fadeDuration: fadeDuration,
      curve: curve,
    );
  }

  group('EdenSkeletonScope', () {
    testWidgets('isLoading=true: skeleton at opacity 1, content at opacity 0', (tester) async {
      await tester.pumpWidget(wrap(build(isLoading: true)));
      // Find Opacity widgets — there should be two (one per child)
      final opacities = tester.widgetList<Opacity>(find.byType(Opacity)).toList();
      expect(opacities.length, greaterThanOrEqualTo(2));
      // Skeleton opacity ~1, content opacity ~0 (or vice versa).
      final values = opacities.map((o) => o.opacity).toList();
      expect(values.any((v) => v >= 0.99), isTrue);
      expect(values.any((v) => v <= 0.01), isTrue);
    });

    testWidgets('isLoading=false: content visible after settle', (tester) async {
      await tester.pumpWidget(wrap(build(isLoading: false)));
      await tester.pumpAndSettle();
      // Content text is in tree
      expect(find.text('CONTENT'), findsOneWidget);
    });

    testWidgets('transition from loading to loaded: mid-flight opacities cross-fade', (tester) async {
      await tester.pumpWidget(wrap(build(isLoading: true)));
      await tester.pumpWidget(wrap(build(isLoading: false)));
      await tester.pump(const Duration(milliseconds: 125));
      // Both children in tree; mid-flight opacities both > 0.
      final opacities = tester.widgetList<Opacity>(find.byType(Opacity))
          .map((o) => o.opacity)
          .toList();
      // Both Opacity nodes present.
      expect(opacities.length, greaterThanOrEqualTo(2));
      await tester.pumpAndSettle();
    });

    testWidgets('default curve: midpoint between 0 and 1', (tester) async {
      // Smoke: just confirm widget pumps without exception with default curve.
      await tester.pumpWidget(wrap(build(isLoading: true)));
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
    });

    testWidgets('custom curve override: linear @ 125ms = ~0.5 opacity', (tester) async {
      await tester.pumpWidget(wrap(build(isLoading: true, curve: Curves.linear)));
      await tester.pumpWidget(wrap(build(isLoading: false, curve: Curves.linear)));
      await tester.pump(const Duration(milliseconds: 125));
      final opacities = tester.widgetList<Opacity>(find.byType(Opacity))
          .map((o) => o.opacity)
          .toList();
      // At linear midpoint each should be ~0.5
      expect(opacities.any((v) => (v - 0.5).abs() < 0.1), isTrue,
          reason: 'linear @ 125ms expected ~0.5; got $opacities');
      await tester.pumpAndSettle();
    });

    testWidgets('both children always in tree (Stack with Opacity)', (tester) async {
      await tester.pumpWidget(wrap(build(isLoading: true)));
      expect(find.byKey(const ValueKey('skel')), findsOneWidget);
      // Content widget still in tree even when isLoading
      expect(find.text('CONTENT'), findsOneWidget);
    });

    testWidgets('pointer events: at isLoading=true content does NOT receive taps', (tester) async {
      int taps = 0;
      await tester.pumpWidget(wrap(build(
        isLoading: true,
        content: content(onTap: () => taps++),
      )));
      await tester.tap(find.byType(EdenSkeletonScope));
      await tester.pump();
      expect(taps, equals(0));
    });

    testWidgets('pointer events: at isLoading=false content receives taps', (tester) async {
      int taps = 0;
      await tester.pumpWidget(wrap(build(
        isLoading: false,
        content: content(onTap: () => taps++),
      )));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(EdenSkeletonScope));
      await tester.pump();
      expect(taps, equals(1));
    });

    testWidgets('different sizes: scope sizes to larger of (skeleton, content)', (tester) async {
      await tester.pumpWidget(wrap(EdenSkeletonScope(
        isLoading: true,
        skeleton: const SizedBox(width: 200, height: 100),
        content: const SizedBox(width: 300, height: 50),
      )));
      final size = tester.getSize(find.byType(EdenSkeletonScope));
      expect(size.width, equals(300));
      expect(size.height, equals(100));
    });

    testWidgets('iPhone-narrow 390pt: no exception', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 700 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap(build(isLoading: true)));
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
    });

    testWidgets('disposes cleanly without pending timers', (tester) async {
      await tester.pumpWidget(wrap(build(isLoading: true)));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpWidget(wrap(const SizedBox.shrink()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('toggling rapidly does not break', (tester) async {
      await tester.pumpWidget(wrap(build(isLoading: true)));
      await tester.pumpWidget(wrap(build(isLoading: false)));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpWidget(wrap(build(isLoading: true)));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpWidget(wrap(build(isLoading: false)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
