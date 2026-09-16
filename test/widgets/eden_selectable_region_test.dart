import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: Center(child: child)));
  }

  group('EdenSelectableRegion', () {
    testWidgets('installs exactly one SelectableRegion over plain Text',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenSelectableRegion(
          child: Column(
            children: <Widget>[
              Text('first line'),
              Text('second line'),
            ],
          ),
        ),
      ));

      // Reproduces 40-RESEARCH.md Appendix A probe 4: one SelectionArea over
      // two plain Text widgets installs exactly ONE SelectableRegion, and the
      // Text widgets need no per-widget change to become selectable.
      expect(find.byType(SelectableRegion), findsOneWidget);
      expect(find.byType(SelectionArea), findsOneWidget);
      expect(find.text('first line'), findsOneWidget);
      expect(find.text('second line'), findsOneWidget);
      expect(find.byType(SelectableText), findsNothing,
          reason: 'SelectableText nested in a SelectionArea creates an '
              'un-draggable selection island — plain Text is the contract.');
    });

    testWidgets('enabled: false is a pass-through', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenSelectableRegion(
          enabled: false,
          child: Text('pass through'),
        ),
      ));

      expect(find.byType(SelectableRegion), findsNothing);
      expect(find.byType(SelectionArea), findsNothing);
      expect(find.text('pass through'), findsOneWidget,
          reason: 'the child must still render untouched');
    });

    testWidgets(
        'nested regions install exactly one SelectableRegion for the inner '
        'subtree', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenSelectableRegion(
          child: EdenSelectableRegion(
            child: Text('nested text'),
          ),
        ),
      ));

      expect(tester.takeException(), isNull,
          reason: 'nesting must never throw — TRD 40-06 bakes this widget into '
              'BOTH the Eden layouts and the library pages.');
      expect(find.text('nested text'), findsOneWidget,
          reason: 'text under a nested region must stay reachable');

      // The invariant that matters: the INNER subtree has exactly one owning
      // region, because SelectionArea scopes selection to the nearest ancestor
      // registrar. The inner region is redundant, not harmful.
      expect(
        find.descendant(
          of: find.byType(EdenSelectableRegion).last,
          matching: find.byType(SelectableRegion),
        ),
        findsOneWidget,
      );

      // Observed total count for the nested pair, recorded in 40-02-SUMMARY:
      // one SelectableRegion per EdenSelectableRegion (no de-duplication).
      expect(find.byType(SelectableRegion), findsNWidgets(2));
    });

    testWidgets('SelectionContainer.disabled excludes a subtree',
        (tester) async {
      SelectionRegistrar? includedRegistrar;
      SelectionRegistrar? excludedRegistrar;

      await tester.pumpWidget(wrap(
        EdenSelectableRegion(
          child: Column(
            children: <Widget>[
              Builder(
                builder: (BuildContext context) {
                  includedRegistrar = SelectionContainer.maybeOf(context);
                  return const Text('included');
                },
              ),
              SelectionContainer.disabled(
                child: Builder(
                  builder: (BuildContext context) {
                    excludedRegistrar = SelectionContainer.maybeOf(context);
                    return const Text('excluded');
                  },
                ),
              ),
            ],
          ),
        ),
      ));

      expect(tester.takeException(), isNull);
      expect(find.text('included'), findsOneWidget);
      expect(find.text('excluded'), findsOneWidget);

      // Structural proof of the opt-out, not a clipboard assertion: a real
      // drag-select is not reliably driveable in a widget test.
      expect(includedRegistrar, isNotNull,
          reason: 'text outside the disabled subtree still sees the region '
              'registrar');
      expect(excludedRegistrar, isNull,
          reason: 'SelectionContainer.disabled contributes no registrar to the '
              'subtree — widgets/selection_container.dart:65');

      final Iterable<SelectionContainer> disabledContainers = tester
          .widgetList<SelectionContainer>(find.byType(SelectionContainer))
          .where((SelectionContainer c) => c.delegate == null);
      expect(disabledContainers, isNotEmpty,
          reason: 'the disabled container is the delegate-less variant');
    });

    testWidgets('onSelectionChanged is forwarded to SelectionArea',
        (tester) async {
      void onSelectionChanged(SelectedContent? content) {}

      await tester.pumpWidget(wrap(
        EdenSelectableRegion(
          onSelectionChanged: onSelectionChanged,
          child: const Text('forwarded'),
        ),
      ));

      final SelectionArea area =
          tester.widget<SelectionArea>(find.byType(SelectionArea));
      expect(area.onSelectionChanged, same(onSelectionChanged),
          reason: 'onSelectionChanged (plain text only) is the entire '
              'selection-notification surface at the >=3.27.0 floor');
    });

    testWidgets(
        'contextMenuBuilder defaults to SelectionArea Material default when '
        'not supplied', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenSelectableRegion(child: Text('menu')),
      ));

      final SelectionArea area =
          tester.widget<SelectionArea>(find.byType(SelectionArea));
      expect(area.contextMenuBuilder, isNotNull,
          reason: 'we must NOT forward a null contextMenuBuilder — '
              'SelectionArea defaults it to _defaultContextMenuBuilder '
              '(material/selection_area.dart:54) and forwarding null would '
              'replace that default with no menu at all');
    });

    testWidgets('an explicit contextMenuBuilder is forwarded unchanged',
        (tester) async {
      Widget builder(
        BuildContext context,
        SelectableRegionState selectableRegionState,
      ) {
        return const SizedBox.shrink();
      }

      await tester.pumpWidget(wrap(
        EdenSelectableRegion(
          contextMenuBuilder: builder,
          child: const Text('custom menu'),
        ),
      ));

      final SelectionArea area =
          tester.widget<SelectionArea>(find.byType(SelectionArea));
      expect(area.contextMenuBuilder, same(builder));
    });

    testWidgets('does not throw on non-web', (tester) async {
      // kIsWeb is a compile-time const and is false in the VM test
      // environment, so the BrowserContextMenu branch is not exercised here.
      // What this documents is that the kIsWeb guard holds: nothing is called
      // and nothing throws off-web, while the region is still installed.
      await tester.pumpWidget(wrap(
        const EdenSelectableRegion(child: Text('non-web')),
      ));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(SelectableRegion), findsOneWidget);
      expect(find.text('non-web'), findsOneWidget);
    });
  });
}
