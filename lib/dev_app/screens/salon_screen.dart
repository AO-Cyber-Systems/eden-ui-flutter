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
          // TRD 016-03 will append: Section(title: 'EdenMembershipManager + EdenPackageRedeem', child: ...).
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
          // TRD 016-06 will append: Section(title: 'EdenStaffSchedule + EdenStaffCapabilityMatrix', child: ...).
        ],
      ),
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
