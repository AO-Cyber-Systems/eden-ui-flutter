import 'package:eden_ui_flutter/src/widgets/eden_warranty_claim.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_equipment_record_card_fixtures.dart';
import '_fixtures/eden_warranty_claim_fixtures.dart';

Widget wrap(Widget child, {double width = 600}) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(width: width, child: child),
        ),
      ),
    );

Future<void> pumpWide(WidgetTester tester, Widget child,
    {double width = 600}) async {
  await tester.binding.setSurfaceSize(Size(width + 100, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(wrap(child, width: width));
}

void main() {
  group('EdenWarrantyClaim — wizard navigation', () {
    testWidgets('starts on step 1 (Equipment & Part)', (tester) async {
      await pumpWide(
        tester,
        EdenWarrantyClaim(
          equipment: EquipmentRecordFixtures.hvacCompressor(),
          submittedBy: 'tech-1',
          onSubmit: (_) {},
        ),
      );
      expect(find.text('Failed part'), findsOneWidget);
      expect(find.byKey(const Key('warranty-next')), findsOneWidget);
    });

    testWidgets('next button disabled until part label entered',
        (tester) async {
      await pumpWide(
        tester,
        EdenWarrantyClaim(
          equipment: EquipmentRecordFixtures.hvacCompressor(),
          submittedBy: 'tech-1',
          onSubmit: (_) {},
        ),
      );
      final next = tester.widget<ElevatedButton>(
          find.byKey(const Key('warranty-next')));
      expect(next.onPressed, isNull);

      await tester.enterText(find.byType(TextField), 'Run capacitor 45/5');
      await tester.pumpAndSettle();
      final next2 = tester.widget<ElevatedButton>(
          find.byKey(const Key('warranty-next')));
      expect(next2.onPressed, isNotNull);
    });

    testWidgets('moves to step 2 on next', (tester) async {
      await pumpWide(
        tester,
        EdenWarrantyClaim(
          equipment: EquipmentRecordFixtures.hvacCompressor(),
          submittedBy: 'tech-1',
          onSubmit: (_) {},
        ),
      );
      await tester.enterText(find.byType(TextField), 'Run capacitor');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('warranty-next')));
      await tester.pumpAndSettle();
      expect(find.text('Failure description'), findsOneWidget);
      expect(find.text('Severity'), findsOneWidget);
    });

    testWidgets('step 3 review shows summary; submit fires onSubmit',
        (tester) async {
      EdenWarrantyClaimDraft? captured;
      await pumpWide(
        tester,
        EdenWarrantyClaim(
          equipment: EquipmentRecordFixtures.hvacCompressor(),
          submittedBy: 'tech-1',
          onSubmit: (d) => captured = d,
        ),
      );
      // Step 1
      await tester.enterText(find.byType(TextField), 'Run capacitor');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('warranty-next')));
      await tester.pumpAndSettle();
      // Step 2 — fill description
      await tester.enterText(
          find.byType(TextField).first, 'Capacitor failed open');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('warranty-next')));
      await tester.pumpAndSettle();
      // Step 3 review
      expect(find.text('Review'), findsAtLeastNWidgets(1));
      await tester.tap(find.byKey(const Key('warranty-submit')));
      await tester.pumpAndSettle();
      expect(captured, isNotNull);
      expect(captured!.partLabel, 'Run capacitor');
      expect(captured!.failureDescription, 'Capacitor failed open');
      expect(captured!.submittedBy, 'tech-1');
    });
  });

  group('EdenWarrantyClaim — part candidates dropdown', () {
    testWidgets('shows dropdown when partCandidates provided',
        (tester) async {
      await pumpWide(
        tester,
        EdenWarrantyClaim(
          equipment: EquipmentRecordFixtures.hvacCompressor(),
          submittedBy: 'tech-1',
          onSubmit: (_) {},
          partCandidates: WarrantyClaimFixtures.hvacParts(),
        ),
      );
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });
  });

  group('EdenWarrantyClaim — photo gallery callback', () {
    testWidgets('Add Photo hidden when onPickPhoto is null',
        (tester) async {
      await pumpWide(
        tester,
        EdenWarrantyClaim(
          equipment: EquipmentRecordFixtures.hvacCompressor(),
          submittedBy: 'tech-1',
          onSubmit: (_) {},
        ),
      );
      // Advance to step 2
      await tester.enterText(find.byType(TextField), 'Part');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('warranty-next')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('warranty-add-photo')), findsNothing);
    });

    testWidgets('Add Photo visible when onPickPhoto wired; tap appends',
        (tester) async {
      await pumpWide(
        tester,
        EdenWarrantyClaim(
          equipment: EquipmentRecordFixtures.hvacCompressor(),
          submittedBy: 'tech-1',
          onSubmit: (_) {},
          onPickPhoto: (ctx) async => 's3://test.jpg',
        ),
      );
      await tester.enterText(find.byType(TextField), 'Part');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('warranty-next')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('warranty-add-photo')), findsOneWidget);
      await tester.tap(find.byKey(const Key('warranty-add-photo')));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.photo), findsAtLeastNWidgets(1));
    });
  });

  group('EdenWarrantyClaim — back button', () {
    testWidgets('Back returns from step 2 to step 1', (tester) async {
      await pumpWide(
        tester,
        EdenWarrantyClaim(
          equipment: EquipmentRecordFixtures.hvacCompressor(),
          submittedBy: 'tech-1',
          onSubmit: (_) {},
        ),
      );
      await tester.enterText(find.byType(TextField), 'Part');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('warranty-next')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('warranty-back')), findsOneWidget);
      await tester.tap(find.byKey(const Key('warranty-back')));
      await tester.pumpAndSettle();
      expect(find.text('Failed part'), findsOneWidget);
    });
  });
}
