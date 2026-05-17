import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_receiving_flow_fixtures.dart';

Widget wrap(Widget child, {double width = 1000, double height = 700}) =>
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(width: width, height: height, child: child),
        ),
      ),
    );

Future<EdenReceivingDoc?> _lookupAcme(String q) async =>
    EdenReceivingFixtures.acmeCoffeePo();

Future<EdenReceivingDoc?> _lookupSmall(String q) async =>
    EdenReceivingFixtures.smallPo();

Future<EdenReceivingDoc?> _lookupNull(String q) async => null;

void main() {
  group('EdenReceivingFlow — initial state + step 1 SelectPo', () {
    testWidgets('initial step renders selectPo with search input',
        (tester) async {
      await tester.pumpWidget(
        wrap(EdenReceivingFlow(
          onPoLookup: _lookupAcme,
          onSubmit: (_) {},
        )),
      );
      expect(find.byKey(const ValueKey('eden-receiving-step-selectPo')),
          findsOneWidget);
    });

    testWidgets('initialDoc constructor arg skips to variance step',
        (tester) async {
      await tester.pumpWidget(
        wrap(EdenReceivingFlow(
          onPoLookup: _lookupAcme,
          onSubmit: (_) {},
          initialDoc: EdenReceivingFixtures.acmeCoffeePo(),
        )),
      );
      expect(find.byKey(const ValueKey('eden-receiving-step-variance')),
          findsOneWidget);
    });

    testWidgets('typing in search + tap Lookup fires onPoLookup',
        (tester) async {
      String? capturedQuery;
      await tester.pumpWidget(
        wrap(EdenReceivingFlow(
          onPoLookup: (q) async {
            capturedQuery = q;
            return EdenReceivingFixtures.smallPo();
          },
          onSubmit: (_) {},
        )),
      );
      await tester.enterText(find.byType(TextField), 'PO-4827');
      await tester.tap(find.text('Lookup'));
      await tester.pumpAndSettle();
      expect(capturedQuery, 'PO-4827');
    });

    testWidgets('successful lookup transitions to variance step',
        (tester) async {
      await tester.pumpWidget(
        wrap(EdenReceivingFlow(
          onPoLookup: _lookupSmall,
          onSubmit: (_) {},
        )),
      );
      await tester.enterText(find.byType(TextField), 'PO-1');
      await tester.tap(find.text('Lookup'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('eden-receiving-step-variance')),
          findsOneWidget);
    });

    testWidgets('null lookup result shows PO not found alert + stays on step 1',
        (tester) async {
      await tester.pumpWidget(
        wrap(EdenReceivingFlow(
          onPoLookup: _lookupNull,
          onSubmit: (_) {},
        )),
      );
      await tester.enterText(find.byType(TextField), 'PO-NOT-EXIST');
      await tester.tap(find.text('Lookup'));
      await tester.pumpAndSettle();
      expect(find.textContaining('not found'), findsOneWidget);
      expect(find.byKey(const ValueKey('eden-receiving-step-selectPo')),
          findsOneWidget);
    });
  });

  group('EdenReceivingFlow — step 2 Variance', () {
    testWidgets('split-pane layout at 1000pt width', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(EdenReceivingFlow(
          onPoLookup: _lookupAcme,
          onSubmit: (_) {},
          initialDoc: EdenReceivingFixtures.acmeCoffeePo(),
        ), width: 1000),
      );
      expect(find.byKey(const ValueKey('eden-receiving-variance-split')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('eden-receiving-variance-tabbed')),
          findsNothing);
    });

    testWidgets('tabbed layout at 500pt width', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(EdenReceivingFlow(
          onPoLookup: _lookupAcme,
          onSubmit: (_) {},
          initialDoc: EdenReceivingFixtures.acmeCoffeePo(),
        ), width: 500),
      );
      expect(find.byKey(const ValueKey('eden-receiving-variance-tabbed')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('eden-receiving-variance-split')),
          findsNothing);
    });

    testWidgets('line item names render on variance step', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(EdenReceivingFlow(
          onPoLookup: _lookupAcme,
          onSubmit: (_) {},
          initialDoc: EdenReceivingFixtures.acmeCoffeePo(),
        ), width: 1000),
      );
      expect(find.textContaining('Espresso Blend 1kg'),
          findsAtLeastNWidgets(1));
    });

    testWidgets('received qty equal to expected → no variance reason picker',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(EdenReceivingFlow(
          onPoLookup: _lookupAcme,
          onSubmit: (_) {},
          initialDoc: EdenReceivingFixtures.smallPo(),
        ), width: 1000),
      );
      // Pre-populated with expected qty = received qty → no variance picker.
      expect(find.byType(EdenSelect<EdenVarianceReason>), findsNothing);
    });

    testWidgets('changing received qty to mismatch shows variance reason picker',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(EdenReceivingFlow(
          onPoLookup: _lookupAcme,
          onSubmit: (_) {},
          initialDoc: EdenReceivingFixtures.smallPo(),
        ), width: 1000),
      );
      // smallPo() has expectedQty: 1. Enter 0 for received qty.
      // The received qty input has hint 'Received'.
      final qtyField = find.byKey(const ValueKey('received-qty-L-A'));
      expect(qtyField, findsOneWidget);
      await tester.enterText(qtyField, '0');
      await tester.pump();
      expect(find.byType(EdenSelect<EdenVarianceReason>), findsOneWidget);
    });
  });

  group('EdenReceivingFlow — state machine transitions', () {
    testWidgets('Next from variance with variance set → costUpdate step',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(EdenReceivingFlow(
          onPoLookup: _lookupAcme,
          onSubmit: (_) {},
          initialDoc: EdenReceivingFixtures.smallPo(),
        ), width: 1000),
      );
      // Trigger variance: receivedQty 0 vs expectedQty 1
      await tester.enterText(
        find.byKey(const ValueKey('received-qty-L-A')),
        '0',
      );
      await tester.pump();
      // Pick variance reason
      await tester.tap(find.byType(EdenSelect<EdenVarianceReason>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Short qty').last);
      await tester.pumpAndSettle();
      // Next button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('eden-receiving-step-costUpdate')),
          findsOneWidget);
    });

    testWidgets('Next from variance with NO variance → disposition step (skip costUpdate)',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(EdenReceivingFlow(
          onPoLookup: _lookupAcme,
          onSubmit: (_) {},
          initialDoc: EdenReceivingFixtures.smallPo(),
        ), width: 1000),
      );
      // Leave received qty at expected = no variance
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('eden-receiving-step-disposition')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('eden-receiving-step-costUpdate')),
          findsNothing);
    });

    testWidgets('Back from variance step → selectPo (doc cleared)',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(EdenReceivingFlow(
          onPoLookup: _lookupAcme,
          onSubmit: (_) {},
          initialDoc: EdenReceivingFixtures.smallPo(),
        ), width: 1000),
      );
      await tester.tap(find.widgetWithText(OutlinedButton, 'Back'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('eden-receiving-step-selectPo')),
          findsOneWidget);
    });
  });

  group('EdenReceivingFlow — step 4 Disposition + Submit', () {
    Future<void> _toDisposition(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 800));
      await tester.pumpWidget(
        wrap(EdenReceivingFlow(
          onPoLookup: _lookupSmall,
          onPhotoCapture: () async => 'demo://photo-ref.jpg',
          onSubmit: (_) {},
          initialDoc: EdenReceivingFixtures.smallPo(),
        ), width: 1000),
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();
    }

    testWidgets('renders 3 disposition radio tiles', (tester) async {
      EdenReceivingDraft? captured;
      await tester.binding.setSurfaceSize(const Size(1100, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(EdenReceivingFlow(
          onPoLookup: _lookupSmall,
          onPhotoCapture: () async => 'demo://photo-ref.jpg',
          onSubmit: (d) => captured = d,
          initialDoc: EdenReceivingFixtures.smallPo(),
        ), width: 1000),
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();
      expect(find.byType(RadioListTile<EdenReceivingDisposition>),
          findsNWidgets(3));
      expect(captured, isNull);
    });

    testWidgets('Submit disabled until disposition is selected',
        (tester) async {
      await _toDisposition(tester);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final submit = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Submit'),
      );
      expect(submit.onPressed, isNull);
    });

    testWidgets('selecting receiveFull → Submit enabled', (tester) async {
      await _toDisposition(tester);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.tap(find.text('Receive full'));
      await tester.pump();
      final submit = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Submit'),
      );
      expect(submit.onPressed, isNotNull);
    });

    testWidgets('selecting damaged → Attach photo button visible; Submit disabled until photo',
        (tester) async {
      await _toDisposition(tester);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.tap(find.text('Damaged'));
      await tester.pump();
      expect(find.text('Attach photo'), findsOneWidget);
      final submitDisabled = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Submit'),
      );
      expect(submitDisabled.onPressed, isNull);
      await tester.tap(find.text('Attach photo'));
      await tester.pumpAndSettle();
      final submitEnabled = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Submit'),
      );
      expect(submitEnabled.onPressed, isNotNull);
    });

    testWidgets('Submit fires onSubmit with EdenReceivingDraft',
        (tester) async {
      EdenReceivingDraft? captured;
      await tester.binding.setSurfaceSize(const Size(1100, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrap(EdenReceivingFlow(
          onPoLookup: _lookupSmall,
          onSubmit: (d) => captured = d,
          initialDoc: EdenReceivingFixtures.smallPo(),
        ), width: 1000),
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Receive full'));
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
      await tester.pump();
      expect(captured, isNotNull);
      expect(captured!.poNumber, 'PO-1');
      expect(captured!.disposition, EdenReceivingDisposition.receiveFull);
      expect(captured!.receivedItems.length, 1);
    });
  });

  group('EdenReceivingFlow — iPhone-narrow safety', () {
    testWidgets('390pt variance step uses tabbed layout + no overflow',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EdenReceivingFlow(
              onPoLookup: _lookupAcme,
              onSubmit: (_) {},
              initialDoc: EdenReceivingFixtures.acmeCoffeePo(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('eden-receiving-variance-tabbed')),
          findsOneWidget);
    });
  });
}
