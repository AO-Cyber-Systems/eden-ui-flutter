import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_field_view_gate_fixtures.dart';

void main() {
  final F = EdenFieldViewGateFixtures.wrapWithScope;

  group('EdenFieldViewGate.companionOnly', () {
    testWidgets('renders child when currentMode == fieldCompanion', (tester) async {
      final c = EdenFieldViewGateFixtures.controllerStartingAt(
          EdenAppMode.fieldCompanion);
      await tester.pumpWidget(F(
        EdenFieldViewGate.companionOnly(child: const Text('visible')),
        c,
      ));
      expect(find.text('visible'), findsOneWidget);
    });

    testWidgets('hides child when currentMode == admin (default fallback)', (tester) async {
      final c = EdenFieldViewGateFixtures.controllerStartingAt(EdenAppMode.admin);
      await tester.pumpWidget(F(
        EdenFieldViewGate.companionOnly(child: const Text('visible')),
        c,
      ));
      expect(find.text('visible'), findsNothing);
    });

    testWidgets('hides child when currentMode == askUser (default fallback)', (tester) async {
      final c = EdenFieldViewGateFixtures.controllerStartingAt(EdenAppMode.askUser);
      await tester.pumpWidget(F(
        EdenFieldViewGate.companionOnly(child: const Text('visible')),
        c,
      ));
      expect(find.text('visible'), findsNothing);
    });
  });

  group('EdenFieldViewGate.adminOnly', () {
    testWidgets('renders child when currentMode == admin', (tester) async {
      final c = EdenFieldViewGateFixtures.controllerStartingAt(EdenAppMode.admin);
      await tester.pumpWidget(F(
        EdenFieldViewGate.adminOnly(child: const Text('visible')),
        c,
      ));
      expect(find.text('visible'), findsOneWidget);
    });

    testWidgets('hides child when currentMode == fieldCompanion', (tester) async {
      final c = EdenFieldViewGateFixtures.controllerStartingAt(
          EdenAppMode.fieldCompanion);
      await tester.pumpWidget(F(
        EdenFieldViewGate.adminOnly(child: const Text('visible')),
        c,
      ));
      expect(find.text('visible'), findsNothing);
    });

    testWidgets('hides child when currentMode == askUser', (tester) async {
      final c = EdenFieldViewGateFixtures.controllerStartingAt(EdenAppMode.askUser);
      await tester.pumpWidget(F(
        EdenFieldViewGate.adminOnly(child: const Text('visible')),
        c,
      ));
      expect(find.text('visible'), findsNothing);
    });
  });

  group('EdenFieldViewGate — fallback arg', () {
    testWidgets('renders fallback in admin mode (companionOnly)', (tester) async {
      final c = EdenFieldViewGateFixtures.controllerStartingAt(EdenAppMode.admin);
      await tester.pumpWidget(F(
        EdenFieldViewGate.companionOnly(
          child: const Text('A'),
          fallback: const Text('B'),
        ),
        c,
      ));
      expect(find.text('B'), findsOneWidget);
      expect(find.text('A'), findsNothing);
    });

    testWidgets('renders child (not fallback) in matching mode', (tester) async {
      final c = EdenFieldViewGateFixtures.controllerStartingAt(
          EdenAppMode.fieldCompanion);
      await tester.pumpWidget(F(
        EdenFieldViewGate.companionOnly(
          child: const Text('A'),
          fallback: const Text('B'),
        ),
        c,
      ));
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsNothing);
    });
  });

  group('EdenFieldViewGate — builder arg', () {
    testWidgets('builder receives admin mode in unmatched case', (tester) async {
      final c = EdenFieldViewGateFixtures.controllerStartingAt(EdenAppMode.admin);
      await tester.pumpWidget(F(
        EdenFieldViewGate.companionOnly(
          child: const Text('A'),
          builder: (ctx, m) => Text('was-${m.name}'),
        ),
        c,
      ));
      expect(find.text('was-admin'), findsOneWidget);
    });

    testWidgets('builder receives askUser mode in unmatched case', (tester) async {
      final c = EdenFieldViewGateFixtures.controllerStartingAt(EdenAppMode.askUser);
      await tester.pumpWidget(F(
        EdenFieldViewGate.companionOnly(
          child: const Text('A'),
          builder: (ctx, m) => Text('was-${m.name}'),
        ),
        c,
      ));
      expect(find.text('was-askUser'), findsOneWidget);
    });

    testWidgets('builder ignored in matching mode → child renders', (tester) async {
      final c = EdenFieldViewGateFixtures.controllerStartingAt(
          EdenAppMode.fieldCompanion);
      await tester.pumpWidget(F(
        EdenFieldViewGate.companionOnly(
          child: const Text('A'),
          builder: (ctx, m) => Text('was-${m.name}'),
        ),
        c,
      ));
      expect(find.text('A'), findsOneWidget);
      expect(find.textContaining('was-'), findsNothing);
    });
  });

  group('EdenFieldViewGate — fallback/builder exclusivity', () {
    testWidgets('passing BOTH fallback AND builder throws assertion error', (tester) async {
      expect(
        () => EdenFieldViewGate.companionOnly(
          child: const Text('A'),
          fallback: const Text('B'),
          builder: (ctx, m) => const Text('C'),
        ),
        throwsAssertionError,
      );
    });
  });

  group('EdenFieldViewGate — rebuild on mode change', () {
    testWidgets('flips from fallback → child → fallback as setMode fires', (tester) async {
      final c = EdenFieldViewGateFixtures.controllerStartingAt(EdenAppMode.admin);
      await tester.pumpWidget(F(
        EdenFieldViewGate.companionOnly(
          child: const Text('A'),
          fallback: const Text('B'),
        ),
        c,
      ));
      expect(find.text('B'), findsOneWidget);
      expect(find.text('A'), findsNothing);

      c.setMode(EdenAppMode.fieldCompanion);
      await tester.pump();
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsNothing);

      c.setMode(EdenAppMode.admin);
      await tester.pump();
      expect(find.text('B'), findsOneWidget);
      expect(find.text('A'), findsNothing);
    });

    testWidgets('builder result updates with new mode after setMode', (tester) async {
      final c = EdenFieldViewGateFixtures.controllerStartingAt(EdenAppMode.admin);
      await tester.pumpWidget(F(
        EdenFieldViewGate.companionOnly(
          child: const Text('A'),
          builder: (ctx, m) => Text('was-${m.name}'),
        ),
        c,
      ));
      expect(find.text('was-admin'), findsOneWidget);

      c.setMode(EdenAppMode.askUser);
      await tester.pump();
      expect(find.text('was-askUser'), findsOneWidget);
    });
  });

  group('EdenFieldViewGate — missing scope assertion', () {
    testWidgets('mount without EdenAppModeScope ancestor → assertion error', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EdenFieldViewGate.companionOnly(child: const Text('A')),
        ),
      ));
      expect(tester.takeException(), isA<AssertionError>());
    });
  });

  group('EdenFieldViewGate — iPhone-narrow safety', () {
    testWidgets('390pt: companionOnly with Row child renders without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final c = EdenFieldViewGateFixtures.controllerStartingAt(
          EdenAppMode.fieldCompanion);
      await tester.pumpWidget(F(
        EdenFieldViewGate.companionOnly(
          child: const Row(
            children: [
              Icon(Icons.check),
              SizedBox(width: 8),
              Text('ok'),
            ],
          ),
        ),
        c,
      ));
      expect(tester.takeException(), isNull);
      expect(find.text('ok'), findsOneWidget);
    });
  });
}
