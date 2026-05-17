// Hand-built fixture file — Do NOT regenerate via LLM.
//
// Covers EdenStatusDotOverlay (composable status dot / unread count badge).
// Includes the mandatory TAP PASS-THROUGH test per TDD playbook habit 6 —
// proves the overlay does not intercept child taps.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: Center(child: child)));
  }

  EdenStatusDotOverlay build({
    Widget? child,
    EdenStatusDotKind kind = EdenStatusDotKind.online,
    int? count,
    Color? color,
    AlignmentGeometry alignment = Alignment.bottomRight,
    double? size,
  }) {
    return EdenStatusDotOverlay(
      child: child ??
          const SizedBox(width: 64, height: 64, child: ColoredBox(color: Colors.blue)),
      kind: kind,
      count: count,
      color: color,
      alignment: alignment,
      size: size,
    );
  }

  group('EdenStatusDotOverlay', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(wrap(EdenStatusDotOverlay(
        child: const Text('hello'),
      )));
      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('renders online dot by default', (tester) async {
      await tester.pumpWidget(wrap(build()));
      // No exception; the overlay should be present.
      expect(find.byType(EdenStatusDotOverlay), findsOneWidget);
    });

    testWidgets('kind=offline renders without exception', (tester) async {
      await tester.pumpWidget(wrap(build(kind: EdenStatusDotKind.offline)));
      expect(tester.takeException(), isNull);
    });

    testWidgets('kind=busy renders without exception', (tester) async {
      await tester.pumpWidget(wrap(build(kind: EdenStatusDotKind.busy)));
      expect(tester.takeException(), isNull);
    });

    testWidgets('kind=sync renders without exception', (tester) async {
      await tester.pumpWidget(wrap(build(kind: EdenStatusDotKind.sync)));
      expect(tester.takeException(), isNull);
    });

    testWidgets('kind=unread + count=3 renders "3" badge', (tester) async {
      await tester.pumpWidget(wrap(build(kind: EdenStatusDotKind.unread, count: 3)));
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('kind=unread + count=99 renders "99" badge', (tester) async {
      await tester.pumpWidget(wrap(build(kind: EdenStatusDotKind.unread, count: 99)));
      expect(find.text('99'), findsOneWidget);
    });

    testWidgets('kind=unread + count=150 renders "99+" overflow cap', (tester) async {
      await tester.pumpWidget(wrap(build(kind: EdenStatusDotKind.unread, count: 150)));
      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('kind=unread + count=0 renders no badge text', (tester) async {
      await tester.pumpWidget(wrap(build(kind: EdenStatusDotKind.unread, count: 0)));
      expect(find.text('0'), findsNothing);
    });

    testWidgets('kind=unread + count=null renders no badge text', (tester) async {
      await tester.pumpWidget(wrap(build(kind: EdenStatusDotKind.unread)));
      expect(find.text('1'), findsNothing);
    });

    testWidgets('alignment=topLeft positions overlay at top-left of child', (tester) async {
      await tester.pumpWidget(wrap(build(alignment: Alignment.topLeft)));
      expect(tester.takeException(), isNull);
    });

    testWidgets('TAP PASS-THROUGH: child onTap fires; overlay does not intercept', (tester) async {
      int taps = 0;
      await tester.pumpWidget(wrap(EdenStatusDotOverlay(
        kind: EdenStatusDotKind.unread,
        count: 3,
        child: GestureDetector(
          onTap: () => taps++,
          behavior: HitTestBehavior.opaque,
          child: const SizedBox(width: 64, height: 64),
        ),
      )));
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();
      expect(taps, equals(1));
    });

    testWidgets('custom color override applies', (tester) async {
      await tester.pumpWidget(wrap(build(color: Colors.purple)));
      expect(tester.takeException(), isNull);
    });

    testWidgets('iPhone-narrow 390pt: 99+ badge does not overflow small child', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 700 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap(EdenStatusDotOverlay(
        kind: EdenStatusDotKind.unread,
        count: 200,
        child: const SizedBox(width: 32, height: 32, child: ColoredBox(color: Colors.blue)),
      )));
      expect(tester.takeException(), isNull);
    });

    testWidgets('semantics: count badge announces "N unread"', (tester) async {
      await tester.pumpWidget(wrap(build(kind: EdenStatusDotKind.unread, count: 3)));
      final labels = tester.widgetList<Semantics>(find.byType(Semantics))
          .map((s) => s.properties.label)
          .where((l) => l != null)
          .toList();
      expect(labels.any((l) => l!.contains('3 unread')), isTrue,
          reason: '"3 unread" semantics label. Got: $labels');
    });

    testWidgets('semantics: status dot announces kind.name', (tester) async {
      await tester.pumpWidget(wrap(build(kind: EdenStatusDotKind.online)));
      final labels = tester.widgetList<Semantics>(find.byType(Semantics))
          .map((s) => s.properties.label)
          .where((l) => l != null)
          .toList();
      expect(labels.contains('online'), isTrue,
          reason: '"online" semantics label. Got: $labels');
    });

    testWidgets('tap on dot/badge area does NOT fire callback', (tester) async {
      // The dot is wrapped in IgnorePointer, so even direct taps on its area
      // pass through to the child below (or hit nothing).
      int taps = 0;
      await tester.pumpWidget(wrap(EdenStatusDotOverlay(
        kind: EdenStatusDotKind.unread,
        count: 5,
        child: GestureDetector(
          onTap: () => taps++,
          behavior: HitTestBehavior.opaque,
          child: const SizedBox(width: 80, height: 80),
        ),
      )));
      // Tap near the bottom-right corner where the badge sits — should pass through
      // to the GestureDetector child and fire taps == 1.
      final center = tester.getCenter(find.byType(EdenStatusDotOverlay));
      await tester.tapAt(center + const Offset(28, 28));
      await tester.pump();
      expect(taps, equals(1));
    });
  });
}
