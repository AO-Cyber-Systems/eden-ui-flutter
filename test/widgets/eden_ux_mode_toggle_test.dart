import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_ux_mode_toggle_fixtures.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('EdenUxModeToggle.compact', () {
    testWidgets('renders three icons (smartphone / desktop / auto_awesome)', (tester) async {
      final c = EdenUxModeToggleFixtures.defaultController();
      await tester.pumpWidget(wrap(EdenUxModeToggle.compact(controller: c)));
      expect(find.byIcon(Icons.smartphone), findsOneWidget);
      expect(find.byIcon(Icons.desktop_windows), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });

    testWidgets('tapping smartphone sets mode to fieldCompanion', (tester) async {
      final c = EdenAppModeController(initialMode: EdenAppMode.admin);
      await tester.pumpWidget(wrap(EdenUxModeToggle.compact(controller: c)));
      await tester.tap(find.byIcon(Icons.smartphone));
      await tester.pumpAndSettle();
      expect(c.currentMode, EdenAppMode.fieldCompanion);
    });

    testWidgets('tapping desktop sets mode to admin', (tester) async {
      final c = EdenAppModeController(initialMode: EdenAppMode.fieldCompanion);
      await tester.pumpWidget(wrap(EdenUxModeToggle.compact(controller: c)));
      await tester.tap(find.byIcon(Icons.desktop_windows));
      await tester.pumpAndSettle();
      expect(c.currentMode, EdenAppMode.admin);
    });

    testWidgets('tapping auto sets mode to askUser', (tester) async {
      final c = EdenAppModeController(initialMode: EdenAppMode.admin);
      await tester.pumpWidget(wrap(EdenUxModeToggle.compact(controller: c)));
      await tester.tap(find.byIcon(Icons.auto_awesome));
      await tester.pumpAndSettle();
      expect(c.currentMode, EdenAppMode.askUser);
    });

    testWidgets('active background highlight moves after tap', (tester) async {
      final c = EdenAppModeController(initialMode: EdenAppMode.admin);
      await tester.pumpWidget(wrap(EdenUxModeToggle.compact(controller: c)));
      // Before tap: admin (desktop icon) is active.
      final adminSemBefore = tester.getSemantics(
        find.ancestor(
          of: find.byIcon(Icons.desktop_windows),
          matching: find.byType(Semantics),
        ).first,
      );
      expect(adminSemBefore.hasFlag(SemanticsFlag.isSelected), isTrue);

      await tester.tap(find.byIcon(Icons.smartphone));
      await tester.pumpAndSettle();

      // After tap: fieldCompanion (smartphone icon) is active.
      final fieldSemAfter = tester.getSemantics(
        find.ancestor(
          of: find.byIcon(Icons.smartphone),
          matching: find.byType(Semantics),
        ).first,
      );
      expect(fieldSemAfter.hasFlag(SemanticsFlag.isSelected), isTrue);
    });

    testWidgets('current mode marked Semantics(selected: true)', (tester) async {
      final c = EdenAppModeController(initialMode: EdenAppMode.fieldCompanion);
      await tester.pumpWidget(wrap(EdenUxModeToggle.compact(controller: c)));
      final fieldSem = tester.getSemantics(
        find.ancestor(
          of: find.byIcon(Icons.smartphone),
          matching: find.byType(Semantics),
        ).first,
      );
      expect(fieldSem.hasFlag(SemanticsFlag.isSelected), isTrue);
    });
  });

  group('EdenUxModeToggle.labeled', () {
    testWidgets('renders three rows with icon + label (Field/Admin/Auto)', (tester) async {
      final c = EdenUxModeToggleFixtures.defaultController();
      await tester.pumpWidget(wrap(EdenUxModeToggle.labeled(controller: c)));
      expect(find.text('Field'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);
      expect(find.text('Auto'), findsOneWidget);
      expect(find.byIcon(Icons.smartphone), findsOneWidget);
      expect(find.byIcon(Icons.desktop_windows), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });

    testWidgets('tapping Field label sets fieldCompanion', (tester) async {
      final c = EdenAppModeController(initialMode: EdenAppMode.admin);
      await tester.pumpWidget(wrap(EdenUxModeToggle.labeled(controller: c)));
      await tester.tap(find.text('Field'));
      await tester.pumpAndSettle();
      expect(c.currentMode, EdenAppMode.fieldCompanion);
    });

    testWidgets('tapping Admin label sets admin', (tester) async {
      final c = EdenAppModeController(initialMode: EdenAppMode.fieldCompanion);
      await tester.pumpWidget(wrap(EdenUxModeToggle.labeled(controller: c)));
      await tester.tap(find.text('Admin'));
      await tester.pumpAndSettle();
      expect(c.currentMode, EdenAppMode.admin);
    });

    testWidgets('tapping Auto label sets askUser', (tester) async {
      final c = EdenAppModeController(initialMode: EdenAppMode.admin);
      await tester.pumpWidget(wrap(EdenUxModeToggle.labeled(controller: c)));
      await tester.tap(find.text('Auto'));
      await tester.pumpAndSettle();
      expect(c.currentMode, EdenAppMode.askUser);
    });

    testWidgets('active label has Semantics(selected: true)', (tester) async {
      final c = EdenAppModeController(initialMode: EdenAppMode.admin);
      await tester.pumpWidget(wrap(EdenUxModeToggle.labeled(controller: c)));
      final sem = tester.getSemantics(
        find.ancestor(
          of: find.text('Admin'),
          matching: find.byType(Semantics),
        ).first,
      );
      expect(sem.hasFlag(SemanticsFlag.isSelected), isTrue);
    });
  });

  group('EdenUxModeToggle — scope vs controller resolution', () {
    testWidgets('reads from EdenAppModeScope when no controller arg', (tester) async {
      final c = EdenAppModeController(initialMode: EdenAppMode.admin);
      await tester.pumpWidget(wrap(
        EdenAppModeScope(
          controller: c,
          child: EdenUxModeToggle.compact(),
        ),
      ));
      await tester.tap(find.byIcon(Icons.smartphone));
      await tester.pumpAndSettle();
      expect(c.currentMode, EdenAppMode.fieldCompanion);
    });

    testWidgets('explicit controller beats scope (mutates the arg, not the scope)', (tester) async {
      final scopeC = EdenAppModeController(initialMode: EdenAppMode.admin);
      final explicitC = EdenAppModeController(initialMode: EdenAppMode.askUser);
      await tester.pumpWidget(wrap(
        EdenAppModeScope(
          controller: scopeC,
          child: EdenUxModeToggle.compact(controller: explicitC),
        ),
      ));
      await tester.tap(find.byIcon(Icons.smartphone));
      await tester.pumpAndSettle();
      expect(explicitC.currentMode, EdenAppMode.fieldCompanion);
      expect(scopeC.currentMode, EdenAppMode.admin); // untouched
    });

    testWidgets('no controller and no scope → assertion error', (tester) async {
      await tester.pumpWidget(wrap(EdenUxModeToggle.compact()));
      expect(tester.takeException(), isA<AssertionError>());
    });
  });

  group('EdenUxModeToggle — accessibility', () {
    testWidgets('each option has a Tooltip with human-readable name', (tester) async {
      final c = EdenUxModeToggleFixtures.defaultController();
      await tester.pumpWidget(wrap(EdenUxModeToggle.compact(controller: c)));
      expect(find.byTooltip('Field companion'), findsOneWidget);
      expect(find.byTooltip('Admin (desktop view)'), findsOneWidget);
      expect(find.byTooltip('Auto (resize-driven)'), findsOneWidget);
    });
  });

  group('EdenUxModeToggle — responsive iPhone-narrow safety', () {
    testWidgets('compact variant fits at 390pt width without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final c = EdenUxModeToggleFixtures.defaultController();
      await tester.pumpWidget(wrap(EdenUxModeToggle.compact(controller: c)));
      expect(tester.takeException(), isNull);
    });
  });
}
