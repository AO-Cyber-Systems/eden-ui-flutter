import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../eden_ui.dart';
import '../widgets/section.dart';

/// Catalog screen for Objective 007 — B-Trades-A field/companion pages.
///
/// Subsections added incrementally as TRDs 007-01..007-08 ship. Each
/// subsection mounts the corresponding widget with hand-built fixture data
/// + a small "Last event: ..." console line where applicable, so reviewers
/// can verify callbacks end-to-end inside the dev catalog.
class FieldScreen extends StatelessWidget {
  const FieldScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Field / Companion Pages — Obj 007')),
      body: ListView(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        children: const [
          // Wave 1 — Mobile-shell primitives
          _QuickAccessGridDemo(),
          _MobileAiFabDemo(),
          // Wave 2 — GPS-aware pages
          _CheckInPageDemo(),
          _LocationMapPageDemo(),
          // Wave 3 — Capture-flow pages
          _SignatureCapturePageDemo(),
          _PhotoCapturePageDemo(),
          // Wave 4 — Form-flow pages
          _PackoutPageDemo(),
          _InspectionFormPageDemo(),
        ],
      ),
    );
  }
}

class _QuickAccessGridDemo extends StatefulWidget {
  const _QuickAccessGridDemo();
  @override
  State<_QuickAccessGridDemo> createState() => _QuickAccessGridDemoState();
}

class _MobileAiFabDemo extends StatefulWidget {
  const _MobileAiFabDemo();
  @override
  State<_MobileAiFabDemo> createState() => _MobileAiFabDemoState();
}

class _MobileAiFabDemoState extends State<_MobileAiFabDemo> {
  EdenAiPersona _persona = EdenAiPersona.fieldTech;
  String _lastSent = '—';

  Stream<EdenChatStreamChunk> _echoSender(EdenChatRequest req) async* {
    setState(() => _lastSent = req.content);
    yield EdenChatStreamChunk(
        type: EdenChatChunkType.content, content: 'Echo: ${req.content}');
    yield const EdenChatStreamChunk(type: EdenChatChunkType.done);
  }

  Future<String> _inertCreate(
          {required String personaId, required String title}) async =>
      'conv-demo';

  @override
  Widget build(BuildContext context) {
    return Section(
      title: 'EdenMobileAiFab + EdenMobileAiChatSheet',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 200,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('Tap the FAB to open the chat sheet'),
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: EdenMobileAiFab(
                    pageContext: 'mobile_home',
                    entityType: 'appointment',
                    entityId: 'apt-123',
                    entityLabel: 'Smith Job — 9:00 AM',
                    activePersona: _persona,
                    onPersonaChanged: (p) => setState(() => _persona = p),
                    sendMessage: _echoSender,
                    createConversation: _inertCreate,
                    quickActions: const [
                      EdenMobileAiQuickAction(
                          label: 'Find Parts', icon: Icons.search),
                      EdenMobileAiQuickAction(
                          label: 'Equipment Info',
                          icon: Icons.info_outline),
                      EdenMobileAiQuickAction(
                          label: 'Report Issue',
                          icon: Icons.report_outlined),
                    ],
                    unreadCount: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('Last sent: $_lastSent'),
        ],
      ),
    );
  }
}

class _LocationMapPageDemo extends StatelessWidget {
  const _LocationMapPageDemo();
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Section(
      title: 'EdenLocationMapPage',
      child: SizedBox(
        height: 600,
        child: EdenLocationMapPage(
          provider: const NoOpMapProvider(),
          pins: [
            EdenLocationPin(
              id: 'demo-1',
              name: 'Mike T.',
              position: const EdenLatLng(lat: 37.7749, lng: -122.4194),
              accuracyMeters: 12,
              batteryLevel: 78,
              lastSeenAt: now.subtract(const Duration(minutes: 3)),
            ),
            EdenLocationPin(
              id: 'demo-2',
              name: 'Sarah K.',
              position: const EdenLatLng(lat: 37.7849, lng: -122.4094),
              accuracyMeters: 8,
              batteryLevel: 92,
              lastSeenAt: now.subtract(const Duration(seconds: 45)),
            ),
            EdenLocationPin(
              id: 'demo-3',
              name: 'Christopher M.',
              position: const EdenLatLng(lat: 37.7949, lng: -122.3994),
              accuracyMeters: 25,
              batteryLevel: 22,
              lastSeenAt: now.subtract(const Duration(hours: 2)),
            ),
          ],
          onPinTapped: (id) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Demo pin tap: $id')),
          ),
          onRefresh: () {},
          appBarTitle: 'Active Technicians',
        ),
      ),
    );
  }
}

