// TSB-FE-01a — EdenQrCode smoke test + golden test
//
// Test list (behavior cases):
//   1. [smoke]  Renders without exception given a valid Stripe Checkout URL.
//   2. [golden] Matches golden snapshot at default 200px size.
//
// Run:         flutter test test/widgets/eden_qr_code_test.dart
// Update goldens: flutter test --update-goldens test/widgets/eden_qr_code_test.dart

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _kTestUrl = 'https://checkout.stripe.com/c/pay/test_abc123';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: Center(child: child)));
}

void main() {
  group('EdenQrCode', () {
    testWidgets(
      '[smoke] renders without exception given a valid URL',
      (tester) async {
        await tester.pumpWidget(
          _wrap(const EdenQrCode(data: _kTestUrl)),
        );
        await tester.pump();
        // No exception — widget tree built successfully.
        expect(find.byType(EdenQrCode), findsOneWidget);
      },
    );

    testWidgets(
      '[golden] matches snapshot at default 200px size',
      (tester) async {
        await tester.pumpWidget(
          _wrap(const EdenQrCode(data: _kTestUrl, size: 200)),
        );
        await tester.pump();
        await expectLater(
          find.byType(EdenQrCode),
          matchesGoldenFile('goldens/eden_qr_code_default.png'),
        );
      },
    );
  });
}
