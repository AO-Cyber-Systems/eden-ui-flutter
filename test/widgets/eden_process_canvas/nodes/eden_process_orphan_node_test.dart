import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../_fixtures/eden_process_node_fixtures.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: Center(
              child: SizedBox(width: 200, height: 80, child: child),
            ),
          ),
        ),
      );

  setUp(() {
    EdenProcessRuntimeComponentRegistry.instance.resetToDefaults();
  });

  group('EdenProcessOrphanNode — icon dispatch', () {
    testWidgets('orphanType=phase renders Layers icon', (tester) async {
      await tester.pumpWidget(wrap(EdenProcessOrphanNode(
        context: nodeCtx(phaseOrphanFixture()),
      )));
      expect(find.byIcon(Icons.layers), findsOneWidget);
    });

    testWidgets('orphanType=taskGroup renders Folder icon', (tester) async {
      await tester.pumpWidget(wrap(EdenProcessOrphanNode(
        context: nodeCtx(taskGroupOrphanFixture()),
      )));
      expect(find.byIcon(Icons.folder), findsOneWidget);
    });

    testWidgets('orphanType=decision renders call_split icon', (tester) async {
      await tester.pumpWidget(wrap(EdenProcessOrphanNode(
        context: nodeCtx(decisionOrphanFixture()),
      )));
      expect(find.byIcon(Icons.call_split), findsOneWidget);
    });

    testWidgets('orphanType=task with no runtime component renders default check_box icon',
        (tester) async {
      await tester.pumpWidget(wrap(EdenProcessOrphanNode(
        context: nodeCtx(taskOrphanFixture()),
      )));
      expect(find.byIcon(Icons.check_box), findsOneWidget);
    });

    testWidgets('orphanType=task with runtime=checklist renders default checklist icon',
        (tester) async {
      // 'checklist' is library-default registered as Icons.check_box.
      await tester.pumpWidget(wrap(EdenProcessOrphanNode(
        context: nodeCtx(taskOrphanFixture(runtimeComponent: 'checklist')),
      )));
      expect(find.byIcon(Icons.check_box), findsOneWidget);
    });

    testWidgets('orphanType=task with custom registered runtime component renders custom icon',
        (tester) async {
      EdenProcessRuntimeComponentRegistry.instance.register(
        const EdenProcessRuntimeComponentType(
          id: 'custom_widget',
          displayName: 'Custom Widget',
          icon: Icons.star,
        ),
      );
      await tester.pumpWidget(wrap(EdenProcessOrphanNode(
        context: nodeCtx(taskOrphanFixture(runtimeComponent: 'custom_widget')),
      )));
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('orphanType=task with unknown runtime component falls back to check_box',
        (tester) async {
      await tester.pumpWidget(wrap(EdenProcessOrphanNode(
        context: nodeCtx(taskOrphanFixture(runtimeComponent: 'no_such_runtime')),
      )));
      expect(find.byIcon(Icons.check_box), findsOneWidget);
    });
  });

  group('EdenProcessOrphanNode — labels', () {
    testWidgets('renders displayName', (tester) async {
      await tester.pumpWidget(wrap(EdenProcessOrphanNode(
        context: nodeCtx(phaseOrphanFixture(displayName: 'Inspect site')),
      )));
      expect(find.text('Inspect site'), findsOneWidget);
    });

    testWidgets('renders type label "Phase" for phase orphan', (tester) async {
      await tester.pumpWidget(wrap(EdenProcessOrphanNode(
        context: nodeCtx(phaseOrphanFixture()),
      )));
      expect(find.text('Phase'), findsOneWidget);
    });

    testWidgets('renders type label "Task Group" for taskGroup orphan',
        (tester) async {
      await tester.pumpWidget(wrap(EdenProcessOrphanNode(
        context: nodeCtx(taskGroupOrphanFixture()),
      )));
      expect(find.text('Task Group'), findsOneWidget);
    });

    testWidgets('renders type label "Decision" for decision orphan',
        (tester) async {
      await tester.pumpWidget(wrap(EdenProcessOrphanNode(
        context: nodeCtx(decisionOrphanFixture()),
      )));
      expect(find.text('Decision'), findsOneWidget);
    });

    testWidgets('renders type label "Task" for task orphan', (tester) async {
      await tester.pumpWidget(wrap(EdenProcessOrphanNode(
        context: nodeCtx(taskOrphanFixture()),
      )));
      expect(find.text('Task'), findsOneWidget);
    });
  });

  group('EdenProcessOrphanNode — delete affordance', () {
    testWidgets('delete button hidden by default (opacity 0)', (tester) async {
      await tester.pumpWidget(wrap(EdenProcessOrphanNode(
        context: nodeCtx(phaseOrphanFixture()),
        onDelete: (_) {},
      )));

      final opacity = tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity));
      expect(opacity.opacity, 0.0);
    });

    testWidgets('delete button revealed on hover via MouseRegion onEnter',
        (tester) async {
      await tester.pumpWidget(wrap(EdenProcessOrphanNode(
        context: nodeCtx(phaseOrphanFixture()),
        onDelete: (_) {},
      )));

      // Simulate a mouse pointer entering the orphan widget area.
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.byType(EdenProcessOrphanNode)));
      await tester.pumpAndSettle();

      final opacity = tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity));
      expect(opacity.opacity, 1.0);
    });

    testWidgets('tapping delete button fires onDelete with node id', (tester) async {
      String? deletedId;
      await tester.pumpWidget(wrap(EdenProcessOrphanNode(
        context: nodeCtx(phaseOrphanFixture(id: 'orphan-XYZ')),
        onDelete: (id) => deletedId = id,
      )));

      // Show the delete button first (hover) then tap.
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.byType(EdenProcessOrphanNode)));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump();

      expect(deletedId, 'orphan-XYZ');
    });

    testWidgets('delete button disabled (no callback) when onDelete is null',
        (tester) async {
      await tester.pumpWidget(wrap(EdenProcessOrphanNode(
        context: nodeCtx(phaseOrphanFixture()),
      )));

      final iconButton =
          tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.delete_outline));
      expect(iconButton.onPressed, isNull);
    });
  });

  group('EdenProcessOrphanNode — selection + responsive', () {
    testWidgets('renders selection ring when ctx.selected==true', (tester) async {
      await tester.pumpWidget(wrap(EdenProcessOrphanNode(
        context: nodeCtx(phaseOrphanFixture(), selected: true),
      )));

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(EdenProcessOrphanNode),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect((decoration.border as Border).top.width, 2);
    });

    testWidgets('omits selection ring when ctx.selected==false', (tester) async {
      await tester.pumpWidget(wrap(EdenProcessOrphanNode(
        context: nodeCtx(phaseOrphanFixture()),
      )));

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(EdenProcessOrphanNode),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      // Non-selected uses width=1.
      expect((decoration.border as Border).top.width, 1);
    });

    testWidgets('renders without overflow at 390pt narrow viewport',
        (tester) async {
      tester.view.physicalSize = const Size(390, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrap(EdenProcessOrphanNode(
        context: nodeCtx(phaseOrphanFixture(displayName: 'Long display name that should ellipsize at narrow widths')),
      )));

      expect(tester.takeException(), isNull);
    });
  });
}
