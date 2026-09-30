@TestOn('browser')
library;

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Chrome half of the context-menu timing fix — the REAL framework failure.
///
/// `SelectableRegion.build` wraps its unkeyed `SelectionContainer` in
/// `PlatformSelectableRegionContextMenu` only while
/// `kIsWeb && BrowserContextMenu.enabled` (and not on Android/iOS). A region
/// built before `disableContextMenu()` lands and rebuilt after it re-inflates
/// that container, which double-registers in the region's single `_selectable`
/// slot: `assert(_selectable == null)` in debug, "Null check operator used on a
/// null value" in release. First found in eden-biz's web console, whose shell
/// is an app-owned `SelectionArea` around an Eden layout.
///
/// Browser-only because the wrapper is gated on `kIsWeb`, and pinned to a
/// desktop target platform because flutter_test defaults to android, which
/// `_webContextMenuEnabled` excludes. Run with:
///   flutter test --platform chrome test/widgets/eden_selectable_region_web_test.dart
///
/// The plain VM `flutter test` run skips this file (`@TestOn('browser')`).
void main() {
  late List<MethodCall> channelCalls;

  /// Inert-setup guard, run first in every test: off web, or on the default
  /// android target, SelectableRegion never adds the wrapper and every test
  /// here would pass with or without the fix.
  void expectWrapperCanAppear() {
    expect(kIsWeb, isTrue);
    expect(defaultTargetPlatform, TargetPlatform.macOS);
    expect(BrowserContextMenu.enabled, isTrue,
        reason: 'each test must start with the menu enabled, or there is no '
            'flip to survive');
  }

  void mockContextMenuChannel(WidgetTester tester) {
    channelCalls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.contextMenu,
      (MethodCall call) async {
        channelCalls.add(call);
        return null;
      },
    );
    // Tear-downs run last-registered-first: re-enable (needs the mock) before
    // the mock is removed, then clear the library's latch.
    addTearDown(edenResetSelectableRegionForTest);
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.contextMenu, null),
    );
    addTearDown(BrowserContextMenu.enableContextMenu);
  }

  int disableCallCount() => channelCalls
      .where((MethodCall call) => call.method == 'disableContextMenu')
      .length;

  /// Returns the exception from the last frame, if any. The chrome runner
  /// sends FlutterError details to the browser console, so the text must
  /// travel in the returned value / `reason` to be visible in the report.
  Object? takeFrameError(WidgetTester tester, String step) {
    final Object? error = tester.takeException();
    if (error != null) {
      printOnFailure('after $step: $error');
    }
    return error;
  }

  /// Mirrors eden-biz's BizShell: an app-owned SelectionArea that owns text
  /// directly (sidebar / top bar) around an EdenSelectableRegion (the Eden
  /// layout's body wrapper). Both are first built on the same frame.
  Widget shell(ValueNotifier<int> tick) => MaterialApp(
        home: ValueListenableBuilder<int>(
          valueListenable: tick,
          builder: (BuildContext context, int n, Widget? _) => SelectionArea(
            child: Scaffold(
              body: Column(
                children: <Widget>[
                  Text('nav $n'),
                  Expanded(
                    child: EdenSelectableRegion(
                      child: n < 2 ? Text('page $n') : const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  /// First frame, a shell rebuild (route change after data arrives), then the
  /// body emptying — the sequence that hits `remove()` in release. Returns the
  /// first frame error, or null.
  Future<Object?> driveShell(WidgetTester tester, ValueNotifier<int> tick) async {
    await tester.pumpWidget(shell(tick));
    await tester.pump();
    final Object? first = takeFrameError(tester, 'first frame');
    if (first != null) {
      return first;
    }
    tick.value = 1;
    await tester.pump();
    final Object? rebuild = takeFrameError(tester, 'shell rebuild');
    if (rebuild != null) {
      return rebuild;
    }
    tick.value = 2;
    await tester.pump();
    await tester.pump();
    return takeFrameError(tester, 'body emptied');
  }

  testWidgets(
      'CONTROL: an app-owned SelectionArea IS broken when the app does not '
      'prepare — the widget cannot protect it', (tester) async {
    expectWrapperCanAppear();
    mockContextMenuChannel(tester);
    final ValueNotifier<int> tick = ValueNotifier<int>(0);
    addTearDown(tick.dispose);

    final Object? error = await driveShell(tester, tick);

    // Proves this harness can see the failure at all (the prepared test below
    // would otherwise pass vacuously), and pins WHY the pre-runApp call exists.
    // If Flutter ever keys SelectableRegion's SelectionContainer this goes red:
    // the pre-runApp requirement can then be relaxed.
    expect(error, isNotNull,
        reason: 'expected the double-registration assert in SelectableRegion');
    expect('$error', contains('_selectable == null'));
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets(
      'an app-owned SelectionArea survives when the app awaits '
      'edenPrepareSelectableRegionForWeb before building', (tester) async {
    expectWrapperCanAppear();
    mockContextMenuChannel(tester);
    final ValueNotifier<int> tick = ValueNotifier<int>(0);
    addTearDown(tick.dispose);

    // The code under test: main() awaits this before runApp.
    await edenPrepareSelectableRegionForWeb();
    // Recorded, asserted after the shell runs: the shell error is the
    // informative failure, so it must not be pre-empted by these.
    final bool enabledAfterPrepare = BrowserContextMenu.enabled;
    final int callsAfterPrepare = disableCallCount();

    final Object? error = await driveShell(tester, tick);
    expect(error, isNull, reason: '$error');
    expect(enabledAfterPrepare, isFalse,
        reason: 'the menu must be off when the call returns');
    expect(callsAfterPrepare, 1);
    expect(find.byType(PlatformSelectableRegionContextMenu), findsNothing);
    expect(disableCallCount(), 1,
        reason: 'the region shares the latch and never re-issues the call');
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets(
      'a region that owns its text survives the flip WITHOUT the app '
      'preparing: it defers its own SelectionArea until the disable lands',
      (tester) async {
    expectWrapperCanAppear();
    mockContextMenuChannel(tester);
    final ValueNotifier<int> tick = ValueNotifier<int>(0);
    addTearDown(tick.dispose);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ValueListenableBuilder<int>(
          valueListenable: tick,
          builder: (BuildContext context, int n, Widget? _) =>
              EdenSelectableRegion(
            child: n < 2 ? Text('page $n') : const SizedBox.shrink(),
          ),
        ),
      ),
    ));
    // Observe everything first, assert afterwards: the chrome runner sends a
    // failed expect's details to the browser console, so the informative
    // failure (the framework's own assert) must be the one that surfaces, via
    // printOnFailure, rather than being pre-empted by a structural check.
    final List<String> errors = <String>[];
    void record(String step) {
      final Object? error = takeFrameError(tester, step);
      if (error != null) {
        errors.add('after $step: $error');
      }
    }

    Finder ownContainer() => find
        .descendant(
          of: find.byType(SelectableRegion),
          matching: find.byType(SelectionContainer),
        )
        .first;

    record('first frame');
    final int wrappersOnFirstFrame =
        find.byType(PlatformSelectableRegionContextMenu).evaluate().length;

    await tester.pump();
    record('install');
    final bool enabledAtInstall = BrowserContextMenu.enabled;
    final State<StatefulWidget> container = tester.state(ownContainer());

    tick.value = 1;
    await tester.pump();
    record('rebuild');
    final bool containerSurvived =
        identical(tester.state(ownContainer()), container);
    if (!containerSurvived) {
      printOnFailure('the region re-inflated its own SelectionContainer');
    }

    tick.value = 2;
    await tester.pump();
    await tester.pump();
    record('body emptied');

    expect(errors, isEmpty, reason: errors.join('\n'));
    expect(containerSurvived, isTrue,
        reason: 'the region must not re-inflate its own SelectionContainer');
    expect(wrappersOnFirstFrame, 0,
        reason: 'no SelectableRegion may be built while the flag is true');
    expect(enabledAtInstall, isFalse);
    expect(find.byType(SelectableRegion), findsOneWidget);
    expect(disableCallCount(), 1);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets(
      'an app that disabled the menu itself: regions neither re-issue the '
      'call nor defer', (tester) async {
    expectWrapperCanAppear();
    mockContextMenuChannel(tester);

    await BrowserContextMenu.disableContextMenu();
    expect(disableCallCount(), 1);

    await tester.pumpWidget(
      const MaterialApp(home: EdenSelectableRegion(child: Text('already off'))),
    );
    expect(find.byType(SelectableRegion), findsOneWidget,
        reason: 'the menu is already off, so install on the first frame');
    expect(disableCallCount(), 1);
    await edenPrepareSelectableRegionForWeb();
    expect(disableCallCount(), 1);
    expect(takeFrameError(tester, 'first frame'), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
}
