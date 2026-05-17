import 'package:eden_ui_flutter/dev_app/screens/commerce_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Smoke + integration tests for the Objective 012 dev catalog screen.
///
/// TRD 012-01 bootstraps the screen with the LineItemEditor section across
/// 5 cross-vertical scenarios; subsequent Wave 1-3 TRDs (012-02..012-07)
/// APPEND additional sections beneath placeholder comments. Each TRD adds
/// smoke assertions here for the section it owns.
void main() {
  group('CommerceScreen', () {
    testWidgets('pumps without exception', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: CommerceScreen()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders LineItemEditor section with all 5 vertical scenario labels', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: CommerceScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Retail cart'), findsOneWidget);
      expect(find.text('Medical claim (with discount)'), findsOneWidget);
      expect(find.text('Fuel POD (single-item delivery)'), findsOneWidget);
      expect(find.text('Trades quote (labor + material + tax)'), findsOneWidget);
      expect(find.text('Salon services (read-only checkout preview)'), findsOneWidget);
    });
  });
}
