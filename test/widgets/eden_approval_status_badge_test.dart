import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('EdenApprovalStatusBadge', () {
    testWidgets('renders Pending for status=pending', (tester) async {
      await tester.pumpWidget(
          wrap(const EdenApprovalStatusBadge(status: 'pending')));
      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('renders Pending for alias status=pending_approval',
        (tester) async {
      await tester.pumpWidget(
          wrap(const EdenApprovalStatusBadge(status: 'pending_approval')));
      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('renders Approved for status=approved', (tester) async {
      await tester.pumpWidget(
          wrap(const EdenApprovalStatusBadge(status: 'approved')));
      expect(find.text('Approved'), findsOneWidget);
    });

    testWidgets('renders Rejected for status=rejected', (tester) async {
      await tester.pumpWidget(
          wrap(const EdenApprovalStatusBadge(status: 'rejected')));
      expect(find.text('Rejected'), findsOneWidget);
    });

    testWidgets('renders Draft for status=draft', (tester) async {
      await tester.pumpWidget(
          wrap(const EdenApprovalStatusBadge(status: 'draft')));
      expect(find.text('Draft'), findsOneWidget);
    });

    testWidgets('renders Ordered for status=ordered', (tester) async {
      await tester.pumpWidget(
          wrap(const EdenApprovalStatusBadge(status: 'ordered')));
      expect(find.text('Ordered'), findsOneWidget);
    });

    testWidgets('renders Received for status=received', (tester) async {
      await tester.pumpWidget(
          wrap(const EdenApprovalStatusBadge(status: 'received')));
      expect(find.text('Received'), findsOneWidget);
    });

    testWidgets("renders 'In Transit' (hand-written, with space) for status=in_transit",
        (tester) async {
      await tester.pumpWidget(
          wrap(const EdenApprovalStatusBadge(status: 'in_transit')));
      expect(find.text('In Transit'), findsOneWidget);
    });

    testWidgets('renders Completed for status=completed', (tester) async {
      await tester.pumpWidget(
          wrap(const EdenApprovalStatusBadge(status: 'completed')));
      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets('renders Fulfilled for status=fulfilled', (tester) async {
      await tester.pumpWidget(
          wrap(const EdenApprovalStatusBadge(status: 'fulfilled')));
      expect(find.text('Fulfilled'), findsOneWidget);
    });

    testWidgets('renders Cancelled for status=cancelled', (tester) async {
      await tester.pumpWidget(
          wrap(const EdenApprovalStatusBadge(status: 'cancelled')));
      expect(find.text('Cancelled'), findsOneWidget);
    });

    testWidgets(
        "case-sensitive switch: 'Approved' (uppercase) falls through to default branch (label='Approved' via no-op replaceAll, onSurfaceVariant tone)",
        (tester) async {
      final theme = ThemeData.light();
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: EdenApprovalStatusBadge(status: 'Approved'),
        ),
      ));
      expect(find.text('Approved'), findsOneWidget);
      final textWidget = tester.widget<Text>(find.text('Approved'));
      expect(textWidget.style?.color, theme.colorScheme.onSurfaceVariant);
    });

    testWidgets(
        "unknown status with underscore: 'in_review' renders 'in review' (replaceAll fallback)",
        (tester) async {
      await tester.pumpWidget(
          wrap(const EdenApprovalStatusBadge(status: 'in_review')));
      expect(find.text('in review'), findsOneWidget);
    });

    testWidgets('fontSize override is applied to the Text style',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenApprovalStatusBadge(status: 'approved', fontSize: 20),
      ));
      final textWidget = tester.widget<Text>(find.text('Approved'));
      expect(textWidget.style?.fontSize, 20);
    });

    testWidgets(
        'iPhone-narrow: no overflow inside SizedBox(width: 90) for all 11 known statuses',
        (tester) async {
      for (final status in const [
        'pending',
        'pending_approval',
        'approved',
        'rejected',
        'draft',
        'ordered',
        'received',
        'in_transit',
        'completed',
        'fulfilled',
        'cancelled',
      ]) {
        await tester.pumpWidget(wrap(
          SizedBox(
            width: 90,
            child: EdenApprovalStatusBadge(status: status),
          ),
        ));
        expect(tester.takeException(), isNull,
            reason: 'overflowed for status=$status');
      }
    });
  });
}
