import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_pipeline_badge_fixtures.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('EdenPipelineBadge', () {
    testWidgets('renders Draft + edit_outlined for stage=draft',
        (tester) async {
      await tester
          .pumpWidget(wrap(const EdenPipelineBadge(stage: 'draft')));
      expect(find.text('Draft'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    });

    testWidgets('renders Sent + send_outlined for stage=sent',
        (tester) async {
      await tester.pumpWidget(wrap(const EdenPipelineBadge(stage: 'sent')));
      expect(find.text('Sent'), findsOneWidget);
      expect(find.byIcon(Icons.send_outlined), findsOneWidget);
    });

    testWidgets('renders Won + check_circle_outline for stage=won',
        (tester) async {
      await tester.pumpWidget(wrap(const EdenPipelineBadge(stage: 'won')));
      expect(find.text('Won'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('renders Lost + cancel_outlined for stage=lost',
        (tester) async {
      await tester.pumpWidget(wrap(const EdenPipelineBadge(stage: 'lost')));
      expect(find.text('Lost'), findsOneWidget);
      expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
    });

    testWidgets('renders Expired + schedule_outlined for stage=expired',
        (tester) async {
      await tester
          .pumpWidget(wrap(const EdenPipelineBadge(stage: 'expired')));
      expect(find.text('Expired'), findsOneWidget);
      expect(find.byIcon(Icons.schedule_outlined), findsOneWidget);
    });

    testWidgets("alias 'accepted' renders as Won",
        (tester) async {
      await tester
          .pumpWidget(wrap(const EdenPipelineBadge(stage: 'accepted')));
      expect(find.text('Won'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets("alias 'rejected' renders as Lost",
        (tester) async {
      await tester
          .pumpWidget(wrap(const EdenPipelineBadge(stage: 'rejected')));
      expect(find.text('Lost'), findsOneWidget);
      expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
    });

    testWidgets("case-insensitive: 'WON' renders identical to 'won'",
        (tester) async {
      await tester.pumpWidget(wrap(const EdenPipelineBadge(stage: 'WON')));
      expect(find.text('Won'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets("case-insensitive: 'Sent' renders identical to 'sent'",
        (tester) async {
      await tester
          .pumpWidget(wrap(const EdenPipelineBadge(stage: 'Sent')));
      expect(find.text('Sent'), findsOneWidget);
      expect(find.byIcon(Icons.send_outlined), findsOneWidget);
    });

    testWidgets('unknown stage renders Unknown + help_outline',
        (tester) async {
      await tester.pumpWidget(
          wrap(const EdenPipelineBadge(stage: 'invented_stage')));
      expect(find.text('Unknown'), findsOneWidget);
      expect(find.byIcon(Icons.help_outline), findsOneWidget);
    });

    testWidgets('iPhone-narrow: no overflow inside SizedBox(width: 100)',
        (tester) async {
      for (final stage in [
        ...EdenPipelineBadgeFixtures.knownStages,
        ...EdenPipelineBadgeFixtures.aliasMap.keys,
        'invented_stage',
      ]) {
        await tester.pumpWidget(wrap(
          SizedBox(width: 100, child: EdenPipelineBadge(stage: stage)),
        ));
        expect(tester.takeException(), isNull,
            reason: 'overflowed for stage=$stage');
      }
    });
  });
}
