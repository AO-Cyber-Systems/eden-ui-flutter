import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) =>
      MaterialApp(home: Scaffold(body: child));

  group('EdenAsyncFormScaffold', () {
    testWidgets('shows spinner while loading', (tester) async {
      await tester.pumpWidget(wrap(
        EdenAsyncFormScaffold<String>(
          value: const EdenAsyncSnapshot<String>.loading(),
          onHydrate: (_) {},
          builder: (_, __) => const Text('form'),
        ),
      ));
      expect(find.byType(EdenSpinner), findsOneWidget);
      expect(find.text('form'), findsNothing);
    });

    testWidgets('shows error message and retry button on error', (tester) async {
      var retryCalls = 0;
      await tester.pumpWidget(wrap(
        EdenAsyncFormScaffold<String>(
          value: EdenAsyncSnapshot<String>.error(
            Exception('boom'),
            StackTrace.current,
          ),
          onHydrate: (_) {},
          onRetry: () => retryCalls++,
          builder: (_, __) => const Text('form'),
        ),
      ));
      expect(find.text('Failed to load'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('form'), findsNothing);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(retryCalls, 1);
    });

    testWidgets('hides retry when onRetry is null', (tester) async {
      await tester.pumpWidget(wrap(
        EdenAsyncFormScaffold<String>(
          value: EdenAsyncSnapshot<String>.error(
            Exception('boom'),
            StackTrace.current,
          ),
          onHydrate: (_) {},
          builder: (_, __) => const Text('form'),
        ),
      ));
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('renders form body when data arrives', (tester) async {
      await tester.pumpWidget(wrap(
        EdenAsyncFormScaffold<String>(
          value: const EdenAsyncSnapshot<String>.data('hello'),
          onHydrate: (_) {},
          builder: (_, data) => Text('form:$data'),
        ),
      ));
      // first frame builds; hydration is post-frame
      await tester.pump();
      expect(find.text('form:hello'), findsOneWidget);
    });

    testWidgets('invokes onHydrate exactly once', (tester) async {
      final hydrations = <String>[];

      Widget build(EdenAsyncSnapshot<String> snap) => wrap(
            EdenAsyncFormScaffold<String>(
              value: snap,
              onHydrate: hydrations.add,
              builder: (_, data) => Text('form:$data'),
            ),
          );

      // Start in loading
      await tester.pumpWidget(build(const EdenAsyncSnapshot<String>.loading()));
      expect(hydrations, isEmpty);

      // Transition to data — onHydrate fires post-frame
      await tester.pumpWidget(build(const EdenAsyncSnapshot<String>.data('a')));
      await tester.pump();
      expect(hydrations, ['a']);

      // Re-pump with new data — should NOT re-hydrate
      await tester.pumpWidget(build(const EdenAsyncSnapshot<String>.data('b')));
      await tester.pump();
      expect(hydrations, ['a']);
    });

    testWidgets('respects custom error and retry labels', (tester) async {
      await tester.pumpWidget(wrap(
        EdenAsyncFormScaffold<String>(
          value: EdenAsyncSnapshot<String>.error(
            Exception('boom'),
            StackTrace.current,
          ),
          onHydrate: (_) {},
          onRetry: () {},
          errorMessage: 'Could not load profile',
          retryLabel: 'Try again',
          builder: (_, __) => const Text('form'),
        ),
      ));
      expect(find.text('Could not load profile'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });
  });

  group('EdenAsyncSnapshot.when', () {
    test('data branch fires for EdenAsyncData', () {
      final result = const EdenAsyncSnapshot<int>.data(7).when(
        data: (d) => 'data:$d',
        loading: () => 'loading',
        error: (_, __) => 'error',
      );
      expect(result, 'data:7');
    });

    test('loading branch fires for EdenAsyncLoading', () {
      final result = const EdenAsyncSnapshot<int>.loading().when(
        data: (_) => 'data',
        loading: () => 'loading',
        error: (_, __) => 'error',
      );
      expect(result, 'loading');
    });

    test('error branch fires for EdenAsyncError', () {
      final result = EdenAsyncSnapshot<int>.error(
        Exception('boom'),
        StackTrace.empty,
      ).when(
        data: (_) => 'data',
        loading: () => 'loading',
        error: (e, _) => 'error:${e.toString()}',
      );
      expect(result, contains('error:Exception: boom'));
    });

    test('value getter returns data only for hydrated state', () {
      expect(const EdenAsyncSnapshot<int>.data(5).value, 5);
      expect(const EdenAsyncSnapshot<int>.loading().value, isNull);
      expect(
        EdenAsyncSnapshot<int>.error(Exception('x'), StackTrace.empty).value,
        isNull,
      );
    });
  });
}
