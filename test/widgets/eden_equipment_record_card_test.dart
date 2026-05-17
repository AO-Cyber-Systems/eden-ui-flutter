import 'package:eden_ui_flutter/src/widgets/eden_equipment_record_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_equipment_record_card_fixtures.dart';

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
  group('EdenEquipmentWarrantyStatus computed properties', () {
    test('isExpired true for past expiresOn', () {
      final w = EdenEquipmentWarrantyStatus(
        expiresOn: DateTime.now().subtract(const Duration(days: 10)),
        type: EdenEquipmentWarrantyType.manufacturer,
      );
      expect(w.isExpired, isTrue);
      expect(w.isExpiringSoon, isFalse);
    });

    test('isExpiringSoon true when <90 days remaining (not expired)', () {
      final w = EdenEquipmentWarrantyStatus(
        expiresOn: DateTime.now().add(const Duration(days: 30)),
        type: EdenEquipmentWarrantyType.manufacturer,
      );
      expect(w.isExpired, isFalse);
      expect(w.isExpiringSoon, isTrue);
    });

    test('isExpiringSoon false when >=90 days remaining', () {
      final w = EdenEquipmentWarrantyStatus(
        expiresOn: DateTime.now().add(const Duration(days: 200)),
        type: EdenEquipmentWarrantyType.manufacturer,
      );
      expect(w.isExpired, isFalse);
      expect(w.isExpiringSoon, isFalse);
    });

    test('typeLabel renders human-readable names', () {
      const labels = {
        EdenEquipmentWarrantyType.manufacturer: 'Manufacturer',
        EdenEquipmentWarrantyType.parts: 'Parts',
        EdenEquipmentWarrantyType.labor: 'Labor',
        EdenEquipmentWarrantyType.extended: 'Extended',
      };
      for (final entry in labels.entries) {
        final w = EdenEquipmentWarrantyStatus(
          expiresOn: DateTime.now(),
          type: entry.key,
        );
        expect(w.typeLabel, entry.value);
      }
    });
  });

  group('EdenEquipmentRecordCard — static rendering', () {
    testWidgets('renders name + type + metadata for HVAC compressor',
        (tester) async {
      await pumpWide(
        tester,
        EdenEquipmentRecordCard(data: EquipmentRecordFixtures.hvacCompressor()),
      );
      expect(find.text('Lennox XC25 Condenser'), findsOneWidget);
      expect(find.text('HVAC'), findsOneWidget);
      expect(find.text('5824L09887'), findsOneWidget);
      expect(find.text('Side yard, north wall'), findsOneWidget);
    });

    testWidgets('renders warranty section for active warranty',
        (tester) async {
      await pumpWide(
        tester,
        EdenEquipmentRecordCard(data: EquipmentRecordFixtures.hvacCompressor()),
      );
      expect(find.textContaining('warranty'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders agreement tier name', (tester) async {
      await pumpWide(
        tester,
        EdenEquipmentRecordCard(data: EquipmentRecordFixtures.hvacCompressor()),
      );
      expect(find.textContaining('Gold Annual'), findsOneWidget);
    });

    testWidgets('renders service history timeline entries', (tester) async {
      await pumpWide(
        tester,
        EdenEquipmentRecordCard(data: EquipmentRecordFixtures.hvacCompressor()),
      );
      expect(
          find.textContaining('Annual tune-up'), findsOneWidget);
      expect(
          find.textContaining('Refrigerant top-up'), findsOneWidget);
    });

    testWidgets('renders photos when present', (tester) async {
      await pumpWide(
        tester,
        EdenEquipmentRecordCard(data: EquipmentRecordFixtures.hvacCompressor()),
      );
      expect(find.byIcon(Icons.photo), findsAtLeastNWidgets(2));
    });
  });

  group('EdenEquipmentRecordCard — warranty status badges', () {
    testWidgets('active warranty -> active status badge', (tester) async {
      await pumpWide(
        tester,
        EdenEquipmentRecordCard(data: EquipmentRecordFixtures.hvacCompressor()),
      );
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('expiring soon -> warning status badge', (tester) async {
      await pumpWide(
        tester,
        EdenEquipmentRecordCard(data: EquipmentRecordFixtures.propaneTank()),
      );
      expect(find.text('Warning'), findsOneWidget);
    });

    testWidgets('expired warranty -> expired status badge', (tester) async {
      await pumpWide(
        tester,
        EdenEquipmentRecordCard(
            data: EquipmentRecordFixtures.expiredGenerator()),
      );
      expect(find.text('Expired'), findsOneWidget);
    });
  });

  group('EdenEquipmentRecordCard — actions', () {
    testWidgets('hidden when both callbacks null', (tester) async {
      await pumpWide(
        tester,
        EdenEquipmentRecordCard(
            data: EquipmentRecordFixtures.hvacCompressor()),
      );
      expect(find.byKey(const Key('equipment-add-service')), findsNothing);
      expect(find.byKey(const Key('equipment-file-warranty-claim')),
          findsNothing);
    });

    testWidgets('Add Service fires callback', (tester) async {
      var added = false;
      await pumpWide(
        tester,
        EdenEquipmentRecordCard(
          data: EquipmentRecordFixtures.hvacCompressor(),
          onAddService: () => added = true,
        ),
      );
      await tester.tap(find.byKey(const Key('equipment-add-service')));
      expect(added, isTrue);
    });

    testWidgets('File Warranty Claim fires callback', (tester) async {
      var filed = false;
      await pumpWide(
        tester,
        EdenEquipmentRecordCard(
          data: EquipmentRecordFixtures.hvacCompressor(),
          onFileWarrantyClaim: () => filed = true,
        ),
      );
      await tester
          .tap(find.byKey(const Key('equipment-file-warranty-claim')));
      expect(filed, isTrue);
    });
  });

  group('EdenEquipmentRecordCard — compact variant', () {
    testWidgets('hides metadata + agreement + photos + history',
        (tester) async {
      await pumpWide(
        tester,
        EdenEquipmentRecordCard(
          data: EquipmentRecordFixtures.hvacCompressor(),
          variant: EdenEquipmentRecordVariant.compact,
        ),
      );
      // Header still present, but no make/model strip
      expect(find.text('Lennox XC25 Condenser'), findsOneWidget);
      expect(find.text('5824L09887'), findsNothing);
      expect(find.textContaining('Gold Annual'), findsNothing);
      expect(find.textContaining('Annual tune-up'), findsNothing);
    });
  });

  group('EdenEquipmentRecordCard — responsive', () {
    testWidgets('iPhone-narrow (390pt) renders without overflow',
        (tester) async {
      await pumpWide(
        tester,
        EdenEquipmentRecordCard(
          data: EquipmentRecordFixtures.hvacCompressor(),
        ),
        width: 390,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