class _InspectionFormPageDemo extends StatelessWidget {
  const _InspectionFormPageDemo();
  @override
  Widget build(BuildContext context) {
    return Section(
      title: 'EdenInspectionFormPage',
      child: SizedBox(
        height: 700,
        child: EdenInspectionFormPage(
          form: EdenInspectionForm(
            id: 'demo-f1',
            name: 'HVAC Inspection',
            status: EdenInspectionFormStatus.draft,
            createdAt: DateTime.now(),
            sections: const [
              EdenInspectionSection(
                id: 'sec-equipment',
                title: 'Equipment',
                fields: [
                  EdenInspectionField(
                      id: 'model',
                      label: 'Model number',
                      type: EdenInspectionFieldType.text,
                      isRequired: true),
                  EdenInspectionField(
                      id: 'age',
                      label: 'Age (years)',
                      type: EdenInspectionFieldType.number),
                  EdenInspectionField(
                      id: 'serviced',
                      label: 'Recently serviced?',
                      type: EdenInspectionFieldType.boolean),
                ],
              ),
              EdenInspectionSection(
                id: 'sec-conditions',
                title: 'Conditions',
                fields: [
                  EdenInspectionField(
                    id: 'rating',
                    label: 'Overall rating',
                    type: EdenInspectionFieldType.singleSelect,
                    options: ['Excellent', 'Good', 'Fair', 'Poor'],
                  ),
                  EdenInspectionField(
                    id: 'tags',
                    label: 'Visible issues',
                    type: EdenInspectionFieldType.multiSelect,
                    options: ['Rust', 'Leak', 'Noise', 'Damaged housing'],
                  ),
                ],
              ),
            ],
          ),
          onSaveDraft: (f) async => f,
          onSubmit: (f) async => f.copyWith(
              status: EdenInspectionFormStatus.submitted,
              submittedAt: DateTime.now()),
        ),
      ),
    );
  }
}

class _PackoutPageDemo extends StatelessWidget {
  const _PackoutPageDemo();
  @override
  Widget build(BuildContext context) {
    return Section(
      title: 'EdenPackoutPage',
      child: SizedBox(
        height: 600,
        child: EdenPackoutPage(
          appBarTitle: 'Packout / Materials',
          appointmentTitle: 'HVAC Repair — Johnson',
          items: const [
            EdenPackoutItem(
              id: 'demo-pi-1',
              itemName: '3/4" copper pipe',
              sku: 'CU-075',
              quantityLoaded: 50,
              quantityUsed: 12,
              quantityReturned: 0,
              unit: 'ft',
            ),
            EdenPackoutItem(
              id: 'demo-pi-2',
              itemName: 'R410A refrigerant',
              sku: 'R410A-1lb',
              quantityLoaded: 4,
              quantityUsed: 2,
              quantityReturned: 2,
              unit: 'lb',
            ),
          ],
          onSaveItem: (item, edit) async => item.copyWith(
            quantityUsed: edit.used,
            quantityReturned: edit.returned,
            notes: edit.notes,
          ),
        ),
      ),
    );
  }
}

class _PhotoCapturePageDemo extends StatefulWidget {
  const _PhotoCapturePageDemo();
  @override
  State<_PhotoCapturePageDemo> createState() => _PhotoCapturePageDemoState();
}

class _PhotoCapturePageDemoState extends State<_PhotoCapturePageDemo> {
  String _last = '—';

  // Synthetic 1×1 PNG bytes — same fixture as the widget test, so reviewers
  // see the post-capture annotation/categorization flow without a real plugin.
  static final _onePixelPng = Uint8List.fromList(const [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
    0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
    0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41,
    0x54, 0x78, 0x9C, 0x62, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
    0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
    0x42, 0x60, 0x82,
  ]);

