// Do NOT regenerate via LLM — hand-built fixtures for EdenEquipmentRecordCard.

import 'package:eden_ui_flutter/src/widgets/eden_equipment_record_card.dart';

class EquipmentRecordFixtures {
  EquipmentRecordFixtures._();

  /// HVAC compressor with active warranty.
  static EdenEquipmentRecordData hvacCompressor() {
    return EdenEquipmentRecordData(
      id: 'eq-hvac-1',
      name: 'Lennox XC25 Condenser',
      type: 'HVAC',
      customerId: 'cust-patel',
      location: 'Side yard, north wall',
      make: 'Lennox',
      model: 'XC25-048-230',
      serialNumber: '5824L09887',
      installDate: DateTime(2024, 5, 12),
      warrantyStatus: EdenEquipmentWarrantyStatus(
        expiresOn: DateTime.now().add(const Duration(days: 320)),
        type: EdenEquipmentWarrantyType.manufacturer,
        coverageNotes: '10-year compressor + 5-year parts',
      ),
      agreementStatus: EdenEquipmentAgreementStatus(
        tierName: 'Gold Annual',
        renewsOn: DateTime.now().add(const Duration(days: 180)),
        isActive: true,
      ),
      serviceHistory: [
        EdenEquipmentServiceHistoryEntry(
          id: 'sh-1',
          serviceDate: DateTime(2025, 4, 2),
          summary: 'Annual tune-up — replaced filter + cleaned coil',
          technicianName: 'Bob T.',
        ),
        EdenEquipmentServiceHistoryEntry(
          id: 'sh-2',
          serviceDate: DateTime(2025, 9, 18),
          summary: 'Refrigerant top-up — added 1.5 lb R-410A',
          technicianName: 'Sue M.',
        ),
      ],
      photoUrls: const ['photo://1', 'photo://2'],
    );
  }

  /// Propane tank with warranty expiring soon (<90 days).
  static EdenEquipmentRecordData propaneTank() {
    return EdenEquipmentRecordData(
      id: 'eq-tank-1',
      name: '500-gal propane tank',
      type: 'Tank',
      customerId: 'cust-hansen',
      location: 'Behind workshop',
      make: 'Worthington',
      model: 'WPT-500-AS',
      serialNumber: 'WTN-2022-94472',
      installDate: DateTime(2022, 8, 30),
      warrantyStatus: EdenEquipmentWarrantyStatus(
        expiresOn: DateTime.now().add(const Duration(days: 45)),
        type: EdenEquipmentWarrantyType.parts,
      ),
    );
  }

  /// Generator with EXPIRED warranty.
  static EdenEquipmentRecordData expiredGenerator() {
    return EdenEquipmentRecordData(
      id: 'eq-gen-1',
      name: 'Generac 22kW standby generator',
      type: 'Generator',
      customerId: 'cust-wilson',
      location: 'East side of house',
      make: 'Generac',
      model: 'G0070433',
      serialNumber: '5024198832',
      installDate: DateTime(2018, 11, 15),
      warrantyStatus: EdenEquipmentWarrantyStatus(
        expiresOn: DateTime.now().subtract(const Duration(days: 200)),
        type: EdenEquipmentWarrantyType.manufacturer,
      ),
    );
  }
}
