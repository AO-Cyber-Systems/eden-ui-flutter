// test/dev_app/explorer/story_shell_test.dart
//
// Widget smoke gate for the Flutter explorer shell (TRD 38-02): the shell
// pumps at desktop width, sidebar selection drives the canvas, a knob change
// updates the preview, and the search field filters the sidebar. Stories are
// registered/cleared per-test so the StoryRegistry singleton doesn't bleed.

import 'package:eden_ui_flutter/dev_app/explorer/canvas.dart';
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
        id: 'demo/static',
        component: 'demo',
        name: 'static',
        knobs: const [],
        build: (ctx, k) => const Text('STATIC'),
      ),
    );
    StoryRegistry.instance.register(
      EdenStory(
        id: 'demo/toggle',
        component: 'demo',
        name: 'toggle',
        knobs: const [BoolKnob(key: 'on', label: 'On', defaultValue: false)],
        build: (ctx, k) => Text(k.get<bool>('on') ? 'ON' : 'OFF'),
      ),
    );
  });

  tearDown(() => StoryRegistry.instance.clear());

  Future<void> pumpShell(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: StoryShell())),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
  }

  testWidgets('shell pumps at desktop width without exception', (tester) async {
    await pumpShell(tester);
    expect(find.byType(StoryShell), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selecting a sidebar story renders it on the canvas', (tester) async {
    await pumpShell(tester);
    // 'demo/toggle' selects to its preview text 'OFF'.
    await tester.tap(find.text('toggle'));
    await tester.pump();
    expect(find.text('OFF'), findsOneWidget);
  });

  testWidgets('a knob change updates the preview', (tester) async {
    await pumpShell(tester);
    await tester.tap(find.text('toggle'));
    await tester.pump();
    expect(find.text('OFF'), findsOneWidget);

    // Disambiguate the knob's Switch from the toolbar's 'Dark' Switch.
    final knobSwitch = find.descendant(
      of: find.byType(KnobPanel),
      matching: find.byType(Switch),
    );
    expect(knobSwitch, findsOneWidget);
    await tester.tap(knobSwitch);
    await tester.pump();
    expect(find.text('ON'), findsOneWidget);
  });

  testWidgets('search filters the sidebar', (tester) async {
    await pumpShell(tester);
    // Use 'tog' so the TextField text doesn't collide with the 'toggle' entry.
    await tester.enterText(find.byType(TextField), 'tog');
    await tester.pump();
    expect(find.text('static'), findsNothing);
    expect(find.text('toggle'), findsOneWidget);
  });
}
