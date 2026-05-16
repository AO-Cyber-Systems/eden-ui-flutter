// lib/dev_app/_sample_data/cross_cutting.dart
//
// Hand-built sample data for the dev catalog. Do NOT regenerate via LLM —
// mutate in-place when downstream verticals shift. Real-world data has
// irregular distributions; uniform patterns (Customer 1/2/3, identical
// timestamps) are a smell that this file was AI-touched. Catch and fix.
//
// Catalog "today" anchor: DateTime(2026, 5, 16). All relative-time fixtures
// compute from this anchor for snapshot stability.

import 'package:eden_ui_flutter/eden_ui.dart';

/// Plain value class for cross-vertical customer/patient/citizen fixtures.
/// NOT a library widget — fixtures only.
class DemoCustomer {
  const DemoCustomer({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    this.tier,
    this.vertical,
    this.notes,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final EdenAddress address;
  final EdenMembershipTier? tier;

  /// 'trades' | 'salon' | 'fuel' | 'medical' | 'gov' (free-form — not enforced).
  final String? vertical;

  /// Optional one-liner shown under the name in catalog rows.
  final String? notes;
}

/// Plain value class for cross-vertical staff fixtures (tech, stylist, driver,
/// nurse, caseworker, etc.). NOT a library widget.
class DemoStaff {
  const DemoStaff({
    required this.id,
    required this.name,
    required this.role,
    required this.vertical,
    required this.initials,
    this.phone,
  });

  final String id;
  final String name;
  final String role;
  final String vertical;
  final String initials;
  final String? phone;
}

/// Plain value class for cross-vertical inventory items (trades parts, salon
/// products, fuel grades, medical supplies). NOT a library widget.
class DemoInventoryItem {
  const DemoInventoryItem({
    required this.sku,
    required this.name,
    required this.vertical,
    required this.onHand,
    required this.reorderPoint,
    this.unitCost,
    this.location,
  });

  final String sku;
  final String name;
  final String vertical;
  final int onHand;
  final int reorderPoint;
  final String? unitCost;
  final String? location;
}

/// Shared cross-cutting fixtures used by all five vertical scenario files.
///
/// DateTime is NOT `const`-able, so [catalogToday] is exposed as a static
/// getter that returns a fresh value at each call site.
class CrossCuttingFixtures {
  /// The fixed "now" the dev catalog renders against. Pinned to a date so
  /// snapshot tests + relative-time copy ("3h ago", "tomorrow") stay stable.
  static DateTime get catalogToday => DateTime(2026, 5, 16, 9, 0);

  /// 10 cross-vertical customer fixtures with realistic geographic spread.
  /// Mix of suburban/urban/rural/gov-campus addresses. Names intentionally
  /// varied (origin, length, hyphenation, apostrophes, suffix).
  static const List<DemoCustomer> customers = <DemoCustomer>[
    DemoCustomer(
      id: 'cust-101',
      name: 'Marcus Whitfield',
      email: 'marcus.whitfield@redbrickcoffee.com',
      phone: '+1 (404) 555-0142',
      address: EdenAddress(
        streetLine1: '1487 Briar Hollow Ln',
        city: 'Marietta',
        regionCode: 'GA',
        postalCode: '30068',
        countryCode: 'US',
        latLng: EdenLatLng(lat: 33.9526, lng: -84.5499),
      ),
      tier: EdenMembershipTier.gold,
      vertical: 'trades',
      notes: 'HVAC contract since 2019. Prefers Tuesday windows.',
    ),
    DemoCustomer(
      id: 'cust-102',
      name: 'Aisha Okonkwo-Reyes',
      email: 'aisha.or@gmail.com',
      phone: '+1 (212) 555-0019',
      address: EdenAddress(
        streetLine1: '88 Bleecker St',
        streetLine2: 'Apt 4B',
        city: 'New York',
        regionCode: 'NY',
        postalCode: '10012',
        countryCode: 'US',
        latLng: EdenLatLng(lat: 40.7281, lng: -73.9942),
      ),
      tier: EdenMembershipTier.platinum,
      vertical: 'salon',
      notes: 'Color correction client. Every 6 weeks.',
    ),
    DemoCustomer(
      id: 'cust-103',
      name: "D'Angelo Pierre",
      email: 'd.pierre@yahoo.com',
      phone: '+1 (310) 555-0207',
      address: EdenAddress(
        streetLine1: '3215 Westwood Blvd',
        city: 'Los Angeles',
        regionCode: 'CA',
        postalCode: '90034',
        countryCode: 'US',
        latLng: EdenLatLng(lat: 34.0319, lng: -118.4267),
      ),
      tier: EdenMembershipTier.silver,
      vertical: 'salon',
    ),
    DemoCustomer(
      id: 'cust-104',
      name: 'Northpoint Diesel Co.',
      email: 'dispatch@northpointdiesel.com',
      phone: '+1 (708) 555-0331',
      address: EdenAddress(
        streetLine1: '2200 S Cicero Ave',
        city: 'Chicago',
        regionCode: 'IL',
        postalCode: '60804',
        countryCode: 'US',
        latLng: EdenLatLng(lat: 41.8497, lng: -87.7449),
      ),
      vertical: 'fuel',
      notes: 'Bulk delivery account. NET-30. 12 trucks.',
    ),
    DemoCustomer(
      id: 'cust-105',
      name: 'J. Doe',
      email: 'patient-mrn-44291@portal.local',
      phone: '+1 (404) 555-0445',
      address: EdenAddress(
        streetLine1: '917 Lullwater Rd NE',
        city: 'Atlanta',
        regionCode: 'GA',
        postalCode: '30307',
        countryCode: 'US',
      ),
      vertical: 'medical',
      notes: 'MRN 44291. Diabetes home-visit panel.',
    ),
    DemoCustomer(
      id: 'cust-106',
      name: 'Eleanor McGrath-Hayworth',
      email: 'emcgrath@cup-hyl.edu',
      phone: '+1 (408) 555-0610',
      address: EdenAddress(
        streetLine1: '1 Infinite Loop',
        streetLine2: 'Bldg D, Suite 217',
        city: 'Cupertino',
        regionCode: 'CA',
        postalCode: '95014',
        countryCode: 'US',
        latLng: EdenLatLng(lat: 37.3318, lng: -122.0312),
      ),
      tier: EdenMembershipTier.vip,
      vertical: 'salon',
      notes: 'On-site stylist visit. Quarterly.',
    ),
    DemoCustomer(
      id: 'cust-107',
      name: 'Linnea Sørensen',
      email: 'lsorensen@cobbcounty-gov.us',
      phone: '+1 (770) 555-0719',
      address: EdenAddress(
        streetLine1: '100 Cherokee St',
        streetLine2: 'Case Mgmt Annex',
        city: 'Marietta',
        regionCode: 'GA',
        postalCode: '30090',
        countryCode: 'US',
      ),
      vertical: 'gov',
      notes: 'Case file CCM-2026-0427. Reviewer Tier 2.',
    ),
    DemoCustomer(
      id: 'cust-108',
      name: 'Hank Bartholomew',
      email: 'hank@hbar-farm.example',
      phone: '+1 (575) 555-0828',
      address: EdenAddress(
        streetLine1: '47 County Road 12',
        city: 'Carrizozo',
        regionCode: 'NM',
        postalCode: '88301',
        countryCode: 'US',
      ),
      vertical: 'trades',
      notes: 'Off-grid ranch. Propane + well pump.',
    ),
    DemoCustomer(
      id: 'cust-109',
      name: 'Priya Venkataraman',
      email: 'priya.v@example.com',
      phone: '+1 (617) 555-0911',
      address: EdenAddress(
        streetLine1: '21 Brattle St',
        city: 'Cambridge',
        regionCode: 'MA',
        postalCode: '02138',
        countryCode: 'US',
        latLng: EdenLatLng(lat: 42.3744, lng: -71.1199),
      ),
      tier: EdenMembershipTier.bronze,
      vertical: 'salon',
    ),
    DemoCustomer(
      id: 'cust-110',
      name:
          'Anne-Marie Bourgeois-Tremblay-Lefebvre Trust Holdings Corporation Inc.',
      email: 'finance@ambt-trust.example',
      phone: '+1 (514) 555-1024',
      address: EdenAddress(
        streetLine1: '4040 Rue Saint-Denis',
        city: 'Montreal',
        regionCode: 'QC',
        postalCode: 'H2W 2M3',
        countryCode: 'CA',
      ),
      vertical: 'trades',
      notes:
          'Edge fixture: extremely long legal name; tests catalog wrap/ellipsis.',
    ),
  ];

  /// 8 staff fixtures spanning trades / salon / fuel / medical / gov verticals.
  static const List<DemoStaff> staff = <DemoStaff>[
    DemoStaff(
      id: 'staff-301',
      name: 'Alice Chen',
      role: 'Senior HVAC Technician',
      vertical: 'trades',
      initials: 'AC',
      phone: '+1 (404) 555-1011',
    ),
    DemoStaff(
      id: 'staff-302',
      name: 'Bob Kowalski',
      role: 'Apprentice Electrician',
      vertical: 'trades',
      initials: 'BK',
      phone: '+1 (404) 555-1012',
    ),
    DemoStaff(
      id: 'staff-303',
      name: 'Marisol Reyes',
      role: 'Master Stylist',
      vertical: 'salon',
      initials: 'MR',
      phone: '+1 (212) 555-2021',
    ),
    DemoStaff(
      id: 'staff-304',
      name: 'Devon Park',
      role: 'Color Specialist',
      vertical: 'salon',
      initials: 'DP',
    ),
    DemoStaff(
      id: 'staff-305',
      name: 'Manuel "Manny" Tovar',
      role: 'Lead Delivery Driver',
      vertical: 'fuel',
      initials: 'MT',
      phone: '+1 (708) 555-3031',
    ),
    DemoStaff(
      id: 'staff-306',
      name: 'Dr. Anjali Patel, MD',
      role: 'Home-Visit Physician',
      vertical: 'medical',
      initials: 'AP',
    ),
    DemoStaff(
      id: 'staff-307',
      name: 'Rosa Soto, RN',
      role: 'Visit Nurse',
      vertical: 'medical',
      initials: 'RS',
    ),
    DemoStaff(
      id: 'staff-308',
      name: 'Linnea Sørensen',
      role: 'Senior Caseworker',
      vertical: 'gov',
      initials: 'LS',
    ),
  ];

  /// 10 inventory fixtures spanning trades parts / salon products / fuel
  /// grades / medical supplies. Real-world SKUs, mixed stock states.
  static const List<DemoInventoryItem> inventory = <DemoInventoryItem>[
    DemoInventoryItem(
      sku: 'HVC-COMP-2T',
      name: 'Goodman 2-Ton Compressor',
      vertical: 'trades',
      onHand: 3,
      reorderPoint: 2,
      unitCost: r'$487.20',
      location: 'Truck 47 / Shelf B2',
    ),
    DemoInventoryItem(
      sku: 'HVC-FLT-20x25',
      name: 'MERV-11 Filter 20x25x1',
      vertical: 'trades',
      onHand: 48,
      reorderPoint: 24,
      unitCost: r'$11.95',
      location: 'Warehouse / Aisle 3',
    ),
    DemoInventoryItem(
      sku: 'ELE-WIRE-12-3',
      name: 'Romex 12/3 250ft Roll',
      vertical: 'trades',
      onHand: 1,
      reorderPoint: 4,
      unitCost: r'$148.00',
      location: 'Truck 12',
    ),
    DemoInventoryItem(
      sku: 'SAL-OLP-BL',
      name: 'Olaplex No. 3 Hair Perfector',
      vertical: 'salon',
      onHand: 14,
      reorderPoint: 6,
      unitCost: r'$28.00',
      location: 'Color station',
    ),
    DemoInventoryItem(
      sku: 'SAL-REDK-SH',
      name: 'Redken Acidic Bonding Shampoo 1L',
      vertical: 'salon',
      onHand: 2,
      reorderPoint: 4,
      unitCost: r'$42.50',
      location: 'Backbar A',
    ),
    DemoInventoryItem(
      sku: 'FUEL-D2-LSULF',
      name: 'Low-Sulfur Diesel #2 (gal)',
      vertical: 'fuel',
      onHand: 18750,
      reorderPoint: 5000,
      unitCost: r'$3.94',
      location: 'Terminal 4 / Tank 7',
    ),
    DemoInventoryItem(
      sku: 'FUEL-GAS-87',
      name: 'Unleaded Regular 87 (gal)',
      vertical: 'fuel',
      onHand: 3200,
      reorderPoint: 4000,
      unitCost: r'$3.42',
      location: 'Terminal 4 / Tank 3',
    ),
    DemoInventoryItem(
      sku: 'MED-GLU-T',
      name: 'OneTouch Verio Test Strips (50ct)',
      vertical: 'medical',
      onHand: 22,
      reorderPoint: 10,
      unitCost: r'$36.99',
      location: 'Visit kit / pocket 4',
    ),
    DemoInventoryItem(
      sku: 'MED-NEED-25',
      name: '25G x 1" Hypodermic Needles (100ct)',
      vertical: 'medical',
      onHand: 4,
      reorderPoint: 6,
      unitCost: r'$18.40',
      location: 'Visit kit / pocket 2',
    ),
    DemoInventoryItem(
      sku: 'OFC-FORM-CASEFILE',
      name: 'Case File Folder, 11x17 expanding',
      vertical: 'gov',
      onHand: 240,
      reorderPoint: 100,
      unitCost: r'$2.85',
      location: 'Records Annex',
    ),
  ];

  /// 10-row mixed-vertical activity feed, reverse-chronological. Composed for
  /// dashboards / activity feeds that intentionally cross verticals (e.g.
  /// company-wide ops view).
  static List<EdenActivityFeedItemData> get mixedActivityFeed =>
      <EdenActivityFeedItemData>[
        const EdenActivityFeedItemData(
          actorName: 'Marisol Reyes',
          actorInitials: 'MR',
          action: 'checked out',
          entityName: 'Aisha Okonkwo-Reyes (balayage)',
          timeAgo: '4m ago',
          variant: EdenActivityVariant.success,
        ),
        const EdenActivityFeedItemData(
          actorName: 'Manuel Tovar',
          actorInitials: 'MT',
          action: 'completed delivery to',
          entityName: 'Northpoint Diesel (1,800 gal)',
          timeAgo: '12m ago',
          variant: EdenActivityVariant.info,
        ),
        const EdenActivityFeedItemData(
          actorName: 'Alice Chen',
          actorInitials: 'AC',
          action: 'flagged blocker on',
          entityName: 'HVAC install — Whitfield',
          timeAgo: '38m ago',
          variant: EdenActivityVariant.warning,
        ),
        const EdenActivityFeedItemData(
          actorName: 'Dr. Anjali Patel',
          actorInitials: 'AP',
          action: 'signed visit note for',
          entityName: 'Patient MRN 44291',
          timeAgo: '1h ago',
          variant: EdenActivityVariant.info,
        ),
        const EdenActivityFeedItemData(
          actorName: 'Devon Park',
          actorInitials: 'DP',
          action: 'rebooked',
          entityName: 'Priya Venkataraman (cut + gloss)',
          timeAgo: '2h ago',
          variant: EdenActivityVariant.success,
        ),
        const EdenActivityFeedItemData(
          actorName: 'Linnea Sørensen',
          actorInitials: 'LS',
          action: 'escalated',
          entityName: 'Case CCM-2026-0427 to Tier 3',
          timeAgo: '3h ago',
          variant: EdenActivityVariant.danger,
        ),
        const EdenActivityFeedItemData(
          actorName: 'Bob Kowalski',
          actorInitials: 'BK',
          action: 'requested parts for',
          entityName: 'Panel upgrade — Bartholomew',
          timeAgo: '5h ago',
          variant: EdenActivityVariant.warning,
        ),
        const EdenActivityFeedItemData(
          actorName: 'Rosa Soto',
          actorInitials: 'RS',
          action: 'started intake for',
          entityName: 'Patient MRN 44291',
          timeAgo: 'yesterday',
          variant: EdenActivityVariant.info,
        ),
        const EdenActivityFeedItemData(
          actorName: 'Manuel Tovar',
          actorInitials: 'MT',
          action: 'reported tank reading at',
          entityName: 'Terminal 4 (Diesel: 78%)',
          timeAgo: 'yesterday',
          variant: EdenActivityVariant.info,
        ),
        const EdenActivityFeedItemData(
          actorName: 'Marcus Whitfield',
          actorInitials: 'MW',
          action: 'signed estimate for',
          entityName: 'HVAC install (\$8,420)',
          timeAgo: '2 days ago',
          variant: EdenActivityVariant.success,
        ),
      ];
}
