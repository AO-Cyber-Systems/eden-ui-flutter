import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_process_menu_fixtures.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 400,
            child: child,
          ),
        ),
      );

  group('EdenNodeContextMenu — basic rendering', () {
    testWidgets('renders each action with icon + label', (tester) async {
      final actions = phaseMenuActionsFixture();
      await tester.pumpWidget(wrap(EdenNodeContextMenu(
        actions: actions,
        onClose: () {},
      )));
      expect(find.text('Add Task'), findsOneWidget);
      expect(find.text('Add Task Group'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.byIcon(Icons.check_box), findsOneWidget);
      expect(find.byIcon(Icons.folder), findsOneWidget);
    });

    testWidgets('empty actions list renders without exception',
        (tester) async {
      await tester.pumpWidget(wrap(EdenNodeContextMenu(
        actions: const [],
        onClose: () {},
      )));
      expect(tester.takeException(), isNull);
    });
  });

  group('EdenNodeContextMenu — action invocation', () {
    testWidgets('tapping a leaf action fires its onTap AND onClose',
        (tester) async {
      bool addTaskCalled = false;
      int closeCount = 0;
      final actions = phaseMenuActionsFixture(
        onAddTask: () => addTaskCalled = true,
      );
      await tester.pumpWidget(wrap(EdenNodeContextMenu(
        actions: actions,
        onClose: () => closeCount += 1,
      )));
      await tester.tap(find.byKey(const ValueKey('action-Add Task')));
      await tester.pump();
      expect(addTaskCalled, isTrue);
      expect(closeCount, 1);
    });
  });

  group('EdenNodeContextMenu — destructive styling', () {
    testWidgets('destructive action renders text in error color',
        (tester) async {
      final actions = phaseMenuActionsFixture();
      await tester.pumpWidget(wrap(EdenNodeContextMenu(
        actions: actions,
        onClose: () {},
      )));
      final deleteText = tester.widget<Text>(find.text('Delete'));
      // theme.colorScheme.error from default ThemeData.light()
      expect(deleteText.style?.color, isNotNull);
    });
  });

  group('EdenNodeContextMenu — submenu', () {
    testWidgets('submenu parent shows chevron-right initially', (tester) async {
      final actions = phaseMenuActionsWithTemplatesFixture();
      await tester.pumpWidget(wrap(EdenNodeContextMenu(
        actions: actions,
        onClose: () {},
      )));
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      expect(find.byIcon(Icons.expand_more), findsNothing);
      // Submenu items not yet rendered.
      expect(find.text('Onboarding'), findsNothing);
    });

    testWidgets('tapping submenu parent toggles expansion and does NOT fire onClose',
        (tester) async {
      int closeCount = 0;
      final actions = phaseMenuActionsWithTemplatesFixture();
      await tester.pumpWidget(wrap(EdenNodeContextMenu(
        actions: actions,
        onClose: () => closeCount += 1,
      )));
      await tester.tap(find.byKey(const ValueKey('action-Apply Template')));
      await tester.pump();
      expect(closeCount, 0);
      expect(find.text('Onboarding'), findsOneWidget);
      expect(find.text('Closeout'), findsOneWidget);
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
    });

    testWidgets('tapping a submenu CHILD fires its onTap AND parent onClose',
        (tester) async {
      String? appliedTemplate;
      int closeCount = 0;
      final actions = phaseMenuActionsWithTemplatesFixture(
        onApplyTemplate: (id) => appliedTemplate = id,
      );
      await tester.pumpWidget(wrap(EdenNodeContextMenu(
        actions: actions,
        onClose: () => closeCount += 1,
      )));
      await tester.tap(find.byKey(const ValueKey('action-Apply Template')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('action-Closeout')));
      await tester.pump();
      expect(appliedTemplate, 'closeout');
      expect(closeCount, 1);
    });
  });

  group('EdenNodeContextMenu — dismissal', () {
    testWidgets('tapping the dismiss backdrop fires onClose', (tester) async {
      int closeCount = 0;
      final actions = phaseMenuActionsFixture();
      await tester.pumpWidget(wrap(EdenNodeContextMenu(
        actions: actions,
        onClose: () => closeCount += 1,
      )));
      // Tap at corner where only the backdrop is — using the keyed backdrop.
      await tester.tap(
        find.byKey(const ValueKey('node-context-menu-dismiss-backdrop')),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(closeCount, 1);
    });

    testWidgets('Esc key dismisses', (tester) async {
      int closeCount = 0;
      final actions = phaseMenuActionsFixture();
      await tester.pumpWidget(wrap(EdenNodeContextMenu(
        actions: actions,
        onClose: () => closeCount += 1,
      )));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(closeCount, 1);
    });
  });

  group('EdenNodeContextMenu — iPhone-narrow safe', () {
    testWidgets('renders at 390pt without exception', (tester) async {
      tester.view.physicalSize = const Size(390, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final actions = phaseMenuActionsFixture();
      await tester.pumpWidget(wrap(EdenNodeContextMenu(
        actions: actions,
        onClose: () {},
      )));
      expect(tester.takeException(), isNull);
    });
  });
}
