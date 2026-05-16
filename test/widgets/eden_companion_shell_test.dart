import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_companion_shell_fixtures.dart';

void main() {
  Widget shellAt({
    required EdenAppMode mode,
    String selectedNavId = 'home',
    ValueChanged<String>? onNavChanged,
    int navCount = 5,
    EdenNetworkStatus networkStatus = EdenNetworkStatus.online,
  }) {
    final c = EdenAppModeController(initialMode: mode);
    final navItems = EdenCompanionShellFixtures.tradesNavItems()
        .take(navCount)
        .toList();
    return MaterialApp(
      home: EdenAppModeScope(
        controller: c,
        child: EdenCompanionShell(
          greeting: 'Good morning, Sarah',
          roleLabel: 'Field Tech',
          rolePalette: EdenRolePalette.trades,
          sections: EdenCompanionShellFixtures.tradesSections(),
          navItems: navItems,
          selectedNavId: selectedNavId,
          onNavChanged: onNavChanged ?? (_) {},
          networkStatus: networkStatus,
        ),
      ),
    );
  }

  Future<void> pumpAtSize(WidgetTester tester, Size size, Widget child) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(child);
    await tester.pump();
  }

  group('EdenCompanionShell — composition smoke', () {
    testWidgets('renders EdenRoleDashboardShell + EdenNetworkStatusBar + EdenUxModeToggle + BottomNavigationBar', (tester) async {
      await pumpAtSize(tester, const Size(390, 800),
          shellAt(mode: EdenAppMode.fieldCompanion));
      expect(find.byType(EdenRoleDashboardShell), findsOneWidget);
      expect(find.byType(EdenNetworkStatusBar), findsOneWidget);
      expect(find.byType(EdenUxModeToggle), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('greeting text passes through', (tester) async {
      await pumpAtSize(tester, const Size(390, 800),
          shellAt(mode: EdenAppMode.fieldCompanion));
      expect(find.text('Good morning, Sarah'), findsOneWidget);
    });

    testWidgets('roleLabel passes through', (tester) async {
      await pumpAtSize(tester, const Size(390, 800),
          shellAt(mode: EdenAppMode.fieldCompanion));
      // roleLabel may appear in both AppBar and the role badge.
      expect(find.text('Field Tech'), findsWidgets);
    });
  });

  group('EdenCompanionShell — bottom-nav behavior', () {
    testWidgets('5 nav items render as 5 BottomNavigationBarItems', (tester) async {
      await pumpAtSize(tester, const Size(390, 800),
          shellAt(mode: EdenAppMode.fieldCompanion));
      final bnb = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      expect(bnb.items.length, 5);
    });

    testWidgets('selectedNavId="jobs" → currentIndex points at jobs', (tester) async {
      await pumpAtSize(tester, const Size(390, 800),
          shellAt(mode: EdenAppMode.fieldCompanion, selectedNavId: 'jobs'));
      final bnb = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      expect(bnb.currentIndex, 1); // jobs is index 1 in the fixture
    });

    testWidgets('tapping a destination fires onNavChanged with the id', (tester) async {
      String? changedId;
      await pumpAtSize(tester, const Size(390, 800),
          shellAt(
            mode: EdenAppMode.fieldCompanion,
            onNavChanged: (id) => changedId = id,
          ));
      await tester.tap(find.byIcon(Icons.inventory_2));
      await tester.pumpAndSettle();
      expect(changedId, 'inventory');
    });

    testWidgets('6+ navItems → assertion error at construction', (tester) async {
      expect(
        () => EdenCompanionShell(
          greeting: 'g',
          roleLabel: 'r',
          sections: const [],
          navItems: const [
            EdenCompanionNavItem(id: '1', label: '1', icon: Icons.circle),
            EdenCompanionNavItem(id: '2', label: '2', icon: Icons.circle),
            EdenCompanionNavItem(id: '3', label: '3', icon: Icons.circle),
            EdenCompanionNavItem(id: '4', label: '4', icon: Icons.circle),
            EdenCompanionNavItem(id: '5', label: '5', icon: Icons.circle),
            EdenCompanionNavItem(id: '6', label: '6', icon: Icons.circle),
          ],
          selectedNavId: '1',
          onNavChanged: (_) {},
        ),
        throwsAssertionError,
      );
    });
  });

  group('EdenCompanionShell — CRITICAL lock E rule 3 enforcement', () {
    testWidgets('CRITICAL — lock E rule 3: companion pins to Compact at 1200pt', (tester) async {
      // 1200pt = Expanded by Material 3 size — but companion mode MUST
      // pin to Compact (BottomNavigationBar visible, expanded marker
      // NOT in tree).
      await pumpAtSize(tester, const Size(1200, 800),
          shellAt(mode: EdenAppMode.fieldCompanion));
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.byKey(const ValueKey('expanded-companion-shell')), findsNothing);
    });
  });

  group('EdenCompanionShell — mode-aware layout switch', () {
    testWidgets('1200pt + admin mode → expanded shell (no BottomNavigationBar)', (tester) async {
      await pumpAtSize(tester, const Size(1200, 800),
          shellAt(mode: EdenAppMode.admin));
      expect(find.byKey(const ValueKey('expanded-companion-shell')),
          findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsNothing);
    });

    testWidgets('setMode flips compact↔expanded at 1200pt', (tester) async {
      final c = EdenAppModeController(initialMode: EdenAppMode.admin);
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(
        home: EdenAppModeScope(
          controller: c,
          child: EdenCompanionShell(
            greeting: 'g',
            roleLabel: 'r',
            sections: EdenCompanionShellFixtures.tradesSections(),
            navItems: EdenCompanionShellFixtures.tradesNavItems(),
            selectedNavId: 'home',
            onNavChanged: (_) {},
          ),
        ),
      ));
      // admin → expanded
      expect(find.byKey(const ValueKey('expanded-companion-shell')),
          findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsNothing);

      // Flip to fieldCompanion → compact
      c.setMode(EdenAppMode.fieldCompanion);
      await tester.pump();
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(
          find.byKey(const ValueKey('expanded-companion-shell')), findsNothing);
    });
  });

  group('EdenCompanionShell — network status embedding', () {
    testWidgets('online → no banner text rendered', (tester) async {
      await pumpAtSize(tester, const Size(390, 800),
          shellAt(mode: EdenAppMode.fieldCompanion));
      expect(find.text('No internet connection'), findsNothing);
    });

    testWidgets('offline → red banner rendered with "No internet connection"', (tester) async {
      await pumpAtSize(
        tester,
        const Size(390, 800),
        shellAt(
          mode: EdenAppMode.fieldCompanion,
          networkStatus: EdenNetworkStatus.offline,
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('No internet connection'), findsOneWidget);
    });
  });

  group('EdenCompanionShell — UX toggle embedding', () {
    testWidgets('tapping the desktop icon in the embedded toggle flips to admin layout', (tester) async {
      final c = EdenAppModeController(initialMode: EdenAppMode.fieldCompanion);
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(
        home: EdenAppModeScope(
          controller: c,
          child: EdenCompanionShell(
            greeting: 'g',
            roleLabel: 'r',
            sections: EdenCompanionShellFixtures.tradesSections(),
            navItems: EdenCompanionShellFixtures.tradesNavItems(),
            selectedNavId: 'home',
            onNavChanged: (_) {},
          ),
        ),
      ));
      // Pinned to Compact (companion mode + 1200pt).
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      // Tap the embedded toggle's "desktop" icon → setMode(admin).
      await tester.tap(find.byIcon(Icons.desktop_windows));
      await tester.pumpAndSettle();
      expect(c.currentMode, EdenAppMode.admin);
      expect(find.byKey(const ValueKey('expanded-companion-shell')),
          findsOneWidget);
    });
  });

  group('EdenCompanionShell — sections passthrough', () {
    testWidgets('all 3 dashboard sections from fixtures render', (tester) async {
      await pumpAtSize(tester, const Size(390, 800),
          shellAt(mode: EdenAppMode.fieldCompanion));
      expect(find.text("Today's appointments"), findsOneWidget);
      expect(find.text('AI insights'), findsOneWidget);
      expect(find.text('Quick actions'), findsOneWidget);
    });
  });

  group('EdenCompanionShell — iPhone-narrow safety', () {
    testWidgets('390pt + fieldCompanion → no overflow', (tester) async {
      await pumpAtSize(tester, const Size(390, 800),
          shellAt(mode: EdenAppMode.fieldCompanion));
      expect(tester.takeException(), isNull);
    });

    testWidgets('390pt: 5 destinations fit in BottomNavigationBar', (tester) async {
      await pumpAtSize(tester, const Size(390, 800),
          shellAt(mode: EdenAppMode.fieldCompanion));
      expect(tester.takeException(), isNull);
      final bnb = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      expect(bnb.items.length, 5);
    });
  });

  group('EdenCompanionShell — missing scope assertion', () {
    testWidgets('mount with no EdenAppModeScope → assertion error', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: EdenCompanionShell(
          greeting: 'g',
          roleLabel: 'r',
          sections: const [],
          navItems: EdenCompanionShellFixtures.tradesNavItems(),
          selectedNavId: 'home',
          onNavChanged: (_) {},
        ),
      ));
      expect(tester.takeException(), isA<AssertionError>());
    });
  });
}
