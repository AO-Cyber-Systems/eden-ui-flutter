import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: Center(child: child)));
  }

  EdenBadge findBadge(WidgetTester tester) {
    return tester.widget<EdenBadge>(find.byType(EdenBadge));
  }

  group('EdenStatusBadge', () {
    testWidgets('maps "active" to success variant', (tester) async {
      await tester.pumpWidget(wrap(const EdenStatusBadge(status: 'active')));
      expect(findBadge(tester).variant, EdenBadgeVariant.success);
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('maps "blocked" to danger variant', (tester) async {
      await tester.pumpWidget(wrap(const EdenStatusBadge(status: 'blocked')));
      expect(findBadge(tester).variant, EdenBadgeVariant.danger);
      expect(find.text('Blocked'), findsOneWidget);
    });

    testWidgets('maps "warning" to warning variant', (tester) async {
      await tester.pumpWidget(wrap(const EdenStatusBadge(status: 'warning')));
      expect(findBadge(tester).variant, EdenBadgeVariant.warning);
    });

    testWidgets('maps "pending" to info variant', (tester) async {
      await tester.pumpWidget(wrap(const EdenStatusBadge(status: 'pending')));
      expect(findBadge(tester).variant, EdenBadgeVariant.info);
      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('maps "fired" / "acknowledged" to warning variant',
        (tester) async {
      for (final s in ['fired', 'acknowledged']) {
        await tester.pumpWidget(wrap(EdenStatusBadge(status: s)));
        expect(findBadge(tester).variant, EdenBadgeVariant.warning);
      }
    });

    testWidgets('maps "expired" to neutral variant', (tester) async {
      await tester.pumpWidget(wrap(const EdenStatusBadge(status: 'expired')));
      expect(findBadge(tester).variant, EdenBadgeVariant.neutral);
    });

    testWidgets('unknown status falls through to neutral with capitalized label',
        (tester) async {
      await tester
          .pumpWidget(wrap(const EdenStatusBadge(status: 'mystery')));
      expect(findBadge(tester).variant, EdenBadgeVariant.neutral);
      expect(find.text('Mystery'), findsOneWidget);
    });

    testWidgets('underscore becomes space in label', (tester) async {
      await tester
          .pumpWidget(wrap(const EdenStatusBadge(status: 'in_progress')));
      expect(find.text('In Progress'), findsOneWidget);
      expect(findBadge(tester).variant, EdenBadgeVariant.info);
    });

    testWidgets('case-insensitive matching (label is normalized)',
        (tester) async {
      // Variant lookup is case-insensitive; the rendered label is the
      // lowercase input with the first letter of each word capitalized.
      await tester.pumpWidget(wrap(const EdenStatusBadge(status: 'ACTIVE')));
      expect(findBadge(tester).variant, EdenBadgeVariant.success);
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('honors size override', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenStatusBadge(status: 'active', size: EdenBadgeSize.lg),
      ));
      expect(findBadge(tester).size, EdenBadgeSize.lg);
    });

    testWidgets('maps "field_billing" to info variant (invoice list badge)',
        (tester) async {
      await tester
          .pumpWidget(wrap(const EdenStatusBadge(status: 'field_billing')));
      expect(findBadge(tester).variant, EdenBadgeVariant.info);
      expect(find.text('Field Billing'), findsOneWidget);
    });

    testWidgets('maps "service_billing" to info variant (semantic synonym)',
        (tester) async {
      await tester
          .pumpWidget(wrap(const EdenStatusBadge(status: 'service_billing')));
      expect(findBadge(tester).variant, EdenBadgeVariant.info);
      expect(find.text('Service Billing'), findsOneWidget);
    });
  });
}
