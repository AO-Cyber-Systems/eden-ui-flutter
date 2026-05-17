import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../_fixtures/eden_workflow_action_fixtures.dart';
import '../_fixtures/eden_workflow_node_fixtures.dart' show wrap;

void main() {
  setUp(() {
    EdenWorkflowActionRegistry.instance.resetToDefaults();
  });

  group('EdenActionNode — visual', () {
    testWidgets('renders without exception', (tester) async {
      await tester.pumpWidget(
        wrap(EdenActionNode(context: actionNodeContextFixture())),
      );
      expect(find.byType(EdenActionNode), findsOneWidget);
    });

    testWidgets('renders "ACTION" uppercase label', (tester) async {
      await tester.pumpWidget(
        wrap(EdenActionNode(context: actionNodeContextFixture())),
      );
      expect(find.text('ACTION'), findsOneWidget);
    });

    testWidgets('renders create_task icon and "Create Task" label',
        (tester) async {
      await tester.pumpWidget(
        wrap(EdenActionNode(context: actionNodeContextFixture())),
      );
      expect(find.byIcon(Icons.add_task), findsOneWidget);
      expect(find.text('Create Task'), findsOneWidget);
    });

    testWidgets('renders config summary "Follow up" for create_task with title',
        (tester) async {
      await tester.pumpWidget(
        wrap(EdenActionNode(
          context: actionNodeContextFixture(
            config: const {'title': 'Follow up'},
          ),
        )),
      );
      expect(find.text('Follow up'), findsOneWidget);
    });

    testWidgets(
        'send_email config summary uses config[to]',
        (tester) async {
      await tester.pumpWidget(
        wrap(EdenActionNode(
          context: actionNodeContextFixture(
            actionType: 'send_email',
            config: const {'to': 'a@b.com'},
          ),
        )),
      );
      expect(find.text('a@b.com'), findsOneWidget);
    });

    testWidgets(
        'send_sms config summary uses config[phoneNumber]',
        (tester) async {
      await tester.pumpWidget(
        wrap(EdenActionNode(
          context: actionNodeContextFixture(
            actionType: 'send_sms',
            config: const {'phoneNumber': '+15551234567'},
          ),
        )),
      );
      expect(find.text('+15551234567'), findsOneWidget);
    });

    testWidgets(
        'update_status config summary uses arrow → newStatus',
        (tester) async {
      await tester.pumpWidget(
        wrap(EdenActionNode(
          context: actionNodeContextFixture(
            actionType: 'update_status',
            config: const {'newStatus': 'completed'},
          ),
        )),
      );
      expect(find.text('→ completed'), findsOneWidget);
    });

    testWidgets('selection ring shown when selected', (tester) async {
      await tester.pumpWidget(
        wrap(EdenActionNode(
          context: actionNodeContextFixture(selected: true),
        )),
      );
      final container = tester.widget<Container>(find
          .descendant(
            of: find.byType(InkWell).first,
            matching: find.byType(Container),
          )
          .first);
      final decoration = container.decoration as BoxDecoration;
      expect((decoration.border as Border).top.width, 2.5);
    });

    testWidgets('renders at iPhone-narrow (390pt) without overflow',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          EdenActionNode(context: actionNodeContextFixture()),
          width: 390,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('EdenActionNode — delete button', () {
    testWidgets('delete button not visible by default (no hover, desktop)',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      await tester.pumpWidget(
        wrap(EdenActionNode(
          context: actionNodeContextFixture(),
          config: EdenActionNodeConfig(onDelete: () {}),
        )),
      );
      expect(find.byIcon(Icons.delete_outline), findsNothing);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('delete button visible on hover (desktop)', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      await tester.pumpWidget(
        wrap(EdenActionNode(
          context: actionNodeContextFixture(),
          config: EdenActionNodeConfig(onDelete: () {}),
        )),
      );
      final gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.byType(EdenActionNode)));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('delete button always visible on touch platforms',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await tester.pumpWidget(
        wrap(EdenActionNode(
          context: actionNodeContextFixture(),
          config: EdenActionNodeConfig(onDelete: () {}),
        )),
      );
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('tapping delete fires onDelete', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      var deleted = 0;
      await tester.pumpWidget(
        wrap(EdenActionNode(
          context: actionNodeContextFixture(),
          config: EdenActionNodeConfig(onDelete: () => deleted++),
        )),
      );
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(deleted, 1);
      debugDefaultTargetPlatformOverride = null;
    });
  });

  group('EdenActionNode — popover editor', () {
    testWidgets('tapping card opens popover dialog', (tester) async {
      await tester.pumpWidget(
        wrap(EdenActionNode(context: actionNodeContextFixture())),
      );
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Edit Action'), findsOneWidget);
    });

    testWidgets('popover for create_task shows 3 fields (title/desc/priority)',
        (tester) async {
      await tester.pumpWidget(
        wrap(EdenActionNode(context: actionNodeContextFixture())),
      );
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      expect(find.text('Task Title'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Priority'), findsOneWidget);
    });

    testWidgets('Save fires onUpdate with actionType + config + label',
        (tester) async {
      final captures = <Map<String, dynamic>>[];
      await tester.pumpWidget(
        wrap(EdenActionNode(
          context: actionNodeContextFixture(),
          config: EdenActionNodeConfig(onUpdate: captures.add),
        )),
      );
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(captures.length, 1);
      expect(captures[0]['actionType'], 'create_task');
      expect(captures[0]['label'], 'Create Task');
      expect(captures[0]['config'], isA<Map<String, dynamic>>());
    });

    testWidgets('Cancel does NOT fire onUpdate', (tester) async {
      final captures = <Map<String, dynamic>>[];
      await tester.pumpWidget(
        wrap(EdenActionNode(
          context: actionNodeContextFixture(),
          config: EdenActionNodeConfig(onUpdate: captures.add),
        )),
      );
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(captures, isEmpty);
    });

    testWidgets('editing a text field updates the captured config',
        (tester) async {
      final captures = <Map<String, dynamic>>[];
      await tester.pumpWidget(
        wrap(EdenActionNode(
          context: actionNodeContextFixture(
            actionType: 'send_email',
            config: const {},
          ),
          config: EdenActionNodeConfig(onUpdate: captures.add),
        )),
      );
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      // First TextFormField is the "To" field
      await tester.enterText(find.byType(TextFormField).first, 'a@b.com');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(captures.length, 1);
      expect(captures[0]['config']['to'], 'a@b.com');
    });
  });
}
