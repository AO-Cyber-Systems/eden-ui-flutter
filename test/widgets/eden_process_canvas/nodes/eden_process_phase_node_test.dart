import 'package:eden_ui_flutter/eden_ui.dart';
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
              child: SizedBox(width: 280, height: 240, child: child),
            ),
          ),
        ),
      );

  group('EdenProcessPhaseNode — basic rendering', () {
    testWidgets('renders displayName', (tester) async {
      final phase = phaseFixture(id: 1, displayName: 'Planning');
      await tester.pumpWidget(wrap(EdenProcessPhaseNode(
        context: nodeCtx(phaseDiagramNodeFixture(phaseId: 1)),
        config: phaseRendererConfigFixture(phasesById: {1: phase}),
      )));
      expect(find.text('Planning'), findsOneWidget);
    });

    testWidgets('renders Layers icon in header', (tester) async {
      final phase = phaseFixture(id: 1);
      await tester.pumpWidget(wrap(EdenProcessPhaseNode(
        context: nodeCtx(phaseDiagramNodeFixture(phaseId: 1)),
        config: phaseRendererConfigFixture(phasesById: {1: phase}),
      )));
      expect(find.byIcon(Icons.layers), findsOneWidget);
    });

    testWidgets('renders chevron_right when not expanded', (tester) async {
      final phase = phaseFixture(id: 1);
      await tester.pumpWidget(wrap(EdenProcessPhaseNode(
        context: nodeCtx(phaseDiagramNodeFixture(phaseId: 1)),
        config: phaseRendererConfigFixture(phasesById: {1: phase}),
      )));
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      expect(find.byIcon(Icons.expand_more), findsNothing);
    });

    testWidgets('renders expand_more chevron when expanded', (tester) async {
      final phase = phaseFixture(id: 1);
      await tester.pumpWidget(wrap(EdenProcessPhaseNode(
        context: nodeCtx(phaseDiagramNodeFixture(phaseId: 1)),
        config: phaseRendererConfigFixture(phasesById: {1: phase}, expanded: {1}),
      )));
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });

    testWidgets('renders milestone Flag icon when isMilestone=true',
        (tester) async {
      final phase = milestonePhaseFixture(id: 1);
      await tester.pumpWidget(wrap(EdenProcessPhaseNode(
        context: nodeCtx(phaseDiagramNodeFixture(phaseId: 1)),
        config: phaseRendererConfigFixture(phasesById: {1: phase}),
      )));
      expect(find.byIcon(Icons.flag), findsOneWidget);
    });

    testWidgets('omits milestone Flag icon when isMilestone=false',
        (tester) async {
      final phase = phaseFixture(id: 1);
      await tester.pumpWidget(wrap(EdenProcessPhaseNode(
        context: nodeCtx(phaseDiagramNodeFixture(phaseId: 1)),
        config: phaseRendererConfigFixture(phasesById: {1: phase}),
      )));
      expect(find.byIcon(Icons.flag), findsNothing);
    });

    testWidgets('renders missing-phase fallback when phasesById lookup fails',
        (tester) async {
      await tester.pumpWidget(wrap(EdenProcessPhaseNode(
        context: nodeCtx(phaseDiagramNodeFixture(phaseId: 999)),
        config: phaseRendererConfigFixture(phasesById: const {}),
      )));
      expect(find.text('Missing phase 999'), findsOneWidget);
    });
  });

  group('EdenProcessPhaseNode — color palette', () {
    ({Color border, Color fill}) _resolveBorder(WidgetTester tester) {
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(EdenProcessPhaseNode),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      final border = (decoration.border as Border).top.color;
      return (border: border, fill: decoration.color ?? Colors.transparent);
    }

    testWidgets('blue color renders blue border', (tester) async {
      final phase = phaseFixture(id: 1, color: 'blue');
      await tester.pumpWidget(wrap(EdenProcessPhaseNode(
        context: nodeCtx(phaseDiagramNodeFixture(phaseId: 1)),
        config: phaseRendererConfigFixture(phasesById: {1: phase}),
      )));
      expect(_resolveBorder(tester).border, const Color(0xFF3B82F6));
    });

    testWidgets('green color renders green border', (tester) async {
      final phase = phaseFixture(id: 1, color: 'green');
      await tester.pumpWidget(wrap(EdenProcessPhaseNode(
        context: nodeCtx(phaseDiagramNodeFixture(phaseId: 1)),
        config: phaseRendererConfigFixture(phasesById: {1: phase}),
      )));
      expect(_resolveBorder(tester).border, const Color(0xFF10B981));
    });

    testWidgets('amber color renders amber border', (tester) async {
      final phase = phaseFixture(id: 1, color: 'amber');
      await tester.pumpWidget(wrap(EdenProcessPhaseNode(
        context: nodeCtx(phaseDiagramNodeFixture(phaseId: 1)),
        config: phaseRendererConfigFixture(phasesById: {1: phase}),
      )));
      expect(_resolveBorder(tester).border, const Color(0xFFF59E0B));
    });

    testWidgets('red color renders red border', (tester) async {
      final phase = phaseFixture(id: 1, color: 'red');
      await tester.pumpWidget(wrap(EdenProcessPhaseNode(
        context: nodeCtx(phaseDiagramNodeFixture(phaseId: 1)),
        config: phaseRendererConfigFixture(phasesById: {1: phase}),
      )));
      expect(_resolveBorder(tester).border, const Color(0xFFEF4444));
    });

    testWidgets('purple color renders purple border', (tester) async {
      final phase = phaseFixture(id: 1, color: 'purple');
      await tester.pumpWidget(wrap(EdenProcessPhaseNode(
        context: nodeCtx(phaseDiagramNodeFixture(phaseId: 1)),
        config: phaseRendererConfigFixture(phasesById: {1: phase}),
      )));
      expect(_resolveBorder(tester).border, const Color(0xFF8B5CF6));
    });

    testWidgets('pink color renders pink border', (tester) async {
      final phase = phaseFixture(id: 1, color: 'pink');
      await tester.pumpWidget(wrap(EdenProcessPhaseNode(
        context: nodeCtx(phaseDiagramNodeFixture(phaseId: 1)),
        config: phaseRendererConfigFixture(phasesById: {1: phase}),
      )));
      expect(_resolveBorder(tester).border, const Color(0xFFEC4899));
    });

    testWidgets('cyan color renders cyan border', (tester) async {
      final phase = phaseFixture(id: 1, color: 'cyan');
      await tester.pumpWidget(wrap(EdenProcessPhaseNode(
        context: nodeCtx(phaseDiagramNodeFixture(phaseId: 1)),
        config: phaseRendererConfigFixture(phasesById: {1: phase}),
      )));
      expect(_resolveBorder(tester).border, const Color(0xFF06B6D4));
    });

    testWidgets('gray color renders gray border', (tester) async {
      final phase = phaseFixture(id: 1, color: 'gray');
      await tester.pumpWidget(wrap(EdenProcessPhaseNode(
        context: nodeCtx(phaseDiagramNodeFixture(phaseId: 1)),
        config: phaseRendererConfigFixture(phasesById: {1: phase}),
      )));
      expect(_resolveBorder(tester).border, const Color(0xFF6B7280));
    });

    testWidgets('hex color #3B82F6 renders blue border', (tester) async {
      final phase = phaseFixture(id: 1, color: '#3B82F6');
      await tester.pumpWidget(wrap(EdenProcessPhaseNode(
        context: nodeCtx(phaseDiagramNodeFixture(phaseId: 1)),
        config: phaseRendererConfigFixture(phasesById: {1: phase}),
      )));
      expect(_resolveBorder(tester).border, const Color(0xFF3B82F6));
    });

    testWidgets('null color defaults to blue', (tester) async {
      final phase = phaseFixture(id: 1, color: null);
      await tester.pumpWidget(wrap(EdenProcessPhaseNode(
        context: nodeCtx(phaseDiagramNodeFixture(phaseId: 1)),
        config: phaseRendererConfigFixture(phasesById: {1: phase}),
      )));
      expect(_resolveBorder(tester).border, const Color(0xFF3B82F6));
    });

    testWidgets('unrecognized color defaults to blue', (tester) async {
      final phase = phaseFixture(id: 1, color: 'fuchsia');
      await tester.pumpWidget(wrap(EdenProcessPhaseNode(
        context: nodeCtx(phaseDiagramNodeFixture(phaseId: 1)),
        config: phaseRendererConfigFixture(phasesById: {1: phase}),
      )));
      expect(_resolveBorder(tester).border, const Color(0xFF3B82F6));
    });
  });

  group('EdenProcessPhaseNode — expand/collapse', () {
    testWidgets('tapping chevron fires onTogglePhaseExpanded', (tester) async {
      int? toggled;
      final phase = phaseFixture(id: 7);
      await tester.pumpWidget(wrap(EdenProcessPhaseNode(
        context: nodeCtx(phaseDiagramNodeFixture(phaseId: 7)),
        config: phaseRendererConfigFixture(
          phasesById: {7: phase},
          onTogglePhaseExpanded: (id) => toggled = id,
        ),
      )));

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pump();

      expect(toggled, 7);
    });

    testWidgets('collapsed shows group + task badges when counts > 0',
        (tester) async {
      final phase = phaseWithGroupsFixture(phaseId: 1, groupCount: 2, tasksPerGroup: 3);
      await tester.pumpWidget(wrap(EdenProcessPhaseNode(
        context: nodeCtx(phaseDiagramNodeFixture(phaseId: 1)),
        config: phaseRendererConfigFixture(phasesById: {1: phase}),
      )));
      expect(find.text('2 groups'), findsOneWidget);
      expect(find.text('6 tasks'), findsOneWidget);
    });

    testWidgets('collapsed shows "No tasks" when 0 groups + 0 tasks',
        (tester) async {
      final phase = phaseFixture(id: 1);
      await tester.pumpWidget(wrap(EdenProcessPhaseNode(
        context: nodeCtx(phaseDiagramNodeFixture(phaseId: 1)),
        config: phaseRendererConfigFixture(phasesById: {1: phase}),
      )));
      expect(find.text('No tasks'), findsOneWidget);
    });

    testWidgets('expanded shows per-group rows', (tester) async {
      final phase = phaseWithGroupsFixture(phaseId: 1, groupCount: 2, tasksPerGroup: 3);
      await tester.pumpWidget(wrap(EdenProcessPhaseNode(
        context: nodeCtx(phaseDiagramNodeFixture(phaseId: 1)),
        config: phaseRendererConfigFixture(phasesById: {1: phase}, expanded: {1}),
      )));
      expect(find.textContaining('Group 1'), findsOneWidget);
      expect(find.textContaining('Group 2'), findsOneWidget);
    });

    testWidgets('expanded with no groups shows empty-state italic placeholder',
        (tester) async {
      final phase = phaseFixture(id: 1);
      await tester.pumpWidget(wrap(EdenProcessPhaseNode(
        context: nodeCtx(phaseDiagramNodeFixture(phaseId: 1)),
        config: phaseRendererConfigFixture(phasesById: {1: phase}, expanded: {1}),
      )));
      expect(find.text('No task groups yet'), findsOneWidget);
    });
  });

  group('EdenProcessPhaseNode — hover-show buttons', () {
    testWidgets('edit + delete buttons hidden by default', (tester) async {
      final phase = phaseFixture(id: 1);
      await tester.pumpWidget(wrap(EdenProcessPhaseNode(
        context: nodeCtx(phaseDiagramNodeFixture(phaseId: 1)),
        config: phaseRendererConfigFixture(phasesById: {1: phase}),
      )));

      final opacity = tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity));
      expect(opacity.opacity, 0.0);
    });

    testWidgets('tapping pencil fires onOpenPhaseEditor', (tester) async {
      int? opened;
      final phase = phaseFixture(id: 3);
      await tester.pumpWidget(wrap(EdenProcessPhaseNode(
        context: nodeCtx(phaseDiagramNodeFixture(phaseId: 3)),
        config: phaseRendererConfigFixture(
          phasesById: {3: phase},
          onOpenPhaseEditor: (id) => opened = id,
        ),
      )));

      await tester.tap(find.byIcon(Icons.edit_outlined), warnIfMissed: false);
      await tester.pump();
      expect(opened, 3);
    });

    testWidgets('tapping trash fires onDeletePhase', (tester) async {
      int? deleted;
      final phase = phaseFixture(id: 3);
      await tester.pumpWidget(wrap(EdenProcessPhaseNode(
        context: nodeCtx(phaseDiagramNodeFixture(phaseId: 3)),
        config: phaseRendererConfigFixture(
          phasesById: {3: phase},
          onDeletePhase: (id) => deleted = id,
        ),
      )));

      await tester.tap(find.byIcon(Icons.delete_outline), warnIfMissed: false);
      await tester.pump();
      expect(deleted, 3);
    });
  });

  group('EdenProcessPhaseNode — inline rename', () {
    testWidgets('tapping displayName enters edit mode (TextField appears)',
        (tester) async {
      final phase = phaseFixture(id: 1, displayName: 'Planning');
      await tester.pumpWidget(wrap(EdenProcessPhaseNode(
        context: nodeCtx(phaseDiagramNodeFixture(phaseId: 1)),
        config: phaseRendererConfigFixture(phasesById: {1: phase}),
      )));

      await tester.tap(find.text('Planning'));
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('typing new name + tapping outside saves via onUpdatePhase',
        (tester) async {
      Map<String, dynamic>? updates;
      int? updatedId;
      final phase = phaseFixture(id: 1, displayName: 'Planning');
      await tester.pumpWidget(wrap(EdenProcessPhaseNode(
        context: nodeCtx(phaseDiagramNodeFixture(phaseId: 1)),
        config: phaseRendererConfigFixture(
          phasesById: {1: phase},
          onUpdatePhase: (id, u) {
            updatedId = id;
            updates = u;
          },
        ),
      )));

      await tester.tap(find.text('Planning'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Discovery');
      // Trigger blur by tapping outside.
      await tester.tap(find.byIcon(Icons.layers));
      await tester.pumpAndSettle();

      expect(updatedId, 1);
      expect(updates?['displayName'], 'Discovery');
    });

    testWidgets('whitespace-only name does NOT fire onUpdatePhase (silent cancel)',
        (tester) async {
      int callCount = 0;
      final phase = phaseFixture(id: 1, displayName: 'Planning');
      await tester.pumpWidget(wrap(EdenProcessPhaseNode(
        context: nodeCtx(phaseDiagramNodeFixture(phaseId: 1)),
        config: phaseRendererConfigFixture(
          phasesById: {1: phase},
          onUpdatePhase: (_, __) => callCount += 1,
        ),
      )));

      await tester.tap(find.text('Planning'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.byIcon(Icons.layers));
      await tester.pumpAndSettle();

      expect(callCount, 0);
    });

    testWidgets('saving the exact same name does NOT fire onUpdatePhase',
        (tester) async {
      int callCount = 0;
      final phase = phaseFixture(id: 1, displayName: 'Planning');
      await tester.pumpWidget(wrap(EdenProcessPhaseNode(
        context: nodeCtx(phaseDiagramNodeFixture(phaseId: 1)),
        config: phaseRendererConfigFixture(
          phasesById: {1: phase},
          onUpdatePhase: (_, __) => callCount += 1,
        ),
      )));

      await tester.tap(find.text('Planning'));
      await tester.pump();
      // Leave text unchanged.
      await tester.tap(find.byIcon(Icons.layers));
      await tester.pumpAndSettle();

      expect(callCount, 0);
    });
  });

  group('EdenProcessPhaseNode — drop-target + selection rings', () {
    testWidgets('dropTarget=true uses primary-color border at width=2',
        (tester) async {
      final phase = phaseFixture(id: 1);
      await tester.pumpWidget(wrap(EdenProcessPhaseNode(
        context: nodeCtx(phaseDiagramNodeFixture(phaseId: 1), dropTarget: true),
        config: phaseRendererConfigFixture(phasesById: {1: phase}),
      )));

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(EdenProcessPhaseNode),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect((decoration.border as Border).top.width, 2);
    });

    testWidgets('default (no drop target, not selected) uses 1.5pt border',
        (tester) async {
      final phase = phaseFixture(id: 1);
      await tester.pumpWidget(wrap(EdenProcessPhaseNode(
        context: nodeCtx(phaseDiagramNodeFixture(phaseId: 1)),
        config: phaseRendererConfigFixture(phasesById: {1: phase}),
      )));

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(EdenProcessPhaseNode),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect((decoration.border as Border).top.width, 1.5);
    });

    testWidgets('selected=true uses 2pt border', (tester) async {
      final phase = phaseFixture(id: 1);
      await tester.pumpWidget(wrap(EdenProcessPhaseNode(
        context: nodeCtx(phaseDiagramNodeFixture(phaseId: 1), selected: true),
        config: phaseRendererConfigFixture(phasesById: {1: phase}),
      )));

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(EdenProcessPhaseNode),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect((decoration.border as Border).top.width, 2);
    });
  });

  group('EdenProcessNodeRenderer dispatch extension — phase', () {
    testWidgets('returns EdenProcessPhaseNode for nodeType=phase',
        (tester) async {
      final phase = phaseFixture(id: 1);
      await tester.pumpWidget(wrap(EdenProcessNodeRenderer.dispatch(
        nodeCtx(phaseDiagramNodeFixture(phaseId: 1)),
        config: phaseRendererConfigFixture(phasesById: {1: phase}),
      )));
      expect(find.byType(EdenProcessPhaseNode), findsOneWidget);
    });
  });

  group('EdenProcessPhaseNode — iPhone-narrow safety', () {
    testWidgets('renders at 390pt without overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final phase = phaseFixture(id: 1, displayName: 'Long phase name that should ellipsize gracefully');
      await tester.pumpWidget(wrap(EdenProcessPhaseNode(
        context: nodeCtx(phaseDiagramNodeFixture(phaseId: 1)),
        config: phaseRendererConfigFixture(phasesById: {1: phase}),
      )));

      expect(tester.takeException(), isNull);
    });
  });
}
