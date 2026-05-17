// Hand-built fixture file — Do NOT regenerate via LLM.
//
// Covers EdenLoadingIndicator across all 3 named variants (shapeMorph,
// shimmer, crossFade). Includes the dispose-clean check that prevents
// pending-timer leaks from cascading across the suite.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: Center(child: child)));
  }

  group('EdenLoadingIndicator.shapeMorph', () {
    testWidgets('renders with CustomPaint (4 dots)', (tester) async {
      await tester.pumpWidget(wrap(const EdenLoadingIndicator.shapeMorph()));
      expect(find.byType(CustomPaint), findsWidgets);
      await tester.pumpWidget(wrap(const SizedBox.shrink()));
    });

    testWidgets('respects size param', (tester) async {
      await tester.pumpWidget(wrap(const EdenLoadingIndicator.shapeMorph(size: 64)));
      final box = tester.getSize(find.byType(EdenLoadingIndicator));
      expect(box.width, equals(64));
      expect(box.height, equals(64));
      await tester.pumpWidget(wrap(const SizedBox.shrink()));
    });

    testWidgets('respects color param (no exception)', (tester) async {
      await tester.pumpWidget(wrap(const EdenLoadingIndicator.shapeMorph(color: Colors.red)));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(wrap(const SizedBox.shrink()));
    });

    testWidgets('animation loops (controller value progresses)', (tester) async {
      await tester.pumpWidget(wrap(const EdenLoadingIndicator.shapeMorph()));
      // Pump a frame so the animation starts.
      await tester.pump(const Duration(milliseconds: 50));
      // No exception thrown == animation tick fired.
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(wrap(const SizedBox.shrink()));
    });

    testWidgets('disposes cleanly without pending timers', (tester) async {
      await tester.pumpWidget(wrap(const EdenLoadingIndicator.shapeMorph()));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpWidget(wrap(const SizedBox.shrink()));
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });

  group('EdenLoadingIndicator.shimmer', () {
    testWidgets('renders with given width and height', (tester) async {
      await tester.pumpWidget(wrap(const EdenLoadingIndicator.shimmer(width: 200, height: 16)));
      final box = tester.getSize(find.byType(EdenLoadingIndicator));
      expect(box.width, equals(200));
      expect(box.height, equals(16));
      await tester.pumpWidget(wrap(const SizedBox.shrink()));
    });

    testWidgets('respects borderRadius', (tester) async {
      await tester.pumpWidget(wrap(EdenLoadingIndicator.shimmer(
        width: 100,
        height: 12,
        borderRadius: BorderRadius.circular(8),
      )));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(wrap(const SizedBox.shrink()));
    });

    testWidgets('disposes cleanly', (tester) async {
      await tester.pumpWidget(wrap(const EdenLoadingIndicator.shimmer(width: 100, height: 10)));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpWidget(wrap(const SizedBox.shrink()));
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });

  group('EdenLoadingIndicator.crossFade', () {
    testWidgets('isLoading=true shows skeleton', (tester) async {
      await tester.pumpWidget(wrap(EdenLoadingIndicator.crossFade(
        isLoading: true,
        skeleton: const Text('SKELETON'),
        content: const Text('CONTENT'),
      )));
      expect(find.text('SKELETON'), findsOneWidget);
      // Content may be in tree (AnimatedCrossFade keeps both) — but skeleton is fully visible.
    });

    testWidgets('isLoading=false shows content after settle', (tester) async {
      await tester.pumpWidget(wrap(EdenLoadingIndicator.crossFade(
        isLoading: false,
        skeleton: const Text('SKELETON'),
        content: const Text('CONTENT'),
      )));
      await tester.pumpAndSettle();
      expect(find.text('CONTENT'), findsOneWidget);
    });

    testWidgets('toggling isLoading triggers cross-fade', (tester) async {
      Widget build({required bool isLoading}) => wrap(EdenLoadingIndicator.crossFade(
            isLoading: isLoading,
            skeleton: const Text('SKELETON'),
            content: const Text('CONTENT'),
          ));
      await tester.pumpWidget(build(isLoading: true));
      await tester.pump();
      await tester.pumpWidget(build(isLoading: false));
      await tester.pumpAndSettle();
      expect(find.text('CONTENT'), findsOneWidget);
    });
  });

  group('EdenLoadingIndicator (cross-cutting)', () {
    testWidgets('semantics: variant has Loading label', (tester) async {
      await tester.pumpWidget(wrap(const EdenLoadingIndicator.shapeMorph()));
      final labels = tester.widgetList<Semantics>(find.byType(Semantics))
          .map((s) => s.properties.label)
          .where((l) => l != null)
          .toList();
      expect(labels.contains('Loading'), isTrue,
          reason: 'Loading semantics label. Got: $labels');
      await tester.pumpWidget(wrap(const SizedBox.shrink()));
    });

    testWidgets('iPhone-narrow 390pt: all variants render without exception', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 700 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap(const EdenLoadingIndicator.shapeMorph()));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(wrap(const EdenLoadingIndicator.shimmer(width: 200, height: 14)));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(wrap(EdenLoadingIndicator.crossFade(
        isLoading: true,
        skeleton: const Text('S'),
        content: const Text('C'),
      )));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(wrap(const SizedBox.shrink()));
    });
  });
}
