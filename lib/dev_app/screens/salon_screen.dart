import 'package:flutter/material.dart';

import '../../eden_ui.dart';
import '../widgets/section.dart';

/// Dev-catalog screen for Objective 016 (Salon-Specific Commerce).
///
/// TRD 016-01 creates this file with the EdenServiceCatalogTile section.
/// TRDs 016-02 through 016-06 each APPEND additional Section(...) entries at
/// the marked anchor comments below — they do NOT re-create the file.
class SalonScreen extends StatefulWidget {
  const SalonScreen({super.key});

  @override
  State<SalonScreen> createState() => _SalonScreenState();
}

class _SalonScreenState extends State<SalonScreen> {
  // Hand-built demo entries — NOT LLM-generated.
  static const _staff1 = EdenServiceStaff(
      id: 'st-aisha', displayName: 'Aisha A.', initials: 'AA');
  static const _staff2 = EdenServiceStaff(
      id: 'st-brendan', displayName: 'Brendan B.', initials: 'BB');
  static const _staff3 = EdenServiceStaff(
      id: 'st-carla', displayName: 'Carla C.', initials: 'CC');
  static const _staff4 = EdenServiceStaff(
      id: 'st-david', displayName: 'David D.', initials: 'DD');
  static const _staff5 = EdenServiceStaff(
      id: 'st-elena', displayName: 'Elena E.', initials: 'EE');
  static const _staff6 = EdenServiceStaff(
      id: 'st-faisal', displayName: 'Faisal F.', initials: 'FF');
  static const _staff7 = EdenServiceStaff(
      id: 'st-gina', displayName: 'Gina G.', initials: 'GG');
  static const _staff8 = EdenServiceStaff(
      id: 'st-hassan', displayName: 'Hassan H.', initials: 'HH');

  static const _entries = <EdenServiceCatalogEntry>[
    EdenServiceCatalogEntry(
      id: 'srv-haircut-women',
      name: "Women's Haircut",
      durationMinutes: 45,
      priceCents: 8500,
      capableStaff: [_staff1, _staff2, _staff3],
      customizations: [
        EdenServiceCustomization(
            id: 'c-toner', label: 'Add color toner', priceCentsDelta: 1500),
        EdenServiceCustomization(
            id: 'c-blowout', label: 'Add blowout', priceCentsDelta: 2500),
      ],
      categoryId: 'hair-services',
    ),
    EdenServiceCatalogEntry(
      id: 'srv-haircut-mens',
      name: "Men's Haircut",
      durationMinutes: 30,
      priceCents: 5500,
      capableStaff: [_staff2, _staff4, _staff5, _staff6, _staff7, _staff8],
      customizations: [
        EdenServiceCustomization(
            id: 'c-beard', label: 'Beard trim', priceCentsDelta: 1500),
      ],
      categoryId: 'hair-services',
    ),
    EdenServiceCatalogEntry(
      id: 'srv-full-color',
      name: 'Full Color Service',
      durationMinutes: 150,
      priceCents: 18500,
      capableStaff: [_staff1, _staff3, _staff5, _staff7, _staff8],
      customizations: [
        EdenServiceCustomization(
            id: 'c-deep-cond',
            label: 'Deep conditioning',
            priceCentsDelta: 2500),
        EdenServiceCustomization(
            id: 'c-bond-builder',
            label: 'Bond builder add-on',
            priceCentsDelta: 1500),
        EdenServiceCustomization(
            id: 'c-glaze', label: 'Glaze finish', priceCentsDelta: 1000),
      ],
      categoryId: 'color-services',
    ),
    EdenServiceCatalogEntry(
      id: 'srv-balayage',
      name: 'Premium Signature Balayage Highlight Service',
      durationMinutes: 195,
      priceCents: 28500,
      capableStaff: [
        _staff1,
        _staff3,
        _staff5,
        _staff7,
        _staff8,
        _staff2,
        _staff4,
        _staff6
      ],
      customizations: [
        EdenServiceCustomization(id: 'c-toner-bal', label: 'Toner refresh'),
        EdenServiceCustomization(id: 'c-extend', label: 'Extended root work'),
      ],
      categoryId: 'color-services',
    ),
    EdenServiceCatalogEntry(
      id: 'srv-facial-basic',
      name: 'Express Facial',
      durationMinutes: 30,
      priceCents: 5500,
      categoryId: 'esthetics',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Objective 016 — Salon-Specific Commerce')),
      body: ListView(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        children: [
          Section(
            title:
                'EdenServiceCatalogTile — Salon service tile with staff + customizations',
            child: Column(
              children: [
                for (final e in _entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: EdenSpacing.space2),
                    child: EdenServiceCatalogTile(
                      entry: e,
                      onTap: (selected) =>
                          ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Tapped: ${selected.name}')),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // TRD 016-02 will append: Section(title: 'EdenTimeSlotPicker — Customer-facing booking slot grid', child: ...).
          // TRD 016-03 will append: Section(title: 'EdenMembershipManager + EdenPackageRedeem', child: ...).
          // TRD 016-04 will append: Section(title: 'EdenIntakeFormBuilder — Form template authoring', child: ...).
          // TRD 016-05 will append: Section(title: 'EdenClientSmsThread — Two-way SMS thread', child: ...).
          // TRD 016-06 will append: Section(title: 'EdenStaffSchedule + EdenStaffCapabilityMatrix', child: ...).
        ],
      ),
    );
  }
}
