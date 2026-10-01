import 'dart:async';

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// VM half of the context-menu timing fix (the chrome half, which reproduces
/// the real framework assert, is `eden_selectable_region_web_test.dart`).
///
/// `kIsWeb` is a compile-time `false` here, so the web path is driven through
/// `debugEdenBrowserContextMenuDisableOverride`, which stands in for
/// `BrowserContextMenu.disableContextMenu()` and lets each test decide WHEN the
/// disable completes. What these tests pin is the widget's own contract: on
/// web it must not build a `SelectableRegion` until the disable has landed,
/// because a region built before the flag flips re-inflates and
/// double-registers its `SelectionContainer` on its next rebuild.
void main() {
  Widget app(Widget child) => MaterialApp(home: Scaffold(body: child));

  /// Runs [body] with `debugPrint` captured, restoring it before the test
  /// binding's end-of-test invariant check (which compares it).
  Future<void> capturingPrints(
    Future<void> Function(List<String> printed) body,
  ) async {
    final List<String> printed = <String>[];
    final DebugPrintCallback original = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      printed.add(message ?? '');
    };
    try {
      await body(printed);
    } finally {
      debugPrint = original;
    }
  }

  Iterable<String> unpreparedWarnings(List<String> printed) => printed
      .where((String line) => line.contains('edenPrepareSelectableRegionForWeb'));

  setUp(edenResetSelectableRegionForTest);
  tearDown(edenResetSelectableRegionForTest);

  group('non-web (the default flutter test platform)', () {
    testWidgets(
        'edenPrepareSelectableRegionForWeb is a no-op and the region is '
        'unchanged: SelectionArea on the first frame, child directly beneath',
        (tester) async {
      // Inert-setup guard: the whole point of this group is the kIsWeb=false
      // path; if this ever ran on web the assertions below mean nothing.
      expect(kIsWeb, isFalse);

      final List<MethodCall> channelCalls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.contextMenu,
        (MethodCall call) async {
          channelCalls.add(call);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.contextMenu, null),
      );

      await capturingPrints((List<String> printed) async {
        await edenPrepareSelectableRegionForWeb();

        const Widget child = Text('non-web');
        await tester.pumpWidget(app(const EdenSelectableRegion(child: child)));

        expect(channelCalls, isEmpty,
            reason: 'nothing may reach the context-menu channel off web');
        expect(find.byType(SelectableRegion), findsOneWidget,
            reason: 'off web the SelectionArea is installed on the first frame');
        expect(
          tester.widget<SelectionArea>(find.byType(SelectionArea)).child,
          same(child),
          reason: 'off web the child must sit directly under SelectionArea — '
              'no deferral key, i.e. the pre-fix widget tree exactly',
        );
        expect(unpreparedWarnings(printed), isEmpty);
      });
    });
  });

  group('web path (debugEdenBrowserContextMenuDisableOverride)', () {
    testWidgets(
        'app did NOT prepare: the region builds no SelectionArea until the '
        'disable completes, then installs one without re-creating its child',
        (tester) async {
      final Completer<void> disable = Completer<void>();
      int disableCalls = 0;
      debugEdenBrowserContextMenuDisableOverride = () {
        disableCalls++;
        return disable.future;
      };
      int probeInits = 0;
      final ValueNotifier<int> tick = ValueNotifier<int>(0);
      addTearDown(tick.dispose);

      await capturingPrints((List<String> printed) async {
        await tester.pumpWidget(app(
          ValueListenableBuilder<int>(
            valueListenable: tick,
            builder: (BuildContext context, int n, Widget? _) =>
                EdenSelectableRegion(
              child: Column(
                children: <Widget>[
                  Text('line $n'),
                  _Probe(onInit: () => probeInits++),
                ],
              ),
            ),
          ),
        ));

        expect(disableCalls, 1);
        expect(find.byType(SelectableRegion), findsNothing,
            reason: 'a SelectableRegion built now would see the flag before '
                'the flip and re-inflate its SelectionContainer after it');
        expect(find.text('line 0'), findsOneWidget,
            reason: 'the child still renders while the region waits');

        // Rebuilds while the disable is in flight keep deferring.
        tick.value = 1;
        await tester.pump();
        expect(find.byType(SelectableRegion), findsNothing);
        expect(unpreparedWarnings(printed), hasLength(1),
            reason: 'one debug warning pointing at the pre-runApp API');

        final State<_Probe> probe = tester.state(find.byType(_Probe));

        disable.complete();
        // Let the completion propagate (it is several microtask hops to the
        // region's setState), then build the frame that setState scheduled.
        await tester.idle();
        await tester.pump();

        expect(find.byType(SelectableRegion), findsOneWidget,
            reason: 'the SelectionArea is installed once the disable lands');
        expect(find.text('line 1'), findsOneWidget);
        expect(tester.state(find.byType(_Probe)), same(probe),
            reason: 'installing the SelectionArea must MOVE the child, not '
                're-create it (initState side effects would run twice)');
        expect(probeInits, 1);

        // After install the region is stable: later rebuilds reuse the same
        // SelectableRegion and SelectionContainer States.
        final State<StatefulWidget> region =
            tester.state(find.byType(SelectableRegion));
        final State<StatefulWidget> container = tester.state(find
            .descendant(
              of: find.byType(SelectableRegion),
              matching: find.byType(SelectionContainer),
            )
            .first);
        tick.value = 2;
        await tester.pump();
        expect(tester.state(find.byType(SelectableRegion)), same(region));
        expect(
          tester.state(find
              .descendant(
                of: find.byType(SelectableRegion),
                matching: find.byType(SelectionContainer),
              )
              .first),
          same(container),
        );
        expect(disableCalls, 1);
        expect(unpreparedWarnings(printed), hasLength(1));
      });
    });

    testWidgets(
        'nested plain regions stay ONE selection scope before and after the '
        'deferred install, sharing one disable call and one warning',
        (tester) async {
      final Completer<void> disable = Completer<void>();
      int disableCalls = 0;
      debugEdenBrowserContextMenuDisableOverride = () {
        disableCalls++;
        return disable.future;
      };

      await capturingPrints((List<String> printed) async {
        await tester.pumpWidget(app(
          const EdenSelectableRegion(
            child: Column(
              children: <Widget>[
                Text('outer'),
                EdenSelectableRegion(child: Text('inner')),
              ],
            ),
          ),
        ));
        expect(find.byType(SelectionArea), findsNothing);

        disable.complete();
        await tester.idle();
        await tester.pump();

        expect(find.byType(SelectionArea), findsOneWidget,
            reason: 'the inner plain region must still collapse into the '
                'outer one, as it does off web');
        expect(disableCalls, 1);
        expect(unpreparedWarnings(printed), hasLength(1));
      });
    });

    testWidgets(
        'app prepared: regions install on the first frame, the disable is '
        'never re-issued, and nothing is printed', (tester) async {
      int disableCalls = 0;
      debugEdenBrowserContextMenuDisableOverride = () async {
        disableCalls++;
      };

      await capturingPrints((List<String> printed) async {
        await edenPrepareSelectableRegionForWeb();
        expect(disableCalls, 1);
        await edenPrepareSelectableRegionForWeb();
        expect(disableCalls, 1, reason: 'idempotent once it has succeeded');

        const Widget a = Text('a');
        await tester.pumpWidget(app(
          const Column(
            children: <Widget>[
              EdenSelectableRegion(child: a),
              EdenSelectableRegion(child: Text('b')),
            ],
          ),
        ));

        expect(find.byType(SelectableRegion), findsNWidgets(2),
            reason: 'nothing to wait for — install on the first frame');
        expect(
          tester.widget<SelectionArea>(find.byType(SelectionArea).first).child,
          same(a),
          reason: 'a prepared app gets the pre-fix tree exactly (no key)',
        );
        expect(disableCalls, 1, reason: 'regions share the latch');
        expect(unpreparedWarnings(printed), isEmpty);
      });
    });

    testWidgets('concurrent callers join the one in-flight attempt',
        (tester) async {
      final Completer<void> disable = Completer<void>();
      int disableCalls = 0;
      debugEdenBrowserContextMenuDisableOverride = () {
        disableCalls++;
        return disable.future;
      };

      await capturingPrints((List<String> printed) async {
        bool firstDone = false;
        bool secondDone = false;
        unawaited(edenPrepareSelectableRegionForWeb()
            .then((_) => firstDone = true));
        unawaited(edenPrepareSelectableRegionForWeb()
            .then((_) => secondDone = true));
        await tester.pumpWidget(
          app(const EdenSelectableRegion(child: Text('joined'))),
        );
        expect(disableCalls, 1);
        expect(firstDone || secondDone, isFalse,
            reason: 'callers must wait for the disable, not return early');

        disable.complete();
        await tester.pump();
        expect(firstDone && secondDone, isTrue);
        expect(find.byType(SelectableRegion), findsOneWidget);
        expect(disableCalls, 1);
      });
    });

    testWidgets(
        'a failed disable is reported, never thrown, and not latched; a region '
        'waiting on it still installs', (tester) async {
      int disableCalls = 0;
      debugEdenBrowserContextMenuDisableOverride = () async {
        disableCalls++;
        if (disableCalls <= 2) {
          throw StateError('context-menu channel down #$disableCalls');
        }
      };

      await capturingPrints((List<String> printed) async {
        // 1: the app's own call fails. It must complete normally (boot is not
        // blocked) and report through FlutterError.
        await edenPrepareSelectableRegionForWeb();
        expect(disableCalls, 1);
        final Object? first = tester.takeException();
        expect(first, isA<StateError>());
        expect('$first', contains('#1'));

        // 2: not latched, so the region retries; that attempt fails too, and
        // the region must still install rather than wait forever.
        await tester.pumpWidget(
          app(const EdenSelectableRegion(child: Text('after failure'))),
        );
        await tester.pump();
        expect(disableCalls, 2);
        expect('${tester.takeException()}', contains('#2'));
        expect(find.byType(SelectableRegion), findsOneWidget);

        // 3: the next call retries and succeeds; after that, nothing re-issues.
        await edenPrepareSelectableRegionForWeb();
        expect(disableCalls, 3);
        await edenPrepareSelectableRegionForWeb();
        expect(disableCalls, 3);
        expect(tester.takeException(), isNull);
      });
    });
  });
}

/// Counts `initState` so a test can tell a MOVED subtree from a re-created one.
class _Probe extends StatefulWidget {
  const _Probe({required this.onInit});

  final VoidCallback onInit;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  Widget build(BuildContext context) => const Text('probe');
}
