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
          Section(
            title: 'EdenTimeSlotPicker — Customer-facing booking slot grid',
            child: SizedBox(
              height: 600,
              child: _TimeSlotPickerDemo(),
            ),
          ),
          Section(
            title: 'EdenMembershipManager + EdenPackageRedeem',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Membership manager (Susan M. Goldman — Gold)',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: EdenSpacing.space2),
                _MembershipManagerDemo(),
                const SizedBox(height: EdenSpacing.space4),
                Text(
                  "Package redemption (for \"Women's Haircut\")",
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: EdenSpacing.space2),
                _PackageRedeemDemo(),
              ],
            ),
          ),
          Section(
            title: 'EdenIntakeFormBuilder — Form template authoring',
            child: SizedBox(
              height: 600,
              child: _IntakeFormBuilderDemo(),
            ),
          ),
          Section(
            title: 'EdenClientSmsThread — Two-way SMS thread',
            child: SizedBox(
              height: 500,
              child: _SmsThreadDemo(),
            ),
          ),
          Section(
            title: 'EdenStaffSchedule + EdenStaffCapabilityMatrix',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Staff schedule (Aisha)',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: EdenSpacing.space2),
                SizedBox(height: 500, child: _StaffScheduleDemo()),
                const SizedBox(height: EdenSpacing.space4),
                Text(
                  'Staff capability matrix',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: EdenSpacing.space2),
                _StaffCapabilityMatrixDemo(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TRD 016-03 — EdenMembershipManager + EdenPackageRedeem demos
// -----------------------------------------------------------------------------

class _MembershipManagerDemo extends StatefulWidget {
  @override
  State<_MembershipManagerDemo> createState() => _MembershipManagerDemoState();
}

class _MembershipManagerDemoState extends State<_MembershipManagerDemo> {
  EdenMembership _m = EdenMembership(
    id: 'mem-001',
    customerId: 'cust-susan',
    customerDisplayName: 'Susan M. Goldman',
    tier: EdenMembershipTier.gold,
    tierLabel: 'Gold',
    monthlyPriceCents: 8900,
    startedAt: DateTime(2025, 11, 17),
    nextBillingAt: DateTime(2026, 6, 17),
    status: EdenMembershipStatus.active,
    benefits: const [
      EdenMembershipBenefit(
        id: 'b-cut',
        label: 'Haircuts',
        remainingThisCycle: 1,
        totalThisCycle: 2,
      ),
      EdenMembershipBenefit(id: 'b-color', label: 'Color'),
      EdenMembershipBenefit(
        id: 'b-addon',
        label: 'Add-ons',
        remainingThisCycle: 3,
        totalThisCycle: 5,
      ),
    ],
  );

  void _flip(EdenMembershipStatus next) {
    setState(() {
      _m = EdenMembership(
        id: _m.id,
        customerId: _m.customerId,
        customerDisplayName: _m.customerDisplayName,
        tier: _m.tier,
        tierLabel: _m.tierLabel,
        monthlyPriceCents: _m.monthlyPriceCents,
        currency: _m.currency,
        startedAt: _m.startedAt,
        nextBillingAt: _m.nextBillingAt,
        status: next,
        benefits: _m.benefits,
      );
    });
  }

  void _toast(BuildContext c, String msg) {
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return EdenMembershipManager(
      membership: _m,
      onPause: () {
        _flip(EdenMembershipStatus.paused);
        _toast(context, 'Paused');
      },
      onResume: () {
        _flip(EdenMembershipStatus.active);
        _toast(context, 'Resumed');
      },
      onCancel: () {
        _flip(EdenMembershipStatus.cancelled);
        _toast(context, 'Cancelled');
      },
      onChangeCard: () => _toast(context, 'Change card flow'),
      onUpdatePaymentMethod: () {
        _flip(EdenMembershipStatus.active);
        _toast(context, 'Payment updated');
      },
    );
  }
}

class _PackageRedeemDemo extends StatefulWidget {
  @override
  State<_PackageRedeemDemo> createState() => _PackageRedeemDemoState();
}

class _PackageRedeemDemoState extends State<_PackageRedeemDemo> {
  static const _haircut = EdenServiceCatalogEntry(
    id: 'srv-haircut-women',
    name: "Women's Haircut",
    durationMinutes: 45,
    priceCents: 8500,
  );

  List<EdenPackage> _packages = [
    EdenPackage(
      id: 'pkg-cutcolor-6',
      customerId: 'cust-susan',
      name: 'Cut & Color 6-Pack',
      totalVisits: 6,
      remainingVisits: 3,
      purchasedAt: DateTime(2026, 3, 15),
      expiresAt: DateTime(2026, 9, 15),
      applicableServices: const ['srv-haircut-women', 'srv-full-color'],
    ),
    EdenPackage(
      id: 'pkg-bday',
      customerId: 'cust-susan',
      name: 'Birthday Special',
      totalVisits: 1,
      remainingVisits: 1,
      purchasedAt: DateTime(2026, 2, 3),
      expiresAt: DateTime(2026, 8, 3),
      applicableServices: const ['srv-haircut-women'],
    ),
    EdenPackage(
      id: 'pkg-facial-10',
      customerId: 'cust-susan',
      name: 'Facial 10-Pack',
      totalVisits: 10,
      remainingVisits: 7,
      purchasedAt: DateTime(2026, 1, 1),
      applicableServices: const ['srv-facial-basic'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return EdenPackageRedeem(
      packages: _packages,
      serviceEntry: _haircut,
      onRedeem: (pkgId, visits) {
        setState(() {
          _packages = _packages
              .map(
                (p) => p.id == pkgId
                    ? EdenPackage(
                        id: p.id,
                        customerId: p.customerId,
                        name: p.name,
                        totalVisits: p.totalVisits,
                        remainingVisits: p.remainingVisits - visits,
                        purchasedAt: p.purchasedAt,
                        expiresAt: p.expiresAt,
                        transferable: p.transferable,
                        applicableServices: p.applicableServices,
                      )
                    : p,
              )
              .toList();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Applied $visits visit${visits == 1 ? '' : 's'} of $pkgId',
            ),
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// TRD 016-02 — EdenTimeSlotPicker demo
// -----------------------------------------------------------------------------

class _TimeSlotPickerDemo extends StatefulWidget {
  @override
  State<_TimeSlotPickerDemo> createState() => _TimeSlotPickerDemoState();
}

class _TimeSlotPickerDemoState extends State<_TimeSlotPickerDemo> {
  DateTime _day = DateTime(2026, 5, 21);
  String? _selectedSlotId;

  static const _staff = <EdenTimeSlotStaff>[
    EdenTimeSlotStaff(
        id: 'st-aisha', displayName: 'Aisha', initials: 'AA'),
    EdenTimeSlotStaff(
        id: 'st-brendan', displayName: 'Brendan', initials: 'BB'),
    EdenTimeSlotStaff(
        id: 'st-carla', displayName: 'Carla', initials: 'CC'),
  ];

  List<EdenTimeSlot> _slotsFor(DateTime day) {
    final out = <EdenTimeSlot>[];
    for (final s in _staff) {
      for (var h = 9; h < 18; h++) {
        for (var m = 0; m < 60; m += 15) {
          final blocked = (s.id == 'st-brendan' && h == 12) ||
              (s.id == 'st-carla' && h == 15 && m == 30);
          out.add(EdenTimeSlot(
            id: '${s.id}-${day.day}-${h.toString().padLeft(2, '0')}-${m.toString().padLeft(2, '0')}',
            staffId: s.id,
            startTime: DateTime(day.year, day.month, day.day, h, m),
            available: !blocked,
            blockedReason: blocked ? 'Booked' : null,
          ));
        }
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return EdenTimeSlotPicker(
      currentDay: _day,
      allStaff: _staff,
      slots: _slotsFor(_day),
      selectedSlotId: _selectedSlotId,
      onSlotSelected: (slot) {
        setState(() => _selectedSlotId = slot.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Booked: ${slot.staffId} at ${slot.startTime.hour}:${slot.startTime.minute.toString().padLeft(2, '0')}',
            ),
          ),
        );
      },
      onDayChanged: (newDay) => setState(() {
        _day = newDay;
        _selectedSlotId = null;
      }),
    );
  }
}

// -----------------------------------------------------------------------------
// TRD 016-04 — EdenIntakeFormBuilder demo
// -----------------------------------------------------------------------------

class _IntakeFormBuilderDemo extends StatefulWidget {
  @override
  State<_IntakeFormBuilderDemo> createState() => _IntakeFormBuilderDemoState();
}

class _IntakeFormBuilderDemoState extends State<_IntakeFormBuilderDemo> {
  EdenIntakeFormSchema _schema = const EdenIntakeFormSchema(
    id: 'salon-intake-v1',
    name: 'New Client Intake',
    fields: [
      EdenIntakeFieldSchema(
        id: 'f1',
        type: EdenIntakeFieldType.shortText,
        label: 'Full name',
        required: true,
      ),
      EdenIntakeFieldSchema(
        id: 'f2',
        type: EdenIntakeFieldType.date,
        label: 'Date of birth',
        required: true,
      ),
      EdenIntakeFieldSchema(
        id: 'f3',
        type: EdenIntakeFieldType.longText,
        label: 'Known allergies or sensitivities',
      ),
      EdenIntakeFieldSchema(
        id: 'f4',
        type: EdenIntakeFieldType.signature,
        label: 'Sign here',
        required: true,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return EdenIntakeFormBuilder(
      schema: _schema,
      onSchemaChanged: (s) => setState(() => _schema = s),
      onPublish: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Published "${_schema.name}" v${_schema.version} with ${_schema.fields.length} fields',
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TRD 016-06 — EdenStaffSchedule + EdenStaffCapabilityMatrix demos
// -----------------------------------------------------------------------------

class _StaffScheduleDemo extends StatefulWidget {
  @override
  State<_StaffScheduleDemo> createState() => _StaffScheduleDemoState();
}

class _StaffScheduleDemoState extends State<_StaffScheduleDemo> {
  late List<EdenStaffWeeklyShift> _shifts = const [
    EdenStaffWeeklyShift(
      staffId: 'st-aisha',
      weekday: EdenWeekday.monday,
      startTime: TimeOfDay(hour: 9, minute: 0),
      endTime: TimeOfDay(hour: 18, minute: 0),
      breaks: [
        EdenStaffBreak(
          startTime: TimeOfDay(hour: 12, minute: 0),
          endTime: TimeOfDay(hour: 13, minute: 0),
          label: 'Lunch',
        ),
      ],
    ),
    EdenStaffWeeklyShift(
      staffId: 'st-aisha',
      weekday: EdenWeekday.tuesday,
      startTime: TimeOfDay(hour: 9, minute: 0),
      endTime: TimeOfDay(hour: 18, minute: 0),
    ),
    EdenStaffWeeklyShift(
      staffId: 'st-aisha',
      weekday: EdenWeekday.wednesday,
      working: false,
    ),
    EdenStaffWeeklyShift(
      staffId: 'st-aisha',
      weekday: EdenWeekday.thursday,
      startTime: TimeOfDay(hour: 9, minute: 0),
      endTime: TimeOfDay(hour: 18, minute: 0),
    ),
    EdenStaffWeeklyShift(
      staffId: 'st-aisha',
      weekday: EdenWeekday.friday,
      startTime: TimeOfDay(hour: 9, minute: 0),
      endTime: TimeOfDay(hour: 18, minute: 0),
    ),
    EdenStaffWeeklyShift(
      staffId: 'st-aisha',
      weekday: EdenWeekday.saturday,
      startTime: TimeOfDay(hour: 10, minute: 0),
      endTime: TimeOfDay(hour: 16, minute: 0),
    ),
    EdenStaffWeeklyShift(
      staffId: 'st-aisha',
      weekday: EdenWeekday.sunday,
      working: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return EdenStaffSchedule(
      shifts: _shifts,
      onShiftChanged: (updated) {
        setState(() {
          _shifts = _shifts
              .map((s) => s.weekday == updated.weekday ? updated : s)
              .toList();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved ${updated.weekday.name} shift')),
        );
      },
    );
  }
}

class _StaffCapabilityMatrixDemo extends StatefulWidget {
  @override
  State<_StaffCapabilityMatrixDemo> createState() =>
      _StaffCapabilityMatrixDemoState();
}

class _StaffCapabilityMatrixDemoState
    extends State<_StaffCapabilityMatrixDemo> {
  static const _staff = <EdenStaffCapabilityRow>[
    EdenStaffCapabilityRow(
        id: 'st-aisha', displayName: 'Aisha A.', initials: 'AA'),
    EdenStaffCapabilityRow(
        id: 'st-brendan', displayName: 'Brendan B.', initials: 'BB'),
    EdenStaffCapabilityRow(
        id: 'st-carla', displayName: 'Carla C.', initials: 'CC'),
    EdenStaffCapabilityRow(
        id: 'st-david', displayName: 'David D.', initials: 'DD'),
    EdenStaffCapabilityRow(
        id: 'st-elena', displayName: 'Elena E.', initials: 'EE'),
  ];

  static const _services = <EdenServiceCatalogEntry>[
    EdenServiceCatalogEntry(
        id: 'srv-haircut',
        name: 'Haircut',
        durationMinutes: 45,
        priceCents: 8500),
    EdenServiceCatalogEntry(
        id: 'srv-color',
        name: 'Color',
        durationMinutes: 150,
        priceCents: 18500),
    EdenServiceCatalogEntry(
        id: 'srv-balayage',
        name: 'Balayage',
        durationMinutes: 195,
        priceCents: 28500),
    EdenServiceCatalogEntry(
        id: 'srv-facial',
        name: 'Facial',
        durationMinutes: 30,
        priceCents: 5500),
  ];

  List<EdenStaffCapability> _caps = const [
    EdenStaffCapability(
        staffId: 'st-aisha', serviceId: 'srv-haircut', canPerform: true),
    EdenStaffCapability(
        staffId: 'st-aisha', serviceId: 'srv-color', canPerform: true),
    EdenStaffCapability(
        staffId: 'st-aisha', serviceId: 'srv-balayage', canPerform: true),
    EdenStaffCapability(
        staffId: 'st-brendan', serviceId: 'srv-haircut', canPerform: true),
    EdenStaffCapability(
        staffId: 'st-carla', serviceId: 'srv-haircut', canPerform: true),
    EdenStaffCapability(
        staffId: 'st-carla', serviceId: 'srv-color', canPerform: true),
    EdenStaffCapability(
        staffId: 'st-carla', serviceId: 'srv-facial', canPerform: true),
    EdenStaffCapability(
        staffId: 'st-david', serviceId: 'srv-facial', canPerform: true),
    EdenStaffCapability(
        staffId: 'st-elena', serviceId: 'srv-haircut', canPerform: true),
    EdenStaffCapability(
        staffId: 'st-elena', serviceId: 'srv-color', canPerform: true),
    EdenStaffCapability(
        staffId: 'st-elena', serviceId: 'srv-balayage', canPerform: true),
    EdenStaffCapability(
        staffId: 'st-elena', serviceId: 'srv-facial', canPerform: true),
  ];

  @override
  Widget build(BuildContext context) {
    return EdenStaffCapabilityMatrix(
      staff: _staff,
      services: _services,
      capabilities: _caps,
      onCapabilityToggled: (staffId, serviceId, canPerform) {
        setState(() {
          _caps = _caps
              .where((c) =>
                  !(c.staffId == staffId && c.serviceId == serviceId))
              .toList();
          if (canPerform) {
            _caps = [
              ..._caps,
              EdenStaffCapability(
                staffId: staffId,
                serviceId: serviceId,
                canPerform: true,
              ),
            ];
          }
        });
      },
    );
  }
}

// -----------------------------------------------------------------------------
// TRD 016-05 — EdenClientSmsThread demo
// -----------------------------------------------------------------------------

class _SmsThreadDemo extends StatefulWidget {
  @override
  State<_SmsThreadDemo> createState() => _SmsThreadDemoState();
}

class _SmsThreadDemoState extends State<_SmsThreadDemo> {
  late List<EdenSmsMessage> _messages = [
    EdenSmsMessage(
      id: 's1',
      body: 'Hi! Can you confirm my appointment for Thursday 3pm?',
      direction: EdenSmsDirection.inbound,
      sentAt: DateTime.now().subtract(const Duration(days: 2, hours: 5)),
    ),
    EdenSmsMessage(
      id: 's2',
      body:
          'Yes — you are confirmed for Thursday May 18 at 3:00 PM with Aisha.',
      direction: EdenSmsDirection.outbound,
      status: EdenSmsDeliveryStatus.delivered,
      sentAt: DateTime.now().subtract(const Duration(days: 2, hours: 5)),
    ),
    EdenSmsMessage(
      id: 's3',
      body: 'Perfect, thank you!',
      direction: EdenSmsDirection.inbound,
      sentAt: DateTime.now().subtract(const Duration(days: 2, hours: 4)),
    ),
    EdenSmsMessage(
      id: 's4',
      body:
          'Quick question — what dye brand do you carry? I want to match my current color.',
      direction: EdenSmsDirection.inbound,
      sentAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    ),
    EdenSmsMessage(
      id: 's5',
      body:
          'We use Wella Professionals + Redken. Send a photo of your current color and Aisha can preview matches.',
      direction: EdenSmsDirection.outbound,
      status: EdenSmsDeliveryStatus.read,
      sentAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    ),
    EdenSmsMessage(
      id: 's6',
      body: "Sure! Here's a photo from yesterday.",
      direction: EdenSmsDirection.inbound,
      mediaUrls: const ['https://example.com/photo.jpg'],
      sentAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    EdenSmsMessage(
      id: 's7',
      body:
          'Beautiful — Aisha will bring out the warm copper tones to match. See you Thursday.',
      direction: EdenSmsDirection.outbound,
      status: EdenSmsDeliveryStatus.delivered,
      sentAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    EdenSmsMessage(
      id: 's8',
      body: 'Looking forward to it!',
      direction: EdenSmsDirection.inbound,
      sentAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
  ];
  int _idCounter = 9;

  @override
  Widget build(BuildContext context) {
    return EdenClientSmsThread(
      messages: _messages,
      onSend: (draft) {
        setState(() {
          _messages = [
            ..._messages,
            EdenSmsMessage(
              id: 's${_idCounter++}',
              body: draft.body,
              direction: EdenSmsDirection.outbound,
              sentAt: DateTime.now(),
              status: EdenSmsDeliveryStatus.queued,
              mediaUrls: draft.mediaUrls,
            ),
          ];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sent: ${draft.body}')),
        );
      },
      onMediaTap: (url) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Open media: $url')),
      ),
    );
  }
}
