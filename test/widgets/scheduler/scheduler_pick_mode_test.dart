// Hand-built tests (no LLM-generated test data) for EdenSchedulerPickMode.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

EdenSchedulerDraftBlock _draft(String id, [int hour = 9]) {
  return EdenSchedulerDraftBlock(
    id: id,
    start: DateTime(2026, 5, 16, hour),
    end: DateTime(2026, 5, 16, hour + 1),
  );
}

void main() {
  group('EdenSchedulerPickModeController', () {
    test('initial state is inactive with no drafts', () {
      final c = EdenSchedulerPickModeController();
      expect(c.active, isFalse);
      expect(c.drafts, isEmpty);
    });

    test('enter activates and notifies', () {
      final c = EdenSchedulerPickModeController();
      var notifies = 0;
      c.addListener(() => notifies++);
      c.enter();
      expect(c.active, isTrue);
      expect(notifies, 1);
    });

    test('exit deactivates and clears drafts by default', () {
      final c = EdenSchedulerPickModeController();
      c.enter();
      c.appendDraft(_draft('a'));
      c.exit();
      expect(c.active, isFalse);
      expect(c.drafts, isEmpty);
    });

    test('exit(clearDrafts: false) preserves drafts', () {
      final c = EdenSchedulerPickModeController();
      c.enter();
      c.appendDraft(_draft('a'));
      c.exit(clearDrafts: false);
      expect(c.active, isFalse);
      expect(c.drafts.length, 1);
    });

    test('toggle switches active state', () {
      final c = EdenSchedulerPickModeController();
      c.toggle();
      expect(c.active, isTrue);
      c.toggle();
      expect(c.active, isFalse);
    });

    test('appendDraft adds and notifies', () {
      final c = EdenSchedulerPickModeController();
      var notifies = 0;
      c.addListener(() => notifies++);
      c.appendDraft(_draft('a'));
      expect(c.drafts.length, 1);
      expect(notifies, 1);
    });

    test('removeDraft drops the matching draft', () {
      final c = EdenSchedulerPickModeController();
      c.appendDraft(_draft('a'));
      c.appendDraft(_draft('b'));
      c.removeDraft('a');
      expect(c.drafts.map((d) => d.id), ['b']);
    });

    test('updateDraft replaces via patch fn', () {
      final c = EdenSchedulerPickModeController();
      c.appendDraft(_draft('a', 9));
      c.updateDraft('a', (d) => d.copyWith(label: 'patched'));
      expect(c.drafts.first.label, 'patched');
    });

    test('clearDrafts empties and notifies', () {
      final c = EdenSchedulerPickModeController();
      c.appendDraft(_draft('a'));
      c.appendDraft(_draft('b'));
      var notifies = 0;
      c.addListener(() => notifies++);
      c.clearDrafts();
      expect(c.drafts, isEmpty);
      expect(notifies, 1);
    });

    test('drafts is unmodifiable', () {
      final c = EdenSchedulerPickModeController();
      c.appendDraft(_draft('a'));
      expect(() => c.drafts.add(_draft('b')), throwsUnsupportedError);
    });
  });

  group('EdenSchedulerPickModeBar', () {
    testWidgets('renders nothing when no drafts', (tester) async {
      final c = EdenSchedulerPickModeController();
      addTearDown(c.dispose);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: EdenSchedulerPickModeBar(controller: c)),
      ));
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('renders with count + Save N when drafts present',
        (tester) async {
      final c = EdenSchedulerPickModeController();
      addTearDown(c.dispose);
      c.appendDraft(_draft('a'));
      c.appendDraft(_draft('b'));
      c.appendDraft(_draft('c'));
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: EdenSchedulerPickModeBar(controller: c)),
      ));
      expect(find.text('3 drafts'), findsOneWidget);
      expect(find.text('Save 3'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('Save tap fires onCommit with drafts list', (tester) async {
      final c = EdenSchedulerPickModeController();
      addTearDown(c.dispose);
      c.appendDraft(_draft('a'));
      List<EdenSchedulerDraftBlock>? captured;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EdenSchedulerPickModeBar(
            controller: c,
            onCommit: (drafts) => captured = drafts,
          ),
        ),
      ));
      await tester.tap(find.text('Save 1'));
      expect(captured, isNotNull);
      expect(captured!.length, 1);
    });

    testWidgets('Cancel clears drafts via controller', (tester) async {
      final c = EdenSchedulerPickModeController();
      addTearDown(c.dispose);
      c.appendDraft(_draft('a'));
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: EdenSchedulerPickModeBar(controller: c)),
      ));
      await tester.tap(find.text('Cancel'));
      expect(c.drafts, isEmpty);
    });
  });

  group('EdenSchedulerDraftBlockWidget', () {
    testWidgets('renders default "Draft" label', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EdenSchedulerDraftBlockWidget(draft: _draft('a')),
        ),
      ));
      expect(find.text('Draft'), findsOneWidget);
    });

    testWidgets('custom label renders', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EdenSchedulerDraftBlockWidget(
            draft: EdenSchedulerDraftBlock(
              id: 'a',
              start: DateTime(2026, 5, 16, 9),
              end: DateTime(2026, 5, 16, 10),
              label: 'Custom',
            ),
          ),
        ),
      ));
      expect(find.text('Custom'), findsOneWidget);
    });
  });
}
