import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_detail_header_fixtures.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('EdenDetailHeader', () {
    // ---------------- Happy path ----------------

    testWidgets('renders title only', (tester) async {
      await tester.pumpWidget(wrap(EdenDetailHeaderFixtures.minimal()));
      expect(find.text('Customer ABC123'), findsOneWidget);
      // No subtitle, no badge, no actions, no breadcrumb.
      expect(find.text('Acme HVAC Co.'), findsNothing);
      expect(find.byIcon(Icons.star), findsNothing);
    });

    testWidgets('renders title + subtitle', (tester) async {
      await tester.pumpWidget(wrap(EdenDetailHeaderFixtures.withSubtitle()));
      expect(find.text('Customer ABC123'), findsOneWidget);
      expect(find.text('Acme HVAC Co.'), findsOneWidget);
    });

    testWidgets('renders breadcrumb segments above the title', (tester) async {
      await tester.pumpWidget(wrap(EdenDetailHeaderFixtures.withBreadcrumb()));
      expect(find.text('Customers'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Customer ABC123'), findsOneWidget);
    });

    testWidgets('renders 3 action icons inline', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final f = EdenDetailHeaderFixtures.withActions(3);
      await tester.pumpWidget(wrap(f.widget));
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byIcon(Icons.push_pin), findsOneWidget);
      expect(find.byIcon(Icons.share), findsOneWidget);
      // Tap one and confirm the callback fires.
      await tester.tap(find.byIcon(Icons.star));
      await tester.pump();
      expect(f.tapped, contains('Star'));
    });

    testWidgets('renders status badge slot', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenDetailHeader(
          title: 'Customer ABC123',
          statusBadge: Chip(label: Text('Active')),
        ),
      ));
      expect(find.text('Active'), findsOneWidget);
    });

    // ---------------- Edge cases ----------------

    testWidgets('no leading widget → leading column collapses',
        (tester) async {
      await tester.pumpWidget(wrap(EdenDetailHeaderFixtures.minimal()));
      // No business icon (the default leading sample).
      expect(find.byIcon(Icons.business), findsNothing);
    });

    testWidgets('no breadcrumb → top row collapses', (tester) async {
      await tester.pumpWidget(wrap(EdenDetailHeaderFixtures.minimal()));
      // The bread-crumb sample value should not be present anywhere.
      expect(find.text('Customers'), findsNothing);
    });

    testWidgets(
        '6 action icons at narrow width → collapses to PopupMenuButton',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final f = EdenDetailHeaderFixtures.withActions(6);
      await tester.pumpWidget(wrap(f.widget));
      await tester.pumpAndSettle();
      // PopupMenuButton renders an Icons.more_vert by default.
      expect(find.byType(PopupMenuButton<int>), findsOneWidget);
      // Not all 6 icons are inline (overflow consumed them).
      // Count inline icons currently visible — should be less than 6.
      final inlineIconHits = [
        Icons.star,
        Icons.push_pin,
        Icons.share,
        Icons.archive,
        Icons.delete_outline,
        Icons.flag_outlined,
      ].where((i) => find.byIcon(i).evaluate().isNotEmpty).length;
      expect(inlineIconHits, lessThan(6));
    });

    // ---------------- Failure / safety ----------------

    testWidgets('renders at iPhone-narrow (390pt) without overflow',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(wrap(
        EdenDetailHeaderFixtures.narrowOverflowProbe(),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
