// test/dev_app/explorer/routing_test.dart
//
// Routing gate for the Flutter explorer (TRD 38-03): generateExplorerRoute
// resolves '/', '/story/<known>', and falls back to the landing on unknown
// routes; tapping a sidebar story deep-links to '/story/<id>'. Stories are
// registered/cleared per-test so the StoryRegistry singleton doesn't bleed.

import 'package:eden_ui_flutter/dev_app/dev_app.dart';
import 'package:eden_ui_flutter/dev_app/explorer/story_shell.dart';
import 'package:eden_ui_flutter/dev_app/registry/eden_story.dart';
import 'package:eden_ui_flutter/dev_app/registry/story_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    StoryRegistry.instance.clear();
    StoryRegistry.instance.register(
      EdenStory(
        id: 'demo/known',
        component: 'demo',
        name: 'known',
        knobs: const [],
        build: (_, __) => const Text('KNOWN'),
      ),
    );
  });

  tearDown(() => StoryRegistry.instance.clear());

  // --- generateExplorerRoute in isolation: settings preserved for known ids ---
  test('generateExplorerRoute preserves the route name for / and known story', () {
    final landing = generateExplorerRoute(const RouteSettings(name: '/'));
    expect(landing.settings.name, '/');
    final known = generateExplorerRoute(const RouteSettings(name: '/story/demo/known'));
    expect(known.settings.name, '/story/demo/known');
  });

  void sizeDesktop(WidgetTester tester) {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('routes resolve known / unknown story deep links to StoryShell',
      (tester) async {
    sizeDesktop(tester);
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(navigatorKey: nav, onGenerateRoute: generateExplorerRoute),
    );
    await tester.pumpAndSettle();

    // Landing → no initial story.
    expect(tester.widget<StoryShell>(find.byType(StoryShell)).initialStoryId, isNull);

    // Known deep link → focused on that story.
    nav.currentState!.pushNamed('/story/demo/known');
    await tester.pumpAndSettle();
    expect(
      tester.widget<StoryShell>(find.byType(StoryShell).last).initialStoryId,
      'demo/known',
    );

    // Unknown deep link → fallback landing (never a null route).
    nav.currentState!.pushNamed('/story/does/not-exist');
    await tester.pumpAndSettle();
    expect(
      tester.widget<StoryShell>(find.byType(StoryShell).last).initialStoryId,
      isNull,
    );
  });

  testWidgets('tapping a sidebar story deep-links to /story/<id>', (tester) async {
    sizeDesktop(tester);
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(navigatorKey: nav, onGenerateRoute: generateExplorerRoute),
    );
    await tester.pumpAndSettle();

    // The landing sidebar lists 'known'; tapping it deep-links and rebuilds the
    // shell focused on that story.
    await tester.tap(find.text('known'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<StoryShell>(find.byType(StoryShell)).initialStoryId,
      'demo/known',
    );
  });
}
