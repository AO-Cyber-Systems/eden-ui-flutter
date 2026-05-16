import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_app_mode_fixtures.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('resolveAppMode (pure function)', () {
    test('Compact viewport (390pt) with no overrides → fieldCompanion', () {
      final mode = resolveAppMode(
        viewport: EdenAppModeFixtures.compactViewport,
      );
      expect(mode, EdenAppMode.fieldCompanion);
    });

    test('Expanded viewport (1200pt) with no overrides → admin', () {
      final mode = resolveAppMode(
        viewport: EdenAppModeFixtures.expandedViewport,
      );
      expect(mode, EdenAppMode.admin);
    });

    test('Medium viewport (700pt) ambiguous → askUser', () {
      final mode = resolveAppMode(
        viewport: EdenAppModeFixtures.mediumViewport,
      );
      expect(mode, EdenAppMode.askUser);
    });

    test('Persisted fieldCompanion beats Expanded viewport default', () {
      final mode = resolveAppMode(
        viewport: EdenAppModeFixtures.expandedViewport,
        persistedAppMode: 'fieldCompanion',
      );
      expect(mode, EdenAppMode.fieldCompanion);
    });

    test('Persisted admin beats Compact viewport default', () {
      final mode = resolveAppMode(
        viewport: EdenAppModeFixtures.compactViewport,
        persistedAppMode: 'admin',
      );
      expect(mode, EdenAppMode.admin);
    });

    test('Invalid persisted string falls through to viewport default (no throw)', () {
      final mode = resolveAppMode(
        viewport: EdenAppModeFixtures.compactViewport,
        persistedAppMode: 'garbage',
      );
      expect(mode, EdenAppMode.fieldCompanion);
    });

    test('JWT claim beats persisted choice', () {
      final mode = resolveAppMode(
        viewport: EdenAppModeFixtures.expandedViewport,
        persistedAppMode: 'admin',
        claimAppMode: EdenAppMode.fieldCompanion,
      );
      expect(mode, EdenAppMode.fieldCompanion);
    });

    test('dart-define beats JWT claim and persistence', () {
      final mode = resolveAppMode(
        viewport: EdenAppModeFixtures.expandedViewport,
        persistedAppMode: 'admin',
        claimAppMode: EdenAppMode.admin,
        dartDefineBuildMode: EdenAppMode.fieldCompanion,
      );
      expect(mode, EdenAppMode.fieldCompanion);
    });

    test('Boundary edge — 600pt is in Medium tier → askUser', () {
      final mode = resolveAppMode(
        viewport: EdenAppModeFixtures.compactBoundaryViewport,
      );
      expect(mode, EdenAppMode.askUser);
    });

    test('Boundary edge — 840pt is in Expanded tier → admin', () {
      final mode = resolveAppMode(
        viewport: EdenAppModeFixtures.expandedBoundaryViewport,
      );
      expect(mode, EdenAppMode.admin);
    });
  });

  group('EdenAppModeController', () {
    test('initialMode is currentMode', () {
      final c = EdenAppModeController(initialMode: EdenAppMode.admin);
      expect(c.currentMode, EdenAppMode.admin);
    });

    test('setMode triggers single notifyListeners', () {
      final c = EdenAppModeController(initialMode: EdenAppMode.admin);
      var calls = 0;
      c.addListener(() => calls++);
      c.setMode(EdenAppMode.fieldCompanion);
      expect(calls, 1);
      expect(c.currentMode, EdenAppMode.fieldCompanion);
    });

    test('setMode is idempotent — same mode → no notification', () {
      final c = EdenAppModeController(initialMode: EdenAppMode.fieldCompanion);
      var calls = 0;
      c.addListener(() => calls++);
      c.setMode(EdenAppMode.fieldCompanion);
      c.setMode(EdenAppMode.fieldCompanion);
      expect(calls, 0);
    });

    test('onChange fires AFTER notifyListeners (ordering invariant)', () {
      final order = <String>[];
      final c = EdenAppModeController(
        initialMode: EdenAppMode.admin,
        onChange: (m) => order.add('onChange:${m.name}'),
      );
      c.addListener(() {
        order.add('listener:${c.currentMode.name}');
      });
      c.setMode(EdenAppMode.fieldCompanion);
      expect(order, ['listener:fieldCompanion', 'onChange:fieldCompanion']);
    });
  });

  group('EdenAppModeScope', () {
    testWidgets('renders initial mode via modeOf', (tester) async {
      final c = EdenAppModeController(initialMode: EdenAppMode.admin);
      await tester.pumpWidget(wrap(
        EdenAppModeScope(
          controller: c,
          child: Builder(
            builder: (ctx) {
              final m = EdenAppModeScope.modeOf(ctx);
              return Text(m.name);
            },
          ),
        ),
      ));
      expect(find.text('admin'), findsOneWidget);
    });

    testWidgets('rebuilds dependents when controller.setMode fires', (tester) async {
      final c = EdenAppModeController(initialMode: EdenAppMode.admin);
      await tester.pumpWidget(wrap(
        EdenAppModeScope(
          controller: c,
          child: Builder(
            builder: (ctx) {
              final m = EdenAppModeScope.modeOf(ctx);
              return Text(m.name);
            },
          ),
        ),
      ));
      expect(find.text('admin'), findsOneWidget);
      c.setMode(EdenAppMode.fieldCompanion);
      await tester.pump();
      expect(find.text('fieldCompanion'), findsOneWidget);
      expect(find.text('admin'), findsNothing);
    });

    testWidgets('of(context) returns the same controller instance', (tester) async {
      final c = EdenAppModeController(initialMode: EdenAppMode.admin);
      EdenAppModeController? observed;
      await tester.pumpWidget(wrap(
        EdenAppModeScope(
          controller: c,
          child: Builder(
            builder: (ctx) {
              observed = EdenAppModeScope.of(ctx);
              return const SizedBox.shrink();
            },
          ),
        ),
      ));
      expect(identical(observed, c), isTrue);
    });

    testWidgets('maybeOf returns null when no scope is in the tree', (tester) async {
      EdenAppModeController? observed = EdenAppModeController(
        initialMode: EdenAppMode.admin,
      );
      await tester.pumpWidget(wrap(
        Builder(
          builder: (ctx) {
            observed = EdenAppModeScope.maybeOf(ctx);
            return const SizedBox.shrink();
          },
        ),
      ));
      expect(observed, isNull);
    });
  });

  group('iPhone-narrow safety', () {
    testWidgets('390pt viewport: scope demo renders without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final c = EdenAppModeController(initialMode: EdenAppMode.fieldCompanion);
      await tester.pumpWidget(wrap(
        EdenAppModeScope(
          controller: c,
          child: Builder(
            builder: (ctx) => Text(EdenAppModeScope.modeOf(ctx).name),
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
      expect(find.text('fieldCompanion'), findsOneWidget);
    });
  });
}