  Future<void> _openPage() async {
    final result = await Navigator.of(context).push<EdenPhotoCaptureResult?>(
      MaterialPageRoute(
        builder: (_) => EdenPhotoCapturePage(
          appointmentId: 'apt-123',
          fieldId: 'before',
          onCapture: (req) async {
            await Future<void>.delayed(const Duration(milliseconds: 200));
            return EdenCapturedPhoto(
              filePath: '/tmp/demo.png',
              bytes: _onePixelPng,
              mimeType: 'image/png',
              capturedAt: DateTime.now(),
            );
          },
          onPickFromGallery: () async => EdenCapturedPhoto(
            filePath: '/tmp/demo.png',
            bytes: _onePixelPng,
            mimeType: 'image/png',
            capturedAt: DateTime.now(),
          ),
          categories: const ['before', 'during', 'after'],
        ),
      ),
    );
    if (!mounted) return;
    setState(() {
      _last = result == null
          ? 'cancelled'
          : '${result.category ?? "no-category"} · "${result.annotation ?? ""}"';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Section(
      title: 'EdenPhotoCapturePage',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilledButton.icon(
            onPressed: _openPage,
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Open photo capture page'),
          ),
          const SizedBox(height: 8),
          Text('Last result: $_last'),
        ],
      ),
    );
  }
}

class _SignatureCapturePageDemo extends StatefulWidget {
  const _SignatureCapturePageDemo();
  @override
  State<_SignatureCapturePageDemo> createState() =>
      _SignatureCapturePageDemoState();
}

class _SignatureCapturePageDemoState extends State<_SignatureCapturePageDemo> {
  String _last = '—';

  Future<void> _openPage() async {
    final result =
        await Navigator.of(context).push<EdenSignatureCaptureResult?>(
      MaterialPageRoute(
        builder: (_) => const EdenSignatureCapturePage(
          title: 'Customer Signature',
          signerName: 'Mr. Johnson',
          metadata: {'work_order_id': 'WO-4821'},
        ),
      ),
    );
    if (!mounted) return;
    setState(() {
      _last = result == null
          ? 'cancelled'
          : '${result.strokes.length} stroke(s) @ ${result.signedAt}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Section(
      title: 'EdenSignatureCapturePage',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilledButton.icon(
            onPressed: _openPage,
            icon: const Icon(Icons.draw),
            label: const Text('Open signature page'),
          ),
          const SizedBox(height: 8),
          Text('Last result: $_last'),
        ],
      ),
    );
  }
}

class _CheckInPageDemo extends StatelessWidget {
  const _CheckInPageDemo();
  @override
  Widget build(BuildContext context) {
    return Section(
      title: 'EdenCheckInPage',
      child: SizedBox(
        height: 600,
        child: EdenCheckInPage(
          appointment: const EdenCheckInAppointment(
            id: 'apt-123',
            title: 'HVAC Repair — Johnson',
            address: '742 Evergreen Terrace',
            icon: Icons.event_available,
          ),
          gpsStatus: EdenGpsStatus.high,
          gpsAccuracyMeters: 5.2,
          gpsPosition: const EdenLatLng(lat: 37.7749, lng: -122.4194),
          events: [
            EdenCheckInEvent(
              id: 'demo-e1',
              type: EdenCheckInEventType.checkIn,
              timestamp: DateTime.now()
                  .subtract(const Duration(hours: 1, minutes: 5)),
              isGeofenceVerified: true,
            ),
          ],
          onSubmit: (s) async {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Demo submit: ${s.type.name}')),
            );
          },
        ),
      ),
    );
  }
}

class _QuickAccessGridDemoState extends State<_QuickAccessGridDemo> {
  String? _lastTap;

  @override
  Widget build(BuildContext context) {
    return Section(
      title: 'EdenMobileQuickAccessGrid',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EdenMobileQuickAccessGrid(
            title: 'Quick Access',
            items: const [
              EdenMobileQuickAccessItem(
                  id: 'find_parts',
                  icon: Icons.search,
                  label: 'Find Parts'),
              EdenMobileQuickAccessItem(
                  id: 'request_parts',
                  icon: Icons.inventory_2_outlined,
                  label: 'Request Parts'),
              EdenMobileQuickAccessItem(
                id: 'quick_bid',
                icon: Icons.attach_money,
                label: 'Quick Bid',
                accent: Color(0xFFD4A853),
              ),
              EdenMobileQuickAccessItem(
                  id: 'contacts',
                  icon: Icons.phone_outlined,
                  label: 'Contacts'),
              EdenMobileQuickAccessItem(
                  id: 'po_status',
                  icon: Icons.assignment_outlined,
                  label: 'PO Status'),
              EdenMobileQuickAccessItem(
                id: 'escalate',
                icon: Icons.warning_amber_outlined,
                label: 'Escalate',
                accent: Color(0xFFEF4444),
              ),
            ],
            onTap: (id) => setState(() => _lastTap = id),
          ),
          const SizedBox(height: 8),
          Text('Last tap: ${_lastTap ?? "—"}'),
        ],
      ),
    );
  }
}
