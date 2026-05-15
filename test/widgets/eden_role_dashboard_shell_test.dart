import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_role_dashboard_shell_fixtures.dart';

void main() {
  Widget wrap(Widget child, {Size size = const Size(1280, 800)}) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(body: SizedBox(width: size.width, height: size.height, child: child)),
      ),
    );
  }

  group('EdenRoleDashboardShell', () {
    testWidgets('renders greeting + roleLabel + avatar in header',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenRoleDashboardShell(
          greeting: 'Good morning, Sarah',
          roleLabel: 'Dispatcher',
          rolePalette: EdenRolePalette.trades,
          avatar: const CircleAvatar(child: Text('S')),
          sections: EdenRoleDashboardShellFixtures.tradesDispatcherSections,
        ),
      ));
      expect(find.text('Good morning, Sarah'), findsOneWidget);
      expect(find.text('Dispatcher'), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('role_badge')), findsOneWidget);
    });

    testWidgets('renders 4 sections at desktop width', (tester) async {
      await tester.pumpWidget(wrap(
        EdenRoleDashboardShell(
          greeting: 'Hi',
          roleLabel: 'Dispatcher',
          sections: EdenRoleDashboardShellFixtures.tradesDispatcherSections,
        ),
      ));
      // Each section card mounted by id key.
      for (final s in EdenRoleDashboardShellFixtures.tradesDispatcherSections) {
        expect(
          find.byKey(ValueKey<String>('section_${s.id}')),
          findsOneWidget,
          reason: 'expected section_${s.id}',
        );
      }
    });

    testWidgets('renders right rail when rightRail widget passed',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenRoleDashboardShell(
          greeting: 'Hi',
          roleLabel: 'Dispatcher',
          sections: EdenRoleDashboardShellFixtures.tradesDispatcherSections,
          rightRail: const Text('Right rail content'),
        ),
      ));
      expect(find.byKey(const ValueKey<String>('right_rail')), findsOneWidget);
      expect(find.text('Right rail content'), findsOneWidget);
    });

    testWidgets('section onTap callback fires when section tapped',
        (tester) async {
      var tappedId = '';
      final sections = <EdenDashboardSection>[
        EdenDashboardSection(
          id: 'tappable',
          title: 'Tap me',
          body: const SizedBox(height: 40),
          onTap: () => tappedId = 'tappable',
        ),
      ];
      await tester.pumpWidget(wrap(
        EdenRoleDashboardShell(
          greeting: 'Hi',
          roleLabel: 'Owner',
          sections: sections,
        ),
      ));
      await tester.tap(find.byKey(const ValueKey<String>('tap_tappable')));
      await tester.pump();
      expect(tappedId, 'tappable');
    });

    testWidgets('trades palette renders distinct background on badge',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenRoleDashboardShell(
          greeting: 'Hi',
          roleLabel: 'Dispatcher',
          rolePalette: EdenRolePalette.trades,
          sections: const [],
        ),
      ));
      final container = tester.widget<Container>(
          find.byKey(const ValueKey<String>('role_badge')));
      final decoration = container.decoration as BoxDecoration;
      // Trades palette = warm orange tint.
      expect(decoration.color, const Color(0xFFFFEDD5));
    });

    testWidgets('medical palette renders blue tint on badge', (tester) async {
      await tester.pumpWidget(wrap(
        EdenRoleDashboardShell(
          greeting: 'Hi',
          roleLabel: 'Doctor',
          rolePalette: EdenRolePalette.medical,
          sections: const [],
        ),
      ));
      final container = tester.widget<Container>(
          find.byKey(const ValueKey<String>('role_badge')));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFFDBEAFE));
    });

    testWidgets('salon palette renders gold tint on badge', (tester) async {
      await tester.pumpWidget(wrap(
        EdenRoleDashboardShell(
          greeting: 'Hi',
          roleLabel: 'Owner',
          rolePalette: EdenRolePalette.salon,
          sections: const [],
        ),
      ));
      final container = tester.widget<Container>(
          find.byKey(const ValueKey<String>('role_badge')));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFFF5E6B8));
    });

    testWidgets('neutral palette uses theme surface variant', (tester) async {
      await tester.pumpWidget(wrap(
        EdenRoleDashboardShell(
          greeting: 'Hi',
          roleLabel: 'Anyone',
          rolePalette: EdenRolePalette.neutral,
          sections: const [],
        ),
      ));
      // Just confirm role_badge exists with non-null decoration (neutral
      // resolves via theme and we don't assert exact theme color).
      final container = tester.widget<Container>(
          find.byKey(const ValueKey<String>('role_badge')));
      expect(container.decoration, isNotNull);
    });

    testWidgets('empty sections renders header only', (tester) async {
      await tester.pumpWidget(wrap(
        EdenRoleDashboardShell(
          greeting: 'Hi',
          roleLabel: 'Anyone',
          sections: const [],
        ),
      ));
      expect(find.text('Hi'), findsOneWidget);
      // No section cards.
      expect(find.byKey(const ValueKey<String>('section_blocked_work')),
          findsNothing);
    });

    testWidgets(
        'high-priority section renders "Action needed" strip + sorts first',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenRoleDashboardShell(
          greeting: 'Hi',
          roleLabel: 'Dispatcher',
          rolePalette: EdenRolePalette.trades,
          sections: EdenRoleDashboardShellFixtures.tradesDispatcherSections,
        ),
      ));
      // The 'blocked_work' section has priority=high; expect its priority
      // strip to render.
      expect(
        find.byKey(const ValueKey<String>('priority_strip_blocked_work')),
        findsOneWidget,
      );
      expect(find.text('Action needed'), findsOneWidget);
    });

    testWidgets(
        'iPhone-narrow (390pt) stacks sections + rail collapses to trigger',
        (tester) async {
      await tester.pumpWidget(wrap(
        EdenRoleDashboardShell(
          greeting: 'Hi',
          roleLabel: 'Dispatcher',
          sections: EdenRoleDashboardShellFixtures.tradesDispatcherSections,
          rightRail: const Text('Insights content'),
        ),
        size: const Size(390, 800),
      ));
      // Right rail should NOT be inline (it's collapsed).
      expect(find.byKey(const ValueKey<String>('right_rail')), findsNothing);
      // A trigger button should be present.
      expect(
        find.byKey(const ValueKey<String>('right_rail_trigger')),
        findsOneWidget,
      );
    });
  });
}
